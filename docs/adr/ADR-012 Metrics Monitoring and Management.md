# ADR-012: Metrics Monitoring and Management

## Status
Accepted

## Context

The Fawkes platform requires comprehensive metrics monitoring to support multiple critical use cases:

**Platform Monitoring Needs**:
- Kubernetes cluster health (nodes, pods, deployments, resource utilization)
- Core service availability (Backstage, ArgoCD, Jenkins, Mattermost, Focalboard, Harbor)
- Infrastructure performance (CPU, memory, disk, network across all nodes)
- Service-level indicators (SLIs) for platform components
- Capacity planning data (growth trends, resource forecasting)
- Cost allocation and optimization metrics

**DORA Metrics Requirements** (Core Platform Value Proposition):
- **Deployment Frequency**: Deployments per day/week/month by team
- **Lead Time for Changes**: Time from commit to production deployment
- **Change Failure Rate**: Percentage of deployments causing incidents
- **Time to Restore Service**: Mean time to recovery (MTTR) from incidents

**Application Monitoring Needs**:
- Application-specific metrics (request rates, latency, error rates)
- Custom business metrics defined by teams
- Service dependency mapping
- Distributed tracing correlation
- Database performance metrics
- Message queue depths and processing rates

**Developer Experience Metrics**:
- Build duration (P50, P95, P99 percentiles)
- Pipeline success/failure rates
- Time spent in code review
- Environment provisioning time
- Developer onboarding time

**Security & Compliance Metrics**:
- Failed authentication attempts
- Privileged access usage
- Security scan results over time
- Vulnerability remediation time
- Certificate expiration tracking

**Learner/Dojo Metrics**:
- Lab environment resource usage
- Module completion times
- Assessment success rates
- Active learners by belt level
- Infrastructure costs per learner

**Technical Requirements**:
- Multi-dimensional metrics (labels/tags for filtering)
- Long-term retention (13+ months for year-over-year analysis)
- High cardinality support (per-team, per-service, per-environment)
- PromQL-compatible query language for flexibility
- Alert rule engine with notification routing
- Horizontal scalability for growing metric volumes
- Multi-tenancy (team-level metric isolation)
- Integration with Kubernetes service discovery
- Support for push and pull metric collection models

**Operational Requirements**:
- Self-service dashboarding for teams
- Alerting without constant platform team intervention
- Backup and disaster recovery
- Low operational overhead
- Works across cloud providers and on-premises
- GitOps-compatible configuration
- Cost-effective at scale

**Integration Requirements**:
- Native Kubernetes integration (kube-state-metrics, node-exporter)
- OpenTelemetry compatibility
- Grafana for visualization
- Jenkins, ArgoCD, Backstage metrics exporters
- Custom application instrumentation (Go, Java, Python, Node.js)
- Webhook receivers for DORA metrics calculation

## Decision

