from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.models.enums import ProjectContextSourceType
from app.schemas.common import ORMModel


class RepoSyncItemIn(BaseModel):
    name: str = Field(min_length=1)
    local_path: str = Field(min_length=1)
    git_root: str = Field(min_length=1)
    current_branch: str | None = None
    default_branch: str | None = None
    last_opened_at: datetime | None = None
    metadata_json: dict = Field(default_factory=dict)


class RepoSyncRequest(BaseModel):
    device_id: UUID
    repositories: list[RepoSyncItemIn] = Field(default_factory=list)
    scanned_at: datetime | None = None


class SyncedRepositoryOut(ORMModel):
    id: UUID
    user_id: UUID
    device_id: UUID
    name: str
    local_path: str
    git_root: str
    current_branch: str | None
    default_branch: str | None
    is_active: bool
    last_scanned_at: datetime | None
    last_opened_at: datetime | None
    metadata_json: dict
    created_at: datetime
    updated_at: datetime


class RepoListResponse(BaseModel):
    items: list[SyncedRepositoryOut]


class RepoSyncResponse(BaseModel):
    synced_count: int
    items: list[SyncedRepositoryOut]


class RepoSelectRequest(BaseModel):
    name: str | None = None


class ProjectContextOut(ORMModel):
    id: UUID
    user_id: UUID
    source_type: ProjectContextSourceType
    synced_repository_id: UUID | None
    name: str
    repo_url: str | None
    branch: str | None
    metadata_json: dict
    created_at: datetime
    updated_at: datetime


class RepoSelectResponse(BaseModel):
    project_context: ProjectContextOut
