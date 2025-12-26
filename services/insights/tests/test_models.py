"""Tests for database models."""
import pytest
from datetime import datetime, timezone

from app.models import Insight, Tag, Category


def test_create_category(db_session):
    """Test creating a category."""
    category = Category(
        name="Technical",
        slug="technical",
        description="Technical insights",
        color="#3B82F6",
        icon="code",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(category)
    db_session.commit()

    assert category.id is not None
    assert category.name == "Technical"
    assert category.slug == "technical"


def test_create_tag(db_session):
    """Test creating a tag."""
    tag = Tag(
        name="Best Practice",
        slug="best-practice",
        description="Recommended best practice",
        color="#10B981",
        created_at=datetime.now(timezone.utc),
    )
    db_session.add(tag)
    db_session.commit()

    assert tag.id is not None
    assert tag.name == "Best Practice"
    assert tag.usage_count == 0


def test_create_insight(db_session, sample_category):
    """Test creating an insight."""
    insight = Insight(
        title="Test Insight",
        description="Test description",
        content="Test content",
        source="Test source",
        author="test-author",
        category_id=sample_category.id,
        priority="high",
        status="published",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(insight)
    db_session.commit()

    assert insight.id is not None
    assert insight.title == "Test Insight"
    assert insight.category_id == sample_category.id
    assert insight.priority == "high"


def test_insight_with_tags(db_session, sample_category, sample_tag):
    """Test creating an insight with tags."""
    insight = Insight(
        title="Test Insight",
        description="Test description",
        author="test-author",
        category_id=sample_category.id,
        priority="medium",
        status="draft",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    insight.tags = [sample_tag]
    db_session.add(insight)
    db_session.commit()

    assert len(insight.tags) == 1
    assert insight.tags[0].name == sample_tag.name


def test_category_hierarchy(db_session):
    """Test category parent-child relationships."""
    parent = Category(
        name="Parent", slug="parent", created_at=datetime.now(timezone.utc), updated_at=datetime.now(timezone.utc)
    )
    db_session.add(parent)
    db_session.commit()

    child = Category(
        name="Child",
        slug="child",
        parent_id=parent.id,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc),
    )
    db_session.add(child)
    db_session.commit()

    assert child.parent_id == parent.id
    assert len(parent.subcategories) == 1
    assert parent.subcategories[0].name == "Child"


def test_cascade_delete_insight_tags(db_session, sample_insight):
    """Test that deleting an insight removes its tag associations."""
    insight_id = sample_insight.id
    tag_count = len(sample_insight.tags)

    db_session.delete(sample_insight)
    db_session.commit()

    # Check that insight is deleted
    deleted_insight = db_session.query(Insight).filter(Insight.id == insight_id).first()
    assert deleted_insight is None

    # Tags should still exist
    tags = db_session.query(Tag).all()
    assert len(tags) >= tag_count
