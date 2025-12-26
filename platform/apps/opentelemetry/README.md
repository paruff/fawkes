# OpenTelemetry Collector - Observability Data Pipeline

## Purpose

OpenTelemetry Collector receives, processes, and exports telemetry data (metrics, logs, traces) from applications and infrastructure.

## Deployment Status

✅ **DEPLOYED** - OpenTelemetry Collector is deployed as a DaemonSet in the `monitoring` namespace.

## Key Features

- **Multi-Protocol**: OTLP (gRPC/HTTP), Prometheus scraping, Filelog collection
- **Processing**: Filtering, batching, Kubernetes attribute enrichment, transform operations
- **Multiple Exporters**: Prometheus Remote Write, OpenSearch, Tempo
- **Kubernetes Enrichment**: Automatic enrichment with K8s pod, namespace, deployment metadata
- **DaemonSet Deployment**: Runs on every node for efficient log and metric collection
- **Low Overhead**: Efficient data pipeline with resource limits

## Architecture

```text
Applications/Pods → OTLP/Logs → Collector (DaemonSet) → Prometheus/OpenSearch/Tempo
                                    ↓
                            Kubernetes Enrichment
                                    ↓
                         Batching & Processing
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

## Deployment

The OpenTelemetry Collector is deployed via ArgoCD:

```bash
# Check ArgoCD Application status
kubectl get application -n fawkes otel-collector

# Check DaemonSet status
kubectl get daemonset -n monitoring otel-collector-opentelemetry-collector

# Check pod status
kubectl get pods -n monitoring -l app.kubernetes.io/name=opentelemetry-collector

# View collector logs
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector --tail=100

# Check health endpoint
kubectl exec -n monitoring <pod-name> -- wget -qO- http://localhost:13133
```

## Testing

Run the comprehensive test script:

```bash
./platform/apps/opentelemetry/test-otel-deployment.sh
```

This will:

1. Verify OpenTelemetry Collector DaemonSet is deployed
2. Check OTLP receiver ports are exposed
3. Validate health endpoints
4. Deploy a sample application
5. Generate sample traces
6. Verify exporters are configured

## Sample Application

A Python Flask application with OpenTelemetry instrumentation is provided in `sample-app/`:

```bash
# Deploy sample app
kubectl apply -f platform/apps/opentelemetry/sample-app/deployment.yaml

# Port forward to access
kubectl port-forward -n otel-demo svc/otel-sample-app 8080:80

# Generate traces
curl http://localhost:8080/hello/World
curl http://localhost:8080/work
curl http://localhost:8080/error
```

View traces in Grafana by querying Tempo with:

```
{service.name="otel-sample-app"}
```

## Acceptance Criteria

✅ **OTel Collector deployed as DaemonSet** - Running on all nodes in monitoring namespace
✅ **Receivers configured (OTLP, Prometheus)** - OTLP gRPC (4317), HTTP (4318), Prometheus scraping, Kubeletstats, Hostmetrics
✅ **Exporters configured (Prometheus, OpenSearch)** - Prometheus Remote Write, OpenSearch for logs, Tempo for traces
✅ **Sample traces flowing** - Sample application generates and exports traces via OTLP

## Configuration Files

- `otel-collector-application.yaml` - ArgoCD Application manifest
- `sample-app/` - Sample instrumented application
- `test-otel-deployment.sh` - Validation test script

## Related Documentation

- [OpenTelemetry Documentation](https://opentelemetry.io/docs/collector/)
- [ADR-011: Centralized Log Management](../../../docs/adr/ADR-011%20Centralized%20Log%20Management.md)
- [ADR-012: Metrics Monitoring](../../../docs/adr/ADR-012-metrics-monitoring.md)
- [ADR-013: Distributed Tracing](../../../docs/adr/ADR-013%20Distributed%20Tracing.md)
- [Architecture: Observability Stack](../../../docs/architecture.md#4-observability-stack)
