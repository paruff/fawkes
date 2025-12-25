# ADR-013: Distributed Tracing for Platform and Applications

## Status
Accepted

## Context

The Fawkes platform consists of multiple interconnected services where a single user request may traverse numerous components:

**Platform Request Flows**:
- **Developer Portal Access**: User → NGINX Ingress → Backstage → PostgreSQL → GitHub API → ArgoCD API
- **CI/CD Pipeline**: Git Push → Jenkins Webhook → Jenkins Build → Harbor Push → ArgoCD Sync → Kubernetes Deployment
- **Dojo Learning**: User → Backstage → Lab Provisioning Service → Terraform → AWS API → Kubernetes API
- **Collaboration**: User → Mattermost → PostgreSQL → S3 (file storage) → Elasticsearch (search)
- **Deployment**: Developer → ArgoCD UI → Kubernetes API → Application Pods → Database

**Application Request Flows**:
- Microservice architectures with service-to-service calls
- Database queries across multiple services
- External API integrations
- Message queue processing
- Asynchronous job execution

**Troubleshooting Challenges Without Tracing**:
- **Latency Attribution**: "Why is this request slow?" - Which service is the bottleneck?
- **Error Root Cause**: "Where did this error originate?" - Which service in the chain failed?
- **Dependency Mapping**: "What services does this request touch?" - Understanding call paths
- **Performance Optimization**: "Which database queries are slow?" - Query-level visibility
- **Cascading Failures**: "Why are all services degraded?" - Tracing failure propagation
- **Cross-Team Debugging**: Multiple teams own services in a request path

**DORA Metrics Requirements**:
- **Lead Time for Changes**: Trace deployment pipeline from commit to production
- **Change Failure Rate**: Correlate failed deployments with application errors
- **Mean Time to Recovery**: Quickly identify root cause of incidents
- **Deployment Frequency**: Understand deployment pipeline performance

**Technical Requirements**:
- Support for multiple programming languages (Java, Python, Node.js, Go)
- Low overhead (<5% CPU, <100MB memory per service)
- Sampling strategies to control data volume
- Integration with existing observability (metrics, logs)
- Correlation IDs linking traces to logs
- Support for synchronous and asynchronous operations
- Trace context propagation across HTTP, gRPC, message queues
- Long-term trace storage for trend analysis
- Real-time trace querying for active troubleshooting

**Operational Requirements**:
- Automatic instrumentation where possible (minimal code changes)
- Manual instrumentation for custom spans
- Scalable backend (handle 100K+ spans/second)
- Data retention policy (7 days detailed, 30 days sampled, 90 days aggregated)
- Multi-tenancy (namespace/team isolation)
- Integration with Grafana for visualization
- Alert on trace-based SLIs (P95 latency, error rates)

**Security Requirements**:
- Sensitive data scrubbing (PII, credentials)
- Access control for trace data
- Encryption in transit and at rest
- Compliance with data retention policies

**Learning & Dojo Requirements**:
- Learners should understand distributed tracing concepts
- Hands-on labs demonstrating tracing implementation
- Troubleshooting exercises using traces
- Integration with Brown Belt (Observability & SRE) curriculum

## Decision

We will use **Grafana Tempo** as the distributed tracing backend, integrated with **OpenTelemetry** for instrumentation and trace collection.

### Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│  Applications & Platform Services                                │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐  ┌──────────┐  │
│  │ Backstage  │  │ Jenkins    │  │ ArgoCD     │  │ Custom   │  │
│  │ (Node.js)  │  │ (Java)     │  │ (Go)       │  │ Apps     │  │
│  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘  └────┬─────┘  │
│        │               │               │              │         │
│        │ OpenTelemetry SDK instrumentation           │         │
│        └───────────────┴───────────────┴──────────────┘         │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │ OTLP (gRPC/HTTP)
                               │
