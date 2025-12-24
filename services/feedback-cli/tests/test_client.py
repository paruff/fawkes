"""Tests for feedback API client."""

import pytest
import responses
from feedback_cli.client import FeedbackClient, FeedbackSubmission


@pytest.fixture
def client():
    """Create test client."""
    return FeedbackClient("http://test-api.com", api_key="test-key")


@responses.activate
def test_submit_feedback_success(client):
    """Test successful feedback submission."""
    responses.add(
        responses.POST,
        "http://test-api.com/api/v1/feedback",
        json={
            "id": 123,
            "rating": 5,
            "category": "UI/UX",
            "comment": "Great!",
            "status": "open",
            "created_at": "2024-01-01T00:00:00",
            "updated_at": "2024-01-01T00:00:00",
        },
        status=201,
    )

    feedback = FeedbackSubmission(
        rating=5,
        category="UI/UX",
        comment="Great!",
    )

    result = client.submit_feedback(feedback)
    
    assert result["id"] == 123
    assert result["rating"] == 5
    assert result["category"] == "UI/UX"


@responses.activate
def test_list_feedback(client):
    """Test listing feedback."""
    responses.add(
        responses.GET,
        "http://test-api.com/api/v1/feedback",
        json={
            "items": [
                {"id": 1, "rating": 5, "category": "UI/UX"},
                {"id": 2, "rating": 4, "category": "Performance"},
            ],
            "total": 2,
            "page": 1,
            "page_size": 10,
        },
        status=200,
    )

    result = client.list_feedback(limit=10)
    
    assert len(result["items"]) == 2
    assert result["total"] == 2


@responses.activate
def test_get_feedback(client):
    """Test getting specific feedback."""
    responses.add(
        responses.GET,
        "http://test-api.com/api/v1/feedback/123",
        json={
            "id": 123,
            "rating": 5,
            "category": "UI/UX",
            "comment": "Great!",
        },
        status=200,
    )

    result = client.get_feedback(123)
    
    assert result["id"] == 123


@responses.activate
def test_health_check_success(client):
    """Test successful health check."""
    responses.add(
        responses.GET,
        "http://test-api.com/health",
        json={"status": "healthy"},
        status=200,
    )

    assert client.health_check() is True


@responses.activate
def test_health_check_failure(client):
    """Test failed health check."""
    responses.add(
        responses.GET,
        "http://test-api.com/health",
        status=503,
    )

    assert client.health_check() is False


def test_client_with_api_key():
    """Test client initialization with API key."""
    client = FeedbackClient("http://test-api.com", api_key="my-key")
    
    assert "Authorization" in client.session.headers
    assert client.session.headers["Authorization"] == "Bearer my-key"


def test_client_without_api_key():
    """Test client initialization without API key."""
    client = FeedbackClient("http://test-api.com")
    
    assert "Authorization" not in client.session.headers


def test_feedback_submission_validation():
    """Test feedback submission model validation."""
    # Valid feedback
    feedback = FeedbackSubmission(
        rating=5,
        category="Test",
        comment="This is a test",
    )
    assert feedback.rating == 5
    
    # Invalid rating (too low)
    with pytest.raises(Exception):
        FeedbackSubmission(
            rating=0,
            category="Test",
            comment="Invalid",
        )
    
    # Invalid rating (too high)
    with pytest.raises(Exception):
        FeedbackSubmission(
            rating=6,
            category="Test",
            comment="Invalid",
        )


def test_feedback_submission_with_optional_fields():
    """Test feedback submission with optional fields."""
    feedback = FeedbackSubmission(
        rating=4,
        category="Test",
        comment="Test comment",
        email="test@example.com",
        page_url="https://example.com",
        feedback_type="bug_report",
    )
    
    assert feedback.email == "test@example.com"
    assert feedback.page_url == "https://example.com"
    assert feedback.feedback_type == "bug_report"
