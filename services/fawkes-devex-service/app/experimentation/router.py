"""Experimentation sub-module."""

from fastapi import APIRouter

router = APIRouter(prefix="/api/v1/experimentation", tags=["experimentation"])


@router.get("/experiments")
async def list_experiments():
    """List all experiments."""
    return []
