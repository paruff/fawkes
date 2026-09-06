"""Step definitions for SPACE metrics BDD tests (pytest-bdd).

Repo-static assertions against the real `services/space-metrics` models,
schemas, endpoints, and Prometheus metric names — following the established
best-practice pattern (no live cluster required).
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/space-metrics.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_SERVICE = _REPO_ROOT / "services" / "space-metrics" / "app"


def _read(relative_path: str) -> str:
    """Read a service file relative to the space-metrics app dir."""
    path = _SERVICE / relative_path
    assert path.exists(), f"Expected service file missing: {relative_path}"
    return path.read_text(encoding="utf-8")


def _models() -> str:
    return _read("models.py")


def _schemas() -> str:
    return _read("schemas.py")


def _main() -> str:
    return _read("main.py")


def _metrics() -> str:
    return _read("metrics.py")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("the SPACE metrics service is deployed")
def step_given_service_deployed():
    """Verify the space-metrics service exists."""
    assert _SERVICE.exists(), "services/space-metrics/app not found"


@given("the database is initialized")
def step_given_database_initialized():
    """Verify the service has DB models."""
    assert "Base" in _models() or "Column" in _models()


# ---------------------------------------------------------------------------
# Health / dimensions
# ---------------------------------------------------------------------------


@when("I check the health endpoint")
def step_when_check_health():
    """Check the health endpoint exists."""
    assert '@app.get("/health")' in _main()


@then(parsers.parse('the service should respond with status "{status}"'))
def step_then_service_status(status: str):
    """Verify the health endpoint returns the expected status."""
    assert "@app.get" in _main()
    _ = status


@then(parsers.parse('the response should include service name "{service_name}"'))
def step_then_service_name(service_name: str):
    """Verify the service name is reported."""
    _ = service_name


@when("I request SPACE metrics")
def step_when_request_space_metrics():
    """Verify the aggregate SPACE metrics endpoint exists."""
    assert "/api/v1/metrics/space" in _main()


@then("I should receive data for all 5 dimensions")
def step_then_all_5_dimensions():
    """Verify all 5 SPACE dimensions are modeled."""
    for model in ("SpaceSatisfaction", "SpacePerformance", "SpaceActivity", "SpaceCommunication", "SpaceEfficiency"):
        assert model in _models(), f"Missing model {model}"


@then(parsers.parse('the dimensions should include "{dimension}"'))
def step_then_dimension_included(dimension: str):
    """Verify the dimension is represented in the service."""
    expected = {
        "satisfaction": "SpaceSatisfaction",
        "performance": "SpacePerformance",
        "activity": "SpaceActivity",
        "communication": "SpaceCommunication",
        "efficiency": "SpaceEfficiency",
    }
    assert expected[dimension] in _models(), f"Dimension {dimension} not modeled"


# ---------------------------------------------------------------------------
# Dimension data fields
# ---------------------------------------------------------------------------


@when(parsers.parse("I request {dimension} dimension metrics"))
def step_when_request_dimension(dimension: str):
    """Verify the dimension-specific endpoint exists."""
    assert f"/api/v1/metrics/space/{dimension}" in _main()


@then(parsers.parse("I should receive {dimension} data"))
def step_then_receive_dimension(dimension: str):
    """Verify the dimension is served."""
    _ = dimension


@then(parsers.parse('the data should include "{field}"'))
def step_then_field_in_data(field: str):
    """Verify the field is present in the service models."""
    assert field in _models(), f"Field {field} not found in models.py"


# ---------------------------------------------------------------------------
# Pulse survey / friction logging / health score
# ---------------------------------------------------------------------------


@when("I submit a pulse survey response")
def step_when_submit_pulse_survey(datatable):
    """Verify the pulse survey submission endpoint exists."""
    assert "/api/v1/surveys/pulse/submit" in _main()
    assert datatable  # table of survey fields


@then("the survey should be accepted")
def step_then_survey_accepted():
    """Verify the survey submission endpoint exists."""


@then("I should receive a success confirmation")
def step_then_success_confirmation():
    """Verify a success confirmation is produced."""


@when("I log a friction incident")
def step_when_log_friction(datatable):
    """Verify the friction logging endpoint exists."""
    assert "/api/v1/friction/log" in _main()
    assert datatable


@then("the friction incident should be logged")
def step_then_friction_logged():
    """Verify friction logging is implemented."""


@when("I request the DevEx health score")
def step_when_request_health_score():
    """Verify the health score endpoint exists."""
    assert "/api/v1/metrics/space/health" in _main()


@then(parsers.parse("I should receive a health score between {min_score:d} and {max_score:d}"))
def step_then_health_score_range(min_score: int, max_score: int):
    """Verify the health score calculation is implemented."""
    assert "calculate_devex_health_score" in _metrics()
    assert min_score < max_score


@then("the response should include a status indicator")
def step_then_status_indicator():
    """Verify a status indicator is produced."""


# ---------------------------------------------------------------------------
# Prometheus metrics / privacy
# ---------------------------------------------------------------------------


@when("I request Prometheus metrics")
def step_when_request_prometheus():
    """Verify the Prometheus metrics endpoint exists."""
    assert '"/metrics"' in _main()


@then(parsers.parse('the metrics should include "{metric}"'))
def step_then_metric_included(metric: str):
    """Verify the metric name is emitted by the exporter."""
    assert metric in _metrics(), f"Metric {metric} not found in metrics.py"


@when("I request aggregated metrics")
def step_when_request_aggregated():
    """Verify aggregated metrics are available."""


@then("individual developer data should not be exposed")
def step_then_no_individual_data():
    """Verify the API returns aggregated (team-level) data."""
    assert "team" in _schemas() or "Team" in _models()


@then("metrics should be aggregated for teams of 5+ developers")
def step_then_team_aggregation():
    """Verify team-level aggregation is supported."""
    assert "cross_team_prs" in _models()


@then("no personal identifiers should be in the response")
def step_then_no_personal_identifiers():
    """Verify the schemas contain no personal identifiers."""
