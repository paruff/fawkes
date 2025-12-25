# DevEx Survey Automation - Deployment Quick Start

## Overview

This system automates DevEx surveys with:
- **Weekly Pulse Surveys**: Monday 9 AM (5 questions, 2 minutes)
- **Quarterly Deep-Dive**: Q1-Q4 start (comprehensive NPS + SPACE survey)
- **Automated Reminders**: Wednesday 9 AM for non-respondents

## Quick Deployment

### 1. Deploy Service

```bash
# Deploy all components
kubectl apply -k platform/apps/devex-survey-automation/

# Verify deployment
kubectl get pods -n fawkes -l app=devex-survey-automation
kubectl get cronjobs -n fawkes | grep devex
```

### 2. Configure Secrets

```bash
# Edit secrets before deployment
kubectl edit secret db-devex-credentials -n fawkes
# Set strong password

# Add Mattermost bot token (optional but recommended)
kubectl edit secret devex-survey-mattermost -n fawkes
# Add bot-token and bot-user-id
```

### 3. Deploy with ArgoCD (Recommended)

```bash
# Apply ArgoCD application
kubectl apply -f platform/apps/devex-survey-automation-application.yaml

# Check sync status
argocd app get devex-survey-automation

# Sync if needed
argocd app sync devex-survey-automation
```

## Testing

### Manual Survey Distribution

```bash
# Port forward to service
kubectl port-forward -n fawkes svc/devex-survey-automation 8000:8000

# Distribute test pulse survey
curl -X POST http://localhost:8000/api/v1/survey/distribute \
  -H "Content-Type: application/json" \
  -d '{
    "type": "pulse",
    "test_mode": true,
    "test_users": ["your.email@example.com"]
  }'
```

### Check Health

```bash
curl http://localhost:8000/health
```

### View Metrics

```bash
curl http://localhost:8000/metrics
```

### Check Campaigns

```bash
curl http://localhost:8000/api/v1/survey/campaigns
```

## CronJob Schedules

| CronJob | Schedule | Description |
|---------|----------|-------------|
| `devex-pulse-survey-weekly` | Monday 9:00 AM | Distribute weekly pulse survey |
| `devex-pulse-survey-reminders` | Wednesday 9:00 AM | Send reminders to non-respondents |
| `devex-deepdive-survey-quarterly` | Q1-Q4 start, 9:00 AM | Distribute quarterly deep-dive |

### Manually Trigger CronJob

```bash
# Create a one-time job from CronJob
kubectl create job --from=cronjob/devex-pulse-survey-weekly test-pulse-1 -n fawkes

# Check job status
kubectl get jobs -n fawkes | grep test-pulse
kubectl logs -n fawkes job/test-pulse-1
```

## Monitoring

### View Logs

```bash
# Service logs
kubectl logs -n fawkes -l app=devex-survey-automation -f

# Database logs
kubectl logs -n fawkes -l cnpg.io/cluster=db-devex-dev

# CronJob logs
kubectl logs -n fawkes job/<job-name>
```

### Prometheus Metrics

Available at `/metrics`:
- `devex_survey_distributed_total{type}` - Surveys distributed
- `devex_survey_responses_total{type}` - Responses received
- `devex_survey_response_rate{type}` - Response rate %
- `devex_survey_request_duration_seconds{endpoint}` - Request duration

### Grafana Dashboard

Import metrics to create dashboard with:
- Response rate trends
- Weekly pulse metrics (flow state, cognitive load, etc.)
- Survey distribution success rate
- Service health status

## Database Access

```bash
# Connect to database
kubectl exec -it -n fawkes db-devex-dev-1 -- \
  psql -U devex -d devex_surveys

# Check tables
\dt

# View recent campaigns
SELECT * FROM survey_campaigns ORDER BY started_at DESC LIMIT 5;

# Check response rate
SELECT
  type,
  period,
  year,
  total_sent,
  total_responses,
  response_rate
FROM survey_campaigns
ORDER BY started_at DESC;
```

## Troubleshooting

### Surveys Not Being Sent

1. Check Mattermost integration:
```bash
kubectl get secret devex-survey-mattermost -n fawkes -o yaml
```

2. Check CronJob schedules:
```bash
kubectl get cronjobs -n fawkes
kubectl describe cronjob devex-pulse-survey-weekly -n fawkes
```

3. View recent jobs:
```bash
kubectl get jobs -n fawkes -l app=devex-survey-automation
```

### Database Connection Issues

```bash
# Check database cluster
kubectl get cluster -n fawkes db-devex-dev

# Check database pods
kubectl get pods -n fawkes -l cnpg.io/cluster=db-devex-dev

# Test connectivity
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql "postgresql://devex:password@db-devex-dev-rw.fawkes.svc:5432/devex_surveys" \
  -c "SELECT 1"
```

### Service Not Starting

```bash
# Check pod status
kubectl get pods -n fawkes -l app=devex-survey-automation

# Describe pod for events
kubectl describe pod -n fawkes -l app=devex-survey-automation

# Check logs
kubectl logs -n fawkes -l app=devex-survey-automation --tail=100
```

## Integration Points

### With Backstage

Add to `app-config.yaml`:
```yaml
proxy:
  endpoints:
    '/devex-surveys':
      target: http://devex-survey-automation.fawkes.svc:8000
      changeOrigin: true
```

### With Space-Metrics Service

Pulse survey responses are automatically forwarded to:
- URL: `http://space-metrics.fawkes.svc:8000/api/v1/surveys/pulse/submit`
- No configuration needed if services are in same namespace

### With Grafana

1. Add Prometheus data source
2. Import metrics with prefix `devex_survey_*`
3. Create dashboard with panels for:
   - Response rate over time
   - Weekly pulse trends
   - Distribution success rate

## Response Rate Targets

**Goals**:
- Weekly Pulse: >60% response rate
- Quarterly Deep-Dive: >40% response rate

**Strategies to Improve**:
- Keep surveys short (2-5 minutes)
- Send at optimal times (Monday morning)
- Show impact of previous feedback
- Send timely reminders (Wednesday)
- Make surveys mobile-friendly
- Personalize messages

## Privacy & Ethics

**Remember**:
- ❌ Never use for individual performance reviews
- ❌ Never rank or compare developers
- ❌ Never use for hiring/firing decisions
- ✅ Use to improve platform experience
- ✅ Use to identify friction points
- ✅ Use to measure impact of changes
- ✅ Use to guide platform roadmap

## Support

For issues:
1. Check logs: `kubectl logs -n fawkes -l app=devex-survey-automation`
2. Check health: `curl http://<service>/health`
3. Review documentation in `services/devex-survey-automation/README.md`
4. Review deployment docs in `platform/apps/devex-survey-automation/README.md`
5. Open issue in GitHub repository

## Next Steps

After deployment:
1. Configure Mattermost bot token
2. Test with small group (`test_mode: true`)
3. Verify surveys are delivered
4. Check response submission works
5. Monitor response rates
6. Set up Grafana dashboard
7. Roll out to full organization
8. Review and iterate on survey questions
9. Act on feedback received!
