# AWS Observability Integration

## Overview

This directory contains AWS-native observability integrations for the Fawkes platform. It provides comprehensive monitoring, tracing, and cost analysis capabilities specifically for AWS infrastructure, particularly EKS (Elastic Kubernetes Service) clusters.

## Architecture

The AWS observability stack consists of four main components:

1. **CloudWatch Integration** - Metrics, logs, and dashboards
2. **X-Ray Integration** - Distributed tracing
3. **ADOT (AWS Distro for OpenTelemetry)** - Unified observability data collection
4. **Cost and Usage Reporting** - Financial operations and cost optimization

```
┌─────────────────────────────────────────────────────────┐
│                    EKS Cluster                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ Application  │  │  X-Ray       │  │    ADOT      │ │
│  │    Pods      │─>│  Daemon      │─>│  Collector   │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                  │                  │
           ├──────────────────┴──────────────────┘
           ▼
┌─────────────────────────────────────────────────────────┐
│                  AWS Observability                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │  CloudWatch  │  │   X-Ray      │  │     CUR      │ │
│  │ Logs/Metrics │  │ Service Map  │  │  (Costs)     │ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
└─────────────────────────────────────────────────────────┘
           │                  │                  │
           └──────────────────┴──────────────────┘
                              ▼
           ┌───────────────────────────────────┐
           │    Grafana Dashboards             │
           │  - EKS Metrics                    │
           │  - Cost Analysis                  │
           │  - Jaeger Traces                  │
           └───────────────────────────────────┘
```

## Directory Structure

```
platform/observability/aws/
├── cloudwatch/
│   ├── dashboards.tf          # CloudWatch dashboard definitions
│   └── alarms.tf              # CloudWatch alarms and SNS topics
├── xray/
│   └── daemon-daemonset.yaml  # X-Ray daemon deployment
├── adot-config.yaml           # ADOT collector configuration
├── log-insights-queries.json  # Pre-built CloudWatch Logs Insights queries
└── README.md                  # This file

platform/observability/grafana/dashboards/
└── aws-costs.json             # Grafana dashboard for AWS cost analysis
```

## Components

### 1. CloudWatch Integration

#### Dashboards

CloudWatch provides native AWS dashboards for EKS monitoring:

- **EKS Cluster Overview** - Control plane metrics, node count, pod count
- **EKS Node Group** - Node CPU/memory/disk/network metrics
- **Application Performance** - Container Insights metrics
- **Cost and Usage** - Resource cost tracking

#### Alarms

Critical and warning alarms with SNS integration:

- **Control Plane Alarms** - CPU and memory utilization
- **Node Alarms** - Resource exhaustion detection
- **Pod Alarms** - Restart and failure tracking
- **API Server Alarms** - Error rate monitoring
- **Disk Space Alarms** - Storage capacity alerts

#### Log Groups

EKS logs are organized by component:

- `/aws/eks/${CLUSTER_NAME}/cluster` - Control plane logs
  - `kube-apiserver` - API server logs
  - `kube-controller-manager` - Controller manager logs
  - `kube-scheduler` - Scheduler logs
  - `authenticator` - AWS IAM authenticator logs
  - `audit` - Kubernetes audit logs

#### Retention Policies

- **Control Plane Logs**: 30 days (configurable via `cluster_log_retention_days`)
- **Application Logs**: 14 days (default)
- **Cost and Usage Logs**: 90 days (recommended)

### 2. X-Ray Integration

X-Ray provides distributed tracing for AWS services and applications.

#### Deployment

```bash
# Deploy X-Ray daemon as DaemonSet
kubectl apply -f platform/observability/aws/xray/daemon-daemonset.yaml
```

#### Configuration

Environment variables can be set in the DaemonSet YAML:
- `AWS_REGION` - AWS region for X-Ray endpoint
- `XRAY_DAEMON_ROLE_ARN` - IAM role for X-Ray daemon (IRSA)

#### IAM Role Requirements

The X-Ray daemon requires the following permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "xray:PutTraceSegments",
        "xray:PutTelemetryRecords"
      ],
      "Resource": "*"
    }
  ]
}
```

#### Application Integration

Applications should send traces to the X-Ray daemon:

```yaml
env:
  - name: AWS_XRAY_DAEMON_ADDRESS
    value: "xray-daemon.aws-observability:2000"
