"""
FastAPI application for AI-powered anomaly detection service.

This service monitors metrics and logs from Prometheus, applies ML models
to detect anomalies in real-time, and provides root cause analysis.
"""
import os
import time
import logging
from typing import Dict, List, Optional
from contextlib import asynccontextmanager
from datetime import datetime, timedelta

from fastapi import FastAPI, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge
import httpx

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Configuration from environment
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://prometheus-kube-prometheus-prometheus.fawkes.svc:9090")
ALERTMANAGER_URL = os.getenv("ALERTMANAGER_URL", "http://prometheus-kube-prometheus-alertmanager.fawkes.svc:9093")
LLM_API_KEY = os.getenv("LLM_API_KEY", "")
LLM_API_URL = os.getenv("LLM_API_URL", "https://api.openai.com/v1/chat/completions")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4")
FALSE_POSITIVE_THRESHOLD = float(os.getenv("FALSE_POSITIVE_THRESHOLD", "0.05"))
DETECTION_INTERVAL_SECONDS = int(os.getenv("DETECTION_INTERVAL_SECONDS", "60"))

# Global HTTP client
http_client: Optional[httpx.AsyncClient] = None


# Pydantic models
class AnomalyScore(BaseModel):
    """Anomaly score model."""

    metric: str = Field(..., description="Metric name")
    timestamp: datetime = Field(..., description="Timestamp of anomaly")
    score: float = Field(..., description="Anomaly score (0-1, higher = more anomalous)")
    confidence: float = Field(..., description="Detection confidence (0-1)")
    value: float = Field(..., description="Actual metric value")
    expected_value: float = Field(..., description="Expected metric value")
    severity: str = Field(..., description="Severity: critical, high, medium, low")


class RootCause(BaseModel):
    """Root cause analysis result."""

    anomaly_id: str
    likely_causes: List[str] = Field(..., description="List of likely root causes")
    correlated_metrics: List[str] = Field(..., description="Correlated metrics showing anomalies")
    recent_events: List[str] = Field(..., description="Recent deployments, config changes, etc.")
    remediation_suggestions: List[str] = Field(..., description="Suggested remediation steps")
    runbook_links: List[str] = Field(..., description="Links to relevant runbooks")


class AnomalyDetection(BaseModel):
    """Complete anomaly detection result."""

    id: str
    anomaly: AnomalyScore
    root_cause: Optional[RootCause] = None
    detected_at: datetime
    alerted: bool = Field(default=False, description="Whether alert was sent")


class HealthResponse(BaseModel):
    """Health check response."""

    status: str
    service: str
    version: str
    prometheus_connected: bool
    models_loaded: bool
    llm_configured: bool


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan (startup/shutdown)."""
    # Startup
    global http_client
    logger.info("Starting Anomaly Detection Service")
    http_client = httpx.AsyncClient(timeout=30.0)

    # Check Prometheus connection
    try:
        response = await http_client.get(f"{PROMETHEUS_URL}/api/v1/status/config")
        if response.status_code == 200:
            logger.info("✅ Connected to Prometheus successfully")
        else:
            logger.warning(f"⚠️  Prometheus returned status {response.status_code}")
    except Exception as e:
        logger.error(f"❌ Failed to connect to Prometheus: {e}")

    # Initialize ML models
    try:
        from .models import detector

        detector.initialize_models()
        logger.info("✅ ML models initialized successfully")
    except Exception as e:
        logger.error(f"❌ Failed to initialize ML models: {e}")

    # Start background anomaly detection
    import asyncio
    from . import detector as detection_module

    detection_task = asyncio.create_task(detection_module.run_continuous_detection())

    yield

    # Shutdown
    logger.info("Shutting down Anomaly Detection Service")
    detection_task.cancel()
    if http_client:
        await http_client.aclose()


# Create FastAPI app
app = FastAPI(
    title="Anomaly Detection Service",
    description="AI-powered anomaly detection for metrics, logs, and system behavior",
    version="0.1.0",
    lifespan=lifespan,
)

# Prometheus metrics
ANOMALIES_DETECTED = Counter("anomaly_detection_total", "Total anomalies detected", ["metric", "severity"])

DETECTION_DURATION = Histogram(
    "anomaly_detection_duration_seconds",
    "Anomaly detection processing duration",
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0],
)

FALSE_POSITIVE_RATE_GAUGE = Gauge("anomaly_detection_false_positive_rate", "Estimated false positive rate")

MODELS_LOADED = Gauge("anomaly_detection_models_loaded", "Number of ML models loaded")

ROOT_CAUSE_ANALYSES = Counter("anomaly_detection_rca_total", "Total root cause analyses performed", ["status"])

# Add prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

# Store recent anomalies
recent_anomalies: List[AnomalyDetection] = []
MAX_RECENT_ANOMALIES = 100


@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint."""
    return {"service": "anomaly-detection", "status": "running", "version": "0.1.0"}


