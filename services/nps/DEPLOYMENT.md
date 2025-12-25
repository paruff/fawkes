# NPS Survey Service - Deployment Guide

## Prerequisites

- Kubernetes cluster (1.28+)
- CloudNativePG operator installed
- Prometheus operator installed (for ServiceMonitor)
- Mattermost bot account created

## Step 1: Create Mattermost Bot

1. Go to Mattermost System Console > Integrations > Bot Accounts
2. Create new bot:
   - Username: `nps-survey-bot`
   - Display Name: `NPS Survey Bot`
   - Description: `Automated NPS survey distribution`
   - Role: `Member`
   - Enable OAuth 2.0: No
3. Copy the bot token
4. Get the bot user ID via API:
   ```bash
   curl -H "Authorization: Bearer YOUR_BOT_TOKEN" \
        https://mattermost.local/api/v4/users/me | jq -r .id
   ```

## Step 2: Configure Secrets

Edit `k8s/configmap.yaml`:

```yaml
data:
  mattermost_url: "http://mattermost.fawkes.svc.cluster.local:8065"
  base_survey_url: "https://nps.fawkes.idp/survey"
  # Add your allowed origins for CORS (comma-separated)
  allowed_origins: "https://nps.fawkes.idp,https://backstage.fawkes.idp"
```

Edit `k8s/secret.yaml` and update:

```yaml
stringData:
  # Database URL (will be auto-created by CloudNativePG)
  database_url: "postgresql://nps:YOUR_DB_PASSWORD@db-nps-dev-rw.fawkes.svc.cluster.local:5432/nps_db"

  # Mattermost bot token from Step 1
  mattermost_token: "YOUR_MATTERMOST_BOT_TOKEN"

  # Mattermost bot user ID from Step 1
  mattermost_bot_user_id: "YOUR_BOT_USER_ID"
```

Edit `k8s/postgresql-credentials.yaml`:

```yaml
stringData:
  username: nps
  password: YOUR_STRONG_DB_PASSWORD  # Generate a strong password
```

## Step 3: Deploy PostgreSQL Database

```bash
# Deploy CloudNativePG cluster
kubectl apply -f k8s/postgresql-credentials.yaml
kubectl apply -f k8s/postgresql-cluster.yaml

# Wait for database to be ready
kubectl wait --for=condition=Ready cluster/db-nps-dev -n fawkes --timeout=5m

# Verify database is running
kubectl get cluster -n fawkes
kubectl get pods -n fawkes -l cnpg.io/cluster=db-nps-dev
```

## Step 4: Deploy NPS Service

```bash
# Apply all Kubernetes manifests
kubectl apply -f k8s/serviceaccount.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/servicemonitor.yaml

# Wait for deployment to be ready
kubectl wait --for=condition=Available deployment/nps-service -n fawkes --timeout=3m

# Verify pods are running
kubectl get pods -n fawkes -l app=nps-service
```

## Step 5: Verify Deployment

```bash
# Check pod logs
kubectl logs -n fawkes -l app=nps-service --tail=50

# Check health endpoint
kubectl port-forward -n fawkes svc/nps-service 8000:8000 &
curl http://localhost:8000/health

# Expected response:
# {
#   "status": "healthy",
#   "service": "nps-survey-service",
#   "version": "1.0.0",
#   "database_connected": true
# }
```

## Step 6: Deploy CronJobs

```bash
# Deploy quarterly survey CronJob
kubectl apply -f k8s/cronjob-quarterly.yaml

# Deploy weekly reminder CronJob
kubectl apply -f k8s/cronjob-reminders.yaml

# Verify CronJobs are created
kubectl get cronjobs -n fawkes -l app=nps-service
```

## Step 7: Test Survey Distribution

### Manual Test

```bash
# Create a test job from the CronJob
kubectl create job --from=cronjob/nps-survey-quarterly nps-test-1 -n fawkes

# Watch the job
kubectl get jobs -n fawkes -l app=nps-service -w

# Check job logs
kubectl logs -n fawkes job/nps-test-1
```

### Test with Test Users

```bash
# Port forward to service
kubectl port-forward -n fawkes svc/nps-service 8000:8000 &

# Run test script (requires Python and dependencies)
cd services/nps
pip install -r requirements.txt
python scripts/send-survey.py --test-users
```

