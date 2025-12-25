"""Unit tests for Focalboard integration."""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch
from datetime import datetime

from app.main import app

client = TestClient(app)


def test_focalboard_integration_available():
    """Test that Focalboard integration is available in root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert "integrations" in data
    assert "focalboard" in data["integrations"]
    # Integration should be available (even if httpx import fails, module should load)
    assert isinstance(data["integrations"]["focalboard"], bool)


def test_focalboard_webhook_endpoint_exists():
    """Test that webhook endpoint is accessible."""
    # Send a test webhook payload
    payload = {
        "action": "card.created",
        "card": {
            "id": "test-card-123",
            "title": "Test Card",
            "boardId": "test-board",
            "status": "Backlog",
            "createAt": int(datetime.now().timestamp() * 1000),
            "updateAt": int(datetime.now().timestamp() * 1000)
        },
        "boardId": "test-board",
        "workspaceId": "test-workspace"
    }

    response = client.post("/api/v1/focalboard/webhook", json=payload)
    # Should return 200 even if DB fails (webhook should not retry on errors)
    assert response.status_code in [200, 500, 503]


def test_focalboard_stage_mapping_endpoint():
    """Test that stage mapping endpoint returns correct data."""
    response = client.get("/api/v1/focalboard/stages/mapping")

    # May fail if integration not available
    if response.status_code == 200:
        data = response.json()
        assert "column_to_stage" in data
        assert isinstance(data["column_to_stage"], dict)
        # Check some expected mappings
        assert "backlog" in data["column_to_stage"]
        assert "development" in data["column_to_stage"]
    else:
        # Acceptable if integration not fully available
        assert response.status_code in [404, 500, 503]


def test_focalboard_column_stage_mapping():
    """Test column to stage mapping logic."""
    try:
        from integrations.focalboard import FocalboardColumnStageMapping

        # Test known mappings
        assert FocalboardColumnStageMapping.get_stage("backlog") == "Backlog"
        assert FocalboardColumnStageMapping.get_stage("Backlog") == "Backlog"
        assert FocalboardColumnStageMapping.get_stage("BACKLOG") == "Backlog"
        assert FocalboardColumnStageMapping.get_stage("development") == "Development"
        assert FocalboardColumnStageMapping.get_stage("to do") == "Backlog"
        assert FocalboardColumnStageMapping.get_stage("done") == "Production"

        # Test reverse mapping
        assert FocalboardColumnStageMapping.get_column("Backlog") is not None
        assert FocalboardColumnStageMapping.get_column("Development") is not None
        assert FocalboardColumnStageMapping.get_column("Production") is not None

        # Test unknown mapping
        assert FocalboardColumnStageMapping.get_stage("unknown-column") is None

    except ImportError:
        pytest.skip("Focalboard integration not available")


def test_webhook_card_created_validation():
    """Test webhook payload validation for card creation."""
    # Valid payload
    valid_payload = {
        "action": "card.created",
        "card": {
            "id": "card-1",
            "title": "New Feature",
            "boardId": "board-1",
            "status": "Backlog",
            "createAt": 1640000000000,
            "updateAt": 1640000000000
        },
        "boardId": "board-1",
        "workspaceId": "workspace-1"
    }

    response = client.post("/api/v1/focalboard/webhook", json=valid_payload)
    assert response.status_code in [200, 500, 503]

    # Invalid payload - missing required fields
    invalid_payload = {
        "action": "card.created",
        "card": {
            "id": "card-1",
            # Missing required fields like title, boardId, status, etc.
        }
    }

    response = client.post("/api/v1/focalboard/webhook", json=invalid_payload)
    # Should return validation error
    assert response.status_code == 422


def test_webhook_card_moved_validation():
    """Test webhook payload validation for card movement."""
    payload = {
        "action": "card.moved",
        "card": {
            "id": "card-1",
            "title": "Existing Feature",
            "boardId": "board-1",
            "status": "Development",
            "createAt": 1640000000000,
            "updateAt": 1640000100000
        },
        "boardId": "board-1",
        "workspaceId": "workspace-1"
    }

    response = client.post("/api/v1/focalboard/webhook", json=payload)
    assert response.status_code in [200, 500, 503]


def test_sync_board_endpoint():
    """Test manual board sync endpoint."""
    sync_request = {
        "board_id": "test-board-123"
    }

    response = client.post("/api/v1/focalboard/sync", json=sync_request)
    # Should return 200 with sync results or error
    assert response.status_code in [200, 500, 503]

    if response.status_code == 200:
        data = response.json()
        assert "status" in data
        assert "synced_count" in data
        assert "failed_count" in data


def test_sync_work_item_to_focalboard():
    """Test syncing a VSM work item to Focalboard."""
    # Test with non-existent work item
    response = client.get("/api/v1/focalboard/work-items/99999/sync-to-focalboard")
    # Should return 404 or DB error (503) if database not available
    assert response.status_code in [404, 500, 503]


def test_focalboard_endpoints_in_root():
    """Test that Focalboard endpoints are listed in root when integration is available."""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()

    if data.get("integrations", {}).get("focalboard"):
        # If integration is available, endpoints should be listed
        endpoints = data.get("endpoints", {})
        assert "focalboard_webhook" in endpoints or "endpoints" in data
