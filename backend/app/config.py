from functools import lru_cache

from pydantic import model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Kumi API"
    app_version: str = "1.0.0"
    debug: bool = False

    database_url: str = "sqlite:///./kumi.db"
    jwt_secret: str = ""
    jwt_algorithm: str = "HS256"
    jwt_expire_days: int = 7

    google_client_id: str = ""
    cors_origins: str = "http://localhost:8080"

    # Seed achievements/dialogs on startup (idempotent). Disable in tests.
    auto_seed: bool = True

    # Fallback offset in minutes when the client does not send X-Timezone-Offset.
    default_tz_offset_minutes: int = 0

    @model_validator(mode="after")
    def validate_jwt_secret(self) -> "Settings":
        if len(self.jwt_secret) < 32:
            raise ValueError(
                "JWT_SECRET wajib diisi minimal 32 karakter. "
                "Jalankan `openssl rand -hex 32` lalu isi di .env."
            )
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()


def cors_origin_list() -> list[str]:
    """Parse comma separated origins, `*` means allow all."""
    raw = settings.cors_origins.strip()
    if raw == "*" or raw == "":
        return ["*"]
    return [origin.strip() for origin in raw.split(",") if origin.strip()]
