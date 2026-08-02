"""Pydantic schemas for API request/response models."""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, ConfigDict, Field


# Tag Schemas
class TagBase(BaseModel):
    """Base tag schema."""

    name: str = Field(..., description="Tag name", min_length=1, max_length=50)
    slug: str = Field(..., description="URL-friendly slug", min_length=1, max_length=50)
    description: str | None = Field(None, description="Tag description")
    color: str | None = Field(None, description="Hex color code", pattern=r"^#[0-9A-Fa-f]{6}$")


class TagCreate(TagBase):
    """Request model for creating a tag."""


class TagUpdate(BaseModel):
    """Request model for updating a tag."""

    name: str | None = Field(None, min_length=1, max_length=50)
    slug: str | None = Field(None, min_length=1, max_length=50)
    description: str | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")


class TagResponse(TagBase):
    """Response model for tag."""

    model_config = ConfigDict(from_attributes=True)

    id: int = Field(..., description="Tag ID")
    created_at: datetime = Field(..., description="Creation timestamp")
    usage_count: int = Field(..., description="Number of insights using this tag")


# Category Schemas
class CategoryBase(BaseModel):
    """Base category schema."""

    name: str = Field(..., description="Category name", min_length=1, max_length=100)
    slug: str = Field(..., description="URL-friendly slug", min_length=1, max_length=100)
    description: str | None = Field(None, description="Category description")
    parent_id: int | None = Field(None, description="Parent category ID for hierarchy")
    color: str | None = Field(None, description="Hex color code", pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str | None = Field(None, description="Icon name for UI display")


class CategoryCreate(CategoryBase):
    """Request model for creating a category."""


class CategoryUpdate(BaseModel):
    """Request model for updating a category."""

    name: str | None = Field(None, min_length=1, max_length=100)
    slug: str | None = Field(None, min_length=1, max_length=100)
    description: str | None = None
    parent_id: int | None = None
    color: str | None = Field(None, pattern=r"^#[0-9A-Fa-f]{6}$")
    icon: str | None = None


class CategoryResponse(CategoryBase):
    """Response model for category."""

    model_config = ConfigDict(from_attributes=True)

    id: int = Field(..., description="Category ID")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    insight_count: int | None = Field(None, description="Number of insights in this category")


# Insight Schemas
class InsightBase(BaseModel):
    """Base insight schema."""

    title: str = Field(..., description="Insight title", min_length=1, max_length=500)
    description: str = Field(..., description="Short description or summary")
    content: str | None = Field(None, description="Extended content or details")
    source: str | None = Field(None, description="Source of the insight", max_length=255)
    author: str = Field(..., description="Insight author", max_length=255)
    category_id: int | None = Field(None, description="Category ID")
    priority: str = Field("medium", description="Priority level: low, medium, high, critical")
    status: str = Field("draft", description="Status: draft, published, archived")


class InsightCreate(InsightBase):
    """Request model for creating an insight."""

    tag_ids: list[int] | None = Field(default_factory=list, description="List of tag IDs")


class InsightUpdate(BaseModel):
    """Request model for updating an insight."""

    title: str | None = Field(None, min_length=1, max_length=500)
    description: str | None = None
    content: str | None = None
    source: str | None = Field(None, max_length=255)
    author: str | None = Field(None, max_length=255)
    category_id: int | None = None
    priority: str | None = None
    status: str | None = None
    tag_ids: list[int] | None = None


class InsightResponse(InsightBase):
    """Response model for insight."""

    model_config = ConfigDict(from_attributes=True)

    id: int = Field(..., description="Insight ID")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    published_at: datetime | None = Field(None, description="Publication timestamp")
    tags: list[TagResponse] = Field(default_factory=list, description="Associated tags")
    category: CategoryResponse | None = Field(None, description="Category information")


class InsightListResponse(BaseModel):
    """Response model for paginated insight list."""

    total: int = Field(..., description="Total number of insights")
    page: int = Field(..., description="Current page number")
    page_size: int = Field(..., description="Number of items per page")
    insights: list[InsightResponse] = Field(..., description="List of insights")


class InsightSearchRequest(BaseModel):
    """Request model for searching insights."""

    query: str | None = Field(None, description="Search query string")
    category_id: int | None = Field(None, description="Filter by category")
    tag_ids: list[int] | None = Field(None, description="Filter by tags (AND logic)")
    priority: str | None = Field(None, description="Filter by priority")
    status: str | None = Field(None, description="Filter by status")
    author: str | None = Field(None, description="Filter by author")
    page: int = Field(1, description="Page number", ge=1)
    page_size: int = Field(20, description="Items per page", ge=1, le=100)


# Statistics Schemas
class InsightStatistics(BaseModel):
    """Statistics about insights."""

    total_insights: int = Field(..., description="Total number of insights")
    insights_by_status: dict = Field(..., description="Count of insights by status")
    insights_by_priority: dict = Field(..., description="Count of insights by priority")
    insights_by_category: dict = Field(..., description="Count of insights by category")
    total_tags: int = Field(..., description="Total number of tags")
    total_categories: int = Field(..., description="Total number of categories")
    recent_insights: list[InsightResponse] = Field(..., description="Most recent insights")


# Health Check Schema
class HealthResponse(BaseModel):
    """Health check response."""

    status: str = Field(..., description="Service status")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    database_connected: bool = Field(..., description="Database connection status")
