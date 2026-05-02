from functools import lru_cache

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
        populate_by_name=True,
    )

    app_name: str = "Phodex Backend"
    environment: str = "development"
    debug: bool = False
    log_level: str = "INFO"

    database_url: str = Field(
        default="postgresql+asyncpg://postgres:postgres@localhost:5432/phodex",
        alias="DATABASE_URL",
    )
    alembic_database_url: str | None = Field(default=None, alias="ALEMBIC_DATABASE_URL")

    jwt_secret_key: str = Field(default="change-me-in-production", alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    access_token_ttl_minutes: int = Field(default=60 * 24 * 7, alias="ACCESS_TOKEN_TTL_MINUTES")
    max_active_sessions_per_user: int = Field(default=0, alias="MAX_ACTIVE_SESSIONS_PER_USER")
    max_concurrent_tasks_per_user: int = Field(default=0, alias="MAX_CONCURRENT_TASKS_PER_USER")

    google_client_id: str | None = Field(default=None, alias="GOOGLE_CLIENT_ID")
    allow_insecure_test_tokens: bool = Field(default=False, alias="ALLOW_INSECURE_TEST_TOKENS")

    auto_create_schema: bool = Field(default=False, alias="AUTO_CREATE_SCHEMA")
    fake_worker_step_delay_seconds: float = Field(
        default=0.35, alias="FAKE_WORKER_STEP_DELAY_SECONDS"
    )
    worker_engine: str = Field(default="fake", alias="WORKER_ENGINE")

    codex_command: str = Field(default="codex", alias="CODEX_COMMAND")
    codex_args: str = Field(default="", alias="CODEX_ARGS")
    codex_prompt_stdin: bool = Field(default=True, alias="CODEX_PROMPT_STDIN")
    codex_timeout_seconds: float = Field(default=1800.0, alias="CODEX_TIMEOUT_SECONDS")
    codex_require_initial_approval: bool = Field(
        default=True, alias="CODEX_REQUIRE_INITIAL_APPROVAL"
    )
    codex_initial_approval_risk_level: str = Field(
        default="medium", alias="CODEX_INITIAL_APPROVAL_RISK_LEVEL"
    )
    codex_default_workdir: str | None = Field(default=None, alias="CODEX_DEFAULT_WORKDIR")


@lru_cache
def get_settings() -> Settings:
    return Settings()
