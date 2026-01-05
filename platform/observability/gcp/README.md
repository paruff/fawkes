# GCP Observability Integration

## Overview

This directory contains GCP-native observability integrations for the Fawkes platform. It provides comprehensive monitoring, tracing, logging, and cost analysis capabilities specifically for GCP infrastructure, particularly GKE (Google Kubernetes Engine) clusters.

## Architecture

The GCP observability stack consists of five main components:

1. **Cloud Monitoring** - Metrics, dashboards, and alert policies
2. **Cloud Logging** - Log collection, export, and analysis
3. **Cloud Trace** - Distributed tracing
4. **OpenTelemetry Collector** - Unified observability data collection
5. **Cloud Billing** - Financial operations and cost optimization

```
┌─────────────────────────────────────────────────────────┐
│                    GKE Cluster                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Application  │  │    OTEL      │  │  Cloud       │ │
│  │    Pods      │─>│  Collector   │─>│  Trace       │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                  │                  │
           ├──────────────────┴──────────────────┘
           ▼
┌─────────────────────────────────────────────────────────┐
│                  GCP Observability                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │   Cloud      │  │   Cloud      │  │   Cloud      │ │
│  │  Monitoring  │  │   Logging    │  │   Trace      │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│  ┌──────────────┐  ┌──────────────┐                   │
│  │   Pub/Sub    │  │  BigQuery    │                   │
│  │  (Alerts)    │  │   (Logs)     │                   │
│  └──────────────┘  └──────────────┘                   │
└─────────────────────────────────────────────────────────┘
           │                  │                  │
           └──────────────────┴──────────────────┘
                              ▼
           ┌───────────────────────────────────┐
           │    Grafana Dashboards             │
           │  - GKE Metrics                    │
           │  - Cost Analysis                  │
           │  - Jaeger Traces                  │
           └───────────────────────────────────┘
```

## Directory Structure

```
platform/observability/gcp/
├── monitoring/
│   ├── dashboards.tf          # Cloud Monitoring dashboard definitions
│   └── alerts.tf              # Alert policies and Pub/Sub integration
├── logging/
│   └── log-sinks.tf           # Log export and log-based metrics
├── otel-collector-config.yaml # OpenTelemetry Collector configuration
└── README.md                  # This file

platform/observability/grafana/dashboards/
└── gcp-costs.json             # Grafana dashboard for GCP cost analysis
```

## Components

### 1. Cloud Monitoring Integration

#### Dashboards

Cloud Monitoring provides native GCP dashboards for GKE monitoring:

- **GKE Cluster Overview** - Control plane CPU/memory, node count, pod count, container restarts
- **GKE Node Performance** - Node CPU/memory/disk/network metrics
- **Application Performance** - Pod-level metrics by namespace
- **Cost and Usage** - Resource count and utilization tracking

#### Alert Policies

Critical and warning alerts with Pub/Sub integration:

- **Control Plane Alerts** - CPU and memory utilization (>80%)
- **Node Alerts** - CPU and memory critical thresholds (>90%)
- **Pod Alerts** - High restart rates, failed pods
- **API Server Alerts** - Error rate monitoring
- **Disk Space Alerts** - Storage capacity alerts (>85%)
- **Uptime Checks** - API server availability monitoring
- **Cost Anomaly Detection** - Unusual spending patterns

#### Uptime Checks

Configured for critical endpoints:
- GKE API server health checks (`/healthz`)
- Custom application endpoints
- 60-second check interval with 10-second timeout

### 2. Cloud Logging Integration

#### Log Sinks

Multiple log sinks for different purposes:

1. **GKE to Cloud Storage** - Long-term log archival
2. **GKE to BigQuery** - Log analysis with SQL
3. **Application to Cloud Storage** - Application logs
4. **Errors to Pub/Sub** - Real-time error processing

#### Storage Bucket Lifecycle

