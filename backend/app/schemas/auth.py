from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, EmailStr, field_validator

from app.schemas.common import ORMModel


class GoogleAuthRequest(BaseModel):
    id_token: str


class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    name: str

    @field_validator("password")
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError("Password must be at least 8 characters")
        return v


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserOut(ORMModel):
    id: UUID
    google_sub: str | None
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
