from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.devices import DeviceOut
from app.schemas.runtime import PublicRuntimeInfoResponse, RuntimeInfoResponse
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/runtime", tags=["runtime"])


@router.get("/public", response_model=PublicRuntimeInfoResponse)
async def public_runtime_info(
    services: Annotated[ServiceRegistry, Depends(get_services)],
) -> PublicRuntimeInfoResponse:
    settings = services.settings
    return PublicRuntimeInfoResponse(
        mode=settings.runtime_mode,
        runner_name=settings.cloud_runner_name,
        demo_available=settings.demo_account_enabled,
        worker_engine=settings.worker_engine,
    )


@router.get("", response_model=RuntimeInfoResponse)
async def runtime_info(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> RuntimeInfoResponse:
    settings = services.settings
    runner = None
    if settings.is_cloud_runtime:
        device = await services.cloud_repo_service.ensure_runner_device(current_user.id)
        runner = DeviceOut.model_validate(device)
    ai_status = await services.user_ai_settings_service.get_status(current_user.id)
    return RuntimeInfoResponse(
        mode=settings.runtime_mode,
        runner=runner,
        has_github_token=bool(ai_status["has_github_token"]),
        demo_available=settings.demo_account_enabled,
        worker_engine=settings.worker_engine,
    )
