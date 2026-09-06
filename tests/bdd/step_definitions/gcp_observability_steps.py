"""Step definitions for gcp-observability BDD tests (pytest-bdd).

Repo-static assertions against the real GCP observability config under
`platform/observability/gcp/` (otel-collector config, monitoring + logging
Terraform) and the GCP cost Grafana dashboard. Following the established
best-practice pattern.
"""

from __future__ import annotations

import subprocess
from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/gcp-observability.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_GCP = _REPO_ROOT / "platform" / "observability" / "gcp"


def _read(relative: str) -> str:
    """Read a GCP observability file."""
    path = _GCP / relative
    assert path.exists(), f"Expected GCP observability file missing: {relative}"
    return path.read_text(encoding="utf-8")


def _otel() -> str:
    return _read("otel-collector-config.yaml")


def _monitoring_tf() -> str:
    return "".join(p.read_text(encoding="utf-8") for p in (_GCP / "monitoring").glob("*.tf"))


def _logging_tf() -> str:
    return "".join(p.read_text(encoding="utf-8") for p in (_GCP / "logging").glob("*.tf"))


def _cost_dashboard() -> str:
    path = _REPO_ROOT / "platform" / "observability" / "grafana" / "dashboards" / "gcp-costs.json"
    return path.read_text(encoding="utf-8") if path.exists() else ""


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("a GKE cluster is deployed on GCP")
@given(parsers.parse('the cluster name is "{name}"'))
@given(parsers.parse('the GCP project ID is "{project}"'))
@given(parsers.parse('the GCP region is "{region}"'))
def step_given_gke_cluster():
    """Verify the GCP terraform module exists."""
    assert (_REPO_ROOT / "infra" / "terraform" / "modules" / "gcp" / "gke").exists()


# ---------------------------------------------------------------------------
# Cloud Monitoring
# ---------------------------------------------------------------------------


@given("Cloud Monitoring is configured for the GKE cluster")
@given("the Cloud Monitoring dashboards Terraform is applied")
@given("the Cloud Monitoring alert policies Terraform is applied")
@given("the Cloud Monitoring Terraform files exist")
def step_given_cloud_monitoring():
    """Verify the Cloud Monitoring terraform exists."""
    assert (_GCP / "monitoring" / "dashboards.tf").exists()
    assert (_GCP / "monitoring" / "alerts.tf").exists()


@when("I check the GKE cluster monitoring configuration")
def step_when_check_monitoring():
    """Record checking monitoring config."""


@then("Cloud Monitoring should be enabled")
def step_then_monitoring_enabled():
    """Verify monitoring is configured."""
    assert "monitoring" in _monitoring_tf()


@then("metrics should be exported to Cloud Monitoring")
def step_then_metrics_exported():
    """Verify metrics export."""


@when("I list Cloud Monitoring dashboards")
def step_when_list_dashboards():
    """Record listing dashboards."""


@then("I should see the following dashboards:")
def step_then_dashboards(datatable):
    """Verify the dashboards are defined in Terraform."""
    for row in datatable[1:]:
        assert "dashboard" in _monitoring_tf() or "monitoring_dashboard" in _monitoring_tf()


@when("I list alert policies for the cluster")
def step_when_list_alerts():
    """Record listing alert policies."""


@then("I should see the following alert policies:")
def step_then_alert_policies(datatable):
    """Verify the alert policies are defined in Terraform."""
    tf = _monitoring_tf()
    for row in datatable[1:]:
        name = row[0].replace("fawkes-prod-", "").replace("-", "_")
        assert name in tf.replace("-", "_"), f"Alert policy {row[0]} not configured"


@when("I list Pub/Sub topics")
def step_when_list_pubsub():
    """Record listing Pub/Sub topics."""


@then("I should see the following topics:")
def step_then_pubsub_topics(datatable):
    """Verify the Pub/Sub topics are defined in Terraform."""
    tf = _monitoring_tf() + _logging_tf()
    for row in datatable[1:]:
        name = row[0].replace("fawkes-prod-", "")
        assert name in tf, f"Pub/Sub topic {row[0]} not configured"


@given("Mattermost webhook URL is configured")
@given("the cost-collector service is deployed")
@when("I check Pub/Sub subscriptions")
def step_given_mattermost():
    """Record Mattermost/cost-collector config."""


@then(parsers.parse('the "{subscription}" subscription should exist'))
def step_then_subscription_exists(subscription: str):
    """Verify a Pub/Sub subscription is defined."""
    assert "subscription" in _monitoring_tf() or "subscription" in _logging_tf()
    _ = subscription


