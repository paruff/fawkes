# Experimentation Service - A/B Testing Framework

A/B testing framework with statistical analysis, variant assignment, and results dashboards.

## Overview

The Experimentation Service provides a complete A/B testing platform that integrates with:
- **Unleash**: Feature flag management for experiment traffic control
- **Plausible**: Analytics platform for event tracking
- **Prometheus/Grafana**: Metrics and visualization

## Components

### 1. Experimentation Service (FastAPI)
- Experiment CRUD operations
- Variant assignment using consistent hashing
- Event tracking and analytics
- Statistical analysis engine
- **Deployment**: 2 replicas, 200m-1 CPU, 256Mi-1Gi RAM

### 2. PostgreSQL Database (CloudNativePG)
- Experiment metadata storage
- Variant assignments
- Event tracking data
- **Deployment**: 3 instances (HA), 200m-500m CPU, 256Mi-512Mi RAM

## Deployment

### Prerequisites

1. CloudNativePG operator installed
2. Ingress controller configured
3. cert-manager for TLS
4. Unleash and Plausible deployed (optional but recommended)

### Deploy via ArgoCD

```bash
# Deploy PostgreSQL cluster first
kubectl apply -f platform/apps/postgresql/db-experiment-cluster.yaml
kubectl apply -f platform/apps/postgresql/db-experiment-credentials.yaml

# Wait for database to be ready
kubectl wait --for=condition=Ready cluster/db-experiment-dev -n fawkes --timeout=300s

# Deploy Experimentation Service
kubectl apply -f platform/apps/experimentation-application.yaml

# Wait for deployment
kubectl wait --for=condition=Ready pod -l app=experimentation -n fawkes --timeout=300s
```

### Validation

```bash
# Check deployment status
kubectl get pods -n fawkes -l app=experimentation

# Check database cluster
kubectl get cluster db-experiment-dev -n fawkes

# Test health endpoint
kubectl exec -n fawkes deployment/experimentation -- \
  curl -s http://localhost:8000/health

# View logs
kubectl logs -n fawkes -l app=experimentation --tail=100
```

## Access

- **API**: https://experimentation.fawkes.idp
- **Metrics**: https://experimentation.fawkes.idp/metrics
- **Health**: https://experimentation.fawkes.idp/health
- **Dashboard**: https://grafana.fawkes.idp/d/experimentation

## Configuration

### Environment Variables

Configured via ConfigMap and Secrets:
- `DATABASE_URL` - PostgreSQL connection string (from secret)
- `ADMIN_TOKEN` - API authentication token (from secret)
- `UNLEASH_URL` - Unleash API endpoint
- `PLAUSIBLE_URL` - Plausible API endpoint

### Security

⚠️ **Production Security**:
1. Replace default credentials in secrets
2. Use External Secrets Operator with Vault
3. Enable TLS for database connections
4. Rotate tokens regularly

## Quick Start Example

### 1. Create Experiment

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments \
  -H "Authorization: Bearer dev-admin-token" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New Dashboard Layout",
    "description": "Testing new dashboard vs. current layout",
    "hypothesis": "New layout will increase engagement by 15%",
    "variants": [
      {"name": "control", "allocation": 0.5, "config": {}},
      {"name": "new-layout", "allocation": 0.5, "config": {"layout": "v2"}}
    ],
    "metrics": ["page_view", "click", "conversion"],
    "target_sample_size": 1000,
    "significance_level": 0.05,
    "traffic_allocation": 0.2
  }'
```

### 2. Start Experiment

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/start \
  -H "Authorization: Bearer dev-admin-token"
```

### 3. Get Variant Assignment

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/assign \
  -H "Content-Type: application/json" \
  -d '{"user_id": "user123"}'
```

### 4. Track Events

```bash
curl -X POST https://experimentation.fawkes.idp/api/v1/experiments/{id}/track \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "user123",
    "event_name": "conversion",
    "value": 1.0
  }'
```

### 5. View Results

```bash
curl https://experimentation.fawkes.idp/api/v1/experiments/{id}/stats
```

## Integration

### Backstage Integration

Add to `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/experimentation/api':
      target: http://experimentation.fawkes.svc:8000/api/
      changeOrigin: true
```

### Application Integration

```typescript
// TypeScript/JavaScript example
import axios from 'axios';

async function getExperimentVariant(experimentId: string, userId: string) {
  const response = await axios.post(
    `https://experimentation.fawkes.idp/api/v1/experiments/${experimentId}/assign`,
    { user_id: userId }
  );
  return response.data.variant;
}

async function trackEvent(experimentId: string, userId: string, eventName: string) {
  await axios.post(
    `https://experimentation.fawkes.idp/api/v1/experiments/${experimentId}/track`,
    { user_id: userId, event_name: eventName, value: 1.0 }
  );
}
```

## Monitoring

### Prometheus Metrics

The service exposes comprehensive metrics:
- `experimentation_experiments_total{status}` - Total experiments
- `experimentation_variant_assignments_total{experiment_id,variant}` - Assignments
- `experimentation_events_total{experiment_id,variant,event_name}` - Events tracked
- `experimentation_significant_results_total{experiment_id}` - Significant findings

### Grafana Dashboard

Pre-built dashboard available at `/grafana/d/experimentation` includes:
- Active experiments gauge
- Variant assignment distribution
- Conversion rate comparison
- Statistical significance indicators
- P-value trends
- Sample size progress bars

## Troubleshooting

### Pods not starting

```bash
# Check pod status
kubectl describe pod -n fawkes -l app=experimentation

# View logs
kubectl logs -n fawkes -l app=experimentation
```

### Database connection issues

```bash
# Verify database is ready
kubectl get cluster db-experiment-dev -n fawkes

# Check credentials
kubectl get secret db-experiment-credentials -n fawkes -o yaml

# Test connection
kubectl exec -n fawkes deployment/experimentation -- \
  python -c "from app.database import engine; engine.connect()"
```

### API errors

```bash
# Check API health
kubectl exec -n fawkes deployment/experimentation -- \
  curl -s http://localhost:8000/health

# View recent logs
kubectl logs -n fawkes -l app=experimentation --tail=50
```

## Resource Usage

Target: <70% CPU/Memory utilization

| Component | Requests | Limits | Replicas | Total |
|-----------|----------|--------|----------|-------|
| Experimentation | 200m CPU, 256Mi | 1 CPU, 1Gi | 2 | 400m-2 CPU, 512Mi-2Gi |
| PostgreSQL | 200m CPU, 256Mi | 500m CPU, 512Mi | 3 | 600m-1.5 CPU, 768Mi-1.5Gi |
| **Total** | - | - | - | **1-3.5 CPU, 1.25-3.5Gi** |

## References

- [Service README](../../services/experimentation/README.md) - Detailed API documentation
- [Statistical Analysis](../../services/experimentation/app/statistical_analysis.py) - Algorithm details
- [Issue #100](https://github.com/paruff/fawkes/issues/100) - Implementation issue
- [ADR-033: Experimentation Framework](../../docs/adr/ADR-033%20experimentation-framework.md) - Architecture decision

## Support

- **Team**: #fawkes-platform (Mattermost)
- **Documentation**: https://docs.fawkes.idp/experimentation
- **Issues**: https://github.com/paruff/fawkes/issues
