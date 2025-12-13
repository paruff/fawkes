# OpenTelemetry Collector - Observability Data Pipeline

## Purpose

OpenTelemetry Collector receives, processes, and exports telemetry data (metrics, logs, traces) from applications and infrastructure.

## Key Features

- **Multi-Protocol**: OTLP, Prometheus, Jaeger, Zipkin
- **Processing**: Filtering, batching, attribute enrichment
- **Multiple Exporters**: Prometheus, OpenSearch, Tempo
- **Kubernetes Enrichment**: Add K8s metadata automatically
- **Low Overhead**: Efficient data pipeline

## Architecture

```text
Applications → OTLP → Collector → Prometheus/OpenSearch/Tempo
```

## Configuration

```yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  k8sattributes:
    passthrough: false
    extract:
      metadata:
        - k8s.pod.name
        - k8s.namespace.name

exporters:
  prometheus:
    endpoint: "0.0.0.0:8889"
  opensearch:
    endpoint: http://opensearch.logging.svc:9200
  otlp/tempo:
    endpoint: http://tempo.monitoring.svc:4317

service:
  pipelines:
    metrics:
      receivers: [otlp]
      processors: [batch, k8sattributes]
      exporters: [prometheus]
    traces:
      receivers: [otlp]
      processors: [batch, k8sattributes]
      exporters: [otlp/tempo]
```

## Application Integration

### Go
```go
import "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"

exporter, _ := otlptracegrpc.New(ctx,
    otlptracegrpc.WithEndpoint("otel-collector.monitoring.svc:4317"),
    otlptracegrpc.WithInsecure(),
)
```

### Python
```python
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter

exporter = OTLPSpanExporter(
    endpoint="otel-collector.monitoring.svc:4317",
    insecure=True
)
```

## Related Documentation

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/collector/)
- [ADR-012: Metrics Monitoring](../../../docs/adr/ADR-012-metrics-monitoring.md)
