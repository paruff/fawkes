# Insights Service Deployment

This directory contains Kubernetes manifests for deploying and monitoring the Insights service in the Fawkes platform.

## Overview

The Insights service provides a database and tracking system for capturing, organizing, and tracking research insights with tagging, categorization, and searchability. It exposes Prometheus metrics for visualization in Grafana dashboards.

## Components

### ServiceMonitor

**File**: `servicemonitor.yaml`

Configures Prometheus to scrape metrics from the Insights service.

- **Metrics Endpoint**: `/metrics`
- **Scrape Interval**: 30 seconds
- **Namespace**: `fawkes-local`

## Deployment

### Prerequisites

1. Insights service running (see `services/insights/`)
2. Prometheus Operator installed
3. Grafana with dashboard provisioning enabled

### Deploy ServiceMonitor

```bash
kubectl apply -f platform/apps/insights/servicemonitor.yaml
```

### Verify Metrics Collection

1. Check ServiceMonitor is created:

   ```bash
   kubectl get servicemonitor -n monitoring insights-metrics
   ```

2. Verify Prometheus is scraping:

   ```bash
   kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
   # Navigate to http://localhost:9090/targets
   # Look for "insights-metrics" target
   ```

3. Query metrics in Prometheus:
   ```promql
   research_insights_total
   research_insights_by_status
   research_insights_validation_rate
   ```

## Metrics Exposed

The Insights service exposes the following Prometheus metrics:

### Core Metrics

- `research_insights_total`: Total number of research insights
- `research_insights_validated`: Number of validated (published) insights
- `research_tags_total`: Total number of tags
- `research_categories_total`: Total number of categories

### Status & Priority Metrics

- `research_insights_by_status{status}`: Insights count by status (draft, published, archived)
- `research_insights_by_priority{priority}`: Insights count by priority (low, medium, high, critical)

### Category Metrics

- `research_insights_by_category{category}`: Insights count by category
- `research_insights_validation_rate{category}`: Validation rate percentage per category
- `research_insights_time_to_action_seconds{category}`: Average time from creation to publication

### Tag Metrics

- `research_tag_usage_count{tag}`: Usage count for each tag

### Time-Based Metrics

- `research_insights_published_last_7d`: Insights published in last 7 days
- `research_insights_published_last_30d`: Insights published in last 30 days

## Grafana Dashboard

The Research Insights Dashboard provides comprehensive visualization of these metrics:

- **File**: `platform/apps/grafana/dashboards/research-insights-dashboard.json`
- **ConfigMap**: `platform/apps/prometheus/research-insights-dashboard.yaml`

Access the dashboard in Grafana at:

```
http://grafana.127.0.0.1.nip.io/d/research-insights
```

## Troubleshooting

### Metrics Not Appearing

1. **Check ServiceMonitor**:

   ```bash
   kubectl get servicemonitor -n monitoring
   kubectl describe servicemonitor -n monitoring insights-metrics
   ```

2. **Verify Service is Running**:

   ```bash
   kubectl get pods -n fawkes-local -l app=insights
   kubectl logs -n fawkes-local -l app=insights
   ```

3. **Test Metrics Endpoint**:

   ```bash
   kubectl port-forward -n fawkes-local svc/insights-metrics 8000:8000
   curl http://localhost:8000/metrics
   ```

4. **Check Prometheus Targets**:
   ```bash
   # Port forward to Prometheus
   kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
   # Navigate to http://localhost:9090/targets
   ```

### Dashboard Shows No Data

1. **Verify metrics exist in Prometheus**:

   - Navigate to Prometheus UI
   - Query: `research_insights_total`
   - Should return a value

2. **Check dashboard time range**:

   - Ensure time range includes periods when insights were created

3. **Verify data source**:
   - Check Grafana data source configuration
   - Should point to Prometheus

## Integration with Backstage

To make the dashboard accessible from Backstage:

1. Add dashboard link to catalog entity metadata
2. Configure proxy endpoint in Backstage
3. Add dashboard widget to component page

See [Backstage Integration Guide](../../../docs/how-to/backstage-integration.md) for details.

## Related Documentation

- [Insights Service README](../../../services/insights/README.md)
- [Grafana Dashboards README](../grafana/dashboards/README.md)
- [Prometheus Configuration](../prometheus/README.md)
- [Observability Architecture](../../../docs/architecture.md#observability)

## Support

For issues with metrics or monitoring:

1. Check the troubleshooting section above
2. Review service logs
3. Consult the [platform documentation](../../../docs/)
4. Open an issue in the GitHub repository
