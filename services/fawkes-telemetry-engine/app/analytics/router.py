"""Analytics Dashboard sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/analytics", tags=["analytics"])


@router.get("/dashboard")
async def get_dashboard():
    """Get analytics dashboard data."""
    return {"metrics": [], "period": "7d"}


@router.get("/usage-trends")
async def get_usage_trends():
    """Get usage trends."""
    return {"trends": []}
