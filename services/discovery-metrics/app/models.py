"""SQLAlchemy models for discovery metrics."""
from datetime import datetime
from sqlalchemy import Column, Integer, String, DateTime, Text, ForeignKey, Float, Boolean, Enum as SQLEnum
from sqlalchemy.orm import relationship
import enum
from app.database import Base


class InterviewStatus(str, enum.Enum):
    """Interview status enum."""

    SCHEDULED = "scheduled"
    COMPLETED = "completed"
    CANCELLED = "cancelled"
    NO_SHOW = "no_show"


class InsightStatus(str, enum.Enum):
    """Insight status enum."""

    DRAFT = "draft"
    VALIDATED = "validated"
    IMPLEMENTED = "implemented"
    REJECTED = "rejected"


class ExperimentStatus(str, enum.Enum):
    """Experiment status enum."""

    PLANNED = "planned"
    RUNNING = "running"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class FeatureStatus(str, enum.Enum):
    """Feature validation status enum."""

    PROPOSED = "proposed"
    VALIDATED = "validated"
    BUILDING = "building"
    SHIPPED = "shipped"
    REJECTED = "rejected"


class Interview(Base):
    """Interview tracking model."""

    __tablename__ = "interviews"

    id = Column(Integer, primary_key=True, index=True)
    participant_role = Column(String(100))
    participant_team = Column(String(100))
    interviewer = Column(String(100))
    scheduled_date = Column(DateTime)
    completed_date = Column(DateTime, nullable=True)
    duration_minutes = Column(Integer, nullable=True)
    status = Column(SQLEnum(InterviewStatus), default=InterviewStatus.SCHEDULED)
    insights_generated = Column(Integer, default=0)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    insights = relationship("DiscoveryInsight", back_populates="interview")


class DiscoveryInsight(Base):
    """Discovery insight model."""

    __tablename__ = "discovery_insights"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255))
    description = Column(Text)
    category = Column(String(100))
    priority = Column(String(50))
    status = Column(SQLEnum(InsightStatus), default=InsightStatus.DRAFT)
    source = Column(String(100))  # interview, survey, analytics, support
    interview_id = Column(Integer, ForeignKey("interviews.id"), nullable=True)
    captured_date = Column(DateTime, default=datetime.utcnow)
    validated_date = Column(DateTime, nullable=True)
    time_to_validation_days = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    interview = relationship("Interview", back_populates="insights")
    experiments = relationship("Experiment", back_populates="insight")


class Experiment(Base):
    """Experiment tracking model."""

    __tablename__ = "experiments"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255))
    description = Column(Text)
    hypothesis = Column(Text)
    insight_id = Column(Integer, ForeignKey("discovery_insights.id"), nullable=True)
    status = Column(SQLEnum(ExperimentStatus), default=ExperimentStatus.PLANNED)
    start_date = Column(DateTime, nullable=True)
    end_date = Column(DateTime, nullable=True)
    duration_days = Column(Integer, nullable=True)
    success_criteria = Column(Text)
    results = Column(Text, nullable=True)
    validated = Column(Boolean, default=False)
    roi_percentage = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    insight = relationship("DiscoveryInsight", back_populates="experiments")
    features = relationship("FeatureValidation", back_populates="experiment")


class FeatureValidation(Base):
    """Feature validation tracking model."""

    __tablename__ = "feature_validations"

    id = Column(Integer, primary_key=True, index=True)
    feature_name = Column(String(255))
    description = Column(Text)
    experiment_id = Column(Integer, ForeignKey("experiments.id"), nullable=True)
    status = Column(SQLEnum(FeatureStatus), default=FeatureStatus.PROPOSED)
    proposed_date = Column(DateTime, default=datetime.utcnow)
    validated_date = Column(DateTime, nullable=True)
    shipped_date = Column(DateTime, nullable=True)
    time_to_validate_days = Column(Float, nullable=True)
    time_to_ship_days = Column(Float, nullable=True)
    adoption_rate = Column(Float, nullable=True)
    user_satisfaction = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    experiment = relationship("Experiment", back_populates="features")


class TeamPerformance(Base):
    """Team performance metrics model."""

    __tablename__ = "team_performance"

    id = Column(Integer, primary_key=True, index=True)
    team_name = Column(String(100))
    period_start = Column(DateTime)
    period_end = Column(DateTime)
    interviews_conducted = Column(Integer, default=0)
    insights_generated = Column(Integer, default=0)
    experiments_run = Column(Integer, default=0)
    features_validated = Column(Integer, default=0)
    features_shipped = Column(Integer, default=0)
    avg_time_to_validation_days = Column(Float, nullable=True)
    avg_time_to_ship_days = Column(Float, nullable=True)
    discovery_velocity = Column(Float, nullable=True)  # insights per week
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
