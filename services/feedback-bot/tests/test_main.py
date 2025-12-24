"""Unit tests for Mattermost Feedback Bot."""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app.main import app, analyze_sentiment, auto_categorize, extract_rating, parse_feedback


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


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