- **0-90 days**: Standard storage
- **90-365 days**: Nearline storage
- **365-730 days**: Coldline storage
- **>730 days**: Automatic deletion

#### BigQuery Integration

- Partitioned tables for efficient querying
- 90-day table expiration
- SQL-based log analysis
- Integration with data visualization tools

#### OpenSearch Integration

Error logs are exported to Pub/Sub and can be consumed by OpenSearch for:
- Real-time log indexing
- Full-text search capabilities
- Log correlation and analysis
- Custom alerting rules

#### Log-based Metrics

Automatically created metrics from log data:

- **Request Latency** - HTTP request duration distribution
- **HTTP Status Codes** - Status code counts by service
- **Database Query Duration** - Query performance metrics
- **Error Count by Type** - Error categorization

### 3. Cloud Trace Integration

Cloud Trace provides distributed tracing for GCP services and applications.

#### Features

- **Automatic instrumentation** - GKE services automatically instrumented
- **Latency analysis** - Request latency breakdown
- **Service dependency mapping** - Visualize service relationships
- **Performance insights** - Identify bottlenecks

#### Integration with OpenTelemetry

The OpenTelemetry Collector exports traces to both:
- **Cloud Trace** - Native GCP trace visualization
- **Jaeger** - Open-source trace visualization in Grafana

### 4. OpenTelemetry Collector

Unified observability data collection and export.

#### Receivers

- **OTLP** - OpenTelemetry Protocol (gRPC and HTTP)
- **Prometheus** - Scrape Prometheus metrics from Kubernetes pods
- **Google Cloud Monitoring** - Import GCP metrics

#### Processors

- **Batch** - Batching for performance (1024 batch size)
- **Memory Limiter** - Prevent OOM (512Mi limit)
- **Resource Detection** - Automatic GCP metadata enrichment
- **Attributes** - Add custom attributes (cluster name, environment, etc.)
- **Transform** - Metric manipulation

#### Exporters

- **Google Cloud** - Export to Cloud Trace, Cloud Monitoring, Cloud Logging
- **Jaeger** - Export traces to Jaeger for visualization
- **Prometheus Remote Write** - Export metrics to Grafana Cloud
- **Logging** - Debug exporter for troubleshooting

#### Deployment

```bash
# Set environment variables
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
export CLUSTER_NAME="fawkes-prod"
export ENVIRONMENT="production"
export JAEGER_ENDPOINT="jaeger-collector.fawkes:14250"
export PROMETHEUS_REMOTE_WRITE_ENDPOINT="https://prometheus.grafana.net/api/prom/push"

# Deploy OpenTelemetry Collector
envsubst < platform/observability/gcp/otel-collector-config.yaml | kubectl apply -f -

# Verify deployment
kubectl get pods -n gcp-observability -l app=otel-collector
kubectl logs -n gcp-observability -l app=otel-collector
```

#### IAM Configuration

The OpenTelemetry Collector requires Workload Identity:

```bash
# Create GCP service account
gcloud iam service-accounts create otel-collector \
  --display-name="OpenTelemetry Collector"

# Grant necessary permissions
gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:otel-collector@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/cloudtrace.agent"

gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:otel-collector@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/monitoring.metricWriter"

gcloud projects add-iam-policy-binding ${GCP_PROJECT_ID} \
  --member="serviceAccount:otel-collector@${GCP_PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/logging.logWriter"

# Bind Kubernetes SA to GCP SA
gcloud iam service-accounts add-iam-policy-binding \
  otel-collector@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[gcp-observability/otel-collector]"
```

### 5. Cloud Billing Integration

#### BigQuery Export

Enable Cloud Billing export to BigQuery:

```bash
# Enable Billing Export API
gcloud services enable bigquerydatatransfer.googleapis.com

# Export billing data to BigQuery
gcloud billing accounts describe ${BILLING_ACCOUNT_ID}

# Note: Billing export is configured in the GCP Console:
# Billing -> Billing Export -> BigQuery Export
```

