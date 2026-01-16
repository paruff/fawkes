# Civo Observability Integration

## Overview

This directory contains observability configurations for Civo Kubernetes clusters running on the Fawkes platform. Since Civo doesn't provide native observability services like AWS CloudWatch or GCP Cloud Monitoring, this implementation relies entirely on the platform's observability stack (Prometheus, Grafana, OpenSearch, Fluent Bit).

## Architecture

Civo uses K3s (lightweight Kubernetes) instead of full Kubernetes, which has some implications for observability:

```
┌─────────────────────────────────────────────────────────┐
│                  Civo K3s Cluster                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Application  │  │  Fluent Bit  │  │  Prometheus  │ │
│  │    Pods      │─>│  DaemonSet   │─>│   Scraping   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                  │                  │
           ├──────────────────┴──────────────────┘
           ▼
┌─────────────────────────────────────────────────────────┐
│              Platform Observability Stack               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  Prometheus  │  │  OpenSearch  │  │   Grafana    │ │
│  │  (Metrics)   │  │   (Logs)     │  │ (Dashboards) │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                  │                  │
           └──────────────────┴──────────────────┘
                              ▼
                  ┌───────────────────────────┐
                  │   Mattermost Alerts       │
                  └───────────────────────────┘
```

## Key Differences from AWS/GCP

| Feature | AWS/GCP | Civo |
|---------|---------|------|
| Kubernetes | Full EKS/GKE | K3s (lightweight) |
| Native Monitoring | CloudWatch/Cloud Monitoring | None - rely on platform stack |
| Native Logging | CloudWatch Logs/Cloud Logging | None - use Fluent Bit |
| Tracing | X-Ray/Cloud Trace | Platform-level (Jaeger) |
| Cost API | Rich billing APIs | Simple API, limited granularity |
| Regions | 20+ regions | 4 regions (NYC1, LON1, FRA1, PHX1) |
| API Rate Limits | High (1000s/min) | Moderate (~100/min) |

## Directory Structure

```
platform/observability/civo/
├── prometheus-config.yaml    # Prometheus scrape configs and recording rules
├── fluent-bit-config.yaml    # Log collection and forwarding to OpenSearch
├── alerts.yaml               # Civo-specific alerting rules
└── README.md                 # This file

platform/observability/grafana/dashboards/
└── civo-overview.json        # Grafana dashboard for Civo clusters
```

## Components

### 1. Prometheus Configuration

**File**: `prometheus-config.yaml`

Configures Prometheus to scrape metrics from:
- **K3s Nodes**: Kubelet metrics from K3s nodes
- **K3s API Server**: Control plane metrics
- **K3s Scheduler**: Scheduler metrics  
- **K3s Controller Manager**: Controller manager metrics
- **Application Pods**: Pods with `prometheus.io/scrape: "true"` annotation

#### Recording Rules

Pre-aggregated metrics for efficient queries:

**Cluster Resources**:
- `civo:cluster:cpu_capacity_cores` - Total CPU capacity
- `civo:cluster:memory_capacity_bytes` - Total memory capacity
- `civo:cluster:cpu_utilization_percent` - CPU utilization %
- `civo:cluster:memory_utilization_percent` - Memory utilization %
- `civo:cluster:nodes_ready` - Number of ready nodes
- `civo:cluster:nodes_not_ready` - Number of not-ready nodes

**Pod Metrics**:
- `civo:cluster:pods_total` - Total pod count
- `civo:cluster:pods_running` - Running pods
- `civo:cluster:pods_pending` - Pending pods
- `civo:cluster:pods_failed` - Failed pods
- `civo:cluster:pod_restart_rate` - Pod restart rate per minute

**API Rate Limits**:
- `civo:api:calls_per_minute` - Civo API calls rate
- `civo:api:error_rate` - API error rate
- `civo:api:rate_limit_usage_percent` - Rate limit usage %

**Cost Metrics**:
- `civo:cost:cluster_hourly_usd` - Cluster cost per hour
- `civo:cost:cluster_monthly_projected_usd` - Projected monthly cost
- `civo:cost:namespace_hourly_usd` - Cost per namespace
- `civo:cost:idle_pods_hourly_usd` - Cost of idle pods

#### ServiceMonitors

Custom ServiceMonitors for:
- **cost-collector**: Scrapes cost metrics every 5 minutes
- **cloud-provider-service**: Scrapes Civo API metrics every minute

