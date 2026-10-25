"""Shared schema primitives."""

from datetime import UTC, datetime
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, PlainSerializer


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
