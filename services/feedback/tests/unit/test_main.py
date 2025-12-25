"""
Unit tests for feedback service main API.
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime


@pytest.fixture
def mock_db_pool():
    """Mock database pool."""
    pool = MagicMock()
    conn = AsyncMock()
    pool.acquire.return_value.__aenter__.return_value = conn
    return pool, conn


@pytest.fixture
def client():
    """Create test client."""
    # Mock the database pool before importing the app
    with patch("app.main.db_pool", MagicMock()):
        from app.main import app

        with TestClient(app) as test_client:
            yield test_client


def test_root_endpoint(client):
    """Test root endpoint returns service info."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "feedback-service"
    assert data["version"] == "2.0.0"  # Updated version
    assert "endpoints" in data
    assert "features" in data  # New field


def test_health_check_healthy(client):
    """Test health check when database is connected."""
    with patch("app.main.db_pool") as mock_pool:
        mock_conn = AsyncMock()
        mock_conn.fetchval.return_value = 1
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "feedback-service"
        assert data["database_connected"] is True


def test_health_check_degraded(client):
    """Test health check when database is not connected."""
    with patch("app.main.db_pool", None):
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "degraded"
        assert data["database_connected"] is False


def test_submit_feedback_success(client):
    """Test successful feedback submission."""
    with patch("app.main.db_pool") as mock_pool, patch("app.main.analyze_feedback_sentiment") as mock_sentiment:
        mock_sentiment.return_value = ("positive", 0.8, 0.8, 0.1, 0.1)
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "id": 1,
            "rating": 5,
            "category": "UI",
            "comment": "Great UI!",
            "email": "user@example.com",
            "page_url": "https://backstage.example.com",
            "status": "open",
            "sentiment": "positive",
            "sentiment_compound": 0.8,
            "feedback_type": "feedback",
            "browser_info": None,
            "user_agent": None,
            "github_issue_url": None,
            "has_screenshot": False,
            "created_at": datetime.now(),
            "updated_at": datetime.now(),
        }
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        feedback_data = {
            "rating": 5,
            "category": "UI",
            "comment": "Great UI!",
            "email": "user@example.com",
            "page_url": "https://backstage.example.com",
        }

        response = client.post("/api/v1/feedback", json=feedback_data)
        assert response.status_code == 201
        data = response.json()
        assert data["rating"] == 5
        assert data["category"] == "UI"
        assert data["status"] == "open"


def test_submit_feedback_validation_error(client):
    """Test feedback submission with validation error."""
    feedback_data = {"rating": 6, "category": "UI", "comment": "Test"}  # Invalid: must be 1-5

    response = client.post("/api/v1/feedback", json=feedback_data)
    assert response.status_code == 422  # Validation error


def test_submit_feedback_missing_fields(client):
    """Test feedback submission with missing required fields."""
    feedback_data = {
        "rating": 5
        # Missing category and comment
    }

    response = client.post("/api/v1/feedback", json=feedback_data)
    assert response.status_code == 422  # Validation error


def test_list_feedback_unauthorized(client):
    """Test listing feedback without authorization."""
    response = client.get("/api/v1/feedback")
    assert response.status_code == 401


def test_list_feedback_invalid_token(client):
    """Test listing feedback with invalid token."""
    response = client.get("/api/v1/feedback", headers={"Authorization": "Bearer invalid-token"})
    assert response.status_code == 403


def test_list_feedback_success(client):
    """Test successful feedback listing."""
    with patch("app.main.db_pool") as mock_pool, patch("app.main.ADMIN_TOKEN", "test-token"):
        mock_conn = AsyncMock()
        mock_conn.fetchval.return_value = 1  # Total count
        mock_conn.fetch.return_value = [
            {
                "id": 1,
                "rating": 5,
                "category": "UI",
                "comment": "Great!",
                "email": "user@example.com",
                "page_url": "https://example.com",
                "status": "open",
                "sentiment": "positive",
                "sentiment_compound": 0.8,
                "feedback_type": "feedback",
                "browser_info": None,
                "user_agent": None,
                "github_issue_url": None,
                "has_screenshot": False,
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
        ]
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        response = client.get("/api/v1/feedback", headers={"Authorization": "Bearer test-token"})
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["items"]) == 1


def test_update_feedback_status_success(client):
    """Test successful feedback status update."""
    with patch("app.main.db_pool") as mock_pool, patch("app.main.ADMIN_TOKEN", "test-token"):
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {
            "id": 1,
            "rating": 5,
            "category": "UI",
            "comment": "Great!",
            "email": "user@example.com",
            "page_url": "https://example.com",
            "status": "resolved",
            "sentiment": "positive",
            "sentiment_compound": 0.8,
            "feedback_type": "feedback",
            "browser_info": None,
            "user_agent": None,
            "github_issue_url": None,
            "has_screenshot": False,
            "created_at": datetime.now(),
            "updated_at": datetime.now(),
        }
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        response = client.put(
            "/api/v1/feedback/1/status", json={"status": "resolved"}, headers={"Authorization": "Bearer test-token"}
        )
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "resolved"


def test_update_feedback_status_invalid_status(client):
    """Test feedback status update with invalid status."""
    with patch("app.main.ADMIN_TOKEN", "test-token"), patch("app.main.db_pool", MagicMock()):
        response = client.put(
            "/api/v1/feedback/1/status",
            json={"status": "invalid-status"},
            headers={"Authorization": "Bearer test-token"},
        )
        assert response.status_code == 400


def test_get_stats_success(client):
    """Test successful statistics retrieval."""
    with patch("app.main.db_pool") as mock_pool, patch("app.main.ADMIN_TOKEN", "test-token"):
        mock_conn = AsyncMock()
        mock_conn.fetchrow.return_value = {"total": 10, "avg_rating": 4.5}
        mock_conn.fetch.side_effect = [
            [{"category": "UI", "count": 5}, {"category": "Performance", "count": 5}],
            [{"status": "open", "count": 7}, {"status": "resolved", "count": 3}],
            [{"rating": 5, "count": 5}, {"rating": 4, "count": 5}],
        ]
        mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

        response = client.get("/api/v1/feedback/stats", headers={"Authorization": "Bearer test-token"})
        assert response.status_code == 200
        data = response.json()
        assert data["total_feedback"] == 10
        assert data["average_rating"] == 4.5
        assert "by_category" in data
        assert "by_status" in data
        assert "by_rating" in data
