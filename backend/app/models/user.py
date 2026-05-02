from sqlalchemy import DateTime, String
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db.base import Base
from app.models.mixins import TimestampMixin, UUIDPrimaryKeyMixin


class User(UUIDPrimaryKeyMixin, TimestampMixin, Base):
    __tablename__ = "users"

    google_sub: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    avatar_url: Mapped[str | None] = mapped_column(String(1024), nullable=True)

    sessions = relationship("Session", back_populates="user", cascade="all,delete-orphan")
    devices = relationship("Device", back_populates="user", cascade="all,delete-orphan")
    synced_repositories = relationship(
        "SyncedRepository", back_populates="user", cascade="all,delete-orphan"
    )
    project_contexts = relationship(
        "ProjectContext", back_populates="user", cascade="all,delete-orphan"
    )
    tasks = relationship("Task", back_populates="user", cascade="all,delete-orphan")
