"""Fawkes DevEx Service — consolidated developer experience domain monolith.

Combines: Feedback, Feedback Bot, NPS Surveys, DevEx Survey Automation,
Insights, Experimentation into a single FastAPI application.
"""

from common.health import create_health_endpoint
from common.metrics import mount_metrics
from common.middleware import add_cors_middleware
from fastapi import FastAPI

from .experimentation.router import router as experimentation_router
from .feedback.router import router as feedback_router
from .feedback_bot.router import router as feedback_bot_router
from .insights.router import router as insights_router
from .nps.router import router as nps_router
from .survey.router import router as survey_router

__version__ = "0.1.0"

app = FastAPI(
    title="Fawkes DevEx Service",
    description="Consolidated DevEx domain — Feedback, NPS, Surveys, Insights, Experimentation",
    version=__version__,
)

# Shared middleware
add_cors_middleware(app)

# Health endpoint
create_health_endpoint(app, service_name="fawkes-devex-service", version=__version__)

# Prometheus metrics
mount_metrics(app)

# Mount sub-module routers
app.include_router(feedback_router)
app.include_router(feedback_bot_router)
app.include_router(nps_router)
app.include_router(survey_router)
app.include_router(insights_router)
app.include_router(experimentation_router)
