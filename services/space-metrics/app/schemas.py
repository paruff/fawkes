"""
Pydantic schemas for API requests and responses
"""

from pydantic import BaseModel, Field
from datetime import datetime
from typing import Optional, Dict, Any


class SatisfactionMetrics(BaseModel):
    """Satisfaction dimension metrics"""
    nps_score: Optional[float] = Field(None, ge=-100, le=100, description="Net Promoter Score")
    satisfaction_rating: Optional[float] = Field(None, ge=1, le=5, description="Platform satisfaction rating")
    burnout_percentage: Optional[float] = Field(None, ge=0, le=100, description="Percentage reporting burnout")
    response_count: int = Field(0, description="Number of survey responses")

    class Config:
        from_attributes = True


class PerformanceMetrics(BaseModel):
    """Performance dimension metrics"""
    deployment_frequency: Optional[float] = Field(None, description="Deployments per day")
    lead_time_hours: Optional[float] = Field(None, description="Average lead time in hours")
    change_failure_rate: Optional[float] = Field(None, ge=0, le=100, description="Change failure rate percentage")
    mttr_minutes: Optional[float] = Field(None, description="Mean time to recovery in minutes")
    build_success_rate: Optional[float] = Field(None, ge=0, le=100, description="Build success rate percentage")
    test_coverage: Optional[float] = Field(None, ge=0, le=100, description="Test coverage percentage")

    class Config:
        from_attributes = True


class ActivityMetrics(BaseModel):
    """Activity dimension metrics"""
    commits_count: int = Field(0, description="Number of commits")
    pull_requests_count: int = Field(0, description="Number of pull requests")
    code_reviews_count: int = Field(0, description="Number of code reviews")
    active_developers_count: int = Field(0, description="Number of active developers")
    ai_tool_adoption_rate: Optional[float] = Field(None, ge=0, le=100, description="AI tool adoption percentage")
    platform_usage_count: int = Field(0, description="Platform usage count")

    class Config:
        from_attributes = True


class CommunicationMetrics(BaseModel):
    """Communication dimension metrics"""
    avg_review_time_hours: Optional[float] = Field(None, description="Average review time in hours")
    pr_comments_avg: Optional[float] = Field(None, description="Average PR comments")
    cross_team_prs: int = Field(0, description="Cross-team pull requests")
    mattermost_messages: int = Field(0, description="Mattermost messages")
    constructive_feedback_rate: Optional[float] = Field(None, ge=0, le=100, description="Constructive feedback rate")

    class Config:
        from_attributes = True


class EfficiencyMetrics(BaseModel):
    """Efficiency dimension metrics"""
    flow_state_days: Optional[float] = Field(None, description="Days per week in flow state")
    valuable_work_percentage: Optional[float] = Field(None, ge=0, le=100, description="Percentage time on valuable work")
    friction_incidents: int = Field(0, description="Number of friction incidents")
    context_switches: Optional[float] = Field(None, description="Context switches per day")
    cognitive_load_avg: Optional[float] = Field(None, ge=1, le=5, description="Average cognitive load")

    class Config:
        from_attributes = True


class SpaceMetricsResponse(BaseModel):
    """Complete SPACE metrics response"""
    satisfaction: SatisfactionMetrics
    performance: PerformanceMetrics
    activity: ActivityMetrics
    communication: CommunicationMetrics
    efficiency: EfficiencyMetrics
    health_score: float = Field(..., ge=0, le=100, description="Overall DevEx health score")
    time_range: str
    timestamp: datetime


class FrictionLogRequest(BaseModel):
    """Request to log friction incident"""
    title: str = Field(..., max_length=200, description="Brief title of friction incident")
    description: str = Field(..., description="Detailed description")
    severity: str = Field(..., description="Severity: low, medium, high, critical")
    category: Optional[str] = Field(None, description="Category: ci, deployment, documentation, etc.")

    class Config:
        json_schema_extra = {
            "example": {
                "title": "Slow CI builds",
                "description": "Jenkins builds taking over 30 minutes",
                "severity": "high",
                "category": "ci"
            }
        }


class PulseSurveyRequest(BaseModel):
    """Weekly pulse survey submission"""
    valuable_work_percentage: float = Field(..., ge=0, le=100, description="Percentage of time on valuable work")
    flow_state_days: float = Field(..., ge=0, le=7, description="Days per week achieving flow state")
    cognitive_load: float = Field(..., ge=1, le=5, description="Cognitive load rating 1-5")
    friction_experienced: Optional[bool] = Field(None, description="Experienced friction this week")

    class Config:
        json_schema_extra = {
            "example": {
                "valuable_work_percentage": 65.0,
                "flow_state_days": 3.0,
                "cognitive_load": 3.0,
                "friction_experienced": False
            }
        }
