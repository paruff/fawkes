"""Smart Alerting sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/alerting", tags=["alerting"])


@router.get("/stats")
async def get_stats():
    """Get alerting statistics."""
    return {"total_alerts": 0, "active": 0, "resolved": 0}


@router.get("/rules")
async def list_rules():
    """List alerting rules."""
    return []
