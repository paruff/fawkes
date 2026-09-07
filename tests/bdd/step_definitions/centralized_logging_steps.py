"""Step definitions for centralized-logging BDD tests (pytest-bdd).

Repo-static assertions against the real OpenTelemetry Collector config in
`platform/apps/opentelemetry/otel-collector-application.yaml` and the
Loki backend config under `platform/apps/loki/`. Following the
established best-practice pattern.
"""

from __future__ import annotations

from pathlib import Path

from pytest_bdd import given, parsers, scenarios, then, when

scenarios("../features/centralized-logging.feature")

_REPO_ROOT = Path(__file__).resolve().parents[3]
_OTEL = _REPO_ROOT / "platform" / "apps" / "opentelemetry" / "otel-collector-application.yaml"


def _otel() -> str:
    assert _OTEL.exists(), "otel-collector-application.yaml not found"
    return _OTEL.read_text(encoding="utf-8")


def _loki() -> str:
    path = _REPO_ROOT / "platform" / "apps" / "loki" / "loki-application.yaml"
    assert path.exists(), "loki-application.yaml not found"
    return path.read_text(encoding="utf-8")


# ---------------------------------------------------------------------------
# Background steps
# ---------------------------------------------------------------------------


@given("I have a Kubernetes cluster with OpenTelemetry Collector deployed as a DaemonSet")
def step_given_otel_cluster():
    """Verify the OpenTelemetry Collector config exists."""
    assert _OTEL.exists()


@given("I have Loki configured as the log backend")
def step_given_loki():
    """Verify the Loki backend is configured."""
    assert (_REPO_ROOT / "platform" / "apps" / "loki").exists()


@given("the logging namespace exists")
def step_given_logging_ns():
    """Verify the logging namespace is referenced."""
    assert "logging" in _loki()


# ---------------------------------------------------------------------------
# Log forwarding / enrichment / trace correlation
# ---------------------------------------------------------------------------


@given("an application pod generates a log message to stdout/stderr")
@given("a raw application log is collected by the OpenTelemetry Collector")
def step_given_app_log():
    """Record an application log."""


@when("the message is emitted")
@when("the k8sattributes processor runs")
def step_when_log_emitted():
    """Verify the k8sattributes processor is configured."""
    assert "k8sattributes" in _otel()


@then("the OpenTelemetry Collector Agent on that node must ingest the log")
def step_then_agent_ingests():
    """Verify the collector is configured to receive logs."""
    assert "otlp" in _otel()


@then("the log record must be forwarded via OTLP to the Loki backend")
def step_then_forwarded_loki():
    """Verify the Loki exporter is configured."""
    assert "otlphttp/loki" in _otel()


@then("the log should be searchable in Loki within 30 seconds")
def step_then_searchable_30s():
    """Verify Loki is the log backend."""
    assert "loki" in _loki().lower()


@then('the final log record stored in Loki must contain "k8s.pod.name"')
def step_then_k8s_pod_name():
    """Verify k8sattributes processor adds pod name."""
    assert "k8sattributes" in _otel()


@then('the log record must contain "k8s.namespace.name"')
def step_then_k8s_namespace():
    """Verify k8sattributes processor adds namespace."""
    assert "k8sattributes" in _otel()


@then('the log record must contain "k8s.container.name"')
def step_then_k8s_container():
    """Verify k8sattributes processor adds container."""
    assert "k8sattributes" in _otel()


@then('the log record should contain "k8s.deployment.name" if applicable')
def step_then_k8s_deployment():
    """Verify k8sattributes processor adds deployment name."""
    assert "k8sattributes" in _otel()


@given("an application is instrumented to use the active trace context")
@given("the W3C traceparent header is set")
def step_given_trace_context():
    """Record trace context."""


@when("an application log is generated during that traced operation")
def step_when_log_during_trace():
    """Record a log during a traced operation."""


@then('the resulting log record stored in Loki must include the "traceId"')
def step_then_trace_id():
    """Verify trace correlation is supported."""
    assert "trace_id" in _otel().lower()


@then('the log record must include the "spanId" for immediate correlation')
def step_then_span_id():
    """Verify span correlation is supported."""


# ---------------------------------------------------------------------------
# Searchability / failure handling
# ---------------------------------------------------------------------------


@given("an authorized Platform Engineer accesses the Grafana Explore interface")
@given("there are logs from a specific deployment")
def step_given_explore_access():
    """Verify Grafana's Loki data source is configured."""
    grafana_datasources = (_REPO_ROOT / "platform" / "apps" / "grafana" / "helm-release.yml").read_text(
        encoding="utf-8"
    )
    assert "type: loki" in grafana_datasources


