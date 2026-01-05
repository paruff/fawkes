# GCP Observability - Deployment Guide

This guide provides step-by-step instructions for deploying GCP observability to your GKE cluster.

## Prerequisites

- Terraform >= 1.6.0
- gcloud CLI installed and configured
- kubectl configured for your GKE cluster
- Appropriate GCP IAM permissions:
  - `roles/monitoring.admin`
  - `roles/logging.admin`
  - `roles/pubsub.admin`
  - `roles/storage.admin`
  - `roles/bigquery.admin`

## Step 1: Enable Required GCP APIs

```bash
# Set your project ID
export GCP_PROJECT_ID="your-project-id"
gcloud config set project ${GCP_PROJECT_ID}

# Enable required APIs
gcloud services enable \
  monitoring.googleapis.com \
  logging.googleapis.com \
  cloudtrace.googleapis.com \
  pubsub.googleapis.com \
  bigquery.googleapis.com \
  storage.googleapis.com \
  compute.googleapis.com \
  container.googleapis.com
```

## Step 2: Configure IAM for Workload Identity

```bash
export CLUSTER_NAME="fawkes-prod"
export GCP_REGION="us-central1"

# Create service account for OpenTelemetry Collector
gcloud iam service-accounts create otel-collector \
  --display-name="OpenTelemetry Collector" \
  --project=${GCP_PROJECT_ID}

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

# Bind Kubernetes service account to GCP service account
gcloud iam service-accounts add-iam-policy-binding \
  otel-collector@${GCP_PROJECT_ID}.iam.gserviceaccount.com \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:${GCP_PROJECT_ID}.svc.id.goog[gcp-observability/otel-collector]"
```

## Step 3: Deploy Cloud Monitoring Dashboards and Alerts

```bash
cd platform/observability/gcp/monitoring

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# Required: cluster_name, project_id, region
# Optional: mattermost_webhook_url, cost_collector_endpoint, api_server_endpoint

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply configuration
terraform apply

# Note the outputs
terraform output
```

## Step 4: Deploy Cloud Logging Configuration

```bash
cd ../logging

# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# Required: cluster_name, project_id, region
# Optional: opensearch_endpoint

# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply configuration
terraform apply

# Note the outputs
terraform output
```

## Step 5: Deploy OpenTelemetry Collector

```bash
cd ..

# Set environment variables for substitution
export GCP_PROJECT_ID="your-project-id"
export GCP_REGION="us-central1"
export CLUSTER_NAME="fawkes-prod"
export ENVIRONMENT="production"
export JAEGER_ENDPOINT="jaeger-collector.fawkes.svc.cluster.local:14250"
export PROMETHEUS_REMOTE_WRITE_ENDPOINT="http://prometheus.fawkes.svc.cluster.local:9090/api/v1/write"

# Optional: If using Grafana Cloud
# export PROMETHEUS_REMOTE_WRITE_ENDPOINT="https://prometheus-prod-XX-XX.grafana.net/api/prom/push"
# kubectl create secret generic prometheus-remote-write \
#   --from-literal=token="YOUR_GRAFANA_CLOUD_API_KEY" \
#   -n gcp-observability

# Deploy OpenTelemetry Collector
envsubst < otel-collector-config.yaml | kubectl apply -f -

# Verify deployment
kubectl get pods -n gcp-observability -l app=otel-collector
kubectl logs -n gcp-observability -l app=otel-collector --tail=50
```

## Step 6: Enable Cloud Billing Export

```bash
# Enable BigQuery Data Transfer API
gcloud services enable bigquerydatatransfer.googleapis.com

# Create BigQuery dataset for billing data
bq mk --dataset \
  --location=${GCP_REGION} \
  --description="GCP Billing Export" \
  ${GCP_PROJECT_ID}:billing_export

# Configure billing export in GCP Console:
# 1. Go to: Billing -> Billing Export -> BigQuery Export
# 2. Enable "Detailed usage cost"
# 3. Select project: ${GCP_PROJECT_ID}
# 4. Select dataset: billing_export
# 5. Click "Save"
```

## Step 7: Deploy Grafana Dashboard

```bash
# Create ConfigMap for GCP costs dashboard
kubectl create configmap grafana-dashboard-gcp-costs \
  --from-file=../grafana/dashboards/gcp-costs.json \
  -n fawkes \
  --dry-run=client -o yaml | kubectl apply -f -

# Label the ConfigMap for Grafana discovery
kubectl label configmap grafana-dashboard-gcp-costs \
  grafana_dashboard=1 \
  -n fawkes

# Restart Grafana to pick up the new dashboard
kubectl rollout restart deployment grafana -n fawkes
```

## Step 8: Verify Installation

### Check Cloud Monitoring Dashboards

```bash
# List dashboards
gcloud monitoring dashboards list --project=${GCP_PROJECT_ID} | grep ${CLUSTER_NAME}

# You should see:
# - fawkes-prod-gke-overview
# - fawkes-prod-gke-node-performance
# - fawkes-prod-app-performance
# - fawkes-prod-cost-usage
```

### Check Alert Policies

```bash
# List alert policies
gcloud alpha monitoring policies list --project=${GCP_PROJECT_ID} | grep ${CLUSTER_NAME}

# You should see 8+ alert policies
```

### Check Pub/Sub Topics and Subscriptions

