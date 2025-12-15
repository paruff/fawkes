# Grafana - Visualization and Dashboards

## Purpose

Grafana provides powerful visualization and analytics for metrics, logs, and traces. It serves as the primary UI for observability, displaying data from Prometheus, OpenSearch, and Tempo.

## Key Features

- **Multi-Source**: Query Prometheus, OpenSearch, Tempo simultaneously
- **Dashboards**: Pre-built and custom dashboards
- **Alerting**: Native alerting with multiple notification channels
- **Variables**: Dynamic dashboard filtering
- **Annotations**: Mark events on graphs
- **Explore**: Ad-hoc queries and investigation

## Quick Start

### Accessing Grafana

Local development:
```bash
# Access UI
http://grafana.127.0.0.1.nip.io
```

Default credentials:
- Username: `admin`
- Password: `fawkesidp`

## Data Sources

### Prometheus

Metrics from all platform and application services:

```yaml
# Configured data source
name: Prometheus
type: prometheus
url: http://prometheus.monitoring.svc:9090
access: proxy
isDefault: true
```

### OpenSearch

Centralized logs:

```yaml
name: OpenSearch
type: elasticsearch
url: http://opensearch.logging.svc:9200
database: "[fawkes-]YYYY.MM.DD"
```

### Tempo

Distributed traces:

```yaml
name: Tempo
type: tempo
url: http://tempo.monitoring.svc:3100
```

## Pre-Built Dashboards

### Kubernetes Cluster Health

**Location**: Dashboards → Kubernetes Cluster Health

Comprehensive monitoring of Kubernetes cluster infrastructure:

- **Cluster Overview**: Total nodes, ready nodes, running pods, namespaces
- **Node Resources**: CPU and memory usage per node
- **Pod Status**: Distribution and restart tracking
- **Resource Utilization**: CPU and memory usage by namespace
- **Storage**: PersistentVolume status and disk usage by node

### Platform Components Health

**Location**: Dashboards → Platform Components Health

Monitor health and performance of Fawkes platform components:

- **Component Status**: ArgoCD, Jenkins, Backstage, Harbor, PostgreSQL, OpenTelemetry
- **ArgoCD Applications**: Sync status, health status, out-of-sync count
- **Jenkins Metrics**: Job success rate, executor usage, queue length
- **Container Registry**: Harbor projects, repositories, storage usage, scan rate
- **Observability Stack**: Prometheus targets, TSDB size, trace ingestion
- **Component Response Times**: P95 latency for platform services

### DORA Metrics (Placeholder)

**Location**: Dashboards → DORA Metrics

Track the four key DORA metrics (requires metrics collection setup):

- **Deployment Frequency**: Deploys per day/week (Elite: On-demand, multiple per day)
- **Lead Time for Changes**: Commit to production time (Elite: < 1 hour)
- **Change Failure Rate**: Failed deployments percentage (Elite: 0-15%)
- **Mean Time to Restore**: Incident to restore time (Elite: < 1 hour)

**Note**: This is a placeholder dashboard. Configure the DORA metrics collector following the [DORA Metrics Implementation Playbook](../../../docs/playbooks/dora-metrics-implementation.md) to populate data.

### Application Metrics Template

**Location**: Dashboards → Application Metrics Template

Template dashboard based on the Golden Signals approach for monitoring applications:

- **Golden Signals Overview**: Request rate, error rate, P95 latency, CPU usage
- **Traffic**: Request rate over time, by method and status
- **Latency**: Response time percentiles (P50, P95, P99), by endpoint
- **Errors**: Error rate by status code, percentage over time
- **Saturation**: CPU usage, memory usage, pod count
- **Custom Metrics**: Placeholder panels for application-specific metrics

**How to Use**:
1. Clone this dashboard and rename it for your application
2. Update the `service` and `namespace` variables
3. Customize queries to match your application's metric names
4. Add application-specific panels as needed

### Golden Signals Dashboard

Monitor the four golden signals for all services:

- **Latency**: P50, P95, P99 request duration
- **Traffic**: Request rate per service
- **Errors**: Error rate and 5xx distribution
- **Saturation**: CPU and memory utilization

Access: Dashboards → Golden Signals

## Creating Custom Dashboards

### Example: Application Dashboard

```json
{
  "dashboard": {
    "title": "My Service Dashboard",
    "tags": ["application"],
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{service=\"my-service\"}[5m])",
            "legendFormat": "{{method}} {{status}}"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "rate(http_requests_total{service=\"my-service\",status=~\"5..\"}[5m])",
            "legendFormat": "Errors"
          }
        ]
      }
    ]
  }
}
```

### Import Dashboard

```bash
# Via UI
Dashboards → Import → Upload JSON file

# Via API
curl -X POST http://grafana.127.0.0.1.nip.io/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dashboard.json \
  --user admin:fawkesidp
```

## Alerting

### Create Alert

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-alert-rules
data:
  alert-rules.yaml: |
    groups:
      - name: application_alerts
        interval: 1m
        rules:
          - alert: HighErrorRate
            expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
            for: 5m
            annotations:
              summary: "High error rate on {{ $labels.service }}"
              description: "Error rate is {{ $value | humanizePercentage }}"
```

### Notification Channels

Configure Slack notifications:

```yaml
apiVersion: 1
notifiers:
  - name: slack-alerts
    type: slack
    uid: slack-alerts
    org_id: 1
    settings:
      url: https://hooks.slack.com/services/YOUR/WEBHOOK/URL
      recipient: '#alerts'
      username: Grafana
```

## Variables

Create dynamic dashboards with variables:

```yaml
# Namespace variable
name: namespace
type: query
query: label_values(kube_pod_info, namespace)
refresh: on_time_range_change

# Service variable
name: service
type: query
query: label_values(http_requests_total{namespace="$namespace"}, service)
refresh: on_time_range_change
```

Use in queries:
```promql
rate(http_requests_total{namespace="$namespace", service="$service"}[5m])
```

## Explore Mode

Ad-hoc querying for troubleshooting:

1. Navigate to Explore
2. Select data source (Prometheus/OpenSearch/Tempo)
3. Build query
4. Add to dashboard or investigate further

### Example Queries

**Find slow requests:**
```promql
histogram_quantile(0.99, 
  rate(http_request_duration_seconds_bucket[5m])
) > 1
```

**Search logs:**
```
namespace:"fawkes" AND level:"ERROR" AND service:"myapp"
```

**Trace lookup:**
```
{service.name="myapp" && http.status_code>=500}
```

## Provisioning

Dashboards are provisioned via ConfigMaps:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-dashboard-myapp
  labels:
    grafana_dashboard: "1"
data:
  myapp.json: |
    {
      "dashboard": { ... }
    }
```

## Troubleshooting

### Dashboard Not Loading

```bash
# Check Grafana logs
kubectl logs -n monitoring deployment/grafana -f

# Check data source connectivity
kubectl exec -n monitoring deployment/grafana -- \
  curl http://prometheus.monitoring.svc:9090/-/healthy
```

### Missing Metrics

1. Verify ServiceMonitor exists
2. Check Prometheus targets: http://prometheus.127.0.0.1.nip.io/targets
3. Verify application exposes /metrics endpoint

## Related Documentation

- [Grafana Documentation](https://grafana.com/docs/grafana/latest/)
- [Dashboard Best Practices](https://grafana.com/docs/grafana/latest/best-practices/)
- [ADR-012: Metrics Monitoring](../../../docs/adr/ADR-012-metrics-monitoring.md)
