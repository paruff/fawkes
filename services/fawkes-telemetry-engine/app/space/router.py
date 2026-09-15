"""SPACE Metrics sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/space", tags=["space"])


@router.get("/metrics/space")
async def get_space_metrics():
    """Get SPACE framework metrics."""
    return {"satisfaction": 0, "performance": 0, "activity": 0, "communication": 0, "efficiency": 0}


@router.get("/metrics/space/health")
async def get_space_health():
    """Get SPACE health score."""
    return {"score": 0, "status": "unknown"}
