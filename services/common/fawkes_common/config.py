"""Settings every service reads from the environment."""

from pydantic_settings import BaseSettings, SettingsConfigDict


class ServiceSettings(BaseSettings):
    """Base class for a service's settings. Field names match environment variables, ignoring case."""

    # extra="ignore": a shared .env holds other services' keys.
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", case_sensitive=False, extra="ignore")

    service_name: str
    version: str = "0.1.0"
    debug: bool = False
