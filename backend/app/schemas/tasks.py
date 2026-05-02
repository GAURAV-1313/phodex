from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import TaskMessageRole, TaskStatus
from app.schemas.approvals import ApprovalRequestOut
from app.schemas.common import ORMModel


class TaskEventEnvelope(BaseModel):
    event_id: UUID
    task_id: UUID
    sequence: int
    type: str
    timestamp: datetime
    data: dict


class TaskCreateRequest(BaseModel):
    prompt: str = Field(min_length=1)
    project_context_id: UUID | None = None
    title: str | None = None


class TaskReplyRequest(BaseModel):
    content: str = Field(min_length=1)


class TaskMessageOut(ORMModel):
    id: UUID
    task_id: UUID
    role: TaskMessageRole
    content: str
    created_at: datetime


class TaskOut(ORMModel):
    id: UUID
    user_id: UUID
    project_context_id: UUID | None
    title: str | None
    prompt: str
    status: TaskStatus
    current_phase: str | None
    created_at: datetime
    updated_at: datetime
    started_at: datetime | None
    finished_at: datetime | None
    error_message: str | None
    final_summary: str | None
    cancelled_at: datetime | None


class TaskListResponse(BaseModel):
    items: list[TaskOut]


class TaskMessagesResponse(BaseModel):
    items: list[TaskMessageOut]


class TaskEventsResponse(BaseModel):
    items: list[TaskEventEnvelope]


class TaskIssueOut(BaseModel):
    sequence: int
    type: str
    timestamp: datetime
    code: str | None
    message: str
    data: dict


class TaskIssuesResponse(BaseModel):
    items: list[TaskIssueOut]


class TaskDetailResponse(BaseModel):
    task: TaskOut
    messages: list[TaskMessageOut]
    events: list[TaskEventEnvelope]
    approvals: list[ApprovalRequestOut]