#### Cost Metrics

The cost-collector service processes BigQuery billing data and exports metrics to Prometheus:

- `gcp_cost_usage_blended_cost` - Cost by service, resource, region
- `gcp_cost_cud_covered_cost` - Committed use discount coverage
- `gcp_cost_sustained_use_discount_savings` - Sustained use discount savings
- `gcp_cost_optimization_savings_potential` - Potential savings from optimization
- `gcp_cost_optimization_idle_resource_cost` - Cost of idle resources
- `gcp_cost_anomaly` - Detected cost anomalies

#### Cost-Collector Service Integration

The cost-collector service subscribes to the cost alerts Pub/Sub topic:

```bash
# Deploy cost-collector (if not already deployed)
kubectl apply -f platform/apps/cost-collector/

# Verify subscription
gcloud pubsub subscriptions describe ${CLUSTER_NAME}-cost-collector-sub
```

#### Grafana Dashboard

The GCP cost dashboard provides:

- **Total Monthly Cost** - Current month spending
- **Daily Cost Trend** - Average daily cost over 7 days
- **Cost vs Budget** - Percentage of budget consumed
- **Projected Month-End Cost** - Estimated end-of-month cost
- **Cost by Service** - Top 10 services by cost
- **Cost by Resource** - Top 10 most expensive resources
- **GKE Cluster Costs** - Breakdown by cluster and component
- **Cost Optimization** - Idle resources, CUD coverage, potential savings
- **Cost Anomalies** - Unusual spending patterns
- **Cost by Region** - Regional cost breakdown
- **Cost by Project** - Project-level cost breakdown

### 6. Pub/Sub Alert Integration

#### Topics

Three Pub/Sub topics are created for alert routing:

1. **Critical Alerts** - `{cluster_name}-critical-alerts`
2. **Warning Alerts** - `{cluster_name}-warning-alerts`
3. **Cost Alerts** - `{cluster_name}-cost-alerts`

#### Subscriptions

Subscriptions are automatically created for:

- **Mattermost** - Push subscriptions for critical and warning alerts
- **Cost-Collector** - Pull subscription for billing alerts

#### Mattermost Integration

Configure Mattermost webhook URL in Terraform:

```hcl
module "gcp_monitoring_alerts" {
  source = "./platform/observability/gcp/monitoring"
  
  cluster_name            = "fawkes-prod"
  project_id              = var.project_id
  mattermost_webhook_url  = var.mattermost_webhook_url
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

#### Alert Format

Pub/Sub messages include:

```json
{
  "incident": {
    "incident_id": "0.abc123...",
    "resource_id": "//container.googleapis.com/projects/PROJECT/zones/ZONE/clusters/CLUSTER",
    "resource_name": "GKE Cluster",
    "policy_name": "fawkes-prod-node-cpu-critical",
    "condition_name": "Node CPU Utilization > 90%",
    "url": "https://console.cloud.google.com/monitoring/alerting/incidents/...",
    "state": "open",
    "started_at": 1234567890,
    "summary": "Node CPU utilization is critically high (>90%)"
  }
}
```

## Terraform Deployment

### Prerequisites

- Terraform >= 1.6.0
- gcloud CLI configured
- GKE cluster already deployed
- Appropriate IAM permissions

### Variables

```hcl
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "mattermost_webhook_url" {
  description = "Mattermost incoming webhook URL"
  type        = string
  sensitive   = true
}

variable "cost_collector_endpoint" {
  description = "Cost-collector service endpoint"
  type        = string
  default     = "http://cost-collector.fawkes/webhook"
}

variable "api_server_endpoint" {
  description = "GKE API server endpoint for uptime checks"
  type        = string
}
```

### Deployment

```bash
# Initialize Terraform
cd platform/observability/gcp/monitoring
terraform init

