
from enum import StrEnum
from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class AppMode(StrEnum):
    STANDALONE = "standalone"   # BP Monitor seul
    INTEGRATED = "integrated"   # Connecté à Vitoo Santé


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Application
    app_name: str = "BP Monitor"
    app_version: str = "1.0.0"
    app_mode: AppMode = AppMode.STANDALONE
    debug: bool = False

    # API
    api_prefix: str = "/api/v1"
    allowed_origins: list[str] = ["*"]

    # Base de données
    database_url: str = "postgresql+asyncpg://user:password@localhost:5432/bp_monitor"
    db_pool_size: int = 10
    db_max_overflow: int = 20

    # Redis
    redis_url: str = "redis://localhost:6379/0"

    # JWT
    jwt_secret_key: str = "change-me-in-production"
    jwt_algorithm: str = "HS256"
    jwt_access_token_expire_minutes: int = 60
    jwt_refresh_token_expire_days: int = 7

    # Notifications
    twilio_account_sid: str = ""
    twilio_auth_token: str = ""
    twilio_from_number: str = ""
    fcm_server_key: str = ""

    # Mode intégré — Vitoo Santé
    vitoo_api_url: str = ""
    vitoo_api_key: str = ""

    # Seuils BP par défaut (mmHg)
    bp_threshold_elevated_systolic: int = 130
    bp_threshold_elevated_diastolic: int = 85
    bp_threshold_high_systolic: int = 140
    bp_threshold_high_diastolic: int = 90
    bp_threshold_critical_systolic: int = 180
    bp_threshold_critical_diastolic: int = 110


@lru_cache
def get_settings() -> Settings:
    return Settings()