import asyncio
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from time import perf_counter
from uuid import uuid4

import structlog
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import Response
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
            while True:
                try:
                    pool = engine.pool
                    size = getattr(pool, "size", None)
                    checked_in = getattr(pool, "checkedin", None)
                    if callable(size) and callable(checked_in):
                        DB_POOL_SIZE.set(float(size()))
                        DB_POOL_IDLE.set(float(checked_in()))
                except Exception:
                    pass
                await asyncio.sleep(5)

        if app_settings.auto_create_schema:
            await create_schema(engine)

        app.state.engine = engine
        app.state.session_factory = session_factory
        app.state.services = build_registry(session_factory, redis, app_settings)
        await app.state.services.event_service.start()
        interrupted = await app.state.services.task_service.recover_interrupted_tasks()
        if interrupted:
            structlog.get_logger(__name__).warning(
                "tasks.recovered_interrupted", count=interrupted
            )
        configure_runtime_telemetry(app_settings, engine.sync_engine)
        _pool_task = asyncio.create_task(_pool_metrics())

        if app_settings.demo_account_enabled:
            await app.state.services.auth_service.ensure_password_account(
                email=str(app_settings.demo_account_email),
                password=str(app_settings.demo_account_password),
                name=app_settings.demo_account_name,
            )

        _runner_task: asyncio.Task[None] | None = None
        if app_settings.is_cloud_runtime:
            cloud_repo_service = app.state.services.cloud_repo_service

            async def _runner_heartbeat() -> None:
                # Stands in for the laptop device agent: keeps every user's
                # "Phodex Cloud" device marked online while this server runs.
                while True:
                    try:
                        await cloud_repo_service.heartbeat_runners()
                    except Exception as exc:
                        structlog.get_logger(__name__).warning(
                            "cloud_runner.heartbeat_failed", error=str(exc)
                        )
                    await asyncio.sleep(app_settings.cloud_runner_heartbeat_seconds)

            _runner_task = asyncio.create_task(_runner_heartbeat())

        base_url, is_guessed = resolve_public_base_url(app_settings)
        if app_settings.is_cloud_runtime:
            print(
                f"\n  Phodex Cloud runtime ready: point the app at {base_url} "
                f"(worker engine: {app_settings.worker_engine}).\n",
                flush=True,
            )
        else:
            note = (
                " (same Wi-Fi only — set PUBLIC_BASE_URL for anywhere access)" if is_guessed else ""
            )
            print(
                f"\n  Connect your phone: open http://localhost:8000/pair in a "
                f"browser and scan the QR code{note}.\n",
                flush=True,
            )

        yield

        for background in (_pool_task, _runner_task):
            if background is None:
                continue
            background.cancel()
            try:
                await background
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
            "runtime_mode": app_settings.runtime_mode,
        }

    return app


app = create_app()
