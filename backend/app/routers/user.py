from datetime import UTC, datetime, timedelta

from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Task, User
from app.schemas import UserProfile, UserStats, UserUpdate

router = APIRouter(prefix="/api/v1/user", tags=["user"])


def _profile_payload(db: Session, user: User) -> UserProfile:
    total_tasks = db.scalar(select(func.count(Task.id)).where(Task.user_id == user.id)) or 0
    completed_tasks = (
        db.scalar(
            select(func.count(Task.id)).where(Task.user_id == user.id, Task.is_completed.is_(True))
        )
        or 0
    )

    now = datetime.now(UTC)
    day_start = now.replace(hour=0, minute=0, second=0, microsecond=0, tzinfo=None)
    day_end = day_start + timedelta(days=1)
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
    db: Session = Depends(get_db), current_user: User = Depends(get_current_user)
) -> UserProfile:
    return _profile_payload(db, current_user)


@router.put("/profile", response_model=UserProfile)
def update_profile(
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> UserProfile:
    current_user.name = payload.name
    db.commit()
    db.refresh(current_user)
    return _profile_payload(db, current_user)
