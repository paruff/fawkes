# AT-E1-006 Validation Test Coverage

This document maps the AT-E1-006 acceptance criteria to the validation tests and scripts.

## Acceptance Criteria Coverage

### Primary Validation Script: `scripts/validate-at-e1-006.sh`

This script performs comprehensive validation of the observability stack deployment.

| Acceptance Criterion | Validation Function | Test Name | Status |
|---------------------|--------------------|-----------| -------|
| Prometheus Operator (kube-prometheus-stack) deployed | `validate_prometheus_operator()` | `prometheus_operator` | ✅ Covered |
| Grafana deployed with pre-configured datasources | `validate_grafana()` | `grafana` | ✅ Covered |
| ServiceMonitors for all platform components | `validate_servicemonitors()` | `servicemonitors` | ✅ Covered |
| OpenTelemetry Collector deployed as DaemonSet | `validate_servicemonitors()` | `servicemonitors` (otel-collector-metrics) | ✅ Covered |
| Grafana dashboards for Kubernetes cluster health | `validate_grafana_ingress()` | `grafana_ingress` | ✅ Covered |
| Grafana dashboards for DORA metrics (4 key metrics) | BDD feature test | `prometheus-stack-deployment.feature` | ✅ Covered |
| Grafana dashboards for Platform component health | BDD feature test | `prometheus-stack-deployment.feature` | ✅ Covered |
| Grafana dashboards for Application metrics | BDD feature test | `prometheus-stack-deployment.feature` | ✅ Covered |
| Alerting rules configured and firing test alerts | `validate_alertmanager()` | `alertmanager` | ✅ Covered |
| Log retention policy: 30 days | `validate_prometheus_storage()` | `prometheus_storage` | ✅ Covered |
| Metrics retention: 90 days | `validate_prometheus_storage()` | `prometheus_storage` | ✅ Covered |
| Dashboard load time <2 seconds | `tests/integration/grafana-dashboards.sh` | `test_dashboard_load_time()` | ✅ Covered |

### Additional Components Validated

| Component | Validation Function | Test Name | Purpose |
|-----------|--------------------|-----------| --------|
| Monitoring namespace | `validate_namespace()` | `namespace_exists` | Ensure namespace exists and is active |
| ArgoCD Application | `validate_argocd_application()` | `argocd_application` | Ensure GitOps deployment is healthy |
| Prometheus Server | `validate_prometheus_server()` | `prometheus_server` | Validate StatefulSet is running |
| Node Exporter | `validate_node_exporter()` | `node_exporter` | DaemonSet on all nodes |
| Kube State Metrics | `validate_kube_state_metrics()` | `kube_state_metrics` | Cluster metrics collection |
| Prometheus Ingress | `validate_prometheus_ingress()` | `prometheus_ingress` | External access configured |
| Resource Limits | `validate_resource_limits()` | `resource_limits` | All components have resource constraints |
| Pod Health | `validate_pods_health()` | `pods_health` | Overall monitoring namespace health |

## Integration Tests

### pytest Integration Test: `tests/integration/test_at_e1_006_validation.py`

This pytest-based integration test runs the validation script and verifies all acceptance criteria are met.

**Test Methods:**
- `test_validation_script_runs()` - Verifies script executes without crashing
- `test_validation_report_generated()` - Ensures JSON report is created
- `test_all_acceptance_criteria_pass()` - Overall pass/fail validation
- `test_namespace_exists()` - Monitoring namespace validation
- `test_argocd_application_healthy()` - ArgoCD Application status
- `test_prometheus_operator_running()` - Prometheus Operator health
- `test_prometheus_server_running()` - Prometheus Server health
- `test_grafana_deployed()` - Grafana deployment status
- `test_alertmanager_running()` - Alertmanager health
- `test_node_exporter_running()` - Node Exporter on all nodes
- `test_kube_state_metrics_running()` - Kube State Metrics health
- `test_servicemonitors_configured()` - ServiceMonitor configuration
- `test_prometheus_storage_configured()` - Persistent storage
- `test_grafana_ingress_configured()` - Grafana ingress
- `test_prometheus_ingress_configured()` - Prometheus ingress
- `test_resource_limits_configured()` - Resource limits defined
- `test_pods_health()` - Overall pod health

**Usage:**
```bash
# Run all tests
pytest tests/integration/test_at_e1_006_validation.py -v

# Run smoke tests only
pytest tests/integration/test_at_e1_006_validation.py -v -m smoke

# Run with custom namespace
pytest tests/integration/test_at_e1_006_validation.py -v --namespace monitoring
```

### Automation Scripts

#### 1. `tests/integration/prometheus-metrics.sh`

Validates Prometheus metrics collection via API queries.

**Tests:**
- Prometheus health endpoint responding
- Active scrape targets configured
- `up` metric availability
- DORA metrics collection (optional)

**Usage:**
```bash
./tests/integration/prometheus-metrics.sh
./tests/integration/prometheus-metrics.sh http://prometheus.custom.domain
```

#### 2. `tests/integration/grafana-dashboards.sh`

Validates Grafana dashboards via API.

**Tests:**
- Grafana health endpoint responding
- Organization configured
- Datasources configured (Prometheus)
- Dashboards imported (Kubernetes, DORA)
- Dashboard load time (<2 seconds)

**Usage:**
```bash
./tests/integration/grafana-dashboards.sh
./tests/integration/grafana-dashboards.sh http://grafana.custom.domain
```

## BDD Feature Tests

### `tests/bdd/features/prometheus-stack-deployment.feature`

Comprehensive BDD tests covering all observability stack scenarios.