We will use **Prometheus** as the core metrics collection and storage engine, deployed via the **kube-prometheus-stack** Helm chart, with **Thanos** for long-term storage and multi-cluster querying.

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  Metrics Sources                                                 │
│                                                                   │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐            │
│  │ Kubernetes  │  │ Platform    │  │ Application │            │
│  │ Cluster     │  │ Services    │  │ Services    │            │
│  │             │  │             │  │             │            │
│  │ • Nodes     │  │ • ArgoCD    │  │ • Custom    │            │
│  │ • Pods      │  │ • Jenkins   │  │   metrics   │            │
│  │ • Services  │  │ • Backstage │  │ • Business  │            │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘            │
│         │                 │                 │                    │
│         └─────────────────┴─────────────────┘                    │
│                           │                                       │
│                           │ /metrics endpoints (pull)             │
│                           │                                       │
└───────────────────────────┼───────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Prometheus Federation Layer                                     │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ kube-prometheus-stack                                     │   │
│  │                                                            │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │   │
│  │  │ Prometheus │  │ Prometheus │  │ Prometheus │         │   │
│  │  │ (Core)     │  │ (Apps)     │  │ (Learner)  │         │   │
│  │  │            │  │            │  │            │         │   │
│  │  │ Platform   │  │ Application│  │ Dojo Labs  │         │   │
│  │  │ metrics    │  │ metrics    │  │ metrics    │         │   │
│  │  └─────┬──────┘  └─────┬──────┘  └─────┬──────┘         │   │
│  │        │               │               │                 │   │
│  └────────┼───────────────┼───────────────┼─────────────────┘   │
│           │               │               │                     │
│           └───────────────┴───────────────┘                     │
│                           │                                       │
│                           │ Remote Write                          │
│                           ▼                                       │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ Thanos (Long-term Storage)                                │   │
│  │                                                            │   │
│  │  ┌────────────┐  ┌────────────┐  ┌────────────┐         │   │
│  │  │ Thanos     │  │ Thanos     │  │ Thanos     │         │   │
│  │  │ Sidecar    │  │ Store      │  │ Compactor  │         │   │
│  │  └────────────┘  └────────────┘  └────────────┘         │   │
│  │                                                            │   │
│  │  ┌────────────┐  ┌────────────┐                          │   │
│  │  │ Thanos     │  │ Object     │                          │   │
│  │  │ Query      │  │ Storage    │                          │   │
│  │  │            │  │ (S3/GCS)   │                          │   │
│  │  └─────┬──────┘  └────────────┘                          │   │
│  └────────┼───────────────────────────────────────────────────┘   │
│           │                                                       │
└───────────┼───────────────────────────────────────────────────────┘
            │ Query API
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Visualization & Alerting                                        │
│                                                                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                │
│  │ Grafana    │  │ Alert      │  │ DORA       │                │
│  │ Dashboards │  │ Manager    │  │ Metrics    │                │
│  │            │  │            │  │ Service    │                │
│  │ • Platform │  │ • Routing  │  │            │                │
│  │ • DORA     │  │ • Silencing│  │ Custom     │                │
│  │ • Apps     │  │ • Grouping │  │ aggregator │                │
│  └────────────┘  └────────────┘  └────────────┘                │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│  Notification Channels                                           │
│                                                                   │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐                │
│  │ Mattermost │  │ Email      │  │ PagerDuty  │                │
│  │ (Primary)  │  │            │  │ (Critical) │                │
│  └────────────┘  └────────────┘  └────────────┘                │
└─────────────────────────────────────────────────────────────────┘
```

### Component Breakdown

**1. Prometheus Core (kube-prometheus-stack)**
- **Prometheus Server**: Metrics collection and short-term storage (15-30 days)
- **Prometheus Operator**: Manages Prometheus instances via CRDs
- **kube-state-metrics**: Kubernetes object state metrics
- **node-exporter**: Node-level system metrics (CPU, memory, disk, network)
- **Alertmanager**: Alert routing, grouping, and notification
- **Grafana**: Pre-configured dashboards and visualization

**2. Thanos (Long-term Storage & Global Query)**
- **Thanos Sidecar**: Uploads Prometheus data to object storage
- **Thanos Store Gateway**: Queries historical data from object storage
- **Thanos Query**: Provides global query interface across all Prometheus instances
- **Thanos Compactor**: Downsamples and compacts historical data
- **Thanos Ruler**: Evaluates recording rules on historical data

**3. Service Monitors (Automated Discovery)**
Kubernetes-native ServiceMonitor CRDs for automatic metric collection:
- Platform services (ArgoCD, Jenkins, Backstage, Harbor, etc.)
- Application services (auto-discovered via labels)
- Custom exporters (database, message queue, etc.)

**4. DORA Metrics Service**
Custom microservice for DORA metrics calculation:
- Receives webhooks from Git, CI/CD, incident management
- Calculates and exposes the 4 key metrics as Prometheus metrics
- Stores raw event data for audit and recalculation
- Provides team-level aggregation

### Deployment Strategy

**Multi-Prometheus Architecture**:

1. **Prometheus-Core** (fawkes-monitoring namespace)
   - Platform infrastructure metrics
   - Kubernetes cluster metrics
   - Core service metrics (ArgoCD, Jenkins, Backstage)
   - Retention: 30 days local, unlimited in Thanos

2. **Prometheus-Apps** (fawkes-monitoring namespace)
   - Application team metrics
   - Custom business metrics
   - Tenant-scoped via namespace labels
   - Retention: 15 days local, unlimited in Thanos

3. **Prometheus-Learner** (fawkes-dojo namespace)
   - Dojo lab environment metrics
   - Learner activity tracking
   - Resource usage per learner
   - Retention: 7 days local, 90 days in Thanos

**Federation**: Thanos Query provides unified interface across all Prometheus instances

### Example Configurations

**ServiceMonitor for ArgoCD**:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: fawkes-cicd
  labels:
    app: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-server
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

**PrometheusRule for Platform Alerts**:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: platform-alerts
  namespace: fawkes-monitoring
spec:
  groups:
  - name: platform
    interval: 30s
    rules:
    - alert: PlatformServiceDown
      expr: up{job=~"argocd|jenkins|backstage"} == 0
      for: 5m
      labels:
        severity: critical
        team: platform
      annotations:
        summary: "Platform service {{ $labels.job }} is down"
        description: "{{ $labels.job }} has been unavailable for 5 minutes"
        runbook_url: "https://docs.fawkes.io/runbooks/service-down"
    
    - alert: HighMemoryUsage
      expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes > 0.85
      for: 10m
      labels:
        severity: warning
        team: platform
      annotations:
        summary: "High memory usage on {{ $labels.instance }}"
        description: "Memory usage is above 85% for 10 minutes"
    
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 15m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.namespace }}/{{ $labels.pod }} is crash looping"
```