```

### 3. ADOT (AWS Distro for OpenTelemetry)

ADOT provides a unified way to collect and export observability data.

#### Features

- **Multi-protocol support** - OTLP, Prometheus, X-Ray
- **Multiple exporters** - CloudWatch, X-Ray, Prometheus, Jaeger
- **Resource detection** - Automatic AWS metadata enrichment
- **Batching and buffering** - Optimized for performance

#### Deployment

```bash
# Deploy ADOT collector
kubectl apply -f platform/observability/aws/adot-config.yaml
```

#### Configuration

Key environment variables:
- `AWS_REGION` - AWS region
- `CLUSTER_NAME` - EKS cluster name
- `ENVIRONMENT` - Deployment environment (dev/staging/prod)
- `PROMETHEUS_REMOTE_WRITE_ENDPOINT` - Grafana Cloud endpoint
- `JAEGER_ENDPOINT` - Jaeger collector endpoint

#### Pipelines

1. **Traces Pipeline**: OTLP → X-Ray + Jaeger
2. **Metrics Pipeline**: Prometheus + OTLP → CloudWatch + Grafana
3. **Logs Pipeline**: OTLP → CloudWatch

### 4. Cost and Usage Reports (CUR)

Cost analysis and optimization using AWS Cost and Usage Reports.

#### Setup

1. **Enable CUR in AWS**:
   ```bash
   aws cur put-report-definition --report-definition \
     ReportName=fawkes-cur \
     TimeUnit=HOURLY \
     Format=Parquet \
     Compression=Parquet \
     S3Bucket=fawkes-cur-${ACCOUNT_ID} \
     S3Prefix=cur/ \
     S3Region=us-east-1 \
     AdditionalSchemaElements=RESOURCES
   ```

2. **Deploy cost-collector service** (if not already deployed):
   ```bash
   kubectl apply -f platform/apps/cost-collector/
   ```

3. **Configure Grafana dashboard**:
   ```bash
   kubectl apply -f platform/observability/grafana/dashboards/aws-costs.json
   ```

#### Metrics Collected

- Blended costs by service, resource, and tag
- Reserved Instance and Savings Plan coverage
- Idle resource identification
- Cost trends and forecasting

## CloudWatch Logs Insights Queries

The `log-insights-queries.json` file contains 20+ pre-built queries for common troubleshooting scenarios:

### Error Detection
- EKS API Server Errors
- Failed Pod Scheduling
- Authentication Failures
- Image Pull Errors
- Network Errors

### Performance Analysis
- High Latency API Requests
- Scheduler Performance
- Slow Database Queries

### Security Monitoring
- Audit Log Analysis
- Privilege Escalation Attempts
- Certificate Errors

### Resource Management
- Container Restarts
- OOM Kills
- Resource Exhaustion

### Cost Optimization
- Top Log Producers (for reducing log costs)

### Usage

1. **AWS Console**:
   - Navigate to CloudWatch → Logs → Insights
   - Select log groups
   - Copy query from JSON file
   - Run query

2. **AWS CLI**:
   ```bash
   aws logs start-query \
     --log-group-name /aws/eks/fawkes-prod/cluster \
     --start-time $(date -u -d '1 hour ago' +%s) \
     --end-time $(date -u +%s) \
     --query-string "$(cat log-insights-queries.json | jq -r '.queries[0].queryString')"
   ```

## SNS Integration for Alerting

### Mattermost Integration

CloudWatch alarms send notifications to SNS topics, which forward to Mattermost.

#### Setup

1. **Create Mattermost incoming webhook**:
   - Go to Mattermost → Integrations → Incoming Webhooks
   - Create webhook for monitoring channel
   - Copy webhook URL

2. **Configure Terraform**:
   ```hcl
   module "cloudwatch_alarms" {
     source = "./platform/observability/aws/cloudwatch"
     
     cluster_name            = "fawkes-prod"
     mattermost_webhook_url  = var.mattermost_webhook_url
     
     tags = {
       Environment = "production"
       Team        = "platform"
     }
   }
   ```

3. **Confirm SNS subscription**:
   - SNS sends confirmation to Mattermost
   - Click confirmation link in message

#### Alert Format

Alerts include:
- Alarm name and description
- Current state (ALARM/OK)
- Metric details
- Timestamp
- Link to AWS Console

## Terraform Deployment

### Prerequisites

- Terraform >= 1.6.0
- AWS CLI configured
- EKS cluster already deployed
- Appropriate IAM permissions

### Variables

```hcl
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "mattermost_webhook_url" {
  description = "Mattermost incoming webhook URL"
  type        = string
  sensitive   = true
}

variable "kms_key_id" {
  description = "KMS key ID for SNS encryption"
  type        = string
  default     = ""
}
```

### Deployment

```bash
# Initialize Terraform
cd platform/observability/aws/cloudwatch
terraform init

# Plan changes
terraform plan \
  -var="cluster_name=fawkes-prod" \
  -var="aws_region=us-east-1" \
  -var="mattermost_webhook_url=${MATTERMOST_WEBHOOK_URL}"

# Apply configuration
terraform apply \
  -var="cluster_name=fawkes-prod" \
  -var="aws_region=us-east-1" \
  -var="mattermost_webhook_url=${MATTERMOST_WEBHOOK_URL}"
```

## Integration with Existing Observability Stack

### Prometheus Integration

ADOT exports metrics to Prometheus Remote Write:

```yaml
# In ADOT configuration
exporters:
  prometheusremotewrite:
    endpoint: http://prometheus.fawkes:9090/api/v1/write
