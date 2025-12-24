# Feedback Service

FastAPI-based feedback collection and management service for Backstage with NPS analytics and AI-powered sentiment analysis.

## Features

- Submit feedback with ratings (1-5), categories, and comments
- **AI-powered sentiment analysis** using VADER for all feedback comments
- **NPS (Net Promoter Score) calculation** with promoters/passives/detractors tracking
- **Time-to-action tracking** measuring response time from submission to first action
- Optional email for follow-up
- Admin endpoints to view and manage feedback
- Aggregated statistics
- PostgreSQL storage with sentiment fields
- **Comprehensive Prometheus metrics** for analytics
- Health checks
- **Grafana dashboard** for feedback analytics and insights

## API Endpoints

### Public Endpoints

- `POST /api/v1/feedback` - Submit feedback (automatically analyzes sentiment)
- `GET /health` - Health check

### Admin Endpoints (require Bearer token)

- `GET /api/v1/feedback` - List all feedback (paginated, includes sentiment)
- `PUT /api/v1/feedback/{id}/status` - Update feedback status
- `GET /api/v1/feedback/stats` - Get aggregated statistics
- `POST /api/v1/metrics/refresh` - Manually refresh Prometheus metrics

### Metrics

- `GET /metrics` - Prometheus metrics endpoint

## Prometheus Metrics

The service exports the following metrics for monitoring and analytics:

### NPS Metrics
- `nps_score{period}` - NPS score (-100 to +100) for overall, last_30d, last_90d
- `nps_promoters_percentage{period}` - Percentage of promoters (5-star ratings)
- `nps_passives_percentage{period}` - Percentage of passives (4-star ratings)
- `nps_detractors_percentage{period}` - Percentage of detractors (1-3 star ratings)

### Feedback Metrics
- `feedback_submissions_total{category,rating}` - Total submissions by category and rating
- `feedback_by_category_total{category}` - Total feedback count by category
- `feedback_response_rate{status}` - Response rate by status (overall, open, resolved, etc.)

### Time-to-Action Metrics
- `feedback_time_to_action_seconds{category}` - Histogram of time from submission to first action (status change from 'open')
  - Buckets: 1min, 5min, 15min, 30min, 1h, 2h, 4h, 8h, 24h, 48h, 7d
- `feedback_avg_time_to_action_hours{status,category}` - Average time to action in hours by status and category

### Sentiment Metrics
- `feedback_sentiment_score{category,sentiment}` - Average sentiment scores by category
  - Sentiment: positive (≥0.05), neutral (-0.05 to 0.05), negative (≤-0.05)
  - Score: -1.0 (most negative) to +1.0 (most positive)

### Request Metrics
- `feedback_request_duration_seconds{endpoint}` - Request processing time histogram

## Sentiment Analysis

The service uses VADER (Valence Aware Dictionary and sEntiment Reasoner) to automatically analyze the sentiment of all feedback comments:

- **Positive**: Compound score ≥ 0.05 (😊)
- **Neutral**: Compound score between -0.05 and 0.05 (😐)
- **Negative**: Compound score ≤ -0.05 (😞)

Sentiment data is stored with each feedback submission and available in:
- API responses
- Database queries
- Prometheus metrics
- Grafana dashboard visualizations

## NPS Calculation

NPS is calculated from 1-5 star ratings:
- **Promoters**: 5 stars (would recommend)
- **Passives**: 4 stars (satisfied but not enthusiastic)
- **Detractors**: 1-3 stars (unhappy customers)

**Formula**: NPS = (% Promoters - % Detractors) × 100

**Score Interpretation**:
- Above 0: Good
- Above 50: Excellent
- Above 70: World-class

## Grafana Dashboard

A comprehensive analytics dashboard is available at `/grafana/d/feedback-analytics`:

**Key Panels**:
- Current NPS score with color-coded thresholds
- NPS trend over time (90-day view)
- NPS components distribution (promoters/passives/detractors)
- Feedback volume by category
- Rating distribution (1-5 stars)
- Sentiment analysis visualizations
- Response rate tracking
- Top issues and low-rated feedback highlights
- **Time-to-action metrics** showing average response times by status and category
- Time-to-action distribution histogram

**Dashboard Features**:
- Auto-refresh every 5 minutes for real-time updates
- 7-day default time range
- Color-coded thresholds for quick insights
- 30 panels providing comprehensive feedback analytics

## Environment Variables

- `DATABASE_URL` - PostgreSQL connection URL (default: `postgresql://feedback:feedback@db-feedback-dev-rw.fawkes.svc.cluster.local:5432/feedback_db`)
- `ADMIN_TOKEN` - Admin authentication token (default: `admin-secret-token`)

## Development

### Install dependencies

```bash
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

### Run tests

```bash
pytest tests/unit -v
```

### Run locally

```bash
# Set environment variables
export DATABASE_URL="postgresql://user:pass@localhost:5432/feedback_db"
export ADMIN_TOKEN="your-secret-token"

