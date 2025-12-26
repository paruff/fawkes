"""Pydantic schemas for request/response validation."""
from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field


# Interview schemas
class InterviewBase(BaseModel):
    """Base interview schema."""

    participant_role: str = Field(..., max_length=100)
    participant_team: str = Field(..., max_length=100)
    interviewer: str = Field(..., max_length=100)
    scheduled_date: datetime
    notes: Optional[str] = None


class InterviewCreate(InterviewBase):
    """Create interview schema."""

    pass


class InterviewUpdate(BaseModel):
    """Update interview schema."""

    completed_date: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    status: Optional[str] = None
    insights_generated: Optional[int] = None
    notes: Optional[str] = None


class InterviewResponse(InterviewBase):
    """Interview response schema."""

    id: int
    completed_date: Optional[datetime] = None
    duration_minutes: Optional[int] = None
    status: str
    insights_generated: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Discovery Insight schemas
class DiscoveryInsightBase(BaseModel):
    """Base discovery insight schema."""

    title: str = Field(..., max_length=255)
    description: str
    category: str = Field(..., max_length=100)
    priority: str = Field(..., max_length=50)
    source: str = Field(..., max_length=100)
    interview_id: Optional[int] = None


class DiscoveryInsightCreate(DiscoveryInsightBase):
    """Create discovery insight schema."""

    pass


class DiscoveryInsightUpdate(BaseModel):
    """Update discovery insight schema."""

    status: Optional[str] = None
    validated_date: Optional[datetime] = None
    time_to_validation_days: Optional[float] = None


class DiscoveryInsightResponse(DiscoveryInsightBase):
    """Discovery insight response schema."""

    id: int
    status: str
    captured_date: datetime
    validated_date: Optional[datetime] = None
    time_to_validation_days: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Experiment schemas
class ExperimentBase(BaseModel):
    """Base experiment schema."""

    name: str = Field(..., max_length=255)
    description: str
    hypothesis: str
    insight_id: Optional[int] = None
    success_criteria: str


class ExperimentCreate(ExperimentBase):
    """Create experiment schema."""

    pass


class ExperimentUpdate(BaseModel):
    """Update experiment schema."""

    status: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    duration_days: Optional[int] = None
    results: Optional[str] = None
    validated: Optional[bool] = None
    roi_percentage: Optional[float] = None


class ExperimentResponse(ExperimentBase):
    """Experiment response schema."""

    id: int
    status: str
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    duration_days: Optional[int] = None
    results: Optional[str] = None
    validated: bool
    roi_percentage: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Feature Validation schemas
class FeatureValidationBase(BaseModel):
    """Base feature validation schema."""

    feature_name: str = Field(..., max_length=255)
    description: str
    experiment_id: Optional[int] = None


class FeatureValidationCreate(FeatureValidationBase):
    """Create feature validation schema."""

    pass


class FeatureValidationUpdate(BaseModel):
    """Update feature validation schema."""

    status: Optional[str] = None
    validated_date: Optional[datetime] = None
    shipped_date: Optional[datetime] = None
    time_to_validate_days: Optional[float] = None
    time_to_ship_days: Optional[float] = None
    adoption_rate: Optional[float] = None
    user_satisfaction: Optional[float] = None


class FeatureValidationResponse(FeatureValidationBase):
    """Feature validation response schema."""

    id: int
    status: str
    proposed_date: datetime
    validated_date: Optional[datetime] = None
    shipped_date: Optional[datetime] = None
    time_to_validate_days: Optional[float] = None
    time_to_ship_days: Optional[float] = None
    adoption_rate: Optional[float] = None
    user_satisfaction: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Team Performance schemas
class TeamPerformanceBase(BaseModel):
    """Base team performance schema."""

    team_name: str = Field(..., max_length=100)
    period_start: datetime
    period_end: datetime


class TeamPerformanceCreate(TeamPerformanceBase):
    """Create team performance schema."""

    interviews_conducted: int = 0
    insights_generated: int = 0
    experiments_run: int = 0
    features_validated: int = 0
    features_shipped: int = 0
    avg_time_to_validation_days: Optional[float] = None
    avg_time_to_ship_days: Optional[float] = None
    discovery_velocity: Optional[float] = None


class TeamPerformanceResponse(TeamPerformanceBase):
    """Team performance response schema."""

    id: int
    interviews_conducted: int
    insights_generated: int
    experiments_run: int
    features_validated: int
    features_shipped: int
    avg_time_to_validation_days: Optional[float] = None
    avg_time_to_ship_days: Optional[float] = None
    discovery_velocity: Optional[float] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Statistics schema
class DiscoveryStatistics(BaseModel):
    """Discovery statistics schema."""

    total_interviews: int
    completed_interviews: int
    total_insights: int
    validated_insights: int
    total_experiments: int
    completed_experiments: int
    total_features: int
    validated_features: int
    shipped_features: int
    avg_time_to_validation_days: Optional[float] = None
    avg_time_to_ship_days: Optional[float] = None
    validation_rate: float
    experiment_success_rate: float
    feature_validation_rate: float


# Health check schema
class HealthResponse(BaseModel):
    """Health check response schema."""

    status: str
    service: str
    version: str
    database_connected: bool
