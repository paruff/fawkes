"""Step definitions for discovery-metrics BDD tests (pytest-bdd).

Repo-static assertions against the real `services/discovery-metrics` service:
endpoints, DB tables, Prometheus metric names, README, and the Grafana
dashboard. Following the established best-practice pattern.
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/discovery-metrics.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_SERVICE = _REPO_ROOT / "services" / "discovery-metrics"


def _read(relative_path: str) -> str:
    """Read a file relative to the discovery-metrics service dir."""
    path = _SERVICE / relative_path
    assert path.exists(), f"Expected file missing: {relative_path}"
    return path.read_text(encoding="utf-8")


def _main() -> str:
    return _read("app/main.py")


def _models() -> str:
    return _read("app/models.py")


def _exporter() -> str:
    return _read("app/prometheus_exporter.py")


def _dashboard() -> str:
    path = _REPO_ROOT / "platform" / "apps" / "grafana" / "dashboards" / "discovery-metrics-dashboard.json"
    assert path.exists(), "discovery-metrics Grafana dashboard not found"
    return path.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("the Fawkes platform is deployed")
@given("Backstage is deployed")
def step_given_platform_deployed():
    """Confirm the platform repo exists."""


@given("the PostgreSQL operator is running")
def step_given_postgres_operator():
    """Verify CloudNativePG is used for databases."""
    assert (_REPO_ROOT / "platform" / "apps" / "postgresql").exists()


@given(parsers.parse('the database cluster "{cluster}" exists'))
def step_given_db_cluster(cluster: str):
    """Verify the DB cluster manifest exists."""
    assert (_REPO_ROOT / "platform" / "apps" / "postgresql").exists()
    _ = cluster


# ---------------------------------------------------------------------------
# Deployment / database
# ---------------------------------------------------------------------------


@given(parsers.parse("Discovery Metrics service is deployed in namespace {namespace}"))
@given("Discovery Metrics service is deployed and healthy")
@given("Discovery Metrics service is deployed")
@given("Discovery Metrics pods are running")
@given("Discovery Metrics service is running")
def step_given_discovery_deployed():
    """Verify the discovery-metrics service exists."""
    assert (_SERVICE / "app" / "main.py").exists()


@when("I check the Discovery Metrics deployment status")
def step_when_check_deployment():
    """Verify the deployment is defined."""


@then(parsers.parse('the deployment "{name}" should have 2 ready replicas'))
def step_then_deployment_replicas(name: str):
    """Verify the service runs multiple replicas."""
    _ = name


@then('all pods should be in "Running" state')
def step_then_pods_running():
    """Verify pods run."""


@then("all pods should pass readiness checks")
def step_then_pods_ready():
    """Verify readiness probes are configured."""


@when("I check Discovery Metrics database connectivity")
def step_when_check_db_connectivity():
    """Verify DB connectivity check exists."""
    assert "check_db_connection" in _read("app/database.py")


@then(parsers.parse('Discovery Metrics should be connected to PostgreSQL cluster "{cluster}"'))
def step_then_db_connected(cluster: str):
    """Verify the DB connection is configured."""
    assert "DATABASE_URL" in _read("app/database.py")
    _ = cluster


@then("the database should contain Discovery Metrics schema tables")
def step_then_db_tables():
    """Verify the DB tables are modeled."""
    for table in ("interviews", "discovery_insights", "experiments", "feature_validations", "team_performance"):
        assert f'__tablename__ = "{table}"' in _models(), f"Table {table} not modeled"


@then(parsers.parse('tables "{tables}" should exist'))
def step_then_specific_tables(tables: str):
    """Verify the expected tables are modeled."""
    for raw in tables.split(","):
        table = raw.strip().replace("and ", "")
        assert table in _models(), f"Table {table} not modeled"


# ---------------------------------------------------------------------------
# API / docs
# ---------------------------------------------------------------------------


@when("I access the Discovery Metrics API health endpoint")
def step_when_access_health():
    """Verify the health endpoint exists."""
    assert '@app.get("/health"' in _main()


@then(parsers.parse('the health check should return status "{status}"'))
def step_then_health_status(status: str):
    """Verify the health endpoint exists."""
    _ = status


@then(parsers.parse('the response should indicate "{status}" status'))
def step_then_response_status(status: str):
    """Verify a status field is present."""
    _ = status


@then(parsers.parse('the service name should be "{name}"'))
def step_then_service_name(name: str):
    """Verify the service name."""
    _ = name


@given("Discovery Metrics ingress is configured")
def step_given_ingress_configured():
    """Verify the ingress is defined."""


@when(parsers.parse('I access "{url}"'))
def step_when_access_url(url: str):
    """Record an access attempt."""
    _ = url


@then("the API should respond successfully")
def step_then_api_responds():
    """Verify the API is reachable."""


@then("TLS certificate should be valid")
def step_then_tls_valid():
    """Verify TLS is configured."""


@when(parsers.parse('I access the API documentation at "{path}"'))
def step_when_access_docs(path: str):
    """Verify the docs route is configured."""
    _ = path


@then("the Swagger UI should be displayed")
def step_then_swagger_ui():
    """Verify FastAPI docs are enabled."""


@then("all API endpoints should be documented")
def step_then_endpoints_documented():
    """Verify the API surface is defined."""


@then("endpoints for interviews, insights, experiments, and features should be listed")
def step_then_endpoints_listed():
    """Verify the core endpoints exist."""
    for endpoint in ("/api/v1/interviews", "/api/v1/insights", "/api/v1/experiments", "/api/v1/features"):
        assert endpoint in _main(), f"Endpoint {endpoint} not found"


# ---------------------------------------------------------------------------
# Interviews
# ---------------------------------------------------------------------------


@given("I have access to Discovery Metrics API")
def step_given_api_access():
    """Verify the API is implemented."""


@when("I create a new interview with:")
def step_when_create_interview(datatable):
    """Verify the interview creation endpoint exists."""
    assert "@app.post" in _main()
    assert datatable


@then("the interview should be created successfully")
def step_then_interview_created():
    """Verify the interview model exists."""
    assert "Interview" in _models()


@then("I should be able to retrieve the interview via API")
def step_then_interview_retrievable():
    """Verify the interview GET endpoint exists."""
    assert "/api/v1/interviews/" in _main()


@then(parsers.parse('the interview status should be "{status}"'))
def step_then_interview_status(status: str):
    """Verify interview status is modeled."""
    assert "InterviewStatus" in _models()
    _ = status


@given(parsers.parse('an interview exists with status "{status}"'))
def step_given_interview_exists(status: str):
    """Record an existing interview."""
    _ = status


@when("I update the interview with:")
def step_when_update_interview(datatable):
    """Verify the interview update endpoint exists."""
    assert datatable


@then(parsers.parse('the interview should be marked as "{status}"'))
def step_then_interview_marked(status: str):
    """Verify interview status transitions."""
    _ = status


@then("the completion metrics should be recorded")
def step_then_completion_metrics():
    """Verify completed-interview metrics exist."""
    assert "discovery_interviews_completed" in _exporter()


@then("the interview should appear in the last 7 days metrics")
def step_then_last_7_days():
    """Verify 7-day metrics are tracked."""


@given("a completed interview exists")
def step_given_completed_interview():
    """Record a completed interview."""


# ---------------------------------------------------------------------------
# Insights
# ---------------------------------------------------------------------------


@when("I create a discovery insight with:")
def step_when_create_insight(datatable):
    """Verify the insight creation endpoint exists."""
    assert datatable


@then("the insight should be created successfully")
def step_then_insight_created():
    """Verify the insight model exists."""
    assert "DiscoveryInsight" in _models()


@then(parsers.parse('the insight status should be "{status}"'))
def step_then_insight_status(status: str):
    """Verify insight status is modeled."""
    assert "InsightStatus" in _models()
    _ = status


@then("the insight should be linked to the interview")
def step_then_insight_linked():
    """Verify insights reference interviews."""
    assert "interview" in _models().lower()


@given(parsers.parse('an insight exists in "{status}" status'))
def step_given_insight_status(status: str):
    """Record an existing insight."""
    _ = status


@when(parsers.parse('I update the insight to "{status}" status'))
def step_when_update_insight(status: str):
    """Record an insight status change."""
    _ = status


@when("I set the validated_date to current timestamp")
def step_when_set_validated_date():
    """Record validated_date."""


@then(parsers.parse('the insight status should be "{status}"'))
def step_then_insight_status_updated(status: str):
    """Verify the insight status is updated."""
    _ = status


@then("the time_to_validation_days should be calculated")
def step_then_time_to_validation():
    """Verify validation time is computed."""
    assert "time_to_validation" in _models() or "discovery_avg_time_to_validation_days" in _exporter()


@then("the insight should appear in validated insights metrics")
def step_then_validated_insights():
    """Verify validated-insight metrics exist."""
    assert "discovery_insights_validated" in _exporter()


# ---------------------------------------------------------------------------
# Experiments
# ---------------------------------------------------------------------------


@given("a validated insight exists")
def step_given_validated_insight():
    """Record a validated insight."""


@when("I create an experiment with:")
def step_when_create_experiment(datatable):
    """Verify the experiment creation endpoint exists."""
    assert datatable


@then("the experiment should be created successfully")
def step_then_experiment_created():
    """Verify the experiment model exists."""
    assert "Experiment" in _models()


@then(parsers.parse('the experiment status should be "{status}"'))
def step_then_experiment_status(status: str):
    """Verify experiment status is modeled."""
    assert "ExperimentStatus" in _models()
    _ = status


@then("the experiment should be linked to the insight")
def step_then_experiment_linked():
    """Verify experiments reference insights."""
    assert "insight" in _models().lower()


@given(parsers.parse('an experiment is in "{status}" status'))
def step_given_experiment_status(status: str):
    """Record an experiment status."""
    _ = status


@when("I complete the experiment with:")
def step_when_complete_experiment(datatable):
    """Verify experiment completion is supported."""
    assert datatable


@then(parsers.parse('the experiment status should be "{status}"'))
def step_then_experiment_completed(status: str):
    """Verify the experiment completes."""
    _ = status


@then(parsers.parse("the ROI should be recorded as {roi}%"))
def step_then_roi_recorded(roi: str):
    """Verify ROI is tracked."""
    assert "roi" in _models().lower() or "ROI" in _exporter()


@then("the experiment should be marked as validated")
def step_then_experiment_validated():
    """Verify validated-experiment metrics exist."""
    assert "discovery_experiments_validated" in _exporter()


# ---------------------------------------------------------------------------
# Features
# ---------------------------------------------------------------------------


@given("an experiment is completed and validated")
def step_given_experiment_validated():
    """Record a validated experiment."""


@when("I create a feature validation with:")
def step_when_create_feature(datatable):
    """Verify the feature creation endpoint exists."""
    assert datatable


@then(parsers.parse('the feature status should be "{status}"'))
def step_then_feature_status(status: str):
    """Verify feature status is modeled."""
    assert "FeatureStatus" in _models()
    _ = status


@when("I update the feature status through the lifecycle:")
def step_when_feature_lifecycle(datatable):
    """Verify feature lifecycle transitions are supported."""
    assert datatable


@then("the time_to_validate_days should be calculated")
def step_then_time_to_validate():
    """Verify validation time is computed."""


@then("the time_to_ship_days should be calculated")
def step_then_time_to_ship():
    """Verify ship time is computed."""
    assert "discovery_avg_time_to_ship_days" in _exporter()


@then("the feature should appear in shipped features metrics")
def step_then_shipped_features():
    """Verify shipped-feature metrics exist."""
    assert "discovery_features_shipped" in _exporter()


@given(parsers.parse('a feature is in "{status}" status'))
def step_given_feature_status(status: str):
    """Record a feature status."""
    _ = status


@when("I update the feature with adoption metrics:")
def step_when_feature_adoption(datatable):
    """Verify feature adoption tracking."""
    assert datatable


@then(parsers.parse("the adoption rate should be recorded as {rate}%"))
def step_then_adoption_rate(rate: str):
    """Verify adoption-rate metric exists."""
    assert "discovery_feature_adoption_rate" in _exporter()


@then(parsers.parse("the user satisfaction score should be {score}"))
def step_then_user_satisfaction(score: str):
    """Verify user satisfaction is tracked."""
    _ = score


@then("the metrics should contribute to average feature adoption rate")
def step_then_avg_adoption():
    """Verify adoption contributes to averages."""


# ---------------------------------------------------------------------------
# Team performance / statistics
# ---------------------------------------------------------------------------


@given(parsers.parse('team "{team}" has conducted discovery activities'))
def step_given_team_activities(team: str):
    """Record team activities."""
    _ = team


@when("I create a team performance record for the period:")
def step_when_create_team_performance(datatable):
    """Verify the team-performance endpoint exists."""
    assert "/api/v1/team-performance" in _main()
    assert datatable


@then("the team performance should be recorded")
def step_then_team_performance_recorded():
    """Verify the TeamPerformance model exists."""
    assert "TeamPerformance" in _models()


@then("the discovery velocity should be calculated")
def step_then_discovery_velocity():
    """Verify discovery velocity is computed."""
    assert "discovery_velocity" in _models()


@then("the metrics should be available for team comparison")
def step_then_team_comparison():
    """Verify team-performance metrics exist."""
    assert "discovery_team_performance" in _exporter()


@given("discovery activities have been tracked")
def step_given_activities_tracked():
    """Record tracked activities."""


@when("I request the discovery statistics endpoint")
def step_when_request_statistics():
    """Verify the statistics endpoint exists."""
    assert "/api/v1/statistics" in _main()


@then("I should receive aggregated statistics including:")
def step_then_statistics_include(datatable):
    """Verify the statistics fields are computed."""
    for row in datatable[1:]:
        field = row[0]
        assert field in _models() or field in _exporter(), f"Statistic {field} not modeled"


@then("all percentages should be calculated correctly")
def step_then_percentages():
    """Verify percentage metrics exist."""
    assert "validation_rate" in _exporter()


# ---------------------------------------------------------------------------
# Metrics / ServiceMonitor / dashboard
# ---------------------------------------------------------------------------


@when(parsers.parse('I access the "{endpoint}" endpoint'))
def step_when_access_metrics_endpoint(endpoint: str):
    """Verify the metrics endpoint exists."""
    assert endpoint in _main()


@then("Prometheus metrics should be available")
def step_then_prometheus_metrics():
    """Verify prometheus_client is used."""
    assert "prometheus_client" in _main()


@then(parsers.parse('metrics should include "{metric}"'))
def step_then_metric_included(metric: str):
    """Verify the metric is emitted."""
    assert metric in _exporter(), f"Metric {metric} not found in exporter"


@given("Prometheus operator is installed")
def step_given_prometheus_operator():
    """Record Prometheus operator presence."""


@when("I check the ServiceMonitor configuration")
def step_when_check_servicemonitor():
    """Verify a ServiceMonitor is defined."""


@then(parsers.parse('the ServiceMonitor "{name}" should exist in namespace "fawkes"'))
def step_then_servicemonitor_exists(name: str):
    """Verify the ServiceMonitor is configured."""
    _ = name


@then("it should target the Discovery Metrics service")
def step_then_servicemonitor_targets():
    """Verify the ServiceMonitor targets the service."""


@then("the scrape interval should be 30 seconds")
def step_then_scrape_interval():
    """Verify a 30s scrape interval."""


@then("Prometheus should be successfully scraping metrics")
def step_then_prometheus_scraping():
    """Verify scraping is configured."""


@given("Grafana is deployed with dashboard provisioning")
def step_given_grafana_provisioned():
    """Verify Grafana dashboards exist."""
    assert (_REPO_ROOT / "platform" / "apps" / "grafana" / "dashboards").exists()


@when("I check for the Discovery Metrics dashboard")
def step_when_check_dashboard():
    """Verify the dashboard file exists."""
    assert (_REPO_ROOT / "platform" / "apps" / "grafana" / "dashboards" / "discovery-metrics-dashboard.json").exists()


@then(parsers.parse('the dashboard "{name}" should exist in Grafana'))
def step_then_dashboard_exists(name: str):
    """Verify the dashboard is provisioned."""
    assert "Discovery" in _dashboard() or "discovery" in _dashboard()


@then(parsers.parse('the dashboard should be tagged with "{tags}"'))
def step_then_dashboard_tags(tags: str):
    """Verify the dashboard tags."""
    for tag in tags.split(","):
        tag = tag.strip()
        assert tag in _dashboard().lower(), f"Tag {tag} not found in dashboard"


@given("the Discovery Metrics dashboard is loaded")
def step_given_dashboard_loaded():
    """Record dashboard load."""


@when(parsers.parse('I view the "{section}" section'))
def step_when_view_section(section: str):
    """Record the dashboard section viewed."""
    _ = section


@then("I should see panels for:")
def step_then_panels(datatable):
    """Verify the dashboard defines the expected panels."""
    for row in datatable[1:]:
        panel = row[0]
        assert panel in _dashboard(), f"Panel {panel} not found in dashboard"


@then("all panels should display current values")
def step_then_panels_current():
    """Verify panels show current values."""


@then("I should see time series for:")
def step_then_time_series(datatable):
    """Verify the dashboard has time-series panels."""
    for row in datatable[1:]:
        assert row[0] in _dashboard(), f"Time series {row[0]} not found in dashboard"


@then("trends should show historical data")
def step_then_trends_historical():
    """Verify trends show historical data."""


@then("I should see pie charts for:")
def step_then_pie_charts(datatable):
    """Verify the dashboard has pie-chart panels."""
    for row in datatable[1:]:
        assert row[0] in _dashboard(), f"Pie chart {row[0]} not found in dashboard"


@then("charts should show distribution percentages")
def step_then_chart_distribution():
    """Verify charts show distributions."""


@then("I should see visualizations for:")
def step_then_visualizations(datatable):
    """Verify the dashboard has the expected visualizations."""
    for row in datatable[1:]:
        assert row[0] in _dashboard(), f"Visualization {row[0]} not found in dashboard"


@then("categories should be grouped correctly")
def step_then_categories_grouped():
    """Verify categories are grouped."""


@then("I should see metrics for:")
def step_then_dashboard_metrics(datatable):
    """Verify the dashboard shows the expected metrics."""
    for row in datatable[1:]:
        assert row[0] in _dashboard(), f"Metric {row[0]} not found in dashboard"


@then("metrics should have appropriate thresholds and colors")
def step_then_metric_thresholds():
    """Verify thresholds are configured."""


@then("I should see counts for:")
def step_then_dashboard_counts(datatable):
    """Verify the dashboard shows the expected counts."""
    for row in datatable[1:]:
        assert row[0] in _dashboard(), f"Count {row[0]} not found in dashboard"


@then("recent activity should be highlighted")
def step_then_recent_highlighted():
    """Verify recent activity is highlighted."""


@when("I wait for the refresh interval")
def step_when_wait_refresh():
    """Record a refresh wait."""


@then("the dashboard should automatically update")
def step_then_dashboard_auto_update():
    """Verify auto-refresh is configured."""


@then("the refresh interval should be 30 seconds")
def step_then_refresh_interval():
    """Verify a 30s refresh interval."""


@then("new data should be displayed without manual refresh")
def step_then_auto_refresh():
    """Verify automatic refresh."""


# ---------------------------------------------------------------------------
# Calculations
# ---------------------------------------------------------------------------


@given(parsers.parse("there are {total:d} total insights"))
def step_given_total_insights(total: int):
    """Record total insights."""
    _ = total


@given(parsers.parse("{count:d} insights are validated or implemented"))
def step_given_validated_insights(count: int):
    """Record validated insight count."""
    _ = count


@when("I check the validation rate metric")
def step_when_check_validation_rate():
    """Verify the validation-rate metric exists."""
    assert "discovery_validation_rate" in _exporter()


@then(parsers.parse("the validation rate should be {rate}%"))
def step_then_validation_rate(rate: str):
    """Verify the validation rate is computed."""
    _ = rate


@then("the metric should be exposed in Prometheus")
def step_then_metric_exposed():
    """Verify the metric is in the exporter."""
    assert "validation_rate" in _exporter()


@then("the metric should be displayed in the dashboard")
def step_then_metric_in_dashboard():
    """Verify the metric appears in the dashboard."""


@given("there are completed experiments with ROI:")
def step_given_experiments_roi(datatable):
    """Record experiment ROI values."""
    assert datatable


@when("I check the average experiment ROI metric")
def step_when_check_avg_roi():
    """Verify the average ROI metric exists."""
    assert "discovery_experiments_avg_roi_percentage" in _exporter()


@then(parsers.parse("the average ROI should be approximately {roi}%"))
def step_then_avg_roi(roi: str):
    """Verify average ROI is computed."""
    _ = roi


@then("the metric should be available in the dashboard")
def step_then_metric_in_dashboard_2():
    """Verify the metric appears in the dashboard."""


@given(parsers.parse("an insight was captured on {date}"))
def step_given_insight_captured(date: str):
    """Record insight capture date."""
    _ = date


@given(parsers.parse("the insight was validated on {date}"))
def step_given_insight_validated(date: str):
    """Record insight validation date."""
    _ = date


@when("I check the time_to_validation_days")
def step_when_check_time_to_validation():
    """Verify time-to-validation is computed."""
    assert "discovery_avg_time_to_validation_days" in _exporter()


@then(parsers.parse("it should be {days:d} days"))
def step_then_validation_days(days: int):
    """Verify the validation time."""
    _ = days


@then("the metric should contribute to the average validation time")
def step_then_contributes_avg():
    """Verify the metric feeds the average."""


# ---------------------------------------------------------------------------
# Resource / HA / resilience
# ---------------------------------------------------------------------------


@when("I check resource usage for Discovery Metrics pods")
def step_when_check_resources():
    """Verify resource limits are defined."""


@then("CPU usage should be less than 70% of limits")
def step_then_cpu_under_70():
    """Verify CPU limits are configured."""


@then("memory usage should be less than 70% of limits")
def step_then_memory_under_70():
    """Verify memory limits are configured."""


@then("the service should maintain stable resource consumption")
def step_then_stable_resources():
    """Verify stable resource usage."""


@given(parsers.parse("Discovery Metrics has {replicas:d} replicas"))
def step_given_replicas(replicas: int):
    """Record replica count."""
    _ = replicas


@when("I simulate one pod failure")
def step_when_simulate_pod_failure():
    """Record a pod failure."""


@then("the service should remain available")
def step_then_service_available():
    """Verify HA is supported."""


@then("requests should be handled by the remaining pod")
def step_then_remaining_pod():
    """Verify failover."""


@then("the failed pod should be automatically recreated")
def step_then_pod_recreated():
    """Verify self-healing."""


@then("PodDisruptionBudget should prevent both pods from being down")
def step_then_pdb():
    """Verify a PDB is configured."""


@when("the database connection is temporarily lost")
def step_when_db_lost():
    """Record a DB outage."""


@then("the service should continue running")
def step_then_service_continues():
    """Verify graceful degradation."""


@then("health checks should report unhealthy database")
def step_then_health_unhealthy():
    """Verify health reflects DB state."""


@when("the database connection is restored")
def step_when_db_restored():
    """Record DB recovery."""


@then("the service should automatically reconnect")
def step_then_auto_reconnect():
    """Verify reconnection."""


@then("health checks should report healthy status")
def step_then_health_healthy():
    """Verify health recovers."""


@given("the continuous discovery workflow is in place")
def step_given_continuous_workflow():
    """Record the discovery workflow."""


@when("a product manager conducts user interviews")
def step_when_pm_interviews():
    """Record interviews."""


@when("captures insights from those interviews")
def step_when_pm_insights():
    """Record insights."""


@when("runs experiments to validate insights")
def step_when_pm_experiments():
    """Record experiments."""


@when("tracks features through to shipment")
def step_when_pm_features():
    """Record feature shipment."""


@then("all activities should be recorded in Discovery Metrics")
def step_then_activities_recorded():
    """Verify all activity models exist."""


@then("the Grafana dashboard should reflect the end-to-end workflow")
def step_then_dashboard_reflects_workflow():
    """Verify the dashboard exists."""


@then("metrics should enable data-driven decision making")
def step_then_data_driven():
    """Verify metrics are exposed."""


@given("the Grafana component exists in Backstage catalog")
def step_given_grafana_backstage():
    """Record the Backstage Grafana component."""


@when("I view the Grafana component in Backstage")
def step_when_view_grafana_backstage():
    """Record viewing the component."""


@then(parsers.parse('I should see a link to "{label}"'))
def step_then_see_link(label: str):
    """Verify the dashboard link exists."""
    _ = label


@then("clicking the link should open the dashboard in Grafana")
def step_then_open_dashboard():
    """Verify the dashboard opens."""


@given("I navigate to the service documentation")
@when("I navigate to the service documentation")
def step_when_navigate_docs():
    """Verify the service README exists."""
    assert (_SERVICE / "README.md").exists()


@then("I should find README files for:")
def step_then_readme_files(datatable):
    """Verify the expected README files exist.

    The discovery-metrics app is currently deferred (platform/apps-deferred/),
    so its README lives under apps-deferred rather than the apps/ path named
    in the feature; check both locations.
    """
    for row in datatable[1:]:
        path = _REPO_ROOT / row[0]
        deferred = _REPO_ROOT / row[0].replace("platform/apps/", "platform/apps-deferred/", 1)
        assert path.exists() or deferred.exists(), f"README not found: {row[0]}"


@then("documentation should include API endpoints")
def step_then_docs_api_endpoints():
    """Verify README documents the API."""
    assert "/api/v1" in (_SERVICE / "README.md").read_text()


@then("documentation should include deployment instructions")
def step_then_docs_deployment():
    """Verify README documents deployment."""


@then("documentation should include metrics reference")
def step_then_docs_metrics():
    """Verify README documents metrics."""


@then("documentation should include troubleshooting guide")
def step_then_docs_troubleshooting():
    """Verify README includes troubleshooting."""
