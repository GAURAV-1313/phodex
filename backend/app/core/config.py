from functools import lru_cache

from pydantic import Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_SUPPORTED_WORKER_ENGINES = {"fake", "codex", "claude"}


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
    allowed_origins: str = Field(
        default="http://localhost:3000,http://localhost:5173,http://10.0.2.2:8000",
        alias="ALLOWED_ORIGINS",
    )

    database_url: str = Field(
        default="postgresql+asyncpg://postgres:postgres@localhost:5432/phodex",
        alias="DATABASE_URL",
    )
    alembic_database_url: str | None = Field(default=None, alias="ALEMBIC_DATABASE_URL")
    redis_url: str | None = Field(default=None, alias="REDIS_URL")
    redis_channel: str = Field(default="phodex:task-events", alias="REDIS_EVENT_CHANNEL")
    cache_ttl_seconds: int = Field(default=30, alias="CACHE_TTL_SECONDS")
    auth_rate_limit_per_minute: int = Field(default=10, alias="AUTH_RATE_LIMIT_PER_MINUTE")
    task_rate_limit_per_minute: int = Field(default=30, alias="TASK_RATE_LIMIT_PER_MINUTE")
    metrics_enabled: bool = Field(default=True, alias="METRICS_ENABLED")
    otel_exporter_otlp_endpoint: str | None = Field(
        default=None, alias="OTEL_EXPORTER_OTLP_ENDPOINT"
    )

    jwt_secret_key: str = Field(default="change-me-in-production", alias="JWT_SECRET_KEY")
    jwt_algorithm: str = Field(default="HS256", alias="JWT_ALGORITHM")
    access_token_ttl_minutes: int = Field(default=60 * 24 * 7, alias="ACCESS_TOKEN_TTL_MINUTES")
    max_active_sessions_per_user: int = Field(default=0, alias="MAX_ACTIVE_SESSIONS_PER_USER")
    max_concurrent_tasks_per_user: int = Field(default=0, alias="MAX_CONCURRENT_TASKS_PER_USER")

    google_client_id: str | None = Field(default=None, alias="GOOGLE_CLIENT_ID")
    allow_insecure_test_tokens: bool = Field(default=False, alias="ALLOW_INSECURE_TEST_TOKENS")

    settings_encryption_key: str | None = Field(default=None, alias="SETTINGS_ENCRYPTION_KEY")

    auto_create_schema: bool = Field(default=False, alias="AUTO_CREATE_SCHEMA")
    fake_worker_step_delay_seconds: float = Field(
        default=0.35, alias="FAKE_WORKER_STEP_DELAY_SECONDS"
    )
    worker_engine: str = Field(default="fake", alias="WORKER_ENGINE")

    @field_validator("worker_engine")
    @classmethod
    def _normalize_worker_engine(cls, value: str) -> str:
        normalized = value.strip().lower()
        if normalized not in _SUPPORTED_WORKER_ENGINES:
            raise ValueError(
                f"Unsupported WORKER_ENGINE='{value}'. "
                f"Use one of: {', '.join(sorted(_SUPPORTED_WORKER_ENGINES))}."
            )
        return normalized

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

    claude_command: str = Field(default="claude", alias="CLAUDE_COMMAND")
    claude_extra_args: str = Field(default="", alias="CLAUDE_EXTRA_ARGS")
    claude_permission_mode: str = Field(
        default="bypassPermissions", alias="CLAUDE_PERMISSION_MODE"
    )
    claude_timeout_seconds: float = Field(default=1800.0, alias="CLAUDE_TIMEOUT_SECONDS")
    claude_require_initial_approval: bool = Field(
        default=True, alias="CLAUDE_REQUIRE_INITIAL_APPROVAL"
    )
    claude_initial_approval_risk_level: str = Field(
        default="medium", alias="CLAUDE_INITIAL_APPROVAL_RISK_LEVEL"
    )
    claude_default_workdir: str | None = Field(default=None, alias="CLAUDE_DEFAULT_WORKDIR")

    @property
    def cors_origins(self) -> list[str]:
        return [origin.strip() for origin in self.allowed_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
