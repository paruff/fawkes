# Feedback Service Deployment

This directory contains Kubernetes manifests for deploying the Feedback Service to the Fawkes platform.

## Overview

The Feedback Service provides in-platform feedback collection for Backstage users. It includes:

- FastAPI-based REST API for feedback submission and management
- PostgreSQL database (via CloudNativePG) for storage
- Admin endpoints for feedback management
- Prometheus metrics for observability
- Integration with Backstage via proxy endpoint

## Components

### Application

- **Deployment**: `deployment.yaml` - Runs 2 replicas of the feedback service
- **Service**: `service.yaml` - ClusterIP service exposing port 8000
- **ServiceAccount**: `serviceaccount.yaml` - Service account for the pods
- **ConfigMap**: `configmap.yaml` - Non-sensitive configuration
- **Secrets**: `secrets.yaml` - Sensitive configuration (admin token, DB credentials)

### Database

- **CloudNativePG Cluster**: `database.yaml` - 2-instance PostgreSQL cluster
  - Database: `feedback_db`
  - User: `feedback`
  - Automatic backups to S3

### Networking

- **Ingress**: `ingress.yaml` - Exposes service at `feedback.127.0.0.1.nip.io`
- **ServiceMonitor**: `servicemonitor.yaml` - Prometheus scraping configuration

### GitOps

- **ArgoCD Application**: `../feedback-service-application.yaml` - ArgoCD app definition

## Deployment

### Prerequisites

1. Kubernetes cluster with ArgoCD installed
2. CloudNativePG operator installed
3. Ingress controller (nginx) installed
4. Prometheus operator (for metrics)

### Deploy via ArgoCD

```bash
# Apply the ArgoCD application
kubectl apply -f platform/apps/feedback-service-application.yaml

# Check sync status
argocd app get feedback-service

# Sync manually if needed
argocd app sync feedback-service
```

### Deploy via kubectl (for testing)

```bash
# Apply all manifests
kubectl apply -k platform/apps/feedback-service/

# Check deployment status
kubectl get pods -n fawkes -l app=feedback-service

# Check database status
kubectl get cluster -n fawkes db-feedback-dev

# Check ingress
kubectl get ingress -n fawkes feedback-service
```

## Configuration

### Secrets

Update the following secrets before production deployment:

1. **feedback-admin-token**: Admin API token
   ```bash
   kubectl create secret generic feedback-admin-token \
     --from-literal=token=<your-secure-token> \
     -n fawkes
   ```

2. **db-feedback-credentials**: Database credentials
   ```bash
   kubectl create secret generic db-feedback-credentials \
     --from-literal=username=feedback \
     --from-literal=password=<your-secure-password> \
     -n fawkes
   ```

### Environment Variables

The service is configured via environment variables:

- `DATABASE_URL`: PostgreSQL connection string (auto-constructed from secret)
- `ADMIN_TOKEN`: Admin authentication token (from secret)

## API Endpoints

### Public Endpoints

- `POST /api/v1/feedback` - Submit feedback
  ```json
  {
    "rating": 5,
    "category": "UI/UX",
    "comment": "Great interface!",
    "email": "user@example.com",
    "page_url": "https://backstage.example.com"
  }
  ```

### Admin Endpoints (require Authorization header)

- `GET /api/v1/feedback?page=1&page_size=20` - List feedback
- `PUT /api/v1/feedback/{id}/status` - Update feedback status
- `GET /api/v1/feedback/stats` - Get aggregated statistics

### Monitoring

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Testing

### Manual Testing

```bash
# Submit feedback
curl -X POST http://feedback.127.0.0.1.nip.io/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "UI/UX",
    "comment": "Test feedback",
    "email": "test@example.com"
  }'

# List feedback (requires admin token)
kubectl get secret feedback-admin-token -n fawkes -o jsonpath='{.data.token}' | base64 -d
curl http://feedback.127.0.0.1.nip.io/api/v1/feedback \
  -H "Authorization: Bearer <token-from-above>"

# Check health
curl http://feedback.127.0.0.1.nip.io/health

# Check metrics
curl http://feedback.127.0.0.1.nip.io/metrics
```

### BDD Tests

