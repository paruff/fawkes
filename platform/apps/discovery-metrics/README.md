# Discovery Metrics Service Deployment

This directory contains Kubernetes manifests for deploying the Discovery Metrics Service.

## Overview

The Discovery Metrics Service tracks continuous discovery activities including:

- Interviews conducted
- Insights captured
- Experiments run
- Features validated
- Team performance metrics
- ROI calculations

## Components

### Service Deployment (`deployment.yaml`)

- **ConfigMap**: Environment configuration
- **Secret**: API keys and credentials
- **Deployment**: FastAPI service (2 replicas)
- **Service**: ClusterIP service exposing port 8000
- **Ingress**: HTTPS access via `discovery-metrics.fawkes.idp`
- **ServiceMonitor**: Prometheus metrics scraping
- **PodDisruptionBudget**: HA configuration

### Database Resources

See `../postgresql/`:

- `db-discovery-cluster.yaml`: PostgreSQL cluster (3 replicas)
- `db-discovery-credentials.yaml`: Database credentials

### ArgoCD Application

`../discovery-metrics-application.yaml`: GitOps configuration

## Deployment

### Prerequisites

1. CloudNativePG operator installed
2. Ingress controller configured
3. cert-manager for TLS
4. Prometheus operator (optional, for metrics)

### Deploy Database

```bash
kubectl apply -f ../postgresql/db-discovery-cluster.yaml
kubectl apply -f ../postgresql/db-discovery-credentials.yaml

# Wait for database to be ready
kubectl wait --for=condition=Ready cluster/db-discovery-dev -n fawkes --timeout=300s
```

### Deploy Service

```bash
# Via ArgoCD (recommended)
kubectl apply -f ../discovery-metrics-application.yaml

# Or directly via kubectl
kubectl apply -k .

# Wait for deployment
kubectl wait --for=condition=Ready pod -l app=discovery-metrics -n fawkes --timeout=300s
```

### Verify Deployment

```bash
# Check pods
kubectl get pods -n fawkes -l app=discovery-metrics

# Check service
kubectl get svc -n fawkes discovery-metrics

# Check ingress
kubectl get ingress -n fawkes discovery-metrics

# Test health endpoint
curl https://discovery-metrics.fawkes.idp/health

# Test metrics endpoint
curl https://discovery-metrics.fawkes.idp/metrics
```

## Access URLs

- **API**: https://discovery-metrics.fawkes.idp
- **API Docs**: https://discovery-metrics.fawkes.idp/docs
- **Metrics**: https://discovery-metrics.fawkes.idp/metrics
- **Health**: https://discovery-metrics.fawkes.idp/health
- **Dashboard**: https://grafana.fawkes.idp/d/discovery-metrics

## Resource Usage

Target: <70% CPU/Memory utilization

| Component  | Requests            | Limits              | Replicas |
| ---------- | ------------------- | ------------------- | -------- |
| Service    | 200m CPU, 256Mi RAM | 1 CPU, 1Gi RAM      | 2        |
| PostgreSQL | 200m CPU, 256Mi RAM | 500m CPU, 512Mi RAM | 3        |
| **Total**  | 800m-2.1 CPU        | 2.28-4.5 CPU        | -        |

## Monitoring

### Prometheus Metrics

The ServiceMonitor configures Prometheus to scrape metrics from `/metrics` endpoint every 30s.

Key metrics exposed:

- `discovery_interviews_total`
- `discovery_insights_total`
- `discovery_experiments_total`
- `discovery_features_validated`
- `discovery_validation_rate`
- `discovery_avg_time_to_validation_days`
- And more...

### Grafana Dashboard

Located at: `../grafana/dashboards/discovery-metrics-dashboard.json`

Includes panels for:

- Discovery overview stats
- Activity trends
- Status breakdowns
- Insights analysis
- Performance metrics
- Recent activity

## Database Schema

The service automatically creates tables on startup:

- `interviews`: Interview tracking
- `discovery_insights`: Insight management
- `experiments`: Experiment tracking
- `feature_validations`: Feature validation
- `team_performance`: Team metrics

## Security

- Non-root container (user 1000)
- Read-only root filesystem
- Dropped capabilities
- TLS encryption via cert-manager
- Secrets managed via Kubernetes Secrets (Vault-ready)

⚠️ **Production Security Checklist**:

- [ ] Replace default API_KEY in Secret
- [ ] Replace default database password
- [ ] Configure External Secrets Operator for Vault
- [ ] Review ingress annotations
- [ ] Configure backup S3 credentials

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod -n fawkes -l app=discovery-metrics
kubectl logs -n fawkes -l app=discovery-metrics --tail=100
```

### Database connection issues

```bash
# Check database status
kubectl get cluster -n fawkes db-discovery-dev

# Check database logs
kubectl logs -n fawkes db-discovery-dev-1
```

### Metrics not appearing

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n fawkes discovery-metrics

# Check Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# Navigate to http://localhost:9090/targets
```

## Related Documentation

- [Discovery Metrics Service README](../../../services/discovery-metrics/README.md)
- [Continuous Discovery Workflow](../../../docs/playbooks/continuous-discovery-workflow.md)
- [Product Discovery Flow (IP3dP)](../../../docs/explanation/idp/product-discovery-delivery-flow.md)

## Support

For issues or questions:

1. Check application logs
2. Review Prometheus and Grafana
3. Check database connectivity
4. Open an issue in GitHub repository
