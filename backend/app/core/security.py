from datetime import UTC, datetime, timedelta
from uuid import UUID

from jose import JWTError, jwt

from app.core.config import Settings


class TokenError(Exception):
    pass


class JWTManager:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    def create_access_token(
        self, user_id: UUID, jti: UUID, expires_delta: timedelta | None = None
    ) -> tuple[str, datetime]:
        expire_at = datetime.now(UTC) + (
            expires_delta or timedelta(minutes=self._settings.access_token_ttl_minutes)
        )
        payload = {
            "sub": str(user_id),
            "jti": str(jti),
            "exp": expire_at,
        }
        token = jwt.encode(
            payload, self._settings.jwt_secret_key, algorithm=self._settings.jwt_algorithm
        )
        return token, expire_at

    def decode_access_token(self, token: str) -> dict:
        try:
            return dict(
                jwt.decode(
                    token,
                    self._settings.jwt_secret_key,
                    algorithms=[self._settings.jwt_algorithm],
                )
            )
        except JWTError as exc:
            raise TokenError("Invalid access token") from exc
