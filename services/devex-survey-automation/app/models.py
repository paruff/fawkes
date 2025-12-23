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
