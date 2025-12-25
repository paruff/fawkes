"""
Unit tests for enhanced feedback service features.
Tests screenshot capture, GitHub integration, and contextual data.
"""
import pytest
import base64
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime


@pytest.fixture
def client():
    """Create test client."""
    with patch("app.main.db_pool", MagicMock()):
        from app.main import app

        with TestClient(app) as test_client:
            yield test_client


@pytest.fixture
def sample_screenshot():
    """Generate a small sample screenshot as base64."""
    # 1x1 PNG pixel (red)
    png_data = (
        b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01"
        b"\x00\x00\x00\x01\x08\x02\x00\x00\x00\x90wS\xde\x00\x00"
        b"\x00\x0cIDATx\x9cc\xf8\xcf\xc0\x00\x00\x00\x00\xff\xff"
        b"\x03\x00\x00\x05\x00\x01\xa5\xf6E@\x00\x00\x00\x00IEND\xaeB`\x82"
    )
    return base64.b64encode(png_data).decode("utf-8")


class TestEnhancedFeedbackSubmission:
    """Tests for enhanced feedback submission with new fields."""

    def test_submit_feedback_with_type(self, client):
        """Test submitting feedback with feedback_type."""
        with patch("app.main.db_pool") as mock_pool, patch("app.main.analyze_feedback_sentiment") as mock_sentiment:
            mock_sentiment.return_value = ("positive", 0.8, 0.8, 0.1, 0.1)
            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = {
                "id": 1,
                "rating": 5,
                "category": "Features",
                "comment": "Great feature!",
                "email": "test@example.com",
                "page_url": "https://example.com",
                "status": "open",
                "sentiment": "positive",
                "sentiment_compound": 0.8,
                "feedback_type": "feature_request",
                "browser_info": "Chrome 120",
                "user_agent": "Mozilla/5.0",
                "github_issue_url": None,
                "has_screenshot": False,
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.post(
                "/api/v1/feedback",
                json={
                    "rating": 5,
                    "category": "Features",
                    "comment": "Great feature!",
                    "email": "test@example.com",
                    "page_url": "https://example.com",
                    "feedback_type": "feature_request",
                },
            )

            assert response.status_code == 201
            data = response.json()
            assert data["feedback_type"] == "feature_request"

    def test_submit_feedback_with_screenshot(self, client, sample_screenshot):
        """Test submitting feedback with screenshot."""
        with patch("app.main.db_pool") as mock_pool, patch("app.main.analyze_feedback_sentiment") as mock_sentiment:
            mock_sentiment.return_value = ("neutral", 0.0, 0.5, 0.5, 0.0)
            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = {
                "id": 2,
                "rating": 3,
                "category": "Bug Report",
                "comment": "Found a bug",
                "email": None,
                "page_url": "https://example.com/page",
                "status": "open",
                "sentiment": "neutral",
                "sentiment_compound": 0.0,
                "feedback_type": "bug_report",
                "browser_info": "Firefox 121",
                "user_agent": "Mozilla/5.0 Firefox",
                "github_issue_url": None,
                "has_screenshot": True,
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.post(
                "/api/v1/feedback",
                json={
                    "rating": 3,
                    "category": "Bug Report",
                    "comment": "Found a bug",
                    "feedback_type": "bug_report",
                    "screenshot": f"data:image/png;base64,{sample_screenshot}",
                    "browser_info": "Firefox 121",
                    "user_agent": "Mozilla/5.0 Firefox",
                },
            )

            assert response.status_code == 201
            data = response.json()
            assert data["has_screenshot"] is True
            assert data["browser_info"] == "Firefox 121"

    def test_submit_feedback_with_contextual_data(self, client):
        """Test submitting feedback with browser and user agent info."""
        with patch("app.main.db_pool") as mock_pool, patch("app.main.analyze_feedback_sentiment") as mock_sentiment:
            mock_sentiment.return_value = ("positive", 0.5, 0.6, 0.3, 0.1)
            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = {
                "id": 3,
                "rating": 4,
                "category": "UI/UX",
                "comment": "Nice design",
                "email": None,
                "page_url": "https://example.com",
                "status": "open",
                "sentiment": "positive",
                "sentiment_compound": 0.5,
                "feedback_type": "feedback",
                "browser_info": "Safari 17.1",
                "user_agent": "Mozilla/5.0 Safari/17.1",
                "github_issue_url": None,
                "has_screenshot": False,
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.post(
                "/api/v1/feedback",
                json={
                    "rating": 4,
                    "category": "UI/UX",
                    "comment": "Nice design",
                    "feedback_type": "feedback",
                    "browser_info": "Safari 17.1",
                    "user_agent": "Mozilla/5.0 Safari/17.1",
                    "page_url": "https://example.com",
                },
            )

            assert response.status_code == 201
            data = response.json()
            assert data["browser_info"] == "Safari 17.1"
            assert data["user_agent"] == "Mozilla/5.0 Safari/17.1"

    def test_submit_feedback_invalid_type(self, client):
        """Test submitting feedback with invalid feedback_type."""
        with patch("app.main.db_pool", MagicMock()):
            response = client.post(
                "/api/v1/feedback",
                json={"rating": 5, "category": "Other", "comment": "Test", "feedback_type": "invalid_type"},
            )

            assert response.status_code == 400
            assert "Invalid feedback_type" in response.json()["detail"]

    def test_submit_feedback_screenshot_too_large(self, client):
        """Test submitting feedback with too large screenshot."""
        # Generate a large base64 string (> 5MB)
        large_data = base64.b64encode(b"x" * (6 * 1024 * 1024)).decode("utf-8")

        with patch("app.main.db_pool") as mock_pool, patch("app.main.analyze_feedback_sentiment") as mock_sentiment:
            mock_sentiment.return_value = ("neutral", 0.0, 0.5, 0.5, 0.0)
            mock_pool.acquire.return_value.__aenter__.return_value = AsyncMock()

            response = client.post(
                "/api/v1/feedback",
                json={
                    "rating": 3,
                    "category": "Bug Report",
                    "comment": "Bug with large screenshot",
                    "feedback_type": "bug_report",
                    "screenshot": large_data,
                },
            )

            assert response.status_code == 400
            detail = response.json()["detail"]
            # Error could be wrapped in another error message
            assert "large" in detail.lower() or "Invalid screenshot" in detail

    def test_submit_feedback_invalid_screenshot(self, client):
        """Test submitting feedback with invalid screenshot data."""
        with patch("app.main.db_pool") as mock_pool, patch("app.main.analyze_feedback_sentiment") as mock_sentiment:
            mock_sentiment.return_value = ("neutral", 0.0, 0.5, 0.5, 0.0)
            mock_pool.acquire.return_value.__aenter__.return_value = AsyncMock()

            response = client.post(
                "/api/v1/feedback",
                json={
                    "rating": 3,
                    "category": "Bug Report",
                    "comment": "Bug with invalid screenshot",
                    "feedback_type": "bug_report",
                    "screenshot": "not-valid-base64!@#",
                },
            )

            assert response.status_code == 400
            assert "Invalid screenshot data" in response.json()["detail"]


class TestGitHubIntegration:
    """Tests for GitHub integration in feedback submission."""

    def test_submit_feedback_with_github_issue_creation(self, client):
        """Test submitting feedback with GitHub issue creation."""
        with patch("app.main.db_pool") as mock_pool, patch(
            "app.main.analyze_feedback_sentiment"
        ) as mock_sentiment, patch("app.main.is_github_enabled") as mock_gh_enabled, patch(
            "app.main.create_github_issue"
        ) as mock_create_issue:
            mock_sentiment.return_value = ("negative", -0.5, 0.2, 0.3, 0.5)
            mock_gh_enabled.return_value = True
            mock_create_issue.return_value = (True, "https://github.com/test/repo/issues/123", None)

            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = {
                "id": 4,
                "rating": 2,
                "category": "Bug Report",
                "comment": "Critical bug",
                "email": "user@example.com",
                "page_url": "https://example.com",
                "status": "open",
                "sentiment": "negative",
                "sentiment_compound": -0.5,
                "feedback_type": "bug_report",
                "browser_info": "Chrome 120",
                "user_agent": "Mozilla/5.0",
                "github_issue_url": None,
                "has_screenshot": False,
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
            mock_conn.execute = AsyncMock()
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.post(
                "/api/v1/feedback",
                json={
                    "rating": 2,
                    "category": "Bug Report",
                    "comment": "Critical bug",
                    "email": "user@example.com",
                    "feedback_type": "bug_report",
                    "create_github_issue": True,
                },
            )

            assert response.status_code == 201
            # GitHub issue creation happens in background task

    def test_submit_feedback_github_disabled(self, client):
        """Test submitting feedback when GitHub integration is disabled."""
        with patch("app.main.db_pool") as mock_pool, patch(
            "app.main.analyze_feedback_sentiment"
        ) as mock_sentiment, patch("app.main.is_github_enabled") as mock_gh_enabled:
            mock_sentiment.return_value = ("neutral", 0.0, 0.5, 0.5, 0.0)
            mock_gh_enabled.return_value = False

            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = {
                "id": 5,
                "rating": 3,
                "category": "Features",
                "comment": "Feature request",
                "email": None,
                "page_url": "https://example.com",
                "status": "open",
                "sentiment": "neutral",
                "sentiment_compound": 0.0,
                "feedback_type": "feature_request",
                "browser_info": None,
                "user_agent": None,
                "github_issue_url": None,
                "has_screenshot": False,
                "created_at": datetime.now(),
                "updated_at": datetime.now(),
            }
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.post(
                "/api/v1/feedback",
                json={
                    "rating": 3,
                    "category": "Features",
                    "comment": "Feature request",
                    "feedback_type": "feature_request",
                    "create_github_issue": True,
                },
            )

            assert response.status_code == 201
            # No error even though GitHub is disabled


class TestScreenshotRetrieval:
    """Tests for screenshot retrieval endpoint."""

    def test_get_screenshot_success(self, client, sample_screenshot):
        """Test successful screenshot retrieval."""
        screenshot_bytes = base64.b64decode(sample_screenshot)

        with patch("app.main.db_pool") as mock_pool, patch("app.main.ADMIN_TOKEN", "test-token"):
            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = {"screenshot": screenshot_bytes}
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.get("/api/v1/feedback/1/screenshot", headers={"Authorization": "Bearer test-token"})

            assert response.status_code == 200
            data = response.json()
            assert "screenshot" in data
            assert "feedback_id" in data
            assert data["feedback_id"] == 1
            assert "size_bytes" in data

    def test_get_screenshot_not_found(self, client):
        """Test retrieving screenshot for non-existent feedback."""
        with patch("app.main.db_pool") as mock_pool, patch("app.main.ADMIN_TOKEN", "test-token"):
            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = None
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.get("/api/v1/feedback/999/screenshot", headers={"Authorization": "Bearer test-token"})

            assert response.status_code == 404
            assert "not found" in response.json()["detail"]

    def test_get_screenshot_no_screenshot_available(self, client):
        """Test retrieving screenshot when none exists."""
        with patch("app.main.db_pool") as mock_pool, patch("app.main.ADMIN_TOKEN", "test-token"):
            mock_conn = AsyncMock()
            mock_conn.fetchrow.return_value = {"screenshot": None}
            mock_pool.acquire.return_value.__aenter__.return_value = mock_conn

            response = client.get("/api/v1/feedback/1/screenshot", headers={"Authorization": "Bearer test-token"})

            assert response.status_code == 404
            assert "No screenshot available" in response.json()["detail"]

    def test_get_screenshot_unauthorized(self, client):
        """Test retrieving screenshot without authorization."""
        response = client.get("/api/v1/feedback/1/screenshot")
        assert response.status_code == 401


class TestRootEndpoint:
    """Tests for enhanced root endpoint."""

    def test_root_endpoint_with_github_enabled(self, client):
        """Test root endpoint shows GitHub integration status."""
        with patch("app.main.is_github_enabled", return_value=True):
            response = client.get("/")
            assert response.status_code == 200
            data = response.json()
            assert data["version"] == "2.0.0"
            assert "features" in data
            assert data["features"]["github_integration"] is True
            assert data["features"]["screenshot_capture"] is True
            assert "feedback_types" in data["features"]

    def test_root_endpoint_with_github_disabled(self, client):
        """Test root endpoint when GitHub integration is disabled."""
        with patch("app.main.is_github_enabled", return_value=False):
            response = client.get("/")
            assert response.status_code == 200
            data = response.json()
            assert data["features"]["github_integration"] is False