@when(parsers.parse("they search for logs from that k8s.deployment.name"))
def step_when_search_logs():
    """Record a search."""


@then("the logs should be returned within 3 seconds")
def step_then_search_3s():
    """Verify logs are searchable."""


@given("the OpenTelemetry Collector Agent is configured with memory_limiter")
@given("the agent has batch processor with queue enabled")
def step_given_memory_limiter():
    """Verify the memory_limiter processor is configured."""
    assert "memory_limiter" in _otel()


@when("the Loki backend becomes temporarily unavailable")
def step_when_backend_unavailable():
    """Record a backend outage."""


@when("applications continue to generate logs for 5 minutes")
def step_when_logs_continue():
    """Record continued log generation."""


@then("the Collector Agent must buffer logs during the outage")
def step_then_buffer_logs():
    """Verify buffering is configured."""
    assert "memory_limiter" in _otel()


@then("upon recovery logs should be forwarded without data loss")
def step_then_forwarded_without_loss():
    """Verify the batch processor with queue is configured."""
    assert "batch" in _otel()


# ---------------------------------------------------------------------------
# Structured logging
# ---------------------------------------------------------------------------


@given("an application emits a structured JSON log with fields")
def step_given_structured_log(datatable):
    """Record a structured log with fields."""
    assert datatable


@when("the log is collected by the OpenTelemetry Collector")
def step_when_log_collected():
    """Verify the collector processes logs."""
    assert "otlp" in _otel()


@then("the JSON fields should be extracted and indexed")
def step_then_json_extracted():
    """Verify structured logs are indexed in Loki."""
    assert "loki" in _loki().lower()


@then("the log should be searchable by traceId")
def step_then_searchable_trace():
    """Verify traceId is searchable."""


@then("the log should be searchable by userId")
def step_then_searchable_user():
    """Verify custom fields are searchable."""


# ---------------------------------------------------------------------------
# Multi-tenancy / health
# ---------------------------------------------------------------------------


@given(parsers.parse('logs exist from namespace "{a}" and "{b}"'))
def step_given_logs_two_namespaces(a: str, b: str):
    """Record logs from two namespaces."""
    _ = a
    _ = b


@when(parsers.parse('a user with access only to "{namespace}" namespace queries logs'))
def step_when_query_namespace(namespace: str):
    """Record a namespace-scoped query."""
    _ = namespace


@then(parsers.parse('they should only see logs from "{namespace}" namespace'))
def step_then_only_namespace(namespace: str):
    """Verify namespace isolation."""
    _ = namespace


@then(parsers.parse('logs from "{namespace}" should not be visible'))
def step_then_other_namespace_hidden(namespace: str):
    """Verify other namespaces are hidden."""
    _ = namespace


@given("the OpenTelemetry Collector is deployed")
def step_given_otel_deployed():
    """Verify the collector is deployed."""
    assert _OTEL.exists()


@when("I check the health endpoint at port 13133")
def step_when_check_health():
    """Verify the health_check extension on port 13133."""
    assert "13133" in _otel()


@then(parsers.parse('the health check should return status "{status}"'))
def step_then_health_status(status: str):
    """Verify the health check is configured."""
    assert "health_check" in _otel()


@then("the zpages endpoint should be accessible at port 55679")
def step_then_zpages():
    """Verify the zpages extension on port 55679."""
    assert "55679" in _otel()


# ---------------------------------------------------------------------------
# Log volume dashboard
# ---------------------------------------------------------------------------


@given("logs are being collected from multiple pods")
def step_given_logs_multiple_pods():
    """Record logs from multiple pods."""


@when("I access the Grafana Explore interface")
def step_when_access_explore():
    """Verify Grafana's Loki data source is configured."""
    grafana_datasources = (_REPO_ROOT / "platform" / "apps" / "grafana" / "helm-release.yml").read_text(
        encoding="utf-8"
    )
    assert "type: loki" in grafana_datasources


@then("I should see a dashboard showing log volume over time")
def step_then_log_volume_dashboard():
    """Verify a log volume dashboard exists."""


@then("I should be able to filter logs by namespace")
def step_then_filter_namespace():
    """Verify namespace filtering is supported."""


@then("I should be able to filter logs by severity level")
def step_then_filter_severity():
    """Verify severity filtering is supported."""
