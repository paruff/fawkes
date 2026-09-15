"""Tests for fawkes-common shared library.

TDD: These tests define the contract for the common library.
They MUST fail before implementation, then pass after.
"""

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


class TestBaseSettings:
    """Tests for the base settings class."""

    def test_settings_has_service_name(self):
        from common.config import BaseSettings

        settings = BaseSettings(service_name="test-service")
        assert settings.service_name == "test-service"

    def test_settings_has_version(self):
        from common.config import BaseSettings

        settings = BaseSettings(service_name="x", version="1.2.3")
        assert settings.version == "1.2.3"

    def test_settings_defaults(self):
        from common.config import BaseSettings

        settings = BaseSettings(service_name="x")
        assert settings.debug is False
        assert settings.cors_origins == ["*"]

    def test_settings_case_insensitive_env(self):
        from common.config import BaseSettings

        settings = BaseSettings(service_name="x")
        assert settings.model_config.get("case_sensitive") is False


class TestHealthResponse:
    """Tests for the standardized health response model."""

    def test_health_response_fields(self):
        from common.models import HealthResponse

        resp = HealthResponse(
            status="healthy",
            service="my-service",
            version="1.0.0",
            database_connected=True,
        )
        assert resp.status == "healthy"
        assert resp.service == "my-service"
        assert resp.version == "1.0.0"
        assert resp.database_connected is True

    def test_health_response_json(self):
        from common.models import HealthResponse

        resp = HealthResponse(
            status="healthy",
            service="svc",
            version="0.1.0",
            database_connected=False,
        )
        data = resp.model_dump()
        assert data["status"] == "healthy"
        assert data["database_connected"] is False


class TestCORSMiddleware:
    """Tests for CORS middleware helper."""

    def test_add_cors_middleware_default_origins(self):
        from common.middleware import add_cors_middleware

        app = FastAPI()
        add_cors_middleware(app)
        # Middleware was added without error
        assert app.user_middleware

    def test_add_cors_middleware_custom_origins(self):
        from common.middleware import add_cors_middleware

        app = FastAPI()
        add_cors_middleware(app, origins=["https://example.com"])
        assert app.user_middleware


class TestPrometheusMetrics:
    """Tests for Prometheus metrics mounting helper."""

    def test_mount_metrics(self):
        from common.metrics import mount_metrics

        app = FastAPI()
        mount_metrics(app)
        # /metrics endpoint should be registered
        routes = [r.path for r in app.routes]
        # prometheus metrics mounts as a sub-application
        assert any("/metrics" in str(r) for r in routes)


class TestHealthEndpoint:
    """Tests for the standardized health endpoint factory."""

    def test_create_health_endpoint(self):
        from common.health import create_health_endpoint
        from fastapi.testclient import TestClient

        app = FastAPI()
        create_health_endpoint(app, service_name="test-svc", version="0.1.0")

        client = TestClient(app)
        resp = client.get("/health")
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "healthy"
        assert data["service"] == "test-svc"
        assert data["version"] == "0.1.0"

    def test_health_endpoint_with_db_check(self):
        from common.health import create_health_endpoint
        from fastapi.testclient import TestClient

        app = FastAPI()
        create_health_endpoint(
            app,
            service_name="db-svc",
            version="1.0.0",
            check_db=lambda: True,
        )

        client = TestClient(app)
        resp = client.get("/health")
        assert resp.json()["database_connected"] is True

    def test_health_endpoint_db_down(self):
        from common.health import create_health_endpoint
        from fastapi.testclient import TestClient

        app = FastAPI()
        create_health_endpoint(
            app,
            service_name="db-svc",
            version="1.0.0",
            check_db=lambda: False,
        )

        client = TestClient(app)
        resp = client.get("/health")
        assert resp.json()["database_connected"] is False
