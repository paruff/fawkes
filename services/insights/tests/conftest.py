"""Test configuration and fixtures."""
import os
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from fastapi.testclient import TestClient

from app.models import Base
from app.database import get_db
from app.main import app

# Use in-memory SQLite for tests
SQLALCHEMY_DATABASE_URL = "sqlite:///./test.db"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="function")
def db_session():
    """Create a fresh database session for each test."""
    # Create tables
    Base.metadata.create_all(bind=engine)

    # Create session
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()
        # Drop all tables
        Base.metadata.drop_all(bind=engine)


@pytest.fixture(scope="function")
def client(db_session):
    """Create a test client with database dependency override."""
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db

    with TestClient(app) as test_client:
        yield test_client

    app.dependency_overrides.clear()


@pytest.fixture
def sample_category(db_session):
    """Create a sample category for testing."""
    from app.models import Category
    from datetime import datetime, timezone

    category = Category(
        name="Test Category",
        slug="test-category",
        description="Test category description",
        color="#3B82F6",
        icon="test",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    db_session.add(category)
    db_session.commit()
    db_session.refresh(category)
    return category


@pytest.fixture
def sample_tag(db_session):
    """Create a sample tag for testing."""
    from app.models import Tag
    from datetime import datetime, timezone

    tag = Tag(
        name="Test Tag",
        slug="test-tag",
        description="Test tag description",
        color="#10B981",
        created_at=datetime.now(timezone.utc)
    )
    db_session.add(tag)
    db_session.commit()
    db_session.refresh(tag)
    return tag


@pytest.fixture
def sample_insight(db_session, sample_category, sample_tag):
    """Create a sample insight for testing."""
    from app.models import Insight
    from datetime import datetime, timezone

    insight = Insight(
        title="Test Insight",
        description="Test insight description",
        content="Test insight content",
        source="Test source",
        author="test-author",
        category_id=sample_category.id,
        priority="medium",
        status="draft",
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    insight.tags = [sample_tag]
    db_session.add(insight)
    db_session.commit()
    db_session.refresh(insight)
    return insight
