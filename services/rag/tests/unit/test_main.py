"""
Unit tests for RAG service main application.
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Add parent directory to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "../.."))

from app.main import app, WEAVIATE_URL, SCHEMA_NAME, DEFAULT_TOP_K, DEFAULT_THRESHOLD


@pytest.fixture
def client():
    """Create test client."""
    return TestClient(app)


@pytest.fixture
def mock_weaviate_client():
    """Create mock Weaviate client."""
    mock = MagicMock()
    mock.is_ready.return_value = True
    return mock


def test_root_endpoint(client):
    """Test root endpoint returns service info."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "rag-service"
    assert data["status"] == "running"
    assert "endpoints" in data


def test_health_endpoint_no_weaviate(client):
    """Test health endpoint when Weaviate is not connected."""
    with patch("app.main.weaviate_client", None):
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "DEGRADED"
        assert data["weaviate_connected"] is False


def test_health_endpoint_with_weaviate(client, mock_weaviate_client):
    """Test health endpoint when Weaviate is connected."""
    with patch("app.main.weaviate_client", mock_weaviate_client):
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "UP"
        assert data["weaviate_connected"] is True
        assert data["service"] == "rag-service"
        assert data["version"] == "0.1.0"


def test_ready_endpoint_not_ready(client):
    """Test ready endpoint when service is not ready."""
    with patch("app.main.weaviate_client", None):
        response = client.get("/ready")
        assert response.status_code == 503


def test_ready_endpoint_ready(client, mock_weaviate_client):
    """Test ready endpoint when service is ready."""
    with patch("app.main.weaviate_client", mock_weaviate_client):
        response = client.get("/ready")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "READY"


def test_query_endpoint_no_weaviate(client):
    """Test query endpoint when Weaviate is not connected."""
    with patch("app.main.weaviate_client", None):
        response = client.post(
            "/api/v1/query",
            json={"query": "test query"}
        )
        assert response.status_code == 503
        assert "Weaviate" in response.json()["detail"]


def test_query_endpoint_success(client, mock_weaviate_client):
    """Test successful query execution."""
    # Mock Weaviate query response
    mock_query = MagicMock()
    mock_query.get.return_value = mock_query
    mock_query.with_near_text.return_value = mock_query
    mock_query.with_limit.return_value = mock_query
    mock_query.with_additional.return_value = mock_query
    mock_query.do.return_value = {
        "data": {
            "Get": {
                SCHEMA_NAME: [
                    {
                        "title": "Test Doc",
                        "content": "Test content",
                        "filepath": "test/path.md",
                        "category": "doc",
                        "_additional": {
                            "certainty": 0.85,
                            "distance": 0.15
                        }
                    }
                ]
            }
        }
    }
    
    mock_weaviate_client.query = mock_query
    
    with patch("app.main.weaviate_client", mock_weaviate_client):
        response = client.post(
            "/api/v1/query",
            json={
                "query": "test query",
                "top_k": 5,
                "threshold": 0.7
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["query"] == "test query"
        assert data["count"] == 1
        assert len(data["results"]) == 1
        assert data["results"][0]["relevance_score"] == 0.85
        assert data["results"][0]["content"] == "Test content"
        assert data["results"][0]["source"] == "test/path.md"
        assert "retrieval_time_ms" in data


def test_query_endpoint_with_threshold_filter(client, mock_weaviate_client):
    """Test query with threshold filtering."""
    # Mock Weaviate query response with mixed relevance scores
    mock_query = MagicMock()
    mock_query.get.return_value = mock_query
    mock_query.with_near_text.return_value = mock_query
    mock_query.with_limit.return_value = mock_query
    mock_query.with_additional.return_value = mock_query
    mock_query.do.return_value = {
        "data": {
            "Get": {
                SCHEMA_NAME: [
                    {
                        "title": "High Relevance",
                        "content": "High relevance content",
                        "filepath": "test/high.md",
                        "category": "doc",
                        "_additional": {"certainty": 0.9}
                    },
                    {
                        "title": "Low Relevance",
                        "content": "Low relevance content",
                        "filepath": "test/low.md",
                        "category": "doc",
                        "_additional": {"certainty": 0.5}
                    }
                ]
            }
        }
    }
    
    mock_weaviate_client.query = mock_query
    
    with patch("app.main.weaviate_client", mock_weaviate_client):
        response = client.post(
            "/api/v1/query",
            json={
                "query": "test query",
                "top_k": 5,
                "threshold": 0.7
            }
        )
        
        assert response.status_code == 200
        data = response.json()
        # Only high relevance result should be returned
        assert data["count"] == 1
        assert data["results"][0]["relevance_score"] == 0.9


def test_query_endpoint_empty_results(client, mock_weaviate_client):
    """Test query with no results."""
    mock_query = MagicMock()
    mock_query.get.return_value = mock_query
    mock_query.with_near_text.return_value = mock_query
    mock_query.with_limit.return_value = mock_query
    mock_query.with_additional.return_value = mock_query
    mock_query.do.return_value = {
        "data": {
            "Get": {
                SCHEMA_NAME: []
            }
        }
    }
    
    mock_weaviate_client.query = mock_query
    
    with patch("app.main.weaviate_client", mock_weaviate_client):
        response = client.post(
            "/api/v1/query",
            json={"query": "test query"}
        )
        
        assert response.status_code == 200
        data = response.json()
        assert data["count"] == 0
        assert len(data["results"]) == 0


def test_query_endpoint_validation_errors(client):
    """Test query endpoint validation."""
    # Missing query
    response = client.post("/api/v1/query", json={})
    assert response.status_code == 422
    
    # Empty query
    response = client.post("/api/v1/query", json={"query": ""})
    assert response.status_code == 422
    
    # Invalid top_k
    response = client.post(
        "/api/v1/query",
        json={"query": "test", "top_k": 0}
    )
    assert response.status_code == 422
    
    # Invalid threshold
    response = client.post(
        "/api/v1/query",
        json={"query": "test", "threshold": 1.5}
    )
    assert response.status_code == 422


def test_query_endpoint_default_parameters(client, mock_weaviate_client):
    """Test query endpoint uses default parameters."""
    mock_query = MagicMock()
    mock_query.get.return_value = mock_query
    mock_query.with_near_text.return_value = mock_query
    mock_query.with_limit.return_value = mock_query
    mock_query.with_additional.return_value = mock_query
    mock_query.do.return_value = {
        "data": {"Get": {SCHEMA_NAME: []}}
    }
    
    mock_weaviate_client.query = mock_query
    
    with patch("app.main.weaviate_client", mock_weaviate_client):
        response = client.post(
            "/api/v1/query",
            json={"query": "test query"}
        )
        
        assert response.status_code == 200
        # Verify default parameters were used
        mock_query.with_limit.assert_called_once_with(DEFAULT_TOP_K)


def test_metrics_endpoint(client):
    """Test metrics endpoint is accessible."""
    response = client.get("/metrics")
    assert response.status_code == 200
    # Should contain Prometheus metrics format
    assert "# HELP" in response.text or "# TYPE" in response.text


def test_openapi_docs(client):
    """Test OpenAPI documentation is accessible."""
    response = client.get("/docs")
    assert response.status_code == 200
    
    # Test OpenAPI JSON schema
    response = client.get("/openapi.json")
    assert response.status_code == 200
    schema = response.json()
    assert "openapi" in schema
    assert "/api/v1/query" in schema["paths"]
    assert "/api/v1/health" in schema["paths"]