```bash
# Run feedback service tests
behave tests/bdd/features/feedback-widget.feature --tags=@feedback

# Run all tests
make test-bdd COMPONENT=feedback
```

## Monitoring

### Metrics

The service exposes Prometheus metrics at `/metrics`:

- `feedback_submissions_total` - Counter of feedback submissions by category and rating
- `feedback_request_duration_seconds` - Histogram of request durations by endpoint

### Logs

```bash
# View service logs
kubectl logs -n fawkes -l app=feedback-service -f

# View database logs
kubectl logs -n fawkes -l cnpg.io/cluster=db-feedback-dev -f
```

### Dashboards

A Grafana dashboard can be created to visualize:
- Feedback submission rate
- Average ratings over time
- Category distribution
- Response times
- Database health

## Troubleshooting

### Service not starting

```bash
# Check pod status
kubectl get pods -n fawkes -l app=feedback-service

# Check pod logs
kubectl logs -n fawkes -l app=feedback-service --tail=100

# Check events
kubectl get events -n fawkes --sort-by='.lastTimestamp' | grep feedback
```

### Database connection issues

```bash
# Check database cluster status
kubectl get cluster -n fawkes db-feedback-dev -o yaml

# Check database pods
kubectl get pods -n fawkes -l cnpg.io/cluster=db-feedback-dev

# Test database connection from service pod
kubectl exec -it -n fawkes <feedback-pod> -- \
  python -c "import asyncpg; import asyncio; asyncio.run(asyncpg.connect('postgresql://...'))"
```

### Ingress not accessible

```bash
# Check ingress status
kubectl get ingress -n fawkes feedback-service

# Check ingress controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller

# Test service internally
kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
  curl http://feedback-service.fawkes.svc:8000/health
```

## Security Considerations

1. **Secrets Management**: Use External Secrets Operator or Sealed Secrets in production
2. **Network Policies**: Implement network policies to restrict traffic
3. **Authentication**: Admin endpoints require Bearer token authentication
4. **RBAC**: Service account has minimal permissions
5. **Container Security**: Runs as non-root user, read-only root filesystem where possible
6. **TLS**: Enable TLS termination at ingress in production

## Integration with Backstage

The feedback service is integrated with Backstage via a proxy endpoint:

```yaml
# In backstage app-config.yaml
proxy:
  endpoints:
    '/feedback/api':
      target: http://feedback-service.fawkes.svc:8000/
      changeOrigin: true
      secure: false
```

Backstage plugins can then call `/api/proxy/feedback/api/v1/feedback` to submit feedback.

## Resource Usage

The deployment is configured to stay within 70% resource utilization targets:

- **Feedback Service**: 100m CPU / 128Mi memory (requests), 500m CPU / 512Mi memory (limits)
- **Database**: 100m CPU / 256Mi memory (requests), 500m CPU / 512Mi memory (limits)
- **Total**: ~200m CPU / ~384Mi memory (requests)

## Backup and Recovery

The CloudNativePG cluster is configured with automatic backups:

- Retention: 7 days
- Destination: S3 bucket `fawkes-backups/feedback-db`
- Schedule: Daily

To restore from backup:

```bash
# List backups
kubectl cnpg backup list db-feedback-dev -n fawkes

# Create restore cluster
kubectl apply -f restore-cluster.yaml
```

## Maintenance

### Scaling

```bash
# Scale service replicas
kubectl scale deployment feedback-service -n fawkes --replicas=3

# Scale database instances
kubectl patch cluster db-feedback-dev -n fawkes \
  --type merge -p '{"spec":{"instances":3}}'
```

### Updates

Updates are handled automatically by ArgoCD when changes are pushed to Git:

1. Update manifests in `platform/apps/feedback-service/`
2. Commit and push to Git
3. ArgoCD will detect changes and sync automatically
4. Monitor rollout: `kubectl rollout status deployment/feedback-service -n fawkes`

### Database Migrations

Database schema is automatically created on service startup. For schema changes:

1. Update schema in `services/feedback/app/main.py` (init_database function)
2. Consider using a proper migration tool (e.g., Alembic) for complex migrations
3. Test in development before deploying to production
