"""Shared Pydantic models for Fawkes platform services."""

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Standard health check response.

    Each service adds its own connectivity fields (database_connected,
    prometheus_connected, etc.) by extending or using this as-is.
    """

    status: str = Field(..., description="Service status: healthy, degraded, or unhealthy")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    database_connected: bool = Field(default=False, description="Database connectivity status")


class ErrorResponse(BaseModel):
    """Standard error response."""

    detail: str
    status_code: int
