"""Unit tests for the shared bearer-token check on /api/v1/* routes.

smart-alerting is exposed externally via k8s/ingress.yaml
(smart-alerting.fawkes.local) - these tests guard against the AUD-2
regression (alert ingestion/acknowledge/resolve/suppression-rule endpoints
reachable with no auth at all).
"""

import pytest
from app import main
from fastapi import HTTPException


@pytest.fixture
def with_token(monkeypatch):
    """Set ALERTING_API_TOKEN on the already-imported module (no reload -
    main.py registers Prometheus metrics at module level, and reloading
    re-registers them into the same global CollectorRegistry)."""
    monkeypatch.setattr(main, "ALERTING_API_TOKEN", "test-token-123")


def test_missing_authorization_header_rejected(with_token):
    with pytest.raises(HTTPException) as exc_info:
        main.verify_api_token(authorization=None)
    assert exc_info.value.status_code == 401


def test_malformed_authorization_header_rejected(with_token):
    with pytest.raises(HTTPException) as exc_info:
        main.verify_api_token(authorization="test-token-123")  # missing "Bearer " prefix
    assert exc_info.value.status_code == 401


def test_wrong_token_rejected(with_token):
    with pytest.raises(HTTPException) as exc_info:
        main.verify_api_token(authorization="Bearer wrong-token")
    assert exc_info.value.status_code == 401


def test_correct_token_accepted(with_token):
    main.verify_api_token(authorization="Bearer test-token-123")  # does not raise


def test_open_when_token_not_configured(monkeypatch):
    """Matches friction-bot's BOT_TOKEN pattern: empty token = local-dev escape hatch."""
    monkeypatch.setattr(main, "ALERTING_API_TOKEN", "")
    main.verify_api_token(authorization=None)  # does not raise
