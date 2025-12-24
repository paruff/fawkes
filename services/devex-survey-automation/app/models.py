"""
Database models for DevEx Survey Automation
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, JSON, Text
from sqlalchemy.orm import declarative_base, relationship
from sqlalchemy.sql import func

Base = declarative_base()


class SurveyCampaign(Base):
    """Survey campaign tracking"""
    __tablename__ = "survey_campaigns"
    
    id = Column(Integer, primary_key=True)
    type = Column(String(50), nullable=False)  # pulse, deep_dive
    period = Column(String(20), nullable=False)  # week number or quarter (Q1, Q2, etc.)
    year = Column(Integer, nullable=False)
    started_at = Column(DateTime, default=func.now())
    completed_at = Column(DateTime, nullable=True)
    total_sent = Column(Integer, default=0)
    total_responses = Column(Integer, default=0)
    response_rate = Column(Float, default=0.0)
    
    # Relationships
    recipients = relationship("SurveyRecipient", back_populates="campaign", cascade="all, delete-orphan")


class SurveyRecipient(Base):
    """Individual survey recipient tracking"""
    __tablename__ = "survey_recipients"
    
    id = Column(Integer, primary_key=True)
    campaign_id = Column(Integer, ForeignKey("survey_campaigns.id"), nullable=False)
    user_id = Column(String(255), nullable=False)
    email = Column(String(255), nullable=False)
    mattermost_id = Column(String(255), nullable=True)
    slack_id = Column(String(255), nullable=True)
    token = Column(String(64), unique=True, nullable=False)
    sent_at = Column(DateTime, default=func.now())
    responded_at = Column(DateTime, nullable=True)
    reminder_sent = Column(Boolean, default=False)
    reminder_sent_at = Column(DateTime, nullable=True)
    response_data = Column(JSON, nullable=True)
    
    # Relationships
    campaign = relationship("SurveyCampaign", back_populates="recipients")


class PulseSurveyAggregate(Base):
    """Aggregated pulse survey metrics by week"""
    __tablename__ = "pulse_survey_aggregates"
    
    id = Column(Integer, primary_key=True)
    week = Column(Integer, nullable=False)  # ISO week number
    year = Column(Integer, nullable=False)
    avg_flow_state_days = Column(Float, nullable=True)
    avg_valuable_work_pct = Column(Float, nullable=True)
    avg_cognitive_load = Column(Float, nullable=True)
    friction_incidents_pct = Column(Float, nullable=True)
    response_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=func.now())
    
    # Unique constraint on week/year
    __table_args__ = (
        {"schema": None}  # Use default schema
    )


class SurveyOptOut(Base):
    """Track users who have opted out of automated surveys"""
    __tablename__ = "survey_opt_outs"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(String(255), unique=True, nullable=False)
    email = Column(String(255), nullable=False)
    opted_out_at = Column(DateTime, default=func.now())
    reason = Column(Text, nullable=True)


class NASATLXAssessment(Base):
    """NASA-TLX cognitive load assessment responses"""
    __tablename__ = "nasa_tlx_assessments"
    
    id = Column(Integer, primary_key=True)
    user_id = Column(String(255), nullable=False)
    task_type = Column(String(100), nullable=False)  # deployment, pr_review, incident_response, etc.
    task_id = Column(String(255), nullable=True)  # Optional reference to specific task
    
    # NASA-TLX dimensions (0-100 scale)
    mental_demand = Column(Float, nullable=False)  # How mentally demanding was the task?
    physical_demand = Column(Float, nullable=False)  # How physically demanding was the task?
    temporal_demand = Column(Float, nullable=False)  # How hurried or rushed was the pace?
    performance = Column(Float, nullable=False)  # How successful were you?
    effort = Column(Float, nullable=False)  # How hard did you have to work?
    frustration = Column(Float, nullable=False)  # How insecure, discouraged, irritated were you?
    
    # Calculated scores
    overall_workload = Column(Float, nullable=False)  # Average of all dimensions
    weighted_workload = Column(Float, nullable=True)  # Optional weighted score
    
    # Context
    duration_minutes = Column(Integer, nullable=True)  # How long did the task take?
    comment = Column(Text, nullable=True)  # Optional feedback
    platform_version = Column(String(50), nullable=True)  # Platform version during assessment
    
    # Metadata
    submitted_at = Column(DateTime, default=func.now())
    created_at = Column(DateTime, default=func.now())


class NASATLXAggregate(Base):
    """Aggregated NASA-TLX metrics by task type and time period"""
    __tablename__ = "nasa_tlx_aggregates"
    
    id = Column(Integer, primary_key=True)
    task_type = Column(String(100), nullable=False)
    week = Column(Integer, nullable=False)  # ISO week number
    year = Column(Integer, nullable=False)
    
    # Average scores
    avg_mental_demand = Column(Float, nullable=True)
    avg_physical_demand = Column(Float, nullable=True)
    avg_temporal_demand = Column(Float, nullable=True)
    avg_performance = Column(Float, nullable=True)
    avg_effort = Column(Float, nullable=True)
    avg_frustration = Column(Float, nullable=True)
    avg_overall_workload = Column(Float, nullable=True)
    
    # Statistics
    response_count = Column(Integer, default=0)
    created_at = Column(DateTime, default=func.now())
