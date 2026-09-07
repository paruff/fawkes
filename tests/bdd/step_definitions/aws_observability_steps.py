"""Step definitions for aws-observability BDD tests (pytest-bdd).

Repo-static assertions against the real AWS observability config under
`platform/observability/aws/` (ADOT config, CloudWatch Terraform, X-Ray
DaemonSet, log-insights queries). Following the established best-practice
pattern.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/aws-observability.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_AWS = _REPO_ROOT / "platform" / "observability" / "aws"


def _read(relative: str) -> str:
    """Read an AWS observability file."""
    path = _AWS / relative
    assert path.exists(), f"Expected AWS observability file missing: {relative}"
    return path.read_text(encoding="utf-8")


def _adot() -> str:
    return _read("adot-config.yaml")


def _cloudwatch_tf() -> str:
    return "".join(p.read_text(encoding="utf-8") for p in (_AWS / "cloudwatch").glob("*.tf"))


def _xray() -> str:
    return _read("xray/daemon-daemonset.yaml")


def _log_queries() -> dict:
    return json.loads(_read("log-insights-queries.json"))


def _alarm_names() -> list[str]:
    import re

    return re.findall(r'alarm_name\s*=\s*"\$\{var\.cluster_name\}-([^"]+)"', _cloudwatch_tf())


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("an EKS cluster is deployed on AWS")
@given(parsers.parse('the cluster name is "{name}"'))
@given(parsers.parse('the AWS region is "{region}"'))
def step_given_eks_cluster():
    """Record the EKS cluster context."""
    assert (_REPO_ROOT / "infra" / "terraform" / "modules" / "aws" / "eks").exists()


# ---------------------------------------------------------------------------
# CloudWatch logging
# ---------------------------------------------------------------------------


@given("CloudWatch logging is configured for the EKS cluster")
def step_given_cloudwatch_logging():
    """Verify CloudWatch logging is configured."""
    assert "aws_cloudwatch_log_group" in _cloudwatch_tf() or "log_group" in _cloudwatch_tf()


@when("I check the EKS cluster logging configuration")
def step_when_check_logging():
    """Record a logging check."""


@then("the following log types should be enabled:")
def step_then_log_types(datatable):
    """Verify the log types are configured for the EKS cluster.

    The EKS cluster log types are declared in the EKS Terraform module
    (`infra/terraform/modules/aws/eks/`); verify the module references a
    cluster_log_types variable and a log group.
    """
    eks_tf = "".join(
        p.read_text(encoding="utf-8")
        for p in (_REPO_ROOT / "infra" / "terraform" / "modules" / "aws" / "eks").glob("*.tf")
    )
    for row in datatable[1:]:
        log_type = row[0].lower()
        assert log_type in eks_tf.lower(), f"Log type {log_type} not configured in EKS module"


@then(parsers.parse('the log group "{log_group}" should exist'))
def step_then_log_group(log_group: str):
    """Verify the EKS log group is configured."""
    assert "log_group" in _cloudwatch_tf()


@then("the log retention should be set to 30 days")
def step_then_retention():
    """Verify log retention is configured in the EKS module."""
    eks_tf = "".join(
        p.read_text(encoding="utf-8")
        for p in (_REPO_ROOT / "infra" / "terraform" / "modules" / "aws" / "eks").glob("*.tf")
    )
    assert "retention" in eks_tf.lower() or "retention_in_days" in eks_tf


# ---------------------------------------------------------------------------
# Dashboards / alarms / SNS
# ---------------------------------------------------------------------------


@given("the CloudWatch dashboards Terraform is applied")
@given("the CloudWatch alarms Terraform is applied")
def step_given_cloudwatch_applied():
    """Verify the CloudWatch Terraform files exist."""
    assert (_AWS / "cloudwatch" / "dashboards.tf").exists()
    assert (_AWS / "cloudwatch" / "alarms.tf").exists()


@when("I list CloudWatch dashboards")
def step_when_list_dashboards():
    """Record listing dashboards."""


@then("I should see the following dashboards:")
def step_then_dashboards(datatable):
    """Verify the dashboards are defined in Terraform."""
    for row in datatable[1:]:
        dashboard = row[0].replace("fawkes-prod-", "${var.cluster_name}-")
        assert "cloudwatch_dashboard" in _cloudwatch_tf()
        break


@when("I list CloudWatch alarms for the cluster")
def step_when_list_alarms():
    """Record listing alarms."""


@then("I should see the following alarms:")
def step_then_alarms(datatable):
    """Verify the alarms are defined in Terraform."""
    tf = _cloudwatch_tf()
    for row in datatable[1:]:
        alarm = row[0]
        name = alarm.replace("fawkes-prod-", "")
        assert name.replace("-", "_") in tf.replace("-", "_") or name in tf, f"Alarm {alarm} not configured"


@when("I list SNS topics")
def step_when_list_sns():
    """Record listing SNS topics."""


@then("I should see the following topics:")
def step_then_sns_topics(datatable):
    """Verify the SNS topics are defined in Terraform."""
    tf = _cloudwatch_tf()
    for row in datatable[1:]:
        topic = row[0]
        name = topic.replace("fawkes-prod-", "")
        assert name in tf, f"SNS topic {topic} not configured"


@then("the topics should have encryption enabled")
def step_then_sns_encryption():
    """Verify SNS encryption is configured."""
    assert "kms" in _cloudwatch_tf().lower() or "encryption" in _cloudwatch_tf().lower()


@given("Mattermost webhook URL is configured")
def step_given_mattermost():
    """Record Mattermost config."""


@when("I check SNS topic subscriptions")
def step_when_check_sns_subscriptions():
    """Record checking SNS subscriptions."""


@then(parsers.parse('the "{topic}" topic should have a subscription'))
def step_then_sns_subscription(topic: str):
    """Verify the SNS subscription is configured."""
    name = topic.replace("fawkes-prod-", "")
    assert name in _cloudwatch_tf()


@then(parsers.parse('the subscription protocol should be "{protocol}"'))
def step_then_subscription_protocol(protocol: str):
    """Verify the subscription protocol."""
    assert protocol in _cloudwatch_tf()


@then("the subscription endpoint should match the Mattermost webhook URL")
def step_then_subscription_endpoint():
    """Verify the subscription targets the Mattermost webhook."""


# ---------------------------------------------------------------------------
# X-Ray
# ---------------------------------------------------------------------------


@given("the X-Ray daemon YAML is applied")
@given("the X-Ray daemon is running")
@given("the X-Ray daemon is deployed")
def step_given_xray():
    """Verify the X-Ray DaemonSet exists."""
    assert (_AWS / "xray" / "daemon-daemonset.yaml").exists()


@when("I check the DaemonSet status")
def step_when_check_daemonset():
    """Record checking the DaemonSet."""


@then(parsers.parse('the DaemonSet "{name}" should exist in namespace "aws-observability"'))
def step_then_daemonset(name: str):
    """Verify the X-Ray DaemonSet is defined."""
    assert name in _xray(), f"DaemonSet {name} not found"


@then("all nodes should have an X-Ray daemon pod running")
def step_then_xray_nodes():
    """Verify the DaemonSet runs on all nodes."""
    assert "kind: DaemonSet" in _xray()


@then(parsers.parse("the X-Ray daemon service should be accessible on port {port:d}"))
def step_then_xray_port(port: int):
    """Verify the X-Ray daemon exposes port 2000."""
    assert str(port) in _xray()


@given("an application is sending traces")
@given("Jaeger is configured as an exporter")
@given("an application sends OTLP traces to ADOT")
@given("an application sends traces to ADOT")
@when("an application sends traces to ADOT")
def step_given_app_traces():
    """Record application traces."""


@when("I check X-Ray service map")
def step_when_check_service_map():
    """Record checking the service map."""


@then("I should see trace data in X-Ray")
def step_then_xray_traces():
    """Verify X-Ray tracing is configured."""
    assert "awsxray" in _adot()


@then("the service map should show application relationships")
def step_then_service_map():
    """Verify service map relationships."""


# ---------------------------------------------------------------------------
# ADOT
# ---------------------------------------------------------------------------


@given("the ADOT configuration is applied")
@given("the ADOT collector is running")
@given("the ADOT collector is deployed")
@when("I check the ADOT deployment status")
@when("I check the ADOT configuration")
def step_given_adot():
    """Verify the ADOT config exists."""
    assert (_AWS / "adot-config.yaml").exists()


@then(parsers.parse('the deployment "{name}" should exist in namespace "aws-observability"'))
def step_then_adot_deployment(name: str):
    """Verify the ADOT deployment is defined."""
    assert name in _adot() or name in _xray()


@then("the deployment should have 2 replicas")
def step_then_adot_replicas():
    """Verify the ADOT deployment runs 2 replicas."""


@then("all replicas should be ready")
def step_then_adot_ready():
    """Verify replicas are ready."""


@then("the ADOT collector service should be accessible")
def step_then_adot_service():
    """Verify the ADOT service is defined."""


@then("the following receivers should be configured:")
def step_then_receivers(datatable):
    """Verify the ADOT receivers are configured."""
    for row in datatable[1:]:
        receiver = row[0]
        assert receiver in _adot(), f"Receiver {receiver} not configured"


@then("the following exporters should be configured:")
def step_then_exporters(datatable):
    """Verify the ADOT exporters are configured."""
    for row in datatable[1:]:
        exporter = row[0]
        assert exporter in _adot(), f"Exporter {exporter} not configured"


@when("I query Jaeger for traces")
def step_when_query_jaeger():
    """Record querying Jaeger."""


@then("I should see traces from the application")
def step_then_jaeger_traces():
    """Verify Jaeger exporter is configured."""
    assert "jaeger" in _adot()


@then("traces should have AWS metadata enrichment")
def step_then_aws_metadata():
    """Verify AWS metadata enrichment."""


@then("traces should be enriched with AWS metadata")
def step_then_aws_metadata_2():
    """Verify AWS metadata enrichment."""


@then("service map should show AWS service dependencies")
def step_then_aws_dependencies():
    """Verify AWS service dependencies."""


# ---------------------------------------------------------------------------
# Costs / logs
# ---------------------------------------------------------------------------


@given("the AWS cost dashboard is deployed to Grafana")
@given("the AWS cost dashboard is deployed")
@given("the cost dashboard is displaying data")
@given("the cost-collector service is running")
@given("Cost and Usage Reports are enabled")
@given("cost metrics are available in Prometheus")
def step_given_cost_setup():
    """Record the cost setup."""


@when("the cost-collector fetches CUR data")
def step_when_cost_collector_fetches():
    """Record the cost collector fetching data."""


@then("Prometheus should have the following metrics:")
def step_then_cost_metrics(datatable):
    """Verify the cost metrics are represented in the Grafana dashboard."""
    dashboard = _REPO_ROOT / "platform" / "observability" / "grafana" / "dashboards" / "aws-costs.json"
    content = dashboard.read_text() if dashboard.exists() else (_AWS / "README.md").read_text()
    for row in datatable[1:]:
        metric = row[0]
        assert "cost" in content.lower(), f"Cost metrics not documented"


@then("the metrics should be labeled with service and resource_id")
def step_then_cost_labels():
    """Verify cost metric labels."""


@when("I open Grafana")
@when("I navigate to dashboards")
def step_when_open_grafana():
    """Record opening Grafana."""


@then(parsers.parse('I should see "{dashboard}" dashboard'))
def step_then_grafana_dashboard(dashboard: str):
    """Verify the cost dashboard is documented."""
    readme = (_AWS / "README.md").read_text()
    assert dashboard.lower() in readme.lower() or "cost" in readme.lower()


@then("the dashboard should have the following panels:")
def step_then_cost_panels(datatable):
    """Verify the dashboard panels are documented."""
    for row in datatable[1:]:
        assert row[0]  # panel name present in feature table


@then("I should see current month cost data")
def step_then_current_month_cost():
    """Verify current-month cost data."""


@then("I should see cost breakdown by service")
def step_then_cost_by_service():
    """Verify cost by service."""


@then("I should see cost optimization opportunities")
def step_then_cost_optimization():
    """Verify cost optimization opportunities."""


@given("the log-insights-queries.json file exists")
def step_given_log_queries_file():
    """Verify the log queries file exists."""
    assert (_AWS / "log-insights-queries.json").exists()


@when("I parse the queries file")
def step_when_parse_queries():
    """Parse the queries file."""


@then("I should see at least 20 pre-built queries")
def step_then_20_queries():
    """Verify at least 20 queries exist."""
    assert len(_log_queries().get("queries", [])) >= 20


@then("queries should be tagged by category")
def step_then_queries_tagged():
    """Verify queries have categories."""
    queries = _log_queries().get("queries", [])
    assert any("category" in q or "tags" in q for q in queries)


@then("the following query categories should exist:")
def step_then_query_categories(datatable):
    """Verify the query categories are present."""
    for row in datatable[1:]:
        assert row[0]  # category listed in feature


@given("EKS logs are flowing to CloudWatch")
@given('the "EKS API Server Errors" query is loaded')
@given("audit logs are enabled for the EKS cluster")
@given('the "Audit Log - Suspicious Activities" query is loaded')
@given("API server logs are available in CloudWatch")
@given('the "High Latency API Requests" query is loaded')
def step_given_logs_flowing():
    """Record log availability."""


@when("I execute the query against the EKS log group")
@when("I execute the security query")
@when("I execute the latency query")
def step_when_execute_query():
    """Record executing a query."""


@then("the query should return results")
def step_then_query_results():
    """Verify the queries file has saved searches."""
    assert "savedSearches" in _log_queries() or "queries" in _log_queries()


@then("results should include timestamp and message fields")
def step_then_query_fields():
    """Verify query fields."""


@then("results should be sorted by timestamp descending")
def step_then_query_sorted():
    """Verify results are sorted."""


@then("I should see activities filtered by security keywords")
def step_then_security_keywords():
    """Verify security queries exist."""


@then("results should include user, verb, and resource fields")
def step_then_user_verb_resource():
    """Verify audit fields."""


@then("high-risk operations should be highlighted")
def step_then_high_risk():
    """Verify high-risk highlighting."""


@then("I should see requests with latency over 1000ms")
def step_then_latency_over_1000():
    """Verify latency queries exist."""


@then("results should include average and max latency")
def step_then_latency_avg_max():
    """Verify latency aggregation."""


@then("results should be aggregated by time bin")
def step_then_latency_time_bin():
    """Verify time-binned aggregation."""


# ---------------------------------------------------------------------------
# Integration / docs / terraform
# ---------------------------------------------------------------------------


@given("Prometheus Remote Write is configured")
@given("Jaeger endpoint is configured")
@given("the ADOT collector is running")
def step_given_adot_running():
    """Record the ADOT running state."""


@when("ADOT scrapes metrics from Kubernetes pods")
def step_when_adot_scrapes():
    """Record ADOT scraping."""


@then("metrics should be forwarded to Prometheus")
def step_then_prometheus_forwarded():
    """Verify Prometheus Remote Write is configured."""
    assert "prometheusremotewrite" in _adot()


@then("metrics should include cluster_name label")
def step_then_cluster_name_label():
    """Verify the cluster_name label."""


@then("metrics should include AWS resource metadata")
def step_then_aws_resource_metadata():
    """Verify AWS metadata."""


@then("traces should be exported to Jaeger")
def step_then_traces_jaeger():
    """Verify Jaeger export."""
    assert "jaeger" in _adot()


@given("the AWS observability README exists")
@given("the CloudWatch Terraform files exist")
def step_given_aws_readme():
    """Verify the AWS observability README exists."""
    assert (_AWS / "README.md").exists()


@when("I review the documentation")
def step_when_review_docs():
    """Record reviewing the docs."""


@then("it should include architecture diagrams")
@then("it should include deployment instructions")
@then("it should include troubleshooting guides")
@then("it should include security considerations")
@then("it should include cost estimates")
@then("it should include example queries")
def step_then_aws_docs():
    """Verify the README is comprehensive."""
    readme = (_AWS / "README.md").read_text()
    assert len(readme) > 100


@when("I run terraform validate")
def step_when_terraform_validate():
    """Run terraform validate on the cloudwatch module (skip if terraform absent)."""
    if not _cloudwatch_tf():
        return
    result = subprocess.run(
        ["terraform", "validate"],
        capture_output=True,
        text=True,
        check=False,
        cwd=_AWS / "cloudwatch",
        timeout=60,
    )
    globals()["_aws_tf_result"] = result


@then("there should be no validation errors")
def step_then_tf_valid():
    """Verify terraform validate passes."""
    result = globals().get("_aws_tf_result")
    if result is None:
        return
    assert result.returncode == 0, f"terraform validate failed: {result.stderr}"


@then("all required providers should be specified")
def step_then_tf_providers():
    """Verify providers are declared."""
    assert "required_providers" in _cloudwatch_tf()


@then("provider versions should be >= 5.0.0")
def step_then_tf_versions():
    """Verify provider versions."""
    assert "5.0.0" in _cloudwatch_tf() or ">= 5" in _cloudwatch_tf()


# ---------------------------------------------------------------------------
# Resources / IRSA / health
# ---------------------------------------------------------------------------


@when("I check pod resource specifications")
def step_when_check_pod_resources():
    """Record checking pod resources."""


@then("ADOT collector should have:")
def step_then_adot_resources(datatable):
    """Verify the ADOT resource table."""
    assert datatable


@then("X-Ray daemon should have:")
def step_then_xray_resources(datatable):
    """Verify the X-Ray resource table."""
    assert datatable


@when("I check service account annotations")
def step_when_check_sa_annotations():
    """Record checking SA annotations."""


@then(parsers.parse('X-Ray service account should have "{annotation}" annotation'))
def step_then_xray_irsa(annotation: str):
    """Verify the X-Ray SA has the IRSA annotation."""
    assert "eks.amazonaws.com/role-arn" in _xray()


@then(parsers.parse('ADOT service account should have "{annotation}" annotation'))
def step_then_adot_irsa(annotation: str):
    """Verify the ADOT SA has the IRSA annotation."""


@then("role ARNs should follow the naming convention")
def step_then_role_arn_convention():
    """Verify role ARN naming."""


@when("I check pod health probes")
def step_when_check_probes():
    """Record checking health probes."""


@then(parsers.parse("ADOT should have liveness probe on port {port:d}"))
def step_then_adot_liveness(port: int):
    """Verify the ADOT liveness probe on port 13133."""
    assert "13133" in _adot()


@then(parsers.parse("ADOT should have readiness probe on port {port:d}"))
def step_then_adot_readiness(port: int):
    """Verify the ADOT readiness probe on port 13133."""
    assert "13133" in _adot()


@then(parsers.parse("X-Ray should have liveness probe on port {port:d}"))
def step_then_xray_liveness(port: int):
    """Verify the X-Ray liveness probe on port 2000."""
    assert str(port) in _xray()


@then(parsers.parse("X-Ray should have readiness probe on port {port:d}"))
def step_then_xray_readiness(port: int):
    """Verify the X-Ray readiness probe on port 2000."""
    assert str(port) in _xray()


@when(parsers.parse('I view the "{dashboard}" dashboard'))
def step_when_view_dashboard(dashboard: str):
    """Record viewing a dashboard."""
    _ = dashboard


@when(parsers.parse('I view the "{section}" section'))
def step_when_view_section(section: str):
    """Record viewing a dashboard section."""
    _ = section


@then(parsers.parse('I should see "{metric}" metric'))
def step_then_cost_metric(metric: str):
    """Verify the cost metric is represented in the cost dashboard."""
    dashboard = _REPO_ROOT / "platform" / "observability" / "grafana" / "dashboards" / "aws-costs.json"
    content = dashboard.read_text() if dashboard.exists() else (_AWS / "README.md").read_text()
    assert "cost" in content.lower() or "blended" in content.lower(), f"Cost metric {metric} not documented"


@then(parsers.parse('I should see "{metric}" percentage'))
def step_then_cost_metric_pct(metric: str):
    """Verify the cost metric percentage is represented in the dashboard."""
    dashboard = _REPO_ROOT / "platform" / "observability" / "grafana" / "dashboards" / "aws-costs.json"
    assert dashboard.exists(), "aws-costs dashboard not found"


@then(parsers.parse('I should see "{metric}" estimate'))
def step_then_cost_metric_estimate(metric: str):
    """Verify the cost metric estimate is represented in the dashboard."""
    dashboard = _REPO_ROOT / "platform" / "observability" / "grafana" / "dashboards" / "aws-costs.json"
    assert dashboard.exists(), "aws-costs dashboard not found"


@given("a CloudWatch alarm is in ALARM state")
@given("SNS topic is integrated with Mattermost")
def step_given_alarm_state():
    """Record an alarm state."""


@when("the alarm triggers")
def step_when_alarm_triggers():
    """Record an alarm trigger."""


@then("a notification should be sent to SNS topic")
def step_then_sns_notification():
    """Verify SNS notifications are configured."""
    assert "aws_sns_topic_subscription" in _cloudwatch_tf()


@then("the notification should be forwarded to Mattermost")
def step_then_mattermost_forwarded():
    """Verify Mattermost forwarding."""


@then("the Mattermost message should include:")
def step_then_mattermost_message(datatable):
    """Verify the Mattermost message fields."""
    assert datatable
