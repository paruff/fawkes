"""Fawkes DevEx Service: one FastAPI app, one router per migrated module (ADR-039)."""

from fastapi import FastAPI
from fawkes_common.config import ServiceSettings
from fawkes_common.logging import configure_logging
from fawkes_common.metrics import add_metrics_route


class Settings(ServiceSettings):
    """This monolith's settings."""

    service_name: str = "fawkes-devex-service"


configure_logging()
settings = Settings()
app = FastAPI(title="Fawkes DevEx Service", version=settings.version)
add_metrics_route(app)


@app.get("/health")
def health() -> dict[str, str]:
    """Report that the process is serving requests.

    Returns:
        Status, service name and version.
    """
    return {"status": "healthy", "service": settings.service_name, "version": settings.version}
