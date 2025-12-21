"""Pydantic schemas for API request/response models."""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from app.models import WorkItemType, StageType


# Work Item Schemas
class WorkItemCreate(BaseModel):
    """Request model for creating a work item."""
    title: str = Field(..., description="Work item title", min_length=1, max_length=500)
    type: WorkItemType = Field(..., description="Work item type")


class WorkItemResponse(BaseModel):
    """Response model for work item."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int = Field(..., description="Work item ID")
    title: str = Field(..., description="Work item title")
    type: WorkItemType = Field(..., description="Work item type")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")
    current_stage: Optional[str] = Field(None, description="Current stage name")


# Stage Transition Schemas
class StageTransitionCreate(BaseModel):
    """Request model for stage transition."""
    to_stage: str = Field(..., description="Target stage name")


class StageTransitionResponse(BaseModel):
    """Response model for stage transition."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int = Field(..., description="Transition ID")
    work_item_id: int = Field(..., description="Work item ID")
    from_stage: Optional[str] = Field(None, description="Source stage name")
    to_stage: str = Field(..., description="Target stage name")
    timestamp: datetime = Field(..., description="Transition timestamp")


# Work Item History Schema
class WorkItemHistory(BaseModel):
    """Work item stage history."""
    work_item_id: int = Field(..., description="Work item ID")
    work_item_title: str = Field(..., description="Work item title")
    transitions: List[StageTransitionResponse] = Field(..., description="Stage transitions")


# Flow Metrics Schemas
class FlowMetricsResponse(BaseModel):
    """Flow metrics response."""
    throughput: int = Field(..., description="Number of items completed in period")
    wip: float = Field(..., description="Average work in progress")
    cycle_time_avg: Optional[float] = Field(None, description="Average cycle time in hours")
    cycle_time_p50: Optional[float] = Field(None, description="Median cycle time in hours")
    cycle_time_p85: Optional[float] = Field(None, description="85th percentile cycle time in hours")
    cycle_time_p95: Optional[float] = Field(None, description="95th percentile cycle time in hours")
    period_start: datetime = Field(..., description="Period start date")
    period_end: datetime = Field(..., description="Period end date")


# Stage Response
class StageResponse(BaseModel):
    """Response model for stage."""
    model_config = ConfigDict(from_attributes=True)
    
    id: int = Field(..., description="Stage ID")
    name: str = Field(..., description="Stage name")
    order: int = Field(..., description="Stage order in value stream")
    type: StageType = Field(..., description="Stage type")


# Health Check Schema
class HealthResponse(BaseModel):
    """Health check response."""
    status: str = Field(..., description="Service status")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    database_connected: bool = Field(..., description="Database connection status")
