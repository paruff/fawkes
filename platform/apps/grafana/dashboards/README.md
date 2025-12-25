# Grafana Dashboards

## Overview

This directory contains Grafana dashboard JSON definitions for the Fawkes platform. Dashboards are automatically loaded into Grafana via ConfigMaps with the `grafana_dashboard: "1"` label.

## Available Dashboards

### 1. Developer Experience (DevEx) Dashboard

**File**: `devex-dashboard.json`  
**ConfigMap**: `platform/apps/prometheus/devex-dashboard.yaml`  
**Namespace**: monitoring

Comprehensive Developer Experience dashboard showing all 5 SPACE framework dimensions with team-level filtering, historical trending, and alerting.

#### Panels

- **DevEx Overview**:
  - Overall DevEx Health Score: Composite score (0-100) based on all SPACE dimensions
  - SPACE Dimensions Status: Bar gauge showing health of all 5 dimensions (0-5 scale)

- **SATISFACTION**:
  - Net Promoter Score (NPS): How likely developers are to recommend platform (gauge, -100 to 100)
  - Platform Satisfaction Rating: Average satisfaction rating (1-5 scale)
  - Survey Response Rate: Percentage of developers responding to surveys
  - Burnout Percentage: Percentage reporting burnout symptoms
  - NPS Trend (30 days): Historical NPS trend

- **PERFORMANCE**:
  - Deployment Frequency: Deploys per day (stat with trend)
  - Lead Time for Changes: Commit to production time in hours (gauge)
  - Change Failure Rate: Percentage of failed deployments (gauge)
  - Build Success Rate: Percentage of successful builds

- **ACTIVITY**:
  - Active Developers: Count of developers active in last 7 days
  - Commits (7d): Total commits in last 7 days
  - Pull Requests (7d): Total PRs created in last 7 days
  - Code Reviews (7d): Total reviews completed in last 7 days
  - AI Tool Adoption: Percentage of developers using AI tools
  - Platform Engagement: Percentage of developers actively using platform weekly

- **COMMUNICATION & COLLABORATION**:
  - Avg Review Time: Average time to first code review in hours (gauge)
  - Comments per PR: Average comments per pull request
  - Cross-Team PRs: Percentage of PRs involving cross-team collaboration
  - Knowledge Sharing: Documentation contributions (wiki edits, TechDocs)

- **EFFICIENCY & FLOW**:
  - Flow State Achievement: Percentage achieving flow 3+ days per week
  - Valuable Work Time: Average % of time spent on valuable work (gauge)
  - Friction Incidents (30d): Total friction incidents reported in last 30 days
  - Cognitive Load: Average cognitive load (1-5 scale, 5=overwhelmed, gauge)

- **HISTORICAL TRENDS**:
  - DevEx Health Score Trend (30 days): Overall health score over time
  - SPACE Dimensions Trend (30 days): Individual dimension scores over time
  - Deployment Frequency Trend: Daily deployment frequency
  - Lead Time Trend: Lead time changes over time
  - Friction Incidents Trend: Daily friction incidents

#### Key Metrics

```promql
# Overall health
space_devex_health_score{team="platform"}

# Satisfaction metrics
space_nps_score{team="platform"}
space_satisfaction_rating_avg{team="platform"}
space_burnout_percentage{team="platform"}

# Performance metrics (DORA)
space_deployments_total{team="platform"}
space_lead_time_hours_avg{team="platform"}
space_change_failure_rate{team="platform"}
space_build_success_rate{team="platform"}

# Activity metrics
space_active_developers_count{team="platform"}
space_commits_total{team="platform"}
space_pull_requests_total{team="platform"}
space_ai_adoption_percentage{team="platform"}

# Communication metrics
space_avg_review_time_hours{team="platform"}
space_comments_per_pr_avg{team="platform"}
space_cross_team_pr_percentage{team="platform"}

# Efficiency metrics
space_flow_state_achievement_percentage{team="platform"}
space_valuable_work_percentage_avg{team="platform"}
space_friction_incidents_total{team="platform"}
space_cognitive_load_avg{team="platform"}
```

#### Variables

- **team**: Filter by team (multi-select, with "All" option)

#### Thresholds

- **DevEx Health Score**:
  - 🔴 Red: < 50
  - 🟠 Orange: 50-59
  - 🟡 Yellow: 60-79
  - 🟢 Green: ≥ 80

- **NPS**:
  - 🔴 Red: < 0
  - 🟠 Orange: 0-49
  - 🟡 Yellow: 50-69
  - 🟢 Green: ≥ 70

- **Satisfaction Rating**:
  - 🔴 Red: < 2.5
  - 🟠 Orange: 2.5-3.4
  - 🟡 Yellow: 3.5-3.9
  - 🟢 Green: ≥ 4.0

- **Lead Time**:
  - 🟢 Green: < 1 hour (Elite)
  - 🟡 Yellow: 1-24 hours
  - 🟠 Orange: 24-168 hours (1 week)
  - 🔴 Red: > 168 hours

