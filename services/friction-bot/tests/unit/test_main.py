"""Unit tests for friction-bot signature/token verification."""

import hashlib
import hmac
import time
from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient


@pytest.fixture
def mock_env(monkeypatch):
    """Mock environment variables for verification."""
    monkeypatch.setenv("SLACK_SIGNING_SECRET", "test-signing-secret")
    monkeypatch.setenv("BOT_TOKEN", "test-bot-token")
    monkeypatch.setenv("INSIGHTS_API_URL", "http://localhost:8000")


def slack_signature(secret: str, timestamp: str, body: bytes) -> str:
    """Compute a valid Slack v0 signature for test payloads."""
    basestring = f"v0:{timestamp}:{body.decode()}"
    return "v0=" + hmac.new(secret.encode(), basestring.encode(), hashlib.sha256).hexdigest()


def test_verify_slack_signature_valid(mock_env):
    from app.main import verify_slack_signature

    ts = str(int(time.time()))
    body = b"token=abc&text=hello"
    sig = slack_signature("test-signing-secret", ts, body)

    assert verify_slack_signature(ts, body, sig) is True


def test_verify_slack_signature_invalid(mock_env):
    from app.main import verify_slack_signature

    ts = str(int(time.time()))
    body = b"token=abc&text=hello"

    assert verify_slack_signature(ts, body, "v0=deadbeef") is False


def test_verify_slack_signature_missing_headers(mock_env):
    from app.main import verify_slack_signature

    assert verify_slack_signature("", b"body", "") is False


def test_verify_slack_signature_stale_timestamp(mock_env):
    from app.main import verify_slack_signature

    stale_ts = str(int(time.time()) - 600)  # 10 minutes old
    body = b"token=abc&text=hello"
    sig = slack_signature("test-signing-secret", stale_ts, body)

    assert verify_slack_signature(stale_ts, body, sig) is False


def test_verify_slack_signature_unconfigured_secret_allows(monkeypatch):
    """Matches the repo's existing GitHub-webhook convention: skip verification
    (with a warning) when the secret isn't configured, rather than hard-failing."""
    monkeypatch.delenv("SLACK_SIGNING_SECRET", raising=False)
    from app import main

    original = main.SLACK_SIGNING_SECRET
    try:
        main.SLACK_SIGNING_SECRET = ""
        assert main.verify_slack_signature("123", b"body", "bad-sig") is True
    finally:
        main.SLACK_SIGNING_SECRET = original


def test_slack_endpoint_rejects_invalid_signature(mock_env):
    from app.main import app

    client = TestClient(app)
    ts = str(int(time.time()))

    response = client.post(
        "/slack/slash/friction",
        data={"token": "x", "text": "Title | desc", "user_name": "alice"},
        headers={"X-Slack-Request-Timestamp": ts, "X-Slack-Signature": "v0=invalid"},
    )
    assert response.status_code == 401


def test_slack_endpoint_accepts_valid_signature(mock_env):
    from app.main import app

    client = TestClient(app)
    body = b"token=x&text=Title+%7C+desc&user_name=alice"
    ts = str(int(time.time()))
    sig = slack_signature("test-signing-secret", ts, body)

    with patch("app.main.send_to_insights_api", return_value={"id": "123"}):
        response = client.post(
            "/slack/slash/friction",
            content=body,
            headers={
                "Content-Type": "application/x-www-form-urlencoded",
                "X-Slack-Request-Timestamp": ts,
                "X-Slack-Signature": sig,
            },
        )

    assert response.status_code == 200
    assert "Friction point logged" in response.json()["text"]


def test_mattermost_endpoint_rejects_invalid_token(mock_env):
    from app.main import app

    client = TestClient(app)

    response = client.post(
        "/mattermost/slash/friction",
        data={"token": "wrong-token", "text": "Title | desc", "user_name": "alice"},
    )
    assert response.status_code == 403


def test_mattermost_endpoint_accepts_valid_token(mock_env):
    from app.main import app

    client = TestClient(app)

    with patch("app.main.send_to_insights_api", return_value={"id": "123"}):
        response = client.post(
            "/mattermost/slash/friction",
            data={"token": "test-bot-token", "text": "Title | desc", "user_name": "alice"},
        )

    assert response.status_code == 200
    assert "Friction point logged" in response.json()["text"]
