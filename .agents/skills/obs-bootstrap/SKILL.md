---
name: obs-bootstrap
description: "Step-by-step OpenTelemetry and uFawkesObs setup: SDK init patterns for TypeScript, Python, Go; DORA metric spans; Grafana dashboard spec. Use when adding observability to a service."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Observability Bootstrap

> **Load trigger:** `"load obs-bootstrap skill"`
> **Agent:** Used by obs-agent
> **DORA:** Cap 6 + Cap 2
> **Token cost:** Medium

## Purpose

Step-by-step guide for connecting a service to uFawkesObs
(Prometheus + Loki + Tempo + Grafana via OpenTelemetry).

## Prerequisites

- [ ] `OTEL_SERVICE_NAME` defined in `docs/PIPELINE_CONTRACT.md`
- [ ] uFawkesObs infrastructure running (`make dev-up` in paruff/fawkes for local)
- [ ] Language OTEL SDK installed (see lang skill for install command)

## Local Endpoints (after `make dev-up`)

| Service           | URL                                                    |
| ----------------- | ------------------------------------------------------ |
| Grafana           | http://localhost:8080/grafana (admin / fawkes-grafana) |
| OTLP collector    | http://localhost:4318                                  |
| Prometheus        | http://localhost:9090                                  |
| Jaeger (Tempo UI) | http://localhost:16686                                 |

## Step 1 — Environment Variables

Add to `.env.example` (never to `.env` committed to git):

```
OTEL_SERVICE_NAME=your-service-name
OTEL_EXPORTER_OTLP_ENDPOINT=http://localhost:4318
OTEL_TRACES_EXPORTER=otlp
OTEL_METRICS_EXPORTER=prometheus
LOG_LEVEL=info
```

Add to Kubernetes Secret for production:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: [service-name]-otel-config
stringData:
  OTEL_SERVICE_NAME: "[service-name]"
  OTEL_EXPORTER_OTLP_ENDPOINT: "http://otel-collector.observability:4318"
```

## Step 2 — SDK Initialization

### TypeScript (Node.js)

```typescript
// src/instrumentation.ts — import BEFORE all other imports
import { NodeSDK } from "@opentelemetry/sdk-node";
import { OTLPTraceExporter } from "@opentelemetry/exporter-trace-otlp-http";

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
  }),
  serviceName: process.env.OTEL_SERVICE_NAME || "unknown-service",
});

sdk.start();
process.on("SIGTERM", () => sdk.shutdown());
```

### Python

```python
# src/instrumentation.py — call configure_otel() before app startup
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
import os

def configure_otel():
    provider = TracerProvider()
    exporter = OTLPSpanExporter(endpoint=os.getenv('OTEL_EXPORTER_OTLP_ENDPOINT'))
    provider.add_span_processor(BatchSpanProcessor(exporter))
    trace.set_tracer_provider(provider)
```

### Go

```go
// internal/telemetry/otel.go
func InitTracer(ctx context.Context) (func(), error) {
    exporter, err := otlptracehttp.New(ctx,
        otlptracehttp.WithEndpoint(os.Getenv("OTEL_EXPORTER_OTLP_ENDPOINT")),
        otlptracehttp.WithInsecure(),
    )
    if err != nil { return nil, err }
    tp := sdktrace.NewTracerProvider(
        sdktrace.WithBatcher(exporter),
        sdktrace.WithResource(resource.NewWithAttributes(
            semconv.SchemaURL,
            semconv.ServiceNameKey.String(os.Getenv("OTEL_SERVICE_NAME")),
        )),
    )
    otel.SetTracerProvider(tp)
    return func() { _ = tp.Shutdown(ctx) }, nil
}
```

## Step 3 — DORA Metric Spans

Add these spans at deployment event points (typically in CI, not application code):

```
deployment.started   → attributes: service, version, environment, commit_sha
deployment.completed → attributes: service, version, environment, duration_ms, status
deployment.failed    → attributes: service, version, environment, error, rollback_triggered
incident.opened      → attributes: service, severity, trigger
incident.resolved    → attributes: service, severity, duration_ms
```

## Step 4 — Grafana Dashboard

Create `docs/obs/[service-name]-dashboard.json` with these panels:

```json
{
  "panels": [
    {
      "title": "Request Rate",
      "type": "timeseries",
      "targets": [{ "expr": "rate(http_requests_total[5m])" }]
    },
    {
      "title": "Error Rate %",
      "type": "stat",
      "targets": [
        {
          "expr": "rate(http_errors_total[5m]) / rate(http_requests_total[5m]) * 100"
        }
      ]
    },
    {
      "title": "P95 Latency",
      "type": "timeseries",
      "targets": [
        {
          "expr": "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))"
        }
      ]
    },
    {
      "title": "Deployment Frequency",
      "type": "timeseries",
      "targets": [{ "expr": "increase(deployments_total[1d])" }]
    }
  ]
}
```

Import via Grafana UI: Dashboards → Import → paste JSON.

## Validation Checklist

- [ ] Span appears in Grafana Explore → Tempo after a test request
- [ ] Service name matches `OTEL_SERVICE_NAME` in Tempo service graph
- [ ] Deployment span visible after a deploy (check Tempo)
- [ ] No PII visible in span attributes
- [ ] Startup time delta < 50ms with SDK enabled
