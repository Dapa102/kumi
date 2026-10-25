from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Task, User
from app.schemas import UserProfile, UserStats, UserUpdate
from app.services.gamification import evaluate_achievements, recalculate_streak
from app.timezone import get_tz_offset_minutes, local_day_bounds_utc, local_today

router = APIRouter(prefix="/api/v1/user", tags=["user"])


def _profile_payload(db: Session, user: User, tz_offset_minutes: int) -> UserProfile:
    total_tasks = db.scalar(select(func.count(Task.id)).where(Task.user_id == user.id)) or 0
    completed_tasks = (
        db.scalar(
            select(func.count(Task.id)).where(Task.user_id == user.id, Task.is_completed.is_(True))
        )
        or 0
    )

    today = local_today(tz_offset_minutes)
    recalculate_streak(db, user, today=today, tz_offset_minutes=tz_offset_minutes)
    evaluate_achievements(db, user)
    db.commit()
    db.refresh(user)

    day_start, day_end = local_day_bounds_utc(today, tz_offset_minutes)
    completed_today = (
        db.scalar(
            select(func.count(Task.id)).where(
                Task.user_id == user.id,
                Task.completed_at.is_not(None),
                Task.completed_at >= day_start,
                Task.completed_at < day_end,
            )
        )
        or 0
    )

    rate = round(completed_tasks / total_tasks, 2) if total_tasks else 0.0

    return UserProfile(
        id=user.id,
        email=user.email,
        name=user.name,
        picture_url=user.picture_url,
        current_streak=user.current_streak,
        last_completed_date=user.last_completed_date,
        created_at=user.created_at,
        stats=UserStats(
            total_tasks=total_tasks,
            completed_tasks=completed_tasks,
            completed_today=completed_today,
            completion_rate=rate,
        ),
    )


@router.get("/profile", response_model=UserProfile)
def get_profile(
    tz_offset: int = Depends(get_tz_offset_minutes),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserProfile:
    return _profile_payload(db, current_user, tz_offset)


@router.put("/profile", response_model=UserProfile)
def update_profile(
    payload: UserUpdate,
    tz_offset: int = Depends(get_tz_offset_minutes),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserProfile:
    current_user.name = payload.name
    db.commit()
    db.refresh(current_user)
    return _profile_payload(db, current_user, tz_offset)