┌──────────────────────────────┼───────────────────────────────────┐
│  Kubernetes Cluster          │                                   │
│                              ▼                                   │
│  ┌────────────────────────────────────────────────┐             │
│  │ OpenTelemetry Collector (DaemonSet/Deployment) │             │
│  │ - Receives traces via OTLP                     │             │
│  │ - Batching and buffering                       │             │
│  │ - Sampling strategies                          │             │
│  │ - Tail-based sampling (intelligent)            │             │
│  │ - Attribute processing and enrichment          │             │
│  │ - Sensitive data scrubbing                     │             │
│  └──────────────────────┬─────────────────────────┘             │
│                         │                                        │
│                         ▼                                        │
│  ┌──────────────────────────────────────┐                       │
│  │ Grafana Tempo (Trace Storage)        │                       │
│  │ - Object storage backend (S3/MinIO)  │                       │
│  │ - Block-based columnar storage       │                       │
│  │ - TraceQL query language             │                       │
│  │ - Multi-tenancy support              │                       │
│  └──────────────────────┬───────────────┘                       │
│                         │                                        │
│                         ▼                                        │
│  ┌──────────────────────────────────────┐                       │
│  │ Grafana (Visualization)              │                       │
│  │ - Trace search and visualization     │                       │
│  │ - Trace-to-logs correlation          │                       │
│  │ - Trace-to-metrics correlation       │                       │
│  │ - Service dependency graphs          │                       │
│  │ - RED metrics from traces            │                       │
│  └──────────────────────────────────────┘                       │
└───────────────────────────────────────────────────────────────────┘

┌───────────────────────────────────────────────────────────────────┐
│  Integration with Observability Stack                            │
│                                                                   │
│  Tempo ←→ Prometheus (Exemplars link metrics to traces)         │
│  Tempo ←→ Loki (Trace IDs in logs for correlation)              │
│  Tempo ←→ Grafana (Unified visualization)                        │
└───────────────────────────────────────────────────────────────────┘
```

### Technology Stack

**Instrumentation**: OpenTelemetry SDKs
- **Java**: `opentelemetry-java-instrumentation` (auto-instrumentation agent)
- **Python**: `opentelemetry-distro` with `opentelemetry-instrumentation`
- **Node.js**: `@opentelemetry/sdk-node` with auto-instrumentation
- **Go**: `go.opentelemetry.io/otel` with manual instrumentation

**Collection**: OpenTelemetry Collector
- Deployed as DaemonSet (node-level collection)
- Deployed as Deployment (centralized processing)
- OTLP receivers (gRPC and HTTP)
- Tail-based sampling processor
- Batch processor for efficiency

**Storage**: Grafana Tempo
- Backend: S3-compatible object storage (AWS S3, MinIO)
- Retention: 7 days full detail, 30 days sampled
- Compression: Snappy/LZ4 for cost efficiency
- Ingestion rate: 100K+ spans/second

**Visualization**: Grafana
- Tempo data source integration
- TraceQL query builder
- Node graph visualization
- Trace comparison tools

### OpenTelemetry Instrumentation Strategy

**Automatic Instrumentation** (Preferred for rapid adoption):

**Java Applications (Jenkins plugins, Spring Boot apps)**:
```bash
# Download OpenTelemetry Java agent
wget https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/latest/download/opentelemetry-javaagent.jar

# Add to JVM arguments
java -javaagent:opentelemetry-javaagent.jar \
     -Dotel.service.name=jenkins \
     -Dotel.exporter.otlp.endpoint=http://otel-collector:4317 \
     -jar jenkins.war
```

**Python Applications (FastAPI, Django)**:
```bash
# Install OpenTelemetry distro
pip install opentelemetry-distro opentelemetry-exporter-otlp

# Auto-instrument
opentelemetry-bootstrap -a install
opentelemetry-instrument \
  --service_name my-python-app \
  --exporter_otlp_endpoint http://otel-collector:4317 \
  python app.py
```

**Node.js Applications (Backstage, Express)**:
```javascript
// app.js - Add at the very top
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');

const sdk = new NodeSDK({
  serviceName: 'backstage',
  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector:4318/v1/traces',
  }),
  instrumentations: [getNodeAutoInstrumentations()],
});

sdk.start();
```

**Manual Instrumentation** (For custom spans):

**Go Example (ArgoCD, custom controllers)**:
```go
import (
    "go.opentelemetry.io/otel"
    "go.opentelemetry.io/otel/trace"
)

