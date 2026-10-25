from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.database import get_db
from app.deps import get_current_user
from app.models import Achievement, User, UserAchievement
from app.schemas import AchievementList, AchievementWithStatus
from app.services.gamification import evaluate_achievements, recalculate_streak
from app.timezone import get_tz_offset_minutes

router = APIRouter(prefix="/api/v1/achievements", tags=["achievements"])


@router.get("", response_model=AchievementList)
def list_achievements(
    tz_offset: int = Depends(get_tz_offset_minutes),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
) -> AchievementList:
    recalculate_streak(db, current_user, tz_offset_minutes=tz_offset)
    evaluate_achievements(db, current_user)
    db.commit()

    earned_map = {
        row.achievement_id: row.earned_at
        for row in db.scalars(
            select(UserAchievement).where(UserAchievement.user_id == current_user.id)
        ).all()
    }

    achievements = db.scalars(select(Achievement).order_by(Achievement.id)).all()
    items = [
        AchievementWithStatus(
            id=achievement.id,
            code=achievement.code,
            name=achievement.name,
            description=achievement.description,
            icon=achievement.icon,
            earned=achievement.id in earned_map,
            earned_at=earned_map.get(achievement.id),
        )
        for achievement in achievements
    ]
    return AchievementList(items=items, total=len(items))
