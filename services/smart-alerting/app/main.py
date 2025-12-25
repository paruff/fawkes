"""
FastAPI application for intelligent alert correlation and routing.

This service provides intelligent alerting that reduces noise through:
- Alert correlation and grouping
- Duplicate detection and suppression
- Priority scoring
- Intelligent routing to appropriate teams and channels
"""
import os
import logging
from typing import Dict, List, Optional, Any
from contextlib import asynccontextmanager
from datetime import datetime
import uuid

from fastapi import FastAPI, HTTPException, BackgroundTasks
from pydantic import BaseModel, Field
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge
import redis.asyncio as redis
import httpx

from .correlation import AlertCorrelator
from .suppression import SuppressionEngine
from .routing import AlertRouter

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration from environment
REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_DB = int(os.getenv("REDIS_DB", "0"))
PROMETHEUS_URL = os.getenv("PROMETHEUS_URL", "http://prometheus-kube-prometheus-prometheus.fawkes.svc:9090")
GRAFANA_URL = os.getenv("GRAFANA_URL", "http://grafana.fawkes.svc:80")
BACKSTAGE_URL = os.getenv("BACKSTAGE_URL", "http://backstage.fawkes.svc:7007")
MATTERMOST_WEBHOOK_URL = os.getenv("MATTERMOST_WEBHOOK_URL", "")
SLACK_WEBHOOK_URL = os.getenv("SLACK_WEBHOOK_URL", "")
PAGERDUTY_API_KEY = os.getenv("PAGERDUTY_API_KEY", "")

# Global clients
redis_client: Optional[redis.Redis] = None
http_client: Optional[httpx.AsyncClient] = None
correlator: Optional[AlertCorrelator] = None
suppression_engine: Optional[SuppressionEngine] = None
router: Optional[AlertRouter] = None


# Pydantic models
class AlertLabel(BaseModel):
    """Alert labels."""
    alertname: str
    service: Optional[str] = None
    severity: Optional[str] = "medium"
    namespace: Optional[str] = None
    pod: Optional[str] = None


class AlertAnnotation(BaseModel):
    """Alert annotations."""
    summary: Optional[str] = None
    description: Optional[str] = None
    runbook_url: Optional[str] = None


class Alert(BaseModel):
    """Alert model."""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    labels: Dict[str, Any]
    annotations: Dict[str, Any] = Field(default_factory=dict)
    startsAt: datetime
    endsAt: Optional[datetime] = None
    status: str = "firing"
    generatorURL: Optional[str] = None
    fingerprint: Optional[str] = None


class AlertGroup(BaseModel):
    """Grouped alerts."""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    alerts: List[Alert]
    grouping_key: str
    priority_score: float
    first_seen: datetime
    last_seen: datetime
    count: int
    suppressed: bool = False
    suppression_reason: Optional[str] = None
    routed_to: Optional[List[str]] = None


class PrometheusAlertPayload(BaseModel):
    """Prometheus webhook alert payload."""
    alerts: List[Alert]
    status: str = "firing"
    groupLabels: Dict[str, str] = Field(default_factory=dict)
    commonLabels: Dict[str, str] = Field(default_factory=dict)
    commonAnnotations: Dict[str, str] = Field(default_factory=dict)


class SuppressionRule(BaseModel):
    """Suppression rule model."""
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    name: str
    type: str  # maintenance_window, known_issue, flapping, cascade, time_based
    enabled: bool = True
    alert_pattern: Optional[str] = None
    services: Optional[List[str]] = None
    schedule: Optional[str] = None
    duration: Optional[int] = None
    threshold: Optional[int] = None
    window: Optional[int] = None
    expires_at: Optional[datetime] = None
    ticket_url: Optional[str] = None
    root_cause_alert: Optional[str] = None
    dependent_alerts: Optional[List[str]] = None
    suppress_severity: Optional[List[str]] = None
    action: str = "suppress"


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    service: str
    version: str
    redis_connected: bool
    rules_loaded: int


# Prometheus metrics
ALERTS_RECEIVED = Counter(
    'smart_alerting_received_total',
    'Total alerts received',
    ['source']
)

