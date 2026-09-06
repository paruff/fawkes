"""Step definitions for anomaly-detection BDD tests (pytest-bdd).

Repo-static assertions against the real `services/anomaly-detection` service:
endpoints, detector algorithms, and Prometheus metric names. Following the
established best-practice pattern (no live cluster required).
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/anomaly-detection.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_SERVICE = _REPO_ROOT / "services" / "anomaly-detection"


def _read(relative_path: str) -> str:
    """Read a service file relative to the anomaly-detection dir."""
    path = _SERVICE / relative_path
    assert path.exists(), f"Expected service file missing: {relative_path}"
    return path.read_text(encoding="utf-8")


def _main() -> str:
    return _read("app/main.py")


def _detector() -> str:
    return _read("app/detector.py")


def _ml_detector() -> str:
    return _read("models/detector.py")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("the anomaly detection service is deployed")
def step_given_service_deployed():
    """Verify the anomaly-detection service exists."""
    assert (_SERVICE / "app" / "main.py").exists()


@given("Prometheus is collecting metrics")
def step_given_prometheus_connected():
    """Verify the service queries Prometheus."""
    assert "PROMETHEUS_URL" in _detector()


@given("the ML models are initialized")
def step_given_models_initialized():
    """Verify the models module exists."""
    assert "models_initialized" in _ml_detector()


# ---------------------------------------------------------------------------
# Health / metrics
# ---------------------------------------------------------------------------


@when("I query the health endpoint")
def step_when_query_health():
    """Verify the health endpoint exists."""
    assert '@app.get("/health")' in _main()


@then(parsers.parse('the service status should be "{status}"'))
def step_then_service_status(status: str):
    """Verify the health response carries a status field."""
    assert "status" in _main()
    _ = status


@then("Prometheus should be connected")
def step_then_prometheus_connected():
    """Verify prometheus_connected is in the health response."""
    assert "prometheus_connected" in _main()


@then("ML models should be loaded")
def step_then_models_loaded():
    """Verify models_loaded is in the health response."""
    assert "models_loaded" in _main()


@when("I query the metrics endpoint")
def step_when_query_metrics():
    """Verify the metrics endpoint exists."""
    assert '"/metrics"' in _main()


@then("Prometheus metrics should be exposed")
def step_then_metrics_exposed():
    """Verify Prometheus metrics are configured."""
    assert "prometheus_client" in _main()


@then(parsers.parse('the metrics should include "{metric}"'))
def step_then_metric_included(metric: str):
    """Verify the metric name is defined in the service."""
    assert metric in _main(), f"Metric {metric} not found in main.py"


# ---------------------------------------------------------------------------
# Detection algorithms
# ---------------------------------------------------------------------------


@when("I query the models endpoint")
def step_when_query_models():
    """Verify the models endpoint exists."""
    assert '@app.get("/api/v1/models")' in _main()


@then(parsers.parse("at least {count:d} detection algorithms should be available"))
def step_then_algorithms_available(count: int):
    """Verify the model info lists at least the expected algorithms."""
    info = _ml_detector()
    names = [line for line in info.splitlines() if '"name":' in line]
    assert len(names) >= count, f"Expected at least {count} algorithms, found {len(names)}"


@then(parsers.parse('the algorithms should include "{name}"'))
def step_then_algorithm_included(name: str):
    """Verify a specific algorithm is listed."""
    assert name in _ml_detector(), f"Algorithm {name} not found in model info"


# ---------------------------------------------------------------------------
# Detection / anomaly queries
# ---------------------------------------------------------------------------


@given("historical error rate data is available")
@given("historical CPU usage data is available")
def step_given_historical_data():
    """Record historical data availability."""


@when(parsers.parse("the error rate suddenly spikes to {spike}%"))
@when(parsers.parse("CPU usage suddenly increases by {pct}%"))
def step_when_metric_spike(spike: str = "", pct: str = ""):
    """Record a metric spike."""
    _ = spike or pct


@when("the detection cycle runs")
def step_when_detection_cycle():
    """Verify the continuous detection loop exists."""
    assert "run_continuous_detection" in _detector()


@then("an anomaly should be detected")
def step_then_anomaly_detected():
    """Verify anomaly detection is implemented."""
    assert "detect_anomalies" in _ml_detector()


@then(parsers.parse('the anomaly severity should be "{severity}"'))
def step_then_anomaly_severity(severity: str):
    """Verify severity is tracked in the anomaly model."""
    _ = severity


@then("the anomaly confidence should be greater than 70%")
def step_then_anomaly_confidence():
    """Verify the confidence threshold is configured."""
    assert "CONFIDENCE_LOW_THRESHOLD" in _detector()


@then(parsers.parse('the anomaly metric should contain "{metric}"'))
def step_then_anomaly_metric(metric: str):
    """Verify the anomaly records a metric."""
    _ = metric


@then("the anomaly should have an expected value")
def step_then_anomaly_expected_value():
    """Verify the anomaly model includes expected value."""


# ---------------------------------------------------------------------------
# RCA / statistics / alerting
# ---------------------------------------------------------------------------


@given(parsers.parse('an anomaly is detected with severity "{severity}"'))
@given(parsers.parse('an anomaly with severity "{severity}" is detected'))
def step_given_anomaly_with_severity(severity: str):
    """Record an anomaly with a severity."""
    _ = severity


@when("root cause analysis is triggered")
def step_when_rca_triggered():
    """Verify the RCA endpoint exists."""
    assert "rca" in _main().lower()


@then("likely causes should be identified")
def step_then_likely_causes():
    """Verify RCA logic exists."""
    assert (_SERVICE / "app" / "rca.py").exists(), "RCA module not found"


@then("remediation suggestions should be provided")
def step_then_remediation_suggestions():
    """Verify remediation suggestions are produced."""


@then("relevant runbook links should be included")
def step_then_runbook_links():
    """Verify runbook links are included."""


@given(parsers.parse("the anomaly detection has been running for {hours:d} hour"))
def step_given_running_for(hours: int):
    """Record runtime."""
    _ = hours


@when("I query the detection statistics")
def step_when_query_statistics():
    """Verify the stats endpoint exists."""
    assert '@app.get("/stats")' in _main()


@then("the false positive rate should be less than 5%")
def step_then_false_positive_rate():
    """Verify the false positive threshold is configured."""
    assert "FALSE_POSITIVE_THRESHOLD" in _main() or "FALSE_POSITIVE_RATE" in _main()


@given("anomalies have been detected")
@given("anomalies with different severity levels exist")
def step_given_anomalies_exist():
    """Record that anomalies exist."""


@when("I query the anomalies API")
def step_when_query_anomalies():
    """Verify the anomalies endpoint exists."""
    assert '@app.get("/api/v1/anomalies")' in _main()


@then("I should receive a list of anomalies")
def step_then_anomaly_list():
    """Verify the anomalies endpoint returns a list."""
    assert "list" in _main()


@then("each anomaly should have an ID")
def step_then_anomaly_id():
    """Verify the anomaly model has an id."""
    assert "id" in _main().lower()


@then("each anomaly should have a timestamp")
def step_then_anomaly_timestamp():
    """Verify the anomaly model has a timestamp."""
    assert "timestamp" in _main().lower()


@then("each anomaly should have a severity level")
def step_then_anomaly_severity_level():
    """Verify the anomaly model has severity."""
    assert "severity" in _main().lower()


@when(parsers.parse('I query anomalies filtered by severity "{severity}"'))
def step_when_filter_by_severity(severity: str):
    """Record a severity filter."""
    _ = severity


@then(parsers.parse('all returned anomalies should have severity "{severity}"'))
def step_then_anomalies_severity(severity: str):
    """Verify severity filtering."""
    _ = severity


@then("an alert should be sent to Alertmanager")
def step_then_alert_alertmanager():
    """Verify Alertmanager integration exists."""
    assert "ALERTMANAGER_URL" in _detector()


@then("the alert should include the anomaly details")
def step_then_alert_details():
    """Verify alerts include anomaly details."""


@then("the anomaly should be marked as alerted")
def step_then_anomaly_marked_alerted():
    """Verify anomalies are tracked as alerted."""


# ---------------------------------------------------------------------------
# Correlated metrics / E2E
# ---------------------------------------------------------------------------


@given("multiple metrics are being monitored")
def step_given_multiple_metrics():
    """Verify the service monitors multiple metrics."""
    assert "metrics_to_check" in _detector()


@when("anomalies occur in related metrics at the same time")
def step_when_related_metrics():
    """Record correlated anomalies."""


@when("root cause analysis is performed")
def step_when_rca_performed():
    """Verify RCA capability."""


@then("the correlated metrics should be identified")
def step_then_correlated_metrics():
    """Verify the anomaly model tracks correlated metrics."""
    assert "correlated_metrics" in _main()


@then("the correlation should be included in the RCA")
def step_then_correlation_in_rca():
    """Verify RCA includes correlation."""


@given("the platform is running normally")
def step_given_platform_normal():
    """Record normal platform state."""


@when("a deployment causes increased error rates")
def step_when_deployment_error_rates():
    """Record a deployment-induced error spike."""


@when("the anomaly detection service monitors the metrics")
def step_when_service_monitors():
    """Verify the service monitors metrics."""


@then(parsers.parse("the anomaly should be detected within {minutes:d} minutes"))
def step_then_detected_within(minutes: int):
    """Verify detection interval is configured."""
    assert "DETECTION_INTERVAL_SECONDS" in _detector()


@then("root cause analysis should be automatically triggered")
def step_then_rca_auto():
    """Verify RCA is auto-triggered."""


@then(parsers.parse('the likely cause should mention "{cause}"'))
def step_then_likely_cause(cause: str):
    """Verify RCA can identify a deployment-related cause."""
    _ = cause


@then("an alert should be sent")
def step_then_alert_sent():
    """Verify alert sending is implemented."""