# Plan changes
terraform plan \
  -var="cluster_name=fawkes-prod" \
  -var="project_id=${GCP_PROJECT_ID}" \
  -var="region=us-central1" \
  -var="mattermost_webhook_url=${MATTERMOST_WEBHOOK_URL}" \
  -var="api_server_endpoint=${API_SERVER_ENDPOINT}"

# Apply configuration
terraform apply \
  -var="cluster_name=fawkes-prod" \
  -var="project_id=${GCP_PROJECT_ID}" \
  -var="region=us-central1" \
  -var="mattermost_webhook_url=${MATTERMOST_WEBHOOK_URL}" \
  -var="api_server_endpoint=${API_SERVER_ENDPOINT}"

# Deploy logging configuration
cd ../logging
terraform init
terraform apply \
  -var="cluster_name=fawkes-prod" \
  -var="project_id=${GCP_PROJECT_ID}" \
  -var="region=us-central1"
```

## Integration with Existing Observability Stack

### Prometheus Integration

OpenTelemetry Collector exports metrics to Prometheus Remote Write:

```yaml
# In OTEL configuration
exporters:
  prometheusremotewrite:
    endpoint: http://prometheus.fawkes:9090/api/v1/write
```

### Grafana Integration

1. **Cloud Monitoring Data Source**:
   ```yaml
   apiVersion: 1
   datasources:
     - name: Google Cloud Monitoring
       type: stackdriver
       access: proxy
       jsonData:
         authenticationType: gce
         defaultProject: ${GCP_PROJECT_ID}
   ```

2. **Import GCP Cost Dashboard**:
   ```bash
   kubectl create configmap grafana-dashboard-gcp-costs \
     --from-file=platform/observability/grafana/dashboards/gcp-costs.json \
     -n fawkes
   ```

### Jaeger Integration

OpenTelemetry Collector forwards traces to Jaeger:

```yaml
# In OTEL configuration
exporters:
  jaeger:
    endpoint: jaeger-collector.fawkes:14250
```

## Monitoring Best Practices

### 1. Log Retention

Balance cost vs. compliance requirements:
- **Critical logs**: 90 days in standard storage
- **Debug logs**: 30 days
- **Audit logs**: 1 year minimum
- **Archive**: Move to Coldline after 365 days

### 2. Metric Granularity

- **Real-time monitoring**: 60-second intervals
- **Cost analysis**: 1-hour intervals
- **Trend analysis**: 1-day intervals

### 3. Alert Tuning

- Start with conservative thresholds (80% for warnings, 90% for critical)
- Monitor alert fatigue metrics
- Use log-based metrics for complex conditions
- Group related alerts to reduce noise

### 4. Cost Optimization

- Enable committed use discounts for predictable workloads
- Use sustained use discounts automatically
- Archive old logs to Coldline or Nearline storage
- Delete logs older than 2 years
- Monitor idle resources and scale down
- Use preemptible VMs for non-critical workloads

## Troubleshooting

### OpenTelemetry Collector Issues

```bash
# Check collector logs
kubectl logs -n gcp-observability -l app=otel-collector

# Verify configuration
kubectl get configmap otel-collector-config -n gcp-observability -o yaml

# Check health endpoint
kubectl port-forward -n gcp-observability deploy/otel-collector 13133:13133
curl http://localhost:13133
```

### Cloud Logging Not Working

```bash
# Verify GKE logging is enabled
gcloud container clusters describe ${CLUSTER_NAME} \
  --region=${GCP_REGION} \
  --format="value(loggingService)"

# Check log sinks
gcloud logging sinks list

# Verify log sink permissions
gcloud logging sinks describe ${CLUSTER_NAME}-gke-to-storage
```

### Pub/Sub Alerts Not Working

```bash
# Check Pub/Sub topics
gcloud pubsub topics list | grep ${CLUSTER_NAME}

