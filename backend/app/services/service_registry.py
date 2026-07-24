from dataclasses import dataclass

from app.core.config import Settings
from app.services.account_service import AccountService
from app.services.approval_service import ApprovalService
from app.services.auth_service import AuthService
from app.services.device_service import DeviceService
from app.services.event_service import EventService
from app.services.google_auth_service import GoogleAuthService
from app.services.redis_service import RedisService
from app.services.repo_sync_service import RepoSyncService
from app.services.task_service import TaskService
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
    redis: RedisService
