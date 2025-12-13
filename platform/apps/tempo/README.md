# Tempo - Distributed Tracing Backend

## Purpose

Grafana Tempo provides scalable, cost-effective distributed tracing storage and querying for the Fawkes platform.

## Key Features

- **High Scale**: Handles millions of spans per second
- **Cost-Effective**: Object storage backend (S3-compatible)
- **Grafana Native**: Seamless integration with Grafana
- **Multiple Protocols**: OTLP, Jaeger, Zipkin
- **TraceQL**: Powerful trace query language

## Architecture

```text
Applications → OpenTelemetry Collector → Tempo → Grafana
```

## Quick Start

### Accessing Tempo

Tempo is accessed through Grafana:
1. Open Grafana: http://grafana.127.0.0.1.nip.io
2. Navigate to Explore
3. Select "Tempo" data source
4. Query traces

## TraceQL Queries

### Find slow requests
```traceql
{duration > 1s}
```

### Find errors
```traceql
{status = error}
```

### Service-specific traces
```traceql
{service.name = "my-service" && http.status_code >= 500}
```

## Trace Retention

Traces are retained based on age:
- **Recent**: Last 7 days (hot storage)
- **Archive**: 8-30 days (cold storage)
- **Deleted**: > 30 days

## Integration

### With Grafana
Tempo is configured as a data source in Grafana for trace visualization and correlation with logs/metrics.

### With OpenSearch
Link traces to logs:
```json
{
  "trace_id": "abc123...",
  "span_id": "def456...",
  "message": "Request failed"
}
```

## Related Documentation

- [Tempo Documentation](https://grafana.com/docs/tempo/latest/)
- [TraceQL Guide](https://grafana.com/docs/tempo/latest/traceql/)
