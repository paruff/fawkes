# Prometheus Metrics Monitoring

This directory contains the configuration for the Fawkes observability stack, implementing a unified metrics collection pipeline using Prometheus, Alertmanager, Grafana, and OpenTelemetry Collector.

## Overview

The observability stack provides:

- **Infrastructure Metrics**: Node and pod metrics (CPU, Memory, Disk, Network) via OpenTelemetry Collector DaemonSet
- **Application Metrics**: Prometheus-formatted metrics from applications using OpenTelemetry SDKs
- **Resource Enrichment**: Kubernetes labels (namespace, pod_name, service_name) on all metrics
- **SLO-Based Alerting**: P99 latency and error rate alerts with Slack notifications
- **Golden Signals Dashboard**: Latency, Traffic, Errors, Saturation visualization

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Applications / Infrastructure                                   │
│  ├─ OpenTelemetry SDK instrumented apps                         │
│  ├─ /metrics endpoints (Prometheus format)                      │
│  └─ Kubernetes nodes and pods                                   │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  OpenTelemetry Collector (DaemonSet)                            │
│  ├─ OTLP Receiver (gRPC: 4317, HTTP: 4318)                     │
│  ├─ Prometheus Receiver (scrapes /metrics)                      │
│  ├─ Kubeletstats Receiver (container metrics)                   │
│  ├─ Host Metrics Receiver (node metrics)                        │
│  └─ K8s Attributes Processor (label enrichment)                 │
└────────────────────────────┬────────────────────────────────────┘
                             │ Prometheus Remote Write
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│  Prometheus Server                                               │
│  ├─ ServiceMonitor auto-discovery                               │
│  ├─ Recording rules (SLO calculations)                          │
│  └─ Alerting rules (SLO violations)                             │
└────────────┬────────────────────────────┬───────────────────────┘
             │                            │
             ▼                            ▼
┌────────────────────────┐    ┌────────────────────────────────────┐
│  Alertmanager          │    │  Grafana                           │
│  ├─ Routing            │    │  ├─ Golden Signals Dashboard       │
│  ├─ Grouping           │    │  ├─ Kubernetes Dashboards          │
│  └─ Slack Notifications│    │  └─ Custom Dashboards              │
└────────────────────────┘    └────────────────────────────────────┘
```

## Components

### ArgoCD Applications

| File | Component | Description |
|------|-----------|-------------|
| `prometheus-application.yaml` | kube-prometheus-stack | Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics |
| `../opentelemetry/otel-collector-application.yaml` | OpenTelemetry Collector | DaemonSet for metrics collection and enrichment |

### Configuration Files

| File | Purpose |
|------|---------|
| `servicemonitors.yaml` | ServiceMonitor/PodMonitor resources for platform services |
| `slo-alerting-rules.yaml` | SLO-based alerting rules (P99 latency, error rate, availability) |
| `golden-signals-dashboard.yaml` | Grafana dashboard ConfigMap for Golden Signals |
| `alerting-rules-mvp.yaml` | Basic infrastructure alerting rules |
| `values-mvp.yaml` | Minimal Prometheus configuration for MVP deployments |
| `additional-scrape-configs.yaml` | Legacy scrape configuration for Jenkins |

## Deployment

### Prerequisites

1. Kubernetes cluster with ArgoCD installed
2. Ingress controller (nginx-ingress)
3. Storage class available for persistent volumes

### Deploy the Stack

```bash
# Apply the ArgoCD applications
kubectl apply -f platform/apps/prometheus/prometheus-application.yaml
kubectl apply -f platform/apps/opentelemetry/otel-collector-application.yaml

# Apply ServiceMonitors and alerting rules
kubectl apply -f platform/apps/prometheus/servicemonitors.yaml
kubectl apply -f platform/apps/prometheus/slo-alerting-rules.yaml
kubectl apply -f platform/apps/prometheus/golden-signals-dashboard.yaml
```

### Configure Alertmanager Slack Integration

```bash
# Create secret with Slack webhook URL
kubectl create secret generic alertmanager-slack-webhook \
  --namespace monitoring \
  --from-literal=slack-webhook-url=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

## Accessing the Services

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Prometheus | http://prometheus.127.0.0.1.nip.io | N/A |
| Grafana | http://grafana.127.0.0.1.nip.io | admin / fawkesidp |
| Alertmanager | http://alertmanager.127.0.0.1.nip.io | N/A |

