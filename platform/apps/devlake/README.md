# DevLake - DORA Metrics Collection Service

## Purpose

Apache DevLake is the DORA Metrics Collection Service for the Fawkes platform. It automates the collection, calculation, and visualization of the five DORA metrics from multiple data sources (GitHub, ArgoCD, Jenkins, and observability systems).

## Key Features

- **Automated Collection**: Pull data from GitHub, Jenkins, ArgoCD, and incident management systems
- **Five DORA Metrics**: Deployment Frequency, Lead Time for Changes, Change Failure Rate, MTTR, Operational Performance
- **REST & GraphQL APIs**: Query metrics programmatically
- **Grafana Dashboards**: Pre-built dashboards for DORA visualization
- **Prometheus Integration**: Exposes metrics for Prometheus scraping
- **MySQL Database**: Persistent storage for raw data and calculated metrics

---

## Architecture

DevLake follows a three-layer architecture:

1. **Data Collection Layer**: Plugins for GitHub, ArgoCD, Jenkins, webhooks
2. **Processing Layer**: Data transformation, DORA metric calculation
3. **API Layer**: REST/GraphQL APIs, Prometheus metrics endpoint

```
┌─────────────────────────────────────────────────────────┐
│  Data Sources (GitHub, ArgoCD, Jenkins, Incidents)     │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│           DevLake Core (lake, workers)                  │
│  • Data collection  • Transformation  • Calculation     │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│               MySQL Database (DORA Metrics)             │
└───────────────────────┬─────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────┐
│    APIs (REST, GraphQL, Prometheus) + Grafana           │
└─────────────────────────────────────────────────────────┘
```

---

## Deployment

### Prerequisites

- Kubernetes cluster (1.28+)
- ArgoCD deployed
- External Secrets Operator (for credentials)
- 20Gi storage for MySQL

### Deploy with ArgoCD

DevLake is deployed via ArgoCD:

```bash
kubectl apply -f platform/apps/devlake/devlake-application.yaml
```

### Verify Deployment

```bash
# Check pods
kubectl get pods -n fawkes -l app.kubernetes.io/name=devlake

# Expected output:
# NAME                      READY   STATUS    RESTARTS   AGE
# devlake-lake-0           1/1     Running   0          5m
# devlake-ui-0             1/1     Running   0          5m
# devlake-grafana-0        1/1     Running   0          5m
# devlake-mysql-0          1/1     Running   0          5m

# Check services
kubectl get svc -n fawkes -l app.kubernetes.io/name=devlake

# Check ingress
kubectl get ingress -n fawkes devlake
```

---

## Accessing DevLake

### Web UI

```bash
# DevLake Configuration UI
http://devlake.127.0.0.1.nip.io

# Grafana Dashboards
http://devlake-grafana.127.0.0.1.nip.io

# Get Grafana admin password
kubectl get secret -n fawkes devlake-grafana-secrets \
  -o jsonpath='{.data.admin-password}' | base64 -d
```

### API Access

```bash
# REST API base URL
http://devlake.127.0.0.1.nip.io/api

# GraphQL endpoint
http://devlake.127.0.0.1.nip.io/api/graphql

# Prometheus metrics
http://devlake.127.0.0.1.nip.io/metrics

# Get API token
kubectl get secret -n fawkes devlake-api-token \
  -o jsonpath='{.data.token}' | base64 -d
```

---

## Data Source Configuration

DevLake collects data from multiple sources. Configure them in the DevLake UI or via ConfigMap.

### 1. GitHub (Commit and PR data)

```yaml
# Configured in: config/data-sources.yaml
plugin: github
endpoint: https://api.github.com/
repositories:
  - paruff/fawkes
scope:
  - commits
  - pull_requests
  - code_review
```

**What it provides**:
- Commit timestamps (for lead time start)
- Pull request data
- Code review metrics

### 2. ArgoCD (PRIMARY for Deployments)

```yaml
# Configured in: config/data-sources.yaml
plugin: argocd
endpoint: http://argocd-server.fawkes.svc
scope:
  - applications
  - syncs
  - sync_status
```

**What it provides**:
- Deployment frequency (sync events)
- Lead time (commit → sync completion)
- Change failure rate (failed syncs)

**Important**: In Fawkes GitOps architecture, ArgoCD is the source of truth for deployments, not Jenkins.

### 3. Jenkins (CI Metrics)

```yaml
# Configured in: config/data-sources.yaml
plugin: jenkins
endpoint: http://jenkins.fawkes.svc
scope:
  - builds
  - pipelines
  - test_results
```

**What it provides**:
- Build success rate
- Rework rate (retry builds)
- Quality gate pass rate
- Test flakiness

**Note**: Jenkins provides CI metrics, not deployment metrics.

### 4. Webhook (Incidents for MTTR)

```yaml
# Configured in: config/data-sources.yaml
plugin: webhook
endpoint: /api/plugins/webhook/1/incidents
```

**What it provides**:
- Production incidents
- Incident resolution times
- MTTR calculation data

**Usage**: Observability platforms send incident webhooks to DevLake.

---

## DORA Metrics

DevLake calculates five DORA metrics automatically.

### 1. Deployment Frequency

**Calculation**: Count of successful ArgoCD syncs to production per time window.

**Query via REST**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/deployment-frequency?project=payment-service&timeRange=last7days" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Query via GraphQL**:

```graphql
query {
  deploymentFrequency(
    project: "payment-service"
    timeRange: "last30days"
  ) {
    value
    unit
    level
    timeseries {
      date
      count
    }
  }
}
```

**Performance Levels**:
- **Elite**: Multiple deploys per day
- **High**: Once per day to once per week
- **Medium**: Once per week to once per month
- **Low**: Less than once per month

### 2. Lead Time for Changes

