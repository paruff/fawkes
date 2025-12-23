# SPACE Metrics Service Deployment

This directory contains Kubernetes manifests for deploying the SPACE Metrics Service to the Fawkes platform.

## Overview

The SPACE Metrics Service collects and exposes Developer Experience metrics across five dimensions:
- **S**atisfaction
- **P**erformance  
- **A**ctivity
- **C**ommunication
- **E**fficiency

## Components

- **Deployment**: `deployment.yaml` - Runs 2 replicas of the service
- **Service**: `service.yaml` - ClusterIP service exposing port 8000
- **ServiceAccount**: `serviceaccount.yaml` - Service account for the pods
- **ConfigMap**: `configmap.yaml` - Non-sensitive configuration
- **Secrets**: `secrets.yaml` - Database credentials
- **ServiceMonitor**: `servicemonitor.yaml` - Prometheus scraping configuration
- **Ingress**: `ingress.yaml` - Exposes service at `space-metrics.127.0.0.1.nip.io`

## Prerequisites

1. Kubernetes cluster with kubectl configured
2. PostgreSQL database for storing metrics
3. Prometheus operator (for ServiceMonitor)
4. Ingress controller (nginx)

## Deployment

### Quick Deploy

```bash
# Apply all manifests via Kustomize
kubectl apply -k platform/apps/space-metrics/

# Check deployment status
kubectl get pods -n fawkes-local -l app=space-metrics

# Check service
kubectl get svc -n fawkes-local space-metrics

# Check ingress
kubectl get ingress -n fawkes-local space-metrics
```

### Manual Deploy

```bash
# Create namespace
kubectl create namespace fawkes-local

# Apply each manifest
kubectl apply -f platform/apps/space-metrics/serviceaccount.yaml
kubectl apply -f platform/apps/space-metrics/configmap.yaml
kubectl apply -f platform/apps/space-metrics/secrets.yaml
kubectl apply -f platform/apps/space-metrics/deployment.yaml
kubectl apply -f platform/apps/space-metrics/service.yaml
kubectl apply -f platform/apps/space-metrics/servicemonitor.yaml
kubectl apply -f platform/apps/space-metrics/ingress.yaml
```

## Configuration

### Database Setup

The service requires a PostgreSQL database. Update the secret with your database credentials:

```bash
kubectl create secret generic space-metrics-db-credentials \
  --from-literal=connection-string="postgresql+asyncpg://user:pass@host:5432/space_metrics" \
  --from-literal=username="space" \
  --from-literal=password="your-secure-password" \
  -n fawkes-local
```

### Environment Variables

Configure via ConfigMap:
- `aggregation-threshold`: Minimum team size for metrics (default: 5)
- `collection-interval`: Metrics collection interval in seconds (default: 3600)
- `retention-days`: Data retention period (default: 90)

## Testing

### Health Check

```bash
# Port forward to service
kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000

# Check health
curl http://localhost:8000/health
```

### API Testing

```bash
# Get all SPACE metrics
curl http://localhost:8000/api/v1/metrics/space

# Get satisfaction metrics
curl http://localhost:8000/api/v1/metrics/space/satisfaction

# Get DevEx health score
curl http://localhost:8000/api/v1/metrics/space/health

# Log friction incident
curl -X POST http://localhost:8000/api/v1/friction/log \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Slow builds",
    "description": "CI builds taking >30 minutes",
    "severity": "high"
  }'
```

### Prometheus Metrics

```bash
# Check Prometheus metrics endpoint
curl http://localhost:8000/metrics
```

## Monitoring

### Verify ServiceMonitor

```bash
# Check ServiceMonitor is created
kubectl get servicemonitor -n monitoring space-metrics

# Verify Prometheus is scraping
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# Navigate to http://localhost:9090/targets
# Look for "space-metrics" target
```

### View Logs

```bash
# View service logs
kubectl logs -n fawkes-local -l app=space-metrics -f

# View specific pod logs
kubectl logs -n fawkes-local <pod-name> -f
```

## Integration

### With Backstage

Add proxy endpoint in Backstage `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/space-metrics/api':
      target: http://space-metrics.fawkes-local.svc:8000/
      changeOrigin: true
```

### With Grafana

1. Ensure Prometheus is scraping the ServiceMonitor
2. Import DevEx Dashboard (see `platform/apps/grafana/dashboards/devex-dashboard.json`)
3. Dashboard will auto-populate with SPACE metrics

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -n fawkes-local -l app=space-metrics

# Describe pod
kubectl describe pod -n fawkes-local <pod-name>

# Check logs
kubectl logs -n fawkes-local <pod-name>
```

### Database Connection Issues

```bash
# Test database connectivity
kubectl exec -it -n fawkes-local <pod-name> -- \
  python -c "import asyncpg; import asyncio; asyncio.run(asyncpg.connect('postgresql://...'))"

# Check secret
kubectl get secret -n fawkes-local space-metrics-db-credentials -o yaml
```

### Metrics Not Appearing

1. Verify ServiceMonitor exists: `kubectl get servicemonitor -n monitoring`
2. Check Prometheus targets: Port forward to Prometheus and check `/targets`
3. Test metrics endpoint: `curl http://<service-ip>:8000/metrics`
4. Check service logs for errors

## Resource Usage

The deployment targets <70% resource utilization:
- **CPU**: 100m request, 500m limit per replica
- **Memory**: 128Mi request, 512Mi limit per replica
- **Total (2 replicas)**: ~200m CPU, ~256Mi memory requests

## Security

- Runs as non-root user (UID 1000)
- Read-only root filesystem
- No privilege escalation
- All capabilities dropped
- Service account with minimal permissions

## Related Documentation

- [Service README](../../../services/space-metrics/README.md)
- [ADR-018: SPACE Framework](../../../docs/adr/ADR-018%20Developer%20Experience%20Measurement%20Framework%20SPACE.md)
- [Grafana Dashboards](../grafana/dashboards/README.md)
