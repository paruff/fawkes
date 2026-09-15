"""NPS Survey sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/nps", tags=["nps"])


@router.get("/metrics")
async def get_metrics():
    """Get NPS metrics."""
    return {"nps_score": 0, "total_responses": 0, "promoters": 0, "detractors": 0}
