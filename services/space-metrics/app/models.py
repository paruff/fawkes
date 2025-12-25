"""
Database models for SPACE metrics
"""

from sqlalchemy import Column, Integer, Float, String, DateTime, JSON, Boolean
from sqlalchemy.sql import func
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()


class SpaceSatisfaction(Base):
    """Satisfaction metrics from surveys and feedback"""
    __tablename__ = "space_satisfaction"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, nullable=False, index=True)
    nps_score = Column(Float)  # -100 to 100
    satisfaction_rating = Column(Float)  # 1-5
    burnout_percentage = Column(Float)  # 0-100
    response_count = Column(Integer, default=0)
    survey_type = Column(String(50))  # nps, pulse, annual
    created_at = Column(DateTime, server_default=func.now())


class SpacePerformance(Base):
    """System and process performance metrics"""
    __tablename__ = "space_performance"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, nullable=False, index=True)
    deployment_frequency = Column(Float)  # per day
    lead_time_hours = Column(Float)
    change_failure_rate = Column(Float)  # percentage
    mttr_minutes = Column(Float)
    build_success_rate = Column(Float)  # percentage
    test_coverage = Column(Float)  # percentage
    created_at = Column(DateTime, server_default=func.now())


class SpaceActivity(Base):
    """Developer activity metrics"""
    __tablename__ = "space_activity"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, nullable=False, index=True)
    commits_count = Column(Integer, default=0)
    pull_requests_count = Column(Integer, default=0)
    code_reviews_count = Column(Integer, default=0)
    active_developers_count = Column(Integer, default=0)
    ai_tool_adoption_rate = Column(Float)  # percentage
    platform_usage_count = Column(Integer, default=0)
    created_at = Column(DateTime, server_default=func.now())


class SpaceCommunication(Base):
    """Collaboration quality metrics"""
    __tablename__ = "space_communication"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, nullable=False, index=True)
    avg_review_time_hours = Column(Float)
    pr_comments_avg = Column(Float)
    cross_team_prs = Column(Integer, default=0)
    mattermost_messages = Column(Integer, default=0)
    constructive_feedback_rate = Column(Float)  # percentage
    created_at = Column(DateTime, server_default=func.now())


class SpaceEfficiency(Base):
    """Flow and efficiency metrics"""
    __tablename__ = "space_efficiency"

    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, nullable=False, index=True)
    flow_state_days = Column(Float)  # days per week
    valuable_work_percentage = Column(Float)  # percentage
    friction_incidents = Column(Integer, default=0)
    friction_details = Column(JSON)  # friction incident details
    context_switches = Column(Float)  # per day
    cognitive_load_avg = Column(Float)  # 1-5
    created_at = Column(DateTime, server_default=func.now())