**Calculation**: Time from commit authored_date to ArgoCD sync finished_date.

**Query via REST**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/lead-time?project=payment-service&includeStages=true" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Query via GraphQL**:

```graphql
query {
  leadTimeForChanges(
    project: "payment-service"
    timeRange: "last30days"
  ) {
    value
    unit
    level
    p50
    p95
    stages {
      name
      duration
    }
  }
}
```

**Performance Levels**:
- **Elite**: Less than one hour
- **High**: Less than one day
- **Medium**: Less than one week
- **Low**: More than one week

### 3. Change Failure Rate

**Calculation**: (Failed ArgoCD syncs + Production incidents) / Total syncs * 100

**Query via REST**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/change-failure-rate?project=payment-service" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Performance Levels**:
- **Elite**: 0-15%
- **High**: 16-30%
- **Medium**: 31-45%
- **Low**: More than 45%

### 4. Mean Time to Restore

**Calculation**: Average time from incident creation to resolution.

**Query via REST**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/mttr?project=payment-service" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Performance Levels**:
- **Elite**: Less than one hour
- **High**: Less than one day
- **Medium**: Less than one week
- **Low**: More than one week

### 5. Operational Performance

**Calculation**: SLO adherence, P99 latency, error rate from observability data.

**Query via REST**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/operational-performance?project=payment-service" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

---

## Prometheus Integration

DevLake exposes metrics to Prometheus via ServiceMonitor:

```yaml
# File: servicemonitor-devlake.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: devlake-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: devlake
  endpoints:
    - port: http
      interval: 60s
      path: /metrics
```

**Available Prometheus Metrics**:

```prometheus
# Deployment frequency
dora_deployment_frequency_total{project="payment-service"} 72

# Lead time histogram
dora_lead_time_seconds_bucket{project="payment-service",le="3600"} 65

# Change failure rate
dora_change_failure_rate{project="payment-service"} 0.085

# MTTR histogram
dora_mttr_seconds_bucket{project="payment-service",le="3600"} 5
```

**Example PromQL Queries**:

```promql
# Deployment frequency per day (last 7 days)
rate(dora_deployment_frequency_total[7d]) * 86400

# P95 lead time in minutes
histogram_quantile(0.95, dora_lead_time_seconds_bucket) / 60

# Current CFR
dora_change_failure_rate

# P95 MTTR in minutes
histogram_quantile(0.95, dora_mttr_seconds_bucket) / 60
```

---

## Database Schema

DevLake uses MySQL 8.0 with InnoDB engine.

**Key Tables**:
- `deployments`: ArgoCD sync events, Jenkins deployments
- `commits`: Git commit data from GitHub
- `incidents`: Production incidents for MTTR
- `cicd_deployments`: Links deployments to commits
- `dora_benchmarks`: Performance level definitions

**See**: [DORA Metrics Database Schema](../../../docs/reference/dora-metrics-database-schema.md)

---

## API Documentation

Full API reference with examples:

- [DORA Metrics API Reference](../../../docs/reference/dora-metrics-api.md)

---

## Troubleshooting

### DevLake UI not loading

```bash
# Check pod status
kubectl get pods -n fawkes -l app.kubernetes.io/component=ui

# Check logs
kubectl logs -n fawkes -l app.kubernetes.io/component=ui

# Restart UI
kubectl rollout restart deployment/devlake-ui -n fawkes
```

### No metrics data

```bash
# Check data collection
kubectl logs -n fawkes -l app.kubernetes.io/component=lake | grep "collection"

# Verify data sources
kubectl get configmap -n fawkes devlake-data-sources -o yaml

# Check database
kubectl exec -it -n fawkes devlake-mysql-0 -- mysql -u root -p lake
> SELECT COUNT(*) FROM deployments;
> SELECT COUNT(*) FROM commits;
```

### Prometheus not scraping metrics

```bash
# Verify ServiceMonitor
kubectl get servicemonitor -n monitoring devlake-metrics

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open http://localhost:9090/targets and search for "devlake"

# Check DevLake metrics endpoint
kubectl exec -it -n fawkes devlake-lake-0 -- curl localhost:8080/metrics
```

---

## Related Documentation

- [DORA Metrics API Reference](../../../docs/reference/dora-metrics-api.md)
- [DORA Metrics Database Schema](../../../docs/reference/dora-metrics-database-schema.md)
- [View DORA Metrics in DevLake](../../../docs/how-to/observability/view-dora-metrics-devlake.md)
- [DORA Metrics Implementation Playbook](../../../docs/playbooks/dora-metrics-implementation.md)
- [ADR-016: DevLake DORA Strategy](../../../docs/adr/ADR-016%20devlake-dora-strategy.md)
- [Architecture: DORA Metrics Service](../../../docs/architecture.md#6-dora-metrics-service)

---

## Maintenance

### Backup Database

```bash
# Automated daily backup
kubectl exec -n fawkes devlake-mysql-0 -- \
  mysqldump -u root -p${MYSQL_ROOT_PASSWORD} lake \
  > backup-$(date +%Y%m%d).sql

# Upload to S3
aws s3 cp backup-$(date +%Y%m%d).sql s3://fawkes-backups/devlake/
```

### Update DevLake

```bash
# Update Helm chart version in devlake-application.yaml
# ArgoCD will automatically sync the update

# Or manually sync
argocd app sync devlake
```

### Scale DevLake

```bash
# Scale lake replicas
kubectl scale deployment devlake-lake -n fawkes --replicas=2

# Scale worker replicas
kubectl scale deployment devlake-worker -n fawkes --replicas=3
```

---

## Support

- **Apache DevLake Documentation**: https://devlake.apache.org/docs
- **Fawkes Issues**: https://github.com/paruff/fawkes/issues
- **Slack**: #fawkes-platform
