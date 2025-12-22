# Grafana Dashboards

## Overview

This directory contains Grafana dashboard JSON definitions for the Fawkes platform. Dashboards are automatically loaded into Grafana via ConfigMaps with the `grafana_dashboard: "1"` label.

## Available Dashboards

### 1. Kubernetes Cluster Health

**File**: `kubernetes-cluster-health-dashboard.json`  
**ConfigMap**: `platform/apps/prometheus/kubernetes-cluster-health-dashboard.yaml`  
**Namespace**: monitoring

Comprehensive monitoring of Kubernetes cluster infrastructure.

#### Panels

- **Cluster Overview**: Total nodes, ready nodes, running pods, namespaces
- **Node Resources**: CPU and memory usage percentage per node with thresholds
- **Pod Status**: Distribution of pod phases and restart tracking
- **Resource Utilization**: CPU and memory usage by namespace with stacking
- **Storage**: PersistentVolume status and disk usage by node

#### Key Metrics

```promql
# Node status
kube_node_status_condition{condition="Ready",status="true"}

# CPU usage
(1 - avg by (node) (irate(node_cpu_seconds_total{mode="idle"}[5m]))) * 100

# Memory usage
(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100

# Pod status
kube_pod_status_phase{phase="Running"}
```

---

### 2. Platform Components Health

**File**: `platform-components-health-dashboard.json`  
**ConfigMap**: `platform/apps/prometheus/platform-components-health-dashboard.yaml`  
**Namespace**: monitoring

Monitor health and performance of Fawkes platform components.

#### Panels

- **Component Status**: Health indicators for ArgoCD, Jenkins, Backstage, Harbor, PostgreSQL, OpenTelemetry
- **ArgoCD Applications**: Sync status, health status, out-of-sync count
- **Jenkins Metrics**: Job success rate, executor usage, queue length
- **Container Registry**: Harbor projects, repositories, storage usage, scan rate
- **Observability Stack**: Prometheus targets, TSDB size, trace ingestion
- **Component Response Times**: P95 latency for platform services

#### Key Metrics

```promql
# Component health
up{job=~"argocd-server-metrics|jenkins-metrics|backstage-metrics"}

# ArgoCD applications
argocd_app_info{sync_status="Synced",health_status="Healthy"}

# Jenkins metrics
jenkins_job_success_total
jenkins_executor_in_use_total

# Harbor metrics
harbor_project_total
harbor_system_volumes_bytes
```

---

### 3. DORA Metrics (Placeholder)

**File**: `dora-metrics-dashboard.json`  
**ConfigMap**: `platform/apps/prometheus/dora-metrics-dashboard.yaml`  
**Namespace**: monitoring

Track DORA (DevOps Research and Assessment) four key metrics.

#### Panels

- **Deployment Frequency**: Deploys per day/week (Elite: On-demand, multiple per day)
- **Lead Time for Changes**: Commit to production time (Elite: < 1 hour)
- **Change Failure Rate**: Failed deployments percentage (Elite: 0-15%)
- **Mean Time to Restore**: Incident to restore time (Elite: < 1 hour)
- **Trends and Analysis**: Historical data and breakdowns by service

#### Implementation Notes

⚠️ **This is a placeholder dashboard**. To populate data:

1. Follow the [DORA Metrics Implementation Playbook](../../../../docs/playbooks/dora-metrics-implementation.md)
2. Configure deployment event collection from ArgoCD
3. Configure Jenkins pipeline metrics integration
4. Set up incident tracking for MTTR
5. Wait 2-4 weeks for baseline data collection

#### Expected Metrics

```promql
# Deployment frequency
dora_deployments_total

# Lead time
dora_lead_time_seconds

# Change failure rate
dora_deployment_failures_total / dora_deployments_total

# MTTR
dora_mttr_seconds
```

---

### 4. Application Metrics Template

**File**: `application-metrics-template-dashboard.json`  
**ConfigMap**: `platform/apps/prometheus/application-metrics-template-dashboard.yaml`  
**Namespace**: monitoring

Template dashboard based on the Golden Signals approach for monitoring applications.

#### Panels

- **Golden Signals Overview**: Request rate, error rate, P95 latency, CPU usage
- **Traffic**: Request rate over time, by method and status
- **Latency**: Response time percentiles (P50, P95, P99), by endpoint
- **Errors**: Error rate by status code, percentage over time
- **Saturation**: CPU usage, memory usage, pod count
- **Custom Metrics**: Placeholder panels for application-specific metrics

#### How to Use

1. **Clone this dashboard** in Grafana UI (Save → Save As)
2. **Rename** it to your application name (e.g., "My App Metrics")
3. **Update variables**:
   - Set `service` variable to match your application's service label
   - Set `namespace` variable to your app's namespace
4. **Customize queries**: Adjust metric names to match your application
5. **Add custom panels**: Extend with application-specific metrics

#### Required Metrics

