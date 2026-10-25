"""Pydantic schemas, grouped by domain and re-exported for convenience."""

from app.schemas.achievement import (
    AchievementList,
    AchievementOut,
    AchievementWithStatus,
    EarnedAchievement,
    GamificationResult,
    TaskCompleteResponse,
)
from app.schemas.auth import AuthResponse, GoogleAuthRequest, UserPublic
from app.schemas.common import DialogContext, ORMModel, UtcDateTime
from app.schemas.dialog import DialogOut
from app.schemas.health import HealthOut
from app.schemas.task import TaskComplete, TaskCreate, TaskList, TaskOut, TaskUpdate
from app.schemas.user import UserProfile, UserStats, UserUpdate

__all__ = [
    "AchievementList",
    "AchievementOut",
    "AchievementWithStatus",
    "AuthResponse",
    "DialogContext",
    "DialogOut",
    "EarnedAchievement",
    "GamificationResult",
    "GoogleAuthRequest",
    "HealthOut",
    "ORMModel",
    "TaskComplete",
    "TaskCompleteResponse",
    "TaskCreate",
    "TaskList",
    "TaskOut",
    "TaskUpdate",
    "UserProfile",
    "UserPublic",
    "UserStats",
    "UserUpdate",
    "UtcDateTime",
]