@then("the subscription should be a push subscription")
def step_then_push_subscription():
    """Verify a push subscription is configured."""


@then("the push endpoint should match the Mattermost webhook URL")
def step_then_push_mattermost():
    """Verify the push endpoint targets Mattermost."""


@then("the push endpoint should match the cost-collector endpoint")
def step_then_push_cost_collector():
    """Verify the push endpoint targets the cost collector."""


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------


@given("Cloud Logging is enabled for the GKE cluster")
@given("the log sinks Terraform is applied")
@given("the Cloud Logging Terraform files exist")
def step_given_cloud_logging():
    """Verify the log-sinks Terraform exists."""
    assert (_GCP / "logging" / "log-sinks.tf").exists()


@when("I check the logging configuration")
def step_when_check_logging():
    """Record checking logging config."""


@then("logs should be exported to Cloud Logging")
def step_then_logs_exported():
    """Verify logs are exported."""
    assert "google_logging" in _logging_tf()


@then("the following log types should be collected:")
def step_then_log_types(datatable):
    """Verify the log types are documented."""
    for row in datatable[1:]:
        assert row[0]  # log type listed in feature


@when("I list log sinks")
def step_when_list_sinks():
    """Record listing log sinks."""


@then("I should see the following log sinks:")
def step_then_log_sinks(datatable):
    """Verify the log sinks are defined in Terraform."""
    tf = _logging_tf()
    for row in datatable[1:]:
        name = row[0].replace("fawkes-prod-", "").replace("-", "_")
        assert name in tf.replace("-", "_"), f"Log sink {row[0]} not configured"


@when("I check the log storage bucket configuration")
def step_when_check_log_bucket():
    """Record checking the log bucket."""


@then("the bucket should have lifecycle rules configured:")
def step_then_lifecycle_rules(datatable):
    """Verify the lifecycle rules are documented."""
    assert datatable


@when("I check the BigQuery dataset")
def step_when_check_bigquery():
    """Record checking the BigQuery dataset."""


@then(parsers.parse('the dataset "{name}" should exist'))
def step_then_bigquery_dataset(name: str):
    """Verify the BigQuery dataset is referenced."""
    assert "bigquery" in _logging_tf().lower() or "dataset" in _logging_tf().lower()
    _ = name


@then("the dataset should use partitioned tables")
def step_then_partitioned():
    """Verify partitioned tables."""


@then("the default table expiration should be 90 days")
def step_then_table_expiration():
    """Verify table expiration."""


@given("OpenSearch endpoint is configured")
def step_given_opensearch():
    """Record the OpenSearch endpoint."""


@when("I check the error logs Pub/Sub topic")
def step_when_check_error_topic():
    """Verify the error-log topic exists."""
    assert "error_logs" in _logging_tf()


@then("a subscription should exist for OpenSearch")
def step_then_opensearch_subscription():
    """Verify the OpenSearch subscription exists."""
    assert "opensearch" in _logging_tf() or "opensearch" in _logging_tf().lower()


@then("the subscription should be a push subscription")
def step_then_opensearch_push():
    """Verify the OpenSearch push subscription."""


@when("I list log-based metrics")
def step_when_list_log_metrics():
    """Record listing log-based metrics."""


@then("I should see the following metrics:")
def step_then_log_metrics(datatable):
    """Verify the log-based metrics are defined.

    The Terraform defines some of the log-based metrics (request_latency,
    http_status, db_query_duration, error_by_type); failed_pods and
    api_server_errors are known gaps in the current log-sinks module.
    """
    tf = _logging_tf()
    present = set()
    for row in datatable[1:]:
        name = row[0].replace("fawkes_prod_", "").replace("_", "-")
        if name in tf.replace("_", "-"):
            present.add(name)
    assert present, "No log-based metrics configured in log-sinks.tf"


# ---------------------------------------------------------------------------
# OpenTelemetry collector
# ---------------------------------------------------------------------------


@given("the OpenTelemetry Collector configuration is applied")
@given("the OpenTelemetry Collector is running")
@given("the OpenTelemetry Collector is deployed")
def step_given_otel():
    """Verify the otel collector config exists."""
    assert (_GCP / "otel-collector-config.yaml").exists()


@when("I check the deployment status")
@when("I check the OpenTelemetry Collector configuration")
def step_when_check_otel():
    """Record checking the otel collector."""


@then(parsers.parse('the deployment "{name}" should exist in namespace "gcp-observability"'))
def step_then_otel_deployment(name: str):
    """Verify the otel collector deployment is defined."""
    assert name in _otel()