# Run the service
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Build Docker image

```bash
docker build -t feedback-service:latest .
```

## Database Schema

The service automatically creates the following schema on startup:

```sql
CREATE TABLE feedback (
    id SERIAL PRIMARY KEY,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    category VARCHAR(100) NOT NULL,
    comment TEXT NOT NULL,
    email VARCHAR(255),
    page_url TEXT,
    status VARCHAR(50) DEFAULT 'open',
    sentiment VARCHAR(20),
    sentiment_compound FLOAT,
    sentiment_pos FLOAT,
    sentiment_neu FLOAT,
    sentiment_neg FLOAT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Usage Examples

### Submit feedback

```bash
curl -X POST http://localhost:8000/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "UI",
    "comment": "Great user interface! Love the new design.",
    "email": "user@example.com",
    "page_url": "https://backstage.example.com/catalog"
  }'
```

Response includes sentiment analysis:
```json
{
  "id": 1,
  "rating": 5,
  "category": "UI",
  "comment": "Great user interface! Love the new design.",
  "sentiment": "positive",
  "sentiment_compound": 0.836,
  "status": "open",
  "created_at": "2025-12-22T20:00:00Z"
}
```

### List feedback (admin)

```bash
curl http://localhost:8000/api/v1/feedback \
  -H "Authorization: Bearer your-admin-token"
```

### Update feedback status (admin)

```bash
curl -X PUT http://localhost:8000/api/v1/feedback/1/status \
  -H "Authorization: Bearer your-admin-token" \
  -H "Content-Type: application/json" \
  -d '{"status": "resolved"}'
```

### Get statistics (admin)

```bash
curl http://localhost:8000/api/v1/feedback/stats \
  -H "Authorization: Bearer your-admin-token"
```

### Refresh metrics (admin)

```bash
curl -X POST http://localhost:8000/api/v1/metrics/refresh \
  -H "Authorization: Bearer your-admin-token"
```

### View Prometheus metrics

```bash
curl http://localhost:8000/metrics | grep nps_score
```

## Acceptance Testing

Run AT-E2-010 validation to verify all components:

```bash
make validate-at-e2-010
```

This validates:
- ✓ Feedback analytics dashboard created
- ✓ NPS trends visible
- ✓ Feedback categorization shown
- ✓ Sentiment analysis working
- ✓ Top issues highlighted
- ✓ Metrics exported to Prometheus


## AI Triage and Automation

### Overview

The feedback service includes an AI-powered triage system that automatically analyzes, prioritizes, and routes feedback to appropriate GitHub issues.

### AI Triage Features

#### Priority Scoring
- **P0 (Critical)**: Security issues, data loss, outages, severe bugs
- **P1 (High)**: Major bugs, blocking issues, important features
- **P2 (Medium)**: Enhancements, non-blocking issues
- **P3 (Low)**: Minor improvements, nice-to-have features

Priority is calculated based on:
- Feedback type (bug_report, feature_request, feedback)
- User rating (1-5)
- Sentiment analysis (negative sentiment increases priority)
- Keyword detection (critical, urgent, blocker, etc.)
- Category (Security, Performance categories get higher priority)

#### Auto-Labeling
Automatically suggests GitHub labels based on:
- Feedback type (bug, enhancement)
- Priority level (P0-P3)
- Category (category:ui-ux, category:performance, etc.)
- Content keywords (security, performance, documentation, accessibility)

#### Duplicate Detection
- Searches existing open GitHub issues
- Uses text similarity matching (fuzzy matching)
- Configurable similarity threshold (default: 70%)
- Prevents creation of duplicate issues

### API Endpoints

#### Triage Specific Feedback
```bash
POST /api/v1/feedback/{id}/triage
Authorization: Bearer {admin-token}

Response:
{
  "status": "success",
  "triage": {
    "feedback_id": 123,
    "priority": "P1",
    "priority_score": 0.65,
    "suggested_labels": ["bug", "P1", "category:performance"],
    "potential_duplicates": [],
    "suggested_milestone": "Next Sprint",
    "should_create_issue": true,
    "triage_reason": "Priority P1 based on score 0.65"
  }
}
```

#### Automated Processing
```bash
POST /api/v1/automation/process-validated?limit=20&min_rating=3
Authorization: Bearer {admin-token}

