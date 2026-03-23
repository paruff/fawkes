# Monitoring and Observability Pattern

While **monitoring** answers "is the system working?", **observability** answers "why
is the system not working?". An observable system exposes enough internal state that
you can understand any failure from the outside, without needing to add new
instrumentation every time something goes wrong.

## The Three Pillars

### Metrics

Metrics are numeric time-series measurements (e.g., request rate, error count,
memory usage). In Fawkes, Prometheus collects metrics from all services via
`/metrics` endpoints exposed by OpenTelemetry instrumentation.

### Logs

Logs record discrete events. Fawkes requires structured JSON logs (`structlog` for
Python, `zap` for Go, `logback` for Java). Fluent Bit ships logs to Loki where
they are queryable with LogQL.

```python
import structlog
log = structlog.get_logger()
log.info("request_processed", user_id=user.id, duration_ms=elapsed)
```

### Traces

Distributed traces track a request's journey across service boundaries. The trace ID
connects a user-facing error to the exact microservice call chain that caused it.
OpenTelemetry auto-instrumentation captures spans for HTTP, database, and messaging
calls with no code changes.

## Observability vs Monitoring

| Aspect | Monitoring | Observability |
|--------|-----------|---------------|
| Asks | Is it working? | Why is it broken? |
| Requires | Known failure modes | Arbitrary exploration |
| Tooling | Dashboards, alerts | Trace explorer, log search |
| Instrumentation | Predefined metrics | Rich structured data |

## Cardinality Considerations

High-cardinality labels (like user IDs or request IDs) in Prometheus metrics will
cause cardinality explosion. Use traces for high-cardinality data; use metrics only
for low-cardinality aggregates.

## SLOs and Error Budgets

Define Service Level Objectives (SLOs) for each user-facing service. An error budget
is the allowed amount of downtime or errors before the SLO is breached. Fawkes tracks
SLOs in Grafana using Prometheus recording rules.

## See Also

- [Unified Telemetry](../explanation/observability/unified-telemetry.md)
- [Grafana](../tools/grafana.md)
- [Monitoring Pattern](monitoring.md)
