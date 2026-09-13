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
    device_name: str
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


class CurrentProjectContextResponse(BaseModel):
    project_context: ProjectContextOut | None


class GithubConnectRequest(BaseModel):
    """Connects a GitHub repository to the cloud runtime (clone or refresh)."""

    url: str = Field(min_length=1, description="https://github.com/owner/repo or owner/repo")
    branch: str | None = None
    # Optional fine-grained PAT (Contents: read/write). Stored encrypted for the
    # user and never echoed back; omit to reuse a previously stored token.
    token: str | None = None


class GithubCredentialsRequest(BaseModel):
    token: str | None = None
    clear: bool = False


class GithubCredentialsResponse(BaseModel):
    has_github_token: bool
