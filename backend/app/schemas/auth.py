from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr

from app.schemas.common import ORMModel


class GoogleAuthRequest(BaseModel):
    id_token: str


class UserOut(ORMModel):
    id: UUID
    google_sub: str
    email: EmailStr
    name: str
    avatar_url: str | None
    created_at: datetime
    updated_at: datetime


class AuthTokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    expires_at: datetime
    user: UserOut
