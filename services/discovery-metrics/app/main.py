"""Main FastAPI application for Discovery Metrics service."""
import os
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, Query, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func, and_
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response
from datetime import datetime, timedelta
import logging

from app import __version__
from app.database import get_db, check_db_connection
from app.models import (
    Interview,
    InterviewStatus,
    DiscoveryInsight,
    InsightStatus,
    Experiment,
    ExperimentStatus,
    FeatureValidation,
    FeatureStatus,
    TeamPerformance,
)
from app.schemas import (
    InterviewCreate,
    InterviewUpdate,
    InterviewResponse,
    DiscoveryInsightCreate,
    DiscoveryInsightUpdate,
    DiscoveryInsightResponse,
    ExperimentCreate,
    ExperimentUpdate,
    ExperimentResponse,
    FeatureValidationCreate,
    FeatureValidationUpdate,
    FeatureValidationResponse,
    TeamPerformanceCreate,
    TeamPerformanceResponse,
    DiscoveryStatistics,
    HealthResponse,
)
from app.prometheus_exporter import update_prometheus_metrics

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Prometheus metrics
interviews_created = Counter("discovery_interviews_created_total", "Total interviews created")
insights_created = Counter("discovery_insights_created_total", "Total insights created")
experiments_created = Counter("discovery_experiments_created_total", "Total experiments created")
features_created = Counter("discovery_features_created_total", "Total features created")
api_requests = Counter("discovery_api_requests_total", "Total API requests", ["method", "endpoint"])
request_duration = Histogram("discovery_request_duration_seconds", "Request duration", ["method", "endpoint"])

