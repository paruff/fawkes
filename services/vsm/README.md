# VSM Service

Value Stream Mapping service for tracking work items through stages from idea to production.

## Features

- **Work Item Tracking**: Track work items (features, bugs, tasks, epics) through value stream stages
- **8-Stage Value Stream**: Backlog → Design → Development → Code Review → Testing → Deployment Approval → Deploy → Production
- **Stage Metadata**: Each stage includes type (wait/active/done), WIP limits, and descriptions
- **Stage Transitions**: Record work item movement between stages with validation rules
- **Flow Metrics**: Calculate throughput, WIP, and cycle time with percentiles (P50, P85, P95)
- **Prometheus Metrics**: Export metrics for monitoring and dashboards
- **RESTful API**: OpenAPI documented endpoints
- **PostgreSQL Storage**: Persistent storage with CloudNativePG
- **Configuration Management**: YAML-based stage and transition configuration

## Value Stream Stages

The VSM service uses an 8-stage value stream:

| Stage | Type | WIP Limit | Description |
|-------|------|-----------|-------------|
| Backlog | wait | - | Work items waiting to be analyzed |
| Design | active | 5 | Active design and analysis phase |
| Development | active | 10 | Active implementation phase |
| Code Review | wait | 8 | Waiting for peer review |
| Testing | active | 8 | Active testing and QA phase |
| Deployment Approval | wait | 5 | Waiting for deployment approval |
| Deploy | active | 3 | Active deployment to production |
| Production | done | - | Successfully deployed and running |

See [config/stages.yaml](config/stages.yaml) for detailed stage definitions and [docs/vsm/value-stream-mapping.md](../../docs/vsm/value-stream-mapping.md) for complete VSM documentation.

## API Endpoints

### Work Items
- `POST /api/v1/work-items` - Create a new work item
- `PUT /api/v1/work-items/{id}/transition` - Move work item between stages
- `GET /api/v1/work-items/{id}/history` - Get stage history for work item

### Metrics
- `GET /api/v1/metrics` - Get flow metrics (throughput, WIP, cycle time)
- `GET /api/v1/stages` - List all available stages

### Health
- `GET /api/v1/health` - Health check
- `GET /ready` - Readiness check
- `GET /metrics` - Prometheus metrics

## Development

### Local Setup

1. Install dependencies:
```bash
pip install -r requirements.txt -r requirements-dev.txt
```

2. Set environment variables:
```bash
export DATABASE_HOST=localhost
export DATABASE_PORT=5432
export DATABASE_NAME=vsm_db
export DATABASE_USER=vsm_user
export DATABASE_PASSWORD=changeme
```

3. Run database migrations:
```bash
alembic upgrade head
```

4. Load stage configurations:
```bash
python scripts/load-stages.py --config config/stages.yaml
```

5. Start the service:
```bash
uvicorn app.main:app --reload
```

6. Access the API:
- API docs: http://localhost:8000/docs
- Health check: http://localhost:8000/api/v1/health

### Testing

Run unit tests:
```bash
pytest tests/unit -v
```

## Database Schema

### Tables

1. **work_items** - Work items being tracked
   - id, title, type, created_at, updated_at

2. **stages** - Value stream stages
   - id, name, order, type, created_at

3. **stage_transitions** - Work item transitions between stages
   - id, work_item_id, from_stage_id, to_stage_id, timestamp

4. **flow_metrics** - Aggregated flow metrics
   - id, date, period_type, throughput, wip, cycle_time_avg, cycle_time_p50, cycle_time_p85, cycle_time_p95

## Deployment

The service is deployed to Kubernetes using ArgoCD. See `platform/apps/vsm-service/` for manifests.

## Environment Variables

- `DATABASE_HOST` - PostgreSQL host (default: db-vsm-dev-rw.fawkes.svc)
- `DATABASE_PORT` - PostgreSQL port (default: 5432)
- `DATABASE_NAME` - Database name (default: vsm_db)
- `DATABASE_USER` - Database user (default: vsm_user)
- `DATABASE_PASSWORD` - Database password (required)
- `SQL_ECHO` - Enable SQL logging (default: false)
