from uuid import UUID

from sqlalchemy import JSON, Enum, ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import ProjectContextSourceType
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class ProjectContext(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "project_contexts"

    user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    source_type: Mapped[ProjectContextSourceType] = mapped_column(
        Enum(ProjectContextSourceType, name="project_context_source_type", native_enum=False)
    )
    synced_repository_id: Mapped[UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("synced_repositories.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    name: Mapped[str] = mapped_column(String(255))
    repo_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)
    branch: Mapped[str | None] = mapped_column(String(255), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    user = relationship("User", back_populates="project_contexts")
    synced_repository = relationship("SyncedRepository", back_populates="project_contexts")
    tasks = relationship("Task", back_populates="project_context")
