"""Anomaly Detection sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/anomaly", tags=["anomaly"])


@router.get("/anomalies")
async def list_anomalies():
    """List detected anomalies."""
    return []


@router.get("/models")
async def list_models():
    """List anomaly detection models."""
    return []
