"""Main FastAPI application for Experimentation Service"""
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator

from fastapi import FastAPI, HTTPException, Depends, Header
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
from sqlalchemy.orm import Session

from .database import engine, Base, get_db
from .models import (
    ExperimentCreate,
    ExperimentResponse,
    ExperimentUpdate,
    VariantAssignment,
    ExperimentStats,
    ExperimentList,
)
from .experiment_manager import ExperimentManager
from .metrics import MetricsCollector


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Manage application lifespan"""
    # Startup: Create database tables
    Base.metadata.create_all(bind=engine)

    # Initialize metrics collector
    metrics_collector = MetricsCollector()
    app.state.metrics_collector = metrics_collector

    yield

    # Shutdown: cleanup if needed
    pass


# Create FastAPI app
app = FastAPI(
    title="Fawkes Experimentation Service",
    description="A/B Testing Framework with statistical analysis and variant assignment",
    version="1.0.0",
    lifespan=lifespan,
)

# Add CORS middleware
# Get allowed origins from environment or use restrictive default
ALLOWED_ORIGINS = os.getenv(
    "CORS_ALLOWED_ORIGINS", "https://backstage.fawkes.idp,https://experimentation.fawkes.idp"
).split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Mount Prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


def get_experiment_manager(db: Session = Depends(get_db)) -> ExperimentManager:
    """Dependency to get experiment manager instance"""
    return ExperimentManager(db, app.state.metrics_collector)


def verify_admin_token(authorization: str = Header(None)) -> bool:
    """Verify admin authorization token"""
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")

    expected_token = f"Bearer {os.getenv('ADMIN_TOKEN', 'dev-admin-token')}"
    if authorization != expected_token:
        raise HTTPException(status_code=401, detail="Invalid authorization token")

    return True


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "experimentation"}


@app.post("/api/v1/experiments", response_model=ExperimentResponse)
async def create_experiment(
    experiment: ExperimentCreate,
    manager: ExperimentManager = Depends(get_experiment_manager),
    _: bool = Depends(verify_admin_token),
):
    """Create a new A/B test experiment"""
    return manager.create_experiment(experiment)


@app.get("/api/v1/experiments", response_model=ExperimentList)
async def list_experiments(
    skip: int = 0, limit: int = 100, status: str = None, manager: ExperimentManager = Depends(get_experiment_manager)
):
    """List all experiments with optional filtering"""
    return manager.list_experiments(skip=skip, limit=limit, status=status)


@app.get("/api/v1/experiments/{experiment_id}", response_model=ExperimentResponse)
async def get_experiment(experiment_id: str, manager: ExperimentManager = Depends(get_experiment_manager)):
    """Get experiment details by ID"""
    experiment = manager.get_experiment(experiment_id)
    if not experiment:
        raise HTTPException(status_code=404, detail="Experiment not found")
    return experiment


@app.put("/api/v1/experiments/{experiment_id}", response_model=ExperimentResponse)
async def update_experiment(
    experiment_id: str,
    update: ExperimentUpdate,
    manager: ExperimentManager = Depends(get_experiment_manager),
    _: bool = Depends(verify_admin_token),
):
    """Update experiment configuration"""
    experiment = manager.update_experiment(experiment_id, update)
    if not experiment:
        raise HTTPException(status_code=404, detail="Experiment not found")
    return experiment


@app.delete("/api/v1/experiments/{experiment_id}")
async def delete_experiment(
    experiment_id: str,
    manager: ExperimentManager = Depends(get_experiment_manager),
    _: bool = Depends(verify_admin_token),
):
    """Delete an experiment"""
    if not manager.delete_experiment(experiment_id):
        raise HTTPException(status_code=404, detail="Experiment not found")
    return {"message": "Experiment deleted successfully"}


@app.post("/api/v1/experiments/{experiment_id}/assign", response_model=VariantAssignment)
async def assign_variant(
    experiment_id: str, user_id: str, context: dict = None, manager: ExperimentManager = Depends(get_experiment_manager)
):
    """Assign a variant to a user for an experiment"""
    assignment = manager.assign_variant(experiment_id, user_id, context or {})
    if not assignment:
        raise HTTPException(status_code=404, detail="Experiment not found")
    return assignment


@app.post("/api/v1/experiments/{experiment_id}/track")
async def track_event(
    experiment_id: str,
    user_id: str,
    event_name: str,
    value: float = 1.0,
    manager: ExperimentManager = Depends(get_experiment_manager),
):
    """Track an event for experiment analytics"""
    success = manager.track_event(experiment_id, user_id, event_name, value)
    if not success:
        raise HTTPException(status_code=404, detail="Experiment or assignment not found")
    return {"message": "Event tracked successfully"}


@app.get("/api/v1/experiments/{experiment_id}/stats", response_model=ExperimentStats)
async def get_experiment_stats(experiment_id: str, manager: ExperimentManager = Depends(get_experiment_manager)):
    """Get statistical analysis for an experiment"""
    stats = manager.get_experiment_stats(experiment_id)
    if not stats:
        raise HTTPException(status_code=404, detail="Experiment not found or insufficient data")
    return stats


@app.post("/api/v1/experiments/{experiment_id}/start")
async def start_experiment(
    experiment_id: str,
    manager: ExperimentManager = Depends(get_experiment_manager),
    _: bool = Depends(verify_admin_token),
):
    """Start an experiment"""
    experiment = manager.start_experiment(experiment_id)
    if not experiment:
        raise HTTPException(status_code=404, detail="Experiment not found")
    return experiment


@app.post("/api/v1/experiments/{experiment_id}/stop")
async def stop_experiment(
    experiment_id: str,
    manager: ExperimentManager = Depends(get_experiment_manager),
    _: bool = Depends(verify_admin_token),
):
    """Stop an experiment"""
    experiment = manager.stop_experiment(experiment_id)
    if not experiment:
        raise HTTPException(status_code=404, detail="Experiment not found")
    return experiment


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
