"""Unit tests for Mattermost Feedback Bot."""

import os
import sys

import pytest
from fastapi.testclient import TestClient

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from app import main
from app.main import analyze_sentiment, app, auto_categorize

client = TestClient(app)


class TestHealthEndpoint:
    """Tests for health check endpoint."""

    def test_health_check(self):
        """Test health endpoint returns healthy status."""
        response = client.get("/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "healthy"
        assert data["service"] == "feedback-bot"


class TestSentimentAnalysis:
    """Tests for sentiment analysis functionality."""

    def test_positive_sentiment(self):
        """Test positive sentiment detection."""
        result = analyze_sentiment("This is amazing! I love it!")
        assert result["sentiment"] == "positive"
        assert result["compound"] > 0.05

    def test_negative_sentiment(self):
        """Test negative sentiment detection."""
        result = analyze_sentiment("This is terrible and broken.")
        assert result["sentiment"] == "negative"
        assert result["compound"] < -0.05

    def test_neutral_sentiment(self):
        """Test neutral sentiment detection."""
        result = analyze_sentiment("The system works as expected.")
        assert result["sentiment"] == "neutral"
        assert -0.05 <= result["compound"] <= 0.05


class TestAutoCategorization:
    """Tests for auto-categorization functionality."""

    def test_ui_category(self):
        """Test UI category detection."""
        category = auto_categorize("The interface design is great")
        assert category == "UI"

    def test_performance_category(self):
        """Test Performance category detection."""
        category = auto_categorize("The system is very slow and laggy")
        assert category == "Performance"

    def test_general_category_fallback(self):
        """Test fallback to General category."""
        category = auto_categorize("Random feedback text")
        assert category == "General"


class TestErrorResponseSanitization:
    """Error responses must not leak raw exception text to callers."""

    def test_slash_feedback_error_does_not_leak_exception(self, monkeypatch):
        """Error response body must not contain the exception's str()."""

        async def boom(feedback_data):
            raise RuntimeError("INTERNAL_SECRET_DETAIL_12345")

        monkeypatch.setattr(main, "submit_feedback_to_api", boom)

        response = client.post(
            "/mattermost/slash/feedback",
            data={
                "token": "",
                "user_name": "tester",
                "user_id": "u1",
                "channel_id": "c1",
                "text": "This is great feedback!",
            },
        )
        assert response.status_code == 200
        assert "INTERNAL_SECRET_DETAIL_12345" not in response.text


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
