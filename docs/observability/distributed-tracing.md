# Distributed Tracing with OpenTelemetry and Tempo

## Overview

Fawkes implements centralized distributed tracing for all platform services and applications using OpenTelemetry for instrumentation and Grafana Tempo for trace storage. This enables end-to-end request visibility across service boundaries, performance analysis, and rapid root cause identification.

**Reference**: See [ADR-013 Distributed Tracing](../adr/ADR-013%20distributed%20tracing.md) for architectural decisions.

## Architecture

```text
┌────────────────────────────────────────────────────────────────────┐
│  Applications & Platform Services                                   │
│                                                                     │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────────┐ │
│  │ Backstage  │  │ Jenkins    │  │ ArgoCD     │  │ Custom Apps  │ │
│  │ (Node.js)  │  │ (Java)     │  │ (Go)       │  │ (Any Lang)   │ │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └──────┬───────┘ │
│        │               │               │                │          │
│        │ OpenTelemetry SDK / Auto-instrumentation       │          │
│        └───────────────┴───────────────┴────────────────┘          │
│                              │                                      │
│                              │ OTLP (gRPC/HTTP)                    │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ OpenTelemetry Collector DaemonSet                           │  │
│  │ - OTLP receiver: Accepts traces from applications           │  │
│  │ - K8s attributes: Enriches with pod/namespace metadata      │  │
│  │ - Sampling: Configurable probabilistic sampling             │  │
│  │ - Security: Scrubs sensitive data (auth headers, etc.)      │  │
│  │ - Batching: Efficient export to Tempo                       │  │
│  └───────────────────────────┬─────────────────────────────────┘  │
│                              │ OTLP/gRPC                           │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Grafana Tempo                                                │  │
│  │ - Trace storage and querying                                 │  │
│  │ - TraceQL for advanced queries                               │  │
│  │ - Service dependency graphs                                  │  │
│  │ - Metrics generation (RED metrics from traces)               │  │
│  └───────────────────────────┬─────────────────────────────────┘  │
│                              │                                      │
│                              ▼                                      │
│  ┌─────────────────────────────────────────────────────────────┐  │
│  │ Grafana                                                      │  │
│  │ - Trace visualization and flame graphs                       │  │
│  │ - Trace-to-logs correlation (OpenSearch)                     │  │
│  │ - Trace-to-metrics correlation (Prometheus)                  │  │
│  │ - Service dependency node graph                              │  │
│  └─────────────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────────────┘
```

## Key Features

### 1. Trace Generation and Collection

The OpenTelemetry Collector receives traces via OTLP protocol from instrumented applications:

- **Protocol**: OTLP over gRPC (port 4317) and HTTP (port 4318)
- **Format**: W3C Trace Context standard (`traceparent`, `tracestate` headers)
- **Enrichment**: Automatic Kubernetes metadata (pod, namespace, deployment)

### 2. Cross-Service Propagation

Traces are automatically propagated across service boundaries using W3C Trace Context:

| Header        | Purpose                                     |
| ------------- | ------------------------------------------- |
| `traceparent` | Contains trace ID, span ID, and trace flags |
| `tracestate`  | Vendor-specific trace context               |

### 3. Trace-Log Correlation

Every trace is correlated with application logs:

| Attribute  | Description                               |
| ---------- | ----------------------------------------- |
| `trace_id` | 32-character hexadecimal trace identifier |
| `span_id`  | 16-character hexadecimal span identifier  |

Click on a trace ID in logs to jump directly to the trace in Grafana.

### 4. Performance Visibility

Traces include key performance attributes:

- HTTP method, status code, and route
- Database query duration and statement (hashed)
- External service call latency
- Custom span attributes

### 5. Sampling Strategy

Development environment uses 100% sampling for full visibility. Production can be configured for:

- **Head-based sampling**: 10% of all requests
- **Always sample**: Errors and requests > 1 second latency
- **Tail-based sampling**: Keep interesting traces after collection

