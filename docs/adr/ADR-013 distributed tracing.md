# ADR-013: Distributed Tracing for Platform and Applications

## Status
Accepted

## Context

Modern distributed systems like the Fawkes platform consist of numerous interconnected services where a single user request may traverse multiple components:

**Typical Request Flow Examples**:
1. **Developer Portal Access**:
   - User → NGINX Ingress → Backstage → PostgreSQL
   - Backstage → GitHub API → ArgoCD API → Kubernetes API

2. **CI/CD Pipeline Execution**:
   - Git commit → Webhook → Jenkins → Docker build → Harbor push
   - Jenkins → SonarQube scan → ArgoCD trigger → Kubernetes deployment

3. **Application Deployment**:
   - ArgoCD → Git repository → Kubernetes API → Container runtime
   - Health checks → Prometheus → Grafana → Alert Manager

**Challenges Without Distributed Tracing**:
- Difficult to identify performance bottlenecks across services
- Cannot determine which service in chain causes latency
- Hard to correlate logs from different services for single request
- No visibility into service dependencies and call patterns
- Troubleshooting production issues requires manual log aggregation
- Cannot measure end-to-end request latency accurately
- Difficulty identifying cascading failures
- No insight into retry/timeout behaviors

**Requirements**:
- Trace requests across all platform services (Backstage, Jenkins, ArgoCD, Mattermost)
- Support for application tracing (polyglot: Java, Python, Node.js, Go)
- Low overhead (<5% performance impact)
- Open standards (OpenTelemetry preferred)
- Integration with existing observability stack (Prometheus, Grafana)
- Sampling strategies to control data volume
- Context propagation across async operations (queues, webhooks)
- Trace retention (7-30 days for analysis)
- Query and visualization capabilities
- Correlation with logs and metrics
- Works across Kubernetes namespaces and clusters

**Use Cases for Fawkes**:
1. **Platform Operations**: Trace deployment pipeline from git commit to running pod
2. **Performance Optimization**: Identify slow database queries or API calls
3. **Incident Response**: Quickly identify failing service in request chain
4. **Capacity Planning**: Understand service call patterns and volumes
5. **Dojo Learning**: Teach distributed systems concepts with real traces
6. **DORA Metrics**: Accurate lead time measurement (commit to deploy)

**Security & Privacy**:
- Traces must not contain sensitive data (passwords, tokens, PII)
- Access control for trace data by team/namespace
- Sampling to prevent excessive data collection
- Data retention policies for compliance

**Operational Constraints**:
- Must work with existing OpenTelemetry collector (from ADR-012)
- Should integrate with Grafana for unified observability
- Must support auto-instrumentation for common frameworks
- Low operational overhead (minimal configuration)
- Cost-effective storage for trace data

## Decision

We will use **Jaeger** as the distributed tracing backend, with **OpenTelemetry** as the instrumentation standard, creating a unified observability stack.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Application & Platform Services                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Backstage    │  │ Jenkins      │  │ ArgoCD       │          │
│  │ (OTel SDK)   │  │ (OTel Agent) │  │ (OTel SDK)   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ User App 1   │  │ User App 2   │  │ User App 3   │          │
│  │ (Java)       │  │ (Python)     │  │ (Node.js)    │          │
│  │ OTel Agent   │  │ OTel Agent   │  │ OTel Agent   │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                   │
│         └──────────────────┴──────────────────┘                  │
│                            │                                      │
│                            ▼ OTLP (gRPC/HTTP)                    │
│         ┌──────────────────────────────────────────┐            │
│         │ OpenTelemetry Collector (Daemonset)      │            │
│         │ - Receives spans via OTLP                 │            │
│         │ - Batching & sampling                     │            │
│         │ - Context propagation                     │            │
│         │ - Span enrichment (k8s metadata)          │            │
│         └──────────────┬───────────────────────────┘            │
│                        │                                          │
└────────────────────────┼──────────────────────────────────────────┘
                         │
                         ▼ Jaeger format
         ┌──────────────────────────────────────────┐
         │ Jaeger Collector (Service)               │
         │ - Validates spans                        │
         │ - Applies sampling policies              │
         │ - Writes to storage backend              │
         └──────────────┬───────────────────────────┘
                        │
                        ▼
         ┌──────────────────────────────────────────┐
         │ Storage Backend                          │
         │ ┌────────────────┐  ┌────────────────┐  │
         │ │ OpenSearch     │  │ Cassandra      │  │
         │ │ (MVP choice)   │  │ (Alternative)  │  │
         │ └────────────────┘  └────────────────┘  │
         │ - Trace data indexed                     │
         │ - 7-day retention (configurable)         │
         │ - Compressed storage                     │
         └──────────────┬───────────────────────────┘
                        │
                        ▼
         ┌──────────────────────────────────────────┐
         │ Jaeger Query Service (UI)                │
         │ - Search traces by service/operation     │
         │ - Visualize trace timelines              │
         │ - Dependency graphs                      │
         │ - Performance analytics                  │
         └──────────────┬───────────────────────────┘
                        │
                        ▼
         ┌──────────────────────────────────────────┐
         │ Grafana (via Jaeger Data Source)        │
         │ - Unified observability dashboard        │
         │ - Correlate traces with logs & metrics   │
         │ - Custom trace-based alerts              │
         └──────────────────────────────────────────┘