- **Change Failure Rate**:
  - 🟢 Green: 0-15% (Elite)
  - 🟡 Yellow: 15-30%
  - 🟠 Orange: 30-45%
  - 🔴 Red: > 45%

- **Flow State Achievement**:
  - 🔴 Red: < 50%
  - 🟡 Yellow: 50-59%
  - 🟢 Green: ≥ 60%

- **Cognitive Load**:
  - 🟢 Green: < 3.0
  - 🟡 Yellow: 3.0-3.4
  - 🟠 Orange: 3.5-3.9
  - 🔴 Red: ≥ 4.0

#### Annotations

The dashboard includes automatic annotations for:
- **Deployments**: Green markers when deployments occur
- **Incidents**: Red markers when incidents are detected

#### Implementation Notes

Requires:
1. SPACE metrics service running (`services/space-metrics/`)
2. Prometheus scraping SPACE metrics service `/metrics` endpoint
3. ServiceMonitor configured for metrics collection
4. Survey responses being collected (NPS, pulse surveys)
5. Activity data being tracked (GitHub, Backstage, AI tools)

See [SPACE Metrics Service README](../../../../services/space-metrics/README.md) and [ADR-018 SPACE Framework](../../../../docs/adr/ADR-018%20Developer%20Experience%20Measurement%20Framework%20SPACE.md) for setup details.

#### Alerting

The dashboard supports alerting on degrading metrics:
- DevEx health score drops below 60
- NPS score drops below 40
- Friction incidents exceed 50 per month per 100 developers
- Cognitive load average exceeds 4.0
- Build success rate drops below 90%

Configure alerts in Grafana UI or via AlertManager rules.

---

### 2. Research Insights Dashboard

**File**: `research-insights-dashboard.json`  
**ConfigMap**: `platform/apps/prometheus/research-insights-dashboard.yaml`  
**Namespace**: monitoring

Comprehensive research insights visualization dashboard showing insight trends, categories, validation rates, and time-to-action metrics.

#### Panels

- **Overview Section**:
  - Total Research Insights: Overall count of captured insights
  - Validated Insights: Published insights count
  - Published (Last 7 Days): Recent publication rate
  - Published (Last 30 Days): Monthly publication rate
  - Total Categories: Category count
  - Total Tags: Tag count

- **Status & Priority Analysis**:
  - Insights by Status: Distribution pie chart (draft, published, archived)
  - Insights by Priority: Distribution pie chart (low, medium, high, critical)
  - Insights Status Over Time: Time series trend of status changes

- **Category Analytics**:
  - Insights by Category: Bar gauge showing count per category
  - Category Distribution: Donut chart of proportional distribution

- **Validation Metrics**:
  - Validation Rate by Category: Percentage of published insights per category
  - Time to Action (Hours): Average time from creation to publication

- **Tag Analytics**:
  - Top Tags by Usage: Bar gauge of most frequently used tags
  - Tag Usage Distribution: Donut chart of tag popularity

- **Trend Analysis**:
  - Published Insights Trend (7 Days): Weekly publication trend
  - Published Insights Trend (30 Days): Monthly publication trend

#### Key Metrics

```promql
# Total insights
research_insights_total

# Validated insights
research_insights_validated

# Insights by status
research_insights_by_status{status="published"}

# Insights by category
research_insights_by_category{category="User Experience"}

# Validation rate
research_insights_validation_rate{category="User Experience"}

# Time to action (in hours)
research_insights_time_to_action_seconds{category="User Experience"} / 3600

# Tag usage
research_tag_usage_count{tag="platform-adoption"}

# Recent publications
research_insights_published_last_7d
research_insights_published_last_30d
```

#### Variables

- **datasource**: Prometheus data source selector
- **category**: Filter by category (multi-select, with "All" option)

#### Thresholds

- **Published (7 Days)**:
  - 🔴 Red: 0 insights
  - 🟡 Yellow: 1-4 insights
  - 🟢 Green: ≥ 5 insights

- **Validation Rate**:
  - 🔴 Red: < 50%
  - 🟡 Yellow: 50-75%
  - 🟢 Green: ≥ 75%

- **Time to Action**:
  - 🟢 Green: < 48 hours
  - 🟡 Yellow: 48-168 hours (2-7 days)
  - 🟠 Orange: 168-336 hours (1-2 weeks)
  - 🔴 Red: > 336 hours (2+ weeks)

#### Implementation Notes

Requires:
1. Insights service running with Prometheus metrics enabled (`services/insights/`)
2. Prometheus scraping insights service `/metrics` endpoint
3. ServiceMonitor configured for metrics collection
4. Data being captured through the insights API

See [Insights Service README](../../../../services/insights/README.md) for setup details.

---

### 3. Kubernetes Cluster Health

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

### 4. Platform Components Health

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

### 5. DORA Metrics (Placeholder)

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

### 6. Application Metrics Template

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