ALERTS_SUPPRESSED = Counter(
    'smart_alerting_suppressed_total',
    'Total alerts suppressed',
    ['reason']
)

ALERT_GROUPS_CREATED = Counter(
    'smart_alerting_grouped_total',
    'Total alert groups created'
)

ALERTS_ROUTED = Counter(
    'smart_alerting_routed_total',
    'Total alerts routed',
    ['channel']
)

ALERT_FATIGUE_REDUCTION = Gauge(
    'smart_alerting_fatigue_reduction',
    'Alert fatigue reduction percentage'
)

FALSE_ALERT_RATE = Gauge(
    'smart_alerting_false_alert_rate',
    'False alert rate'
)

PROCESSING_DURATION = Histogram(
    'smart_alerting_processing_duration_seconds',
    'Alert processing duration',
    buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0]
)


# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan."""
    global redis_client, http_client, correlator, suppression_engine, router

    logger.info("Starting Smart Alerting Service")

    # Initialize Redis
    try:
        redis_client = redis.Redis(
            host=REDIS_HOST,
            port=REDIS_PORT,
            db=REDIS_DB,
            decode_responses=True
        )
        await redis_client.ping()
        logger.info("✅ Connected to Redis successfully")
    except Exception as e:
        logger.error(f"❌ Failed to connect to Redis: {e}")
        raise

    # Initialize HTTP client
    http_client = httpx.AsyncClient(timeout=30.0)

    # Initialize components
    correlator = AlertCorrelator(redis_client)
    suppression_engine = SuppressionEngine(redis_client)
    router = AlertRouter(
        http_client=http_client,
        backstage_url=BACKSTAGE_URL,
        mattermost_webhook=MATTERMOST_WEBHOOK_URL,
        slack_webhook=SLACK_WEBHOOK_URL,
        pagerduty_api_key=PAGERDUTY_API_KEY
    )

    # Load suppression rules
    await suppression_engine.load_rules_from_directory("rules/")
    logger.info(f"✅ Loaded {len(suppression_engine.rules)} suppression rules")

    yield

    # Shutdown
    logger.info("Shutting down Smart Alerting Service")
    if redis_client:
        await redis_client.close()
    if http_client:
        await http_client.aclose()


# Create FastAPI app
app = FastAPI(
    title="Smart Alerting Service",
    description="Intelligent alerting that reduces noise and groups related alerts",
    version="0.1.0",
    lifespan=lifespan
)

# Add prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint."""
    return {
        "service": "smart-alerting",
        "status": "running",
        "version": "0.1.0"
    }


@app.get("/health")
async def health() -> HealthResponse:
    """Health check endpoint."""
    redis_connected = False
    rules_loaded = 0

    try:
        if redis_client:
            await redis_client.ping()
            redis_connected = True
    except Exception:
        pass

    if suppression_engine:
        rules_loaded = len(suppression_engine.rules)

    return HealthResponse(
        status="UP",
        service="smart-alerting",
        version="0.1.0",
        redis_connected=redis_connected,
        rules_loaded=rules_loaded
    )


@app.get("/ready")
async def ready():
    """Readiness check endpoint."""
    try:
        if redis_client:
            await redis_client.ping()
        else:
            raise HTTPException(status_code=503, detail="Redis client not initialized")
    except Exception as e:
        raise HTTPException(status_code=503, detail=f"Redis not ready: {str(e)}")

    if not suppression_engine:
        raise HTTPException(status_code=503, detail="Suppression engine not initialized")

    if not correlator:
        raise HTTPException(status_code=503, detail="Correlator not initialized")

    return {
        "status": "READY",
        "service": "smart-alerting"
    }


@app.post("/api/v1/alerts/prometheus")
async def ingest_prometheus_alerts(payload: PrometheusAlertPayload, background_tasks: BackgroundTasks):
    """Ingest alerts from Prometheus."""
    ALERTS_RECEIVED.labels(source="prometheus").inc(len(payload.alerts))

    background_tasks.add_task(process_alerts, payload.alerts, "prometheus")

    return {
        "message": f"Received {len(payload.alerts)} alerts",
        "status": "processing"
    }