func processDeployment(ctx context.Context, app string) error {
    tracer := otel.Tracer("argocd")
    ctx, span := tracer.Start(ctx, "process-deployment",
        trace.WithAttributes(
            attribute.String("app.name", app),
            attribute.String("namespace", "default"),
        ),
    )
    defer span.End()

    // Business logic here
    if err := syncApplication(ctx, app); err != nil {
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
        return err
    }

    return nil
}
```

### OpenTelemetry Collector Configuration

**DaemonSet Deployment** (for application traces):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: otel-collector-config
  namespace: fawkes-observability
data:
  config.yaml: |
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

      # Tail-based sampling - keep all errors, sample successes
      tail_sampling:
        decision_wait: 10s
        num_traces: 100
        expected_new_traces_per_sec: 10
        policies:
          - name: errors
            type: status_code
            status_code: {status_codes: [ERROR]}
          - name: slow-requests
            type: latency
            latency: {threshold_ms: 1000}
          - name: probabilistic-sampling
            type: probabilistic
            probabilistic: {sampling_percentage: 10}

      # Add Kubernetes metadata
      k8sattributes:
        auth_type: "serviceAccount"
        passthrough: false
        extract:
          metadata:
            - k8s.pod.name
            - k8s.pod.uid
            - k8s.deployment.name
            - k8s.namespace.name
            - k8s.node.name

      # Scrub sensitive data
      attributes:
        actions:
          - key: http.request.header.authorization
            action: delete
          - key: http.request.header.cookie
            action: delete
          - key: db.statement
            action: hash

    exporters:
      otlp:
        endpoint: tempo:4317
        tls:
          insecure: true

      # Also export to Prometheus for exemplars
      prometheus:
        endpoint: 0.0.0.0:8889

    service:
      pipelines:
        traces:
          receivers: [otlp]
          processors: [k8sattributes, tail_sampling, attributes, batch]
          exporters: [otlp]

        metrics:
          receivers: [otlp]
          processors: [batch]
          exporters: [prometheus]
```

### Grafana Tempo Configuration

**Deployment Manifest**:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tempo-config
  namespace: fawkes-observability
data:
  tempo.yaml: |
    server:
      http_listen_port: 3200

    distributor:
      receivers:
        otlp:
          protocols:
            grpc:
              endpoint: 0.0.0.0:4317
            http:
              endpoint: 0.0.0.0:4318

    ingester:
      trace_idle_period: 10s
      max_block_bytes: 1_000_000
      max_block_duration: 5m

    compactor:
      compaction:
        block_retention: 168h  # 7 days

    storage:
      trace:
        backend: s3
        s3:
          bucket: fawkes-tempo-traces
          endpoint: s3.amazonaws.com
          region: us-east-1
        wal:
          path: /var/tempo/wal
        pool:
          max_workers: 100
          queue_depth: 10000

    overrides:
      defaults:
        metrics_generator:
          processors: [service-graphs, span-metrics]
          storage:
            path: /var/tempo/generator/wal
            remote_write:
              - url: http://prometheus:9090/api/v1/write
                send_exemplars: true
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: tempo
  namespace: fawkes-observability
spec:
  serviceName: tempo
  replicas: 3
  selector:
    matchLabels:
      app: tempo
  template:
    metadata:
      labels:
        app: tempo
    spec:
      containers:
      - name: tempo
        image: grafana/tempo:latest
        args:
          - -config.file=/etc/tempo/tempo.yaml
        ports:
        - containerPort: 3200
          name: http
        - containerPort: 4317
          name: otlp-grpc
        - containerPort: 4318
          name: otlp-http
        volumeMounts:
        - name: config
          mountPath: /etc/tempo
        - name: storage
          mountPath: /var/tempo
        resources:
          requests:
            cpu: 500m
            memory: 1Gi
          limits:
            cpu: 2000m
            memory: 4Gi
      volumes:
      - name: config
        configMap:
          name: tempo-config
  volumeClaimTemplates:
  - metadata:
      name: storage
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 100Gi
```

### Trace Correlation with Logs

**Log Entry with Trace Context**:
```json
{
  "timestamp": "2024-12-07T10:30:45Z",
  "level": "ERROR",
  "message": "Failed to sync application",
  "service": "argocd",
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id": "00f067aa0ba902b7",
  "trace_flags": "01",
  "namespace": "production",
  "app_name": "payment-service"
}
```

**Loki Configuration for Trace Correlation**:
```yaml
# Grafana data source configuration
apiVersion: 1
datasources:
  - name: Loki
    type: loki
    uid: loki
    url: http://loki:3100
    jsonData:
      derivedFields:
        - datasourceUid: tempo
          matcherRegex: "trace_id=(\\w+)"
          name: TraceID
          url: "$${__value.raw}"
```

### Grafana Dashboard Configuration

**Service Dependency Graph**:
- Automatically generated from trace data
- Shows request flow between services
- Color-coded by error rate
- Size proportional to request volume

**TraceQL Queries**:

**Find slow database queries**:
```traceql
{span.db.system="postgresql" && duration > 1s}
```

**Find all traces with errors in production**:
```traceql
{status=error && resource.namespace="production"}
```

**Find traces for specific user**:
```traceql
{resource.service.name="backstage" && span.http.route="/api/catalog/*" && trace.user.id="alice@example.com"}
```

**Deployment trace (commit to production)**:
```traceql
{resource.service.name="jenkins" || resource.service.name="argocd"}
  | {span.git.commit.sha="abc123def"}
