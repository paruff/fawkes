# Monitoring and Observability Pattern

Monitoring tells you **when** something is wrong. Observability tells you **why**.
Elite engineering teams invest in both to detect problems before users do and to
understand the root cause quickly when incidents occur.

## The Four Golden Signals

Google SRE defined four golden signals that, when measured for every service, give
a complete picture of health:

| Signal | What It Measures | Example Metric |
|--------|-----------------|----------------|
| **Latency** | Time to service a request | P95 HTTP response time |
| **Traffic** | Demand on the system | Requests per second |
| **Errors** | Rate of failed requests | HTTP 5xx error rate |
| **Saturation** | How "full" the service is | CPU utilisation, queue depth |

## How Fawkes Implements Monitoring

All workloads in Fawkes emit the four golden signals automatically via OpenTelemetry
auto-instrumentation. Prometheus scrapes `/metrics` endpoints; Grafana renders dashboards.

```yaml
# PrometheusRule (platform/apps/monitoring/rules.yaml)
- alert: HighErrorRate
  expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05
  for: 2m
  labels:
    severity: warning
```

## Alerting Strategy

1. **Page on symptoms, not causes** — Alert on user-visible SLO violations (error rate,
   latency), not on intermediate metrics (CPU) that may not affect users.
2. **Every alert needs a runbook** — Link the alert annotation to the relevant runbook
   in `docs/runbooks/`.
3. **Silence noisy alerts** — A silenced alert is better than alert fatigue that causes
   on-call engineers to ignore pages.

## Distributed Tracing

Requests that span multiple services are traced end-to-end with OpenTelemetry. Traces
are stored in Tempo and visualised in Grafana. Use the trace ID from logs to jump
directly to the relevant span waterfall.

## Log Aggregation

Fluent Bit collects structured JSON logs from all pods and ships them to Loki. Use
LogQL in Grafana to search and correlate logs across services.

## See Also

- [Unified Telemetry](../explanation/observability/unified-telemetry.md)
- [Trace Requests with Tempo](../how-to/observability/trace-request-tempo.md)
- [Grafana](../tools/grafana.md)
