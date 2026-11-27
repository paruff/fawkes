"""Prometheus exposition."""

from fastapi import FastAPI
from fastapi.responses import Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest


def add_metrics_route(app: FastAPI) -> None:
    """Serve the default Prometheus registry at /metrics."""

    @app.get("/metrics", include_in_schema=False)
    def metrics() -> Response:
        return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)
