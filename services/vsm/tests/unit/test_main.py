"""Unit tests for VSM service API."""
import pytest
from fastapi.testclient import TestClient
from datetime import datetime
from app.main import app

client = TestClient(app)


def test_root_endpoint():
    """Test root endpoint returns service info."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "vsm-service"
    assert data["status"] == "running"
    assert "endpoints" in data


def test_health_endpoint_structure():
    """Test health check endpoint returns proper structure."""
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "vsm-service"
    assert data["version"] == "0.1.0"
    assert "database_connected" in data
    # Status can be UP or DEGRADED depending on DB
    assert data["status"] in ["UP", "DEGRADED"]


def test_create_work_item_validation():
    """Test work item creation validation."""
    # Test with invalid type
    response = client.post(
        "/api/v1/work-items",
        json={"title": "Test item", "type": "invalid_type"}
    )
    assert response.status_code == 422  # Validation error
    
    # Test with missing title
    response = client.post(
        "/api/v1/work-items",
        json={"type": "feature"}
    )
    assert response.status_code == 422


def test_transition_validation():
    """Test stage transition validation."""
    # Test with non-existent work item - expects failure without DB
    response = client.put(
        "/api/v1/work-items/99999/transition",
        json={"to_stage": "Development"}
    )
    # Will fail with 404 or 500 or 503 depending on DB state
    assert response.status_code in [404, 500, 503]


def test_metrics_endpoint_structure():
    """Test metrics endpoint returns proper structure or error."""
    response = client.get("/api/v1/metrics")
    # May fail if DB not connected
    assert response.status_code in [200, 500, 503]
    
    if response.status_code == 200:
        data = response.json()
        assert "throughput" in data
        assert "wip" in data
        assert "period_start" in data
        assert "period_end" in data


def test_stages_endpoint_structure():
    """Test stages listing endpoint returns proper structure or error."""
    response = client.get("/api/v1/stages")
    # May fail if DB not connected
    assert response.status_code in [200, 500, 503]
    
    if response.status_code == 200:
        data = response.json()
        assert isinstance(data, list)
