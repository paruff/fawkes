# Smart Alerting System

Intelligent alerting system that reduces noise and groups related alerts for the Fawkes platform.

## Overview

The Smart Alerting System provides:

- **Alert Correlation**: Groups related alerts by time, service, and symptom
- **Alert Suppression**: Reduces noise through intelligent suppression rules
- **Priority Scoring**: Calculates alert priority based on severity × impact × frequency
- **Intelligent Routing**: Routes alerts to appropriate teams and channels
- **Context Enrichment**: Adds recent changes, logs, and similar incidents

## Features

- Alert ingestion from Prometheus, Grafana, and DataHub
- Duplicate alert detection and suppression
- Maintenance window awareness
- Flapping alert detection (>3x in 10 minutes)
- Cascade suppression based on root cause
- Time-based suppression for non-critical alerts
- Integration with Mattermost and Slack
- On-call rotation awareness
- Service owner lookup from Backstage

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Alert Sources                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                   │
│  │Prometheus│  │ Grafana  │  │ DataHub  │                   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                   │
└───────┼─────────────┼─────────────┼──────────────────────────┘
        │             │             │
        └─────────────┴─────────────┘
                      │
                      ▼
┌──────────────────────────────────────────────────────────────┐
│              Smart Alerting Service                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │            Alert Ingestion                              │  │
│  └─────────────────┬──────────────────────────────────────┘  │
│                    │                                          │
│  ┌─────────────────▼──────────────────────────────────────┐  │
│  │         Alert Correlation Engine                        │  │
│  │  • Group by time, service, symptom                     │  │
│  │  • Deduplicate alerts                                  │  │
│  │  • Calculate priority score                            │  │
│  └─────────────────┬──────────────────────────────────────┘  │
│                    │                                          │
│  ┌─────────────────▼──────────────────────────────────────┐  │
│  │         Suppression Rules Engine                        │  │
│  │  • Maintenance windows                                 │  │
│  │  • Known issues                                        │  │
│  │  • Flapping alerts                                     │  │
│  │  • Cascade suppression                                 │  │
│  │  • Time-based suppression                              │  │
│  └─────────────────┬──────────────────────────────────────┘  │
│                    │                                          │
│  ┌─────────────────▼──────────────────────────────────────┐  │
│  │          Intelligent Routing                            │  │
│  │  • Service owner lookup                                │  │
│  │  • On-call rotation                                    │  │
│  │  • Escalation logic                                    │  │
│  │  • Context enrichment                                  │  │
│  └─────────────────┬──────────────────────────────────────┘  │
│                    │                                          │
│  ┌─────────────────▼──────────────────────────────────────┐  │
│  │             Redis State Store                           │  │
│  └────────────────────────────────────────────────────────┘  │
└────────────────────────┬─────────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
   ┌──────────┐    ┌──────────┐   ┌──────────┐
   │Mattermost│    │  Slack   │   │PagerDuty │
   └──────────┘    └──────────┘   └──────────┘
```

## API Endpoints

### Health and Status

- `GET /health` - Health check
- `GET /ready` - Readiness check
- `GET /metrics` - Prometheus metrics

### Alert Ingestion

- `POST /api/v1/alerts/prometheus` - Ingest Prometheus alerts
- `POST /api/v1/alerts/grafana` - Ingest Grafana alerts
- `POST /api/v1/alerts/datahub` - Ingest DataHub alerts
- `POST /api/v1/alerts/generic` - Ingest generic alerts

### Alert Management

- `GET /api/v1/alert-groups` - List grouped alerts
- `GET /api/v1/alert-groups/{id}` - Get specific alert group
- `GET /api/v1/alerts/{id}` - Get specific alert
- `PUT /api/v1/alerts/{id}/acknowledge` - Acknowledge alert
- `PUT /api/v1/alerts/{id}/resolve` - Resolve alert

### Suppression Rules

- `GET /api/v1/rules` - List suppression rules
- `POST /api/v1/rules` - Create suppression rule
- `GET /api/v1/rules/{id}` - Get suppression rule
- `PUT /api/v1/rules/{id}` - Update suppression rule
- `DELETE /api/v1/rules/{id}` - Delete suppression rule

### Statistics

- `GET /api/v1/stats` - Get alerting statistics
- `GET /api/v1/stats/reduction` - Get alert reduction metrics

## Configuration

Environment variables:

| Variable                  | Default                                                        | Description                                  |
| ------------------------- | -------------------------------------------------------------- | -------------------------------------------- |
| `REDIS_HOST`              | `redis`                                                        | Redis host                                   |
| `REDIS_PORT`              | `6379`                                                         | Redis port                                   |
| `REDIS_DB`                | `0`                                                            | Redis database number                        |
| `PROMETHEUS_URL`          | `http://prometheus-kube-prometheus-prometheus.fawkes.svc:9090` | Prometheus URL                               |
| `GRAFANA_URL`             | `http://grafana.fawkes.svc:80`                                 | Grafana URL                                  |
| `BACKSTAGE_URL`           | `http://backstage.fawkes.svc:7007`                             | Backstage API URL                            |
| `MATTERMOST_WEBHOOK_URL`  | -                                                              | Mattermost webhook URL                       |
| `SLACK_WEBHOOK_URL`       | -                                                              | Slack webhook URL                            |
| `PAGERDUTY_API_KEY`       | -                                                              | PagerDuty API key                            |
| `CORRELATION_TIME_WINDOW` | `300`                                                          | Time window for correlation (seconds)        |
| `FLAPPING_THRESHOLD`      | `3`                                                            | Number of alerts to consider flapping        |
| `FLAPPING_WINDOW`         | `600`                                                          | Time window for flapping detection (seconds) |
| `ESCALATION_TIMEOUT`      | `900`                                                          | Time before escalation (seconds, 15 min)     |
| `ALERT_FATIGUE_TARGET`    | `0.5`                                                          | Target alert reduction (50%)                 |

