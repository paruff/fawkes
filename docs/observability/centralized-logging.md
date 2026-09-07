# Centralized Log Management with OpenTelemetry

## Overview

Fawkes implements centralized, structured logging for all Kubernetes workloads using OpenTelemetry Collector and OTLP. This enables reliable correlation of log events with traces and metrics, accelerating Mean Time to Resolution (MTTR) for application and platform incidents.

**Reference**: See [ADR-035 Log Storage Migration from OpenSearch to Loki](../adr/ADR-035%20Log%20Storage%20Migration%20from%20OpenSearch%20to%20Loki.md) for the current architecture, and [ADR-011 Centralized Log Management](../adr/ADR-011%20Centralized%20Log%20Management.md) (superseded) for the original decision.

## Architecture

```text
┌────────────────────────────────────────────────────────────────┐
│  Kubernetes Cluster                                            │
│                                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│  │ Application  │  │ Application  │  │ Platform     │        │
│  │ Pod          │  │ Pod          │  │ Service Pod  │        │
│  │              │  │              │  │              │        │
│  │ stdout/stderr│  │ stdout/stderr│  │ stdout/stderr│        │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘        │
│         │                  │                  │                 │
│         ▼                  ▼                  ▼                 │
│  ┌──────────────────────────────────────────────────────┐     │
│  │ /var/log/containers/*.log                            │     │
│  └──────────────────────────────────────────────────────┘     │
│         │                                                       │
│         ▼                                                       │
│  ┌─────────────────────────────────────────────────────┐      │
│  │ OpenTelemetry Collector DaemonSet                   │      │
│  │ - filelog receiver: Tail container logs             │      │
│  │ - k8sattributes: Add Kubernetes metadata            │      │
│  │ - otlphttp/loki exporter: Send to Loki              │      │
│  │ - memory_limiter: Buffer during outages             │      │
│  └───────────────────┬─────────────────────────────────┘      │
│                      │ OTLP/HTTP                                │
└──────────────────────┼──────────────────────────────────────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────────────────────┐
│  Loki                                                             │
│  - Centralized log storage (single-binary MVP deployment)        │
│  - Queried via Grafana Explore (LogQL)                            │
└──────────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Log Forwarding

The OpenTelemetry Collector Agent runs as a DaemonSet on every node and collects logs from all containers:

- **Source**: `/var/log/containers/*.log`
- **Format**: Kubernetes container log format (CRI/Docker JSON)
- **Receiver**: `filelog` receiver with custom operators

### 2. Kubernetes Context Enrichment

Every log record is enriched with Kubernetes metadata via the `k8sattributes` processor:

| Attribute             | Description                                    |
| --------------------- | ---------------------------------------------- |
| `k8s.pod.name`        | Pod name                                       |
| `k8s.namespace.name`  | Namespace name                                 |
| `k8s.container.name`  | Container name                                 |
| `k8s.deployment.name` | Deployment name (if applicable)                |
| `k8s.node.name`       | Node where pod is running                      |
| `cluster`             | Cluster identifier                             |
| `environment`         | Environment (development, staging, production) |

Loki's OTLP ingestion endpoint automatically promotes a curated subset of
these resource attributes to indexed stream labels (`k8s.namespace.name`,
`k8s.pod.name`, `k8s.container.name`, `k8s.deployment.name` among them,
sanitized to `k8s_namespace_name` etc. for LogQL); everything else stays as
unindexed structured metadata, searchable but not part of the label index.

### 3. Trace Correlation

Logs are automatically correlated with traces when applications use OpenTelemetry instrumentation:

- **traceId**: 32-character hexadecimal trace identifier
- **spanId**: 16-character hexadecimal span identifier

This enables seamless navigation from logs to traces in observability tools.

### 4. Failure Handling

The collector is configured for resilience during backend unavailability:

- **Memory Limiter**: 800MiB limit with 200MiB spike limit
- **Batch Processor**: Queue-based batching for efficient export
- **Retry on Failure**: Automatic retries with exponential backoff
- **Sending Queue**: 5000-item queue for 5+ minute buffering

## Configuration

### OpenTelemetry Collector

The collector configuration is defined in:

```text
platform/apps/opentelemetry/otel-collector-application.yaml
```

Key configuration sections:

#### Filelog Receiver

```yaml
filelog:
  include:
    - /var/log/containers/*.log
  exclude:
    - /var/log/containers/*otel-collector*.log
  start_at: end
  include_file_path: true
```

#### K8s Attributes Processor

```yaml
k8sattributes:
  extract:
    metadata:
      - k8s.namespace.name
      - k8s.pod.name
      - k8s.container.name
      - k8s.deployment.name
      # ... more attributes
```

#### Loki Exporter (OTLP/HTTP)

```yaml
otlphttp/loki:
  logs_endpoint: "http://loki.logging.svc.cluster.local:3100/otlp/v1/logs"
  retry_on_failure:
    enabled: true
    max_elapsed_time: 300s
  sending_queue:
    enabled: true
    queue_size: 5000
```

This uses Loki's native OTLP endpoint rather than the community
`lokiexporter` component - Grafana's recommended path, since Loki applies
its own resource-attribute-to-label mapping automatically.

### Loki Deployment

Loki's chart values (schema, retention, storage) are defined in:

```text
platform/apps/loki/loki-application.yaml
```

Single-binary MVP deployment: `deploymentMode: SingleBinary`, filesystem
chunk storage, `retention_period: 720h` (30 days). No index-template or
ILM-policy configuration is needed - Loki derives its index directly from
stream labels and the schema config in the chart values.

## Usage

### Searching Logs in Loki

Access Grafana Explore, select the **Loki** data source, and use LogQL:

**Find logs from a specific namespace:**

```logql
{k8s_namespace_name="my-namespace"}
```

**Find logs with a specific trace ID:**

```logql
{k8s_namespace_name="my-namespace"} | trace_id="<your-32-character-trace-id>"
```

**Find error logs from a deployment:**

```logql
{k8s_deployment_name="my-app"} | severity_text="ERROR"
```

### Structured Logging Best Practices

For optimal trace correlation, applications should emit structured JSON logs:

```json
{
  "@timestamp": "2024-12-07T10:30:00.123Z",
  "level": "INFO",
  "message": "User login successful",
  "traceId": "<32-character-hex-trace-id>",
  "spanId": "<16-character-hex-span-id>",
  "userId": "user-123"
}
```

### Required Fields

| Field     | Type    | Description                          |
| --------- | ------- | ------------------------------------ |
| `level`   | keyword | Log level (ERROR, WARN, INFO, DEBUG) |
| `message` | text    | Human-readable message               |
| `traceId` | keyword | OpenTelemetry trace ID (optional)    |
| `spanId`  | keyword | OpenTelemetry span ID (optional)     |

## Environment Variables

The following environment variables are used by the collector:

| Variable        | Description                        |
| --------------- | ---------------------------------- |
| `K8S_NODE_NAME` | Current node name (auto-populated) |
| `NODE_IP`       | Node IP address (auto-populated)   |

## Monitoring

### Collector Health

Check collector health:

```bash
kubectl port-forward -n monitoring daemonset/otel-collector 13133:13133
curl http://localhost:13133/
```

### ZPages for Debugging

Access collector internal diagnostics:

```bash
kubectl port-forward -n monitoring daemonset/otel-collector 55679:55679
# Open http://localhost:55679/debug/tracez
```

### Metrics

The collector exposes Prometheus metrics at port 8888:

- `otelcol_receiver_accepted_log_records`: Logs received
- `otelcol_exporter_sent_log_records`: Logs exported
- `otelcol_exporter_queue_size`: Current queue size

## Troubleshooting

### Logs Not Appearing in Loki

1. **Check collector pods are running:**

   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=opentelemetry-collector
   ```

2. **Check collector logs:**

   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector --tail=100
   ```

3. **Verify Loki connectivity:**

   ```bash
   kubectl exec -n monitoring -it <collector-pod> -- curl http://loki.logging.svc.cluster.local:3100/ready
   ```

### Missing Kubernetes Attributes

Ensure the collector service account has proper RBAC permissions to read pod metadata.

### High Memory Usage

If the collector is using too much memory, adjust the `memory_limiter` settings or increase resource limits.

## Related Documentation

- [Architecture Overview](../architecture.md)
- [ADR-035 Log Storage Migration from OpenSearch to Loki](../adr/ADR-035%20Log%20Storage%20Migration%20from%20OpenSearch%20to%20Loki.md)
- [ADR-011 Centralized Log Management](../adr/ADR-011%20Centralized%20Log%20Management.md) (superseded)
- [Module 13: Observability](https://github.com/paruff/uFawkesDojo/blob/main/modules/brown-belt/module-13-observability.md)