```

### Key Components

**1. OpenTelemetry SDKs/Agents** (Application Layer):
- **Auto-instrumentation**: Java, Python, Node.js, .NET, Go, Ruby
- **Manual instrumentation**: Custom spans for business logic
- **Context propagation**: W3C Trace Context headers
- **Sampling**: Configurable at application level

**2. OpenTelemetry Collector** (Already deployed from ADR-012):
- **Receiver**: OTLP (gRPC port 4317, HTTP port 4318)
- **Processor**: Batch processing, tail sampling, span enrichment
- **Exporter**: Jaeger (gRPC to Jaeger collector)
- **Kubernetes metadata**: Automatic pod/namespace/service labeling

**3. Jaeger Collector**:
- Receives spans from OpenTelemetry Collector
- Applies sampling strategies (adaptive, rate-limiting)
- Validates span data and enforces schemas
- Writes to OpenSearch backend

**4. Jaeger Query Service**:
- REST API for trace retrieval
- Web UI for trace visualization
- Service dependency graph generation
- Support for lookback queries (find similar slow traces)

**5. Storage - OpenSearch**:
- Reuses existing OpenSearch cluster (from ADR-011)
- Separate indices for traces (`jaeger-span-*`)
- 7-day retention (configurable to 30 days)
- Index templates for automatic management

**6. Grafana Integration**:
- Jaeger data source plugin
- Trace-to-log correlation (clicking span opens related logs)
- Trace-to-metrics correlation (RED metrics by trace)
- Exemplars (link from metric spike to example trace)

### Trace Context Propagation

**Standard**: W3C Trace Context (traceparent/tracestate headers)

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
             ││ └────────────── trace-id ──────────────┘ └─ span-id ─┘ │
             │└────────────────────────────────────────────────────────┘
             └─ version                                     trace-flags ┘

Example HTTP request:
GET /api/projects HTTP/1.1
Host: backstage.fawkes.example.com
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
```

**Propagation Across Services**:
1. Ingress creates root span, generates trace-id
2. Backstage receives trace-id, creates child span
3. Backstage calls GitHub API, propagates trace-id
4. All spans linked by trace-id in Jaeger

### Sampling Strategy

**Head-Based Sampling** (at application/collector):
- **Always Sample**: Error traces (status code 5xx)
- **Rate Limiting**: 100 traces/second per service (prevents overwhelming backend)
- **Probabilistic**: Sample 10% of normal traffic (1 in 10 requests)
- **Configurable by service**: Critical services 100%, others 10%

**Tail-Based Sampling** (at collector - optional):
- Keep all error traces
- Keep all slow traces (>1s duration)
- Sample 10% of successful fast traces

**Production Configuration**:
```yaml
# OpenTelemetry Collector - tail_sampling processor
tail_sampling:
  decision_wait: 10s  # Wait for all spans in trace
  num_traces: 100000  # Memory limit
  policies:
    - name: error-traces
      type: status_code
      status_code: {status_codes: [ERROR]}
    - name: slow-traces
      type: latency
      latency: {threshold_ms: 1000}
    - name: probabilistic-sample
      type: probabilistic
      probabilistic: {sampling_percentage: 10}
```

### Instrumentation Strategy

**Platform Services** (MVP):
1. **Backstage**: OpenTelemetry JavaScript SDK
2. **Jenkins**: OpenTelemetry Java Agent (no code changes)
3. **ArgoCD**: Native OTLP support (configuration only)
4. **NGINX Ingress**: OpenTelemetry module (creates root spans)
5. **Mattermost**: OpenTelemetry Go SDK

