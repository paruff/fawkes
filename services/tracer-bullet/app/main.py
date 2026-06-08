"""Tracer Bullet — Hello World FastAPI service.

Minimal service to validate the full deployment pipeline:
code → Docker build → push → K8s manifest update → ArgoCD sync → running service.
"""

import logging
import time
from typing import Callable

from fastapi import FastAPI, Request, Response
from prometheus_client import Counter, Histogram, make_asgi_app

from app import __version__

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
logger = logging.getLogger(__name__)

app = FastAPI(title="tracer-bullet", version=__version__)

# ---------------------------------------------------------------------------
# Prometheus metrics
# ---------------------------------------------------------------------------
REQUEST_COUNT = Counter(
    "http_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
)
REQUEST_LATENCY = Histogram(
    "http_request_duration_seconds",
    "HTTP request latency in seconds",
    ["method", "endpoint"],
)

# Mount Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


# ---------------------------------------------------------------------------
# Middleware — track every request
# ---------------------------------------------------------------------------
@app.middleware("http")
async def track_metrics(request: Request, call_next: Callable) -> Response:
    method = request.method
    path = request.url.path
    start = time.perf_counter()

    response = await call_next(request)

    elapsed = time.perf_counter() - start
    REQUEST_COUNT.labels(method=method, endpoint=path, status=response.status_code).inc()
    REQUEST_LATENCY.labels(method=method, endpoint=path).observe(elapsed)
    logger.info("%s %s %d %.3fs", method, path, response.status_code, elapsed)
    return response


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.get("/")
async def root() -> dict:
    return {"message": "Hello from the tracer bullet!", "version": __version__}


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


@app.get("/ready")
async def ready() -> dict:
    return {"status": "ready"}


@app.get("/info")
async def info() -> dict:
    return {
        "service": "tracer-bullet",
        "version": __version__,
        "description": "Minimal service to validate the Fawkes deployment pipeline",
    }
