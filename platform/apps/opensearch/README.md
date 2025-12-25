# OpenSearch - Log Aggregation and Search

## Purpose

OpenSearch provides centralized log storage and full-text search capabilities for all platform and application logs collected by **OpenTelemetry Collector**.

## Deployment Status

✅ **Ready to Deploy** - ArgoCD Applications configured and ready

## Key Features

- **Full-Text Search**: Fast log search with Lucene
- **Index Management**: ISM for 30-day log retention
- **Dashboards**: Kibana-compatible visualizations
- **Trace Correlation**: Integration with Grafana Tempo via trace_id
- **Kubernetes Context**: Enriched with pod, namespace, container metadata
- **Security**: RBAC and encryption (configurable)

## Architecture

```text
OpenTelemetry Collector (DaemonSet)
    ↓ filelog receiver + k8sattributes
    ↓ OpenSearch exporter
OpenSearch Cluster (StatefulSet)
    ↓ Index patterns: otel-logs-*, fawkes-logs-*
    ↓ ISM Policy: 30-day retention
OpenSearch Dashboards
    ↓ Visualization & Search
Grafana Integration
    ↓ Trace-to-Logs Correlation
```

## Quick Start

### Deploy via ArgoCD

```bash
# Deploy OpenSearch cluster
kubectl apply -f platform/apps/opensearch/opensearch-application.yaml

# Deploy OpenSearch Dashboards
kubectl apply -f platform/apps/opensearch/opensearch-dashboards-application.yaml

# ISM policy and index templates are applied automatically via PostSync hooks
```

### Verify Deployment

```bash
# Run validation script
./platform/apps/opensearch/validate-logging-stack.sh

# Check ArgoCD Applications
kubectl get application -n fawkes opensearch opensearch-dashboards

# Check pods
kubectl get pods -n logging
```

### Accessing OpenSearch

```bash
# API (port-forward)
kubectl port-forward -n logging svc/opensearch-cluster-master 9200:9200
curl http://localhost:9200

# Dashboards
# http://opensearch-dashboards.127.0.0.1.nip.io
kubectl port-forward -n logging svc/opensearch-dashboards 5601:5601
# Open http://localhost:5601
```

## Log Retention Policy

Automatic 30-day retention via Index State Management (ISM):
- **Hot** (0-7 days): Active indexing and search, rollover at 1d or 10GB
- **Warm** (7-30 days): Reduce replicas, force merge, read-only
- **Delete** (30+ days): Automatic deletion

Applied to: `otel-logs-*`, `fawkes-logs-*`, `fawkes-host-logs-*`

## Index Structure

```text
otel-logs-YYYY.MM.DD      OpenTelemetry logs from Collector
fawkes-logs-YYYY.MM.DD    Application logs (Fluent Bit format)
fawkes-host-logs-YYYY.MM.DD  Host/system logs
```

## Integration with OpenTelemetry

Logs are collected by **OpenTelemetry Collector** (not Fluent Bit):
- DaemonSet on every node
- Filelog receiver: `/var/log/containers/*.log`
- Kubernetes metadata enrichment
- Trace correlation (trace_id, span_id)
- Direct export to OpenSearch via opensearch exporter

See: `platform/apps/opentelemetry/otel-collector-application.yaml`

## Searching Logs

### Query DSL

Search logs with Kubernetes context and trace correlation:

```json
{
  "query": {
    "bool": {
      "must": [
        { "match": { "k8s.namespace.name": "default" }},
        { "match": { "severityText": "ERROR" }}
      ],
      "filter": {
        "range": {
          "@timestamp": {
            "gte": "now-1h"
          }
        }
      }
    }
  }
}
```

### Query by Trace ID

Correlate logs with distributed traces:

```bash
curl -X GET "http://localhost:9200/otel-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": { "trace_id": "a1b2c3d4e5f6789012345678901234" }
    }
  }'
```

### Simple Query
```bash
# Search for errors in the last hour
curl -X GET "http://localhost:9200/otel-logs-*/_search?q=severityText:ERROR&size=10"

# Search by namespace
curl -X GET "http://localhost:9200/otel-logs-*/_search?q=k8s.namespace.name:default"
```

## Configuration Files

- `opensearch-application.yaml` - ArgoCD Application for OpenSearch cluster
- `opensearch-dashboards-application.yaml` - ArgoCD Application for Dashboards
- `ism-retention-policy.yaml` - 30-day retention policy via ISM
- `configure-index-patterns.yaml` - Index templates and patterns
- `opensearch-values-mvp.yaml` - Helm values (reference)
- `opensearch-dashboard-values-mvp.yaml` - Dashboards Helm values (reference)
- `index-template.yaml` - Index templates (legacy)
- `DEPLOYMENT_GUIDE.md` - Comprehensive deployment guide
- `validate-logging-stack.sh` - Validation script

## Testing

### Validation Script

```bash
./platform/apps/opensearch/validate-logging-stack.sh
```

### BDD Tests

```bash
behave tests/bdd/features/centralized-logging.feature --tags=@local
```

## Troubleshooting

### No logs appearing

1. Check OpenTelemetry Collector:
   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector
   ```

2. Check OpenSearch cluster health:
   ```bash
   kubectl exec -n logging opensearch-cluster-master-0 -- \
     curl http://localhost:9200/_cluster/health
   ```

3. Verify indices exist:
   ```bash
   kubectl exec -n logging opensearch-cluster-master-0 -- \
     curl http://localhost:9200/_cat/indices?v
   ```

### High disk usage

Check ISM policy is working:
```bash
kubectl exec -n logging opensearch-cluster-master-0 -- \
  curl http://localhost:9200/_plugins/_ism/policies/fawkes-log-retention-policy
```

## Related Documentation

- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Complete deployment documentation
- [OpenTelemetry Collector](../opentelemetry/README.md) - Log collection configuration
- [ADR-011: Centralized Log Management](../../../docs/adr/ADR-011%20Centralized%20Log%20Management.md)
- [Architecture: Observability Stack](../../../docs/architecture.md#4-observability-stack)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [BDD Test: Centralized Logging](../../../tests/bdd/features/centralized-logging.feature)
