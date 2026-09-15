"""Standardized health endpoint factory for Fawkes platform services."""

from typing import Callable, Optional

from fastapi import FastAPI

from .models import HealthResponse


def create_health_endpoint(
    app: FastAPI,
    service_name: str,
    version: str,
    check_db: Callable[[], bool] | None = None,
    path: str = "/health",
) -> None:
    """Create a standardized health check endpoint.

    Args:
        app: The FastAPI application instance.
        service_name: Name of the service.
        version: Version string.
        check_db: Optional callable that returns True if DB is connected.
        path: Health endpoint path. Defaults to "/health".
    """

    @app.get(path, response_model=HealthResponse)
    async def health_check() -> HealthResponse:
        db_connected = check_db() if check_db else False
        return HealthResponse(
            status="healthy",
            service=service_name,
            version=version,
            database_connected=db_connected,
        )
