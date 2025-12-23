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
