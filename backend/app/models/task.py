from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, Enum, ForeignKey, Integer, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import TaskStatus
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class Task(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "tasks"

    user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    project_context_id: Mapped[UUID | None] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("project_contexts.id", ondelete="SET NULL"),
        nullable=True,
        index=True,
    )
    title: Mapped[str | None] = mapped_column(String(255), nullable=True)
    prompt: Mapped[str] = mapped_column(Text)
    status: Mapped[TaskStatus] = mapped_column(
        Enum(TaskStatus, name="task_status", native_enum=False),
        index=True,
        default=TaskStatus.QUEUED,
    )
    current_phase: Mapped[str | None] = mapped_column(String(255), nullable=True)
    started_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    finished_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    error_message: Mapped[str | None] = mapped_column(Text, nullable=True)
    final_summary: Mapped[str | None] = mapped_column(Text, nullable=True)
    cancelled_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    # Agent-side conversation id (e.g. the Claude Code `session_id` from its
    # stream-json init event). Lets a resumed run continue the same agent
    # conversation via `claude --resume <id>` instead of starting cold.
    runtime_session_id: Mapped[str | None] = mapped_column(String(255), nullable=True)
    # How many times the user has resumed this task after it stopped.
    # A non-zero value tells the worker to continue rather than start fresh.
    resume_count: Mapped[int] = mapped_column(Integer, default=0, server_default="0")

    user = relationship("User", back_populates="tasks")
    project_context = relationship("ProjectContext", back_populates="tasks")
    messages = relationship("TaskMessage", back_populates="task", cascade="all,delete-orphan")
    events = relationship("TaskEvent", back_populates="task", cascade="all,delete-orphan")
    approval_requests = relationship(
        "ApprovalRequest", back_populates="task", cascade="all,delete-orphan"
    )
    artifacts = relationship("Artifact", back_populates="task", cascade="all,delete-orphan")
    git_operations = relationship(
        "GitOperation", back_populates="task", cascade="all,delete-orphan"
    )
