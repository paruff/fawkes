"""Pydantic schemas for request/response validation."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


# Interview schemas
class InterviewBase(BaseModel):
    """Base interview schema."""

    participant_role: str = Field(..., max_length=100)
    participant_team: str = Field(..., max_length=100)
    interviewer: str = Field(..., max_length=100)
    scheduled_date: datetime
    notes: str | None = None


class InterviewCreate(InterviewBase):
    """Create interview schema."""


class InterviewUpdate(BaseModel):
    """Update interview schema."""

    completed_date: datetime | None = None
    duration_minutes: int | None = None
    status: str | None = None
    insights_generated: int | None = None
    notes: str | None = None


class InterviewResponse(InterviewBase):
    """Interview response schema."""

    id: int
    completed_date: datetime | None = None
    duration_minutes: int | None = None
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
    interview_id: int | None = None


class DiscoveryInsightCreate(DiscoveryInsightBase):
    """Create discovery insight schema."""


class DiscoveryInsightUpdate(BaseModel):
    """Update discovery insight schema."""

    status: str | None = None
    validated_date: datetime | None = None
    time_to_validation_days: float | None = None


class DiscoveryInsightResponse(DiscoveryInsightBase):
    """Discovery insight response schema."""

    id: int
    status: str
    captured_date: datetime
    validated_date: datetime | None = None
    time_to_validation_days: float | None = None
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
    insight_id: int | None = None
    success_criteria: str


class ExperimentCreate(ExperimentBase):
    """Create experiment schema."""


class ExperimentUpdate(BaseModel):
    """Update experiment schema."""

    status: str | None = None
    start_date: datetime | None = None
    end_date: datetime | None = None
    duration_days: int | None = None
    results: str | None = None
    validated: bool | None = None
    roi_percentage: float | None = None


class ExperimentResponse(ExperimentBase):
    """Experiment response schema."""

    id: int
    status: str
    start_date: datetime | None = None
    end_date: datetime | None = None
    duration_days: int | None = None
    results: str | None = None
    validated: bool
    roi_percentage: float | None = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# Feature Validation schemas
class FeatureValidationBase(BaseModel):
    """Base feature validation schema."""

    feature_name: str = Field(..., max_length=255)
    description: str
    experiment_id: int | None = None


class FeatureValidationCreate(FeatureValidationBase):
    """Create feature validation schema."""


class FeatureValidationUpdate(BaseModel):
    """Update feature validation schema."""

    status: str | None = None
    validated_date: datetime | None = None
    shipped_date: datetime | None = None
    time_to_validate_days: float | None = None
    time_to_ship_days: float | None = None
    adoption_rate: float | None = None
    user_satisfaction: float | None = None


class FeatureValidationResponse(FeatureValidationBase):
    """Feature validation response schema."""

    id: int
    status: str
    proposed_date: datetime
    validated_date: datetime | None = None
    shipped_date: datetime | None = None
    time_to_validate_days: float | None = None
    time_to_ship_days: float | None = None
    adoption_rate: float | None = None
    user_satisfaction: float | None = None
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
    avg_time_to_validation_days: float | None = None
    avg_time_to_ship_days: float | None = None
    discovery_velocity: float | None = None


class TeamPerformanceResponse(TeamPerformanceBase):
    """Team performance response schema."""

    id: int
    interviews_conducted: int
    insights_generated: int
    experiments_run: int
    features_validated: int
    features_shipped: int
    avg_time_to_validation_days: float | None = None
    avg_time_to_ship_days: float | None = None
    discovery_velocity: float | None = None
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
    avg_time_to_validation_days: float | None = None
    avg_time_to_ship_days: float | None = None
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
