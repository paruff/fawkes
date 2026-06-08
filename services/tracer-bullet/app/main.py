"""Tracer Bullet — Hello World FastAPI service.

Minimal service to validate the full deployment pipeline:
code → Docker build → push → K8s manifest update → ArgoCD sync → running service.

Instrumented with:
- OpenTelemetry tracing (OTLP gRPC → Collector → Tempo)
- Prometheus metrics (scraped by Collector/Prometheus)
- Structured logging with trace ID injection
"""

import logging
import os
import time
from typing import Callable

from fastapi import FastAPI, Request, Response
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from prometheus_client import Counter, Histogram, make_asgi_app

from app import __version__

# ---------------------------------------------------------------------------
# OpenTelemetry setup
# ---------------------------------------------------------------------------
SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "tracer-bullet")
DEPLOYMENT_ENV = os.getenv("DEPLOYMENT_ENVIRONMENT", "development")
OTEL_ENDPOINT = os.getenv(
    "OTEL_EXPORTER_OTLP_ENDPOINT",
    "otel-collector-opentelemetry-collector.monitoring.svc.cluster.local:4317",
)

resource = Resource.create(
    {
        "service.name": SERVICE_NAME,
        "service.version": __version__,
        "deployment.environment": DEPLOYMENT_ENV,
    }
)

tracer_provider = TracerProvider(resource=resource)
otlp_exporter = OTLPSpanExporter(endpoint=OTEL_ENDPOINT, insecure=True)
tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
trace.set_tracer_provider(tracer_provider)
tracer = trace.get_tracer(__name__)

# ---------------------------------------------------------------------------
# Structured logging with trace ID injection
# ---------------------------------------------------------------------------
class TraceContextFilter(logging.Filter):
    """Inject current trace/span IDs into every log record."""

    def filter(self, record: logging.LogRecord) -> bool:
        span = trace.get_current_span()
        ctx = span.get_span_context()
        if ctx and ctx.is_valid:
            record.trace_id = format(ctx.trace_id, "032x")
            record.span_id = format(ctx.span_id, "016x")
        else:
            record.trace_id = "0" * 32
            record.span_id = "0" * 16
        return True


logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s [%(name)s] trace_id=%(trace_id)s span_id=%(span_id)s %(message)s",
)
logger = logging.getLogger(__name__)
logger.addFilter(TraceContextFilter())

# ---------------------------------------------------------------------------
# FastAPI app
# ---------------------------------------------------------------------------
app = FastAPI(title="tracer-bullet", version=__version__)

# Auto-instrument FastAPI (creates spans for every request)
FastAPIInstrumentor.instrument_app(app)

# ---------------------------------------------------------------------------
# Prometheus metrics (kept alongside OTEL for dual-visibility)
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

metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


# ---------------------------------------------------------------------------
# Middleware — track every request with Prometheus + structured log
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


@app.get("/demo/span")
async def demo_span() -> dict:
    """Create a custom child span to demonstrate OTEL tracing."""
    with tracer.start_as_current_span("demo-work") as span:
        span.set_attribute("demo.key", "hello-tracer-bullet")
        span.add_event("processing started")
        time.sleep(0.01)  # Simulate work
        span.add_event("processing finished")
    return {"trace_id": format(trace.get_current_span().get_span_context().trace_id, "032x")}
