"""
FastAPI application for VSM (Value Stream Mapping) service.

This service provides work item tracking through value stream stages
from idea to production, with flow metrics and cycle time calculation.
"""
import os
import time
import logging
from datetime import datetime, timedelta, timezone
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, Query
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from sqlalchemy import func
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge

from app.database import get_db, init_db, engine
from app.models import WorkItem, Stage, StageTransition, FlowMetrics, WorkItemType
from app.schemas import (
    WorkItemCreate, WorkItemResponse, StageTransitionCreate,
    StageTransitionResponse, WorkItemHistory, FlowMetricsResponse,
    StageResponse, HealthResponse
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
VERSION = "0.1.0"


# Prometheus metrics
REQUEST_COUNT = Counter(
    'vsm_requests_total',
    'Total VSM requests',
    ['method', 'endpoint', 'status']
)

WORK_ITEMS_CREATED = Counter(
    'vsm_work_items_created_total',
    'Total work items created',
    ['type']
)

STAGE_TRANSITIONS = Counter(
    'vsm_stage_transitions_total',
    'Total stage transitions',
    ['from_stage', 'to_stage']
)

CYCLE_TIME = Histogram(
    'vsm_cycle_time_hours',
    'Cycle time for work items in hours',
    buckets=[1, 4, 8, 24, 48, 72, 168, 336, 720]  # 1h to 30 days
)

WIP_GAUGE = Gauge(
    'vsm_work_in_progress',
    'Current work in progress',
    ['stage']
)


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan (startup/shutdown)."""
    # Startup
    logger.info("Starting VSM service")
    try:
        init_db()
        logger.info("✅ Database initialized successfully")
    except Exception as e:
        logger.error(f"❌ Failed to initialize database: {e}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down VSM service")


# Create FastAPI app
app = FastAPI(
    title="VSM Service",
    description="Value Stream Mapping service for work item tracking and flow metrics",
    version=VERSION,
    lifespan=lifespan
)

# Add prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


@app.middleware("http")
async def add_metrics(request, call_next):
    """Add prometheus metrics to all requests."""
    start_time = time.time()
    response = await call_next(request)
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    return response


@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint."""
    return {
        "service": "vsm-service",
        "status": "running",
        "version": VERSION,
        "endpoints": {
            "work_items": "/api/v1/work-items",
            "transition": "/api/v1/work-items/{id}/transition",
            "metrics": "/api/v1/metrics",
            "history": "/api/v1/work-items/{id}/history",
            "stages": "/api/v1/stages",
            "health": "/api/v1/health",
            "prometheus": "/metrics"
        }
    }


@app.get("/api/v1/health", response_model=HealthResponse, tags=["Health"])
async def health(db: Session = Depends(get_db)):
    """
    Health check endpoint.
    
    Returns service status and database connection status.
    """
    database_connected = False
    try:
        # Test database connection
        db.execute(func.now())
        database_connected = True
    except Exception as e:
        logger.warning(f"Database health check failed: {e}")
    
    return HealthResponse(
        status="UP" if database_connected else "DEGRADED",
        service="vsm-service",
        version=VERSION,
        database_connected=database_connected
    )


@app.get("/ready", include_in_schema=False)
async def ready(db: Session = Depends(get_db)):
    """
    Readiness check endpoint for Kubernetes.
    
    Returns 200 if service is ready to accept traffic, 503 otherwise.
    """
    try:
        # Test database connection
        db.execute(func.now())
        return {"status": "READY"}
    except Exception as e:
        logger.warning(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="Service not ready")


@app.post("/api/v1/work-items", response_model=WorkItemResponse, status_code=201, tags=["Work Items"])
async def create_work_item(
    work_item: WorkItemCreate,
    db: Session = Depends(get_db)
):
    """
    Create a new work item.
    
    Args:
        work_item: Work item creation request
        db: Database session
        
    Returns:
        Created work item
    """
    try:
        # Create work item
        db_work_item = WorkItem(
            title=work_item.title,
            type=work_item.type
        )
        db.add(db_work_item)
        db.commit()
        db.refresh(db_work_item)
        
        # Add initial transition to Backlog
        backlog_stage = db.query(Stage).filter(Stage.name == "Backlog").first()
        if backlog_stage:
            transition = StageTransition(
                work_item_id=db_work_item.id,
                from_stage_id=None,
                to_stage_id=backlog_stage.id
            )
            db.add(transition)
            db.commit()
        
        # Update metrics
        WORK_ITEMS_CREATED.labels(type=work_item.type.value).inc()
        
        logger.info(f"Created work item {db_work_item.id}: {db_work_item.title}")
        
        # Get current stage
        current_stage_name = None
        if backlog_stage:
            current_stage_name = backlog_stage.name
        
        return WorkItemResponse(
            id=db_work_item.id,
            title=db_work_item.title,
            type=db_work_item.type,
            created_at=db_work_item.created_at,
            updated_at=db_work_item.updated_at,
            current_stage=current_stage_name
        )
        
    except Exception as e:
        logger.error(f"Failed to create work item: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to create work item: {str(e)}")


@app.put("/api/v1/work-items/{work_item_id}/transition", response_model=StageTransitionResponse, tags=["Work Items"])
async def transition_work_item(
    work_item_id: int,
    transition_request: StageTransitionCreate,
    db: Session = Depends(get_db)
):
    """
    Move work item to a new stage.
    
    Args:
        work_item_id: Work item ID
        transition_request: Transition request with target stage
        db: Database session
        
    Returns:
        Stage transition record
    """
    # Verify work item exists
    work_item = db.query(WorkItem).filter(WorkItem.id == work_item_id).first()
    if not work_item:
        raise HTTPException(status_code=404, detail=f"Work item {work_item_id} not found")
    
    # Get target stage
    to_stage = db.query(Stage).filter(Stage.name == transition_request.to_stage).first()
    if not to_stage:
        raise HTTPException(status_code=404, detail=f"Stage '{transition_request.to_stage}' not found")
    
    # Get current stage (most recent transition)
    current_transition = (
        db.query(StageTransition)
        .filter(StageTransition.work_item_id == work_item_id)
        .order_by(StageTransition.timestamp.desc())
        .first()
    )
    
    from_stage_id = current_transition.to_stage_id if current_transition else None
    from_stage_name = None
    if from_stage_id:
        from_stage = db.query(Stage).filter(Stage.id == from_stage_id).first()
        if from_stage:
            from_stage_name = from_stage.name
    
    try:
        # Create transition
        transition = StageTransition(
            work_item_id=work_item_id,
            from_stage_id=from_stage_id,
            to_stage_id=to_stage.id
        )
        db.add(transition)
        
        # Update work item timestamp
        work_item.updated_at = datetime.now(timezone.utc)
        
        db.commit()
        db.refresh(transition)
        
        # Update metrics
        STAGE_TRANSITIONS.labels(
            from_stage=from_stage_name or "none",
            to_stage=to_stage.name
        ).inc()
        
        # If moved to production, calculate cycle time
        if to_stage.name == "Production":
            cycle_time_hours = calculate_cycle_time(work_item_id, db)
            if cycle_time_hours:
                CYCLE_TIME.observe(cycle_time_hours)
        
        logger.info(f"Transitioned work item {work_item_id} from {from_stage_name} to {to_stage.name}")
        
        return StageTransitionResponse(
            id=transition.id,
            work_item_id=work_item_id,
            from_stage=from_stage_name,
            to_stage=to_stage.name,
            timestamp=transition.timestamp
        )
        
    except Exception as e:
        logger.error(f"Failed to transition work item: {e}")
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to transition work item: {str(e)}")


@app.get("/api/v1/work-items/{work_item_id}/history", response_model=WorkItemHistory, tags=["Work Items"])
async def get_work_item_history(
    work_item_id: int,
    db: Session = Depends(get_db)
):
    """
    Get stage history for a work item.
    
    Args:
        work_item_id: Work item ID
        db: Database session
        
    Returns:
        Work item history with all stage transitions
    """
    # Verify work item exists
    work_item = db.query(WorkItem).filter(WorkItem.id == work_item_id).first()
    if not work_item:
        raise HTTPException(status_code=404, detail=f"Work item {work_item_id} not found")
    
    # Get all transitions
    transitions = (
        db.query(StageTransition)
        .filter(StageTransition.work_item_id == work_item_id)
        .order_by(StageTransition.timestamp.asc())
        .all()
    )
    
    # Build response
    transition_responses = []
    for transition in transitions:
        from_stage_name = None
        if transition.from_stage_id:
            from_stage = db.query(Stage).filter(Stage.id == transition.from_stage_id).first()
            if from_stage:
                from_stage_name = from_stage.name
        
        to_stage = db.query(Stage).filter(Stage.id == transition.to_stage_id).first()
        to_stage_name = to_stage.name if to_stage else "Unknown"
        
        transition_responses.append(
            StageTransitionResponse(
                id=transition.id,
                work_item_id=work_item_id,
                from_stage=from_stage_name,
                to_stage=to_stage_name,
                timestamp=transition.timestamp
            )
        )
    
    return WorkItemHistory(
        work_item_id=work_item_id,
        work_item_title=work_item.title,
        transitions=transition_responses
    )


@app.get("/api/v1/metrics", response_model=FlowMetricsResponse, tags=["Metrics"])
async def get_flow_metrics(
    days: int = Query(7, description="Number of days to calculate metrics for", ge=1, le=90),
    db: Session = Depends(get_db)
):
    """
    Get flow metrics (WIP, throughput, cycle time).
    
    Args:
        days: Number of days to calculate metrics for (default: 7)
        db: Database session
        
    Returns:
        Flow metrics for the specified period
    """
    period_end = datetime.now(timezone.utc)
    period_start = period_end - timedelta(days=days)
    
    try:
        # Calculate throughput (items completed in period)
        production_stage = db.query(Stage).filter(Stage.name == "Production").first()
        throughput = 0
        if production_stage:
            throughput = (
                db.query(StageTransition)
                .filter(
                    StageTransition.to_stage_id == production_stage.id,
                    StageTransition.timestamp >= period_start,
                    StageTransition.timestamp <= period_end
                )
                .count()
            )
        
        # Calculate WIP (average work in progress)
        # Count work items that have transitions but haven't reached production
        wip_count = (
            db.query(WorkItem)
            .join(StageTransition)
            .filter(
                WorkItem.id.notin_(
                    db.query(StageTransition.work_item_id)
                    .filter(StageTransition.to_stage_id == production_stage.id)
                    .subquery()
                )
            )
            .distinct()
            .count()
        ) if production_stage else 0
        
        # Calculate cycle times for completed items
        cycle_times = []
        if production_stage:
            completed_items = (
                db.query(StageTransition.work_item_id)
                .filter(
                    StageTransition.to_stage_id == production_stage.id,
                    StageTransition.timestamp >= period_start,
                    StageTransition.timestamp <= period_end
                )
                .all()
            )
            
            for (work_item_id,) in completed_items:
                cycle_time = calculate_cycle_time(work_item_id, db)
                if cycle_time:
                    cycle_times.append(cycle_time)
        
        # Calculate cycle time statistics
        cycle_time_avg = None
        cycle_time_p50 = None
        cycle_time_p85 = None
        cycle_time_p95 = None
        
        if cycle_times:
            cycle_times.sort()
            cycle_time_avg = sum(cycle_times) / len(cycle_times)
            cycle_time_p50 = cycle_times[int(len(cycle_times) * 0.5)]
            cycle_time_p85 = cycle_times[int(len(cycle_times) * 0.85)]
            cycle_time_p95 = cycle_times[int(len(cycle_times) * 0.95)]
        
        # Update WIP gauge
        stages = db.query(Stage).all()
        for stage in stages:
            stage_wip = (
                db.query(WorkItem)
                .join(StageTransition)
                .filter(
                    StageTransition.to_stage_id == stage.id,
                    WorkItem.id.notin_(
                        db.query(StageTransition.work_item_id)
                        .filter(StageTransition.timestamp > StageTransition.timestamp)
                        .subquery()
                    )
                )
                .distinct()
                .count()
            )
            WIP_GAUGE.labels(stage=stage.name).set(stage_wip)
        
        return FlowMetricsResponse(
            throughput=throughput,
            wip=float(wip_count),
            cycle_time_avg=round(cycle_time_avg, 2) if cycle_time_avg else None,
            cycle_time_p50=round(cycle_time_p50, 2) if cycle_time_p50 else None,
            cycle_time_p85=round(cycle_time_p85, 2) if cycle_time_p85 else None,
            cycle_time_p95=round(cycle_time_p95, 2) if cycle_time_p95 else None,
            period_start=period_start,
            period_end=period_end
        )
        
    except Exception as e:
        logger.error(f"Failed to calculate flow metrics: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to calculate flow metrics: {str(e)}")


@app.get("/api/v1/stages", response_model=List[StageResponse], tags=["Stages"])
async def list_stages(db: Session = Depends(get_db)):
    """
    List all available stages.
    
    Args:
        db: Database session
        
    Returns:
        List of all stages in order
    """
    stages = db.query(Stage).order_by(Stage.order.asc()).all()
    return [
        StageResponse(
            id=stage.id,
            name=stage.name,
            order=stage.order,
            type=stage.type
        )
        for stage in stages
    ]


def calculate_cycle_time(work_item_id: int, db: Session) -> Optional[float]:
    """
    Calculate cycle time for a work item in hours.
    
    Args:
        work_item_id: Work item ID
        db: Database session
        
    Returns:
        Cycle time in hours or None if cannot be calculated
    """
    transitions = (
        db.query(StageTransition)
        .filter(StageTransition.work_item_id == work_item_id)
        .order_by(StageTransition.timestamp.asc())
        .all()
    )
    
    if len(transitions) < 2:
        return None
    
    # Calculate time from first to last transition
    start_time = transitions[0].timestamp
    end_time = transitions[-1].timestamp
    
    cycle_time_seconds = (end_time - start_time).total_seconds()
    cycle_time_hours = cycle_time_seconds / 3600
    
    return cycle_time_hours


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
