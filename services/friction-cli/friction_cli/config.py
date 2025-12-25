"""Configuration management for Friction CLI."""

import os
from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseModel, Field


class FrictionConfig(BaseModel):
    """Configuration for Friction CLI."""

    api_url: str = Field(
        default="http://insights-service.fawkes.svc.cluster.local:8000",
        description="URL of the insights API service",
    )
    api_key: Optional[str] = Field(
        default=None,
        description="API key for authentication (if required)",
    )
    default_category: str = Field(
        default="Developer Experience",
        description="Default category for friction logs",
    )
    default_priority: str = Field(
        default="medium",
        description="Default priority for friction logs",
    )
    author: Optional[str] = Field(
        default=None,
        description="Default author name (uses git config if not set)",
    )


class ConfigManager:
    """Manages configuration for Friction CLI."""

    def __init__(self, config_path: Optional[Path] = None):
        """Initialize config manager.

        Args:
            config_path: Path to configuration file (defaults to ~/.friction/config.yaml)
        """
        if config_path is None:
            config_path = Path.home() / ".friction" / "config.yaml"
        self.config_path = config_path
        self._config: Optional[FrictionConfig] = None

    def load(self) -> FrictionConfig:
        """Load configuration from file or environment."""
        # Try to load from file
        if self.config_path.exists():
            with open(self.config_path, "r") as f:
                config_data = yaml.safe_load(f) or {}
        else:
            config_data = {}

        # Override with environment variables
        if os.getenv("FRICTION_API_URL"):
            config_data["api_url"] = os.getenv("FRICTION_API_URL")
        if os.getenv("FRICTION_API_KEY"):
            config_data["api_key"] = os.getenv("FRICTION_API_KEY")
        if os.getenv("FRICTION_AUTHOR"):
            config_data["author"] = os.getenv("FRICTION_AUTHOR")

        # If author not set, try to get from git config
        if not config_data.get("author"):
            try:
                import subprocess

                result = subprocess.run(
                    ["git", "config", "user.name"],
                    capture_output=True,
                    text=True,
                    check=False,
                )
                if result.returncode == 0:
                    config_data["author"] = result.stdout.strip()
            except Exception:
                pass

        self._config = FrictionConfig(**config_data)
        return self._config

    def save(self, config: FrictionConfig) -> None:
        """Save configuration to file.

        Args:
            config: Configuration to save
        """
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_path, "w") as f:
            yaml.safe_dump(config.model_dump(exclude_none=True), f, default_flow_style=False)
        self._config = config

    @property
    def config(self) -> FrictionConfig:
        """Get current configuration (loads if not already loaded)."""
        if self._config is None:
            return self.load()
        return self._config
