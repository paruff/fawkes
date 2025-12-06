---
title: Trace a Request with Grafana Tempo
description: Debug application latency and errors using distributed tracing
---

# Trace a Request with Grafana Tempo

## Goal

Find and analyze a specific request trace using Grafana Tempo to debug latency issues, identify bottlenecks, or investigate errors across microservices.

## Prerequisites

Before you begin, ensure you have:

- [ ] Application instrumented with OpenTelemetry (see [Distributed Tracing](../../observability/distributed-tracing.md))
- [ ] Access to Grafana UI (`https://grafana.127.0.0.1.nip.io`)
- [ ] Tempo data source configured in Grafana
- [ ] Trace ID from application logs (for direct lookup) OR time window of the issue

## Steps

### Method 1: Find Trace by Trace ID (Direct Lookup)

Use this method when you have a specific trace ID from application logs.

#### 1. Locate Trace ID in Application Logs

Application logs should include trace IDs. Example log entry:

```json
{
  "timestamp": "2024-12-06T10:30:45Z",
  "level": "ERROR",
  "message": "Payment processing failed",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "service": "payment-service",
  "error": "Database connection timeout"
}
```

#### 2. Open Grafana Explore

1. Navigate to Grafana: `https://grafana.127.0.0.1.nip.io`
2. Click **Explore** (compass icon) in the left sidebar
3. Select **Tempo** from the data source dropdown

#### 3. Search by Trace ID

1. In the query builder, select **Search** tab
2. Enter the trace ID in the **Trace ID** field:
   ```
   4bf92f3577b34da6a3ce929d0e0e4736
   ```
3. Click **Run query** (or press Shift+Enter)

#### 4. Analyze the Trace

The trace view displays:

- **Service Map**: Visual representation of service calls
- **Timeline**: Waterfall view showing span duration
- **Span Details**: Click any span to see:
  - Span name and duration
  - HTTP method, status code, route
  - Database queries
  - Error messages
  - Custom attributes

### Method 2: Search Traces Using TraceQL

Use this method to find traces matching specific criteria (errors, slow requests, specific service).

#### 1. Open Tempo in Grafana Explore

1. Navigate to **Explore** in Grafana
2. Select **Tempo** data source

#### 2. Write TraceQL Query

Use TraceQL to search for traces. Common queries:

**Find all error traces in the last hour:**

```traceql
{status = error}
```

**Find slow requests (> 1 second):**

```traceql
{duration > 1s}
```

**Find traces for a specific service:**

```traceql
{resource.service.name = "payment-service"}
```

**Find traces with database errors:**

```traceql
{span.db.system = "postgresql" && status = error}
```

**Find traces for a specific HTTP route:**

```traceql
{span.http.route = "/api/orders/*" && span.http.method = "POST"}
```

**Combine multiple conditions:**

```traceql
{
  resource.service.name = "payment-service" &&
  duration > 500ms &&
  span.http.status_code = 500
}
```

#### 3. Execute Query

1. Enter your TraceQL query in the query editor
2. Set the time range (e.g., "Last 1 hour")
3. Click **Run query**

#### 4. Review Search Results

Results show:

- Trace ID
- Root service name
- Trace duration
- Start time
- Number of spans
- Number of errors

Click on a trace to view details.

### Method 3: Trace-to-Logs Correlation

Use this method to jump from logs to traces.

#### 1. Open Logs in Grafana

1. Navigate to **Explore** in Grafana
2. Select **OpenSearch** (or **Loki**) data source

#### 2. Query Application Logs

Example query for recent errors:

```
{namespace="my-service-dev"} |~ "ERROR"
```

#### 3. Click Trace ID Link

In the log results:

1. Find a log entry with a `trace_id` field
2. Click on the trace ID link (appears as a blue hyperlink)
3. Grafana automatically switches to Tempo and loads the trace

### Method 4: Trace from Service Map

Use this method to explore service dependencies and find problematic traces.

#### 1. Open Service Map

1. In Grafana, navigate to **Explore**
2. Select **Tempo** data source
3. Click on **Service Graph** tab

#### 2. Identify Problematic Service

The service map shows:

- **Nodes**: Each service in your architecture
- **Edges**: Request flow between services
- **Colors**: Green (healthy), Yellow (warnings), Red (errors)
- **Size**: Proportional to request volume

#### 3. Search Traces for That Service

1. Click on a service node showing high latency or errors
2. The query builder auto-populates with the service name
3. Add additional filters (e.g., errors only)
4. Click **Run query**

### Method 5: Search by Custom Attributes

Use custom span attributes to find specific user journeys or business flows.

#### 1. Build Query with Custom Attributes

Example queries using custom attributes:

**Find traces for a specific user:**

```traceql
{span.user.id = "alice@example.com"}
```

**Find traces for a specific order:**

```traceql
{span.order.id = "ORD-12345"}
```

**Find traces with feature flag enabled:**

```traceql
{span.feature.flag.new_checkout = "true"}
```

#### 2. Combine with Other Filters

```traceql
{
  span.user.id = "alice@example.com" &&
  resource.service.name = "checkout-service" &&
  duration > 2s
}
```

## Verification

### 1. Verify Trace Completeness

A complete trace should show:

- ✅ All services involved in the request path
- ✅ Parent-child relationships between spans
- ✅ No missing spans (gaps in the timeline)
- ✅ Consistent trace context propagation

**Check for missing spans:**

- Look for gaps in the waterfall view
- Verify each service call has a corresponding child span
- Check for orphaned spans (no parent)

