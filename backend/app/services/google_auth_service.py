from dataclasses import dataclass

from fastapi.concurrency import run_in_threadpool
from google.auth.transport import requests
from google.oauth2 import id_token

from app.core.config import Settings
from app.services.exceptions import UnauthorizedError


@dataclass
class GoogleProfile:
    google_sub: str
    email: str
    name: str
    avatar_url: str | None


class GoogleAuthService:
    def __init__(self, settings: Settings) -> None:
        self._settings = settings

    async def verify_id_token(self, token: str) -> GoogleProfile:
        if self._settings.allow_insecure_test_tokens and token.startswith("test-token|"):
            parts = token.split("|", maxsplit=4)
            if len(parts) < 4:
                raise UnauthorizedError("Invalid test token format")
            google_sub = parts[1]
            email = parts[2]
            name = parts[3]
            avatar_url = parts[4] if len(parts) == 5 else None
            return GoogleProfile(
                google_sub=google_sub,
                email=email,
                name=name,
                avatar_url=avatar_url,
            )

        if not self._settings.google_client_id:
            raise UnauthorizedError("GOOGLE_CLIENT_ID is not configured")

        try:
            claims = await run_in_threadpool(
                id_token.verify_oauth2_token,
                token,
                requests.Request(),
                self._settings.google_client_id,
            )
        except Exception as exc:
            raise UnauthorizedError("Unable to verify Google ID token") from exc

        sub = claims.get("sub")
        email = claims.get("email")
        if not sub or not email:
            raise UnauthorizedError("Google token missing required claims")

        return GoogleProfile(
            google_sub=sub,
            email=email,
            name=claims.get("name", email),
            avatar_url=claims.get("picture"),
        )
