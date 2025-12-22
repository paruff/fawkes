# Feedback Service

FastAPI-based feedback collection and management service for Backstage.

## Features

- Submit feedback with ratings (1-5), categories, and comments
- Optional email for follow-up
- Admin endpoints to view and manage feedback
- Aggregated statistics
- PostgreSQL storage
- Prometheus metrics
- Health checks

## API Endpoints

### Public Endpoints

- `POST /api/v1/feedback` - Submit feedback
- `GET /health` - Health check

### Admin Endpoints (require Bearer token)

- `GET /api/v1/feedback` - List all feedback (paginated)
- `PUT /api/v1/feedback/{id}/status` - Update feedback status
- `GET /api/v1/feedback/stats` - Get aggregated statistics

### Metrics

- `GET /metrics` - Prometheus metrics

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
    "comment": "Great user interface!",
    "email": "user@example.com",
    "page_url": "https://backstage.example.com/catalog"
  }'
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
