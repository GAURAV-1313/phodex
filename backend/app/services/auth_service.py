from datetime import datetime
from uuid import UUID, uuid4

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from app.core.config import Settings
from app.core.security import JWTManager, TokenError, hash_password, verify_password
from app.models.session import Session
from app.models.user import User
from app.services.exceptions import ConflictError, LimitExceededError, UnauthorizedError
from app.services.google_auth_service import GoogleProfile
from app.utils.datetime import coerce_utc, utcnow


class AuthService:
    def __init__(
        self,
        session_factory: async_sessionmaker[AsyncSession],
        jwt_manager: JWTManager,
        settings: Settings,
    ) -> None:
        self._session_factory = session_factory
        self._jwt_manager = jwt_manager
        self._settings = settings

    async def login_with_google_profile(self, profile: GoogleProfile) -> tuple[str, datetime, User]:
        async with self._session_factory() as session:
            user = await session.scalar(select(User).where(User.google_sub == profile.google_sub))
            if user is None:
                user = User(
                    google_sub=profile.google_sub,
                    email=profile.email,
                    name=profile.name,
                    avatar_url=profile.avatar_url,
                )
                session.add(user)
            else:
                user.email = profile.email
                user.name = profile.name
                user.avatar_url = profile.avatar_url

            await session.flush()
            token, expires_at = await self._issue_token(session, user)
            await session.commit()
            await session.refresh(user)
            return token, expires_at, user

    async def _issue_token(self, session: AsyncSession, user: User) -> tuple[str, datetime]:
        max_sessions = self._settings.max_active_sessions_per_user
        if max_sessions > 0:
            active_sessions = await session.scalar(
                select(func.count(Session.id)).where(
                    Session.user_id == user.id,
                    Session.revoked_at.is_(None),
                    Session.expires_at > utcnow(),
                )
            )
            if int(active_sessions or 0) >= max_sessions:
                raise LimitExceededError(
                    "Active session limit reached",
                    code="SESSION_LIMIT_REACHED",
                )
        jti = uuid4()
        token, expires_at = self._jwt_manager.create_access_token(user.id, jti)
        db_session = Session(
            user=user,
            jwt_jti=str(jti),
            expires_at=expires_at,
            created_at=utcnow(),
        )
        session.add(db_session)
        return token, expires_at

    async def register_with_password(
        self, email: str, password: str, name: str
    ) -> tuple[str, datetime, User]:
        async with self._session_factory() as session:
            existing = await session.scalar(select(User).where(User.email == email))
            if existing is not None:
                raise ConflictError("An account with this email already exists")
            user = User(
                email=email,
                name=name,
                password_hash=hash_password(password),
            )
            session.add(user)
            await session.flush()
            token, expires_at = await self._issue_token(session, user)
            await session.commit()
            await session.refresh(user)
            return token, expires_at, user

    async def login_with_password(
        self, email: str, password: str
    ) -> tuple[str, datetime, User]:
        async with self._session_factory() as session:
            user = await session.scalar(select(User).where(User.email == email))
            if user is None or not user.password_hash or not verify_password(password, user.password_hash):
                raise UnauthorizedError("Invalid email or password")
            token, expires_at = await self._issue_token(session, user)
            await session.commit()
            await session.refresh(user)
            return token, expires_at, user

    async def get_user_from_bearer(self, bearer_token: str) -> User:
        token = bearer_token.removeprefix("Bearer ").strip()
        if not token:
            raise UnauthorizedError("Missing token")

        try:
            payload = self._jwt_manager.decode_access_token(token)
        except TokenError as exc:
            raise UnauthorizedError("Invalid access token") from exc

        sub = payload.get("sub")
        jti = payload.get("jti")
        if not sub or not jti:
            raise UnauthorizedError("Token missing required claims")

        try:
            user_id = UUID(sub)
        except ValueError as exc:
            raise UnauthorizedError("Token subject is invalid") from exc

        async with self._session_factory() as session:
            db_session = await session.scalar(select(Session).where(Session.jwt_jti == str(jti)))
            if db_session is None or db_session.revoked_at is not None:
                raise UnauthorizedError("Session not found or revoked")

            if coerce_utc(db_session.expires_at) < utcnow():
                raise UnauthorizedError("Session expired")

            user = await session.get(User, user_id)
            if user is None:
                raise UnauthorizedError("User not found")

            return user

    async def get_current_session(self, bearer_token: str) -> Session:
        token = bearer_token.removeprefix("Bearer ").strip()
        if not token:
            raise UnauthorizedError("Missing token")

        try:
            payload = self._jwt_manager.decode_access_token(token)
        except TokenError as exc:
            raise UnauthorizedError("Invalid access token") from exc

        jti = payload.get("jti")
        if not jti:
            raise UnauthorizedError("Token missing required claims")

        async with self._session_factory() as session:
            db_session = await session.scalar(select(Session).where(Session.jwt_jti == str(jti)))
            if db_session is None or db_session.revoked_at is not None:
                raise UnauthorizedError("Session not found or revoked")

            if coerce_utc(db_session.expires_at) < utcnow():
                raise UnauthorizedError("Session expired")

            return db_session