### 2. Fluent Bit Configuration

**File**: `fluent-bit-config.yaml`

Deploys Fluent Bit as a DaemonSet to collect and forward logs to OpenSearch.

#### Input Sources

- **Container Logs**: `/var/log/containers/*.log` (all pod logs)
- **K3s System Logs**: systemd logs from `k3s.service`
- **Node Syslog**: `/var/log/syslog` for system-level events

#### Filters

1. **Kubernetes Metadata Enrichment**: Adds pod, namespace, labels, annotations
2. **Civo Metadata**: Adds `cloud_provider=civo`, `cloud_region`, `cluster_name`, `environment`
3. **JSON Parsing**: Parses structured JSON logs
4. **Record Modification**: Removes unnecessary fields to reduce storage costs

#### Outputs

- **civo-k8s-logs**: Kubernetes pod logs → `civo-k8s-YYYY.MM.DD` index
- **civo-host-logs**: System/host logs → `civo-host-YYYY.MM.DD` index
- **civo-errors**: Error logs only → `civo-errors-YYYY.MM.DD` index (for alerting)

#### Resource Requirements

- **CPU**: 100m request, 500m limit
- **Memory**: 128Mi request, 512Mi limit
- Runs on all nodes including control plane (tolerations configured)

### 3. Alerting Rules

**File**: `alerts.yaml`

#### Cluster Health Alerts

- **CivoNodeNotReady**: Node unready for 5+ minutes (critical)
- **CivoClusterHighCPU**: CPU > 80% for 10 minutes (warning)
- **CivoClusterCriticalCPU**: CPU > 90% for 5 minutes (critical)
- **CivoClusterHighMemory**: Memory > 85% for 10 minutes (warning)
- **CivoClusterCriticalMemory**: Memory > 95% for 5 minutes (critical)
- **CivoPodCrashLooping**: Pod restarting > 2x/min for 5 minutes (warning)
- **CivoPodsStuckPending**: > 5 pods pending for 15 minutes (warning)

#### API Rate Limit Alerts

- **CivoAPIRateLimitApproaching**: Usage > 70% for 5 minutes (warning)
- **CivoAPIRateLimitCritical**: Usage > 90% for 2 minutes (critical)
- **CivoAPIHighErrorRate**: Error rate > 10% for 5 minutes (warning)
- **CivoAPIDown**: API service unreachable for 5 minutes (critical)

#### Cost Alerts

- **CivoCostAnomalyDetected**: Cost increase > 30% vs 24h average for 1 hour (warning)
- **CivoHighMonthlyCost**: Projected monthly cost > $500 for 30 minutes (warning)
- **CivoCriticalMonthlyCost**: Projected monthly cost > $1000 for 15 minutes (critical)
- **CivoIdleResourcesDetected**: Idle pods costing > $5/hr for 2 hours (info)

#### K3s Specific Alerts

- **CivoK3sAPIServerDown**: API server down for 5 minutes (critical)
- **CivoK3sHighAPILatency**: p99 latency > 1s for 10 minutes (warning)
- **CivoK3sControllerManagerDown**: Controller manager down for 5 minutes (critical)
- **CivoK3sSchedulerDown**: Scheduler down for 5 minutes (critical)

#### Logging Alerts

- **CivoFluentBitDown**: Fluent Bit down for 5 minutes (warning)
- **CivoHighLogVolume**: > 10k log records/sec for 15 minutes (warning)
- **CivoLogForwardingFailing**: > 10 errors/sec for 5 minutes (critical)

### 4. Mattermost Integration

Alerts are routed to Mattermost channels based on severity:

- **Critical alerts**: Immediate notification, 1-hour repeat interval
- **Warning alerts**: Standard notification, 4-hour repeat interval
- **Cost alerts**: Separate channel for finance team, 12-hour repeat interval

Configuration requires setting environment variables:
- `MATTERMOST_WEBHOOK_URL`: Main alerts channel
- `MATTERMOST_COST_WEBHOOK_URL`: Cost alerts channel (optional)

### 5. Grafana Dashboard

**File**: `grafana/dashboards/civo-overview.json`

Comprehensive dashboard with 24 panels organized into sections:

#### Cluster Overview (6 panels)
- Total Monthly Cost
- CPU Utilization Gauge
- Memory Utilization Gauge
- Nodes Status
- Running Pods

