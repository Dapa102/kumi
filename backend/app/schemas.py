from datetime import UTC, date, datetime
from typing import Annotated, Literal

from pydantic import (
    BaseModel,
    ConfigDict,
    EmailStr,
    Field,
    PlainSerializer,
    field_validator,
)


def _as_utc(value: datetime | None) -> str | None:
    """Serialize naive datetimes (stored as UTC) with an explicit UTC offset."""
    if value is None:
        return None
    if value.tzinfo is None:
        value = value.replace(tzinfo=UTC)
    return value.astimezone(UTC).isoformat().replace("+00:00", "Z")


UtcDateTime = Annotated[datetime, PlainSerializer(_as_utc, return_type=str)]

DialogContext = Literal["morning", "afternoon", "night", "task_done", "idle"]


class ORMModel(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# --- Auth -------------------------------------------------------------------


class GoogleAuthRequest(BaseModel):
    id_token: str = Field(min_length=20, max_length=4096)


class UserPublic(ORMModel):
    id: int
    email: EmailStr
    name: str
    picture_url: str | None = None
    current_streak: int
    created_at: UtcDateTime


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    is_new_user: bool
    user: UserPublic


# --- User -------------------------------------------------------------------


class UserStats(BaseModel):
    total_tasks: int
    completed_tasks: int
    completed_today: int
    completion_rate: float


class UserProfile(ORMModel):
    id: int
    email: EmailStr
    name: str
    picture_url: str | None = None
    current_streak: int
    last_completed_date: date | None = None
    created_at: UtcDateTime
    stats: UserStats


class UserUpdate(BaseModel):
    name: str = Field(min_length=1, max_length=100)

    @field_validator("name")
    @classmethod
    def name_not_blank(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Nama tidak boleh kosong")
        return cleaned


# --- Tasks ------------------------------------------------------------------


class TaskCreate(BaseModel):
    title: str = Field(min_length=1, max_length=150)
    description: str | None = Field(default=None, max_length=1000)
    due_time: datetime

    @field_validator("title")
    @classmethod
    def title_not_blank(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("Judul wajib diisi")
        return cleaned


class TaskUpdate(TaskCreate):
    pass


class TaskComplete(BaseModel):
    is_completed: bool | None = None


class TaskOut(ORMModel):
    id: int
    title: str
    description: str | None
    due_time: UtcDateTime
    is_completed: bool
    completed_at: UtcDateTime | None
    created_at: UtcDateTime
    updated_at: UtcDateTime


class TaskList(BaseModel):
    items: list[TaskOut]
    total: int


# --- Gamification -----------------------------------------------------------


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


# --- Dialog -----------------------------------------------------------------


class DialogOut(ORMModel):
    id: int
    context: str
    text: str


# --- Health -----------------------------------------------------------------


class HealthOut(BaseModel):
    status: str
    database: str
    version: str
    time: UtcDateTime