# Create FastAPI app
app = FastAPI(
    title="Fawkes Discovery Metrics Service",
    description="Track discovery activities: interviews, insights, experiments, and feature validations",
    version=__version__,
    docs_url="/docs",
    redoc_url="/redoc",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Health check endpoint
@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check(db: Session = Depends(get_db)):
    """Health check endpoint."""
    return HealthResponse(
        status="healthy", service="discovery-metrics", version=__version__, database_connected=check_db_connection()
    )


# Metrics endpoint
@app.get("/metrics", tags=["Metrics"])
async def metrics(db: Session = Depends(get_db)):
    """Prometheus metrics endpoint."""
    update_prometheus_metrics(db)
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


# Interview endpoints
@app.post(
    "/api/v1/interviews", response_model=InterviewResponse, status_code=status.HTTP_201_CREATED, tags=["Interviews"]
)
async def create_interview(interview_data: InterviewCreate, db: Session = Depends(get_db)):
    """Create a new interview."""
    interview = Interview(**interview_data.model_dump())
    db.add(interview)
    db.commit()
    db.refresh(interview)
    interviews_created.inc()
    return interview


@app.get("/api/v1/interviews", response_model=List[InterviewResponse], tags=["Interviews"])
async def list_interviews(
    status_filter: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
):
    """List interviews."""
    query = db.query(Interview)
    if status_filter:
        query = query.filter(Interview.status == status_filter)
    interviews = query.order_by(Interview.scheduled_date.desc()).offset(skip).limit(limit).all()
    return interviews


@app.get("/api/v1/interviews/{interview_id}", response_model=InterviewResponse, tags=["Interviews"])
async def get_interview(interview_id: int, db: Session = Depends(get_db)):
    """Get a specific interview."""
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")
    return interview


@app.put("/api/v1/interviews/{interview_id}", response_model=InterviewResponse, tags=["Interviews"])
async def update_interview(interview_id: int, interview_data: InterviewUpdate, db: Session = Depends(get_db)):
    """Update an interview."""
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")

    for key, value in interview_data.model_dump(exclude_unset=True).items():
        setattr(interview, key, value)

    db.commit()
    db.refresh(interview)
    return interview


# Discovery Insight endpoints
@app.post(
    "/api/v1/insights", response_model=DiscoveryInsightResponse, status_code=status.HTTP_201_CREATED, tags=["Insights"]
)
async def create_insight(insight_data: DiscoveryInsightCreate, db: Session = Depends(get_db)):
    """Create a new discovery insight."""
    insight = DiscoveryInsight(**insight_data.model_dump())
    db.add(insight)
    db.commit()
    db.refresh(insight)
    insights_created.inc()
    return insight


@app.get("/api/v1/insights", response_model=List[DiscoveryInsightResponse], tags=["Insights"])
async def list_insights(
    status_filter: Optional[str] = None,
    category: Optional[str] = None,
    source: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
):
    """List discovery insights."""
    query = db.query(DiscoveryInsight)
    if status_filter:
        query = query.filter(DiscoveryInsight.status == status_filter)
    if category:
        query = query.filter(DiscoveryInsight.category == category)
    if source:
        query = query.filter(DiscoveryInsight.source == source)
    insights = query.order_by(DiscoveryInsight.captured_date.desc()).offset(skip).limit(limit).all()
    return insights


@app.get("/api/v1/insights/{insight_id}", response_model=DiscoveryInsightResponse, tags=["Insights"])
async def get_insight(insight_id: int, db: Session = Depends(get_db)):
    """Get a specific insight."""
    insight = db.query(DiscoveryInsight).filter(DiscoveryInsight.id == insight_id).first()
    if not insight:
        raise HTTPException(status_code=404, detail="Insight not found")
    return insight


@app.put("/api/v1/insights/{insight_id}", response_model=DiscoveryInsightResponse, tags=["Insights"])
async def update_insight(insight_id: int, insight_data: DiscoveryInsightUpdate, db: Session = Depends(get_db)):
    """Update a discovery insight."""
    insight = db.query(DiscoveryInsight).filter(DiscoveryInsight.id == insight_id).first()
    if not insight:
        raise HTTPException(status_code=404, detail="Insight not found")

    for key, value in insight_data.model_dump(exclude_unset=True).items():
        setattr(insight, key, value)

    # Calculate time to validation if validated
    if insight_data.validated_date and insight.captured_date:
        days = (insight_data.validated_date - insight.captured_date).days
        insight.time_to_validation_days = float(days)

    db.commit()
    db.refresh(insight)
    return insight


# Experiment endpoints
@app.post(
    "/api/v1/experiments", response_model=ExperimentResponse, status_code=status.HTTP_201_CREATED, tags=["Experiments"]
)
async def create_experiment(experiment_data: ExperimentCreate, db: Session = Depends(get_db)):
    """Create a new experiment."""
    experiment = Experiment(**experiment_data.model_dump())
    db.add(experiment)
    db.commit()
    db.refresh(experiment)
    experiments_created.inc()
    return experiment


@app.get("/api/v1/experiments", response_model=List[ExperimentResponse], tags=["Experiments"])
async def list_experiments(
    status_filter: Optional[str] = None,
    validated: Optional[bool] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
):
    """List experiments."""
    query = db.query(Experiment)
    if status_filter:
        query = query.filter(Experiment.status == status_filter)
    if validated is not None:
        query = query.filter(Experiment.validated == validated)
    experiments = query.order_by(Experiment.created_at.desc()).offset(skip).limit(limit).all()
    return experiments


@app.get("/api/v1/experiments/{experiment_id}", response_model=ExperimentResponse, tags=["Experiments"])
async def get_experiment(experiment_id: int, db: Session = Depends(get_db)):
    """Get a specific experiment."""
    experiment = db.query(Experiment).filter(Experiment.id == experiment_id).first()
    if not experiment:
        raise HTTPException(status_code=404, detail="Experiment not found")
    return experiment


@app.put("/api/v1/experiments/{experiment_id}", response_model=ExperimentResponse, tags=["Experiments"])
async def update_experiment(experiment_id: int, experiment_data: ExperimentUpdate, db: Session = Depends(get_db)):
    """Update an experiment."""
    experiment = db.query(Experiment).filter(Experiment.id == experiment_id).first()
    if not experiment:
        raise HTTPException(status_code=404, detail="Experiment not found")

    for key, value in experiment_data.model_dump(exclude_unset=True).items():
        setattr(experiment, key, value)

    # Calculate duration if end date is set
    if experiment_data.end_date and experiment.start_date:
        days = (experiment_data.end_date - experiment.start_date).days
        experiment.duration_days = days

    db.commit()
    db.refresh(experiment)
    return experiment


# Feature Validation endpoints
@app.post(
    "/api/v1/features", response_model=FeatureValidationResponse, status_code=status.HTTP_201_CREATED, tags=["Features"]
)
async def create_feature(feature_data: FeatureValidationCreate, db: Session = Depends(get_db)):
    """Create a new feature validation."""
    feature = FeatureValidation(**feature_data.model_dump())
    db.add(feature)
    db.commit()
    db.refresh(feature)
    features_created.inc()
    return feature


@app.get("/api/v1/features", response_model=List[FeatureValidationResponse], tags=["Features"])
async def list_features(
    status_filter: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
):
    """List feature validations."""
    query = db.query(FeatureValidation)
    if status_filter:
        query = query.filter(FeatureValidation.status == status_filter)
    features = query.order_by(FeatureValidation.proposed_date.desc()).offset(skip).limit(limit).all()
    return features


@app.get("/api/v1/features/{feature_id}", response_model=FeatureValidationResponse, tags=["Features"])
async def get_feature(feature_id: int, db: Session = Depends(get_db)):
    """Get a specific feature validation."""
    feature = db.query(FeatureValidation).filter(FeatureValidation.id == feature_id).first()
    if not feature:
        raise HTTPException(status_code=404, detail="Feature validation not found")
    return feature


@app.put("/api/v1/features/{feature_id}", response_model=FeatureValidationResponse, tags=["Features"])
async def update_feature(feature_id: int, feature_data: FeatureValidationUpdate, db: Session = Depends(get_db)):
    """Update a feature validation."""
    feature = db.query(FeatureValidation).filter(FeatureValidation.id == feature_id).first()
    if not feature:
        raise HTTPException(status_code=404, detail="Feature validation not found")

    for key, value in feature_data.model_dump(exclude_unset=True).items():
        setattr(feature, key, value)

    # Calculate time to validate
    if feature_data.validated_date and feature.proposed_date:
        days = (feature_data.validated_date - feature.proposed_date).days
        feature.time_to_validate_days = float(days)

    # Calculate time to ship
    if feature_data.shipped_date and feature.proposed_date:
        days = (feature_data.shipped_date - feature.proposed_date).days
        feature.time_to_ship_days = float(days)

    db.commit()
    db.refresh(feature)
    return feature


# Team Performance endpoints
@app.post(
    "/api/v1/team-performance",
    response_model=TeamPerformanceResponse,
    status_code=status.HTTP_201_CREATED,
    tags=["Team Performance"],
)
async def create_team_performance(team_data: TeamPerformanceCreate, db: Session = Depends(get_db)):
    """Create team performance record."""
    team = TeamPerformance(**team_data.model_dump())
    db.add(team)
    db.commit()
    db.refresh(team)
    return team


@app.get("/api/v1/team-performance", response_model=List[TeamPerformanceResponse], tags=["Team Performance"])
async def list_team_performance(
    team_name: Optional[str] = None,
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
):
    """List team performance records."""
    query = db.query(TeamPerformance)
    if team_name:
        query = query.filter(TeamPerformance.team_name == team_name)
    teams = query.order_by(TeamPerformance.period_end.desc()).offset(skip).limit(limit).all()
    return teams


# Statistics endpoint
@app.get("/api/v1/statistics", response_model=DiscoveryStatistics, tags=["Statistics"])
async def get_statistics(db: Session = Depends(get_db)):
    """Get discovery statistics."""
    total_interviews = db.query(Interview).count()
    completed_interviews = db.query(Interview).filter(Interview.status == InterviewStatus.COMPLETED).count()

    total_insights = db.query(DiscoveryInsight).count()
    validated_insights = (
        db.query(DiscoveryInsight)
        .filter(DiscoveryInsight.status.in_([InsightStatus.VALIDATED, InsightStatus.IMPLEMENTED]))
        .count()
    )

    total_experiments = db.query(Experiment).count()
    completed_experiments = db.query(Experiment).filter(Experiment.status == ExperimentStatus.COMPLETED).count()

    total_features = db.query(FeatureValidation).count()
    validated_features = (
        db.query(FeatureValidation)
        .filter(FeatureValidation.status.in_([FeatureStatus.VALIDATED, FeatureStatus.BUILDING, FeatureStatus.SHIPPED]))
        .count()
    )
    shipped_features = db.query(FeatureValidation).filter(FeatureValidation.status == FeatureStatus.SHIPPED).count()

    avg_validation_time = (
        db.query(func.avg(DiscoveryInsight.time_to_validation_days))
        .filter(DiscoveryInsight.time_to_validation_days.isnot(None))
        .scalar()
    )

    avg_ship_time = (
        db.query(func.avg(FeatureValidation.time_to_ship_days))
        .filter(FeatureValidation.time_to_ship_days.isnot(None))
        .scalar()
    )

    validation_rate = (validated_insights / total_insights * 100) if total_insights > 0 else 0
    experiment_success_rate = (completed_experiments / total_experiments * 100) if total_experiments > 0 else 0
    feature_validation_rate = (validated_features / total_features * 100) if total_features > 0 else 0

    return DiscoveryStatistics(
        total_interviews=total_interviews,
        completed_interviews=completed_interviews,
        total_insights=total_insights,
        validated_insights=validated_insights,
        total_experiments=total_experiments,
        completed_experiments=completed_experiments,
        total_features=total_features,
        validated_features=validated_features,
        shipped_features=shipped_features,
        avg_time_to_validation_days=float(avg_validation_time) if avg_validation_time else None,
        avg_time_to_ship_days=float(avg_ship_time) if avg_ship_time else None,
        validation_rate=validation_rate,
        experiment_success_rate=experiment_success_rate,
        feature_validation_rate=feature_validation_rate,
    )
