"""Tests for fawkes-devex-service consolidated service.

TDD: These tests define the contract for the monolith.
They MUST fail before implementation, then pass after.
"""

import pytest
from fastapi.testclient import TestClient


class TestDevExServiceHealth:
    """Tests for the unified health endpoint."""

    def test_health_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/health")
        assert resp.status_code == 200

    def test_health_status_healthy(self):
        from app.main import app

        client = TestClient(app)
        data = client.get("/health").json()
        assert data["status"] == "healthy"
        assert data["service"] == "fawkes-devex-service"


class TestFeedbackRoutes:
    """Tests for Feedback sub-module routes."""

    def test_feedback_list_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/feedback")
        assert resp.status_code == 200

    def test_feedback_stats_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/feedback/stats")
        assert resp.status_code == 200


class TestFeedbackBotRoutes:
    """Tests for Feedback Bot sub-module routes."""

    def test_feedback_bot_health_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/feedback-bot/health")
        assert resp.status_code == 200


class TestNPSRoutes:
    """Tests for NPS Survey sub-module routes."""

    def test_nps_metrics_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/nps/metrics")
        assert resp.status_code == 200


class TestSurveyRoutes:
    """Tests for DevEx Survey Automation sub-module routes."""

    def test_survey_campaigns_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/survey/campaigns")
        assert resp.status_code == 200

    def test_nasa_tlx_task_types_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/nasa-tlx/task-types")
        assert resp.status_code == 200


class TestInsightsRoutes:
    """Tests for Insights sub-module routes."""

    def test_insights_list_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/insights/insights")
        assert resp.status_code == 200

    def test_insights_statistics_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/insights/statistics")
        assert resp.status_code == 200

    def test_insights_tags_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/insights/tags")
        assert resp.status_code == 200

    def test_insights_categories_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/insights/categories")
        assert resp.status_code == 200


class TestExperimentationRoutes:
    """Tests for Experimentation sub-module routes."""

    def test_experiments_list_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/experimentation/experiments")
        assert resp.status_code == 200
