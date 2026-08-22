from uuid import UUID

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.core.crypto import decrypt_secret, encrypt_secret
from app.models.user_ai_settings import UserAiSettings


class UserAiSettingsService:
    """Per-user AI provider overrides.

    Optional by design: if a user never sets anything here, the Codex/Claude
    CLI subprocess behaves exactly as it does today — inheriting whatever
    auth is already configured on this machine (`codex login`/`claude
    login`). A key set here only overrides that for this user's tasks.
    """

    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        settings: Settings,
    ) -> None:
        self._session_factory = session_factory
        self._settings = settings

    async def get_decrypted(self, user_id: UUID) -> UserAiSettings | None:
        """Internal use only (subprocess env building) — never expose decrypted keys over the API."""
        async with self._session_factory() as session:
            row: UserAiSettings | None = await session.scalar(
                select(UserAiSettings).where(UserAiSettings.user_id == user_id)
            )
            return row

    def decrypt_anthropic_key(self, settings_row: UserAiSettings) -> str | None:
        if not settings_row.anthropic_api_key_encrypted:
            return None
        return decrypt_secret(self._settings, settings_row.anthropic_api_key_encrypted)

    def decrypt_openai_key(self, settings_row: UserAiSettings) -> str | None:
        if not settings_row.openai_api_key_encrypted:
            return None
        return decrypt_secret(self._settings, settings_row.openai_api_key_encrypted)

    async def get_status(self, user_id: UUID) -> dict:
        row = await self.get_decrypted(user_id)
        if row is None:
            return {
                "has_anthropic_key": False,
                "has_openai_key": False,
                "preferred_claude_model": None,
                "preferred_codex_model": None,
            }
        return {
            "has_anthropic_key": bool(row.anthropic_api_key_encrypted),
            "has_openai_key": bool(row.openai_api_key_encrypted),
            "preferred_claude_model": row.preferred_claude_model,
            "preferred_codex_model": row.preferred_codex_model,
        }

    async def update(
        self,
        user_id: UUID,
        *,
        anthropic_api_key: str | None,
        openai_api_key: str | None,
        clear_anthropic_key: bool,
        clear_openai_key: bool,
        preferred_claude_model: str | None,
        preferred_codex_model: str | None,
    ) -> dict:
        async with self._session_factory() as session:
            row = await session.scalar(
                select(UserAiSettings).where(UserAiSettings.user_id == user_id)
            )
            if row is None:
                row = UserAiSettings(user_id=user_id)
                session.add(row)

            if clear_anthropic_key:
                row.anthropic_api_key_encrypted = None
            elif anthropic_api_key:
                row.anthropic_api_key_encrypted = encrypt_secret(self._settings, anthropic_api_key)

            if clear_openai_key:
                row.openai_api_key_encrypted = None
            elif openai_api_key:
                row.openai_api_key_encrypted = encrypt_secret(self._settings, openai_api_key)

            if preferred_claude_model is not None:
                row.preferred_claude_model = preferred_claude_model or None
            if preferred_codex_model is not None:
                row.preferred_codex_model = preferred_codex_model or None

            await session.commit()

        return await self.get_status(user_id)