## Step 8: Create Ingress (Optional)

If you want to expose the survey service externally:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nps-service
  namespace: fawkes
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - nps.fawkes.idp
    secretName: nps-service-tls
  rules:
  - host: nps.fawkes.idp
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: nps-service
            port:
              number: 8000
```

Apply the ingress:

```bash
kubectl apply -f ingress.yaml
```

## Monitoring

### Prometheus Metrics

The service exposes metrics at `/metrics`:

```bash
# Port forward
kubectl port-forward -n fawkes svc/nps-service 8000:8000

# View metrics
curl http://localhost:8000/metrics
```

Key metrics:
- `nps_responses_total{score_type}` - Total responses by type
- `nps_score{period}` - Current NPS score
- `nps_survey_request_duration_seconds{endpoint}` - Request duration

### Grafana Dashboard

Import the NPS dashboard (create if needed):

1. Go to Grafana
2. Create new dashboard
3. Add panels for:
   - Current NPS Score (gauge)
   - Response Rate (gauge)
   - Responses by Type (pie chart)
   - Response Trend (time series)
   - Survey Distribution Status

## Troubleshooting

### Database Connection Issues

```bash
# Check database status
kubectl get cluster -n fawkes db-nps-dev

# Check database logs
kubectl logs -n fawkes db-nps-dev-1

# Test connection from pod
kubectl exec -it -n fawkes deployment/nps-service -- \
  python -c "import asyncpg; print('DB connection test')"
```

### Mattermost Integration Issues

```bash
# Test Mattermost connectivity
kubectl exec -it -n fawkes deployment/nps-service -- \
  curl http://mattermost.fawkes.svc.cluster.local:8065/api/v4/system/ping

# Check if bot token is valid
kubectl exec -it -n fawkes deployment/nps-service -- \
  curl -H "Authorization: Bearer $MATTERMOST_TOKEN" \
       http://mattermost.fawkes.svc.cluster.local:8065/api/v4/users/me
```

### CronJob Not Running

```bash
# Check CronJob schedule
kubectl get cronjob -n fawkes nps-survey-quarterly -o yaml

# Manually trigger job
kubectl create job --from=cronjob/nps-survey-quarterly manual-test -n fawkes

# Check job status
kubectl describe job -n fawkes manual-test

# View job logs
kubectl logs -n fawkes job/manual-test
```

## Maintenance

### Database Backup

CloudNativePG handles automatic backups. To manually trigger:

```bash
# Trigger on-demand backup
kubectl cnpg backup db-nps-dev -n fawkes
```

### Update Service

```bash
# Build new image
docker build -t nps-service:v1.1.0 .

# Update deployment
kubectl set image deployment/nps-service -n fawkes \
  nps-service=nps-service:v1.1.0

# Monitor rollout
kubectl rollout status deployment/nps-service -n fawkes
```

### Scale Service

```bash
# Scale to 3 replicas
kubectl scale deployment/nps-service -n fawkes --replicas=3

# Verify scaling
kubectl get pods -n fawkes -l app=nps-service
```

## Security Best Practices

1. **Use External Secrets Operator** in production:
   ```bash
   # Replace k8s/secret.yaml with ExternalSecret
   kubectl apply -f external-secret.yaml
   ```

2. **Rotate credentials regularly**:
   - Database password every 90 days
   - Mattermost bot token every 180 days

3. **Enable network policies**:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: nps-service
     namespace: fawkes
   spec:
     podSelector:
       matchLabels:
         app: nps-service
     policyTypes:
     - Ingress
     - Egress
     ingress:
     - from:
       - namespaceSelector:
           matchLabels:
             name: fawkes
       ports:
       - protocol: TCP
         port: 8000
     egress:
     - to:
       - namespaceSelector:
           matchLabels:
             name: fawkes
       ports:
       - protocol: TCP
         port: 5432  # PostgreSQL
       - protocol: TCP
         port: 8065  # Mattermost
   ```

4. **Enable audit logging** for survey responses

## Support

For issues or questions:
- Check logs: `kubectl logs -n fawkes -l app=nps-service`
- Open issue in Fawkes repository
- Contact platform team