#### Cost Tracking (5 panels)
- Hourly Cost
- Idle Resource Cost
- Cost Trend (24h)
- Cost by Namespace

#### Resource Utilization (2 panels)
- CPU Utilization by Node
- Memory Utilization by Node

#### K3s Performance (2 panels)
- API Server Requests
- API Server Latency (p99)

#### Pod Status (2 panels)
- Pod Status Distribution (pie chart)
- Pod Restart Rate

#### API Rate Limits (3 panels)
- Civo API Calls Rate Gauge
- API Error Rate
- API Calls Trend

**Variables**:
- `$cluster`: Select cluster to view
- `$region`: Filter by Civo region

## Deployment

### Prerequisites

1. **Civo Cluster Running**: K3s cluster deployed on Civo
2. **Platform Stack Deployed**:
   - Prometheus (with Prometheus Operator)
   - Grafana
   - OpenSearch
   - Mattermost (optional, for alerts)
3. **Cost Collector Service**: Deployed with Civo API credentials
4. **Cloud Provider Service**: Running with Civo provider enabled

### Step 1: Create Namespace

```bash
# Create monitoring namespace if it doesn't exist
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# Create logging namespace if it doesn't exist
kubectl create namespace logging --dry-run=client -o yaml | kubectl apply -f -
```

### Step 2: Create OpenSearch Credentials Secret

```bash
# Create secret for Fluent Bit to access OpenSearch
kubectl create secret generic opensearch-credentials \
  --from-literal=username=admin \
  --from-literal=password=${OPENSEARCH_PASSWORD} \
  -n logging
```

### Step 3: Deploy Prometheus Configuration

```bash
# Set environment variables
export CLUSTER_NAME="fawkes-civo-prod"
export ENVIRONMENT="production"
export CIVO_REGION="NYC1"

# Deploy Prometheus scrape configs and recording rules
envsubst < platform/observability/civo/prometheus-config.yaml | kubectl apply -f -
```

### Step 4: Deploy Fluent Bit

```bash
# Set additional environment variables
export OPENSEARCH_HOST="opensearch.fawkes.svc.cluster.local"
export OPENSEARCH_PORT="9200"

# Deploy Fluent Bit DaemonSet
envsubst < platform/observability/civo/fluent-bit-config.yaml | kubectl apply -f -

# Verify Fluent Bit is running
kubectl get pods -n logging -l app=fluent-bit
kubectl logs -n logging -l app=fluent-bit --tail=50
```

### Step 5: Deploy Alerting Rules

```bash
# Deploy Prometheus alerting rules
kubectl apply -f platform/observability/civo/alerts.yaml

# Verify rules are loaded
kubectl get prometheusrules -n monitoring civo-alerts
```

### Step 6: Configure Mattermost Integration

```bash
# Create Mattermost webhook URLs as secrets
kubectl create secret generic mattermost-webhooks \
  --from-literal=webhook-url=${MATTERMOST_WEBHOOK_URL} \
  --from-literal=cost-webhook-url=${MATTERMOST_COST_WEBHOOK_URL} \
  -n monitoring

# Update Alertmanager configuration
# This step depends on your Alertmanager setup
# See "Mattermost Integration" section for configuration details
```

### Step 7: Import Grafana Dashboard

```bash
# Create ConfigMap for Grafana dashboard
kubectl create configmap grafana-dashboard-civo-overview \
  --from-file=platform/observability/grafana/dashboards/civo-overview.json \
  -n monitoring

# Label it so Grafana auto-imports it
kubectl label configmap grafana-dashboard-civo-overview \
  grafana_dashboard=1 \
  -n monitoring

# Verify dashboard appears in Grafana
# Open Grafana UI and look for "Civo Cluster Overview"
```

### Step 8: Verify Metrics are Flowing

```bash
# Port-forward to Prometheus
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Open http://localhost:9090 and run these queries:
# - civo:cluster:nodes_ready
# - civo:cluster:cpu_utilization_percent
# - civo:cost:cluster_monthly_projected_usd

# Check for scrape targets
# Open http://localhost:9090/targets
# Look for civo-k3s-* jobs
```

### Step 9: Verify Logs are Flowing

```bash
# Port-forward to OpenSearch Dashboards
kubectl port-forward -n opensearch svc/opensearch-dashboards 5601:5601

# Open http://localhost:5601
# Check for civo-k8s-* and civo-host-* index patterns
# Create index patterns if they don't exist
```

