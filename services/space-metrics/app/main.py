"""
SPACE Metrics Collection Service

FastAPI-based service for collecting and exposing SPACE framework metrics
for Developer Experience measurement.
"""

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, PlainTextResponse
from datetime import datetime, timedelta
from typing import Optional, Dict, Any, List
import logging
from contextlib import asynccontextmanager

from .database import init_db, get_db_session
from .models import (
    SpaceSatisfaction,
    SpacePerformance,
    SpaceActivity,
    SpaceCommunication,
    SpaceEfficiency,
)
from .schemas import (
    SatisfactionMetrics,
    PerformanceMetrics,
    ActivityMetrics,
    CommunicationMetrics,
    EfficiencyMetrics,
    SpaceMetricsResponse,
    FrictionLogRequest,
    PulseSurveyRequest,
)
from .collectors import (
    collect_satisfaction_metrics,
    collect_performance_metrics,
    collect_activity_metrics,
    collect_communication_metrics,
    collect_efficiency_metrics,
)
from .metrics import (
    expose_prometheus_metrics,
    calculate_devex_health_score,
)

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Initialize and cleanup application lifecycle"""
    # Startup
    logger.info("Starting SPACE Metrics Service")
    await init_db()
    logger.info("Database initialized")
    
    yield
    
    # Shutdown
    logger.info("Shutting down SPACE Metrics Service")


app = FastAPI(
    title="SPACE Metrics Service",
    description="Developer Experience metrics collection using SPACE framework",
    version="1.0.0",
    lifespan=lifespan,
)


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "service": "space-metrics",
        "timestamp": datetime.utcnow().isoformat(),
    }


@app.get("/metrics", response_class=PlainTextResponse)
async def prometheus_metrics():
    """Expose Prometheus metrics"""
    try:
        metrics = await expose_prometheus_metrics()
        return PlainTextResponse(content=metrics, media_type="text/plain")
    except Exception as e:
        logger.error(f"Error exposing metrics: {e}")
        raise HTTPException(status_code=500, detail="Error exposing metrics")


@app.get("/api/v1/metrics/space", response_model=SpaceMetricsResponse)
async def get_space_metrics(
    time_range: Optional[str] = "30d"
) -> SpaceMetricsResponse:
    """
    Get all SPACE dimension metrics (aggregated)
    
    time_range: Time range for metrics (24h, 7d, 30d, 90d)
    """
    try:
        # Parse time range
        now = datetime.utcnow()
        if time_range == "24h":
            start_time = now - timedelta(hours=24)
        elif time_range == "7d":
            start_time = now - timedelta(days=7)
        elif time_range == "30d":
            start_time = now - timedelta(days=30)
        elif time_range == "90d":
            start_time = now - timedelta(days=90)
        else:
            start_time = now - timedelta(days=30)
        
        async with get_db_session() as session:
            # Collect metrics from each dimension
            satisfaction = await collect_satisfaction_metrics(session, start_time, now)
            performance = await collect_performance_metrics(session, start_time, now)
            activity = await collect_activity_metrics(session, start_time, now)
            communication = await collect_communication_metrics(session, start_time, now)
            efficiency = await collect_efficiency_metrics(session, start_time, now)
            
            # Calculate overall health score
            health_score = calculate_devex_health_score(
                satisfaction, performance, activity, communication, efficiency
            )
            
            return SpaceMetricsResponse(
                satisfaction=satisfaction,
                performance=performance,
                activity=activity,
                communication=communication,
                efficiency=efficiency,
                health_score=health_score,
                time_range=time_range,
                timestamp=now,
            )
    except Exception as e:
        logger.error(f"Error getting SPACE metrics: {e}")
        raise HTTPException(status_code=500, detail=f"Error retrieving metrics: {str(e)}")


@app.get("/api/v1/metrics/space/satisfaction", response_model=SatisfactionMetrics)
async def get_satisfaction_metrics(time_range: Optional[str] = "30d"):
    """Get satisfaction dimension metrics"""
    try:
        now = datetime.utcnow()
        start_time = now - timedelta(days=30)
        
        async with get_db_session() as session:
            metrics = await collect_satisfaction_metrics(session, start_time, now)
            return metrics
    except Exception as e:
        logger.error(f"Error getting satisfaction metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/metrics/space/performance", response_model=PerformanceMetrics)
async def get_performance_metrics(time_range: Optional[str] = "30d"):
    """Get performance dimension metrics"""
    try:
        now = datetime.utcnow()
        start_time = now - timedelta(days=30)
        
        async with get_db_session() as session:
            metrics = await collect_performance_metrics(session, start_time, now)
            return metrics
    except Exception as e:
        logger.error(f"Error getting performance metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/metrics/space/activity", response_model=ActivityMetrics)
async def get_activity_metrics(time_range: Optional[str] = "30d"):
    """Get activity dimension metrics"""
    try:
        now = datetime.utcnow()
        start_time = now - timedelta(days=30)
        
        async with get_db_session() as session:
            metrics = await collect_activity_metrics(session, start_time, now)
            return metrics
    except Exception as e:
        logger.error(f"Error getting activity metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/metrics/space/communication", response_model=CommunicationMetrics)
async def get_communication_metrics(time_range: Optional[str] = "30d"):
    """Get communication dimension metrics"""
    try:
        now = datetime.utcnow()
        start_time = now - timedelta(days=30)
        
        async with get_db_session() as session:
            metrics = await collect_communication_metrics(session, start_time, now)
            return metrics
    except Exception as e:
        logger.error(f"Error getting communication metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/metrics/space/efficiency", response_model=EfficiencyMetrics)
async def get_efficiency_metrics(time_range: Optional[str] = "30d"):
    """Get efficiency dimension metrics"""
    try:
        now = datetime.utcnow()
        start_time = now - timedelta(days=30)
        
        async with get_db_session() as session:
            metrics = await collect_efficiency_metrics(session, start_time, now)
            return metrics
    except Exception as e:
        logger.error(f"Error getting efficiency metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/friction/log")
async def log_friction_incident(request: FrictionLogRequest):
    """Log a friction incident"""
    try:
        async with get_db_session() as session:
            # Create efficiency record with friction incident
            efficiency = SpaceEfficiency(
                timestamp=datetime.utcnow(),
                friction_incidents=1,
                friction_details=request.dict(),
            )
            session.add(efficiency)
            await session.commit()
            
            return {
                "status": "success",
                "message": "Friction incident logged",
                "id": efficiency.id,
            }
    except Exception as e:
        logger.error(f"Error logging friction: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/v1/surveys/pulse/submit")
async def submit_pulse_survey(request: PulseSurveyRequest):
    """Submit pulse survey response"""
    try:
        async with get_db_session() as session:
            # Create efficiency record with flow state and valuable work
            efficiency = SpaceEfficiency(
                timestamp=datetime.utcnow(),
                flow_state_days=request.flow_state_days,
                valuable_work_percentage=request.valuable_work_percentage,
                cognitive_load_avg=request.cognitive_load,
            )
            session.add(efficiency)
            await session.commit()
            
            return {
                "status": "success",
                "message": "Pulse survey submitted",
            }
    except Exception as e:
        logger.error(f"Error submitting pulse survey: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/metrics/space/health")
async def get_devex_health():
    """Get overall DevEx health score"""
    try:
        now = datetime.utcnow()
        start_time = now - timedelta(days=30)
        
        async with get_db_session() as session:
            satisfaction = await collect_satisfaction_metrics(session, start_time, now)
            performance = await collect_performance_metrics(session, start_time, now)
            activity = await collect_activity_metrics(session, start_time, now)
            communication = await collect_communication_metrics(session, start_time, now)
            efficiency = await collect_efficiency_metrics(session, start_time, now)
            
            health_score = calculate_devex_health_score(
                satisfaction, performance, activity, communication, efficiency
            )
            
            return {
                "health_score": health_score,
                "timestamp": now,
                "status": "excellent" if health_score >= 80 else "good" if health_score >= 60 else "needs_improvement",
            }
    except Exception as e:
        logger.error(f"Error calculating health score: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
