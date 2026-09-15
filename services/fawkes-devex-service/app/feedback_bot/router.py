"""Feedback Bot sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/feedback-bot", tags=["feedback-bot"])


@router.get("/health")
async def health():
    """Feedback bot health check."""
    return {"status": "healthy"}
