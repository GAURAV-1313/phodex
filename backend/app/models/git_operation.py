from uuid import UUID

from sqlalchemy import Enum, ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import GitOperationStatus
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class GitOperation(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "git_operations"

    task_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), index=True
    )
    repo_path: Mapped[str] = mapped_column(String(1024))
    commit_message: Mapped[str] = mapped_column(Text)
    status: Mapped[GitOperationStatus] = mapped_column(
        Enum(GitOperationStatus, name="git_operation_status", native_enum=False),
        index=True,
        default=GitOperationStatus.PENDING_REVIEW,
    )
    status_output: Mapped[str | None] = mapped_column(Text, nullable=True)
    diff_stat_output: Mapped[str | None] = mapped_column(Text, nullable=True)
    pushed_branch: Mapped[str | None] = mapped_column(String(255), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)

    task = relationship("Task", back_populates="git_operations")
