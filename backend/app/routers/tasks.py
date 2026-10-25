from datetime import UTC, date, datetime

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Task, User, utcnow
from app.schemas import (
    EarnedAchievement,
    GamificationResult,
    TaskComplete,
    TaskCompleteResponse,
    TaskCreate,
    TaskList,
    TaskOut,
    TaskUpdate,
)
from app.services.gamification import evaluate_achievements, recalculate_streak
from app.timezone import get_tz_offset_minutes, local_day_bounds_utc

router = APIRouter(prefix="/api/v1/tasks", tags=["tasks"])


def _to_utc_naive(value: datetime) -> datetime:
    """Normalize incoming datetimes to naive UTC, which is what the DB stores."""
    if value.tzinfo is None:
        return value
    return value.astimezone(UTC).replace(tzinfo=None)


def _reject_past_due(due: datetime) -> None:
    if due <= utcnow():
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail={
                "code": "VALIDATION_ERROR",
                "message": "Data tidak valid.",
                "fields": {"due_time": "Tenggat harus di masa depan"},
            },
        )


def _get_owned_task(db: Session, user_id: int, task_id: int) -> Task:
    task = db.scalar(select(Task).where(Task.id == task_id, Task.user_id == user_id))
    if task is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"code": "NOT_FOUND", "message": "Tugas tidak ditemukan."},
        )
    return task


@router.get("", response_model=TaskList)
def list_tasks(
    date_filter: date | None = Query(default=None, alias="date"),
    task_status: str = Query(default="all", alias="status", pattern="^(all|pending|completed)$"),
    limit: int = Query(default=50, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    tz_offset: int = Depends(get_tz_offset_minutes),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskList:
    conditions = [Task.user_id == current_user.id]

    if date_filter is not None:
        start, end = local_day_bounds_utc(date_filter, tz_offset)
        conditions.append(Task.due_time >= start)
        conditions.append(Task.due_time < end)

    if task_status == "pending":
        conditions.append(Task.is_completed.is_(False))
    elif task_status == "completed":
        conditions.append(Task.is_completed.is_(True))

    total = db.scalar(select(func.count(Task.id)).where(*conditions)) or 0
    items = db.scalars(
        select(Task)
        .where(*conditions)
        .order_by(Task.due_time.asc(), Task.id.asc())
        .limit(limit)
        .offset(offset)
    ).all()

    return TaskList(items=[TaskOut.model_validate(t) for t in items], total=total)


@router.post("", response_model=TaskOut, status_code=status.HTTP_201_CREATED)
def create_task(
    payload: TaskCreate,
    response: Response,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskOut:
    due = _to_utc_naive(payload.due_time)
    _reject_past_due(due)

    task = Task(
        user_id=current_user.id,
        title=payload.title,
        description=payload.description,
        due_time=due,
    )
    db.add(task)
    db.commit()
    db.refresh(task)

    response.headers["Location"] = f"/api/v1/tasks/{task.id}"
    return TaskOut.model_validate(task)


@router.get("/{task_id}", response_model=TaskOut)
def get_task(
    task_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskOut:
    return TaskOut.model_validate(_get_owned_task(db, current_user.id, task_id))


@router.put("/{task_id}", response_model=TaskOut)
def update_task(
    task_id: int,
    payload: TaskUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskOut:
    task = _get_owned_task(db, current_user.id, task_id)

    due = _to_utc_naive(payload.due_time)
    if not task.is_completed:
        _reject_past_due(due)

    task.title = payload.title
    task.description = payload.description
    task.due_time = due
    task.updated_at = utcnow()
    db.commit()
    db.refresh(task)
    return TaskOut.model_validate(task)


@router.delete("/{task_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_task(
    task_id: int,
    tz_offset: int = Depends(get_tz_offset_minutes),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> Response:
    task = _get_owned_task(db, current_user.id, task_id)
    was_completed = task.is_completed
    db.delete(task)
    db.flush()

    if was_completed:
        recalculate_streak(db, current_user, tz_offset_minutes=tz_offset)

    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.patch("/{task_id}/complete", response_model=TaskCompleteResponse)
def complete_task(
    task_id: int,
    payload: TaskComplete | None = None,
    tz_offset: int = Depends(get_tz_offset_minutes),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> TaskCompleteResponse:
    task = _get_owned_task(db, current_user.id, task_id)

    target = (
        payload.is_completed
        if payload and payload.is_completed is not None
        else not task.is_completed
    )

    if target:
        task.is_completed = True
        if task.completed_at is None:
            task.completed_at = utcnow()
    else:
        task.is_completed = False
        task.completed_at = None

    task.updated_at = utcnow()
    db.flush()

    previous_streak = current_user.current_streak
    recalculate_streak(db, current_user, tz_offset_minutes=tz_offset)
    awarded = evaluate_achievements(db, current_user)

    db.commit()
    db.refresh(task)
    db.refresh(current_user)

    return TaskCompleteResponse(
        **TaskOut.model_validate(task).model_dump(),
        gamification=GamificationResult(
            current_streak=current_user.current_streak,
            streak_increased=current_user.current_streak > previous_streak,
            new_achievements=[
                EarnedAchievement(
                    id=achievement.id,
                    code=achievement.code,
                    name=achievement.name,
                    description=achievement.description,
                    icon=achievement.icon,
                    earned_at=earned_at,
                )
                for achievement, earned_at in awarded
            ],
        ),
    )