## Application Instrumentation

### Using OpenTelemetry SDK

Applications should use the OpenTelemetry SDK to emit metrics. The collector is available at:

- **gRPC**: `otel-collector.monitoring.svc.cluster.local:4317`
- **HTTP**: `otel-collector.monitoring.svc.cluster.local:4318`

### Go Application Example

```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc"
    "go.opentelemetry.io/otel/sdk/metric"
)

func initMetrics() (*metric.MeterProvider, error) {
    exporter, err := otlpmetricgrpc.New(ctx,
        otlpmetricgrpc.WithEndpoint("otel-collector.monitoring.svc.cluster.local:4317"),
        otlpmetricgrpc.WithInsecure(),
    )
    if err != nil {
        return nil, err
    }

    provider := metric.NewMeterProvider(
        metric.WithReader(metric.NewPeriodicReader(exporter)),
    )
    otel.SetMeterProvider(provider)
    return provider, nil
}
```

### Python Application Example

```python
from opentelemetry import metrics
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader

exporter = OTLPMetricExporter(
    endpoint="otel-collector.monitoring.svc.cluster.local:4317",
    insecure=True,
)
reader = PeriodicExportingMetricReader(exporter)
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)
```

### Exposing /metrics Endpoint

For applications that expose a Prometheus `/metrics` endpoint, add these annotations to enable auto-discovery:

```yaml
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
    prometheus.io/path: "/metrics"
```

## SLO Alerting Rules

The following SLO-based alerts are configured:

| Alert | Condition | Severity | SLO |
|-------|-----------|----------|-----|
| SLOLatencyP99Critical | P99 latency > 500ms for 5m | critical | 99th percentile < 500ms |
| SLOLatencyP95Warning | P95 latency > 300ms for 10m | warning | 95th percentile < 300ms |
| SLOErrorRateCritical | Error rate > 5% for 5m | critical | Error rate < 5% |
| SLOErrorRateWarning | Error rate > 1% for 10m | warning | Error rate < 1% |
| SLOAvailabilityCritical | Availability < 99.9% for 5m | critical | 99.9% uptime |

## Golden Signals Dashboard

The dashboard provides visibility into the four golden signals:

1. **Latency**: P50, P95, P99 request duration
2. **Traffic**: Request rate by service
3. **Errors**: Error rate and 5xx distribution
4. **Saturation**: CPU and memory utilization

### Dashboard Variables

- **datasource**: Prometheus data source
- **namespace**: Filter by Kubernetes namespace
- **service**: Filter by service name

## Recording Rules

Pre-aggregated metrics for efficient dashboard queries:

| Metric | Description |
|--------|-------------|
| `fawkes:http_requests:rate5m` | Request rate per service |
| `fawkes:http_errors:rate5m` | Error rate per service |
| `fawkes:http_error_rate:ratio5m` | Error rate percentage |
| `fawkes:http_latency:p50` | P50 latency per service |
| `fawkes:http_latency:p95` | P95 latency per service |
| `fawkes:http_latency:p99` | P99 latency per service |
| `fawkes:service:availability` | Service availability |

## Troubleshooting

### Check Prometheus Targets

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090

# Open http://localhost:9090/targets
```

### Check Alertmanager Status

```bash
# Port-forward to Alertmanager
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

# Open http://localhost:9093/#/status
```

### View OpenTelemetry Collector Logs

```bash
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector -f
```

### Verify ServiceMonitors

```bash
kubectl get servicemonitors -n monitoring
kubectl describe servicemonitor <name> -n monitoring
```

## Legacy Configuration

The original scrape configuration approach (documented in `prometheus-notes.md`) used external secrets for additional scrape configs. The new approach uses:

1. **ServiceMonitors**: Kubernetes-native service discovery
2. **PodMonitors**: Pod-level metric scraping
3. **OpenTelemetry Collector**: Unified metrics collection

The legacy `additional-scrape-configs.yaml` is maintained for backward compatibility but should be migrated to ServiceMonitors.

## References

- [kube-prometheus-stack Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
- [OpenTelemetry Collector](https://opentelemetry.io/docs/collector/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [ADR-012: Metrics Monitoring and Management](../../../docs/adr/ADR-012%20Metrics%20Monitoring%20and%20Management.md)
