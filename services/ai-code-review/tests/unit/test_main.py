"""Unit tests for the main FastAPI application."""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
import httpx


@pytest.fixture
def mock_env(monkeypatch):
    """Mock environment variables."""
    monkeypatch.setenv("GITHUB_WEBHOOK_SECRET", "test-secret")
    monkeypatch.setenv("GITHUB_TOKEN", "test-token")
    monkeypatch.setenv("LLM_API_KEY", "test-api-key")
    monkeypatch.setenv("RAG_SERVICE_URL", "http://localhost:8001")


@pytest.fixture
def mock_http_client():
    """Mock HTTP client."""
    with patch('httpx.AsyncClient') as mock:
        mock_instance = Mock(spec=httpx.AsyncClient)
        mock_instance.get = Mock()
        mock_instance.post = Mock()
        mock.return_value = mock_instance
        yield mock_instance


def test_root_endpoint(mock_env):
    """Test root endpoint returns service info."""
    from app.main import app
    client = TestClient(app)
    
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "ai-code-review"
    assert data["status"] == "running"
    assert "version" in data


def test_health_endpoint(mock_env):
    """Test health check endpoint."""
    from app.main import app
    client = TestClient(app)
    
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "UP"
    assert data["service"] == "ai-code-review"
    assert "rag_connected" in data
    assert "github_configured" in data
    assert "llm_configured" in data


def test_ready_endpoint_success(mock_env):
    """Test readiness endpoint when configured."""
    from app.main import app
    client = TestClient(app)
    
    response = client.get("/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "READY"


def test_ready_endpoint_missing_config():
    """Test readiness endpoint fails when not configured."""
    from app import main
    
    # Save original values
    original_github_token = main.GITHUB_TOKEN
    original_llm_key = main.LLM_API_KEY
    
    try:
        # Set to empty
        main.GITHUB_TOKEN = ""
        main.LLM_API_KEY = ""
        
        client = TestClient(main.app)
        response = client.get("/ready")
        assert response.status_code == 503
    finally:
        # Restore original values
        main.GITHUB_TOKEN = original_github_token
        main.LLM_API_KEY = original_llm_key


def test_verify_github_signature_valid(mock_env):
    """Test GitHub signature verification with valid signature."""
    from app.main import verify_github_signature
    import hmac
    import hashlib
    
    payload = b'{"test": "data"}'
    secret = "test-secret"
    
    signature = hmac.new(
        secret.encode(),
        msg=payload,
        digestmod=hashlib.sha256
    ).hexdigest()
    
    assert verify_github_signature(payload, f"sha256={signature}") is True


def test_verify_github_signature_invalid(mock_env):
    """Test GitHub signature verification with invalid signature."""
    from app.main import verify_github_signature
    
    payload = b'{"test": "data"}'
    signature = "sha256=invalid"
    
    assert verify_github_signature(payload, signature) is False


def test_webhook_invalid_signature(mock_env):
    """Test webhook rejects invalid signature."""
    from app.main import app
    client = TestClient(app)
    
    response = client.post(
        "/webhook/github",
        json={"action": "opened"},
        headers={
            "X-Hub-Signature-256": "sha256=invalid",
            "X-GitHub-Event": "pull_request"
        }
    )
    assert response.status_code == 401


def test_webhook_pull_request_opened(mock_env):
    """Test webhook processes pull request opened event."""
    from app.main import app
    import hmac
    import hashlib
    import json
    
    client = TestClient(app)
    
    payload = {
        "action": "opened",
        "pull_request": {
            "number": 123,
            "diff_url": "https://github.com/test/repo/pull/123.diff"
        },
        "repository": {
            "full_name": "test/repo"
        }
    }
    
    payload_bytes = json.dumps(payload).encode()
    signature = hmac.new(
        "test-secret".encode(),
        msg=payload_bytes,
        digestmod=hashlib.sha256
    ).hexdigest()
    
    with patch('app.main.process_pull_request_review'):
        response = client.post(
            "/webhook/github",
            json=payload,
            headers={
                "X-Hub-Signature-256": f"sha256={signature}",
                "X-GitHub-Event": "pull_request",
                "Content-Type": "application/json"
            }
        )
    
    assert response.status_code == 202
    data = response.json()
    assert "scheduled" in data["message"].lower()


def test_webhook_ignores_other_events(mock_env):
    """Test webhook ignores non-PR events."""
    from app.main import app
    import hmac
    import hashlib
    import json
    
    client = TestClient(app)
    
    payload = {"action": "created"}
    payload_bytes = json.dumps(payload).encode()
    signature = hmac.new(
        "test-secret".encode(),
        msg=payload_bytes,
        digestmod=hashlib.sha256
    ).hexdigest()
    
    response = client.post(
        "/webhook/github",
        json=payload,
        headers={
            "X-Hub-Signature-256": f"sha256={signature}",
            "X-GitHub-Event": "issue_comment"
        }
    )
    
    assert response.status_code == 200
    data = response.json()
    assert "ignored" in data["message"].lower()


def test_stats_endpoint(mock_env):
    """Test stats endpoint."""
    from app.main import app
    client = TestClient(app)
    
    response = client.get("/stats")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "ai-code-review"
    assert "metrics" in data["message"].lower()