```

### Sampling Strategies

**Head-Based Sampling** (at application):
- 100% of errors
- 100% of requests > 1 second
- 10% of successful requests < 1 second

**Tail-Based Sampling** (at collector):
- Keep all traces with errors
- Keep all traces with latency > P95
- Keep traces matching specific criteria (user ID, request path)
- Sample remaining traces at 10%

**Cost Optimization**:
- Production: 10% sampling → ~50GB/day traces
- Staging: 50% sampling → ~20GB/day traces
- Development: 100% sampling → ~5GB/day traces

### DORA Metrics Integration

**Lead Time for Changes Tracing**:
1. Git commit event → creates trace context
2. Jenkins build → child span with commit SHA
3. Docker build → child span with image tag
4. Harbor push → child span with artifact metadata
5. ArgoCD sync → child span with deployment details
6. Application start → final span with health check

**Query to calculate lead time**:
```traceql
{span.git.commit.sha="abc123"}
  | {span.name="deploy-to-production"}
```

**Change Failure Rate**:
- Trace deployments with `deployment.status=failed`
- Correlate with application error traces
- Generate failure rate dashboard

**Mean Time to Recovery**:
- Incident start → trace ID in alert
- Trace investigation → linked troubleshooting actions
- Incident resolution → final span
- Calculate MTTR from trace duration

### Security & Privacy

**Sensitive Data Scrubbing**:
```yaml
# OpenTelemetry Collector processor
processors:
  attributes:
    actions:
      # Remove authorization headers
      - key: http.request.header.authorization
        action: delete

      # Hash SQL statements (preserve structure, hide values)
      - key: db.statement
        action: hash

      # Redact email addresses
      - key: user.email
        action: update
        value: "REDACTED"

      # Remove credit card numbers from URLs
      - key: http.url
        action: update
        from_attribute: http.url
        pattern: '\d{4}-\d{4}-\d{4}-\d{4}'
        value: 'XXXX-XXXX-XXXX-XXXX'
