"""Insights sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/insights", tags=["insights"])


@router.get("/insights")
async def list_insights():
    """List all insights."""
    return []


@router.get("/statistics")
async def get_statistics():
    """Get insight statistics."""
    return {"total_insights": 0, "by_status": {}, "by_priority": {}}


@router.get("/tags")
async def list_tags():
    """List all tags."""
    return []


@router.get("/categories")
async def list_categories():
    """List all categories."""
    return []