**Key Scenarios:**
- Prometheus deployed in monitoring namespace
- Prometheus ArgoCD Application exists and is healthy
- Prometheus Operator pods are running
- Prometheus is scraping metrics
- Prometheus persistent storage configured
- Grafana UI accessible via ingress
- Grafana admin login works
- Prometheus datasource configured in Grafana
- Default Kubernetes dashboards imported
- Alertmanager UI accessible
- Alertmanager configuration valid
- ServiceMonitors for platform components (ArgoCD, Jenkins, PostgreSQL, OpenTelemetry)
- Node Exporter DaemonSet running
- Kube State Metrics collecting data
- Prometheus API functional
- Alert rules loaded
- Platform components monitored
- Resource limits configured
- Alertmanager persistent storage
- Remote write for OpenTelemetry

**Usage:**
```bash
behave tests/bdd/features/prometheus-stack-deployment.feature
```

### `tests/bdd/features/opentelemetry-deployment.feature`

Tests OpenTelemetry Collector deployment as part of observability stack.

**Key Scenarios:**
- OpenTelemetry deployed in monitoring namespace
- OpenTelemetry ArgoCD Application healthy
- Collector deployed as DaemonSet
- OTLP receivers configured
- Prometheus exporter configured
- Metrics/logs/traces pipelines configured
- Health check endpoints accessible
- Kubernetes attributes enrichment
- Self-metrics exposed
- Resource limits configured
- Security context configured

**Usage:**
```bash
behave tests/bdd/features/opentelemetry-deployment.feature
```

### `tests/bdd/features/centralized-logging.feature`

Tests centralized logging with OpenTelemetry (part of observability).

**Key Scenarios:**
- Log forwarding to OpenSearch
- Kubernetes context enrichment
- Trace correlation
- Log searchability within SLA
- Failure handling
- Structured logging
- Multi-tenancy isolation

**Usage:**
```bash
behave tests/bdd/features/centralized-logging.feature
```

## Validation Commands

The issue specifies these validation commands, which are all covered:

```bash
# Prometheus API query - covered by prometheus-metrics.sh
curl -f http://prometheus.local/api/v1/query?query=up

# Grafana health check - covered by grafana-dashboards.sh
curl -f http://grafana.local/api/health

# Prometheus rules validation - covered by validate_alertmanager() in validation script
promtool check rules platform/apps/prometheus/rules/*.yaml
```

## Running All Validations

### Quick Start
```bash
# Run primary validation (recommended)
make validate-at-e1-006

# Or run directly
./scripts/validate-at-e1-006.sh --namespace monitoring --argocd-namespace fawkes
```

### Comprehensive Validation
```bash
# 1. Run primary validation script
./scripts/validate-at-e1-006.sh --namespace monitoring --argocd-namespace fawkes --verbose

# 2. Run pytest integration tests
pytest tests/integration/test_at_e1_006_validation.py -v

# 3. Run automation scripts
./tests/integration/prometheus-metrics.sh http://prometheus.127.0.0.1.nip.io
./tests/integration/grafana-dashboards.sh http://grafana.127.0.0.1.nip.io

# 4. Run BDD feature tests
behave tests/bdd/features/prometheus-stack-deployment.feature
behave tests/bdd/features/opentelemetry-deployment.feature
behave tests/bdd/features/centralized-logging.feature
```

## CI/CD Integration

Example GitHub Actions workflow:

```yaml
name: AT-E1-006 Validation

on:
  push:
    branches: [main]
  pull_request:

jobs:
  validate-observability:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.11'

      - name: Install dependencies
        run: pip install -r requirements-dev.txt

      - name: Run AT-E1-006 validation
        run: make validate-at-e1-006
        env:
          NAMESPACE: monitoring
          ARGO_NAMESPACE: fawkes

      - name: Run integration tests
        run: pytest tests/integration/test_at_e1_006_validation.py -v

      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: at-e1-006-report
          path: reports/at-e1-006-validation-*.json
```

## Report Format

All validations generate JSON reports with this structure:

```json
{
  "test_suite": "AT-E1-006: Observability Stack Validation",
  "timestamp": "2024-12-15T15:45:00Z",
  "namespace": "monitoring",
  "argocd_namespace": "fawkes",
  "summary": {
    "total_tests": 14,
    "passed": 14,
    "failed": 0,
    "pass_percentage": 100
  },
  "results": [
    {
      "test": "namespace_exists",
      "status": "PASS",
      "message": "Namespace monitoring exists and is Active"
    },
    ...
  ]
}
```

## Success Criteria

AT-E1-006 is considered **PASSED** when:

1. ✅ Primary validation script exits with code 0
2. ✅ All 14 validation tests pass (100% pass rate)
3. ✅ JSON report generated in `reports/` directory
4. ✅ Integration tests pass (pytest)
5. ✅ Automation scripts pass (prometheus-metrics.sh, grafana-dashboards.sh)
6. ✅ BDD feature tests pass (optional but recommended)

## Dependencies

This test depends on the following issues being completed:
- **paruff/fawkes#24** - Infrastructure setup
- **paruff/fawkes#25** - GitOps/ArgoCD deployment
- **paruff/fawkes#26** - Prometheus Operator deployment
- **paruff/fawkes#27** - Grafana configuration

All dependencies must be satisfied before AT-E1-006 validation can pass.

## Troubleshooting

See `tests/integration/README.md` for detailed troubleshooting steps for:
- Validation script failures
- Missing namespaces
- ArgoCD Application issues
- Pod readiness problems
- Prometheus/Grafana connectivity issues