```

**Access Control**:
- Grafana RBAC for trace viewing
- Namespace-based trace isolation
- Tempo multi-tenancy (tenant ID from namespace)

### Performance Impact

**Benchmarks** (per-service overhead):
- **CPU**: 2-5% increase
- **Memory**: 50-100MB increase
- **Network**: ~1KB per span (compressed)
- **Latency**: <1ms per instrumented operation

**Production Optimizations**:
- Use tail-based sampling
- Batch span exports (10s intervals)
- Compress spans before export
- Use gRPC for OTLP (more efficient than HTTP)

## Consequences

### Positive

1. **Root Cause Analysis**: Quickly identify bottlenecks across distributed services
2. **Performance Optimization**: Data-driven latency improvements
3. **Dependency Visualization**: Automatic service dependency mapping
4. **Error Attribution**: Precise identification of failing services
5. **DORA Metrics**: End-to-end deployment pipeline visibility
6. **Cross-Team Collaboration**: Shared visibility into request flows
7. **Unified Observability**: Traces linked to metrics and logs
8. **Cost-Effective**: Tempo uses object storage (~$10/TB/month vs. $100+ for commercial solutions)
9. **Vendor-Neutral**: OpenTelemetry standard, not locked to Tempo
10. **Learning-Friendly**: Clear visualization helps dojo learners understand distributed systems

### Negative

1. **Learning Curve**: Teams must understand tracing concepts and instrumentation
2. **Storage Costs**: Trace data requires significant storage (~50GB/day for production)
3. **Instrumentation Effort**: Applications require SDK integration
4. **Sampling Complexity**: Tail-based sampling configuration requires tuning
5. **Performance Overhead**: 2-5% CPU overhead per service
6. **Cardinality Challenges**: High-cardinality attributes can degrade performance

### Neutral

1. **Tempo Maturity**: Tempo is newer than Jaeger/Zipkin but rapidly maturing
2. **TraceQL Learning**: New query language to learn (though similar to LogQL/PromQL)
3. **Object Storage Dependency**: Requires S3-compatible storage

## Alternatives Considered

### Alternative 1: Jaeger

**Pros**:
- CNCF graduated project, very mature
- Excellent UI with service dependency graphs
- Strong community and documentation
- Battle-tested in production
- Built-in sampling strategies
- Supports multiple storage backends (Cassandra, Elasticsearch, Badger)

**Cons**:
- Higher operational complexity (requires Elasticsearch or Cassandra for scale)
- Higher storage costs (~5x more than Tempo for equivalent data)
- Less integration with Grafana (requires separate UI)
- No native metrics generation from traces
- Elasticsearch/Cassandra adds infrastructure overhead

**Reason for Rejection**: Operational complexity and storage costs. Tempo's integration with Grafana provides unified observability, and object storage backend is significantly cheaper than Elasticsearch. Jaeger's maturity is valuable, but Tempo's simplicity better suits Fawkes' goals.

### Alternative 2: Zipkin

**Pros**:
- Original distributed tracing system, very mature
- Simple architecture, easy to deploy
- Low resource requirements
- Multiple language SDK support
- Compatible with OpenTelemetry

**Cons**:
- Less feature-rich than modern alternatives
- No native Grafana integration
- Limited query capabilities
- In-memory storage default (poor retention)
- Requires Elasticsearch for production (added complexity)
- Smaller active community compared to CNCF projects

**Reason for Rejection**: While simple, Zipkin lacks modern features like TraceQL queries, Grafana integration, and metrics generation. Tempo provides better long-term value with similar deployment simplicity.

### Alternative 3: AWS X-Ray

**Pros**:
- Fully managed service (no infrastructure to maintain)
- Native AWS integration (Lambda, ECS, EC2)
- Automatic instrumentation for AWS services
- Low operational overhead
- Pay-per-use pricing

**Cons**:
- **Cloud vendor lock-in** (AWS only)
- No multi-cloud support
- Limited customization
- Higher costs at scale (~$5/million traces)
- Cannot run on-premises or in dojo labs
- Separate UI from other observability tools

**Reason for Rejection**: Violates Fawkes' cloud-agnostic principle. Learners need portable skills, not cloud-specific tools. X-Ray's managed benefits don't outweigh lock-in costs.

### Alternative 4: Elastic APM

**Pros**:
- Integrated with Elastic Stack (logs, metrics, traces in one UI)
- Excellent UI and visualization
- Strong Java and Node.js support
- Machine learning for anomaly detection
- Good documentation

**Cons**:
- Requires Elasticsearch cluster (high resource usage)
- Complex scaling and tuning
- Higher costs (compute + storage)
- OpenTelemetry support is secondary (Elastic APM agents preferred)
- Not CNCF/vendor-neutral

**Reason for Rejection**: Elasticsearch operational complexity and costs. Fawkes already uses Grafana for visualization, so Elastic APM adds redundancy. Tempo + Grafana provides equivalent value with lower operational burden.

### Alternative 5: Lightstep / Honeycomb / Datadog APM (Commercial SaaS)

**Pros**:
- Best-in-class UX and query capabilities
- Advanced sampling and trace analysis
- Fully managed (zero operational burden)
- Superior support and documentation
- Advanced features (BubbleUp, trace comparison, service catalog)

**Cons**:
- **Very high costs** ($100-500/month per host)
- SaaS-only (not self-hosted)
- Data sent to third-party
- Cannot use in air-gapped or on-premises environments
- Not suitable for learner environments (cost prohibitive)

**Reason for Rejection**: Cost prohibitive for open-source platform. Learners cannot use these tools without organization sponsorship. Self-hosted Tempo provides 90% of functionality at 5% of cost.

### Alternative 6: No Distributed Tracing (Logs + Metrics Only)

**Pros**:
- Lower complexity
- Smaller operational footprint
- Existing tools (Loki, Prometheus) sufficient
- No additional instrumentation required

**Cons**:
- **Cannot trace requests across services** (critical gap)
- Debugging distributed systems is extremely difficult
- No service dependency visualization
- Cannot calculate accurate DORA lead time metrics
- Poor learner experience (can't see end-to-end flows)

**Reason for Rejection**: Distributed tracing is essential for modern microservices platforms. DORA State of DevOps research shows observability (including tracing) strongly correlates with elite performance. Omitting tracing would cripple platform effectiveness.

## Implementation Plan

### Phase 1: Foundation (Week 6, Days 1-2)

**Day 1: OpenTelemetry Collector Deployment** [4 hours]
1. Deploy OpenTelemetry Collector as DaemonSet
2. Configure OTLP receivers (gRPC + HTTP)
3. Set up batch and tail-sampling processors
4. Test with sample trace data
5. Verify Prometheus metrics export

**Day 2: Grafana Tempo Deployment** [4 hours]
1. Deploy Tempo StatefulSet (3 replicas)
2. Configure S3/MinIO backend storage
3. Set up retention policies
4. Configure Grafana data source
5. Test trace ingestion and querying

### Phase 2: Platform Service Instrumentation (Week 6, Days 3-5)

**Day 3: Backstage Tracing** [3 hours]
1. Add OpenTelemetry Node.js SDK to Backstage
2. Configure auto-instrumentation
3. Test trace collection for catalog API calls
4. Add custom spans for plugin operations
5. Verify Grafana visualization

**Day 4: Jenkins & ArgoCD Tracing** [4 hours]
1. Jenkins: Add OpenTelemetry Java agent to JVM
2. Configure trace export for pipeline execution
3. ArgoCD: Manual Go instrumentation for sync operations
4. Test deployment trace (Jenkins → ArgoCD)
5. Create Grafana dashboard for CI/CD traces

**Day 5: Ingress & Database Tracing** [3 hours]
1. NGINX Ingress: Configure trace propagation headers
2. PostgreSQL: Add pg_stat_statements for query tracing
3. Test end-to-end trace (User → NGINX → Backstage → PostgreSQL)
4. Validate trace-to-log correlation

### Phase 3: Application Instrumentation Templates (Week 7, Days 1-2)

**Day 1: Create Language-Specific Templates** [4 hours]
1. Java Spring Boot template with OTel auto-instrumentation
2. Python FastAPI template with OTel SDK
3. Node.js Express template with OTel SDK
4. Go template with manual instrumentation
5. Document instrumentation patterns

**Day 2: Golden Path Integration** [4 hours]
1. Update Backstage templates with OTel dependencies
2. Add Dockerfile entries for OTel agents
3. Update Helm charts with OTel environment variables
4. Create CI/CD pipeline checks for instrumentation
5. Test end-to-end application deployment with tracing

### Phase 4: Observability Integration (Week 7, Days 3-5)

**Day 3: Trace-to-Metrics Integration** [3 hours]
1. Configure Tempo metrics generator
2. Send exemplars to Prometheus
3. Create Grafana dashboard linking metrics to traces
4. Add "View Trace" links from Prometheus alerts

**Day 4: Trace-to-Logs Integration** [3 hours]
1. Configure Loki derived fields for trace IDs
2. Update application logging to include trace context
3. Test correlation (click trace ID in logs → opens trace in Tempo)
4. Create unified dashboard with logs + traces

**Day 5: DORA Metrics Tracing** [4 hours]
1. Instrument deployment pipeline with trace context
2. Track commit SHA through build → deploy → release
3. Calculate lead time from traces
4. Create DORA dashboard with trace links

### Phase 5: Performance & Optimization (Week 8, Days 1-2)

**Day 1: Sampling Optimization** [3 hours]
1. Analyze trace volumes and costs
2. Tune tail-based sampling policies
3. Implement adaptive sampling based on load
4. Verify sample representativeness
5. Document sampling strategies

**Day 2: Performance Testing** [3 hours]
1. Load test with tracing enabled (measure overhead)
2. Benchmark trace ingestion rates
3. Test Tempo query performance
4. Optimize collector configurations
5. Document performance baseline

### Phase 6: Documentation & Training (Week 8, Days 3-5)

**Day 3: Platform Documentation** [4 hours]
1. Architecture overview with data flow diagrams
2. Instrumentation guide for each language
3. TraceQL query examples and cookbook
4. Troubleshooting guide
5. Runbook for Tempo operations

**Day 4: Dojo Module - Brown Belt** [4 hours]
1. Module: "Distributed Tracing for Microservices"
2. Theory: Trace context, spans, sampling
3. Hands-on lab: Instrument sample app, query traces
4. Troubleshooting exercise: Debug slow request
5. Assessment quiz on tracing concepts

**Day 5: Dashboard & Playbooks** [4 hours]
1. Create standard Grafana dashboards:
   - Service dependency graph
   - Request latency heatmap
   - Error rate by service
   - Deployment trace timeline
2. Create troubleshooting playbooks
3. Document common trace patterns
4. Create video walkthrough (15 minutes)

## Dojo Integration

### Brown Belt - Module 6: "Distributed Tracing & Request Flow Analysis"

**Learning Objectives**:
- Understand distributed tracing concepts (spans, traces, context propagation)
- Implement OpenTelemetry instrumentation in applications
- Query traces using TraceQL
- Correlate traces with metrics and logs
- Debug performance issues using distributed tracing
- Calculate DORA lead time metrics from traces

**Hands-On Lab** (90 minutes):

**Part 1: Instrument a Microservice** (30 min)
1. Deploy sample 3-tier app (frontend → API → database)
2. Add OpenTelemetry SDK to each service
3. Configure trace export to Tempo
4. Generate traffic and view traces in Grafana
5. Observe request flow across services

**Part 2: Advanced Querying** (30 min)
1. Write TraceQL queries to find:
   - Slow database queries
   - Requests with errors
   - Specific user journeys
   - Deployment traces
2. Create custom Grafana dashboard
3. Set up trace-based alerts

**Part 3: Troubleshooting Exercise** (30 min)
- **Scenario**: Application experiencing intermittent slowness
- **Task**: Use traces to identify:
  - Which service is the bottleneck
  - Slow database queries
  - External API latency
  - Network issues
- **Deliverable**: Root cause analysis report with trace evidence

**Assessment**:
- Quiz: 10 questions on tracing concepts
- Practical: Instrument new service and create dashboard
- Troubleshooting: Debug broken trace (missing context propagation)

**Time**: 2 hours (30 min theory + 90 min hands-on + assessment)

## Monitoring & Observability

### Tempo Health Metrics

**Key Metrics to Monitor**:
- `tempo_ingester_bytes_received_total` - Trace ingestion rate
- `tempo_ingester_blocks_flushed_total` - Block flush rate
- `tempo_query_frontend_result_metrics_inspected_bytes` - Query performance
- `tempo_distributor_spans_received_total` - Span reception rate
- `tempo_compactor_blocks_compacted_total` - Compaction health

**Grafana Dashboard**: "Tempo Operations"
- Ingestion rate by tenant
- Query latency (P50, P95, P99)
- Storage usage and growth
- Compaction lag
- Error rates

**Alerting Rules**:
```yaml
groups:
- name: tempo_alerts
  rules:
  - alert: TempoHighIngestionErrors
    expr: rate(tempo_distributor_spans_received_total{status="error"}[5m]) > 100
    for: 10m
    annotations:
      summary: "High trace ingestion error rate"

  - alert: TempoHighQueryLatency
    expr: histogram_quantile(0.95, tempo_query_frontend_duration_seconds_bucket) > 10
    for: 5m
    annotations:
      summary: "Tempo query latency P95 > 10s"

  - alert: TempoStorageUsageHigh
    expr: tempo_ingester_bytes_metric_total > 100e9  # 100GB
    annotations:
      summary: "Tempo ingester storage usage high"
