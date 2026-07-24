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

from app.api.router import api_router
from app.core.config import Settings, get_settings
from app.core.logging import configure_logging
from app.core.metrics import HTTP_DURATION, HTTP_REQUESTS, metrics_response
from app.core.security import JWTManager
from app.core.telemetry import configure_runtime_telemetry, instrument_fastapi
from app.db.session import create_engine_and_sessionmaker, create_schema
from app.services.account_service import AccountService
from app.services.approval_service import ApprovalService
from app.services.auth_service import AuthService
from app.services.device_service import DeviceService
from app.services.event_service import EventBus, EventService
from app.services.google_auth_service import GoogleAuthService
from app.services.redis_service import RedisService
from app.services.repo_sync_service import RepoSyncService
from app.services.service_registry import ServiceRegistry
from app.services.task_service import TaskService
from app.services.worker_dispatcher import WorkerDispatcher
from app.workers.base import WorkerEngine
from app.workers.codex_worker import CodexWorkerEngine
from app.workers.fake_worker import FakeWorkerEngine


def _build_service_registry(
    settings: Settings,
    session_factory: async_sessionmaker[AsyncSession],
    redis: RedisService,
) -> ServiceRegistry:
    jwt_manager = JWTManager(settings)
    event_bus = EventBus(redis)

    event_service = EventService(session_factory=session_factory, event_bus=event_bus)
    task_service = TaskService(
        session_factory=session_factory,
        event_service=event_service,
        settings=settings,
        redis=redis,
    )
    approval_service = ApprovalService(
        session_factory=session_factory,
        event_service=event_service,
        redis=redis,
    )

    worker_engine: WorkerEngine
    worker_engine_name = settings.worker_engine.strip().lower()
    if worker_engine_name == "codex":
        worker_engine = CodexWorkerEngine(
            settings=settings,
            session_factory=session_factory,
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
        )
    elif worker_engine_name == "fake":
        worker_engine = FakeWorkerEngine(
            settings=settings,
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
        )
    else:
        raise ValueError(
            f"Unsupported WORKER_ENGINE='{settings.worker_engine}'. Use 'fake' or 'codex'."
        )
    worker_dispatcher = WorkerDispatcher(worker_engine=worker_engine)

    task_service.set_worker_dispatcher(worker_dispatcher)
    approval_service.set_worker_dispatcher(worker_dispatcher)

    return ServiceRegistry(
        settings=settings,
        auth_service=AuthService(
            session_factory=session_factory,
            jwt_manager=jwt_manager,
            settings=settings,
        ),
        google_auth_service=GoogleAuthService(settings=settings),
        account_service=AccountService(
            session_factory=session_factory,
            settings=settings,
            redis=redis,
        ),
        task_service=task_service,
        event_service=event_service,
        approval_service=approval_service,
        device_service=DeviceService(session_factory=session_factory),
        repo_sync_service=RepoSyncService(session_factory=session_factory),
        worker_dispatcher=worker_dispatcher,
        redis=redis,
    )


def create_app(settings: Settings | None = None) -> FastAPI:
    app_settings = settings or get_settings()

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        configure_logging(app_settings.log_level)
        engine, session_factory = create_engine_and_sessionmaker(app_settings.database_url)
        redis = RedisService(app_settings.redis_url, app_settings.redis_channel)
        await redis.connect()

        if app_settings.auto_create_schema:
            await create_schema(engine)

        app.state.engine = engine
        app.state.session_factory = session_factory
        app.state.services = _build_service_registry(app_settings, session_factory, redis)
        await app.state.services.event_service.start()
        configure_runtime_telemetry(app_settings, engine.sync_engine)

        yield

        await app.state.services.event_service.close()
        await redis.close()
        await engine.dispose()

    app = FastAPI(title=app_settings.app_name, debug=app_settings.debug, lifespan=lifespan)
    instrument_fastapi(app)

    @app.middleware("http")
    async def observe_request(request: Request, call_next: RequestResponseEndpoint) -> Response:
        request_id = request.headers.get("X-Request-ID", str(uuid4()))
        structlog.contextvars.bind_contextvars(request_id=request_id)
        started = perf_counter()
        try:
            response = await call_next(request)
        finally:
            structlog.contextvars.clear_contextvars()
        duration = perf_counter() - started
        route = request.scope.get("route")
        path = getattr(route, "path", request.url.path)
        HTTP_REQUESTS.labels(request.method, path, response.status_code).inc()
        HTTP_DURATION.labels(request.method, path).observe(duration)
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
