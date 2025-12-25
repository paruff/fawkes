# NPS Survey Service

Automated NPS (Net Promoter Score) survey service for Fawkes Platform with quarterly scheduling and Mattermost integration.

## Overview

This service provides:

- **Quarterly Survey Automation**: Scheduled CronJob for quarterly survey distribution
- **Unique Survey Links**: Generate unique, time-limited survey links per user
- **Multi-Channel Distribution**: Send surveys via Mattermost DM
- **Automated Reminders**: Send reminders to non-respondents after 1 week
- **NPS Calculation**: Automatic NPS score calculation (% promoters - % detractors)
- **Response Tracking**: Track survey recipients and responses
- **Analytics Dashboard**: Expose metrics via Prometheus for dashboard integration

## Architecture

### Components

- **FastAPI Backend**: RESTful API for survey management
- **PostgreSQL Database**: Store survey links, responses, and campaigns
- **Mattermost Integration**: Send survey invitations and reminders via DM
- **CronJob**: Scheduled quarterly survey distribution
- **Prometheus Metrics**: Expose NPS metrics for monitoring

### Database Schema

#### survey_links

- `id`: Primary key
- `token`: Unique survey token (64 chars)
- `user_id`: User identifier
- `email`: User email
- `expires_at`: Link expiration timestamp (30 days)
- `responded`: Boolean flag
- `reminder_sent`: Boolean flag
- `created_at`, `updated_at`: Timestamps

#### survey_responses

- `id`: Primary key
- `user_id`: User identifier
- `token`: Survey token (foreign key)
- `score`: NPS score (0-10)
- `score_type`: promoter/passive/detractor
- `comment`: Optional feedback
- `created_at`: Timestamp

#### survey_campaigns

- `id`: Primary key
- `quarter`: Quarter identifier (Q1-Q4)
- `year`: Campaign year
- `started_at`: Campaign start
- `total_sent`: Count of surveys sent
- `total_responses`: Count of responses
- `nps_score`: Calculated NPS score

## API Endpoints

### Public Endpoints

- `GET /survey/{token}` - Survey page (HTML)
- `GET /survey/{token}/thanks` - Thank you page (HTML)
- `POST /api/v1/survey/{token}/submit` - Submit survey response
- `GET /health` - Health check

### Internal Endpoints

- `POST /api/v1/survey/generate` - Generate survey link
- `GET /api/v1/nps/metrics` - Get NPS metrics
- `GET /metrics` - Prometheus metrics

## NPS Score Calculation

NPS is calculated as: **(% Promoters - % Detractors) × 100**

Score classification:

- **Promoters** (9-10): Enthusiastic users
- **Passives** (7-8): Satisfied but unenthusiastic
- **Detractors** (0-6): Unhappy users

NPS Score ranges from -100 to +100:

- **-100 to 0**: Needs improvement
- **0 to 30**: Good
- **30 to 70**: Great
- **70 to 100**: Excellent

## Usage

### Manual Survey Distribution

```bash
# Send to test users
python scripts/send-survey.py --test-users

# Send to all users
python scripts/send-survey.py --all-users

# Send reminders
python scripts/send-survey.py --send-reminders
```

### Environment Variables

```bash
# Database
DATABASE_URL=postgresql://user:pass@host:5432/nps_db

# Mattermost
MATTERMOST_URL=http://mattermost.local:8065
MATTERMOST_TOKEN=your-bot-token
MATTERMOST_BOT_USER_ID=bot-user-id

# Survey Settings
BASE_SURVEY_URL=https://nps.fawkes.idp/survey
SURVEY_EXPIRY_DAYS=30
REMINDER_DAYS=7
```

### Testing Survey Link

```bash
# Manually trigger survey
python scripts/send-survey.py --test-users

# Check survey link works
curl http://nps.local/survey/test-token
```

## Development

### Setup

```bash
# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Run locally
uvicorn app.main:app --reload --port 8000
```

### Testing

```bash
# Run unit tests
pytest tests/unit -v

# Run with coverage
pytest tests/unit --cov=app --cov-report=html
```

## Deployment

### Docker

```bash
# Build image
docker build -t nps-service:latest .

# Run container
docker run -p 8000:8000 \
  -e DATABASE_URL=postgresql://... \
  -e MATTERMOST_TOKEN=... \
  nps-service:latest
```

### Kubernetes

```bash
# Deploy to Kubernetes
kubectl apply -f k8s/

# Check deployment
kubectl get pods -n fawkes -l app=nps-service

# View logs
kubectl logs -n fawkes -l app=nps-service
```

## Monitoring

### Prometheus Metrics

- `nps_responses_total{score_type}` - Total responses by type
- `nps_score{period}` - Current NPS score
- `nps_survey_request_duration_seconds{endpoint}` - Request duration

### Health Check

```bash
curl http://nps.local/health
```

## Survey Flow

### 1. Survey Distribution

- Quarterly CronJob triggers survey distribution
- Generate unique survey link per user
- Send DM via Mattermost with survey link
- Track distribution in database

### 2. User Response

- User clicks survey link
- Validates link (not expired, not already responded)
- Displays survey form (0-10 score + optional comment)
- Submits response

### 3. Response Processing

- Store response in database
- Calculate score type (promoter/passive/detractor)
- Update metrics
- Mark link as responded

### 4. Reminders

- Weekly CronJob checks for non-respondents
- Send reminder after 7 days
- Track reminder status
- Don't spam users who already responded

### 5. NPS Calculation

- Calculate NPS score periodically
- Expose via API and Prometheus
- Display in dashboard

## Response Rate Target

**Goal**: >30% response rate

Strategies to achieve:

- Clear, concise survey (2 minutes)
- Personalized DM messages
- Timely reminders (7 days)
- Anonymous responses
- Show impact of previous feedback

## Security Considerations

- Survey links expire after 30 days
- Unique tokens prevent unauthorized access
- No PII exposed in survey URLs
- Rate limiting on submission endpoints
- Database connection pooling
- Non-root container execution

## Future Enhancements

- [ ] Email integration (in addition to Mattermost)
- [ ] Multi-language support
- [ ] Custom survey questions
- [ ] Trend analysis dashboard
- [ ] Export to CSV/PDF
- [ ] Integration with Backstage plugin
- [ ] Slack integration
- [ ] Advanced analytics (sentiment analysis)

## License

MIT

## Support

For issues or questions, please open an issue in the Fawkes repository.
