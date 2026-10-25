"""Local-day helpers.

Timestamps are stored as naive UTC. Clients send their UTC offset via the
``X-Timezone-Offset`` header (minutes east of UTC, e.g. 420 for WIB) so that
"today", date filters, and streaks follow the user's local calendar day.
"""

from datetime import UTC, date, datetime, time, timedelta

from fastapi import Header

from app.config import settings


def get_tz_offset_minutes(
    x_timezone_offset: int | None = Header(
        default=None,
        alias="X-Timezone-Offset",
        ge=-720,
        le=840,
        description="Client offset from UTC in minutes (e.g. 420 for WIB).",
    ),
) -> int:
    if x_timezone_offset is None:
        return settings.default_tz_offset_minutes
    return x_timezone_offset


def utcnow() -> datetime:
    """Naive UTC, matching the database representation."""
    return datetime.now(UTC).replace(tzinfo=None)


def local_today(tz_offset_minutes: int) -> date:
    return (utcnow() + timedelta(minutes=tz_offset_minutes)).date()


def to_local_date(value: datetime, tz_offset_minutes: int) -> date:
    return (value + timedelta(minutes=tz_offset_minutes)).date()


def local_day_bounds_utc(day: date, tz_offset_minutes: int) -> tuple[datetime, datetime]:
    """Return the [start, end) UTC range covering a local calendar day."""
    start = datetime.combine(day, time.min) - timedelta(minutes=tz_offset_minutes)
    return start, start + timedelta(days=1)
