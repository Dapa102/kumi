from datetime import datetime

from pydantic import BaseModel, Field, field_validator

from app.schemas.common import ORMModel, UtcDateTime


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