## Cost Tracking Integration

Civo provides a simple billing API that can be integrated for cost tracking.

### Civo Billing API

The `cost-collector` service queries the Civo API for:
- Current cluster resource costs
- Instance pricing
- Volume pricing
- Load balancer pricing

### Cost Metrics

The following metrics are exposed to Prometheus:

```
# Cluster hourly cost
civo_cluster_cost_hourly_usd{cluster_name="fawkes-civo-prod", region="NYC1"} 0.045

# Resource costs by type
civo_resource_cost_hourly_usd{resource_type="compute", cluster_name="...", namespace="..."} 0.030
civo_resource_cost_hourly_usd{resource_type="storage", cluster_name="...", namespace="..."} 0.010
civo_resource_cost_hourly_usd{resource_type="loadbalancer", cluster_name="...", namespace="..."} 0.005

# API request metrics
civo_api_requests_total{method="GET", endpoint="/v2/kubernetes/clusters", status="200"} 150
```

### Cost Optimization

1. **Identify Idle Resources**:
   - Query: `civo:cost:idle_pods_hourly_usd`
   - Scale down or delete pods with low CPU usage

2. **Right-size Clusters**:
   - Monitor CPU/memory utilization
   - Downsize nodes if consistently < 50% utilized

3. **Use Spot Instances** (if available):
   - Civo doesn't currently offer spot instances
   - Monitor for this feature in future

4. **Clean Up Unused Resources**:
   - Persistent volumes
   - Load balancers
   - Unused nodes

## Monitoring Best Practices

### 1. Metric Retention

Configure Prometheus retention based on needs:
- **Default**: 15 days
- **Recommended**: 30 days for production
- **Long-term**: Export to Thanos or Cortex for > 30 days

### 2. Log Retention

Configure OpenSearch index lifecycle:
- **Hot tier** (0-7 days): Standard storage
- **Warm tier** (7-30 days): Slower storage
- **Cold tier** (30-90 days): Archive storage
- **Delete** (> 90 days): Remove old logs

Example policy in `fluent-bit-config.yaml`:
```yaml
# OpenSearch ILM policy (configure in OpenSearch)
{
  "policy": {
    "description": "Civo logs lifecycle policy",
    "default_state": "hot",
    "states": [
      {
        "name": "hot",
        "transitions": [
          {
            "state_name": "warm",
            "conditions": {
              "min_index_age": "7d"
            }
          }
        ]
      },
      {
        "name": "warm",
        "transitions": [
          {
            "state_name": "delete",
            "conditions": {
              "min_index_age": "90d"
            }
          }
        ]
      },
      {
        "name": "delete",
        "actions": [
          {
            "delete": {}
          }
        ]
      }
    ]
  }
}
```

### 3. Alert Tuning

Start with conservative thresholds and adjust based on actual usage:
- **CPU**: 80% warning, 90% critical
- **Memory**: 85% warning, 95% critical
- **API rate limit**: 70% warning, 90% critical

Monitor alert frequency and adjust to reduce noise.

### 4. Dashboard Organization

Organize Grafana dashboards by audience:
- **Developers**: Focus on application metrics, logs, traces
- **Platform team**: Focus on cluster health, K3s performance
- **Finance**: Focus on cost tracking, optimization

## Troubleshooting

### Prometheus Not Scraping Metrics

```bash
# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus 9090:9090
# Open http://localhost:9090/targets

# Look for errors on civo-k3s-* targets

# Common issues:
# 1. RBAC permissions - check ClusterRole and ClusterRoleBinding
kubectl get clusterrole prometheus-k8s -o yaml
kubectl get clusterrolebinding prometheus-k8s -o yaml

# 2. Network policies blocking access
kubectl get networkpolicies -A

# 3. ServiceMonitors not being picked up
kubectl get servicemonitors -n monitoring
kubectl describe servicemonitor civo-cost-collector -n monitoring
```

### Fluent Bit Not Forwarding Logs

