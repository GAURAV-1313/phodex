from pydantic import BaseModel, Field


class RegisterPushTokenRequest(BaseModel):
    fcm_token: str = Field(min_length=1)
    platform: str = Field(min_length=1)


class UnregisterPushTokenRequest(BaseModel):
    fcm_token: str = Field(min_length=1)
