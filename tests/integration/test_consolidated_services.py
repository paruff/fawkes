"""Integration tests for consolidated Fawkes services.

Run from each service's venv to avoid module import conflicts:
  services/fawkes-telemetry-engine/.venv/bin/python -m pytest tests/integration/test_telemetry_engine.py
  services/fawkes-devex-service/.venv/bin/python -m pytest tests/integration/test_devex_service.py

These tests verify all sub-module routes respond correctly.
"""

import pytest
from fastapi.testclient import TestClient


class TestTelemetryEngineIntegration:
    """Integration tests for fawkes-telemetry-engine.

    Run with: services/fawkes-telemetry-engine/.venv/bin/python -m pytest tests/integration/test_consolidated_services.py::TestTelemetryEngineIntegration -v
    """

    @pytest.fixture(autouse=True)
    def setup_client(self):
        from app.main import app

        self.client = TestClient(app)

    def test_health(self):
        resp = self.client.get("/health")
        assert resp.status_code == 200
        assert resp.json()["status"] == "healthy"
        assert resp.json()["service"] == "fawkes-telemetry-engine"

    @pytest.mark.parametrize(
        "route",
        [
            "/api/v1/vsm/stages",
            "/api/v1/vsm/work-items",
            "/api/v1/vsm/metrics",
            "/api/v1/analytics/dashboard",
            "/api/v1/analytics/usage-trends",
            "/api/v1/anomaly/anomalies",
            "/api/v1/anomaly/models",
            "/api/v1/alerting/stats",
            "/api/v1/alerting/rules",
            "/api/v1/discovery/interviews",
            "/api/v1/discovery/statistics",
            "/api/v1/space/metrics/space",
            "/api/v1/space/metrics/space/health",
        ],
    )
    def test_route_accessible(self, route):
        resp = self.client.get(route)
        assert resp.status_code == 200, f"Route {route} returned {resp.status_code}"


class TestDevExServiceIntegration:
    """Integration tests for fawkes-devex-service.

    Run with: services/fawkes-devex-service/.venv/bin/python -m pytest tests/integration/test_consolidated_services.py::TestDevExServiceIntegration -v
    """

    @pytest.fixture(autouse=True)
    def setup_client(self):
        from app.main import app

        self.client = TestClient(app)

    def test_health(self):
        resp = self.client.get("/health")
        assert resp.status_code == 200
        assert resp.json()["status"] == "healthy"
        assert resp.json()["service"] == "fawkes-devex-service"

    @pytest.mark.parametrize(
        "route",
        [
            "/api/v1/feedback",
            "/api/v1/feedback/stats",
            "/api/v1/feedback-bot/health",
            "/api/v1/nps/metrics",
            "/api/v1/survey/campaigns",
            "/api/v1/nasa-tlx/task-types",
            "/api/v1/insights/insights",
            "/api/v1/insights/statistics",
            "/api/v1/insights/tags",
            "/api/v1/insights/categories",
            "/api/v1/experimentation/experiments",
        ],
    )
    def test_route_accessible(self, route):
        resp = self.client.get(route)
        assert resp.status_code == 200, f"Route {route} returned {resp.status_code}"
