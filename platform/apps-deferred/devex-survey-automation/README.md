# DevEx Survey Automation - Kubernetes Deployment

This directory contains Kubernetes manifests for deploying the DevEx Survey Automation Service.

## Components

### Core Service

- **deployment.yaml**: Main application deployment (2 replicas)
- **service.yaml**: ClusterIP service exposing port 8000
- **serviceaccount.yaml**: Service account for the pods
- **database.yaml**: CloudNativePG database cluster (3 instances)
- **secrets.yaml**: Database and Mattermost credentials
- **servicemonitor.yaml**: Prometheus metrics scraping

### Automated Scheduling (CronJobs)

- **cronjob-pulse-weekly.yaml**: Weekly pulse survey distribution (Monday 9 AM)
- **cronjob-pulse-reminders.yaml**: Pulse survey reminders (Wednesday 9 AM)
- **cronjob-quarterly.yaml**: Quarterly deep-dive surveys (Q1-Q4 start, 9 AM)

## Deployment

### Option 1: Using kubectl

```bash
# Apply all manifests
kubectl apply -k platform/apps/devex-survey-automation/

# Check deployment status
kubectl get pods -n fawkes -l app=devex-survey-automation

# View logs
kubectl logs -n fawkes -l app=devex-survey-automation -f

# Check CronJobs
kubectl get cronjobs -n fawkes
```

### Option 2: Using ArgoCD

```bash
# Apply ArgoCD application
kubectl apply -f platform/apps/devex-survey-automation-application.yaml

# Check sync status
argocd app get devex-survey-automation

# Manual sync if needed
argocd app sync devex-survey-automation
```

## Configuration

### Required Secrets

Before deployment, update secrets in `secrets.yaml`:

1. **Database Credentials**

   ```yaml
   name: db-devex-credentials
   username: devex
   password: <strong-password> # Change this!
   ```

2. **Mattermost Bot Token** (optional but recommended)
   ```yaml
   name: devex-survey-mattermost
   bot-token: <mattermost-bot-token>
   bot-user-id: <mattermost-bot-user-id>
   ```

### Environment Variables

Edit `deployment.yaml` to configure:

- `SPACE_METRICS_URL`: Space metrics service URL
- `NPS_SERVICE_URL`: NPS service URL
- `SURVEY_BASE_URL`: Public survey URL
- `PULSE_SURVEY_DAY`: Day of week for pulse surveys
- `PULSE_SURVEY_HOUR`: Hour to send surveys (24h format)
- `REMINDER_DAYS`: Days after initial send to remind

### CronJob Schedules

Edit CronJob files to adjust schedules:

- **Pulse Weekly**: `"0 9 * * 1"` (Monday 9 AM)
- **Reminders**: `"0 9 * * 3"` (Wednesday 9 AM)
- **Quarterly**: `"0 9 1 1,4,7,10 *"` (Q1-Q4 start, 9 AM)

Don't forget to set the `timeZone` field to your timezone.

## Monitoring

### Prometheus Metrics

The service exposes metrics at `/metrics`:

- `devex_survey_distributed_total{type}` - Surveys distributed by type
- `devex_survey_responses_total{type}` - Responses received by type
- `devex_survey_response_rate{type}` - Response rate by type
- `devex_survey_request_duration_seconds{endpoint}` - Request duration

### Health Check

```bash
# Check service health
kubectl port-forward -n fawkes svc/devex-survey-automation 8000:8000
curl http://localhost:8000/health
```

### View Metrics

```bash
# Port forward to access metrics
kubectl port-forward -n fawkes svc/devex-survey-automation 8000:8000
curl http://localhost:8000/metrics
```

## Database

The service uses CloudNativePG for PostgreSQL:

```bash
# Check database cluster
kubectl get cluster -n fawkes db-devex-dev

# Check database pods
kubectl get pods -n fawkes -l cnpg.io/cluster=db-devex-dev

# Connect to database
kubectl exec -it -n fawkes db-devex-dev-1 -- psql -U devex -d devex_surveys
```

### Database Schema

Tables created automatically on first startup:

- `survey_campaigns` - Campaign tracking
- `survey_recipients` - Individual recipients and responses
- `pulse_survey_aggregates` - Weekly aggregated metrics
- `survey_opt_outs` - Users who opted out

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n fawkes -l app=devex-survey-automation

# Describe pod for events
kubectl describe pod -n fawkes -l app=devex-survey-automation

# Check logs
kubectl logs -n fawkes -l app=devex-survey-automation --tail=100
```

### Database Connection Issues

```bash
# Check database is running
kubectl get cluster -n fawkes db-devex-dev

# Check database credentials secret
kubectl get secret -n fawkes db-devex-credentials -o yaml

# Test database connectivity
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql postgresql://devex:password@db-devex-dev-rw.fawkes.svc:5432/devex_surveys
```

### CronJobs Not Running

```bash
# List CronJobs
kubectl get cronjobs -n fawkes

# Check CronJob schedule
kubectl describe cronjob -n fawkes devex-pulse-survey-weekly

# View recent jobs
kubectl get jobs -n fawkes -l app=devex-survey-automation

# Check job logs
kubectl logs -n fawkes job/<job-name>
```

### Mattermost Integration Issues

```bash
# Check Mattermost secret
kubectl get secret -n fawkes devex-survey-mattermost -o yaml

# Test Mattermost connectivity from pod
kubectl exec -it -n fawkes <pod-name> -- \
  curl -H "Authorization: Bearer $MATTERMOST_TOKEN" \
  http://mattermost.fawkes.svc:8065/api/v4/system/ping
```

## Manual Testing

### Trigger Survey Distribution

```bash
# Port forward to service
kubectl port-forward -n fawkes svc/devex-survey-automation 8000:8000

# Distribute pulse survey (test mode)
curl -X POST http://localhost:8000/api/v1/survey/distribute \
  -H "Content-Type: application/json" \
  -d '{
    "type": "pulse",
    "test_mode": true,
    "test_users": ["dev1@example.com", "dev2@example.com"]
  }'

# Check campaign status
curl http://localhost:8000/api/v1/survey/campaigns
```

### Access Survey UI

```bash
# Get a survey token from database or logs
TOKEN=<survey-token>

# Access survey page
curl http://localhost:8000/survey/$TOKEN
```

## Resource Usage

### Current Limits

- **CPU Request**: 100m
- **CPU Limit**: 500m
- **Memory Request**: 256Mi
- **Memory Limit**: 512Mi
- **Database Storage**: 5Gi
- **Replicas**: 2

Adjust in `deployment.yaml` if needed.

## Security Considerations

1. **Secrets Management**: Use External Secrets Operator or Sealed Secrets in production
2. **Network Policies**: Restrict traffic to/from survey service
3. **RBAC**: Service account has minimal permissions
4. **Container Security**: Runs as non-root user (UID 1000)
5. **Database**: Encrypted connections, strong passwords

## Integration with Other Services

### Backstage

Add to Backstage `app-config.yaml`:

```yaml
proxy:
  endpoints:
    "/devex-surveys":
      target: http://devex-survey-automation.fawkes.svc:8000
      changeOrigin: true
```

### Grafana

Import metrics to Grafana dashboard for DevEx monitoring.

## Support

For issues:

1. Check logs: `kubectl logs -n fawkes -l app=devex-survey-automation`
2. Check health: `curl http://<service>/health`
3. Review events: `kubectl get events -n fawkes --sort-by='.lastTimestamp'`
4. Open issue in GitHub repository
