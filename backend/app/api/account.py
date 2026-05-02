from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.account import AccountSummaryResponse, LimitStatusResponse, UsageSummaryResponse
from app.schemas.auth import UserOut
from app.services.service_registry import ServiceRegistry
from app.utils.datetime import utcnow

router = APIRouter(prefix="/account", tags=["account"])


@router.get("/me", response_model=AccountSummaryResponse)
async def account_me(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AccountSummaryResponse:
    active_sessions = await services.account_service.active_sessions_count(current_user.id)
    return AccountSummaryResponse(
        user=UserOut.model_validate(current_user),
        active_sessions=active_sessions,
        generated_at=utcnow(),
    )


@router.get("/usage", response_model=UsageSummaryResponse)
async def account_usage(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> UsageSummaryResponse:
    usage = await services.account_service.usage_summary(current_user.id)
    return UsageSummaryResponse(
        user_id=current_user.id,
        generated_at=utcnow(),
        total_tasks=usage.total_tasks,
        queued_tasks=usage.queued_tasks,
        running_tasks=usage.running_tasks,
        waiting_approval_tasks=usage.waiting_approval_tasks,
        completed_tasks=usage.completed_tasks,
        failed_tasks=usage.failed_tasks,
        cancelled_tasks=usage.cancelled_tasks,
        pending_approvals=usage.pending_approvals,
        total_events=usage.total_events,
        active_sessions=usage.active_sessions,
    )


@router.get("/limits", response_model=LimitStatusResponse)
async def account_limits(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> LimitStatusResponse:
    limits = await services.account_service.limits(current_user.id)
    return LimitStatusResponse(
        generated_at=utcnow(),
        max_active_sessions=limits.max_active_sessions,
        active_sessions=limits.active_sessions,
        remaining_active_sessions=limits.remaining_active_sessions,
        max_concurrent_tasks=limits.max_concurrent_tasks,
        current_concurrent_tasks=limits.current_concurrent_tasks,
        remaining_concurrent_tasks=limits.remaining_concurrent_tasks,
    )
