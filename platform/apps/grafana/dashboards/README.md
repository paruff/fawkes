# Trivy Grafana Dashboard

## Overview

This dashboard provides comprehensive visibility into container security scanning with Trivy across the Fawkes platform.

## Panels

### 1. Critical & High Vulnerabilities
- **Type**: Stat panel
- **Purpose**: Shows total count of CRITICAL and HIGH severity vulnerabilities
- **Alert Threshold**: Red if > 10, Yellow if > 5
- **Data Source**: Prometheus metrics from Jenkins and Harbor

### 2. Images Scanned Today
- **Type**: Stat panel
- **Purpose**: Number of container images scanned in the last 24 hours
- **Indicates**: Platform scanning activity level

### 3. Scan Success Rate
- **Type**: Gauge
- **Purpose**: Percentage of successful Trivy scans
- **Healthy Range**: > 95%
- **Alert Threshold**: < 80% indicates issues

### 4. Vulnerability Trends (7 Days)
- **Type**: Time series
- **Purpose**: Track vulnerability counts over time by severity
- **Use Case**: Identify if security posture is improving or degrading

### 5. Top 10 Vulnerable Images
- **Type**: Table
- **Purpose**: List images with most HIGH/CRITICAL vulnerabilities
- **Action**: Prioritize remediation efforts

### 6. Scan Activity by Source
- **Type**: Pie chart
- **Purpose**: Distribution of scans between Jenkins and Harbor
- **Expected**: Balanced distribution

### 7. Average Scan Duration
- **Type**: Stat panel
- **Purpose**: Track scan performance
- **Target**: < 60 seconds for typical images

### 8. Failed Scans (24h)
- **Type**: Stat panel
- **Purpose**: Count of failed scans
- **Alert Threshold**: Any failures should be investigated

## Metrics

The dashboard expects the following Prometheus metrics to be available:

```promql
# Vulnerability counts
trivy_vulnerabilities_total{severity="critical|high|medium|low"}

# Scan metrics
trivy_scan_total
trivy_scan_success_total
trivy_scan_failure_total
trivy_scan_duration_seconds

# Image tracking
trivy_scan_timestamp{image="..."}
```

## Installation

### Automatic (via Grafana ConfigMap)

1. The dashboard JSON is automatically loaded by Grafana via ConfigMap
2. It will appear in the "Security" folder
3. No manual import needed

### Manual Import

If needed, import manually:

1. Navigate to Grafana UI
2. Click "+" → "Import"
3. Upload `trivy-security-dashboard.json`
4. Select Prometheus data source
5. Click "Import"

## Prometheus Configuration

Ensure Prometheus is scraping Trivy metrics:

### Jenkins Pipeline Metrics

Trivy scan results should be exported to Prometheus via a pushgateway or exporter after each pipeline run.

### Harbor Metrics

Harbor exports Trivy scan results via ServiceMonitor. Ensure the following ServiceMonitor exists:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: harbor-trivy
  namespace: fawkes
spec:
  selector:
    matchLabels:
      component: trivy
  endpoints:
    - port: metrics
      interval: 30s
```

## Alerting

### Recommended Alerts

```yaml
# Alert on high vulnerability count
- alert: TrivyHighVulnerabilities
  expr: sum(trivy_vulnerabilities_total{severity=~"critical|high"}) > 50
  for: 5m
  annotations:
    summary: "High number of critical/high vulnerabilities detected"

# Alert on scan failures
- alert: TrivyScanFailures
  expr: rate(trivy_scan_failure_total[5m]) > 0.1
  for: 5m
  annotations:
    summary: "Trivy scans are failing"
```

## Troubleshooting

### No Data Displayed

1. Check Prometheus is scraping metrics:
   ```bash
   kubectl get servicemonitor -n fawkes
   ```

2. Verify Trivy is exporting metrics:
   ```bash
   kubectl logs -n fawkes -l component=trivy
   ```

3. Check Prometheus targets:
   - Navigate to Prometheus UI
   - Status → Targets
   - Look for Harbor and Jenkins endpoints

### Incorrect Values

1. Verify metric labels match dashboard queries
2. Check time range selection
3. Ensure namespace variable is set correctly

## Related Documentation

- [Trivy Integration](../trivy/README.md)
- [Jenkins Security Scanning](../jenkins/README.md)
- [Harbor Deployment](../harbor/README.md)
- [Prometheus Configuration](../prometheus/README.md)
