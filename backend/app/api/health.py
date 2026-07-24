from fastapi import APIRouter, Request
from sqlalchemy import text

from app.schemas.health import HealthResponse

router = APIRouter(prefix="/health", tags=["health"])


@router.get("", response_model=HealthResponse)
async def health() -> HealthResponse:
    return HealthResponse(status="ok")


@router.get("/live", response_model=HealthResponse)
async def live() -> HealthResponse:
    return HealthResponse(status="ok")


@router.get("/ready", response_model=HealthResponse)
async def ready(request: Request) -> HealthResponse:
    try:
        async with request.app.state.session_factory() as session:
            await session.execute(text("SELECT 1"))
        redis = request.app.state.services.redis
        if redis.enabled and not await redis.ping():
            return HealthResponse(status="unavailable", database="ok", redis="unavailable")
        return HealthResponse(
            status="ok", database="ok", redis="ok" if redis.enabled else "disabled"
        )
    except Exception:
        return HealthResponse(status="unavailable", database="unavailable", redis="unknown")