**DORA Metrics Recording Rules**:
```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: dora-metrics
  namespace: fawkes-monitoring
spec:
  groups:
  - name: dora_deployment_frequency
    interval: 1m
    rules:
    - record: fawkes:dora:deployment_frequency:per_day
      expr: |
        sum(rate(fawkes_deployment_total[24h])) by (team, environment)
  
  - name: dora_lead_time
    interval: 1m
    rules:
    - record: fawkes:dora:lead_time_seconds:p50
      expr: |
        histogram_quantile(0.50, 
          sum(rate(fawkes_lead_time_seconds_bucket[1h])) by (team, le))
    
    - record: fawkes:dora:lead_time_seconds:p95
      expr: |
        histogram_quantile(0.95, 
          sum(rate(fawkes_lead_time_seconds_bucket[1h])) by (team, le))
  
  - name: dora_change_failure_rate
    interval: 5m
    rules:
    - record: fawkes:dora:change_failure_rate
      expr: |
        sum(rate(fawkes_deployment_failed_total[7d])) by (team) 
        / 
        sum(rate(fawkes_deployment_total[7d])) by (team)
  
  - name: dora_mttr
    interval: 5m
    rules:
    - record: fawkes:dora:mttr_seconds:median
      expr: |
        histogram_quantile(0.50, 
          sum(rate(fawkes_incident_resolution_seconds_bucket[7d])) by (team, le))
```

**Thanos Configuration**:
```yaml
# thanos-storage-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: thanos-objstore-config
  namespace: fawkes-monitoring
stringData:
  objstore.yml: |
    type: S3
    config:
      bucket: fawkes-metrics-storage
      endpoint: s3.us-west-2.amazonaws.com
      region: us-west-2
      access_key: ${AWS_ACCESS_KEY_ID}
      secret_key: ${AWS_SECRET_ACCESS_KEY}
```

```yaml
# prometheus-with-thanos.yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: prometheus-core
  namespace: fawkes-monitoring
spec:
  replicas: 2
  retention: 30d
  retentionSize: 50GB
  
  resources:
    requests:
      cpu: 500m
      memory: 2Gi
    limits:
      cpu: 2000m
      memory: 8Gi
  
  storageSpec:
    volumeClaimTemplate:
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 100Gi
  
  thanos:
    version: v0.32.5
    objectStorageConfig:
      key: objstore.yml
      name: thanos-objstore-config
  
  serviceMonitorSelector:
    matchLabels:
      prometheus: core
  
  podMonitorSelector:
    matchLabels:
      prometheus: core
  
  ruleSelector:
    matchLabels:
      prometheus: core
```

