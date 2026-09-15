"""VSM (Value Stream Mapping) sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/vsm", tags=["vsm"])


@router.get("/stages")
async def list_stages():
    """List all VSM stages."""
    return []


@router.get("/work-items")
async def list_work_items():
    """List all work items."""
    return []


@router.get("/metrics")
async def get_metrics():
    """Get VSM metrics."""
    return {"cycle_time": 0, "lead_time": 0, "throughput": 0}
