from uuid import UUID

from sqlalchemy import ForeignKey, String, Text, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class UserAiSettings(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "user_ai_settings"

    user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True),
        ForeignKey("users.id", ondelete="CASCADE"),
        unique=True,
        index=True,
    )
    anthropic_api_key_encrypted: Mapped[str | None] = mapped_column(Text, nullable=True)
    openai_api_key_encrypted: Mapped[str | None] = mapped_column(Text, nullable=True)
    preferred_claude_model: Mapped[str | None] = mapped_column(String(255), nullable=True)
    preferred_codex_model: Mapped[str | None] = mapped_column(String(255), nullable=True)

    user = relationship("User", back_populates="ai_settings")