### 7. Trivy Security Dashboard

**File**: `trivy-security-dashboard.json`  
**Purpose**: Container security scanning visibility

See [Trivy Dashboard README](README.md) in this directory for details.

---

### 8. VSM Flow Metrics Dashboard

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

### 9. Data Quality Dashboard

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

### 10. AI Observability Dashboard

**File**: `ai-observability.json`  
**ConfigMap**: Loaded via Grafana provisioning  
**Namespace**: monitoring

Comprehensive AI-powered observability dashboard showing anomaly detection, smart alerting, and system intelligence.

#### Panels

- **Active Anomalies Feed (Real-Time)**:
  - Active Anomalies Count: Current number of detected anomalies
  - Critical Anomalies: Critical severity anomalies requiring immediate attention
  - Active Alert Groups: Smart alert groups currently active
  - Mean Time to Detection: Average time to detect incidents
  - Real-Time Anomaly Feed: Live table of detected anomalies with details

- **Anomaly Detection Performance**:
  - Anomaly Detection Accuracy: Detection accuracy percentage (target >95%)
  - False Positive Rate: Current FP rate (target <5%)
  - ML Models Loaded: Number of active ML models
  - Anomaly Detection Processing Time: P50, P95, P99 latency percentiles
  - Anomalies by Severity Over Time: Trend analysis by severity level

- **Smart Alert Groups**:
  - Alert Grouping Efficiency: Total alert groups vs individual alerts
  - Alerts Suppressed: Number of alerts suppressed by suppression engine
  - Alert Fatigue Reduction: Percentage of alert noise reduced (target >50%)
  - Alerts Routed: Total alerts routed to channels
  - Alert Groups by Service: Distribution pie chart
  - Alerts by Source Over Time: Incoming alerts by source
  - Suppression Reasons: Why alerts were suppressed (pie chart)

- **Root Cause Analysis**:
  - Root Cause Analysis Success Rate: Percentage of successful RCA executions
  - RCA Executions: Total root cause analyses performed
  - RCA Status Distribution: Success vs failure rates

- **Historical Trends**:
  - Historical Anomaly Trends (7 Days): 7-day anomaly detection trends
  - Alert Reduction Rate Trend: Historical alert fatigue reduction
  - Anomaly Detection Latency Trend: Time to detection over 7 days

#### Key Metrics

```promql
# Anomaly detection metrics
anomaly_detection_total{severity, metric}
anomaly_detection_false_positive_rate
anomaly_detection_models_loaded
anomaly_detection_duration_seconds
anomaly_detection_rca_total{status}

# Smart alerting metrics
smart_alerting_grouped_total
smart_alerting_suppressed_total{reason}
smart_alerting_fatigue_reduction
smart_alerting_received_total{source}
smart_alerting_routed_total{channel}
```

#### Variables

- **severity**: Filter anomalies by severity (critical, high, medium, low)
- **metric**: Filter by specific metric type
- **alert_source**: Filter alerts by source (Prometheus, Grafana, DataHub, etc.)

#### Thresholds

- **Anomaly Detection Accuracy**:
  - 🔴 Red: < 85%
  - 🟠 Orange: 85-92%
  - 🟡 Yellow: 92-95%
  - 🟢 Green: ≥ 95%

- **False Positive Rate**:
  - 🟢 Green: < 3%
  - 🟡 Yellow: 3-5%
  - 🟠 Orange: 5-8%
  - 🔴 Red: > 8%

- **Alert Fatigue Reduction**:
  - 🔴 Red: < 30%
  - 🟡 Yellow: 30-50%
  - 🟢 Green: ≥ 50%

- **Mean Time to Detection**:
  - 🟢 Green: < 60 seconds
  - 🟡 Yellow: 60-120 seconds
  - 🟠 Orange: 120-180 seconds
  - 🔴 Red: > 180 seconds

#### Annotations

The dashboard includes automatic annotations for:
- **Critical Anomalies**: Red markers when critical anomalies are detected
- **Alert Groups**: Orange markers when new alert groups are created

#### Implementation Notes

Requires:
1. Anomaly detection service running (see `services/anomaly-detection/`)
2. Smart alerting service running (see `services/smart-alerting/`)
3. Prometheus scraping both services' `/metrics` endpoints
4. ServiceMonitors configured for metrics collection

#### Anomaly Timeline UI

In addition to the Grafana dashboard, an interactive HTML timeline is available at:
- **File**: `services/anomaly-detection/ui/timeline.html`
- **URL**: `http://anomaly-detection.local/timeline` (when deployed)

The timeline provides:
- Interactive anomaly visualization over time
- Correlated events (deployments, config changes)
- Incident markers
- Click-to-view details and root cause analysis
- Filtering by service, severity, type, and time range
- Auto-refresh every 30 seconds

See [Anomaly Detection Service README](../../../../services/anomaly-detection/README.md) and [Smart Alerting Service README](../../../../services/smart-alerting/README.md) for setup details.

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