```

### Grafana Integration

1. **CloudWatch Data Source**:
   ```yaml
   apiVersion: 1
   datasources:
     - name: CloudWatch
       type: cloudwatch
       access: proxy
       jsonData:
         authType: default
         defaultRegion: us-east-1
   ```

2. **Import AWS Cost Dashboard**:
   ```bash
   kubectl create configmap grafana-dashboard-aws-costs \
     --from-file=platform/observability/grafana/dashboards/aws-costs.json \
     -n fawkes
   ```

### Jaeger Integration

ADOT forwards traces to Jaeger:

```yaml
# In ADOT configuration
exporters:
  jaeger:
    endpoint: jaeger-collector.fawkes:14250
```

## Monitoring Best Practices

### 1. Log Retention

Balance cost vs. compliance requirements:
- **Critical logs**: 90 days
- **Debug logs**: 7 days
- **Audit logs**: 1 year minimum

### 2. Metric Granularity

- **Real-time monitoring**: 1-minute intervals
- **Cost analysis**: 1-hour intervals
- **Trend analysis**: 1-day intervals

### 3. Alert Tuning

- Start with conservative thresholds
- Monitor alert fatigue metrics
- Use anomaly detection for dynamic thresholds
- Group related alerts

### 4. Cost Optimization

- Use CloudWatch Logs Insights instead of exporting to S3
- Enable log group retention policies
- Archive old logs to S3 Glacier
- Use metric filters to reduce metric costs

## Troubleshooting

### X-Ray Daemon Not Starting

```bash
# Check daemon logs
kubectl logs -n aws-observability -l app=xray-daemon

# Verify IAM role
kubectl describe sa xray-daemon -n aws-observability

# Check service connectivity
kubectl exec -n aws-observability deploy/adot-collector -- \
  nc -zv xray-daemon.aws-observability 2000
```

### ADOT Collector Issues

```bash
# Check collector logs
kubectl logs -n aws-observability deploy/adot-collector

# Verify configuration
kubectl get configmap adot-collector-config -n aws-observability -o yaml

# Check health endpoint
kubectl port-forward -n aws-observability deploy/adot-collector 13133:13133
curl http://localhost:13133
```

### CloudWatch Logs Not Appearing

```bash
# Verify EKS logging is enabled
aws eks describe-cluster --name fawkes-prod \
  --query 'cluster.logging.clusterLogging[0].enabled'

# Check log group exists
aws logs describe-log-groups \
  --log-group-name-prefix /aws/eks/fawkes-prod

# Verify IAM permissions
aws iam get-role --role-name fawkes-prod-cluster-role
```

### SNS Alerts Not Reaching Mattermost

```bash
# Check SNS topic subscriptions
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:fawkes-prod-critical-alerts

# Test SNS publish
aws sns publish \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT_ID:fawkes-prod-critical-alerts \
  --message "Test alert"

# Check CloudWatch alarm state
aws cloudwatch describe-alarms \
  --alarm-names fawkes-prod-control-plane-cpu-high
```

## Security Considerations

1. **Encryption**:
   - Enable KMS encryption for SNS topics
   - Use encryption at rest for CloudWatch Logs
   - TLS in transit for all data

2. **IAM Roles**:
   - Use IRSA (IAM Roles for Service Accounts)
   - Follow principle of least privilege
   - Regularly rotate credentials

3. **Network Security**:
   - Use VPC endpoints for AWS services
   - Restrict egress traffic
   - Enable VPC Flow Logs

4. **Audit**:
   - Enable CloudTrail for API auditing
   - Monitor privileged operations
   - Alert on suspicious activities

## Cost Estimates

Based on typical usage for a production EKS cluster:

| Service | Usage | Monthly Cost |
|---------|-------|--------------|
| CloudWatch Logs | 50 GB ingested, 30-day retention | $25-30 |
| CloudWatch Metrics | 100 custom metrics, 5-min resolution | $30-35 |
| CloudWatch Dashboards | 3 dashboards | $9 |
| X-Ray | 1M traces/month | $5 |
| SNS | 10K notifications | $0.50 |
| **Total** | | **~$70-80/month** |

## References

- [AWS CloudWatch Documentation](https://docs.aws.amazon.com/cloudwatch/)
- [AWS X-Ray Documentation](https://docs.aws.amazon.com/xray/)
- [ADOT Documentation](https://aws-otel.github.io/)
- [EKS Observability Best Practices](https://aws.github.io/aws-eks-best-practices/observability/)
- [CloudWatch Logs Insights Query Syntax](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/CWL_QuerySyntax.html)

## Support

For issues or questions:
- File an issue in the Fawkes repository
- Contact the platform team via Mattermost #platform-observability
- Check the [Fawkes documentation](../../docs/)

## License

MIT License - See LICENSE file for details.