**Application Support** (for user workloads):
1. **Java**: OpenTelemetry Java Agent (auto-instrumentation)
   ```bash
   java -javaagent:/opt/opentelemetry-javaagent.jar \
        -Dotel.service.name=my-app \
        -Dotel.exporter.otlp.endpoint=http://otel-collector:4317 \
        -jar app.jar
   ```

2. **Python**: OpenTelemetry Python auto-instrumentation
   ```bash
   opentelemetry-instrument \
     --traces_exporter otlp \
     --service_name my-app \
     python app.py
   ```

3. **Node.js**: OpenTelemetry JS SDK
   ```javascript
   const { NodeSDK } = require('@opentelemetry/sdk-node');
   const sdk = new NodeSDK({
     serviceName: 'my-app',
     traceExporter: new OTLPTraceExporter()
   });
   sdk.start();
   ```

4. **Go**: OpenTelemetry Go SDK (manual instrumentation)
   ```go
   import "go.opentelemetry.io/otel"
   
   tracer := otel.Tracer("my-service")
   ctx, span := tracer.Start(ctx, "operation-name")
   defer span.End()
   ```

**Auto-Instrumentation via Kubernetes Operator** (Post-MVP):
- OpenTelemetry Operator auto-injects agents via mutating webhook
- Developers annotate pods: `instrumentation.opentelemetry.io/inject-java: "true"`
- Zero code changes required

### DORA Metrics Integration

**Lead Time for Changes** - Enhanced with tracing:
1. Webhook creates trace when commit pushed to main
2. Trace follows through: Jenkins build → Harbor push → ArgoCD sync → Pod running
3. Calculate exact end-to-end duration from trace timeline
4. More accurate than timestamp differencing (accounts for retries, waits)

**Change Failure Rate** - Trace-based detection:
- Identify failed deployments by error spans in deployment traces
- Correlate with rollback traces
- Tag traces with deployment result (success/failure)

**Mean Time to Restore** - Incident tracing:
- Create trace when incident detected (alert fires)
- Trace follows incident response: diagnosis → fix deployment → verification
- Measure actual restoration timeline with trace duration

### Integration with Existing Observability

**Trace-to-Metrics Correlation**:
```promql
# Find traces for requests with high latency
histogram_quantile(0.95, 
  rate(http_request_duration_seconds_bucket[5m])
) > 1

# Grafana displays exemplar traces for this metric
```

**Trace-to-Log Correlation**:
- Inject trace-id into application logs (structured logging)
```json
{
  "timestamp": "2024-12-07T10:15:30Z",
  "level": "ERROR",
  "message": "Database connection failed",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "service": "backstage"
}
```
- OpenSearch query by trace-id retrieves all logs for trace
- Grafana "Explore" view: click trace span → view logs

**Service Dependency Mapping**:
- Jaeger automatically generates service dependency graph from traces
- Shows call volume and error rates between services
- Updated in real-time as traces arrive
- Helps identify critical path and single points of failure

## Consequences

### Positive

1. **Complete Visibility**: End-to-end request tracing across all services
2. **Fast Troubleshooting**: Identify failing service in seconds vs. hours
3. **Performance Optimization**: Pinpoint exact bottleneck (slow DB query, external API)
4. **DORA Accuracy**: Precise lead time measurement from commit to production
5. **Unified Observability**: Trace-log-metric correlation in single Grafana view
6. **Standards-Based**: OpenTelemetry ensures vendor neutrality and broad support
7. **Low Barrier**: Auto-instrumentation requires minimal developer effort
8. **Educational Value**: Excellent teaching tool for distributed systems in dojo
9. **Service Mapping**: Auto-generated dependency graphs show architecture reality
10. **Cost Effective**: Open source stack, reuses OpenSearch storage

### Negative

1. **Storage Costs**: Traces consume significant storage (7-day retention ~500GB for medium platform)
2. **Performance Overhead**: 2-5% latency increase from span creation and propagation
3. **Complexity**: Additional component (Jaeger) to operate and maintain
4. **Sampling Tradeoffs**: 10% sampling means missing 90% of requests (may miss rare issues)
5. **Learning Curve**: Developers must understand spans, context propagation, sampling
6. **Data Volume**: High traffic services generate millions of spans per day
7. **Manual Instrumentation**: Custom business logic requires manual span creation
8. **Context Propagation**: Async operations (queues, workers) require careful header passing

### Neutral

1. **OpenSearch Dependency**: Reuses existing cluster, but adds index management complexity
2. **Jaeger vs. Alternatives**: Could use Tempo or Zipkin, but Jaeger more mature
3. **Sampling Required**: Cannot trace 100% of requests at scale (cost/performance prohibitive)
4. **Multi-Cluster**: Tracing across clusters requires federation (future consideration)

