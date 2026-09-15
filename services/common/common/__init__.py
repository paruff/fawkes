"""Fawkes Common — shared library for platform services."""

from .config import BaseSettings
from .health import create_health_endpoint
from .metrics import mount_metrics
from .middleware import add_cors_middleware
from .models import ErrorResponse, HealthResponse

__all__ = [
    "BaseSettings",
    "ErrorResponse",
    "HealthResponse",
    "add_cors_middleware",
    "create_health_endpoint",
    "mount_metrics",
]
