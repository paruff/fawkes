"""Pydantic models for API requests and responses"""
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field


class VariantConfig(BaseModel):
    """Configuration for an experiment variant"""

    name: str = Field(..., description="Variant name (e.g., 'control', 'variant-a')")
    allocation: float = Field(..., ge=0, le=1, description="Traffic allocation (0-1)")
    config: Dict[str, Any] = Field(default_factory=dict, description="Variant-specific configuration")


class ExperimentCreate(BaseModel):
    """Request model for creating an experiment"""

    name: str = Field(..., description="Experiment name")
    description: str = Field(..., description="Experiment description")
    hypothesis: str = Field(..., description="Hypothesis being tested")
    variants: List[VariantConfig] = Field(..., min_items=2, description="Experiment variants")
    metrics: List[str] = Field(..., min_items=1, description="Metrics to track")
    target_sample_size: int = Field(default=1000, ge=10, description="Target sample size per variant")
    significance_level: float = Field(default=0.05, ge=0.01, le=0.1, description="Statistical significance level")
    traffic_allocation: float = Field(default=1.0, ge=0, le=1, description="Overall traffic allocation")


class ExperimentUpdate(BaseModel):
    """Request model for updating an experiment"""

    description: Optional[str] = None
    traffic_allocation: Optional[float] = Field(None, ge=0, le=1)
    target_sample_size: Optional[int] = Field(None, ge=10)


class ExperimentResponse(BaseModel):
    """Response model for experiment details"""

    id: str
    name: str
    description: str
    hypothesis: str
    status: str
    variants: List[VariantConfig]
    metrics: List[str]
    target_sample_size: int
    significance_level: float
    traffic_allocation: float
    created_at: datetime
    started_at: Optional[datetime]
    stopped_at: Optional[datetime]

    class Config:
        from_attributes = True


class ExperimentList(BaseModel):
    """Response model for listing experiments"""

    experiments: List[ExperimentResponse]
    total: int
    skip: int
    limit: int


class VariantAssignment(BaseModel):
    """Response model for variant assignment"""

    experiment_id: str
    user_id: str
    variant: str
    assigned_at: datetime

    class Config:
        from_attributes = True


class VariantStats(BaseModel):
    """Statistics for a single variant"""

    variant: str
    sample_size: int
    conversions: int
    conversion_rate: float
    mean_value: float
    std_dev: float
    confidence_interval: tuple[float, float]


class ExperimentStats(BaseModel):
    """Statistical analysis results for an experiment"""

    experiment_id: str
    experiment_name: str
    status: str
    variants: List[VariantStats]
    control_variant: str
    winner: Optional[str] = None
    statistical_significance: bool
    p_value: float
    confidence_level: float
    effect_size: float
    recommendation: str
    sample_size_per_variant: int
    total_conversions: int
