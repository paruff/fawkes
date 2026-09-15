"""Fawkes Telemetry Engine — consolidated telemetry domain monolith.

Combines: VSM, Analytics Dashboard, Anomaly Detection, Smart Alerting,
Discovery Metrics, SPACE Metrics into a single FastAPI application.
"""

from common.health import create_health_endpoint
from common.metrics import mount_metrics
from common.middleware import add_cors_middleware
from fastapi import FastAPI

from .alerting.router import router as alerting_router
from .analytics.router import router as analytics_router
from .anomaly.router import router as anomaly_router
from .discovery.router import router as discovery_router
from .space.router import router as space_router
from .vsm.router import router as vsm_router

__version__ = "0.1.0"

app = FastAPI(
    title="Fawkes Telemetry Engine",
    description="Consolidated telemetry domain — VSM, Analytics, Anomaly Detection, Alerting, Discovery, SPACE",
    version=__version__,
)

# Shared middleware
add_cors_middleware(app)

# Health endpoint
create_health_endpoint(app, service_name="fawkes-telemetry-engine", version=__version__)

# Prometheus metrics
mount_metrics(app)

# Mount sub-module routers
app.include_router(vsm_router)
app.include_router(analytics_router)
app.include_router(anomaly_router)
app.include_router(alerting_router)
app.include_router(discovery_router)
app.include_router(space_router)
