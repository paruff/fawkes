"""SQLAlchemy database schema"""
from datetime import datetime
from sqlalchemy import Column, String, Integer, Float, DateTime, JSON, ForeignKey, Text, Boolean
from sqlalchemy.orm import relationship

from .database import Base


class Experiment(Base):
    """Experiment database model"""
    __tablename__ = "experiments"

    id = Column(String, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    description = Column(Text, nullable=False)
    hypothesis = Column(Text, nullable=False)
    status = Column(String, default="draft", index=True)  # draft, running, stopped, completed
    variants = Column(JSON, nullable=False)  # List of variant configurations
    metrics = Column(JSON, nullable=False)  # List of metrics to track
    target_sample_size = Column(Integer, default=1000)
    significance_level = Column(Float, default=0.05)
    traffic_allocation = Column(Float, default=1.0)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    started_at = Column(DateTime, nullable=True)
    stopped_at = Column(DateTime, nullable=True)

    # Relationships
    assignments = relationship("Assignment", back_populates="experiment", cascade="all, delete-orphan")
    events = relationship("Event", back_populates="experiment", cascade="all, delete-orphan")


class Assignment(Base):
    """Variant assignment database model"""
    __tablename__ = "assignments"

    id = Column(Integer, primary_key=True, index=True)
    experiment_id = Column(String, ForeignKey("experiments.id"), nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)
    variant = Column(String, nullable=False, index=True)
    context = Column(JSON, nullable=True)  # Additional context data
    assigned_at = Column(DateTime, default=datetime.utcnow, nullable=False)

    # Relationships
    experiment = relationship("Experiment", back_populates="assignments")
    events = relationship("Event", back_populates="assignment")


class Event(Base):
    """Event tracking database model"""
    __tablename__ = "events"

    id = Column(Integer, primary_key=True, index=True)
    experiment_id = Column(String, ForeignKey("experiments.id"), nullable=False, index=True)
    assignment_id = Column(Integer, ForeignKey("assignments.id"), nullable=False, index=True)
    user_id = Column(String, nullable=False, index=True)
    variant = Column(String, nullable=False, index=True)
    event_name = Column(String, nullable=False, index=True)
    value = Column(Float, default=1.0)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    # Relationships
    experiment = relationship("Experiment", back_populates="events")
    assignment = relationship("Assignment", back_populates="events")
