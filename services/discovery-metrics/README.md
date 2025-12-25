# Discovery Metrics Service

Track discovery activities including interviews, insights captured, experiments run, and features validated.

## Overview

The Discovery Metrics Service provides comprehensive tracking and analytics for continuous discovery activities as outlined in the IP3dP (Internal Platform Product Discovery and Delivery Process) framework.

## Features

- **Interview Tracking**: Record and monitor user interviews
- **Insight Management**: Capture and validate discovery insights
- **Experiment Tracking**: Track experiments from planning to completion
- **Feature Validation**: Monitor feature validation and adoption
- **Team Performance**: Measure team discovery metrics
- **ROI Calculations**: Track return on investment for experiments
- **Prometheus Metrics**: Export metrics for Grafana dashboards

## API Endpoints

### Interviews

- `POST /api/v1/interviews` - Create interview
- `GET /api/v1/interviews` - List interviews
- `GET /api/v1/interviews/{id}` - Get interview details
- `PUT /api/v1/interviews/{id}` - Update interview

### Discovery Insights

- `POST /api/v1/insights` - Create insight
- `GET /api/v1/insights` - List insights
- `GET /api/v1/insights/{id}` - Get insight details
- `PUT /api/v1/insights/{id}` - Update insight

### Experiments

- `POST /api/v1/experiments` - Create experiment
- `GET /api/v1/experiments` - List experiments
- `GET /api/v1/experiments/{id}` - Get experiment details
- `PUT /api/v1/experiments/{id}` - Update experiment

### Feature Validations

- `POST /api/v1/features` - Create feature validation
- `GET /api/v1/features` - List features
- `GET /api/v1/features/{id}` - Get feature details
- `PUT /api/v1/features/{id}` - Update feature

### Team Performance

- `POST /api/v1/team-performance` - Create team performance record
- `GET /api/v1/team-performance` - List team performance

### Statistics

- `GET /api/v1/statistics` - Get discovery statistics

### System

- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Metrics Exposed

- `discovery_interviews_total` - Total interviews conducted
- `discovery_interviews_completed` - Completed interviews
- `discovery_insights_total` - Total insights captured
- `discovery_insights_validated` - Validated insights
- `discovery_experiments_total` - Total experiments
- `discovery_experiments_completed` - Completed experiments
- `discovery_features_total` - Total features tracked
- `discovery_features_validated` - Validated features
- `discovery_features_shipped` - Shipped features
- `discovery_avg_time_to_validation_days` - Average time to validate insights
- `discovery_avg_time_to_ship_days` - Average time to ship features
- `discovery_validation_rate` - Percentage of insights validated
- `discovery_feature_adoption_rate` - Average feature adoption rate
- `discovery_interviews_last_7d` - Interviews in last 7 days
- `discovery_interviews_last_30d` - Interviews in last 30 days

## Local Development

### Prerequisites

- Python 3.11+
- PostgreSQL 15+

### Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt

# Set environment variables
export DATABASE_URL="postgresql://discovery:discovery@localhost:5432/discovery_metrics"

# Run database migrations (if using Alembic)
# alembic upgrade head

# Run the service
uvicorn app.main:app --reload --port 8000
```

### Access API Documentation

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Docker

```bash
# Build image
docker build -t discovery-metrics:latest .

# Run container
docker run -d \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://user:pass@host:5432/db" \
  discovery-metrics:latest
```

## Database Schema

### Interviews Table

- Interview details (participant, interviewer, dates, status)
- Tracks insights generated per interview

### Discovery Insights Table

- Insight information (title, description, category, priority)
- Source tracking (interview, survey, analytics, support)
- Validation tracking and time-to-validation

### Experiments Table

- Experiment details (name, hypothesis, status)
- Duration and ROI tracking
- Success validation

### Feature Validations Table

- Feature tracking (name, description, status)
- Validation and ship dates
- Adoption rate and user satisfaction

### Team Performance Table

- Team-level metrics aggregation
- Discovery velocity calculation

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://discovery:discovery@localhost:5432/discovery_metrics` |

## Testing

```bash
# Run tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html
```

## Deployment

See `platform/apps/discovery-metrics/` for Kubernetes deployment manifests.

## Related Documentation

- [Continuous Discovery Workflow Playbook](../../docs/playbooks/continuous-discovery-workflow.md)
- [Product Discovery and Delivery Flow (IP3dP)](../../docs/explanation/idp/product-discovery-delivery-flow.md)
- [Discovery Metrics Dashboard](../../platform/apps/grafana/dashboards/discovery-metrics-dashboard.json)

## License

See [LICENSE](../../LICENSE) file in the root directory.
