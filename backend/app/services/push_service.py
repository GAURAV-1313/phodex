from uuid import UUID

import httpx
from fastapi.concurrency import run_in_threadpool
from google.auth.transport.requests import Request as GoogleAuthRequest
from google.oauth2.service_account import Credentials
from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.models.push_subscription import PushSubscription

_FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging"


class PushService:
    """Sends real push notifications via the FCM HTTP v1 API directly
    (service-account OAuth2 via google-auth + a plain HTTP POST via httpx)
    rather than the full firebase-admin SDK — that SDK's Firestore/Storage
    clients drag in a protobuf version that conflicts with this project's
    pinned OpenTelemetry stack, and Phodex only ever needs to send messages.

    Entirely best-effort: unconfigured or failing push must never break the
    task/approval flow that triggered it, matching this codebase's existing
    pattern for optional infrastructure (see RedisService.enabled).
    """

    def __init__(
        self, session_factory: async_sessionmaker[AsyncSession], settings: Settings
    ) -> None:
        self._session_factory = session_factory
        self._settings = settings
        self._credentials: Credentials | None = None
        if settings.firebase_service_account_json and settings.firebase_project_id:
            try:
                self._credentials = Credentials.from_service_account_file(
                    settings.firebase_service_account_json, scopes=[_FCM_SCOPE]
                )
            except (OSError, ValueError):
                self._credentials = None

    @property
    def enabled(self) -> bool:
        return self._credentials is not None

    async def register_token(self, user_id: UUID, fcm_token: str, platform: str) -> None:
        async with self._session_factory() as session:
            existing = await session.scalar(
                select(PushSubscription).where(PushSubscription.fcm_token == fcm_token)
            )
            if existing is not None:
                existing.user_id = user_id
                existing.platform = platform
            else:
                session.add(
                    PushSubscription(user_id=user_id, fcm_token=fcm_token, platform=platform)
                )
            await session.commit()

    async def unregister_token(self, user_id: UUID, fcm_token: str) -> None:
        async with self._session_factory() as session:
            await session.execute(
                delete(PushSubscription).where(
                    PushSubscription.fcm_token == fcm_token,
                    PushSubscription.user_id == user_id,
                )
            )
            await session.commit()

    async def notify_user(
        self, user_id: UUID, title: str, body: str, data: dict[str, str] | None = None
    ) -> None:
        if not self.enabled:
            return

        async with self._session_factory() as session:
            tokens = (
                (
                    await session.execute(
                        select(PushSubscription.fcm_token).where(
                            PushSubscription.user_id == user_id
                        )
                    )
                )
                .scalars()
                .all()
            )
        if not tokens:
            return

        for token in tokens:
            try:
                await run_in_threadpool(self._send_sync, token, title, body, data or {})
            except Exception:
                # Best-effort: a dead/unregistered token or a transient FCM
                # error must never surface to the caller's own request flow.
                continue

    def _send_sync(self, token: str, title: str, body: str, data: dict[str, str]) -> None:
        assert self._credentials is not None
        self._credentials.refresh(GoogleAuthRequest())
        response = httpx.post(
            f"https://fcm.googleapis.com/v1/projects/{self._settings.firebase_project_id}"
            "/messages:send",
            headers={"Authorization": f"Bearer {self._credentials.token}"},
            json={
                "message": {
                    "token": token,
                    "notification": {"title": title, "body": body},
                    "data": data,
                }
            },
            timeout=10.0,
        )
        response.raise_for_status()
