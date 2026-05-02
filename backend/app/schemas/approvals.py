from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.models.enums import ApprovalStatus
from app.schemas.common import ORMModel


class ApprovalRequestOut(ORMModel):
    id: UUID
    task_id: UUID
    kind: str
    title: str
    description: str
    payload_json: dict
    status: ApprovalStatus
    created_at: datetime
    resolved_at: datetime | None


class ApprovalDecisionRequest(BaseModel):
    note: str | None = None


class PendingApprovalsResponse(BaseModel):
    items: list[ApprovalRequestOut]
