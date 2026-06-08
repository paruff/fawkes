"""Unit tests for tracer-bullet FastAPI service."""

import pytest
from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


@pytest.mark.unit
def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Hello from the tracer bullet!"
    assert data["version"] == "0.1.0"


@pytest.mark.unit
def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


@pytest.mark.unit
def test_ready():
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"


@pytest.mark.unit
def test_info():
    response = client.get("/info")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "tracer-bullet"
    assert data["version"] == "0.1.0"


@pytest.mark.unit
def test_metrics_endpoint():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"http_requests_total" in response.content
