"""
Pydantic schemas for API requests and responses
"""
from pydantic import BaseModel, Field, EmailStr
from datetime import datetime
from typing import Optional, Dict, Any, List


class PulseSurveyResponse(BaseModel):
    """Pulse survey response data"""
    flow_state_days: float = Field(..., ge=0, le=7, description="Days per week in flow state")
    valuable_work_pct: float = Field(..., ge=0, le=100, description="Percentage time on valuable work")
    cognitive_load: float = Field(..., ge=1, le=5, description="Cognitive load rating 1-5")
    friction_incidents: bool = Field(..., description="Experienced friction this week")
    comment: Optional[str] = Field(None, max_length=1000, description="Optional feedback")
    
    class Config:
        json_schema_extra = {
            "example": {
                "flow_state_days": 3.5,
                "valuable_work_pct": 70.0,
                "cognitive_load": 3.0,
                "friction_incidents": False,
                "comment": "Great week, deployment pipeline improvements helped a lot!"
            }
        }


class SurveyDistributionRequest(BaseModel):
    """Request to distribute surveys"""
    type: str = Field(..., description="Survey type: pulse or deep_dive")
    test_mode: bool = Field(False, description="Test mode sends to limited users")
    test_users: Optional[List[str]] = Field(None, description="Specific users for test mode")
    
    class Config:
        json_schema_extra = {
            "example": {
                "type": "pulse",
                "test_mode": True,
                "test_users": ["user1@example.com", "user2@example.com"]
            }
        }


class CampaignResponse(BaseModel):
    """Campaign details response"""
    id: int
    type: str
    period: str
    year: int
    started_at: datetime
    completed_at: Optional[datetime]
    total_sent: int
    total_responses: int
    response_rate: float
    
    class Config:
        from_attributes = True


class PulseAnalytics(BaseModel):
    """Pulse survey analytics"""
    week: int
    year: int
    avg_flow_state_days: float
    avg_valuable_work_pct: float
    avg_cognitive_load: float
    friction_incidents_pct: float
    response_count: int
    
    class Config:
        from_attributes = True


class WeeklyTrend(BaseModel):
    """Weekly trend data"""
    weeks: List[int]
    flow_state_trend: List[float]
    valuable_work_trend: List[float]
    cognitive_load_trend: List[float]
    friction_trend: List[float]
    response_counts: List[int]


class ResponseRateMetrics(BaseModel):
    """Response rate metrics"""
    survey_type: str
    period: str
    total_sent: int
    total_responses: int
    response_rate: float
    target_rate: float
    status: str  # above_target, below_target, at_target


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    service: str
    version: str
    database_connected: bool
    integrations: Dict[str, bool]


class SurveySubmissionResponse(BaseModel):
    """Response after survey submission"""
    success: bool
    message: str
    recipient_id: int
    submitted_at: datetime


class NASATLXRequest(BaseModel):
    """NASA-TLX assessment request"""
    task_type: str = Field(..., description="Type of task: deployment, pr_review, incident_response, build, etc.")
    task_id: Optional[str] = Field(None, description="Optional reference to specific task")
    
    # NASA-TLX dimensions (0-100 scale)
    mental_demand: float = Field(..., ge=0, le=100, description="How mentally demanding was the task?")
    physical_demand: float = Field(..., ge=0, le=100, description="How physically demanding was the task?")
    temporal_demand: float = Field(..., ge=0, le=100, description="How hurried or rushed was the pace?")
    performance: float = Field(..., ge=0, le=100, description="How successful were you? (100=perfect, 0=failure)")
    effort: float = Field(..., ge=0, le=100, description="How hard did you have to work?")
    frustration: float = Field(..., ge=0, le=100, description="How insecure, discouraged, irritated were you?")
    
    # Optional context
    duration_minutes: Optional[int] = Field(None, ge=0, description="How long did the task take?")
    comment: Optional[str] = Field(None, max_length=2000, description="Optional feedback")
    
    class Config:
        json_schema_extra = {
            "example": {
                "task_type": "deployment",
                "task_id": "deploy-123",
                "mental_demand": 45.0,
                "physical_demand": 15.0,
                "temporal_demand": 60.0,
                "performance": 85.0,
                "effort": 50.0,
                "frustration": 30.0,
                "duration_minutes": 25,
                "comment": "Deployment went smoothly but monitoring was confusing"
            }
        }


class NASATLXResponse(BaseModel):
    """NASA-TLX assessment response"""
    id: int
    user_id: str
    task_type: str
    task_id: Optional[str]
    
    mental_demand: float
    physical_demand: float
    temporal_demand: float
    performance: float
    effort: float
    frustration: float
    overall_workload: float
    
    duration_minutes: Optional[int]
    comment: Optional[str]
    submitted_at: datetime
    
    class Config:
        from_attributes = True


class NASATLXSubmissionResponse(BaseModel):
    """Response after NASA-TLX submission"""
    success: bool
    message: str
    assessment_id: int
    overall_workload: float
    submitted_at: datetime


class NASATLXAnalytics(BaseModel):
    """NASA-TLX analytics by task type"""
    task_type: str
    week: int
    year: int
    
    avg_mental_demand: float
    avg_physical_demand: float
    avg_temporal_demand: float
    avg_performance: float
    avg_effort: float
    avg_frustration: float
    avg_overall_workload: float
    
    response_count: int
    
    class Config:
        from_attributes = True


class NASATLXTrendData(BaseModel):
    """NASA-TLX trend data over time"""
    task_type: str
    weeks: List[int]
    mental_demand_trend: List[float]
    physical_demand_trend: List[float]
    temporal_demand_trend: List[float]
    performance_trend: List[float]
    effort_trend: List[float]
    frustration_trend: List[float]
    overall_workload_trend: List[float]
    response_counts: List[int]


class TaskTypeStats(BaseModel):
    """Statistics by task type"""
    task_type: str
    total_assessments: int
    avg_workload: float
    avg_duration_minutes: Optional[float]
    most_demanding_dimension: str  # Which dimension has highest average
    health_status: str  # healthy, warning, critical based on workload
