from datetime import date

from pydantic import BaseModel, EmailStr, Field, field_validator

from app.schemas.common import ORMModel, UtcDateTime


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