```bash
# Check Fluent Bit pods
kubectl get pods -n logging -l app=fluent-bit

# Check logs for errors
kubectl logs -n logging -l app=fluent-bit --tail=100

# Common issues:
# 1. OpenSearch credentials incorrect
kubectl get secret opensearch-credentials -n logging -o yaml

# 2. OpenSearch not reachable
kubectl exec -n logging -it $(kubectl get pod -n logging -l app=fluent-bit -o jsonpath='{.items[0].metadata.name}') -- \
  curl -u admin:${OPENSEARCH_PASSWORD} https://${OPENSEARCH_HOST}:${OPENSEARCH_PORT}

# 3. Fluent Bit buffer full
# Check metrics endpoint
kubectl port-forward -n logging svc/fluent-bit 2020:2020
curl http://localhost:2020/api/v1/metrics/prometheus
```

### Alerts Not Reaching Mattermost

```bash
# Check Alertmanager config
kubectl get configmap alertmanager-config -n monitoring -o yaml

# Check Alertmanager logs
kubectl logs -n monitoring -l app=alertmanager

# Test webhook manually
curl -X POST ${MATTERMOST_WEBHOOK_URL} \
  -H 'Content-Type: application/json' \
  -d '{"text": "Test alert from Civo observability"}'

# Check firing alerts
kubectl port-forward -n monitoring svc/alertmanager 9093:9093
# Open http://localhost:9093
```

### High Cardinality Metrics

If Prometheus is running out of memory:

```bash
# Check current cardinality
kubectl exec -n monitoring prometheus-k8s-0 -- \
  promtool tsdb analyze /prometheus

# Identify high-cardinality metrics
# Query in Prometheus: topk(10, count by (__name__)({__name__=~".+"}))

# Solutions:
# 1. Add metric_relabel_configs to drop high-cardinality labels
# 2. Increase Prometheus memory limits
# 3. Use recording rules to pre-aggregate metrics
```

### Civo API Rate Limiting

If hitting rate limits:

```bash
# Check current API usage
# Query in Prometheus: civo:api:calls_per_minute

# Solutions:
# 1. Increase cost-collector polling interval (5m → 10m)
# 2. Batch API requests where possible
# 3. Cache API responses in cost-collector
# 4. Contact Civo support for higher rate limits
```

## Cost Estimates

Based on typical usage for a production Civo cluster:

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| Prometheus | 50GB storage, 2GB memory | Included in cluster |
| OpenSearch | 100GB logs, 30-day retention | $15-25 |
| Fluent Bit | DaemonSet on all nodes | Included (minimal overhead) |
| Grafana | Dashboards and queries | Included in platform |
| **Platform Overhead** | | **~$15-25/month** |
| **Civo Cluster** | 3 nodes × g4s.kube.medium | **~$90/month** |
| **Total** | | **~$105-115/month** |

*Note: Civo clusters are significantly cheaper than EKS/GKE, with observability overhead around 15-20% of cluster cost.*

## Performance Impact

- **Prometheus scraping**: < 1% CPU overhead per node
- **Fluent Bit**: 100-200m CPU, 128-256Mi memory per node
- **Network overhead**: ~2-5% of application traffic (logs + metrics)
- **Storage impact**: ~10-20GB logs per day for typical workloads

## Security Considerations

1. **Secrets Management**:
   - Store Civo API keys in Kubernetes secrets
   - Use external secret management (Vault, AWS Secrets Manager)
   - Rotate API keys regularly

2. **RBAC**:
   - Limit Prometheus scraping to necessary resources
   - Restrict Fluent Bit to read-only access
   - Use separate service accounts per component

3. **Network Security**:
   - Use Network Policies to restrict pod-to-pod traffic
   - TLS for all external connections (OpenSearch, Mattermost)
   - Verify TLS certificates (don't use `insecure_skip_verify` in production)

4. **Data Privacy**:
   - Redact sensitive data from logs (passwords, tokens, PII)
   - Use log filters in Fluent Bit
   - Encrypt logs at rest in OpenSearch

## References

- [Civo Documentation](https://www.civo.com/docs)
- [Civo API Documentation](https://www.civo.com/api)
- [K3s Documentation](https://docs.k3s.io/)
- [Prometheus Documentation](https://prometheus.io/docs/)
- [Fluent Bit Documentation](https://docs.fluentbit.io/)
- [OpenSearch Documentation](https://opensearch.org/docs/)
- [Grafana Documentation](https://grafana.com/docs/)

## Support

For issues or questions:
- File an issue in the Fawkes repository
- Contact the platform team via Mattermost #platform-observability
- Check [Civo Community](https://www.civo.com/community)
- Consult [Civo Status Page](https://status.civo.com)

## License

MIT License - See LICENSE file for details.