## Alternatives Considered

### Alternative 1: Grafana Tempo

**Pros**:
- Native Grafana integration (same vendor)
- Extremely cost-efficient (uses object storage)
- Simpler architecture (no separate query service)
- Scales to billions of spans
- Tag-based querying (no need for index)

**Cons**:
- Less mature than Jaeger (launched 2020 vs. 2015)
- Limited query capabilities (no full-text search)
- Requires external object storage (S3, GCS, Azure Blob)
- Smaller community and fewer integrations
- UI less polished than Jaeger

**Reason for Rejection**: While Tempo is promising, Jaeger's maturity, rich query capabilities, and built-in UI make it better for MVP. Tempo's strength (object storage efficiency) is less critical for Fawkes' scale. Can migrate to Tempo post-MVP if storage costs become issue.

### Alternative 2: Zipkin

**Pros**:
- Pioneer in distributed tracing (created by Twitter 2012)
- Simple architecture (fewer moving parts)
- Battle-tested at scale
- Multiple storage backends (MySQL, Cassandra, OpenSearch)
- Good documentation and examples

**Cons**:
- Less active development than Jaeger/Tempo
- UI feels dated compared to modern tools
- Limited advanced features (no tail sampling, basic analytics)
- OpenTelemetry support added later (not native)
- Smaller community momentum

**Reason for Rejection**: Zipkin is solid but feels "last generation." Jaeger has more momentum, better OpenTelemetry integration, and richer feature set. For educational platform, modern tooling is preferable.

### Alternative 3: Elastic APM

**Pros**:
- Integrated with Elastic Stack (logs, metrics, traces in one)
- Excellent UI and visualizations
- Powerful querying (Elasticsearch under hood)
- Machine learning anomaly detection
- Application performance monitoring features beyond tracing

**Cons**:
- **Licensing concerns**: Elastic License 2.0 (not open source)
- Vendor lock-in to Elastic ecosystem
- Higher resource requirements than Jaeger
- More complex architecture (APM Server + Elasticsearch + Kibana)
- Cost considerations for Elastic Cloud

**Reason for Rejection**: Elastic APM is feature-rich but introduces licensing concerns and vendor lock-in. Fawkes prioritizes open source (Apache 2.0) and cloud-agnostic tooling. Also conflicts with using OpenSearch (Elasticsearch fork) elsewhere.

### Alternative 4: AWS X-Ray / Cloud Provider Tracing

**Pros**:
- Fully managed (no infrastructure to maintain)
- Native cloud integration (Lambda, ECS, etc.)
- Built-in sampling and cost controls
- Tight integration with cloud services

**Cons**:
- **Cloud vendor lock-in** (violates Fawkes portability principle)
- Cannot run on-premises or in learner laptops
- Inconsistent across AWS/Azure/GCP
- Less suitable for teaching (managed service abstracts details)
- Cost unpredictable at scale

**Reason for Rejection**: Same reason as cloud ingress controllers (ADR-010). Fawkes must work anywhere. Dojo learners need local tracing stack. Platform teams need cloud-agnostic solution.

### Alternative 5: Lightstep / Honeycomb (Commercial SaaS)

**Pros**:
- Exceptional user experience
- Advanced features (Service Level Objectives, intelligent sampling)
- Minimal operational overhead (fully managed)
- Excellent performance at massive scale

**Cons**:
- **Commercial pricing** (cost prohibitive for open source project)
- Data leaves cluster (security/privacy concerns)
- Not self-hosted option
- Vendor lock-in
- Antithetical to Fawkes open source values

**Reason for Rejection**: Fawkes is open source platform for self-hosting. Commercial SaaS doesn't align with principles. Organizations using Fawkes can choose commercial observability, but platform itself must be self-contained.

### Alternative 6: OpenTelemetry Collector Only (No Backend)

**Pros**:
- Minimal complexity (already deploying OTel Collector)
- Export to any backend later
- No storage costs
- Flexible backend choice

**Cons**:
- **No trace visualization** (cannot view traces)
- No query capability (useless for troubleshooting)
- Defeats purpose of distributed tracing
- Cannot demonstrate value to learners
- DORA metrics incomplete without trace analysis

**Reason for Rejection**: Tracing without storage and visualization provides no value. Like installing Prometheus without Grafana. Backend is essential for distributed tracing ROI.

## Implementation Plan