### 2. Identify Bottlenecks

Find the slowest operation in the trace:

1. Sort spans by duration (longest first)
2. Look for spans consuming >50% of total trace time
3. Common bottlenecks:
   - Slow database queries
   - External API calls
   - Expensive computation
   - Network latency between services

### 3. Analyze Error Attribution

For traces with errors:

1. Find the first span with `status = error`
2. Check span attributes for error details:
   - `error.type`: Exception class name
   - `error.message`: Error description
   - `error.stack`: Stack trace
3. Trace backwards to find the root cause

### 4. Verify Span Attributes

Inspect key span attributes:

```text
Service: payment-service
Operation: POST /api/payments
Duration: 1.2s

Attributes:
  http.method: POST
  http.route: /api/payments
  http.status_code: 500
  http.url: https://api.example.com/api/payments
  db.system: postgresql
  db.statement: SELECT * FROM payments WHERE id = $1
  db.statement.duration: 850ms
  error.type: ConnectionTimeoutError
  error.message: Database connection timeout after 1000ms
  user.id: alice@example.com
  payment.amount: 99.99
  payment.currency: USD
```

## Understanding Trace Visualization

### Waterfall View

The waterfall view shows spans in chronological order:

```text
┌─────────────────────────────────────────────────────────────┐
│ payment-service: POST /api/payments         [1.2s] ▓▓▓▓▓▓▓ │
│  ├─ validate-payment                       [50ms]  ▓        │
│  ├─ check-fraud                            [200ms] ▓▓       │
│  ├─ database: SELECT                       [850ms] ▓▓▓▓▓▓   │
│  └─ send-confirmation                      [100ms] ▓        │
└─────────────────────────────────────────────────────────────┘
          Time →
```

**Key indicators:**

- **Width**: Span duration (wider = slower)
- **Color**: Status (green = success, red = error)
- **Nesting**: Parent-child relationships
- **Gaps**: Network latency or waiting time

### Service Dependency Graph

Shows the flow of requests across services:

```text
┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   Frontend   │ ─────▶  │   API GW     │ ─────▶  │   Payment    │
│              │         │              │         │   Service    │
└──────────────┘         └──────────────┘         └───────┬──────┘
                                                          │
                                                          ▼
                                                   ┌──────────────┐
                                                   │  PostgreSQL  │
                                                   └──────────────┘
```

### Span Timeline

Detailed view of a single span:

```text
Span: database-query
Duration: 850ms
Start: 2024-12-06 10:30:45.123
End: 2024-12-06 10:30:45.973

Timeline:
  0ms ──────────▶ Connection acquired
  50ms ─────────▶ Query sent to database
  800ms ────────▶ Results received
  850ms ────────▶ Span complete
```

## Troubleshooting

### No Traces Found for Trace ID

**Cause**: Trace ID not in Tempo, or retention period expired.

**Solution**:

```bash
# Check Tempo health
kubectl get pods -n monitoring -l app.kubernetes.io/name=tempo

# Verify trace retention period
kubectl get configmap tempo-config -n monitoring -o yaml | grep retention

# Check OpenTelemetry Collector is sending traces
kubectl logs -n monitoring -l app.kubernetes.io/name=opentelemetry-collector | grep -i tempo
```

### Trace Shows Incomplete Spans

**Cause**: Missing OpenTelemetry instrumentation or broken trace context propagation.

**Solution**:

1. Verify all services are instrumented with OpenTelemetry
2. Check for proper trace context propagation:
   ```bash
   # Logs should include trace_id in each service
   kubectl logs -n my-service-dev deployment/my-service | grep trace_id
   ```
3. Verify HTTP headers are propagated (`traceparent`, `tracestate`)

### TraceQL Query Returns No Results

**Cause**: Incorrect query syntax or no matching traces.

**Solution**:

```traceql
# Start with broad query
{ }  # Returns all traces in time range

# Gradually narrow down
{resource.service.name = "payment-service"}

# Check attribute spelling and case sensitivity
{span.http.method = "POST"}  # Correct
{span.HTTP.Method = "POST"}  # Incorrect (case-sensitive)
```

### Trace Shows High Latency but No Bottleneck

**Cause**: Network latency or waiting between spans.

**Solution**:

1. Look for gaps in the waterfall view (time between spans)
2. Check for asynchronous operations or queued tasks
3. Verify inter-service network latency:
   ```bash
   # Test network latency between pods
   kubectl exec -n namespace1 pod1 -- curl -w "@curl-format.txt" -o /dev/null -s http://service2.namespace2.svc.cluster.local
   ```

## Next Steps

After mastering request tracing:

- [View DORA Metrics in DevLake](view-dora-metrics-devlake.md) - Analyze deployment performance
- [Configure Alerts](../../observability/centralized-logging.md) - Set up proactive monitoring
- [Optimize Performance](../../patterns/continuous-delivery.md) - Use trace data to improve latency
- [Instrument Custom Spans](../../observability/distributed-tracing.md#application-instrumentation) - Add custom tracing

## Related Documentation

- [Distributed Tracing with OpenTelemetry and Tempo](../../observability/distributed-tracing.md) - Architecture and setup
- [ADR-013: Distributed Tracing](../../adr/ADR-013%20distributed%20tracing.md) - Technical decisions
- [Centralized Logging](../../observability/centralized-logging.md) - Trace-to-logs correlation
- [Brown Belt Module: Observability](../../dojo/modules/brown-belt/module-13-observability.md) - Hands-on training
