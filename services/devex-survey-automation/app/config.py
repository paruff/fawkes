"""
Configuration management for DevEx Survey Automation Service
"""
import os
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings from environment variables"""
    
    # Service
    service_name: str = "devex-survey-automation"
    version: str = "1.0.0"
    debug: bool = False
    
    # Database
    database_url: str = os.getenv(
        "DATABASE_URL",
        "postgresql://devex:devex@db-devex-dev-rw.fawkes.svc.cluster.local:5432/devex_surveys"
    )
    
    # Integrations
    space_metrics_url: str = os.getenv(
        "SPACE_METRICS_URL",
        "http://space-metrics.fawkes.svc:8000"
    )
    nps_service_url: str = os.getenv(
        "NPS_SERVICE_URL",
        "http://nps-service.fawkes.svc:8000"
    )
    
    # Mattermost
    mattermost_url: str = os.getenv(
        "MATTERMOST_URL",
        "http://mattermost.fawkes.svc:8065"
    )
    mattermost_token: Optional[str] = os.getenv("MATTERMOST_TOKEN")
    mattermost_bot_user_id: Optional[str] = os.getenv("MATTERMOST_BOT_USER_ID")
    
    # Slack (optional)
    slack_bot_token: Optional[str] = os.getenv("SLACK_BOT_TOKEN")
    slack_signing_secret: Optional[str] = os.getenv("SLACK_SIGNING_SECRET")
    
    # Email (optional)
    smtp_host: Optional[str] = os.getenv("SMTP_HOST")
    smtp_port: int = int(os.getenv("SMTP_PORT", "587"))
    smtp_user: Optional[str] = os.getenv("SMTP_USER")
    smtp_password: Optional[str] = os.getenv("SMTP_PASSWORD")
    from_email: str = os.getenv("FROM_EMAIL", "Fawkes DevEx <surveys@fawkes.idp>")
    
    # Survey Settings
    survey_base_url: str = os.getenv("SURVEY_BASE_URL", "http://localhost:8000")
    pulse_survey_day: str = os.getenv("PULSE_SURVEY_DAY", "monday")
    pulse_survey_hour: int = int(os.getenv("PULSE_SURVEY_HOUR", "9"))
    reminder_days: int = int(os.getenv("REMINDER_DAYS", "2"))
    survey_expiry_days: int = int(os.getenv("SURVEY_EXPIRY_DAYS", "7"))
    
    # CORS
    allowed_origins: str = os.getenv("ALLOWED_ORIGINS", "*")
    
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False
    )


settings = Settings()