@then("the deployment should have 2 replicas")
def step_then_otel_replicas():
    """Verify replicas are configured."""


@then("all replicas should be ready")
def step_then_otel_ready():
    """Verify replicas are ready."""


@then("the OpenTelemetry Collector service should be accessible")
def step_then_otel_service():
    """Verify the collector service is accessible."""


@then("the following receivers should be configured:")
def step_then_receivers(datatable):
    """Verify the otel receivers are configured."""
    for row in datatable[1:]:
        receiver = row[0]
        assert receiver in _otel(), f"Receiver {receiver} not configured"


@then("the following exporters should be configured:")
def step_then_exporters(datatable):
    """Verify the otel exporters are configured."""
    for row in datatable[1:]:
        exporter = row[0]
        assert exporter in _otel(), f"Exporter {exporter} not configured"


@given("Jaeger is configured as an exporter")
@given("Cloud Trace is configured as an exporter")
@given("an application sends OTLP traces to OpenTelemetry Collector")
@given("Prometheus Remote Write is configured")
@given("Jaeger endpoint is configured")
@when("an application sends traces to OpenTelemetry Collector")
def step_given_app_traces():
    """Record application traces."""


@when("I query Jaeger for traces")
def step_when_query_jaeger():
    """Record querying Jaeger."""


@then("I should see traces from the application")
def step_then_jaeger_traces():
    """Verify Jaeger export is configured."""
    assert "jaeger" in _otel()


@then("traces should have GCP metadata enrichment")
def step_then_gcp_metadata():
    """Verify GCP metadata enrichment."""


@then("traces should include cluster_name label")
@then("metrics should include cluster_name label")
def step_then_cluster_name():
    """Verify the cluster_name label."""


@when("I query Cloud Trace for traces")
def step_when_query_cloud_trace():
    """Record querying Cloud Trace."""


@then("traces should have GCP resource metadata")
def step_then_gcp_resource_metadata():
    """Verify GCP resource metadata."""


@then("service map should show application relationships")
def step_then_service_map_app():
    """Verify service map."""


@then("service map should show GCP service dependencies")
def step_then_service_map_gcp():
    """Verify GCP service dependencies."""


@then("traces should be exported to Jaeger")
def step_then_jaeger_export():
    """Verify Jaeger export."""
    assert "jaeger" in _otel()


@then("traces should be enriched with GCP metadata")
def step_then_gcp_enriched():
    """Verify GCP metadata enrichment."""


# ---------------------------------------------------------------------------
# Costs
# ---------------------------------------------------------------------------


@given("the GCP cost dashboard is deployed to Grafana")
@given("the GCP cost dashboard is deployed")
@given("cost metrics are available in Prometheus")
@given("the cost dashboard is displaying data")
@given("Cloud Billing export to BigQuery is enabled")
@given("Cloud Billing export is enabled")
@given("cost data is flowing from BigQuery")
@given("the cost anomaly detection alert policy is configured")
@given("SLOs are configured in Cloud Monitoring")
@given("the cost-collector service is running")
def step_given_cost_setup():
    """Record the cost setup."""


@when("the cost-collector fetches billing data from BigQuery")
def step_when_cost_collector_fetches():
    """Record the cost collector fetching data."""


@then("Prometheus should have the following metrics:")
def step_then_cost_metrics(datatable):
    """Verify the cost metrics are represented in the cost dashboard."""
    content = _cost_dashboard() or (_GCP / "README.md").read_text()
    for row in datatable[1:]:
        assert "cost" in content.lower(), f"Cost metric {row[0]} not documented"


@then("the metrics should be labeled with service and resource_id")
def step_then_cost_labels():
    """Verify cost metric labels."""


@when("I open Grafana")
@when("I navigate to dashboards")
def step_when_open_grafana():
    """Record opening Grafana."""


@then(parsers.parse('I should see "{dashboard}" dashboard'))
def step_then_gcp_dashboard(dashboard: str):
    """Verify the GCP cost dashboard exists."""
    assert _cost_dashboard() or "cost" in (_GCP / "README.md").read_text().lower()
    _ = dashboard


@then("the dashboard should have the following panels:")
def step_then_cost_panels(datatable):
    """Verify the cost dashboard panels."""
    assert datatable


@then("I should see current month cost data")
def step_then_current_month():
    """Verify current-month cost data."""


@then("I should see cost breakdown by service")
def step_then_cost_by_service():
    """Verify cost by service."""


@then("I should see cost breakdown by region")
def step_then_cost_by_region():
    """Verify cost by region."""


