from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "Kumi API"
    app_version: str = "1.0.0"
    debug: bool = False

    database_url: str = "sqlite:///./kumi.db"
    jwt_secret: str = "dev-only-secret-change-me"
    jwt_algorithm: str = "HS256"
    jwt_expire_days: int = 7

    google_client_id: str = ""
    cors_origins: str = "*"


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