### Phase 1: MVP (Week 6 of Sprint)

1. **Deploy Jaeger Components** [4 hours]
   - Install Jaeger Operator via Helm
   - Configure Jaeger instance with OpenSearch backend
   - Deploy Jaeger Query Service and UI
   - Configure Ingress (https://tracing.fawkes.example.com)

2. **Configure OpenTelemetry Collector** [2 hours]
   - Add Jaeger exporter to existing OTel Collector
   - Configure tail sampling processor
   - Test OTLP → Jaeger pipeline
   - Verify spans appearing in Jaeger UI

3. **Instrument NGINX Ingress** [2 hours]
   - Enable OpenTelemetry module
   - Configure to create root spans
   - Propagate trace context headers
   - Test end-to-end tracing

4. **Instrument Backstage** [3 hours]
   - Add OpenTelemetry JavaScript SDK
   - Configure OTLP exporter
   - Add custom spans for catalog operations
   - Test trace visualization

### Phase 2: Core Services (Week 7)

5. **Instrument Jenkins** [3 hours]
   - Deploy OpenTelemetry Java Agent
   - Configure Jenkins JVM parameters
   - Create spans for build stages
   - Test pipeline tracing

6. **Instrument ArgoCD** [2 hours]
   - Enable native OTLP export (if available)
   - OR configure OTel sidecar
   - Trace sync operations
   - Test deployment tracing

7. **Grafana Integration** [3 hours]
   - Add Jaeger data source to Grafana
   - Configure trace-to-log correlation
   - Add trace exemplars to metric dashboards
   - Create combined observability dashboard

### Phase 3: Application Support (Week 8)

8. **Create Auto-Instrumentation Guides** [4 hours]
   - Java application instrumentation guide
   - Python application instrumentation guide
   - Node.js application instrumentation guide
   - Go application instrumentation guide (manual)

9. **Deploy Sample Instrumented Apps** [3 hours]
   - Java Spring Boot with OTel agent
   - Python FastAPI with auto-instrumentation
   - Node.js Express with OTel SDK
   - Test cross-service tracing

10. **DORA Metrics Integration** [4 hours]
    - Create trace-based lead time calculator
    - Tag deployment traces with result
    - Integrate trace data into DORA dashboard
    - Test end-to-end measurement

### Phase 4: Documentation & Training (Week 9)

11. **Documentation** [6 hours]
    - Architecture overview with diagrams
    - Instrumentation best practices
    - Troubleshooting guide (common issues)
    - Query and visualization guide

12. **Dojo Module - Brown Belt** [4 hours]
    - Module: "Distributed Tracing & Observability"
    - Hands-on lab: Instrument custom application
    - Exercise: Debug slow request with traces
    - Assessment on tracing concepts

## Dojo Integration

### Brown Belt - Module 2: "Distributed Tracing & Observability"

**Learning Objectives**:
- Understand distributed tracing concepts (spans, traces, context propagation)
- Instrument applications with OpenTelemetry
- Use Jaeger UI to analyze traces and identify bottlenecks
- Correlate traces with logs and metrics
- Apply sampling strategies appropriately

**Hands-On Lab** (90 minutes):
1. **Setup**: Deploy pre-built microservices application (3 services)
2. **Problem**: Application is slow, identify bottleneck
3. **Instrument**: Add OpenTelemetry to each service
4. **Analyze**: Find slow database query in traces
5. **Fix**: Optimize query, verify improvement in traces
6. **Advanced**: Add custom spans for business operations

**Lab Architecture**:
```
┌──────────┐     ┌──────────┐     ┌──────────┐
│ Frontend │ ──> │ API      │ ──> │ Database │
│ (Node)   │     │ (Python) │     │ (Postgres│
└──────────┘     └──────────┘     └──────────┘
     │                │                 │
     └────────────────┴─────────────────┘
                      │
                      ▼
              Trace everything!
```

**Assessment**:
- Quiz on tracing concepts (10 questions)
- Practical: Debug performance issue using traces
- Code review: Evaluate instrumentation quality

## Monitoring & Operations

### Jaeger Health Metrics

Monitor via Prometheus:
```yaml
# Jaeger Collector metrics
jaeger_collector_spans_received_total
jaeger_collector_spans_saved_total
jaeger_collector_spans_dropped_total
jaeger_collector_queue_length

# Jaeger Query metrics
jaeger_query_requests_total
jaeger_query_latency_seconds
```

### Grafana Dashboard Panels

**Jaeger Operations Dashboard**:
1. Spans received per second (by service)
2. Span save success rate
3. Collector queue depth
4. Query latency (P95, P99)
5. Storage usage (OpenSearch indices)
6. Most traced services (top 10)
7. Sampling rate by service

### Alerting Rules

```yaml
groups:
- name: jaeger_alerts
  rules:
  - alert: HighSpanDropRate
    expr: rate(jaeger_collector_spans_dropped_total[5m]) / rate(jaeger_collector_spans_received_total[5m]) > 0.01
    for: 10m
    annotations:
      summary: "Jaeger dropping >1% of spans"
      description: "Check collector resources and storage backend"

  - alert: JaegerCollectorDown
    expr: up{job="jaeger-collector"} == 0
    for: 5m
    annotations:
      summary: "Jaeger Collector is down"
      
  - alert: HighQueryLatency
    expr: histogram_quantile(0.95, jaeger_query_latency_seconds_bucket) > 5
    for: 10m
    annotations:
      summary: "Jaeger Query P95 latency >5s"
```

### Operational Runbook

**Trace Data Volume Too High**:
1. Increase sampling percentage (reduce from 10% to 5%)
2. Apply tail sampling (keep only slow/error traces)
3. Reduce retention (7 days → 3 days)
4. Scale OpenSearch cluster (more data nodes)

**Missing Traces**:
1. Check OTel Collector exporter config (OTLP → Jaeger)
2. Verify Jaeger Collector receiving spans (Prometheus metrics)
3. Check application instrumentation (SDK configured?)
4. Verify sampling (maybe sampled out?)
5. Check network connectivity (firewall rules)

**Slow Trace Queries**:
1. Check OpenSearch cluster health (yellow/red status?)
2. Optimize indices (force merge, reindex)
3. Add more Jaeger Query replicas
4. Implement query caching

## Security Considerations

### Sensitive Data in Traces

**Problem**: Traces may inadvertently capture passwords, tokens, PII

**Mitigation**:
1. **Sanitize at source**: Remove sensitive fields before creating spans
   ```python
   # BAD
   span.set_attribute("sql.query", "SELECT * FROM users WHERE password='secret123'")
   
   # GOOD
   span.set_attribute("sql.query", "SELECT * FROM users WHERE password='[REDACTED]'")
   ```

2. **OTel Collector processor**: Scrub sensitive attributes
   ```yaml
   processors:
     attributes/sanitize:
       actions:
         - key: http.request.header.authorization
           action: delete
         - key: db.statement
           pattern: password=.*
           action: replace
           value: password=[REDACTED]
   ```

3. **Developer training**: Educate on what NOT to trace

### Access Control

**Jaeger UI**: Integrate with OAuth2 proxy (same as other platform services)
- Platform teams: Full access to all traces
- Application teams: Access to their namespace traces only (via Jaeger Query filters)

**Grafana**: Role-based access control
- Developers see traces for their services
- Platform SREs see all traces

### Data Retention

**Compliance**: 
- Default 7-day retention meets most needs
- Extend to 30 days for compliance (SOC 2 requires evidence retention)
- Automate deletion via OpenSearch ILM policies

## Cost Analysis

### Infrastructure Costs (AWS, Medium Platform)

**Jaeger Components**:
- Jaeger Collector (3 replicas): 1 CPU × 3 = $40/month
- Jaeger Query (2 replicas): 0.5 CPU × 2 = $13/month

**Storage** (OpenSearch):
- Trace data: ~500GB for 7-day retention at 10% sampling
- Cost: 500GB × $0.10/GB (GP3) = $50/month

**Network**:
- Data transfer (spans): Minimal (<$10/month, intra-VPC)

**Total Monthly Cost**: ~$113/month

**Cost Optimization**:
- Reduce sampling (10% → 5%) = 50% storage savings
- Shorter retention (7 days → 3 days) = 57% storage savings
- Use S3 for cold storage (>7 days) = 90% savings on old traces

### Cost Comparison

| Solution | Monthly Cost | Storage | Notes |
|----------|--------------|---------|-------|
| Jaeger + OpenSearch | $113 | 500GB | Self-hosted, full control |
| Grafana Tempo + S3 | $70 | Unlimited | Object storage efficient |
| Elastic APM | $200+ | 500GB | Enterprise features |
| Datadog APM | $500+ | Unlimited | SaaS, easy but expensive |
| AWS X-Ray | $150 | N/A | Managed, AWS-only |

## Documentation Structure

### For Platform Teams

1. **Architecture Guide**
   - Trace flow d
