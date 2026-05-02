from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.common import ORMModel


class DeviceRegisterRequest(BaseModel):
    device_id: UUID | None = None
    name: str = Field(min_length=1)
    platform: str = "macos"
    status: str = "online"
    agent_version: str | None = None


class DeviceHeartbeatRequest(BaseModel):
    device_id: UUID
    status: str = "online"
    agent_version: str | None = None


class DeviceOut(ORMModel):
    id: UUID
    user_id: UUID
    name: str
    platform: str
    status: str
    agent_version: str | None
    last_seen_at: datetime | None
    created_at: datetime
    updated_at: datetime


class DeviceListResponse(BaseModel):
    items: list[DeviceOut]
