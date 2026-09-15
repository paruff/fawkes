"""DevEx Survey Automation sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1", tags=["survey"])


@router.get("/survey/campaigns")
async def list_campaigns():
    """List survey campaigns."""
    return []


@router.get("/nasa-tlx/task-types")
async def list_task_types():
    """List NASA-TLX task types."""
    return []