```bash
# List topics
gcloud pubsub topics list --project=${GCP_PROJECT_ID} | grep ${CLUSTER_NAME}

# List subscriptions
gcloud pubsub subscriptions list --project=${GCP_PROJECT_ID} | grep ${CLUSTER_NAME}
```

### Check Log Sinks

```bash
# List log sinks
gcloud logging sinks list --project=${GCP_PROJECT_ID} | grep ${CLUSTER_NAME}

# You should see:
# - fawkes-prod-gke-to-storage
# - fawkes-prod-gke-to-bigquery
# - fawkes-prod-app-to-storage
# - fawkes-prod-errors-to-pubsub
```

### Check OpenTelemetry Collector

```bash
# Check pods
kubectl get pods -n gcp-observability -l app=otel-collector

# Check service
kubectl get svc -n gcp-observability otel-collector

# Check health endpoint
kubectl port-forward -n gcp-observability svc/otel-collector 13133:13133
curl http://localhost:13133
```

### Check Grafana Dashboard

```bash
# Port-forward to Grafana
kubectl port-forward -n fawkes svc/grafana 3000:3000

# Open browser to http://localhost:3000
# Navigate to Dashboards -> Browse
# You should see "GCP Cost Analysis" dashboard
```

## Step 9: Test Alert Integration

### Test Pub/Sub to Mattermost

```bash
# Publish a test message to critical alerts topic
gcloud pubsub topics publish ${CLUSTER_NAME}-critical-alerts \
  --message='{"incident":{"policy_name":"test-alert","summary":"This is a test alert"}}' \
  --project=${GCP_PROJECT_ID}

# Check Mattermost channel for the message
```

### Test Alert Policy

```bash
# Trigger a test alert by generating high CPU load
kubectl run cpu-stress --image=progrium/stress \
  --restart=Never \
  -- --cpu 4 --timeout 300s

# Wait 5-10 minutes for the alert to trigger
# Check Pub/Sub topic for messages
gcloud pubsub subscriptions pull ${CLUSTER_NAME}-mattermost-critical-sub \
  --limit=5 \
  --project=${GCP_PROJECT_ID}
```

## Step 10: Monitor and Tune

### View Metrics in Cloud Console

1. Go to: https://console.cloud.google.com/monitoring
2. Click on "Dashboards" -> Find your cluster dashboards
3. Review metrics and ensure data is flowing

### View Logs in Cloud Console

1. Go to: https://console.cloud.google.com/logs
2. Select your GKE cluster resource
3. View logs from containers

### View Traces in Cloud Console

1. Go to: https://console.cloud.google.com/traces
2. Select your project
3. View trace data from applications

### View Billing Data in BigQuery

```bash
# Query billing data
bq query --use_legacy_sql=false '
SELECT
  service.description as service,
  SUM(cost) as total_cost
FROM `'${GCP_PROJECT_ID}'.billing_export.gcp_billing_export_v1_*`
WHERE _TABLE_SUFFIX >= FORMAT_DATE("%Y%m%d", DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY))
GROUP BY service
ORDER BY total_cost DESC
LIMIT 10
'
```

## Troubleshooting

### OpenTelemetry Collector Not Starting

```bash
# Check logs
kubectl logs -n gcp-observability -l app=otel-collector

# Common issues:
# 1. Workload Identity not configured correctly
# 2. Missing IAM permissions
# 3. Environment variables not set correctly

# Verify Workload Identity
kubectl describe sa otel-collector -n gcp-observability | grep Annotations
```

### Alerts Not Triggering

```bash
# Check alert policy status
gcloud alpha monitoring policies list --project=${GCP_PROJECT_ID}

# Check notification channels
gcloud alpha monitoring channels list --project=${GCP_PROJECT_ID}

# Test notification channel
gcloud alpha monitoring channels describe CHANNEL_ID --project=${GCP_PROJECT_ID}
```

### Logs Not Appearing in BigQuery

```bash
# Check log sink status
gcloud logging sinks describe ${CLUSTER_NAME}-gke-to-bigquery --project=${GCP_PROJECT_ID}

# Verify BigQuery dataset exists
bq ls --project_id=${GCP_PROJECT_ID}

# Check IAM permissions on dataset
bq show --format=prettyjson ${GCP_PROJECT_ID}:fawkes_prod_logs
```

## Cost Management

Expected monthly costs for a production GKE cluster:

- Cloud Monitoring: ~$25-30
- Cloud Logging: ~$25-30
- Cloud Trace: ~$2-5
- Cloud Storage (logs): ~$10-15
- BigQuery: ~$15-20
- Pub/Sub: ~$0.50
- **Total: ~$80-100/month**

## Security Considerations

1. **Enable encryption at rest** for Cloud Storage buckets
2. **Use VPC Service Controls** to restrict data exfiltration
3. **Enable Cloud Audit Logs** for all services
4. **Use Workload Identity** instead of service account keys
5. **Regularly rotate credentials** and review IAM permissions
6. **Use Secret Manager** for sensitive configuration

## Next Steps

1. Configure custom dashboards for your applications
2. Create custom log-based metrics
3. Set up SLOs (Service Level Objectives)
4. Configure error budgets
5. Implement cost optimization recommendations
6. Set up automated reports

## Support

For issues or questions:
- File an issue in the Fawkes repository
- Contact the platform team via Mattermost #platform-observability
- Check the [main README](README.md) for detailed documentation
