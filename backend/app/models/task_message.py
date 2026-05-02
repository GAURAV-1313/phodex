from datetime import datetime
from uuid import UUID

from sqlalchemy import DateTime, Enum, ForeignKey, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.enums import TaskMessageRole
from app.models.mixins import UUIDPrimaryKeyMixin
from app.utils.datetime import utcnow


class TaskMessage(UUIDPrimaryKeyMixin, Base):
    __tablename__ = "task_messages"

    task_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("tasks.id", ondelete="CASCADE"), index=True
    )
    role: Mapped[TaskMessageRole] = mapped_column(
        Enum(TaskMessageRole, name="task_message_role", native_enum=False),
        index=True,
    )
    content: Mapped[str] = mapped_column(Text)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

    task = relationship("Task", back_populates="messages")
