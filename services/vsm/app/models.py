"""Database models for VSM service."""
from datetime import datetime
from typing import Optional
from sqlalchemy import Column, Integer, String, DateTime, ForeignKey, Float, Enum as SQLEnum
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import relationship
import enum

Base = declarative_base()


class WorkItemType(str, enum.Enum):
    """Work item types."""
    FEATURE = "feature"
    BUG = "bug"
    TASK = "task"
    EPIC = "epic"


class StageType(str, enum.Enum):
    """Stage types in value stream."""
    BACKLOG = "backlog"
    ANALYSIS = "analysis"
    DEVELOPMENT = "development"
    TESTING = "testing"
    DEPLOYMENT = "deployment"
    PRODUCTION = "production"


class WorkItem(Base):
    """Work item model."""
    __tablename__ = "work_items"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(500), nullable=False)
    type = Column(SQLEnum(WorkItemType), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)
    
    # Relationships
    transitions = relationship("StageTransition", back_populates="work_item", cascade="all, delete-orphan")


class Stage(Base):
    """Stage model."""
    __tablename__ = "stages"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    order = Column(Integer, nullable=False)
    type = Column(SQLEnum(StageType), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Relationships
    transitions_from = relationship(
        "StageTransition",
        foreign_keys="StageTransition.from_stage_id",
        back_populates="from_stage"
    )
    transitions_to = relationship(
        "StageTransition",
        foreign_keys="StageTransition.to_stage_id",
        back_populates="to_stage"
    )


class StageTransition(Base):
    """Stage transition model."""
    __tablename__ = "stage_transitions"
    
    id = Column(Integer, primary_key=True, index=True)
    work_item_id = Column(Integer, ForeignKey("work_items.id"), nullable=False, index=True)
    from_stage_id = Column(Integer, ForeignKey("stages.id"), nullable=True)  # NULL for initial state
    to_stage_id = Column(Integer, ForeignKey("stages.id"), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)
    
    # Relationships
    work_item = relationship("WorkItem", back_populates="transitions")
    from_stage = relationship("Stage", foreign_keys=[from_stage_id], back_populates="transitions_from")
    to_stage = relationship("Stage", foreign_keys=[to_stage_id], back_populates="transitions_to")


class FlowMetrics(Base):
    """Flow metrics aggregated by time period."""
    __tablename__ = "flow_metrics"
    
    id = Column(Integer, primary_key=True, index=True)
    date = Column(DateTime, nullable=False, index=True)
    period_type = Column(String(20), nullable=False)  # 'day' or 'week'
    
    # Flow metrics
    throughput = Column(Integer, default=0)  # Number of items completed
    wip = Column(Float, default=0.0)  # Average work in progress
    cycle_time_avg = Column(Float, nullable=True)  # Average cycle time in hours
    cycle_time_p50 = Column(Float, nullable=True)  # Median cycle time
    cycle_time_p85 = Column(Float, nullable=True)  # 85th percentile
    cycle_time_p95 = Column(Float, nullable=True)  # 95th percentile
    
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