## Configuration

### OpenTelemetry Collector

The traces pipeline is configured in:

```text
platform/apps/opentelemetry/otel-collector-application.yaml
```

Key configuration:

```yaml
# Traces pipeline configuration
traces:
  receivers:
    - otlp
  processors:
    - memory_limiter
    - probabilistic_sampler
    - k8sattributes
    - resourcedetection
    - attributes/traces
    - transform/traces
    - batch/traces
  exporters:
    - otlp/tempo
```

### Grafana Tempo

Tempo is deployed as the trace storage backend:

```text
platform/apps/tempo/tempo-application.yaml
```

Key features:

- OTLP ingestion on ports 4317 (gRPC) and 4318 (HTTP)
- 7-day trace retention
- Metrics generation for RED metrics
- TraceQL query support

### Grafana Data Sources

Grafana is configured with trace correlation:

```text
platform/apps/grafana/helm-release.yml
```

Data sources configured:

- **Tempo**: Trace storage and visualization
- **Prometheus**: Trace-to-metrics correlation
- **OpenSearch**: Trace-to-logs correlation

## Application Instrumentation

### Java Applications (Spring Boot, Jenkins)

```bash
# Download OpenTelemetry Java agent
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Add to JVM arguments
java -javaagent:opentelemetry-javaagent.jar \
     -Dotel.service.name=my-java-app \
     -Dotel.exporter.otlp.endpoint=http://otel-collector.monitoring.svc.cluster.local:4317 \
     -jar my-app.jar
```

### Python Applications (FastAPI, Django)

```bash
# Install OpenTelemetry packages
pip install opentelemetry-distro opentelemetry-exporter-otlp

# Auto-instrument application
opentelemetry-bootstrap -a install
opentelemetry-instrument \
  --service_name my-python-app \
  --exporter_otlp_endpoint http://otel-collector.monitoring.svc.cluster.local:4317 \
  python app.py
```

### Node.js Applications (Backstage, Express)

```javascript
// tracing.js - Add at the very top of your application
const { NodeSDK } = require("@opentelemetry/sdk-node");
const { OTLPTraceExporter } = require("@opentelemetry/exporter-trace-otlp-grpc");
const { getNodeAutoInstrumentations } = require("@opentelemetry/auto-instrumentations-node");

const sdk = new NodeSDK({
  serviceName: "my-nodejs-app",
  traceExporter: new OTLPTraceExporter({
    url: "grpc://otel-collector.monitoring.svc.cluster.local:4317",
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

### Go Applications (ArgoCD, Custom Controllers)

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
    "go.opentelemetry.io/otel/sdk/resource"
    sdktrace "go.opentelemetry.io/otel/sdk/trace"
    semconv "go.opentelemetry.io/otel/semconv/v1.17.0"
)

func initTracer() (*sdktrace.TracerProvider, error) {
    exporter, err := otlptracegrpc.New(context.Background(),
        otlptracegrpc.WithEndpoint("otel-collector.monitoring.svc.cluster.local:4317"),
        otlptracegrpc.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }

    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceName("my-go-app"),
        )),
    )
    otel.SetTracerProvider(tp)
    return tp, nil
}
```

## Usage

### Querying Traces in Grafana

Access Grafana at `http://grafana.127.0.0.1.nip.io` and navigate to Explore → Tempo.

#### Find traces by service

```traceql
{resource.service.name="backstage"}
```

#### Find slow traces (> 1 second)

```traceql
{duration > 1s}
```

#### Find traces with errors

```traceql
{status = error}
```

#### Find database queries

```traceql
{span.db.system = "postgresql"}
```

#### Find traces by HTTP route

```traceql
{span.http.route = "/api/catalog/*"}
```

### Trace-to-Logs Correlation

1. Open a trace in Grafana Tempo
2. Click on any span
3. Click "Logs for this span" to jump to OpenSearch logs
4. Logs are filtered by trace ID and time range

### Trace-to-Metrics Correlation