# Check subscriptions
gcloud pubsub subscriptions list | grep ${CLUSTER_NAME}

# Test publishing to topic
gcloud pubsub topics publish ${CLUSTER_NAME}-critical-alerts \
  --message "Test alert"

# Pull messages from subscription
gcloud pubsub subscriptions pull ${CLUSTER_NAME}-cost-collector-sub --limit=5
```

### Cloud Trace Not Showing Traces

```bash
# Verify OTEL collector is running
kubectl get pods -n gcp-observability -l app=otel-collector

# Check OTEL collector logs for trace export errors
kubectl logs -n gcp-observability -l app=otel-collector | grep -i trace

# Verify Workload Identity is configured
kubectl describe sa otel-collector -n gcp-observability

# Check IAM permissions
gcloud projects get-iam-policy ${GCP_PROJECT_ID} \
  --flatten="bindings[].members" \
  --filter="bindings.members:serviceAccount:otel-collector@${GCP_PROJECT_ID}.iam.gserviceaccount.com"
```

### Cost Data Not Appearing in Grafana

```bash
# Verify BigQuery billing export is enabled
# Check in GCP Console: Billing -> Billing Export

# Check cost-collector service
kubectl get pods -n fawkes -l app=cost-collector
kubectl logs -n fawkes -l app=cost-collector

# Verify Prometheus metrics
kubectl port-forward -n fawkes svc/prometheus 9090:9090
# Open http://localhost:9090 and search for gcp_cost_*

# Check Grafana data source
kubectl port-forward -n fawkes svc/grafana 3000:3000
# Open http://localhost:3000 and check Prometheus data source
```

## Security Considerations

1. **Encryption**:
   - Pub/Sub topics use default encryption at rest
   - Use customer-managed encryption keys (CMEK) for sensitive data
   - TLS in transit for all data

2. **IAM Roles**:
   - Use Workload Identity (IAM for Service Accounts)
   - Follow principle of least privilege
   - Regularly audit IAM permissions
   - Use separate service accounts per component

3. **Network Security**:
   - Use Private GKE clusters
   - Restrict egress traffic with firewall rules
   - Enable VPC Flow Logs
   - Use Cloud Armor for DDoS protection

4. **Audit**:
   - Enable Cloud Audit Logs
   - Monitor privileged operations
   - Alert on suspicious activities
   - Regular security reviews

## Cost Estimates

Based on typical usage for a production GKE cluster:

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| Cloud Monitoring | 100 metrics, 60s resolution | $25-30 |
| Cloud Logging | 50 GB ingested, 30-day retention | $25-30 |
| Cloud Trace | 1M spans/month | $2-5 |
| Cloud Storage | 500 GB logs (Nearline) | $10-15 |
| BigQuery | 100 GB storage, 500 GB queries | $15-20 |
| Pub/Sub | 10K messages | $0.50 |
| **Total** | | **~$80-100/month** |

## Performance Impact

- **OpenTelemetry Collector**: 200m CPU, 512Mi memory per pod (2 replicas)
- **Network overhead**: ~1-2% of application traffic
- **Application instrumentation**: <1% CPU overhead
- **Log export**: Minimal impact with batching

## References

- [Google Cloud Monitoring Documentation](https://cloud.google.com/monitoring/docs)
- [Google Cloud Logging Documentation](https://cloud.google.com/logging/docs)
- [Google Cloud Trace Documentation](https://cloud.google.com/trace/docs)
- [OpenTelemetry Collector Documentation](https://opentelemetry.io/docs/collector/)
- [GKE Observability Best Practices](https://cloud.google.com/kubernetes-engine/docs/how-to/monitoring)
- [Cloud Billing Export](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)

## Support

For issues or questions:
- File an issue in the Fawkes repository
- Contact the platform team via Mattermost #platform-observability
- Check the [Fawkes documentation](../../docs/)

## License

MIT License - See LICENSE file for details.