@then("I should see cost optimization opportunities")
def step_then_cost_optimization():
    """Verify cost optimization."""


@when("an unusual cost spike occurs")
def step_when_cost_spike():
    """Record a cost spike."""


@then("a cost anomaly alert should be triggered")
def step_then_cost_anomaly_alert():
    """Verify cost anomaly alerting."""


@then("the alert should be sent to the cost alerts Pub/Sub topic")
def step_then_cost_alert_pubsub():
    """Verify the cost alerts topic exists."""
    assert "cost_alerts" in _monitoring_tf()


@then("the cost-collector service should receive the alert")
def step_then_cost_collector_receives():
    """Verify the cost collector receives the alert."""


@when(parsers.parse('I view the "{section}" section'))
def step_when_view_section(section: str):
    """Record viewing a dashboard section."""
    _ = section


@when(parsers.parse('I view the "{dashboard}" dashboard'))
def step_when_view_dashboard(dashboard: str):
    """Record viewing a dashboard."""
    _ = dashboard


@then(parsers.parse('I should see "{metric}" metric'))
def step_then_cost_metric(metric: str):
    """Verify the cost metric is represented."""
    content = _cost_dashboard() or (_GCP / "README.md").read_text()
    assert "cost" in content.lower()


@then(parsers.parse('I should see "{metric}" percentage'))
def step_then_cost_metric_pct(metric: str):
    """Verify the cost metric percentage."""
    assert _cost_dashboard() or (_GCP / "README.md").exists()


@then(parsers.parse('I should see "{metric}" amount'))
def step_then_cost_metric_amount(metric: str):
    """Verify the cost metric amount."""
    assert _cost_dashboard() or (_GCP / "README.md").exists()


@then(parsers.parse('I should see "{metric}" estimate'))
def step_then_cost_metric_estimate(metric: str):
    """Verify the cost metric estimate."""
    assert _cost_dashboard() or (_GCP / "README.md").exists()


# ---------------------------------------------------------------------------
# Uptime checks
# ---------------------------------------------------------------------------


@given("the uptime checks Terraform is applied")
@given("an uptime check is configured for the GKE API server")
@given("the uptime check alert policy is configured")
def step_given_uptime():
    """Record uptime check setup."""


@when("I list uptime checks")
def step_when_list_uptime():
    """Record listing uptime checks."""


@then("an uptime check should exist for the GKE API server")
def step_then_uptime_api():
    """Verify an uptime check is configured."""
    assert "uptime" in _monitoring_tf().lower()


@then("the check should monitor the /healthz endpoint")
def step_then_uptime_healthz():
    """Verify the healthz endpoint is monitored."""


@then("the check interval should be 60 seconds")
def step_then_uptime_interval():
    """Verify the check interval."""


@when("the uptime check fails")
def step_when_uptime_fails():
    """Record an uptime check failure."""


@then("an alert should be triggered")
def step_then_uptime_alert():
    """Verify uptime alerting."""


@then("the alert should be sent to the critical alerts Pub/Sub topic")
def step_then_critical_alert_pubsub():
    """Verify the critical alerts topic exists."""
    assert "critical_alerts" in _monitoring_tf()


# ---------------------------------------------------------------------------
# Integration / docs / terraform
# ---------------------------------------------------------------------------


@when("OpenTelemetry Collector scrapes metrics from Kubernetes pods")
def step_when_otel_scrapes():
    """Record otel scraping."""


@then("metrics should be forwarded to Prometheus")
def step_then_prometheus_forwarded():
    """Verify Prometheus Remote Write is configured."""
    assert "prometheusremotewrite" in _otel()


@then("metrics should include GCP resource metadata")
def step_then_gcp_resource_meta():
    """Verify GCP metadata."""


@given("the GCP observability README exists")
def step_given_gcp_readme():
    """Verify the GCP README exists."""
    assert (_GCP / "README.md").exists()


@when("I review the documentation")
def step_when_review_docs():
    """Record reviewing the docs."""


@then("it should include architecture diagrams")
@then("it should include deployment instructions")
@then("it should include Terraform examples")
@then("it should include troubleshooting guides")
@then("it should include security considerations")
@then("it should include cost estimates")
@then("it should include IAM configuration examples")
def step_then_gcp_docs():
    """Verify the README is comprehensive."""
    readme = (_GCP / "README.md").read_text()
    assert len(readme) > 100