Your application should expose these metrics:

```promql
# Traffic
http_requests_total{service="$service",namespace="$namespace"}

# Latency
http_request_duration_seconds_bucket{service="$service"}

# Errors
http_requests_total{service="$service",status=~"5.."}

# Saturation
container_cpu_usage_seconds_total{namespace="$namespace"}
container_memory_working_set_bytes{namespace="$namespace"}
```

---

### 5. Trivy Security Dashboard

**File**: `trivy-security-dashboard.json`  
**Purpose**: Container security scanning visibility

See [Trivy Dashboard README](README.md) in this directory for details.

---

### 6. VSM Flow Metrics Dashboard

**File**: `vsm-flow-metrics.json`  
**ConfigMap**: Loaded via Grafana provisioning  
**Namespace**: monitoring

Comprehensive Value Stream Mapping flow metrics dashboard showing WIP, throughput, cycle time, lead time, and bottleneck detection.

#### Panels

- **Flow Metrics Overview**:
  - Total WIP (Work in Progress): Count across all stages
  - Throughput: Items completed in last 7 days
  - Lead Time (P50): Median time from backlog to production
  - Avg Cycle Time: Average completion time

- **Cumulative Flow Diagram**:
  - WIP by Stage Over Time: Stacked area chart showing work distribution
  - Identifies where work accumulates

- **Throughput & Flow**:
  - Daily Throughput: Bar chart of items completed per day
  - Weekly Throughput Trend: 7-day rolling average

- **Cycle Time Analysis**:
  - Cycle Time by Stage: Median time spent in each stage
  - Stage Cycle Time Distribution: Current stage timings

- **Lead Time Trends**:
  - Lead Time Percentiles: P50, P75, P95 over time

- **Bottleneck Detection**:
  - WIP by Stage: Pie chart identifying high-WIP stages
  - Stage Transition Rate: Flow rate between stages
  - High WIP Stages: Table of potential bottlenecks
  - Stage Cycle Time Comparison: Horizontal bar gauge

#### Key Metrics

```promql
# Work in progress
vsm_work_in_progress{stage="Development"}

# Throughput
sum(increase(vsm_throughput_per_day[7d]))

# Lead time percentiles
histogram_quantile(0.50, sum(rate(vsm_lead_time_seconds_bucket[7d])) by (le))

# Stage cycle time
histogram_quantile(0.50, sum(rate(vsm_stage_cycle_time_seconds_bucket{stage="Testing"}[7d])) by (le))

# Stage transitions
sum(rate(vsm_stage_transitions_total{to_stage="Production"}[5m]))
```

#### Variables

- **time_range**: Time range for metrics aggregation (1h, 6h, 12h, 1d, 7d, 30d)

#### Thresholds

- **WIP**:
  - 🟢 Green: < 20 items
  - 🟡 Yellow: 20-50 items
  - 🟠 Orange: 50-100 items
  - 🔴 Red: > 100 items

- **Lead Time**:
  - 🟢 Green: < 24 hours
  - 🟡 Yellow: 24-168 hours (1-7 days)
  - 🟠 Orange: 168-336 hours (1-2 weeks)
  - 🔴 Red: > 336 hours (2+ weeks)

- **Cycle Time**:
  - 🟢 Green: < 48 hours
  - 🟡 Yellow: 48-168 hours (2-7 days)
  - 🟠 Orange: 168-336 hours (1-2 weeks)
  - 🔴 Red: > 336 hours (2+ weeks)

#### Implementation Notes

Requires:
1. VSM service running (`services/vsm/`)
2. Work items being tracked through stages
3. Prometheus scraping VSM `/metrics` endpoint
4. ServiceMonitor configured for metrics collection

See [VSM Service README](../../../../services/vsm/README.md) for setup details.

---

### 7. Data Quality Dashboard

**File**: `data-quality.json`  
**ConfigMap**: Loaded via Grafana provisioning  
**Namespace**: monitoring

Comprehensive monitoring of data quality metrics from Great Expectations validations.

#### Panels

- **Overview Section**:
  - Overall Data Quality Score: Percentage of all expectations passing
  - Validation Pass/Fail Summary: Current status counts
  - Total Validation Runs: Activity in last 24 hours

- **Validation Results by Datasource**:
  - Status table: Per-datasource validation status with success rates
  - Success rate bar gauges: Visual comparison across datasources

- **Failed Expectations**:
  - Pie chart: Distribution of failures by datasource
  - Time series: Trend of failed expectations over time

- **Data Freshness**:
  - Status indicators: Time since last validation per datasource

- **Historical Trends**:
  - 7-day trend: Success rate over last week
  - 30-day trend: Success rate over last month
  - Validation runs by status: Success vs failure counts
  - Expectations evaluated: Total expectations tracked over time

#### Key Metrics

