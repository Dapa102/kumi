from pydantic import BaseModel

from app.schemas.common import ORMModel, UtcDateTime
from app.schemas.task import TaskOut


class AchievementOut(ORMModel):
    id: int
    code: str
    name: str
    description: str
    icon: str


class EarnedAchievement(AchievementOut):
    earned_at: UtcDateTime


class AchievementWithStatus(AchievementOut):
    earned: bool
    earned_at: UtcDateTime | None = None


class AchievementList(BaseModel):
    items: list[AchievementWithStatus]
    total: int


class GamificationResult(BaseModel):
    current_streak: int
    streak_increased: bool
    new_achievements: list[EarnedAchievement]


class TaskCompleteResponse(TaskOut):
    gamification: GamificationResult
