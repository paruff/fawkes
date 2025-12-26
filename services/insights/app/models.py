"""Database models for Insights service."""
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import Column, Integer, String, Text, DateTime, ForeignKey, Table, Index
from sqlalchemy.orm import declarative_base, relationship
import enum

Base = declarative_base()


def utcnow():
    """Get current UTC time."""
    return datetime.now(timezone.utc)


# Association table for many-to-many relationship between insights and tags
insight_tags = Table(
    "insight_tags",
    Base.metadata,
    Column("insight_id", Integer, ForeignKey("insights.id", ondelete="CASCADE"), primary_key=True),
    Column("tag_id", Integer, ForeignKey("tags.id", ondelete="CASCADE"), primary_key=True),
    Index("idx_insight_tags_insight_id", "insight_id"),
    Index("idx_insight_tags_tag_id", "tag_id"),
)


class InsightStatus(str, enum.Enum):
    """Insight status types."""

    DRAFT = "draft"
    PUBLISHED = "published"
    ARCHIVED = "archived"


class InsightPriority(str, enum.Enum):
    """Insight priority levels."""

    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class Insight(Base):
    """Insight model - stores captured insights and learnings."""

    __tablename__ = "insights"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(500), nullable=False, index=True)
    description = Column(Text, nullable=False)
    content = Column(Text, nullable=True)  # Extended content/details
    source = Column(String(255), nullable=True)  # Where the insight came from
    author = Column(String(255), nullable=False, index=True)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True, index=True)
    priority = Column(String(20), nullable=False, default="medium", index=True)
    status = Column(String(20), nullable=False, default="draft", index=True)

    # Metadata
    created_at = Column(DateTime, default=utcnow, nullable=False, index=True)
    updated_at = Column(DateTime, default=utcnow, onupdate=utcnow, nullable=False)
    published_at = Column(DateTime, nullable=True)

    # Relationships
    category = relationship("Category", back_populates="insights")
    tags = relationship("Tag", secondary=insight_tags, back_populates="insights")

    # Add composite indexes for common queries
    __table_args__ = (
        Index("idx_insights_status_priority", "status", "priority"),
        Index("idx_insights_category_status", "category_id", "status"),
        Index("idx_insights_author_status", "author", "status"),
    )


class Category(Base):
    """Category model - hierarchical categorization for insights."""

    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False, index=True)
    slug = Column(String(100), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    parent_id = Column(Integer, ForeignKey("categories.id"), nullable=True, index=True)
    color = Column(String(7), nullable=True)  # Hex color for UI display
    icon = Column(String(50), nullable=True)  # Icon name for UI display

    # Metadata
    created_at = Column(DateTime, default=utcnow, nullable=False)
    updated_at = Column(DateTime, default=utcnow, onupdate=utcnow, nullable=False)

    # Relationships
    parent = relationship("Category", remote_side=[id], backref="subcategories")
    insights = relationship("Insight", back_populates="category")


class Tag(Base):
    """Tag model - flexible tagging system for insights."""

    __tablename__ = "tags"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(50), unique=True, nullable=False, index=True)
    slug = Column(String(50), unique=True, nullable=False, index=True)
    description = Column(Text, nullable=True)
    color = Column(String(7), nullable=True)  # Hex color for UI display

    # Metadata
    created_at = Column(DateTime, default=utcnow, nullable=False)
    usage_count = Column(Integer, default=0, nullable=False)  # Track tag popularity

    # Relationships
    insights = relationship("Insight", secondary=insight_tags, back_populates="tags")
