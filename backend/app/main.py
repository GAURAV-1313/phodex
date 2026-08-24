import asyncio
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from time import perf_counter
from uuid import uuid4

import structlog
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from starlette.middleware.base import RequestResponseEndpoint

from app.api.error_handlers import register_exception_handlers
from app.api.router import api_router
from app.core.config import Settings, get_settings
from app.core.logging import configure_logging
from app.core.metrics import (
    AUTH_DURATION,
    DB_POOL_IDLE,
    DB_POOL_SIZE,
    HTTP_DURATION,
    HTTP_REQUESTS,
    RATE_LIMIT_REJECTIONS,
    SSE_CONNECTION_DURATION,
    TASK_CREATE_DURATION,
    TASK_DETAIL_DURATION,
    metrics_response,
)
from app.core.telemetry import configure_runtime_telemetry, instrument_fastapi
from app.db.session import create_engine_and_sessionmaker, create_schema
from app.services.pairing_service import resolve_public_base_url
from app.services.redis_service import RedisService
from app.services.service_registry import build_registry


def create_app(settings: Settings | None = None) -> FastAPI:
    app_settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        configure_logging(app_settings.log_level)
        engine, session_factory = create_engine_and_sessionmaker(app_settings.database_url)
        redis = RedisService(app_settings.redis_url, app_settings.redis_channel)
        await redis.connect()

        async def _pool_metrics() -> None:
            import asyncio
            while True:
                try:
                    pool = engine.pool
                    DB_POOL_SIZE.set(pool.status()["size"])
                    DB_POOL_IDLE.set(pool.status()["idle"])
                except Exception:
                    pass
                await asyncio.sleep(5)

        if app_settings.auto_create_schema:
            await create_schema(engine)

        app.state.engine = engine
        app.state.session_factory = session_factory
        app.state.services = build_registry(session_factory, redis, app_settings)
        await app.state.services.event_service.start()
        configure_runtime_telemetry(app_settings, engine.sync_engine)
        _pool_task = asyncio.create_task(_pool_metrics())

        _, is_guessed = resolve_public_base_url(app_settings)
        note = " (same Wi-Fi only — set PUBLIC_BASE_URL for anywhere access)" if is_guessed else ""
        print(
            f"\n  Connect your phone: open http://localhost:8000/pair in a "
            f"browser and scan the QR code{note}.\n",
            flush=True,
        )

        yield

        _pool_task.cancel()
        try:
            await _pool_task
        except asyncio.CancelledError:
            pass
        await app.state.services.event_service.close()
        await redis.close()
        await engine.dispose()

    app = FastAPI(title=app_settings.app_name, debug=app_settings.debug, lifespan=lifespan)
    instrument_fastapi(app)
    register_exception_handlers(app)

    @app.middleware("http")
    async def observe_request(request: Request, call_next: RequestResponseEndpoint) -> Response:
        request_id = request.headers.get("X-Request-ID", str(uuid4()))
        structlog.contextvars.bind_contextvars(request_id=request_id)
        started = perf_counter()
        route = request.scope.get("route")
        path = getattr(route, "path", request.url.path)
        response = await call_next(request)
        duration = perf_counter() - started
        HTTP_REQUESTS.labels(request.method, path, response.status_code).inc()
        HTTP_DURATION.labels(request.method, path).observe(duration)
        if path.startswith("/auth"):
            AUTH_DURATION.labels(endpoint=path).observe(duration)
        elif path == "/tasks" and request.method == "POST":
            TASK_CREATE_DURATION.observe(duration)
        elif "/tasks/" in path and "/stream" not in path and "/messages" not in path and "/events" not in path:
            TASK_DETAIL_DURATION.observe(duration)
        structlog.contextvars.clear_contextvars()
        response.headers["X-Request-ID"] = request_id
        return response

    app.add_middleware(
        CORSMiddleware,
        allow_origins=app_settings.cors_origins,
        allow_credentials=False,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    app.include_router(api_router)

    @app.get("/metrics", include_in_schema=False)
    async def metrics() -> Response:
        if not app_settings.metrics_enabled:
            return Response(status_code=404)
        payload, media_type = metrics_response()
        return Response(content=payload, media_type=media_type)

    @app.get("/")
    async def root() -> dict[str, str]:
        return {
            "name": app_settings.app_name,
            "docs": "/docs",
        }

    return app


app = create_app()
