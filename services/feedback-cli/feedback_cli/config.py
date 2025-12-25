"""Configuration management for Feedback CLI."""

import os
from pathlib import Path
from typing import Optional

import yaml
from pydantic import BaseModel, Field


class FeedbackConfig(BaseModel):
    """Configuration for Feedback CLI."""

    api_url: str = Field(
        default="http://feedback-service.fawkes.svc.cluster.local:8000",
        description="URL of the feedback API service",
    )
    api_key: Optional[str] = Field(
        default=None,
        description="API key for authentication (if required)",
    )
    default_category: str = Field(
        default="General",
        description="Default category for feedback",
    )
    author: Optional[str] = Field(
        default=None,
        description="Default author name (uses git config if not set)",
    )
    offline_mode: bool = Field(
        default=True,
        description="Enable offline queue for when service is unavailable",
    )
    queue_path: Optional[str] = Field(
        default=None,
        description="Path to offline queue file (defaults to ~/.fawkes-feedback/queue.json)",
    )


class ConfigManager:
    """Manages configuration for Feedback CLI."""

    def __init__(self, config_path: Optional[Path] = None):
        """Initialize config manager.

        Args:
            config_path: Path to configuration file (defaults to ~/.fawkes-feedback/config.yaml)
        """
        if config_path is None:
            config_path = Path.home() / ".fawkes-feedback" / "config.yaml"
        self.config_path = config_path
        self._config: Optional[FeedbackConfig] = None

    def load(self) -> FeedbackConfig:
        """Load configuration from file or environment."""
        # Try to load from file
        if self.config_path.exists():
            with open(self.config_path, "r") as f:
                config_data = yaml.safe_load(f) or {}
        else:
            config_data = {}

        # Override with environment variables
        if os.getenv("FEEDBACK_API_URL"):
            config_data["api_url"] = os.getenv("FEEDBACK_API_URL")
        if os.getenv("FEEDBACK_API_KEY"):
            config_data["api_key"] = os.getenv("FEEDBACK_API_KEY")
        if os.getenv("FEEDBACK_AUTHOR"):
            config_data["author"] = os.getenv("FEEDBACK_AUTHOR")
        if os.getenv("FEEDBACK_OFFLINE_MODE"):
            config_data["offline_mode"] = os.getenv("FEEDBACK_OFFLINE_MODE").lower() in ["true", "1", "yes"]

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

        # If queue path not set, use default
        if not config_data.get("queue_path"):
            config_data["queue_path"] = str(Path.home() / ".fawkes-feedback" / "queue.json")

        self._config = FeedbackConfig(**config_data)
        return self._config

    def save(self, config: FeedbackConfig) -> None:
        """Save configuration to file.

        Args:
            config: Configuration to save
        """
        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_path, "w") as f:
            yaml.safe_dump(config.model_dump(exclude_none=True), f, default_flow_style=False)
        self._config = config

    @property
    def config(self) -> FeedbackConfig:
        """Get current configuration (loads if not already loaded)."""
        if self._config is None:
            return self.load()
        return self._config
