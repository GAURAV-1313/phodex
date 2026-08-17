from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.schemas.auth import UserOut


class AccountSummaryResponse(BaseModel):
    user: UserOut
    active_sessions: int
    device_online: bool
    device_last_seen_at: datetime | None
    generated_at: datetime


class UsageSummaryResponse(BaseModel):
    user_id: UUID
    generated_at: datetime
    total_tasks: int
    queued_tasks: int
    running_tasks: int
    waiting_approval_tasks: int
    completed_tasks: int
    failed_tasks: int
    cancelled_tasks: int
    pending_approvals: int
    total_events: int
    active_sessions: int


class LimitStatusResponse(BaseModel):
    generated_at: datetime
    max_active_sessions: int | None
    active_sessions: int
    remaining_active_sessions: int | None
    max_concurrent_tasks: int | None
    current_concurrent_tasks: int
    remaining_concurrent_tasks: int | None
