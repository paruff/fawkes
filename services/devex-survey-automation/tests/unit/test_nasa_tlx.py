"""
Unit tests for NASA-TLX cognitive load assessment endpoints
"""
import pytest
from datetime import datetime
from app.schemas import NASATLXRequest, NASATLXResponse


def test_nasa_tlx_request_validation():
    """Test NASA-TLX request schema validation"""
    # Valid request
    valid_request = NASATLXRequest(
        task_type="deployment",
        task_id="deploy-123",
        mental_demand=50.0,
        physical_demand=20.0,
        temporal_demand=60.0,
        performance=85.0,
        effort=45.0,
        frustration=30.0,
        duration_minutes=15,
        comment="Test deployment was smooth",
    )
    assert valid_request.task_type == "deployment"
    assert valid_request.mental_demand == 50.0


def test_nasa_tlx_request_out_of_range():
    """Test NASA-TLX request with out-of-range values"""
    with pytest.raises(ValueError):
        NASATLXRequest(
            task_type="deployment",
            mental_demand=150.0,  # Out of range (0-100)
            physical_demand=20.0,
            temporal_demand=60.0,
            performance=85.0,
            effort=45.0,
            frustration=30.0,
        )


def test_nasa_tlx_request_minimal():
    """Test NASA-TLX request with minimal required fields"""
    minimal_request = NASATLXRequest(
        task_type="pr_review",
        mental_demand=40.0,
        physical_demand=10.0,
        temporal_demand=30.0,
        performance=90.0,
        effort=35.0,
        frustration=15.0,
    )
    assert minimal_request.task_id is None
    assert minimal_request.duration_minutes is None
    assert minimal_request.comment is None


def test_overall_workload_calculation():
    """Test that overall workload is calculated correctly"""
    # Overall workload should be average of all 6 dimensions
    # with performance inverted (100 - performance)
    request = NASATLXRequest(
        task_type="incident_response",
        mental_demand=80.0,
        physical_demand=40.0,
        temporal_demand=90.0,
        performance=70.0,  # Inverted to 30.0 in calculation
        effort=75.0,
        frustration=85.0,
    )

    # Manual calculation: (80 + 40 + 90 + 30 + 75 + 85) / 6 = 400 / 6 = 66.67
    expected_workload = (80.0 + 40.0 + 90.0 + (100 - 70.0) + 75.0 + 85.0) / 6.0
    assert expected_workload == pytest.approx(66.67, rel=0.01)


def test_task_types():
    """Test common platform task types"""
    task_types = ["deployment", "pr_review", "incident_response", "build", "debug", "configuration", "onboarding"]

    for task_type in task_types:
        request = NASATLXRequest(
            task_type=task_type,
            mental_demand=50.0,
            physical_demand=25.0,
            temporal_demand=50.0,
            performance=75.0,
            effort=50.0,
            frustration=40.0,
        )
        assert request.task_type == task_type


def test_nasa_tlx_response_schema():
    """Test NASA-TLX response schema"""
    response_data = {
        "id": 1,
        "user_id": "test_user",
        "task_type": "deployment",
        "task_id": "deploy-123",
        "mental_demand": 50.0,
        "physical_demand": 20.0,
        "temporal_demand": 60.0,
        "performance": 85.0,
        "effort": 45.0,
        "frustration": 30.0,
        "overall_workload": 45.0,
        "duration_minutes": 15,
        "comment": "Test comment",
        "submitted_at": datetime.now(),
    }

    response = NASATLXResponse(**response_data)
    assert response.id == 1
    assert response.task_type == "deployment"
    assert response.overall_workload == 45.0


def test_comment_length_validation():
    """Test that comment length is validated"""
    # Max length is 2000 characters
    long_comment = "x" * 2001

    with pytest.raises(ValueError):
        NASATLXRequest(
            task_type="deployment",
            mental_demand=50.0,
            physical_demand=20.0,
            temporal_demand=60.0,
            performance=85.0,
            effort=45.0,
            frustration=30.0,
            comment=long_comment,
        )


def test_negative_duration():
    """Test that negative duration is rejected"""
    with pytest.raises(ValueError):
        NASATLXRequest(
            task_type="deployment",
            mental_demand=50.0,
            physical_demand=20.0,
            temporal_demand=60.0,
            performance=85.0,
            effort=45.0,
            frustration=30.0,
            duration_minutes=-5,
        )


def test_performance_interpretation():
    """Test understanding of performance score"""
    # Performance is special: higher is better (0=failure, 100=perfect)
    # In workload calculation, it's inverted: (100 - performance)
    # So a high performance (good) contributes less to workload

    high_performance = NASATLXRequest(
        task_type="deployment",
        mental_demand=0.0,
        physical_demand=0.0,
        temporal_demand=0.0,
        performance=100.0,  # Perfect performance
        effort=0.0,
        frustration=0.0,
    )
    # Workload = (0 + 0 + 0 + (100-100) + 0 + 0) / 6 = 0
    expected_workload_high = (0.0 + 0.0 + 0.0 + 0.0 + 0.0 + 0.0) / 6.0
    assert expected_workload_high == 0.0

    low_performance = NASATLXRequest(
        task_type="deployment",
        mental_demand=0.0,
        physical_demand=0.0,
        temporal_demand=0.0,
        performance=0.0,  # Complete failure
        effort=0.0,
        frustration=0.0,
    )
    # Workload = (0 + 0 + 0 + (100-0) + 0 + 0) / 6 = 16.67
    expected_workload_low = (0.0 + 0.0 + 0.0 + 100.0 + 0.0 + 0.0) / 6.0
    assert expected_workload_low == pytest.approx(16.67, rel=0.01)