```promql
# Validation success status
data_quality_validation_success{datasource="backstage",suite="backstage_db_suite"}

# Success rate percentage
data_quality_success_rate_percent{datasource="backstage"}

# Failed expectations count
data_quality_expectation_failures_total{datasource="backstage"}

# Data freshness
data_quality_data_freshness_seconds{datasource="backstage"}

# Validation runs
data_quality_validation_runs_total{datasource="backstage",status="success"}

# Total and successful expectations
data_quality_expectations_total{datasource="backstage"}
data_quality_expectations_successful{datasource="backstage"}
```

#### Variables

- **datasource**: Filter by specific datasource(s) - Backstage, Harbor, DataHub, DORA, SonarQube
- **suite**: Filter by expectation suite name

#### Thresholds

- **Quality Score**:
  - 🔴 Red: < 70%
  - 🟠 Orange: 70-85%
  - 🟡 Yellow: 85-95%
  - 🟢 Green: ≥ 95%

- **Data Freshness**:
  - 🟢 Green: < 6 hours
  - 🟡 Yellow: 6-12 hours
  - 🟠 Orange: 12-24 hours
  - 🔴 Red: > 24 hours

#### Implementation Notes

Requires:
1. Great Expectations data quality service running
2. Prometheus exporter deployed (see `platform/apps/data-quality/`)
3. ServiceMonitor configured for metrics scraping
4. Data quality validations executed (CronJob runs every 6 hours)

See [Data Quality Service README](../../../../services/data-quality/README.md) for setup details.

---

## Installation

### Automatic (Recommended)

Dashboards are automatically loaded via Grafana's dashboard provisioning:

1. ConfigMaps are created in the `monitoring` namespace
2. Grafana sidecar watches for ConfigMaps with label `grafana_dashboard: "1"`
3. Dashboards appear automatically in Grafana UI

### Manual Import

If needed, import manually:

1. Navigate to Grafana UI at http://grafana.127.0.0.1.nip.io
2. Click "+" → "Import"
3. Upload the JSON file
4. Select "Prometheus" as the data source
5. Click "Import"

## Configuration

### Data Source

All dashboards use the Prometheus data source with UID `prometheus`. Ensure it's configured:

```yaml
datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    url: http://prometheus-prometheus.monitoring.svc.cluster.local:9090
    isDefault: true
```

### Variables

Most dashboards include template variables for dynamic filtering:

- `datasource`: Prometheus data source selector
- `namespace`: Kubernetes namespace filter
- `service`: Service name filter
- `environment`: Environment filter (for DORA metrics)

## Troubleshooting

### Dashboard Not Appearing

1. Check ConfigMap exists:
   ```bash
   kubectl get configmap -n monitoring -l grafana_dashboard=1
   ```

2. Check Grafana logs:
   ```bash
   kubectl logs -n monitoring deployment/prometheus-grafana -f
   ```

3. Verify sidecar is enabled in Grafana Helm values

### No Data Displayed

1. Verify Prometheus is scraping targets:
   ```bash
   # Check targets
   kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
   # Navigate to http://localhost:9090/targets
   ```

2. Check metrics exist:
   ```promql
   # In Prometheus UI, query for:
   up
   kube_node_info
   http_requests_total
   ```

3. Verify ServiceMonitors:
   ```bash
   kubectl get servicemonitor -n monitoring
   ```

### Incorrect Values

1. Check time range selection (top right)
2. Verify variable selections (top left dropdowns)
3. Inspect panel query (Edit → Query)
4. Check for metric label mismatches

## Customization

### Modifying Existing Dashboards

1. Edit the dashboard in Grafana UI
2. Export the JSON (Share → Export → Save to file)
3. Update the JSON file in this directory
4. Update the ConfigMap YAML wrapper
5. Apply changes:
   ```bash
   kubectl apply -f platform/apps/prometheus/<dashboard>-dashboard.yaml
   ```

### Creating New Dashboards

1. Use the Application Metrics Template as a starting point
2. Clone and customize in Grafana UI
3. Export the JSON
4. Create a ConfigMap wrapper following the existing pattern
5. Place files in appropriate directories

## Best Practices

1. **Use template variables** for dynamic filtering
2. **Set appropriate thresholds** (green/yellow/red) for alerting
3. **Include panel descriptions** to explain metrics
4. **Use consistent naming** for labels and metrics
5. **Set refresh intervals** appropriately (30s for dashboards, 1m for slow queries)
6. **Organize with row panels** to group related metrics
7. **Add annotations** for deployment and incident tracking

## Related Documentation

- [Grafana Configuration](../README.md)
- [Prometheus Setup](../../prometheus/README.md)
- [DORA Metrics Implementation](../../../../docs/playbooks/dora-metrics-implementation.md)
- [Observability Architecture](../../../../docs/architecture.md#observability)

## Support

For issues with dashboards:

1. Check the troubleshooting section above
2. Review Grafana and Prometheus logs
3. Consult the [platform documentation](../../../../docs/)
4. Open an issue in the GitHub repository

