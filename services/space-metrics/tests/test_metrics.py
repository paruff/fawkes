"""
Unit tests for SPACE metrics service
"""

import pytest
from datetime import datetime, timedelta
from app.metrics import calculate_devex_health_score
from app.schemas import (
    SatisfactionMetrics,
    PerformanceMetrics,
    ActivityMetrics,
    CommunicationMetrics,
    EfficiencyMetrics,
)


def test_health_score_calculation_excellent():
    """Test health score calculation with excellent metrics"""
    satisfaction = SatisfactionMetrics(
        nps_score=70.0,
        satisfaction_rating=4.5,
        burnout_percentage=10.0,
        response_count=50
    )
    performance = PerformanceMetrics(
        deployment_frequency=3.0,
        lead_time_hours=8.0,
        change_failure_rate=5.0,
        mttr_minutes=30.0,
        build_success_rate=98.0,
        test_coverage=85.0
    )
    activity = ActivityMetrics(
        commits_count=500,
        pull_requests_count=100,
        code_reviews_count=150,
        active_developers_count=10,
        ai_tool_adoption_rate=75.0,
        platform_usage_count=1000
    )
    communication = CommunicationMetrics(
        avg_review_time_hours=4.0,
        pr_comments_avg=3.5,
        cross_team_prs=20,
        mattermost_messages=500,
        constructive_feedback_rate=95.0
    )
    efficiency = EfficiencyMetrics(
        flow_state_days=4.0,
        valuable_work_percentage=70.0,
        friction_incidents=5,
        context_switches=3.0,
        cognitive_load_avg=2.5
    )
    
    health_score = calculate_devex_health_score(
        satisfaction, performance, activity, communication, efficiency
    )
    
    assert 70 <= health_score <= 100, "Excellent metrics should yield high health score"


def test_health_score_calculation_poor():
    """Test health score calculation with poor metrics"""
    satisfaction = SatisfactionMetrics(
        nps_score=-20.0,
        satisfaction_rating=2.0,
        burnout_percentage=50.0,
        response_count=20
    )
    performance = PerformanceMetrics(
        deployment_frequency=0.2,
        lead_time_hours=48.0,
        change_failure_rate=30.0,
        mttr_minutes=180.0,
        build_success_rate=70.0,
        test_coverage=40.0
    )
    activity = ActivityMetrics(
        commits_count=50,
        pull_requests_count=10,
        code_reviews_count=5,
        active_developers_count=3,
        ai_tool_adoption_rate=10.0,
        platform_usage_count=100
    )
    communication = CommunicationMetrics(
        avg_review_time_hours=48.0,
        pr_comments_avg=1.0,
        cross_team_prs=2,
        mattermost_messages=50,
        constructive_feedback_rate=60.0
    )
    efficiency = EfficiencyMetrics(
        flow_state_days=1.0,
        valuable_work_percentage=30.0,
        friction_incidents=50,
        context_switches=10.0,
        cognitive_load_avg=4.5
    )
    
    health_score = calculate_devex_health_score(
        satisfaction, performance, activity, communication, efficiency
    )
    
    assert 0 <= health_score <= 50, "Poor metrics should yield low health score"


def test_health_score_no_data():
    """Test health score calculation with no data"""
    satisfaction = SatisfactionMetrics(response_count=0)
    performance = PerformanceMetrics()
    activity = ActivityMetrics()
    communication = CommunicationMetrics()
    efficiency = EfficiencyMetrics()
    
    health_score = calculate_devex_health_score(
        satisfaction, performance, activity, communication, efficiency
    )
    
    assert health_score == 0.0, "No data should yield zero health score"


def test_satisfaction_metrics_validation():
    """Test satisfaction metrics validation"""
    # Valid metrics
    metrics = SatisfactionMetrics(
        nps_score=50.0,
        satisfaction_rating=4.0,
        burnout_percentage=15.0,
        response_count=100
    )
    assert metrics.nps_score == 50.0
    assert metrics.satisfaction_rating == 4.0
    
    # Invalid NPS score (out of range)
    with pytest.raises(ValueError):
        SatisfactionMetrics(nps_score=150.0)


def test_efficiency_metrics_validation():
    """Test efficiency metrics validation"""
    # Valid metrics
    metrics = EfficiencyMetrics(
        flow_state_days=3.5,
        valuable_work_percentage=65.0,
        friction_incidents=10,
        cognitive_load_avg=3.0
    )
    assert metrics.flow_state_days == 3.5
    assert metrics.valuable_work_percentage == 65.0
    
    # Invalid cognitive load (out of range)
    with pytest.raises(ValueError):
        EfficiencyMetrics(cognitive_load_avg=6.0)


def test_privacy_no_individual_data():
    """Test that schemas don't expose individual developer data"""
    activity = ActivityMetrics(
        commits_count=100,
        active_developers_count=10,
        platform_usage_count=500
    )
    
    # Ensure no individual identifiers in model
    model_dict = activity.model_dump()
    assert "user_id" not in model_dict
    assert "developer_name" not in model_dict
    assert "email" not in model_dict
