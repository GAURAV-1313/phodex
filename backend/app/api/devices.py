from typing import Annotated
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, status

from app.api.deps import get_current_user, get_services
from app.models.user import User
from app.schemas.devices import (
    DeviceHeartbeatRequest,
    DeviceListResponse,
    DeviceOut,
    DeviceRegisterRequest,
)
from app.services.exceptions import NotFoundError
from app.services.service_registry import ServiceRegistry

router = APIRouter(prefix="/devices", tags=["devices"])


@router.post("/register", response_model=DeviceOut, status_code=status.HTTP_201_CREATED)
async def register_device(
    payload: DeviceRegisterRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> DeviceOut:
    device = await services.device_service.register_device(current_user.id, payload)
    return DeviceOut.model_validate(device)


@router.post("/heartbeat", response_model=DeviceOut)
async def heartbeat(
    payload: DeviceHeartbeatRequest,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> DeviceOut:
    try:
        device = await services.device_service.heartbeat(current_user.id, payload)
    except NotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc

    return DeviceOut.model_validate(device)


@router.get("", response_model=DeviceListResponse)
async def list_devices(
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> DeviceListResponse:
    devices = await services.device_service.list_devices(current_user.id)
    return DeviceListResponse(items=[DeviceOut.model_validate(device) for device in devices])


@router.get("/{device_id}", response_model=DeviceOut)
async def get_device(
    device_id: UUID,
    services: Annotated[ServiceRegistry, Depends(get_services)],
    current_user: Annotated[User, Depends(get_current_user)],
) -> DeviceOut:
    try:
        device = await services.device_service.get_device(current_user.id, device_id)
    except NotFoundError as exc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(exc)) from exc

    return DeviceOut.model_validate(device)