@app.get("/health")
async def health() -> HealthResponse:
    """Health check endpoint."""
    prometheus_connected = False
    models_loaded = False

    try:
        if http_client:
            response = await http_client.get(f"{PROMETHEUS_URL}/api/v1/status/config", timeout=5.0)
            prometheus_connected = response.status_code == 200
    except Exception:
        pass

    try:
        from .models import detector

        models_loaded = detector.models_initialized
    except Exception:
        pass

    return HealthResponse(
        status="UP",
        service="anomaly-detection",
        version="0.1.0",
        prometheus_connected=prometheus_connected,
        models_loaded=models_loaded,
        llm_configured=bool(LLM_API_KEY),
    )


@app.get("/ready")
async def ready():
    """Readiness check endpoint."""
    try:
        if http_client:
            response = await http_client.get(f"{PROMETHEUS_URL}/api/v1/status/config", timeout=5.0)
            if response.status_code != 200:
                raise HTTPException(status_code=503, detail="Prometheus not reachable")
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Prometheus not ready: {str(e)}")

    try:
        from .models import detector

        if not detector.models_initialized:
            raise HTTPException(status_code=503, detail="ML models not loaded")
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Models not ready: {str(e)}")

    return {"status": "READY", "service": "anomaly-detection"}


@app.get("/api/v1/anomalies")
async def get_anomalies(
    limit: int = 50, severity: Optional[str] = None, metric: Optional[str] = None
) -> List[AnomalyDetection]:
    """
    Get recent anomalies.

    Args:
        limit: Maximum number of anomalies to return
        severity: Filter by severity (critical, high, medium, low)
        metric: Filter by metric name
    """
    filtered = recent_anomalies

    if severity:
        filtered = [a for a in filtered if a.anomaly.severity == severity]

    if metric:
        filtered = [a for a in filtered if a.anomaly.metric == metric]

    return filtered[:limit]


@app.get("/api/v1/anomalies/{anomaly_id}")
async def get_anomaly(anomaly_id: str) -> AnomalyDetection:
    """Get specific anomaly by ID."""
    for anomaly in recent_anomalies:
        if anomaly.id == anomaly_id:
            return anomaly

    raise HTTPException(status_code=404, detail="Anomaly not found")


@app.post("/api/v1/anomalies/{anomaly_id}/rca")
async def trigger_rca(anomaly_id: str, background_tasks: BackgroundTasks):
    """Trigger root cause analysis for an anomaly."""
    anomaly = None
    for a in recent_anomalies:
        if a.id == anomaly_id:
            anomaly = a
            break

    if not anomaly:
        raise HTTPException(status_code=404, detail="Anomaly not found")

    if anomaly.root_cause:
        return {"message": "RCA already exists", "root_cause": anomaly.root_cause}

    # Perform RCA in background
    from . import rca as rca_module

    background_tasks.add_task(rca_module.perform_root_cause_analysis, anomaly, recent_anomalies)

    return {"message": "RCA triggered", "anomaly_id": anomaly_id}


@app.get("/api/v1/models")
async def get_models():
    """Get information about loaded ML models."""
    try:
        from .models import detector

        return {"models_loaded": detector.models_initialized, "models": detector.get_model_info()}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get model info: {str(e)}")


@app.get("/stats")
async def get_stats():
    """Get detection statistics."""
    total_anomalies = len(recent_anomalies)

    severity_counts = {}
    for anomaly in recent_anomalies:
        sev = anomaly.anomaly.severity
        severity_counts[sev] = severity_counts.get(sev, 0) + 1

    with_rca = sum(1 for a in recent_anomalies if a.root_cause is not None)
    alerted = sum(1 for a in recent_anomalies if a.alerted)

    return {
        "total_anomalies": total_anomalies,
        "severity_counts": severity_counts,
        "with_root_cause_analysis": with_rca,
        "alerts_sent": alerted,
        "false_positive_threshold": FALSE_POSITIVE_THRESHOLD,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