@app.post("/api/v1/alerts/grafana")
async def ingest_grafana_alerts(alerts: List[Alert], background_tasks: BackgroundTasks):
    """Ingest alerts from Grafana."""
    ALERTS_RECEIVED.labels(source="grafana").inc(len(alerts))

    background_tasks.add_task(process_alerts, alerts, "grafana")

    return {
        "message": f"Received {len(alerts)} alerts",
        "status": "processing"
    }


@app.post("/api/v1/alerts/datahub")
async def ingest_datahub_alerts(alerts: List[Alert], background_tasks: BackgroundTasks):
    """Ingest alerts from DataHub."""
    ALERTS_RECEIVED.labels(source="datahub").inc(len(alerts))

    background_tasks.add_task(process_alerts, alerts, "datahub")

    return {
        "message": f"Received {len(alerts)} alerts",
        "status": "processing"
    }


@app.post("/api/v1/alerts/generic")
async def ingest_generic_alerts(alerts: List[Alert], background_tasks: BackgroundTasks):
    """Ingest generic alerts."""
    ALERTS_RECEIVED.labels(source="generic").inc(len(alerts))

    background_tasks.add_task(process_alerts, alerts, "generic")

    return {
        "message": f"Received {len(alerts)} alerts",
        "status": "processing"
    }


@app.get("/api/v1/alert-groups")
async def get_alert_groups(limit: int = 50) -> List[AlertGroup]:
    """Get recent alert groups."""
    if not correlator:
        raise HTTPException(status_code=503, detail="Correlator not initialized")

    groups = await correlator.get_recent_groups(limit)
    return groups


@app.get("/api/v1/alert-groups/{group_id}")
async def get_alert_group(group_id: str) -> AlertGroup:
    """Get specific alert group."""
    if not correlator:
        raise HTTPException(status_code=503, detail="Correlator not initialized")

    group = await correlator.get_group(group_id)
    if not group:
        raise HTTPException(status_code=404, detail="Alert group not found")

    return group


@app.get("/api/v1/alerts/{alert_id}")
async def get_alert(alert_id: str) -> Alert:
    """Get specific alert."""
    if not redis_client:
        raise HTTPException(status_code=503, detail="Redis not initialized")

    alert_data = await redis_client.get(f"alert:{alert_id}")
    if not alert_data:
        raise HTTPException(status_code=404, detail="Alert not found")

    import json
    return Alert(**json.loads(alert_data))


@app.put("/api/v1/alerts/{alert_id}/acknowledge")
async def acknowledge_alert(alert_id: str):
    """Acknowledge an alert."""
    if not redis_client:
        raise HTTPException(status_code=503, detail="Redis not initialized")

    await redis_client.hset(f"alert:{alert_id}", "acknowledged", "true")
    await redis_client.hset(f"alert:{alert_id}", "acknowledged_at", datetime.now().isoformat())

    return {"message": "Alert acknowledged", "alert_id": alert_id}


@app.put("/api/v1/alerts/{alert_id}/resolve")
async def resolve_alert(alert_id: str):
    """Resolve an alert."""
    if not redis_client:
        raise HTTPException(status_code=503, detail="Redis not initialized")

    await redis_client.hset(f"alert:{alert_id}", "status", "resolved")
    await redis_client.hset(f"alert:{alert_id}", "resolved_at", datetime.now().isoformat())

    return {"message": "Alert resolved", "alert_id": alert_id}


@app.get("/api/v1/rules")
async def get_suppression_rules() -> List[SuppressionRule]:
    """Get all suppression rules."""
    if not suppression_engine:
        raise HTTPException(status_code=503, detail="Suppression engine not initialized")

    # Convert rules to Pydantic models
    result = []
    for rule in suppression_engine.rules:
        if isinstance(rule, dict):
            # Add id if missing
            if 'id' not in rule:
                rule['id'] = str(uuid.uuid4())
            result.append(SuppressionRule(**rule))
        else:
            result.append(rule)

    return result


@app.post("/api/v1/rules")
async def create_suppression_rule(rule: SuppressionRule) -> SuppressionRule:
    """Create a new suppression rule."""
    if not suppression_engine:
        raise HTTPException(status_code=503, detail="Suppression engine not initialized")

    # Convert to dict for suppression engine
    await suppression_engine.add_rule(rule.dict())
    return rule


