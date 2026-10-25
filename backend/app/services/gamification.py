from datetime import date, datetime, timedelta

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.models import Achievement, Task, User, UserAchievement, utcnow
from app.timezone import local_today, to_local_date


def completed_tasks_count(db: Session, user_id: int) -> int:
    return (
        db.scalar(
            select(func.count(Task.id)).where(Task.user_id == user_id, Task.is_completed.is_(True))
        )
        or 0
    )


def recalculate_streak(
    db: Session, user: User, today: date | None = None, tz_offset_minutes: int = 0
) -> bool:
    """Recompute streak from completed_at dates. Returns True if streak value changed."""
    today = today or local_today(tz_offset_minutes)

    rows = db.scalars(
        select(Task.completed_at)
        .where(Task.user_id == user.id, Task.completed_at.is_not(None))
        .order_by(Task.completed_at.desc())
    ).all()

    days = sorted({to_local_date(row, tz_offset_minutes) for row in rows}, reverse=True)
    if not days:
        changed = user.current_streak != 0 or user.last_completed_date is not None
        user.current_streak = 0
        user.last_completed_date = None
        return changed

    latest = days[0]
    if latest < today - timedelta(days=1):
        streak = 0
    else:
        streak = 1
        cursor = latest
        for day in days[1:]:
            if day == cursor - timedelta(days=1):
                streak += 1
                cursor = day
            elif day == cursor:
                continue
            else:
                break

    changed = user.current_streak != streak or user.last_completed_date != latest
    user.current_streak = streak
    user.last_completed_date = latest
    return changed


def _earned_ids(db: Session, user_id: int) -> set[int]:
    return set(
        db.scalars(
            select(UserAchievement.achievement_id).where(UserAchievement.user_id == user_id)
        ).all()
    )


def evaluate_achievements(db: Session, user: User) -> list[tuple[Achievement, datetime]]:
    """Award any newly satisfied achievements. Returns list of (achievement, earned_at)."""
    earned = _earned_ids(db, user.id)
    total_completed = completed_tasks_count(db, user.id)
    streak = user.current_streak

    awarded: list[tuple[Achievement, datetime]] = []
    for achievement in db.scalars(select(Achievement).order_by(Achievement.id)).all():
        if achievement.id in earned:
            continue

        value = total_completed if achievement.criteria_type == "total_completed" else streak
        if value < achievement.criteria_value:
            continue

        now = utcnow()
        db.add(UserAchievement(user_id=user.id, achievement_id=achievement.id, earned_at=now))
        earned.add(achievement.id)
        awarded.append((achievement, now))

    if awarded:
        db.flush()
    return awarded