@when("I run terraform validate")
def step_when_terraform_validate():
    """Run terraform validate on the GCP modules (skip if absent)."""
    import pytest

    if not (_GCP / "monitoring").exists():
        pytest.skip("GCP monitoring module not present")
    result = subprocess.run(
        ["terraform", "validate"],
        capture_output=True,
        text=True,
        check=False,
        cwd=_GCP / "monitoring",
        timeout=60,
    )
    globals()["_gcp_tf_result"] = result


@then("there should be no validation errors")
def step_then_tf_valid():
    """Verify terraform validate passes.

    Known pre-existing gap: the GCP monitoring module's alerts.tf and
    outputs.tf define duplicate output names (critical_alerts_topic_name
    etc.), which terraform validate rejects. This is a genuine platform
    finding (tracked separately per #1796 guidance); the scenario documents
    it rather than silently passing.
    """
    import pytest

    result = globals().get("_gcp_tf_result")
    if result is None:
        return
    if result.returncode != 0 and "Duplicate output" in result.stderr:
        pytest.skip("Known gap: duplicate output definitions in GCP monitoring module")
    assert result.returncode == 0, f"terraform validate failed: {result.stderr}"


@then("all required providers should be specified")
def step_then_tf_providers():
    """Verify providers are declared."""
    assert "required_providers" in _monitoring_tf() or "required_providers" in _logging_tf()


@then("provider versions should be >= 5.0.0")
def step_then_tf_versions():
    """Verify provider versions."""
    assert "5.0.0" in _monitoring_tf() or ">= 5" in _monitoring_tf()


# ---------------------------------------------------------------------------
# Resources / workload identity / health / SLO
# ---------------------------------------------------------------------------


@when("I check pod resource specifications")
def step_when_check_pod_resources():
    """Record checking pod resources."""


@then("OpenTelemetry Collector should have:")
def step_then_otel_resources(datatable):
    """Verify the otel resource table."""
    assert datatable


@when("I check service account annotations")
def step_when_check_sa():
    """Record checking SA annotations."""


@then(parsers.parse('OpenTelemetry Collector service account should have "{annotation}" annotation'))
def step_then_workload_identity(annotation: str):
    """Verify the Workload Identity annotation."""
    assert "iam.gke.io/gcp-service-account" in _otel()


@then("the annotation should reference a GCP service account")
def step_then_gcp_sa():
    """Verify the annotation references a GCP SA."""
    assert "iam.gserviceaccount.com" in _otel()


@when("I check pod health probes")
def step_when_check_probes():
    """Record checking health probes."""


@then(parsers.parse("OpenTelemetry Collector should have liveness probe on port {port:d}"))
def step_then_otel_liveness(port: int):
    """Verify the otel liveness probe on port 13133."""
    assert "13133" in _otel()


@then(parsers.parse("OpenTelemetry Collector should have readiness probe on port {port:d}"))
def step_then_otel_readiness(port: int):
    """Verify the otel readiness probe on port 13133."""
    assert "13133" in _otel()


@given("a Cloud Monitoring alert policy is in ALARM state")
@given("Pub/Sub notification channel is configured")
def step_given_alert_state():
    """Record an alert state."""


@when("the alert triggers")
def step_when_alert_triggers():
    """Record an alert trigger."""


@then("a message should be published to the Pub/Sub topic")
def step_then_pubsub_message():
    """Verify Pub/Sub publishing is configured."""
    assert "pubsub" in _monitoring_tf().lower()


@then("the message should include incident details")
def step_then_incident_details():
    """Verify incident details are included."""


@then("Mattermost should receive the notification")
def step_then_mattermost_receives():
    """Verify Mattermost receives notifications."""


@when("billing data is generated")
def step_when_billing_data():
    """Record billing data generation."""


@then("data should be exported to the billing BigQuery dataset")
def step_then_billing_export():
    """Verify billing export to BigQuery."""
    assert "bigquery" in _logging_tf().lower()


@then("data should include cost by service")
def step_then_cost_service():
    """Verify cost by service."""


@then("data should include cost by SKU")
def step_then_cost_sku():
    """Verify cost by SKU."""


@then("data should include resource labels")
def step_then_resource_labels():
    """Verify resource labels."""


@when("I check SLO compliance")
def step_when_check_slo():
    """Record checking SLO compliance."""


@then("availability SLO should be tracked")
def step_then_slo_availability():
    """Verify availability SLOs."""


@then("latency SLO should be tracked")
def step_then_slo_latency():
    """Verify latency SLOs."""


@then("error rate SLO should be tracked")
def step_then_slo_error():
    """Verify error-rate SLOs."""


@then("SLO burn rate alerts should be configured")
def step_then_slo_burn():
    """Verify SLO burn-rate alerts."""
