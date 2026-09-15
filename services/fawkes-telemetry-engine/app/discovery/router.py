"""Discovery Metrics sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/discovery", tags=["discovery"])


@router.get("/interviews")
async def list_interviews():
    """List discovery interviews."""
    return []


@router.get("/statistics")
async def get_statistics():
    """Get discovery statistics."""
    return {"total_interviews": 0, "completed": 0}
