"""Feedback sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/feedback", tags=["feedback"])


@router.get("")
async def list_feedback():
    """List all feedback items."""
    return []


@router.get("/stats")
async def get_stats():
    """Get feedback statistics."""
    return {"total_feedback": 0, "by_category": {}, "by_status": {}}