1. Open a Prometheus dashboard
2. Click on a data point with exemplars
3. Click "View Trace" to jump to the associated trace

## Environment Variables

| Variable                    | Description                  | Default                                          |
| --------------------------- | ---------------------------- | ------------------------------------------------ |
| `TEMPO_URL`                 | Tempo API endpoint           | `http://tempo.monitoring.svc.cluster.local:3200` |
| `TEMPO_OTLP_GRPC_ENDPOINT`  | OTLP gRPC ingestion endpoint | `tempo.monitoring.svc.cluster.local:4317`        |
| `TEMPO_OTLP_HTTP_ENDPOINT`  | OTLP HTTP ingestion endpoint | `http://tempo.monitoring.svc.cluster.local:4318` |
| `TRACE_SAMPLING_PERCENTAGE` | Sampling rate (1-100)        | `100` (development)                              |
| `TRACE_CLUSTER_NAME`        | Cluster identifier           | `fawkes-dev`                                     |
| `TRACE_ENVIRONMENT`         | Environment label            | `development`                                    |

## Monitoring

### Tempo Health

Check Tempo health via API:

```bash
kubectl port-forward -n monitoring svc/tempo 3200:3200
curl http://localhost:3200/ready
```

### Collector Metrics

The OpenTelemetry Collector exposes metrics at port 8888:

- `otelcol_receiver_accepted_spans`: Spans received
- `otelcol_exporter_sent_spans`: Spans exported to Tempo
- `otelcol_exporter_send_failed_spans`: Export failures
- `otelcol_processor_batch_batch_send_size`: Batch sizes

### ZPages for Debugging

Access collector internal diagnostics:

```bash
kubectl port-forward -n monitoring daemonset/otel-collector 55679:55679
# Open http://localhost:55679/debug/tracez
```

## Troubleshooting

### Traces Not Appearing in Tempo

1. **Check collector pods are running:**

   ```bash
   kubectl get pods -n monitoring -l app.kubernetes.io/name=opentelemetry-collector
   ```

2. **Check collector logs for export errors:**

   ```bash
   kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector --tail=100 | grep -i error
   ```

3. **Verify Tempo connectivity:**

   ```bash
   kubectl exec -n monitoring -it <collector-pod> -- wget -qO- http://tempo.monitoring.svc.cluster.local:3200/ready
   ```

### Missing Kubernetes Attributes

Ensure the collector service account has proper RBAC permissions to read pod metadata.

### Application Not Sending Traces

1. Verify OTEL SDK is properly initialized
2. Check `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable
3. Verify network connectivity to collector (port 4317/4318)

### High Trace Volume / Cost

1. Reduce `TRACE_SAMPLING_PERCENTAGE` (e.g., 10 for production)
2. Configure tail-based sampling for error/latency-focused collection
3. Review span cardinality and reduce high-cardinality attributes

## Best Practices

### Span Naming

- Use semantic, action-based names: `GET /api/users/{id}`, `db.query`
- Avoid high-cardinality values in span names (user IDs, timestamps)
- Be consistent across services

### Span Attributes

- Include relevant context: `user.id`, `order.id`, `feature.flag`
- Avoid sensitive data: passwords, tokens, PII
- Use OpenTelemetry semantic conventions

### Error Handling

```go
span.RecordError(err)
span.SetStatus(codes.Error, err.Error())
```

### Custom Spans

Create spans for significant operations:

```go
ctx, span := tracer.Start(ctx, "process-order",
    trace.WithAttributes(
        attribute.String("order.id", orderID),
        attribute.Int("order.items", len(items)),
    ),
)
defer span.End()
```

## Related Documentation

- [Architecture Overview](../architecture.md)
- [ADR-013 Distributed Tracing](../adr/ADR-013%20distributed%20tracing.md)
- [Centralized Logging](centralized-logging.md)
- [Module 13: Observability](../dojo/modules/brown-belt/module-13-observability.md)
