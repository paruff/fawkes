"""Unit tests for alert correlation engine."""
import pytest
from datetime import datetime
from unittest.mock import AsyncMock, MagicMock
import json

from app.correlation import AlertCorrelator


@pytest.fixture
def redis_mock():
    """Mock Redis client."""
    mock = AsyncMock()
    mock.get = AsyncMock(return_value=None)
    mock.setex = AsyncMock()
    mock.lpush = AsyncMock()
    mock.ltrim = AsyncMock()
    mock.lrange = AsyncMock(return_value=[])
    return mock


@pytest.fixture
def correlator(redis_mock):
    """Create correlator instance."""
    return AlertCorrelator(redis_mock)


@pytest.mark.unit
@pytest.mark.asyncio
async def test_correlate_alerts_groups_by_service(correlator, redis_mock):
    """Test that alerts are grouped by service and alertname."""
    alerts = [
        {
            "id": "1",
            "fingerprint": "fp1",
            "labels": {"alertname": "HighErrorRate", "service": "api-gateway", "severity": "critical"},
            "annotations": {"summary": "Error rate high"},
            "startsAt": datetime.now().isoformat(),
            "status": "firing",
        },
        {
            "id": "2",
            "fingerprint": "fp2",
            "labels": {"alertname": "HighErrorRate", "service": "api-gateway", "severity": "critical"},
            "annotations": {"summary": "Error rate high"},
            "startsAt": datetime.now().isoformat(),
            "status": "firing",
        },
    ]

    groups = await correlator.correlate_alerts(alerts)

    assert len(groups) == 1
    assert groups[0]["count"] == 2
    assert groups[0]["grouping_key"] == "api-gateway:HighErrorRate:critical"


@pytest.mark.unit
@pytest.mark.asyncio
async def test_correlate_alerts_separate_groups_different_services(correlator, redis_mock):
    """Test that alerts for different services create separate groups."""
    alerts = [
        {
            "id": "1",
            "labels": {"alertname": "HighErrorRate", "service": "service-a", "severity": "critical"},
            "annotations": {},
            "startsAt": datetime.now().isoformat(),
            "status": "firing",
        },
        {
            "id": "2",
            "labels": {"alertname": "HighErrorRate", "service": "service-b", "severity": "critical"},
            "annotations": {},
            "startsAt": datetime.now().isoformat(),
            "status": "firing",
        },
    ]

    groups = await correlator.correlate_alerts(alerts)

    assert len(groups) == 2


@pytest.mark.unit
def test_calculate_priority_critical_severity(correlator):
    """Test priority calculation for critical alerts."""
    alerts = [{"labels": {"severity": "critical", "service": "api-gateway"}}]

    priority = correlator._calculate_priority(alerts)

    assert priority > 5.0


@pytest.mark.unit
def test_calculate_priority_increases_with_count(correlator):
    """Test that priority increases with alert count."""
    single_alert = [{"labels": {"severity": "warning", "service": "api-gateway"}}]

    multiple_alerts = [
        {"labels": {"severity": "warning", "service": "api-gateway"}},
        {"labels": {"severity": "warning", "service": "api-gateway"}},
        {"labels": {"severity": "warning", "service": "api-gateway"}},
    ]

    priority_single = correlator._calculate_priority(single_alert)
    priority_multiple = correlator._calculate_priority(multiple_alerts)

    assert priority_multiple > priority_single


@pytest.mark.unit
def test_deduplicate_alerts(correlator):
    """Test alert deduplication."""
    alerts = [
        {"fingerprint": "abc123", "labels": {"alertname": "Test"}},
        {"fingerprint": "abc123", "labels": {"alertname": "Test"}},
        {"fingerprint": "def456", "labels": {"alertname": "Test2"}},
    ]

    deduplicated = correlator._deduplicate_alerts(alerts)

    assert len(deduplicated) == 2


@pytest.mark.unit
def test_generate_grouping_key(correlator):
    """Test grouping key generation."""
    alert = {"labels": {"service": "api-gateway", "alertname": "HighErrorRate", "severity": "critical"}}

    key = correlator._generate_grouping_key(alert)

    assert key == "api-gateway:HighErrorRate:critical"


@pytest.mark.unit
def test_generate_grouping_key_handles_missing_labels(correlator):
    """Test grouping key generation with missing labels."""
    alert = {"labels": {"alertname": "TestAlert"}}

    key = correlator._generate_grouping_key(alert)

    assert "unknown" in key
    assert "TestAlert" in key
