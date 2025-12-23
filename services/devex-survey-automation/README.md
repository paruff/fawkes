# DevEx Survey Automation Service

Automated DevEx survey system for periodic pulse surveys (weekly) and deep-dive surveys (quarterly) with multi-channel distribution and analysis automation.

## Overview

This service provides:

- **Weekly Pulse Surveys**: Automated weekly developer experience check-ins
- **Quarterly Deep-Dive Integration**: Coordinates with NPS service for comprehensive surveys
- **Multi-Channel Distribution**: Send surveys via Mattermost, Slack, or Email
- **Automated Scheduling**: CronJobs for survey distribution and reminders
- **Response Tracking**: Track participation and send timely reminders
- **Analysis Automation**: Aggregate responses and generate insights
- **Integration**: Works with space-metrics and NPS services

## Architecture

### Components

- **FastAPI Backend**: RESTful API for survey orchestration
- **PostgreSQL Database**: Store survey campaigns, recipients, and responses
- **Mattermost Integration**: Send DMs to developers
- **Slack Integration**: Alternative messaging channel
- **Email Integration**: Fallback distribution method
- **CronJobs**: Automated scheduling
- **Space-Metrics Integration**: Submit pulse survey data

### Survey Types

#### 1. Weekly Pulse Survey (5 questions, ~2 minutes)

Measures developer experience weekly:
- Flow state days (0-7)
- Valuable work percentage (0-100%)
- Cognitive load (1-5)
- Friction incidents (boolean)
- Optional comment

**Schedule**: Every Monday at 9:00 AM
**Distribution**: Mattermost DM with inline survey link
**Reminder**: Wednesday if no response

#### 2. Quarterly Deep-Dive Survey

Comprehensive NPS and SPACE framework survey:
- NPS score (0-10)
- Platform satisfaction (1-5)
- Feature-specific ratings
- Open-ended feedback
- Burnout assessment

**Schedule**: First Monday of Q1, Q2, Q3, Q4
**Distribution**: Mattermost DM + Email
**Reminder**: After 1 week

## Database Schema

### survey_campaigns
- `id`: Primary key
- `type`: pulse or deep_dive
- `period`: week number or quarter
- `year`: Campaign year
- `started_at`: Campaign start timestamp
- `total_sent`: Count of surveys sent
- `total_responses`: Count of responses received
- `response_rate`: Calculated response rate

### survey_recipients
- `id`: Primary key
- `campaign_id`: Foreign key to campaign
- `user_id`: Developer identifier
- `email`: User email
- `mattermost_id`: Mattermost user ID
- `slack_id`: Slack user ID (optional)
- `token`: Unique survey token
- `sent_at`: Distribution timestamp
- `responded_at`: Response timestamp
- `reminder_sent`: Boolean flag
- `response_data`: JSONB with survey responses

### pulse_survey_aggregates
- `id`: Primary key
- `week`: Week number
- `year`: Year
- `avg_flow_state_days`: Average flow state
- `avg_valuable_work_pct`: Average valuable work %
- `avg_cognitive_load`: Average cognitive load
- `friction_incidents_pct`: % reporting friction
- `response_count`: Number of responses

## API Endpoints

### Survey Distribution

- `POST /api/v1/survey/distribute` - Manually trigger survey distribution
- `GET /api/v1/survey/campaign/{id}` - Get campaign details
- `GET /api/v1/survey/campaigns` - List campaigns

### Survey Response

- `GET /survey/{token}` - Survey page (HTML)
- `POST /api/v1/survey/{token}/submit` - Submit response
- `GET /survey/{token}/thanks` - Thank you page

### Analytics

- `GET /api/v1/analytics/pulse/weekly` - Weekly pulse trends
- `GET /api/v1/analytics/pulse/summary` - Pulse summary stats
- `GET /api/v1/analytics/response-rate` - Response rate tracking

### Health & Metrics

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Usage

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/devex_surveys

# Integrations
SPACE_METRICS_URL=http://space-metrics.fawkes.svc:8000
NPS_SERVICE_URL=http://nps-service.fawkes.svc:8000

# Mattermost
MATTERMOST_URL=http://mattermost.fawkes.svc:8065
MATTERMOST_TOKEN=bot-token
MATTERMOST_BOT_USER_ID=bot-user-id

# Slack (optional)
SLACK_BOT_TOKEN=xoxb-...
SLACK_SIGNING_SECRET=...

# Email (optional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=surveys@fawkes.idp
SMTP_PASSWORD=...
FROM_EMAIL=Fawkes DevEx <surveys@fawkes.idp>

# Survey Settings
SURVEY_BASE_URL=https://surveys.fawkes.idp
PULSE_SURVEY_DAY=monday  # Day of week for pulse surveys
PULSE_SURVEY_HOUR=9      # Hour to send (24h format)
REMINDER_DAYS=2          # Days after initial send
```

### Manual Survey Distribution

```bash
# Distribute weekly pulse survey
curl -X POST http://localhost:8000/api/v1/survey/distribute \
  -H "Content-Type: application/json" \
  -d '{"type": "pulse", "test_mode": true}'

