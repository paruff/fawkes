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

## Prometheus Metrics

The VSM service exposes the following Prometheus metrics at the `/metrics` endpoint:

### Flow Metrics
- `vsm_work_in_progress{stage}` (Gauge) - Current work in progress by stage
- `vsm_throughput_per_day{date}` (Counter) - Number of items completed per day
- `vsm_cycle_time_hours` (Histogram) - Overall cycle time in hours from start to production
- `vsm_stage_cycle_time_seconds{stage}` (Histogram) - Time spent in each stage in seconds
- `vsm_lead_time_seconds` (Histogram) - Lead time from backlog to production in seconds

### Activity Metrics
- `vsm_requests_total{method, endpoint, status}` (Counter) - Total API requests
- `vsm_work_items_created_total{type}` (Counter) - Work items created by type
- `vsm_stage_transitions_total{from_stage, to_stage}` (Counter) - Stage transitions

### Grafana Dashboard

A comprehensive flow metrics dashboard is available at:
- `platform/apps/grafana/dashboards/vsm-flow-metrics.json`

The dashboard includes:
- **Cumulative Flow Diagram**: WIP by stage over time
- **Throughput Charts**: Daily and weekly completion trends
- **Cycle Time Analysis**: Per-stage cycle times and distributions
- **Lead Time Trends**: P50, P75, P95 percentiles
- **Bottleneck Detection**: Identify stages with high WIP or slow transitions

## Deployment

The service is deployed to Kubernetes using ArgoCD. See `platform/apps/vsm-service/` for manifests.

## Focalboard Integration

The VSM service provides bidirectional integration with Focalboard for work tracking and flow metrics visualization.

### Webhook Integration

The VSM service can receive webhooks from Focalboard to automatically sync work items:

**Webhook Endpoint**: `POST /api/v1/focalboard/webhook`

Supported webhook actions:
- `card.created` - Creates a new VSM work item when a Focalboard card is created
- `card.moved` - Updates work item stage when a card is moved between columns
- `card.updated` - Updates work item metadata
- `card.deleted` - Logs deletion (preserves VSM history)

**Column to Stage Mapping**:
- Focalboard columns are automatically mapped to VSM stages
- See `GET /api/v1/focalboard/stages/mapping` for current mappings
- Default mappings:
  - "Backlog" / "To Do" → Backlog
  - "In Progress" / "Development" → Development
  - "In Review" / "Code Review" → Code Review
  - "Testing" → Testing
  - "Done" / "Production" → Production

### Manual Sync

Sync an entire Focalboard board to VSM:

```bash
curl -X POST http://vsm-service.fawkes.svc:8000/api/v1/focalboard/sync \
  -H "Content-Type: application/json" \
  -d '{"board_id": "your-board-id"}'
```

### VSM Metrics Widget

A custom Focalboard widget displays real-time flow metrics directly in your boards.

**Features**:
- Throughput, WIP, and cycle time display
- Per-stage WIP counts
- Bottleneck detection and warnings
- WIP limit tracking
- Link to full Grafana dashboard

**Installation**: See `focalboard-widget/README.md` for installation and configuration instructions.

### API Endpoints

**Focalboard Integration Endpoints**:
- `POST /api/v1/focalboard/webhook` - Receive Focalboard webhooks
- `POST /api/v1/focalboard/sync` - Manually sync a board
- `GET /api/v1/focalboard/work-items/{id}/sync-to-focalboard` - Push work item to Focalboard
- `GET /api/v1/focalboard/stages/mapping` - Get column-to-stage mapping

## Environment Variables

- `DATABASE_HOST` - PostgreSQL host (default: db-vsm-dev-rw.fawkes.svc)
- `DATABASE_PORT` - PostgreSQL port (default: 5432)
- `DATABASE_NAME` - Database name (default: vsm_db)
- `DATABASE_USER` - Database user (default: vsm_user)
- `DATABASE_PASSWORD` - Database password (required)
- `SQL_ECHO` - Enable SQL logging (default: false)
