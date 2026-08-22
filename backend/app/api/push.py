from typing import Annotated

from fastapi import APIRouter, Depends, status

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.push import RegisterPushTokenRequest, UnregisterPushTokenRequest
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/push", tags=["push"])


@router.post("/register", status_code=status.HTTP_204_NO_CONTENT)
async def register_push_token(
    payload: RegisterPushTokenRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    await services.push_service.register_token(
        current_user.id, payload.fcm_token, payload.platform
    )


@router.post("/unregister", status_code=status.HTTP_204_NO_CONTENT)
async def unregister_push_token(
    payload: UnregisterPushTokenRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> None:
    await services.push_service.unregister_token(current_user.id, payload.fcm_token)