# Check campaign status
curl http://localhost:8000/api/v1/survey/campaigns
```

### Development

```bash
# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run locally
uvicorn app.main:app --reload --port 8000

# Run tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=html
```

## Deployment

### Docker

```bash
# Build image
docker build -t devex-survey-automation:latest .

# Run container
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql://... \
  -e MATTERMOST_TOKEN=... \
  devex-survey-automation:latest
```

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Check deployment
kubectl get pods -n fawkes -l app=devex-survey-automation

# View logs
kubectl logs -n fawkes -l app=devex-survey-automation -f
```

## CronJob Schedules

### Weekly Pulse Survey
```yaml
schedule: "0 9 * * 1"  # Every Monday at 9:00 AM
```

### Pulse Survey Reminders
```yaml
schedule: "0 9 * * 3"  # Every Wednesday at 9:00 AM
```

### Quarterly Deep-Dive
```yaml
schedule: "0 9 1 1,4,7,10 *"  # First day of Q1,Q2,Q3,Q4 at 9:00 AM
```

### Weekly Analysis
```yaml
schedule: "0 0 * * 0"  # Every Sunday at midnight (analyze previous week)
```

## Monitoring

### Prometheus Metrics

- `devex_survey_distributed_total{type}` - Surveys distributed
- `devex_survey_responses_total{type}` - Survey responses
- `devex_survey_response_rate{type}` - Response rate by survey type
- `devex_survey_request_duration_seconds{endpoint}` - Request duration

### Health Check

```bash
curl http://localhost:8000/health
```

## Privacy & Ethics

### Privacy-First Design

1. **Anonymous Responses**: Survey responses are aggregated and never tied to individuals in reports
2. **Opt-Out Available**: Developers can opt out of automated surveys
3. **Data Retention**: Individual responses deleted after 90 days
4. **Aggregation Threshold**: Metrics only shown for teams of 5+ developers
5. **No Tracking**: No individual performance tracking or ranking

### Ethical Use Guidelines

**Never use survey data for:**
- ❌ Individual performance reviews
- ❌ Ranking or comparing developers
- ❌ Hiring/firing decisions
- ❌ Bonus or compensation decisions

**Always use survey data for:**
- ✅ Improving platform experience
- ✅ Identifying friction points
- ✅ Measuring impact of changes
- ✅ Guiding platform roadmap
- ✅ Understanding team trends

## Integration Points

### With Space-Metrics Service

Pulse survey responses are automatically forwarded to space-metrics:

```python
# After pulse survey submission
response = await submit_to_space_metrics({
    "valuable_work_percentage": data.valuable_work_pct,
    "flow_state_days": data.flow_state_days,
    "cognitive_load": data.cognitive_load,
    "friction_experienced": data.friction_incidents
})
```

### With NPS Service

Quarterly deep-dive surveys are coordinated with NPS service:
- Share recipient lists
- Combine survey distribution
- Unified analytics dashboard

### With Backstage

Add to Backstage `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/devex-surveys/api':
      target: http://devex-survey-automation.fawkes.svc:8000/
      changeOrigin: true
```

Create Backstage plugin to display survey results.

## Response Rate Targets

**Goals**:
- Weekly Pulse: >60% response rate
- Quarterly Deep-Dive: >40% response rate

**Strategies**:
- Keep surveys short (2-5 minutes)
- Send at optimal times (Monday morning)
- Personalized messages
- Show impact of previous feedback
- Timely reminders
- Make it easy (inline links, mobile-friendly)

## Troubleshooting

### Low Response Rates

1. Check survey timing (avoid busy periods)
2. Review message content (too long? unclear?)
3. Verify distribution channels working
4. Survey fatigue? (too frequent)
5. Show impact of previous surveys

### Service Not Starting

```bash
# Check pod logs
kubectl logs -n fawkes -l app=devex-survey-automation

# Check database connection
kubectl exec -it -n fawkes <pod> -- python -c "import asyncpg; print('ok')"
```

### Surveys Not Being Sent

1. Check CronJob schedule: `kubectl get cronjobs -n fawkes`
2. Check CronJob logs: `kubectl logs -n fawkes job/<job-name>`
3. Verify Mattermost integration working
4. Check recipient list not empty

## Future Enhancements

- [ ] Slack full integration
- [ ] Email distribution (SMTP)
- [ ] Microsoft Teams integration
- [ ] Multi-language support
- [ ] Custom survey questions per team
- [ ] A/B testing for survey formats
- [ ] Machine learning for optimal send times
- [ ] Sentiment analysis on comments
- [ ] Integration with Backstage plugin
- [ ] Mobile app for survey completion

## License

MIT

## Support

For issues or questions, please open an issue in the Fawkes repository.