### Grafana Dashboard Strategy

**Pre-configured Dashboards** (Included in MVP):

1. **Platform Overview Dashboard**
   - Cluster resource utilization (CPU, memory, disk)
   - Node health status
   - Pod count by namespace
   - Top resource consumers
   - Alert summary

2. **DORA Metrics Dashboard**
   - 4 key metrics with benchmark comparison
   - Team-level breakdown
   - Trend analysis (7d, 30d, 90d)
   - Elite/High/Medium/Low performer classification
   - Deployment calendar heatmap

3. **Service Health Dashboard**
   - Service availability (uptime %)
   - Request rate, latency (P50, P95, P99)
   - Error rate (4xx, 5xx)
   - Saturation metrics
   - Dependency map

4. **Kubernetes Cluster Dashboard**
   - Node resource usage
   - Pod status distribution
   - Persistent volume usage
   - Network I/O
   - API server performance

5. **CI/CD Pipeline Dashboard**
   - Build duration trends
   - Success/failure rates
   - Queue depth and wait time
   - Test coverage trends
   - Deployment frequency

6. **Cost Allocation Dashboard**
   - Resource costs by team/namespace
   - Over-provisioned resources
   - Idle resource identification
   - Cost trends and forecasting

**Self-Service Dashboarding**:
- Teams can create custom dashboards using Grafana UI
- Dashboard-as-code via ConfigMaps for GitOps
- Dashboard templates for common patterns
- Export/import for sharing across teams

### DORA Metrics Service Architecture

Custom Go microservice for DORA metrics calculation:

**Components**:
1. **Webhook Receiver**: Accepts events from Git, CI/CD, incident management
2. **Event Store**: PostgreSQL database for raw event storage
3. **Metrics Calculator**: Aggregates events into DORA metrics
4. **Prometheus Exporter**: Exposes metrics on /metrics endpoint
5. **REST API**: Provides historical data and drill-down capabilities

**Event Types**:
- `commit` - Git commit with author, timestamp, repository
- `build_started` - CI pipeline initiated
- `build_completed` - CI pipeline finished (success/failure)
- `deployment_started` - Deployment initiated
- `deployment_completed` - Deployment finished (success/failure)
- `incident_created` - Production incident reported
- `incident_resolved` - Incident closed

**Metrics Exposed**:
```
# Deployment Frequency
fawkes_deployment_total{team="teamA",environment="production"} 45

# Lead Time (histogram)
fawkes_lead_time_seconds_bucket{team="teamA",le="3600"} 30
fawkes_lead_time_seconds_bucket{team="teamA",le="7200"} 50
fawkes_lead_time_seconds_sum{team="teamA"} 180000
fawkes_lead_time_seconds_count{team="teamA"} 75

# Change Failure Rate
fawkes_deployment_failed_total{team="teamA",environment="production"} 5

# MTTR (histogram)
fawkes_incident_resolution_seconds_bucket{team="teamA",le="1800"} 12
fawkes_incident_resolution_seconds_bucket{team="teamA",le="3600"} 18
fawkes_incident_resolution_seconds_sum{team="teamA"} 54000
fawkes_incident_resolution_seconds_count{team="teamA"} 20
```

**API Endpoints**:
- `POST /webhook/commit` - Receive Git commit events
- `POST /webhook/build` - Receive CI build events
- `POST /webhook/deployment` - Receive deployment events
- `POST /webhook/incident` - Receive incident events
- `GET /metrics` - Prometheus metrics endpoint
- `GET /api/v1/dora/{team}` - DORA metrics for specific team
- `GET /api/v1/deployments/{team}` - Deployment history

### Application Instrumentation

**Supported Languages** (Client Libraries):
- **Go**: `prometheus/client_golang`
- **Java**: `micrometer` with Prometheus registry
- **Python**: `prometheus_client`
- **Node.js**: `prom-client`
- **.NET**: `prometheus-net`

**Standard Metrics** (RED Method):
- **Rate
