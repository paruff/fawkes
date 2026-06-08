"""Tracer Bullet — Hello World FastAPI service.

Minimal service to validate the full deployment pipeline:
code → Docker build → push → K8s manifest update → ArgoCD sync → running service.
"""

from fastapi import FastAPI
from prometheus_client import Counter, Histogram, make_asgi_app

app = FastAPI(title="tracer-bullet", version="0.1.0")

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
async def track_metrics(request, call_next):
    import time

    method = request.method
    path = request.url.path
    start = time.perf_counter()

    response = await call_next(request)

    elapsed = time.perf_counter() - start
    REQUEST_COUNT.labels(method=method, endpoint=path, status=response.status_code).inc()
    REQUEST_LATENCY.labels(method=method, endpoint=path).observe(elapsed)
    return response


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------
@app.get("/")
async def root():
    return {"message": "Hello from the tracer bullet!", "version": "0.1.0"}


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/ready")
async def ready():
    return {"status": "ready"}


@app.get("/info")
async def info():
    return {
        "service": "tracer-bullet",
        "version": "0.1.0",
        "description": "Minimal service to validate the Fawkes deployment pipeline",
    }
