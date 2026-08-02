"""Pydantic models for Analytics Dashboard Service"""

from datetime import datetime
from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class TimeSeriesDataPoint(BaseModel):
    """Single data point in a time series"""

    timestamp: datetime
    value: float
    label: str | None = None


class UsageTrends(BaseModel):
    """Usage trends over time"""

    total_users: int = Field(description="Total unique users")
    active_users: int = Field(description="Active users in time range")
    page_views: int = Field(description="Total page views")
    unique_visitors: int = Field(description="Unique visitors")
    avg_session_duration: float = Field(description="Average session duration in seconds")
    bounce_rate: float = Field(description="Bounce rate percentage")

    # Time series data
    users_over_time: list[TimeSeriesDataPoint] = Field(description="User activity over time")
    pageviews_over_time: list[TimeSeriesDataPoint] = Field(description="Page views over time")
    top_pages: dict[str, int] = Field(description="Top pages by view count")
    traffic_sources: dict[str, int] = Field(description="Traffic sources breakdown")


class FeatureUsage(BaseModel):
    """Individual feature usage metrics"""

    feature_name: str
    total_uses: int
    unique_users: int
    adoption_rate: float = Field(description="Percentage of users using this feature")
    trend: str = Field(description="up, down, or stable")
    first_seen: datetime | None = None
    last_used: datetime | None = None


class FeatureAdoption(BaseModel):
    """Feature adoption metrics"""

    total_features: int
    features: list[FeatureUsage]
    most_adopted: str = Field(description="Most adopted feature name")
    least_adopted: str = Field(description="Least adopted feature name")
    adoption_trend: list[TimeSeriesDataPoint] = Field(description="Overall adoption over time")


class VariantMetrics(BaseModel):
    """Metrics for a single experiment variant"""

    variant_id: str
    name: str
    assignments: int
    conversions: int
    conversion_rate: float
    confidence_interval_low: float
    confidence_interval_high: float


class ExperimentResults(BaseModel):
    """Results from A/B test experiments"""

    experiment_id: str
    experiment_name: str
    status: str = Field(description="draft, running, stopped")
    start_date: datetime | None = None
    end_date: datetime | None = None

    # Statistical analysis
    variants: list[VariantMetrics]
    winner: str | None = Field(description="Variant ID of the winner, if determined")
    p_value: float | None = Field(description="Statistical significance p-value")
    confidence_level: float = Field(default=0.95, description="Confidence level for analysis")
    is_significant: bool = Field(description="Whether results are statistically significant")
    recommendation: str = Field(description="Recommendation based on results")


class UserSegment(BaseModel):
    """Single user segment with metrics"""

    segment_name: str
    user_count: int
    percentage: float
    avg_engagement: float = Field(description="Average engagement score")
    characteristics: dict[str, Any] = Field(description="Segment characteristics")


class UserSegments(BaseModel):
    """User segmentation analysis"""

    total_users: int
    segments: list[UserSegment]
    segmentation_method: str = Field(description="Method used for segmentation")
    last_updated: datetime


class FunnelStep(BaseModel):
    """Single step in a conversion funnel"""

    step_name: str
    step_number: int
    users_entered: int
    users_completed: int
    completion_rate: float
    drop_off_rate: float
    avg_time_to_next_step: float | None = Field(description="Average time to next step in seconds")


class FunnelData(BaseModel):
    """Funnel visualization data"""

    funnel_name: str
    description: str
    steps: list[FunnelStep]
    overall_conversion_rate: float
    total_users: int
    completed_users: int
    avg_completion_time: float | None = Field(description="Average time to complete funnel in seconds")


class DashboardData(BaseModel):
    """Complete dashboard data"""

    timestamp: datetime = Field(default_factory=datetime.utcnow)
    time_range: str
    usage_trends: UsageTrends
    feature_adoption: FeatureAdoption
    experiments: list[ExperimentResults]
    user_segments: UserSegments
    funnels: dict[str, FunnelData] = Field(description="Key funnels by name")
