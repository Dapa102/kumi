"""Shared model primitives and constants."""

from datetime import UTC, datetime

from sqlalchemy import BigInteger, Integer

from app.database import Base

DIALOG_CONTEXTS = ("morning", "afternoon", "night", "task_done", "idle")
CRITERIA_TYPES = ("total_completed", "streak")


def utcnow() -> datetime:
    """Return naive UTC, matching how timestamps are stored in the database."""
    return datetime.now(UTC).replace(tzinfo=None)


# SQLite only auto-increments columns declared exactly as INTEGER PRIMARY KEY.
BigIntPK = BigInteger().with_variant(Integer, "sqlite")
BigIntFK = BigInteger().with_variant(Integer, "sqlite")

__all__ = [
    "Base",
    "BigIntFK",
    "BigIntPK",
    "CRITERIA_TYPES",
    "DIALOG_CONTEXTS",
    "utcnow",
]