```

### OpenTelemetry Collector Health

**Key Metrics**:
- `otelcol_receiver_accepted_spans` - Spans received
- `otelcol_receiver_refused_spans` - Spans refused (backpressure)
- `otelcol_processor_batch_batch_send_size` - Batch sizes
- `otelcol_exporter_sent_spans` - Spans successfully exported
- `otelcol_exporter_send_failed_spans` - Export failures

**Dashboard**: "OpenTelemetry Collector Health"
- Span throughput (in/out)
- Processor queue depth
- Export success/failure rates
- Memory usage by component

## Security Considerations

### Data Privacy

**Sensitive Data Scrubbing**:
- Remove authorization headers
- Hash SQL statements
- Redact PII from URLs and headers
- Obfuscate API keys in trace attributes

**Access Control**:
- Grafana RBAC for trace viewing
- Namespace-based trace isolation (teams only see their traces)
- Audit logging for trace access

### Compliance

**Data Retention**:
- 7 days detailed traces (compliance with GDPR "right to be forgotten")
- 30 days sampled traces
- Automated deletion after retention period

**Encryption**:
- TLS for all trace transmission (OTLP over gRPC/HTTPS)
- S3 server-side encryption for stored traces
- No plaintext credentials in trace attributes

## Cost Analysis

### Storage Costs (Production)

**Assumptions**:
- 100 services generating traces
- 1,000 requests/second average
- 10 spans per trace average
- 10% sampling rate (tail-based)
- ~1KB per span (compressed)

**Daily Trace Volume**:
- Raw spans: 100 services × 1,000 req/s × 10 spans × 86,400 s = 86.4 billion spans/day
- After sampling: 8.64 billion spans/day
- Storage: 8.64B spans × 1KB = 8.64 TB/day (before compression)
- After compression (10:1): ~864 GB/day

**Monthly Storage (7-day retention)**:
- 864 GB/day × 7 days = 6 TB active storage
- S3 Standard: $0.023/GB = $138/month
- S3 Intelligent-Tiering (after 7 days): $0.0125/GB = $75/month

**Total Monthly Cost**: ~$213/month (vs. $5,000+/month for commercial APM at 100 services)

**Cost Optimization**:
- Increase sampling rate in non-production (less cost-sensitive)
- Use S3 Lifecycle policies to move old traces to Glacier
- Tune tail-based sampling to focus on valuable traces
- Compress spans aggressively (Snappy → LZ4)

### Infrastructure Costs

**Tempo Pods**:
- 3 replicas × 2 CPU × $0.04/CPU/hour = $5.76/day = $173/month
- 3 replicas × 4GB RAM × $0.005/GB/hour = $1.44/day = $43/month

**OpenTelemetry Collector**:
- DaemonSet (1 per node, 10 nodes): 10 × 0.1 CPU × $0.04 = $0.96/day = $29/month
- DaemonSet memory: 10 × 128MB × $0.005/GB/hour = negligible

**Total Infrastructure**: ~$245/month

**Grand Total**: ~$458/month for distributed tracing (100 services, production scale)

## Documentation Structure

### For Platform Teams

1. **Architecture & Design**
   - Trace collection flow
   - Sampling strategies explained
   - Storage architecture (S3 layout)
   - Query performance optimization

2. **Deployment Guide**
   - Helm chart installation (Tempo, OTel Collector)
   - Cloud-specific configurations (AWS, Azure, GCP)
   - Scaling guidelines
   - Backup and disaster recovery

3. **Operations Runbook**
   - Common troubleshooting scenarios
   - Tempo upgrade procedures
   - Storage management (compaction, cleanup)
   - Performance tuning guide

### For Application Teams

1. **Instrumentation Guide**
   - Language-specific SDKs (Java, Python, Node.js, Go)
   - Auto vs. manual instrumentation
   - Custom span creation
   - Best practices (span naming, attributes)

2. **Querying & Troubleshooting**
   - TraceQL query cookbook
   - Common debugging patterns
   - Grafana dashboard usage
   - Trace-to-logs/metrics correlation

3. **Performance Impact**
   - Overhead benchmarks
   - Sampling recommendations
   - Optimization techniques

### For Dojo Learners

1. **Concepts Tutorial**
   - What is distributed tracing?
   - Spans, traces, and context propagation
   - When to use tracing vs. logs/metrics
   - Real-world use cases

2. **Hands-On Labs**
   - Lab 1: Instrument a simple app
   - Lab 2: Query traces with TraceQL
   - Lab 3: Debug performance issue
   - Lab 4: Trace a deployment pipeline

3. **Reference Materials**
   - OpenTelemetry SDK quick reference
   - TraceQL cheat sheet
   - Common trace patterns
   - Troubleshooting decision tree

## Related Decisions

- **ADR-011**: Centralized Log Management (Loki) - Trace-to-log correlation via trace IDs
- **ADR-012**: Metrics Monitoring (Prometheus/Grafana) - Exemplars link metrics to traces
- **ADR-002**: Backstage for Developer Portal - Primary UI instrumentation
- **ADR-004**: Jenkins for CI/CD - Pipeline trace instrumentation
- **ADR-003**: ArgoCD for GitOps - Deployment trace instrumentation
- **Future ADR**: Service Mesh (Istio) - Alternative instrumentation via sidecar proxies

## References

- OpenTelemetry Documentation: https://opentelemetry.io/docs/
- Grafana Tempo Documentation: https://grafana.com/docs/tempo/
- TraceQL Language Reference: https://grafana.com/docs/tempo/latest/traceql/
- CNCF Distributed Tracing Best Practices: https://github.com/cncf/tag-observability
- Distributed Tracing Patterns (book) by Austin Parker
- OpenTelemetry Best Practices: https://opentelemetry.io/docs/concepts/instrumentation/

## Notes

**Production Readiness Checklist**:
- [ ] Tempo deployed with 3+ replicas for HA
- [ ] S3/MinIO backend configured with proper retention
- [ ] OpenTelemetry Collector deployed (DaemonSet + Deployment)
- [ ] Tail-based sampling configured and tested
- [ ] Grafana data source configured with Tempo
- [ ] Trace-to-logs correlation working (Loki derived fields)
- [ ] Trace-to-metrics correlation working (Prometheus exemplars)
- [ ] Sensitive data scrubbing verified
- [ ] Performance benchmarks completed (overhead < 5%)
- [ ] Monitoring dashboards created
- [ ] Alerting rules configured
- [ ] Documentation complete
- [ ] Team trained on querying and troubleshooting

**Learner Environment Considerations**:
- Use in-memory Tempo backend for short-lived labs
- Pre-instrument sample applications
- Provide TraceQL query examples
- Include broken traces for troubleshooting practice
- Show real-world debugging scenarios
- Integrate with DORA metrics curriculum

**Future Enhancements** (Post-MVP):
- Service mesh integration (Istio sidecar auto-instrumentation)
- Trace-based SLO monitoring
- Anomaly detection from trace patterns
- Cost attribution per service from trace data
- Automated performance recommendations
- Trace replay for testing

## Last Updated

December 7, 2024 - Initial version documenting Grafana Tempo + OpenTelemetry for distributed tracing
