"""Base settings for Fawkes platform services."""

import os
from typing import List

from pydantic_settings import BaseSettings as _BaseSettings
from pydantic_settings import SettingsConfigDict


class BaseSettings(_BaseSettings):
    """Base settings class with common fields for all Fawkes services.

    Extend this in each service's config.py to add domain-specific settings.
    """

    service_name: str
    version: str = "0.1.0"
    debug: bool = False
    cors_origins: list[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )
