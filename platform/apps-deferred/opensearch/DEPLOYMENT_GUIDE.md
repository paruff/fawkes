# Logging Stack Deployment Guide

## Overview

The Fawkes platform uses **OpenTelemetry Collector** for unified log collection and **OpenSearch** for centralized log storage and analysis. This guide covers the deployment and configuration of the complete logging stack.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────┐
│                     Application Pods                             │
│  ├─ Container logs (stdout/stderr)                              │
│  ├─ Structured JSON logs with trace correlation                 │
│  └─ /var/log/containers/*.log                                   │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│         OpenTelemetry Collector (DaemonSet)                      │
│  ├─ Filelog Receiver: /var/log/containers/*.log                │
│  ├─ Processors:                                                 │
│  │   ├─ k8sattributes: Kubernetes metadata enrichment          │
│  │   ├─ batch: Efficient batching                              │
│  │   ├─ memory_limiter: Backpressure handling                  │
│  │   └─ transform: Trace correlation                           │
│  └─ OpenSearch Exporter: OTLP → OpenSearch                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                  OpenSearch Cluster                              │
│  ├─ Index: otel-logs-YYYY.MM.DD                                │
│  ├─ Index: fawkes-logs-YYYY.MM.DD                              │
│  ├─ ISM Policy: 30-day retention (hot → warm → delete)        │
│  └─ Index Templates: Kubernetes field mappings                  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              OpenSearch Dashboards                               │
│  ├─ Log visualization and search                               │
│  ├─ Trace correlation via trace_id                             │
│  └─ Kubernetes context filtering                               │
└─────────────────────────────────────────────────────────────────┘
```

## Components

### 1. OpenTelemetry Collector (Already Deployed)

**Status**: ✅ Deployed in `monitoring` namespace
**Configuration**: `platform/apps/opentelemetry/otel-collector-application.yaml`

**Key Features**:

- DaemonSet deployment (runs on every node)
- Filelog receiver for container log collection
- Kubernetes metadata enrichment (pod name, namespace, container, etc.)
- Trace correlation support (traceId, spanId)
- OpenSearch exporter with retry and queuing (5+ minute buffer)
- Memory limiter for backpressure handling

**Log Collection**:

```yaml
filelog:
  include:
    - /var/log/containers/*.log
  exclude:
    - /var/log/containers/*otel-collector*.log
```

**Kubernetes Enrichment**:

- `k8s.namespace.name`
- `k8s.pod.name`
- `k8s.pod.uid`
- `k8s.container.name`
- `k8s.node.name`
- `k8s.deployment.name`
- `container.id`
- `container.image.name`

**Trace Correlation**:

- Extracts `trace_id` and `span_id` from structured JSON logs
- Preserves W3C trace context for correlation with Grafana Tempo

### 2. OpenSearch Cluster

**Status**: Ready to deploy
**Configuration**: `platform/apps/opensearch/opensearch-application.yaml`

**Deployment Details**:

- **Chart**: opensearch-project.github.io/helm-charts/opensearch v2.17.0
- **Version**: OpenSearch 2.11.1
- **Replicas**: 1 (MVP - single node)
- **Storage**: 50Gi persistent volume
- **Resources**: 500m-1000m CPU, 2Gi memory
- **Security**: Disabled for MVP (enable for production)

**Configuration**:

```yaml
clusterName: opensearch-cluster
replicas: 1
minimumMasterNodes: 1
roles: [master, ingest, data, remote_cluster_client]
```

**ArgoCD Sync Wave**: `1` (deploys before collectors)

### 3. OpenSearch Dashboards

**Status**: Ready to deploy
**Configuration**: `platform/apps/opensearch/opensearch-dashboards-application.yaml`

**Deployment Details**:

- **Chart**: opensearch-project.github.io/helm-charts/opensearch-dashboards v2.16.0
- **Version**: 2.11.1
- **Resources**: 200m-500m CPU, 512Mi-1Gi memory
- **Ingress**: opensearch-dashboards.127.0.0.1.nip.io

**ArgoCD Sync Wave**: `2` (deploys after OpenSearch)

### 4. Index State Management (ISM) Policy

**Status**: Ready to deploy
**Configuration**: `platform/apps/opensearch/ism-retention-policy.yaml`

**30-Day Retention Policy**:

```yaml
States:
  hot (0-7 days):
    - Active indexing and search
    - Rollover at 1 day or 10GB
  warm (7-30 days):
    - Reduce replicas to 0
    - Force merge to 1 segment
    - Read-only access
  delete (30+ days):
    - Automatic deletion
```

**Applied to Indices**:

- `fawkes-logs-*`
- `fawkes-host-logs-*`
- `otel-logs-*`

**ArgoCD Sync Wave**: `3` (PostSync hook)

### 5. Index Patterns and Templates

**Status**: Ready to deploy
**Configuration**: `platform/apps/opensearch/configure-index-patterns.yaml`

**Index Templates**:

**Application Logs** (`fawkes-logs-*`):

```json
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "index.refresh_interval": "30s",
    "index.codec": "best_compression"
  },
  "mappings": {
    "@timestamp": "date",
    "message": "text",
    "k8s.namespace.name": "keyword",
    "k8s.pod.name": "keyword",
    "k8s.container.name": "keyword",
    "traceId": "keyword",
    "spanId": "keyword"
  }
}
```

**Host Logs** (`fawkes-host-logs-*`):

- System logs from Kubelet
- Node-level metrics

**ArgoCD Sync Wave**: `3` (PostSync hook)

## Deployment

### Prerequisites

1. Kubernetes cluster with ArgoCD installed
2. OpenTelemetry Collector already deployed (see `platform/apps/opentelemetry/`)
3. `monitoring` and `logging` namespaces (created automatically)

### Deploy OpenSearch and Logging Stack

All components are deployed via ArgoCD using GitOps:

```bash
# Apply OpenSearch Application (sync wave 1)
kubectl apply -f platform/apps/opensearch/opensearch-application.yaml

# Apply OpenSearch Dashboards Application (sync wave 2)
kubectl apply -f platform/apps/opensearch/opensearch-dashboards-application.yaml

# Apply ISM Policy Job (sync wave 3, PostSync hook)
kubectl apply -f platform/apps/opensearch/ism-retention-policy.yaml

# Apply Index Configuration Job (sync wave 3, PostSync hook)
kubectl apply -f platform/apps/opensearch/configure-index-patterns.yaml
```

**ArgoCD will automatically**:

1. Deploy OpenSearch cluster
2. Deploy OpenSearch Dashboards
3. Wait for OpenSearch to be ready
4. Apply ISM retention policy
5. Configure index patterns

### Verify Deployment

```bash
# Check ArgoCD Application status
kubectl get application -n fawkes opensearch opensearch-dashboards

# Check OpenSearch cluster
kubectl get pods -n logging -l app=opensearch-cluster-master
kubectl get svc -n logging opensearch-cluster-master

# Check OpenSearch Dashboards
kubectl get pods -n logging -l app=opensearch-dashboards
kubectl get ingress -n logging

# Check OpenTelemetry Collector (already deployed)
kubectl get daemonset -n monitoring -l app.kubernetes.io/name=opentelemetry-collector

# Verify logs are flowing
kubectl exec -n logging opensearch-cluster-master-0 -- curl -s http://localhost:9200/_cat/indices?v

# Check ISM policy
kubectl exec -n logging opensearch-cluster-master-0 -- curl -s http://localhost:9200/_plugins/_ism/policies
```

## Accessing Logs

### OpenSearch Dashboards UI

1. **Access URL**: http://opensearch-dashboards.127.0.0.1.nip.io
2. **Create Index Pattern**:
   - Go to Stack Management → Index Patterns
   - Create pattern: `otel-logs-*` or `fawkes-logs-*`
   - Select time field: `@timestamp`
3. **Discover Logs**:
   - Go to Discover
   - Filter by `k8s.namespace.name`, `k8s.pod.name`, etc.
   - Correlate with traces via `trace_id`

### Query via API

```bash
# Port forward to OpenSearch
kubectl port-forward -n logging svc/opensearch-cluster-master 9200:9200

# Search recent logs
curl -X GET "http://localhost:9200/otel-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "bool": {
        "must": [
          { "match": { "k8s.namespace.name": "default" }}
        ],
        "filter": {
          "range": {
            "@timestamp": { "gte": "now-1h" }
          }
        }
      }
    },
    "size": 10,
    "sort": [{ "@timestamp": "desc" }]
  }'
```

### Grafana Integration

OpenSearch is already configured as a datasource in Grafana (see `platform/apps/grafana/helm-release.yml`):

```yaml
datasources:
  - name: OpenSearch
    type: opensearch
    uid: opensearch
    url: http://opensearch-cluster-master.logging.svc.cluster.local:9200
    database: otel-logs*
    jsonData:
      timeField: "@timestamp"
      derivedFields:
        - name: TraceID
          matcherRegex: "trace_id=([a-fA-F0-9]{32})"
          datasourceUid: tempo
```

**View logs in Grafana**:

1. Go to Explore
2. Select OpenSearch datasource
3. Query logs with trace correlation to Tempo

## Log Correlation

### Trace-to-Logs Correlation

Applications instrumented with OpenTelemetry automatically include trace context in logs:

```json
{
  "@timestamp": "2024-12-15T12:00:00.000Z",
  "message": "Processing request",
  "k8s.namespace.name": "default",
  "k8s.pod.name": "myapp-xyz",
  "trace_id": "a1b2c3d4e5f6789012345678901234",
  "span_id": "1234567890abcdef",
  "level": "INFO"
}
```

**In Grafana Tempo**, click "Logs for this span" to jump directly to correlated logs in OpenSearch.

**In OpenSearch Dashboards**, search by `trace_id` to find all logs for a specific request.

## Troubleshooting

### No Logs Appearing in OpenSearch

1. **Check OpenTelemetry Collector**:

```bash
# View collector logs
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector --tail=100

# Check collector health
kubectl exec -n monitoring <otel-pod> -- wget -qO- http://localhost:13133
```

2. **Check OpenSearch is Ready**:

```bash
kubectl exec -n logging opensearch-cluster-master-0 -- curl http://localhost:9200/_cluster/health
```

3. **Verify Log Pipeline**:

```bash
# Check if logs are being received by OpenSearch
kubectl exec -n logging opensearch-cluster-master-0 -- curl -s "http://localhost:9200/_cat/indices?v"
```

### High Memory Usage in OTel Collector

The collector has memory_limiter configured for backpressure:

- Limit: 800MiB
- Spike limit: 200MiB

If hitting limits, check:

```bash
kubectl top pods -n monitoring -l app.kubernetes.io/name=opentelemetry-collector
```

Adjust resources in `platform/apps/opentelemetry/otel-collector-application.yaml`.

### Index Retention Not Working

Check ISM policy status:

```bash
kubectl exec -n logging opensearch-cluster-master-0 -- \
  curl -s "http://localhost:9200/_plugins/_ism/policies/fawkes-log-retention-policy"
```

View index states:

```bash
kubectl exec -n logging opensearch-cluster-master-0 -- \
  curl -s "http://localhost:9200/_plugins/_ism/explain/fawkes-logs-*?pretty"
```

## Testing

### BDD Acceptance Tests

Run the centralized logging BDD tests:

```bash
# Run all logging tests
behave tests/bdd/features/centralized-logging.feature --tags=@local

# Run specific scenarios
behave tests/bdd/features/centralized-logging.feature --tags=@log-forwarding
behave tests/bdd/features/centralized-logging.feature --tags=@kubernetes-enrichment
behave tests/bdd/features/centralized-logging.feature --tags=@trace-correlation
```

### Manual Testing

1. **Deploy Test Application**:

```bash
kubectl apply -f platform/apps/opentelemetry/sample-app/deployment.yaml
```

2. **Generate Logs**:

```bash
kubectl port-forward -n otel-demo svc/otel-sample-app 8080:80
curl http://localhost:8080/hello/World
curl http://localhost:8080/work
```

3. **Verify in OpenSearch**:

```bash
# Search for test app logs
curl -X GET "http://localhost:9200/otel-logs-*/_search?pretty" \
  -H 'Content-Type: application/json' \
  -d '{
    "query": {
      "match": { "k8s.pod.name": "otel-sample-app" }
    },
    "size": 5
  }'
```

## Production Considerations

### Security

**For production, enable OpenSearch security**:

```yaml
config:
  opensearch.yml: |
    plugins.security.disabled: false
    plugins.security.ssl.http.enabled: true
    plugins.security.ssl.transport.enabled: true
```

Configure:

- TLS certificates
- Authentication (LDAP/SAML/OIDC)
- Role-based access control (RBAC)
- Audit logging

### High Availability

**Multi-node OpenSearch cluster**:

```yaml
replicas: 3
minimumMasterNodes: 2
roles:
  master: [master, ingest]
  data: [data]
  client: [ingest]
```

**OpenTelemetry Collector scaling**:

- DaemonSet handles horizontal scaling automatically
- Increase resources per pod if needed

### Performance Tuning

**OpenSearch**:

- Increase JVM heap: `-Xmx4g -Xms4g`
- More shards for high volume: `number_of_shards: 5`
- Disable replicas in warm state: `number_of_replicas: 0`

**OTel Collector**:

- Increase batch size: `send_batch_size: 2000`
- Larger queue: `queue_size: 10000`
- More memory: `limits.memory: 2Gi`

### Monitoring

**OpenSearch Metrics**:

- Cluster health
- Index size and count
- Query latency
- JVM heap usage

**OTel Collector Metrics** (already exposed to Prometheus):

- `otelcol_receiver_accepted_log_records`
- `otelcol_exporter_sent_log_records`
- `otelcol_exporter_send_failed_log_records`
- `otelcol_processor_batch_batch_send_size`

Create alerts for:

- High log ingestion failures
- OpenSearch cluster health != green
- Disk space < 15%
- OTel collector memory > 80%

## Related Documentation

- [Architecture: Observability Stack](../../docs/architecture.md#4-observability-stack)
- [ADR-011: Centralized Log Management](../../docs/adr/ADR-011%20Centralized%20Log%20Management.md)
- [ADR-013: Distributed Tracing](../../docs/adr/ADR-013%20Distributed%20Tracing.md)
- [OpenTelemetry Collector README](../opentelemetry/README.md)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/collector/)
- [OpenSearch Documentation](https://opensearch.org/docs/latest/)
- [BDD Test: Centralized Logging](../../tests/bdd/features/centralized-logging.feature)

## Support

For issues or questions:

1. Check logs: `kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector`
2. Verify health: `kubectl exec -n monitoring <pod> -- wget -qO- http://localhost:13133`
3. Review [Troubleshooting](#troubleshooting) section
4. Open GitHub issue with logs and error details
