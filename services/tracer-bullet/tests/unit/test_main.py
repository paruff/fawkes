"""Unit tests for tracer-bullet FastAPI service."""

from fastapi.testclient import TestClient

from app.main import app

client = TestClient(app)


def test_root():
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["message"] == "Hello from the tracer bullet!"
    assert data["version"] == "0.1.0"


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_ready():
    response = client.get("/ready")
    assert response.status_code == 200
    assert response.json()["status"] == "ready"


def test_info():
    response = client.get("/info")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "tracer-bullet"
    assert data["version"] == "0.1.0"


def test_metrics_endpoint():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert b"http_requests_total" in response.content
