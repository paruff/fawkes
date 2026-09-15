"""Tests for fawkes-telemetry-engine consolidated service.

TDD: These tests define the contract for the monolith.
They MUST fail before implementation, then pass after.
"""

import pytest
from fastapi.testclient import TestClient


class TestTelemetryEngineHealth:
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
        assert data["service"] == "fawkes-telemetry-engine"

    def test_health_includes_version(self):
        from app.main import app

        client = TestClient(app)
        data = client.get("/health").json()
        assert "version" in data


class TestVSMRoutes:
    """Tests for VSM sub-module routes."""

    def test_vsm_stages_returns_list(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/vsm/stages")
        assert resp.status_code == 200

    def test_vsm_work_items_returns_list(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/vsm/work-items")
        assert resp.status_code == 200

    def test_vsm_metrics_returns_dict(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/vsm/metrics")
        assert resp.status_code == 200


class TestAnalyticsRoutes:
    """Tests for Analytics sub-module routes."""

    def test_analytics_dashboard_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/analytics/dashboard")
        assert resp.status_code == 200

    def test_analytics_usage_trends_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/analytics/usage-trends")
        assert resp.status_code == 200


class TestAnomalyRoutes:
    """Tests for Anomaly Detection sub-module routes."""

    def test_anomaly_list_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/anomaly/anomalies")
        assert resp.status_code == 200

    def test_anomaly_models_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/anomaly/models")
        assert resp.status_code == 200


class TestAlertingRoutes:
    """Tests for Smart Alerting sub-module routes."""

    def test_alerting_stats_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/alerting/stats")
        assert resp.status_code == 200

    def test_alerting_rules_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/alerting/rules")
        assert resp.status_code == 200


class TestDiscoveryRoutes:
    """Tests for Discovery Metrics sub-module routes."""

    def test_discovery_interviews_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/discovery/interviews")
        assert resp.status_code == 200

    def test_discovery_statistics_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/discovery/statistics")
        assert resp.status_code == 200


class TestSpaceRoutes:
    """Tests for SPACE Metrics sub-module routes."""

    def test_space_metrics_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/space/metrics/space")
        assert resp.status_code == 200

    def test_space_health_returns_200(self):
        from app.main import app

        client = TestClient(app)
        resp = client.get("/api/v1/space/metrics/space/health")
        assert resp.status_code == 200
