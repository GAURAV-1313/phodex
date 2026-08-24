from dataclasses import dataclass

from sqlalchemy.ext.asyncio import async_sessionmaker

from app.core.config import Settings
from app.repositories.approval_repo import ApprovalRepository
from app.repositories.device_repo import DeviceRepository
from app.repositories.event_repo import EventRepository
from app.repositories.git_repo import GitOperationRepository
from app.repositories.push_repo import PushRepository
from app.repositories.repo_repo import RepoRepository
from app.repositories.session_repo import SessionRepository
from app.repositories.task_repo import TaskRepository
from app.repositories.user_ai_settings_repo import UserAiSettingsRepository
from app.repositories.user_repo import UserRepository
from app.services.account_service import AccountService
from app.services.approval_service import ApprovalService
from app.services.auth_service import AuthService
from app.services.device_service import DeviceService
from app.services.event_service import EventService
from app.services.git_service import GitService
from app.services.google_auth_service import GoogleAuthService
from app.services.push_service import PushService
from app.services.redis_service import RedisService
from app.services.repo_sync_service import RepoSyncService
from app.services.task_service import TaskService
from app.services.user_ai_settings_service import UserAiSettingsService
from app.services.worker_dispatcher import WorkerDispatcher


@dataclass
class ServiceRegistry:
    settings: Settings
    auth_service: AuthService
    google_auth_service: GoogleAuthService
    account_service: AccountService
    task_service: TaskService
    event_service: EventService
    approval_service: ApprovalService
    device_service: DeviceService
    repo_sync_service: RepoSyncService
    worker_dispatcher: WorkerDispatcher
    git_service: GitService
    user_ai_settings_service: UserAiSettingsService
    push_service: PushService
    redis: RedisService


def build_registry(
    session_factory: async_sessionmaker,
    redis: RedisService,
    settings: Settings,
) -> ServiceRegistry:
    user_repo = UserRepository(session_factory)
    session_repo = SessionRepository(session_factory)
    task_repo = TaskRepository(session_factory)
    approval_repo = ApprovalRepository(session_factory)
    device_repo = DeviceRepository(session_factory)
    repo_repo = RepoRepository(session_factory)
    git_repo = GitOperationRepository(session_factory)
    event_repo = EventRepository(session_factory)
    push_repo = PushRepository(session_factory)
    user_ai_settings_repo = UserAiSettingsRepository(session_factory)

    from app.core.security import JWTManager
    from app.services.event_service import EventBus
    from app.services.worker_dispatcher import WorkerDispatcher

    jwt_manager = JWTManager(settings)
    event_bus = EventBus(redis)

    event_service = EventService(session_factory=session_factory, event_bus=event_bus, event_repo=event_repo)
    push_service = PushService(
        session_factory=session_factory, settings=settings, push_repo=push_repo
    )
    task_service = TaskService(
        session_factory=session_factory,
        event_service=event_service,
        settings=settings,
        redis=redis,
        push_service=push_service,
        task_repo=task_repo,
    )
    approval_service = ApprovalService(
        session_factory=session_factory,
        event_service=event_service,
        redis=redis,
        push_service=push_service,
        approval_repo=approval_repo,
    )
    user_ai_settings_service = UserAiSettingsService(
        session_factory=session_factory,
        settings=settings,
        user_ai_settings_repo=user_ai_settings_repo,
    )

    worker_engine: WorkerEngine
    if settings.worker_engine == "codex":
        from workers.codex import CodexWorkerEngine

        worker_engine = CodexWorkerEngine(
            settings=settings,
            session_factory=session_factory,
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
            user_ai_settings_service=user_ai_settings_service,
        )
    elif settings.worker_engine == "claude":
        from workers.claude import ClaudeWorkerEngine

        worker_engine = ClaudeWorkerEngine(
            settings=settings,
            session_factory=session_factory,
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
            user_ai_settings_service=user_ai_settings_service,
        )
    else:
        from workers.fake_worker import FakeWorkerEngine

        worker_engine = FakeWorkerEngine(
            settings=settings,
            task_service=task_service,
            event_service=event_service,
            approval_service=approval_service,
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
            user_repo=user_repo,
            session_repo=session_repo,
        ),
        google_auth_service=GoogleAuthService(settings=settings),
        account_service=AccountService(
            session_factory=session_factory,
            settings=settings,
            redis=redis,
            session_repo=session_repo,
            task_repo=task_repo,
        ),
        task_service=task_service,
        event_service=event_service,
        approval_service=approval_service,
        device_service=DeviceService(
            session_factory=session_factory,
            device_repo=device_repo,
        ),
        repo_sync_service=RepoSyncService(
            session_factory=session_factory,
            repo_repo=repo_repo,
        ),
        worker_dispatcher=worker_dispatcher,
        git_service=GitService(
            session_factory=session_factory,
            event_service=event_service,
            git_repo=git_repo,
        ),
        user_ai_settings_service=user_ai_settings_service,
        push_service=push_service,
        redis=redis,
    )
