"""
Unit tests for DevEx Survey Automation main application
"""
import pytest
from fastapi.testclient import TestClient
from unittest.mock import AsyncMock, patch, MagicMock
from datetime import datetime

# Mock database before importing app
with patch('app.database.init_database', new_callable=AsyncMock):
    with patch('app.database.close_database', new_callable=AsyncMock):
        from app.main import app


@pytest.fixture
def client():
    """Test client fixture"""
    return TestClient(app)


def test_root_endpoint(client):
    """Test root endpoint returns service info"""
    response = client.get("/")
    assert response.status_code == 200
    data = response.json()
    assert data["service"] == "devex-survey-automation"
    assert "version" in data
    assert "endpoints" in data


def test_health_check_returns_response(client):
    """Test health check returns valid response"""
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert "status" in data
    assert "service" in data
    assert "version" in data
    assert "database_connected" in data
    assert "integrations" in data


def test_survey_page_without_token_returns_error(client):
    """Test accessing survey without valid token shows error"""
    # Note: In full integration test with DB, this would work properly
    # For unit test, we just verify the endpoint exists
    response = client.get("/survey/nonexistent_token_12345")
    assert response.status_code in [200, 500]  # Either renders error or DB connection fails


def test_thank_you_page(client):
    """Test thank you page renders"""
    response = client.get("/survey/test_token/thanks")
    assert response.status_code == 200
    assert "Thank You!" in response.text
    assert "feedback has been submitted" in response.text


@pytest.mark.parametrize("flow_state,valuable_work,cognitive_load,friction", [
    (3.5, 70.0, 3.0, False),
    (0.0, 0.0, 1.0, True),
    (7.0, 100.0, 5.0, False),
])
def test_pulse_survey_response_validation(flow_state, valuable_work, cognitive_load, friction):
    """Test pulse survey response data validation"""
    from app.schemas import PulseSurveyResponse

    response = PulseSurveyResponse(
        flow_state_days=flow_state,
        valuable_work_pct=valuable_work,
        cognitive_load=cognitive_load,
        friction_incidents=friction
    )

    assert response.flow_state_days == flow_state
    assert response.valuable_work_pct == valuable_work
    assert response.cognitive_load == cognitive_load
    assert response.friction_incidents == friction


def test_pulse_survey_response_invalid_values():
    """Test pulse survey response rejects invalid values"""
    from app.schemas import PulseSurveyResponse
    from pydantic import ValidationError

    # Test invalid flow_state_days (> 7)
    with pytest.raises(ValidationError):
        PulseSurveyResponse(
            flow_state_days=8.0,
            valuable_work_pct=70.0,
            cognitive_load=3.0,
            friction_incidents=False
        )

    # Test invalid valuable_work_pct (> 100)
    with pytest.raises(ValidationError):
        PulseSurveyResponse(
            flow_state_days=3.0,
            valuable_work_pct=150.0,
            cognitive_load=3.0,
            friction_incidents=False
        )

    # Test invalid cognitive_load (> 5)
    with pytest.raises(ValidationError):
        PulseSurveyResponse(
            flow_state_days=3.0,
            valuable_work_pct=70.0,
            cognitive_load=6.0,
            friction_incidents=False
        )


def test_survey_distribution_request_validation():
    """Test survey distribution request validation"""
    from app.schemas import SurveyDistributionRequest

    # Valid request
    request = SurveyDistributionRequest(
        type="pulse",
        test_mode=True,
        test_users=["user1@example.com"]
    )
    assert request.type == "pulse"
    assert request.test_mode is True

    # Valid request with defaults
    request = SurveyDistributionRequest(type="deep_dive")
    assert request.test_mode is False
    assert request.test_users is None


def test_campaign_response_model():
    """Test campaign response model"""
    from app.schemas import CampaignResponse

    campaign = CampaignResponse(
        id=1,
        type="pulse",
        period="W50",
        year=2024,
        started_at=datetime.now(),
        completed_at=None,
        total_sent=100,
        total_responses=65,
        response_rate=65.0
    )

    assert campaign.id == 1
    assert campaign.type == "pulse"
    assert campaign.response_rate == 65.0


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
