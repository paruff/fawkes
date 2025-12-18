"""
Unit tests for sample-python-app
"""
import pytest
from fastapi.testclient import TestClient
from app.main import app


client = TestClient(app)


def test_root_endpoint():
    """Test root endpoint returns service information"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "sample-python-app"
    assert data["status"] == "running"
    assert "version" in data


def test_health_endpoint():
    """Test health endpoint returns UP status"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "UP"
    assert data["service"] == "sample-python-app"


def test_ready_endpoint():
    """Test readiness endpoint returns READY status"""
    response = client.get("/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "READY"
    assert data["service"] == "sample-python-app"


def test_info_endpoint():
    """Test info endpoint returns service details"""
    response = client.get("/info")
    assert response.status_code == 200
    data = response.json()
    assert data["name"] == "sample-python-app"
    assert data["version"] == "0.1.0"
    assert "description" in data