## Deployment

### Local Development

```bash
# Install dependencies
pip install -r requirements-dev.txt

# Start Redis
docker run -d -p 6379:6379 redis:7-alpine

# Run service
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

### Docker

```bash
# Build image
docker build -t smart-alerting:latest .

# Run with docker-compose
docker-compose up
```

### Kubernetes

```bash
# Apply manifests
kubectl apply -f k8s/

# Check status
kubectl get pods -n fawkes -l app=smart-alerting

# View logs
kubectl logs -n fawkes -l app=smart-alerting -f
```

### ArgoCD

```bash
# Deploy via ArgoCD
kubectl apply -f ../platform/apps/smart-alerting-application.yaml

# Check sync status
argocd app get smart-alerting
```

## Usage Examples

### Ingest Alert from Prometheus

```bash
curl -X POST http://smart-alerting.local/api/v1/alerts/prometheus \
  -H "Content-Type: application/json" \
  -d '{
    "alerts": [{
      "labels": {
        "alertname": "HighErrorRate",
        "service": "api-gateway",
        "severity": "critical"
      },
      "annotations": {
        "summary": "High error rate detected",
        "description": "Error rate is above 5%"
      },
      "startsAt": "2025-12-22T14:00:00Z",
      "status": "firing"
    }]
  }'
```

### Get Alert Groups

```bash
curl http://smart-alerting.local/api/v1/alert-groups
```

### Get Statistics

```bash
curl http://smart-alerting.local/api/v1/stats
```

### Create Suppression Rule

```bash
curl -X POST http://smart-alerting.local/api/v1/rules \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Maintenance Window - Weekly Deploy",
    "type": "maintenance_window",
    "enabled": true,
    "schedule": "0 2 * * 0",
    "duration": 7200,
    "services": ["api-gateway", "auth-service"]
  }'
```

## Testing

### Unit Tests

```bash
pytest tests/unit -v
```

### Integration Tests

```bash
pytest tests/integration -v
```

### Trigger Test Alerts

```bash
./tests/alerting/trigger-test-alerts.sh
```

## Metrics

The service exposes Prometheus metrics:

- `smart_alerting_received_total{source}` - Total alerts received
- `smart_alerting_suppressed_total{reason}` - Total alerts suppressed
- `smart_alerting_grouped_total` - Total alert groups created
- `smart_alerting_routed_total{channel}` - Total alerts routed
- `smart_alerting_fatigue_reduction` - Alert fatigue reduction percentage
- `smart_alerting_false_alert_rate` - False alert rate
- `smart_alerting_processing_duration_seconds` - Processing duration

## Suppression Rules

Rules are defined in YAML format in the `rules/` directory.

### Example: Maintenance Window

```yaml
name: "Weekly Maintenance Window"
type: maintenance_window
enabled: true
schedule: "0 2 * * 0" # Every Sunday at 2 AM
duration: 7200 # 2 hours
services:
  - api-gateway
  - database
  - cache
suppress_severity:
  - medium
  - low
```

### Example: Known Issue

```yaml
name: "Known Database Connection Issue"
type: known_issue
enabled: true
alert_pattern: "DatabaseConnectionTimeout"
services:
  - api-gateway
ticket_url: "https://jira.example.com/ISSUE-123"
expires_at: "2025-12-31T23:59:59Z"
```

### Example: Flapping Detection

```yaml
name: "Flapping Network Alerts"
type: flapping
enabled: true
threshold: 3
window: 600 # 10 minutes
alert_pattern: "NetworkLatency*"
action: suppress
```

### Example: Cascade Suppression

```yaml
name: "Database Down Cascade"
type: cascade
enabled: true
root_cause_alert: "DatabaseDown"
dependent_alerts:
  - "HighLatency"
  - "ConnectionTimeout"
  - "ServiceUnavailable"
suppress_duration: 1800 # 30 minutes
```

## Alert Reduction Targets

- **Alert Fatigue Reduction**: >50% reduction in total alerts
- **False Alert Rate**: <10% of alerts are false positives
- **Grouped Alerts**: >60% of related alerts are grouped
- **Response Time**: Alerts processed in <5 seconds

## Troubleshooting

### Service not starting

Check logs:

```bash
kubectl logs -n fawkes -l app=smart-alerting
```

Common issues:

- Redis connection failed: Check REDIS_HOST and REDIS_PORT
- Failed to load rules: Check rules syntax in `rules/` directory

### Alerts not being grouped

- Check correlation time window: Adjust CORRELATION_TIME_WINDOW
- Verify alert labels: Ensure alerts have proper service/symptom labels
- Check grouping logic: Review correlation engine configuration

### Too many/few alerts suppressed

- Review suppression rules: Check if rules are too broad/narrow
- Adjust thresholds: Tune FLAPPING_THRESHOLD and windows
- Monitor suppression metrics: Check `smart_alerting_suppressed_total`

## License

See LICENSE file in repository root.
