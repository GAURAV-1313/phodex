from typing import Annotated

from fastapi import APIRouter, Depends

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.ai_settings import AiSettingsStatusResponse, AiSettingsUpdateRequest
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/account", tags=["account"])


@router.get("/ai-settings", response_model=AiSettingsStatusResponse)
async def get_ai_settings(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AiSettingsStatusResponse:
    status = await services.user_ai_settings_service.get_status(current_user.id)
    return AiSettingsStatusResponse(**status)


@router.put("/ai-settings", response_model=AiSettingsStatusResponse)
async def update_ai_settings(
    payload: AiSettingsUpdateRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> AiSettingsStatusResponse:
    status = await services.user_ai_settings_service.update(
        current_user.id,
        anthropic_api_key=payload.anthropic_api_key,
        openai_api_key=payload.openai_api_key,
        clear_anthropic_key=payload.clear_anthropic_key,
        clear_openai_key=payload.clear_openai_key,
        preferred_claude_model=payload.preferred_claude_model,
        preferred_codex_model=payload.preferred_codex_model,
    )
    return AiSettingsStatusResponse(**status)