@app.get("/api/v1/rules/{rule_id}")
async def get_suppression_rule(rule_id: str) -> SuppressionRule:
    """Get specific suppression rule."""
    if not suppression_engine:
        raise HTTPException(status_code=503, detail="Suppression engine not initialized")

    for rule in suppression_engine.rules:
        # Handle both dict and Pydantic models
        rid = rule.get('id') if isinstance(rule, dict) else getattr(rule, 'id', None)
        if rid == rule_id:
            # Convert to Pydantic model if it's a dict
            if isinstance(rule, dict):
                return SuppressionRule(**rule)
            return rule

    raise HTTPException(status_code=404, detail="Rule not found")


@app.put("/api/v1/rules/{rule_id}")
async def update_suppression_rule(rule_id: str, rule: SuppressionRule) -> SuppressionRule:
    """Update suppression rule."""
    if not suppression_engine:
        raise HTTPException(status_code=503, detail="Suppression engine not initialized")

    rule.id = rule_id
    # Convert to dict for suppression engine
    await suppression_engine.update_rule(rule.dict())
    return rule


@app.delete("/api/v1/rules/{rule_id}")
async def delete_suppression_rule(rule_id: str):
    """Delete suppression rule."""
    if not suppression_engine:
        raise HTTPException(status_code=503, detail="Suppression engine not initialized")

    await suppression_engine.delete_rule(rule_id)
    return {"message": "Rule deleted", "rule_id": rule_id}


@app.get("/api/v1/stats")
async def get_stats():
    """Get alerting statistics."""
    if not redis_client:
        raise HTTPException(status_code=503, detail="Redis not initialized")

    total_received = await redis_client.get("stats:total_received") or "0"
    total_suppressed = await redis_client.get("stats:total_suppressed") or "0"
    total_grouped = await redis_client.get("stats:total_grouped") or "0"
    total_routed = await redis_client.get("stats:total_routed") or "0"

    total_received_int = int(total_received)
    total_suppressed_int = int(total_suppressed)

    reduction = 0.0
    if total_received_int > 0:
        reduction = (total_suppressed_int / total_received_int) * 100

    ALERT_FATIGUE_REDUCTION.set(reduction)

    return {
        "total_received": total_received_int,
        "total_suppressed": total_suppressed_int,
        "total_grouped": int(total_grouped),
        "total_routed": int(total_routed),
        "fatigue_reduction_percent": round(reduction, 2)
    }


@app.get("/api/v1/stats/reduction")
async def get_reduction_stats():
    """Get alert reduction metrics."""
    stats = await get_stats()
    return {
        "fatigue_reduction_percent": stats["fatigue_reduction_percent"],
        "target": 50.0,
        "target_met": stats["fatigue_reduction_percent"] >= 50.0
    }


async def process_alerts(alerts: List[Alert], source: str):
    """Process incoming alerts through correlation, suppression, and routing."""
    start_time = datetime.now()

    try:
        # Correlate alerts
        groups = await correlator.correlate_alerts(alerts)
        ALERT_GROUPS_CREATED.inc(len(groups))

        # Apply suppression rules
        for group in groups:
            suppressed, reason = await suppression_engine.should_suppress(group)
            group.suppressed = suppressed
            group.suppression_reason = reason

            if suppressed:
                ALERTS_SUPPRESSED.labels(reason=reason).inc(len(group.alerts))
                await redis_client.incr("stats:total_suppressed", len(group.alerts))
            else:
                # Route non-suppressed alerts
                channels = await router.route_alert_group(group)
                group.routed_to = channels

                for channel in channels:
                    ALERTS_ROUTED.labels(channel=channel).inc()

                await redis_client.incr("stats:total_routed", len(group.alerts))

        await redis_client.incr("stats:total_received", len(alerts))
        await redis_client.incr("stats:total_grouped", len(groups))

        duration = (datetime.now() - start_time).total_seconds()
        PROCESSING_DURATION.observe(duration)

        logger.info(f"Processed {len(alerts)} alerts from {source} in {duration:.2f}s")

    except Exception as e:
        logger.error(f"Error processing alerts: {e}", exc_info=True)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
