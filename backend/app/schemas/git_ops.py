from datetime import datetime
from uuid import UUID

from pydantic import BaseModel

from app.models.enums import GitOperationStatus
from app.schemas.common import ORMModel


class GitOperationOut(ORMModel):
    id: UUID
    task_id: UUID
    repo_path: str
    commit_message: str
    status: GitOperationStatus
    status_output: str | None
    diff_stat_output: str | None
    pushed_branch: str | None
    error_message: str | None
    created_at: datetime
    updated_at: datetime


class GitConfirmRequest(BaseModel):
    commit_message: str | None = None