Response:
{
  "status": "success",
  "message": "Processed 5 feedback items",
  "processed": 5,
  "issues_created": 4,
  "skipped_duplicates": 1,
  "errors": null
}
```

### Automation Pipeline

#### CronJob Configuration
A Kubernetes CronJob runs every 15 minutes to:
1. Fetch validated feedback (status='open', no GitHub issue)
2. Run AI triage on each item
3. Skip duplicates with notifications
4. Create GitHub issues for non-duplicate, validated feedback
5. Send notifications for each action
6. Provide summary report

#### Manual Trigger
```bash
kubectl create job --from=cronjob/feedback-automation feedback-automation-manual -n fawkes
```

#### Environment Variables
```yaml
GITHUB_TOKEN: GitHub personal access token (required for automation)
GITHUB_OWNER: Repository owner (default: paruff)
GITHUB_REPO: Repository name (default: fawkes)
MATTERMOST_WEBHOOK_URL: Webhook URL for notifications (optional)
NOTIFICATION_ENABLED: Enable/disable notifications (default: true)
```

### Notification System

#### Supported Channels
- **Mattermost**: Via incoming webhooks
- **Future**: Slack, email, custom webhooks

#### Notification Types
1. **Issue Created**: Sent when new issue is created from feedback
2. **Duplicate Detected**: Sent when duplicate issues are found
3. **High Priority**: Immediate alert for P0/P1 feedback
4. **Automation Summary**: Report after scheduled processing

#### Configuration
```yaml
# In deployment.yaml
- name: MATTERMOST_WEBHOOK_URL
  valueFrom:
    secretKeyRef:
      name: feedback-mattermost-webhook
      key: url
- name: NOTIFICATION_ENABLED
  value: "true"
```

### Testing

#### Unit Tests
```bash
cd services/feedback
pytest tests/unit/test_ai_triage.py -v
```

#### BDD Tests
```bash
behave tests/bdd/features/feedback-automation.feature
```

### Monitoring

#### Key Metrics to Watch
- `feedback_submissions_total`: Track incoming feedback volume
- `nps_score`: Monitor user satisfaction trends
- `feedback_sentiment_score`: Identify negative sentiment patterns

#### Recommended Alerts
- P0 feedback submitted (immediate action)
- NPS score drops below threshold
- High volume of negative sentiment feedback
- Automation pipeline failures

### Architecture

```
┌─────────────────────────────────────────────────────┐
│            Feedback Submission                       │
│    (User/Bot/CLI → Feedback Service)                │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│          Sentiment Analysis (VADER)                  │
│       Store in PostgreSQL with metadata              │
└─────────────────┬───────────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────────┐
│              AI Triage (Manual/Auto)                 │
│  - Calculate Priority (P0-P3)                       │
│  - Suggest Labels                                    │
│  - Detect Duplicates                                │
│  - Determine Milestone                               │
└─────────────────┬───────────────────────────────────┘
                  │
         ┌────────┴─────────┐
         │                  │
         ▼                  ▼
┌─────────────┐    ┌─────────────────┐
│  Duplicate? │    │ Create GitHub   │
│  → Skip     │    │ Issue           │
│  → Notify   │    │ → Auto-label    │
└─────────────┘    │ → Link to FB    │
                   │ → Notify        │
                   └─────────────────┘
```

### Best Practices

1. **Configure GitHub Token**: Required for automation and duplicate detection
2. **Set Up Notifications**: Configure Mattermost webhooks for team awareness
3. **Monitor Automation**: Check CronJob logs regularly
4. **Tune Thresholds**: Adjust priority scoring based on your team's needs
5. **Review Duplicates**: Verify duplicate detection accuracy periodically
6. **Regular Cleanup**: Archive or close resolved feedback items

### Troubleshooting

#### Automation Not Running
```bash
# Check CronJob status
kubectl get cronjob feedback-automation -n fawkes

# View job history
kubectl get jobs -n fawkes -l app=feedback-automation

# Check logs
kubectl logs -n fawkes -l app=feedback-automation --tail=100
```

#### GitHub Integration Issues
```bash
# Verify token is set
kubectl get secret feedback-github-token -n fawkes -o yaml

# Test GitHub API access
curl -H "Authorization: Bearer ${GITHUB_TOKEN}" https://api.github.com/user
```

#### No Notifications Sent
```bash
# Check if notifications are enabled
curl http://feedback-service:8000/ | jq '.features.notifications'

# Verify webhook URL
kubectl get secret feedback-mattermost-webhook -n fawkes -o yaml

# Test webhook manually
curl -X POST ${MATTERMOST_WEBHOOK_URL} -d '{"text":"Test message"}'
```

### Security Considerations

- **GitHub Token**: Store in Kubernetes secret, limit to repository scope
- **Admin Token**: Rotate regularly, use strong random values
- **Webhook URLs**: Keep confidential, use HTTPS only
- **Rate Limiting**: Consider implementing for public endpoints
- **Input Validation**: All feedback content is validated and sanitized

### Future Enhancements

- [ ] ML-based priority prediction using historical data
- [ ] Advanced duplicate detection with embeddings
- [ ] Auto-assignment to team members based on category
- [ ] SLA tracking and escalation
- [ ] Feedback clustering and trend analysis
- [ ] Multi-language sentiment analysis
- [ ] Integration with more notification channels (Slack, email)
- [ ] Custom workflow automation rules
