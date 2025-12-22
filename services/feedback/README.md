# Feedback Service

FastAPI-based feedback collection and management service for Backstage with NPS analytics and AI-powered sentiment analysis.

## Features

- Submit feedback with ratings (1-5), categories, and comments
- **AI-powered sentiment analysis** using VADER for all feedback comments
- **NPS (Net Promoter Score) calculation** with promoters/passives/detractors tracking
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

