from uuid import UUID

from sqlalchemy import ForeignKey, String, Uuid
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class PushSubscription(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "push_subscriptions"

    user_id: Mapped[UUID] = mapped_column(
        Uuid(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), index=True
    )
    # Unique, not user_id-scoped: re-registering the same physical device
    # (token unchanged) updates in place rather than duplicating, and a
    # token that moves to a different signed-in user reassigns cleanly.
    fcm_token: Mapped[str] = mapped_column(String(4096), unique=True, index=True)
    platform: Mapped[str] = mapped_column(String(32))

    user = relationship("User", back_populates="push_subscriptions")
