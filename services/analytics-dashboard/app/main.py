"""Analytics Dashboard Service - Main Application"""
import os
from contextlib import asynccontextmanager
from typing import AsyncGenerator, Dict, List, Optional
from datetime import datetime, timedelta

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
import httpx

from .metrics import MetricsCollector
from .data_aggregator import DataAggregator
from .models import (
    UsageTrends,
    FeatureAdoption,
    ExperimentResults,
    UserSegments,
    FunnelData,
    DashboardData
)


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncGenerator:
    """Manage application lifespan"""
    # Initialize metrics collector
    metrics_collector = MetricsCollector()
    app.state.metrics_collector = metrics_collector

    # Initialize data aggregator
    data_aggregator = DataAggregator(metrics_collector)
    app.state.data_aggregator = data_aggregator

    # Start background task to refresh metrics
    await data_aggregator.start_background_refresh()

    yield

    # Shutdown: cleanup
    await data_aggregator.stop_background_refresh()


# Create FastAPI app
app = FastAPI(
    title="Fawkes Analytics Dashboard Service",
    description="Comprehensive analytics dashboards with usage trends, feature adoption, experiment results, and user segments",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
ALLOWED_ORIGINS = os.getenv(
    "CORS_ALLOWED_ORIGINS",
    "https://backstage.fawkes.idp,https://grafana.fawkes.idp"
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


def get_data_aggregator() -> DataAggregator:
    """Dependency to get data aggregator instance"""
    return app.state.data_aggregator


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "analytics-dashboard"}


@app.get("/api/v1/dashboard", response_model=DashboardData)
async def get_dashboard_data(
    time_range: str = "7d",
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """
    Get complete dashboard data including all analytics

    Time ranges: 1h, 6h, 24h, 7d, 30d, 90d
    """
    try:
        data = await aggregator.get_dashboard_data(time_range)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch dashboard data: {str(e)}")


@app.get("/api/v1/usage-trends", response_model=UsageTrends)
async def get_usage_trends(
    time_range: str = "7d",
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """Get usage trends over time"""
    try:
        data = await aggregator.get_usage_trends(time_range)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch usage trends: {str(e)}")


@app.get("/api/v1/feature-adoption", response_model=FeatureAdoption)
async def get_feature_adoption(
    time_range: str = "30d",
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """Get feature adoption metrics"""
    try:
        data = await aggregator.get_feature_adoption(time_range)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch feature adoption: {str(e)}")


@app.get("/api/v1/experiment-results", response_model=List[ExperimentResults])
async def get_experiment_results(
    status: Optional[str] = None,
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """Get experiment results with statistical analysis"""
    try:
        data = await aggregator.get_experiment_results(status)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch experiment results: {str(e)}")


@app.get("/api/v1/user-segments", response_model=UserSegments)
async def get_user_segments(
    time_range: str = "30d",
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """Get user segment analysis"""
    try:
        data = await aggregator.get_user_segments(time_range)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch user segments: {str(e)}")


@app.get("/api/v1/funnel/{funnel_name}", response_model=FunnelData)
async def get_funnel_data(
    funnel_name: str,
    time_range: str = "30d",
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """
    Get funnel visualization data

    Available funnels: onboarding, deployment, service_creation
    """
    try:
        data = await aggregator.get_funnel_data(funnel_name, time_range)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to fetch funnel data: {str(e)}")


@app.post("/api/v1/metrics/refresh")
async def refresh_metrics(
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """Manually trigger metrics refresh"""
    try:
        await aggregator.refresh_all_metrics()
        return {"status": "success", "message": "Metrics refreshed successfully"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to refresh metrics: {str(e)}")


@app.get("/api/v1/export/{format}")
async def export_data(
    format: str,
    time_range: str = "30d",
    aggregator: DataAggregator = Depends(get_data_aggregator)
):
    """
    Export dashboard data in various formats

    Formats: json, csv
    """
    if format not in ["json", "csv"]:
        raise HTTPException(status_code=400, detail="Format must be 'json' or 'csv'")

    try:
        data = await aggregator.export_data(format, time_range)
        return data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to export data: {str(e)}")
