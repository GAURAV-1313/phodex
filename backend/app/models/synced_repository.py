from datetime import datetime
from uuid import UUID

from sqlalchemy import JSON, Boolean, DateTime, ForeignKey, String, UniqueConstraint, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class SyncedRepository(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "synced_repositories"
    __table_args__ = (
        UniqueConstraint("user_id", "device_id", "git_root", name="uq_repo_user_device_git_root"),
    )

    user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    device_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("devices.id", ondelete="CASCADE"), index=True
    )
    name: Mapped[str] = mapped_column(String(255))
    local_path: Mapped[str] = mapped_column(String(2048))
    git_root: Mapped[str] = mapped_column(String(2048))
    current_branch: Mapped[str | None] = mapped_column(String(255), nullable=True)
    default_branch: Mapped[str | None] = mapped_column(String(255), nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    last_scanned_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    last_opened_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True), nullable=True)
    metadata_json: Mapped[dict] = mapped_column(JSON, default=dict)

    user = relationship("User", back_populates="synced_repositories")
    device = relationship("Device", back_populates="repositories")
    project_contexts = relationship("ProjectContext", back_populates="synced_repository")

    @property
    def device_name(self) -> str:
        return str(self.device.name)
