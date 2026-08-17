from pydantic import BaseModel


class AiSettingsStatusResponse(BaseModel):
    has_anthropic_key: bool
    has_openai_key: bool
    preferred_claude_model: str | None
    preferred_codex_model: str | None


class AiSettingsUpdateRequest(BaseModel):
    anthropic_api_key: str | None = None
    openai_api_key: str | None = None
    clear_anthropic_key: bool = False
    clear_openai_key: bool = False
    preferred_claude_model: str | None = None
    preferred_codex_model: str | None = None
