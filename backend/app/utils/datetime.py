from datetime import UTC, datetime


def utcnow() -> datetime:
    return datetime.now(UTC)


def coerce_utc(value: datetime) -> datetime:
    if value.tzinfo is None:
        return value.replace(tzinfo=UTC)
    return value.astimezone(UTC)
