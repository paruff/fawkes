# ADR-029: Flow Metrics Storage Strategy

**Status**: Proposed

**Date**: 2025-01-15

**Authors**: Fawkes Architecture Team

**Deciders**: Platform Architects, SRE Team, Data Engineering

---

## Context

The Flow Metrics Service needs to store and query multiple types of data to support Value Stream Management:

1. **Flow Items** - Complete journey of work items through all stages
1. **Time-Series Metrics** - Flow velocity, flow time, efficiency trends over time
1. **Event Stream** - Raw webhook events from GitHub, Jenkins, ArgoCD, etc.
1. **Aggregated Analytics** - Pre-calculated metrics for dashboards
1. **Historical Data** - Long-term retention for trend analysis

**Key Requirements:**

### Functional Requirements

- Store complete flow item lifecycle (8 stages, multiple timestamps)
- Support complex relational queries (joins across teams, stages, items)
- Handle time-series data for trending and alerting
- Enable real-time dashboard updates (<1 second latency)
- Support historical queries (90 days minimum, ideally 1+ year)
- Calculate percentiles (P50, P75, P95) efficiently
- Support team-level and individual item drill-downs
- Enable export for data science/ML analysis

### Non-Functional Requirements

- **Write throughput**: 100+ events/second (peak)
- **Query latency**: <500ms for dashboard queries
- **Data retention**: 90 days hot, 1 year warm, 3 years cold
- **Availability**: 99.9% uptime
- **Scalability**: Support 50+ teams, 10,000+ flow items/month
- **Cost**: <$500/month infrastructure
- **Backup/Recovery**: RPO <1 hour, RTO <4 hours

### Data Access Patterns

**Write-Heavy Patterns:**

- Webhook events (high frequency, small payloads)
- Flow item updates (multiple times per item lifecycle)
- Metrics calculations (periodic batch processing)

**Read-Heavy Patterns:**

- Dashboard queries (real-time, high concurrency)
- Team metrics (daily/weekly aggregations)
- Individual flow item drill-downs (ad-hoc queries)
- Historical trend analysis (monthly/quarterly reports)
- Executive reporting (weekly/monthly aggregations)

---

## Decision

We will implement a **hybrid storage architecture** combining PostgreSQL for relational data and Prometheus for time-series metrics:

### Primary Storage: PostgreSQL

**Purpose**: Authoritative source for flow items and detailed event data

**Schema**:

```sql
-- Core flow items table
CREATE TABLE flow_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(255) NOT NULL,  -- GitHub issue #, JIRA ticket, etc.
    team_id VARCHAR(100) NOT NULL,
    item_type VARCHAR(50) NOT NULL,     -- feature, bug, chore
    title VARCHAR(500),
    description TEXT,
    story_points INTEGER,
    current_stage VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,        -- in_progress, completed, cancelled
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,

    -- Metadata
    labels JSONB,
    metadata JSONB,

    -- Indexes
    CONSTRAINT flow_items_external_id_key UNIQUE (external_id, team_id)
);

CREATE INDEX idx_flow_items_team_status ON flow_items(team_id, status);
CREATE INDEX idx_flow_items_created_at ON flow_items(created_at);
CREATE INDEX idx_flow_items_completed_at ON flow_items(completed_at) WHERE completed_at IS NOT NULL;
CREATE INDEX idx_flow_items_current_stage ON flow_items(current_stage);

-- Stage transitions table
CREATE TABLE stage_transitions (
    id BIGSERIAL PRIMARY KEY,
    flow_item_id UUID NOT NULL REFERENCES flow_items(id) ON DELETE CASCADE,
    from_stage VARCHAR(50),
    to_stage VARCHAR(50) NOT NULL,
    transitioned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    duration_seconds INTEGER,  -- Time spent in from_stage

    -- Metadata
    triggered_by VARCHAR(100),  -- user, automation, webhook
    event_type VARCHAR(100),
    event_payload JSONB,

    -- Indexes
    CONSTRAINT stage_transitions_flow_item_stage UNIQUE (flow_item_id, to_stage)
);

CREATE INDEX idx_stage_transitions_flow_item ON stage_transitions(flow_item_id);
CREATE INDEX idx_stage_transitions_timestamp ON stage_transitions(transitioned_at);
CREATE INDEX idx_stage_transitions_stage ON stage_transitions(to_stage);

-- Stage metrics (denormalized for query performance)
CREATE TABLE stage_metrics (
    id BIGSERIAL PRIMARY KEY,
    flow_item_id UUID NOT NULL REFERENCES flow_items(id) ON DELETE CASCADE,
    stage VARCHAR(50) NOT NULL,

    -- Time tracking
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    active_time_seconds INTEGER DEFAULT 0,
    wait_time_seconds INTEGER DEFAULT 0,

    -- Calculated metrics
    flow_efficiency_percent DECIMAL(5,2),

    -- Metadata
    blockers JSONB,  -- List of blockers encountered
    metadata JSONB,

    CONSTRAINT stage_metrics_flow_item_stage UNIQUE (flow_item_id, stage)
);

CREATE INDEX idx_stage_metrics_flow_item ON stage_metrics(flow_item_id);
CREATE INDEX idx_stage_metrics_stage ON stage_metrics(stage);

-- Teams table
CREATE TABLE teams (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,

    -- Configuration
    wip_limit INTEGER DEFAULT 20,
    target_flow_time_hours INTEGER DEFAULT 96,  -- 4 days
    target_flow_efficiency_percent INTEGER DEFAULT 40,

    -- Metadata
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    config JSONB
);

-- Raw webhook events (for debugging and reprocessing)
CREATE TABLE webhook_events (
    id BIGSERIAL PRIMARY KEY,
    source VARCHAR(50) NOT NULL,        -- github, jenkins, argocd
    event_type VARCHAR(100) NOT NULL,
    received_at TIMESTAMP NOT NULL DEFAULT NOW(),
    processed_at TIMESTAMP,
    processing_status VARCHAR(50) DEFAULT 'pending',  -- pending, processed, failed

    -- Event data
    payload JSONB NOT NULL,
    headers JSONB,

    -- Processing info
    flow_item_id UUID REFERENCES flow_items(id),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,

    -- Partitioning by month
    CHECK (received_at >= DATE '2025-01-01')
);

CREATE INDEX idx_webhook_events_source ON webhook_events(source, event_type);
CREATE INDEX idx_webhook_events_received_at ON webhook_events(received_at);
CREATE INDEX idx_webhook_events_processing_status ON webhook_events(processing_status)
    WHERE processing_status != 'processed';

-- Partition webhook_events by month for performance
CREATE TABLE webhook_events_2025_01 PARTITION OF webhook_events
    FOR VALUES FROM ('2025-01-01') TO ('2025-02-01');

-- Aggregated metrics (pre-calculated for dashboard performance)
CREATE TABLE daily_team_metrics (
    id BIGSERIAL PRIMARY KEY,
    team_id VARCHAR(100) NOT NULL REFERENCES teams(id),
    metric_date DATE NOT NULL,

    -- Flow metrics
    flow_velocity DECIMAL(10,2),              -- items/week
    flow_time_p50_hours DECIMAL(10,2),
    flow_time_p75_hours DECIMAL(10,2),
    flow_time_p95_hours DECIMAL(10,2),
    flow_efficiency_percent DECIMAL(5,2),
    flow_load INTEGER,                         -- WIP count

    -- Item counts
    items_completed INTEGER DEFAULT 0,
    items_started INTEGER DEFAULT 0,
    items_cancelled INTEGER DEFAULT 0,

    -- Breakdown by type
    features_completed INTEGER DEFAULT 0,
    bugs_completed INTEGER DEFAULT 0,
    chores_completed INTEGER DEFAULT 0,

    -- Calculated
    calculated_at TIMESTAMP NOT NULL DEFAULT NOW(),

    CONSTRAINT daily_team_metrics_team_date UNIQUE (team_id, metric_date)
);

CREATE INDEX idx_daily_team_metrics_team_date ON daily_team_metrics(team_id, metric_date DESC);

-- Materialized view for current flow metrics (refreshed every 5 minutes)
CREATE MATERIALIZED VIEW current_flow_metrics AS
SELECT
    fi.team_id,
    COUNT(*) FILTER (WHERE fi.status = 'in_progress') as current_wip,
    COUNT(*) FILTER (WHERE fi.completed_at >= NOW() - INTERVAL '7 days') as completed_last_7d,
    COUNT(*) FILTER (WHERE fi.completed_at >= NOW() - INTERVAL '30 days') as completed_last_30d,

    -- Flow time percentiles (last 30 days)
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY
        EXTRACT(EPOCH FROM (fi.completed_at - fi.created_at))/3600
    ) FILTER (WHERE fi.completed_at >= NOW() - INTERVAL '30 days') as flow_time_p50_hours,

    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY
        EXTRACT(EPOCH FROM (fi.completed_at - fi.created_at))/3600
    ) FILTER (WHERE fi.completed_at >= NOW() - INTERVAL '30 days') as flow_time_p95_hours,

    -- Flow efficiency (last 30 days)
    AVG(
        (SELECT SUM(sm.active_time_seconds) FROM stage_metrics sm WHERE sm.flow_item_id = fi.id) /
        NULLIF(EXTRACT(EPOCH FROM (fi.completed_at - fi.created_at)), 0) * 100
    ) FILTER (WHERE fi.completed_at >= NOW() - INTERVAL '30 days') as avg_flow_efficiency_percent,

    MAX(fi.updated_at) as last_updated
FROM flow_items fi
GROUP BY fi.team_id;

CREATE UNIQUE INDEX ON current_flow_metrics (team_id);

-- Refresh materialized view every 5 minutes via cron job
-- SELECT refresh_flow_metrics_view();
```

### Secondary Storage: Prometheus

**Purpose**: Time-series metrics for real-time monitoring and alerting

**Metrics Exposed**:

```python
# flow_metrics_service/src/metrics/prometheus_metrics.py

from prometheus_client import Counter, Histogram, Gauge, Summary

# Flow Velocity
flow_velocity_items_per_week = Gauge(
    'flow_velocity_items_per_week',
    'Number of flow items completed per week',
    ['team', 'item_type']
)

# Flow Time
flow_time_seconds = Histogram(
    'flow_time_seconds',
    'Total time from start to completion',
    ['team', 'item_type'],
    buckets=[
        3600,      # 1 hour
        21600,     # 6 hours
        86400,     # 1 day
        172800,    # 2 days
        345600,    # 4 days
        604800,    # 1 week
        1209600,   # 2 weeks
        2592000,   # 30 days
    ]
)

# Flow Efficiency
flow_efficiency_percent = Histogram(
    'flow_efficiency_percent',
    'Flow efficiency (active time / total time)',
    ['team'],
    buckets=[10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
)

# Flow Load (WIP)
flow_load_wip_current = Gauge(
    'flow_load_wip_current',
    'Current number of items in progress',
    ['team']
)

flow_load_wip_limit = Gauge(
    'flow_load_wip_limit',
    'WIP limit for team',
    ['team']
)

# Stage Metrics
stage_wait_time_seconds = Histogram(
    'stage_wait_time_seconds',
    'Wait time in each stage',
    ['team', 'stage'],
    buckets=[300, 1800, 3600, 21600, 86400, 172800, 604800]
)

stage_active_time_seconds = Histogram(
    'stage_active_time_seconds',
    'Active time in each stage',
    ['team', 'stage'],
    buckets=[300, 1800, 3600, 21600, 86400, 172800]
)

stage_flow_efficiency_percent = Gauge(
    'stage_flow_efficiency_percent',
    'Flow efficiency per stage',
    ['team', 'stage']
)

# Event Counters
webhook_events_received_total = Counter(
    'webhook_events_received_total',
    'Total webhook events received',
    ['source', 'event_type']
)

webhook_events_processed_total = Counter(
    'webhook_events_processed_total',
    'Total webhook events successfully processed',
    ['source', 'event_type']
)

webhook_events_failed_total = Counter(
    'webhook_events_failed_total',
    'Total webhook events that failed processing',
    ['source', 'event_type', 'error_type']
)

# Flow Item Lifecycle
flow_items_created_total = Counter(
    'flow_items_created_total',
    'Total flow items created',
    ['team', 'item_type']
)

flow_items_completed_total = Counter(
    'flow_items_completed_total',
    'Total flow items completed',
    ['team', 'item_type']
)

flow_items_cancelled_total = Counter(
    'flow_items_cancelled_total',
    'Total flow items cancelled',
    ['team', 'item_type']
)

# Stage Transitions
stage_transitions_total = Counter(
    'stage_transitions_total',
    'Total stage transitions',
    ['team', 'from_stage', 'to_stage']
)

# Bottleneck Detection
bottleneck_detected = Gauge(
    'bottleneck_detected',
    'Binary indicator of bottleneck (1 = yes, 0 = no)',
    ['team', 'stage']
)

bottleneck_severity = Gauge(
    'bottleneck_severity',
    'Severity of bottleneck (0-100 scale)',
    ['team', 'stage']
)
```

### Tertiary Storage: S3 (Cold Storage)

**Purpose**: Long-term archival and compliance

**Data Archived**:

- Flow items older than 90 days (compressed JSON)
- Webhook events older than 30 days
- Daily aggregated metrics (permanent retention)

**Format**: Parquet files partitioned by `year/month/team_id/`

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    WRITE PATH                                    │
└─────────────────────────────────────────────────────────────────┘

GitHub/Jenkins/ArgoCD Webhooks
        ↓
┌──────────────────┐
│ Flow Metrics API │
│ (FastAPI)        │
└────────┬─────────┘
         │
         ├──────────────────┐
         ↓                  ↓
┌─────────────────┐  ┌──────────────────┐
│ PostgreSQL      │  │ Prometheus       │
│ (write-through) │  │ (metrics export) │
└─────────────────┘  └──────────────────┘
         │
         ↓ (async background job)
┌─────────────────┐
│ Metrics         │
│ Aggregator      │
│ (nightly batch) │
└────────┬────────┘
         │
         ↓
┌─────────────────┐
│ daily_team_     │
│ metrics table   │
└─────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                    READ PATH                                     │
└─────────────────────────────────────────────────────────────────┘

Dashboard Queries
        │
        ├─────────────────────────┬─────────────────────────┐
        ↓                         ↓                         ↓
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ Grafana          │    │ Backstage VSM    │    │ Executive        │
│ (Prometheus +    │    │ (PostgreSQL)     │    │ Reports          │
│  PostgreSQL)     │    │                  │    │ (PostgreSQL)     │
└──────────────────┘    └──────────────────┘    └──────────────────┘
        ↓                         ↓                         ↓
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ current_flow_    │    │ flow_items       │    │ daily_team_      │
│ metrics view     │    │ + stage_metrics  │    │ metrics          │
│ (5min refresh)   │    │ (live queries)   │    │ (pre-agg)        │
└──────────────────┘    └──────────────────┘    └──────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                    ARCHIVAL PATH                                 │
└─────────────────────────────────────────────────────────────────┘

PostgreSQL (90+ days old)
        ↓
┌──────────────────┐
│ Archival Job     │
│ (weekly cron)    │
└────────┬─────────┘
         ↓
┌──────────────────┐
│ S3 Bucket        │
│ (Parquet files)  │
│ year/month/team/ │
└──────────────────┘
```

---

## Data Flow Examples

### Example 1: Webhook Event Processing

```python
# Webhook received
POST /webhook/github
{
  "event_type": "pull_request.opened",
  "pr_number": 456,
  "repository": "sample-app",
  "author": "alice",
  "timestamp": "2025-01-15T10:30:00Z"
}

# Step 1: Insert raw event to PostgreSQL
INSERT INTO webhook_events (source, event_type, payload)
VALUES ('github', 'pull_request.opened', '{"pr_number": 456, ...}');

# Step 2: Identify or create flow item
SELECT id FROM flow_items
WHERE external_id = 'sample-app#456' AND team_id = 'alpha';

# Step 3: Create stage transition
INSERT INTO stage_transitions (flow_item_id, from_stage, to_stage, transitioned_at)
VALUES ('uuid-123', 'development', 'code_review', '2025-01-15T10:30:00Z');

# Step 4: Update flow item current stage
UPDATE flow_items
SET current_stage = 'code_review', updated_at = NOW()
WHERE id = 'uuid-123';

# Step 5: Calculate and update stage metrics
UPDATE stage_metrics
SET ended_at = NOW(),
    wait_time_seconds = <calculated>,
    active_time_seconds = <calculated>
WHERE flow_item_id = 'uuid-123' AND stage = 'development';

# Step 6: Export metrics to Prometheus
stage_transitions_total{team="alpha", from_stage="development", to_stage="code_review"} += 1
flow_load_wip_current{team="alpha"} = <count in progress items>
```

### Example 2: Dashboard Query (Grafana)

```promql
# Query: Flow Velocity (last 30 days)
# Grafana queries Prometheus

flow_velocity_items_per_week{team="alpha"}

# Prometheus scrapes /metrics endpoint every 15 seconds
# Flow Metrics Service calculates and exposes:
# - Count completed items in last 7 days
# - Divide by (7/7) = items per week
# - Update gauge metric
```

### Example 3: Detailed Flow Item Query (Backstage)

```sql
-- Query: Get complete flow item journey for USER-123

-- Main flow item
SELECT * FROM flow_items WHERE external_id = 'USER-123';

-- All stage transitions
SELECT
    st.from_stage,
    st.to_stage,
    st.transitioned_at,
    st.duration_seconds
FROM stage_transitions st
JOIN flow_items fi ON st.flow_item_id = fi.id
WHERE fi.external_id = 'USER-123'
ORDER BY st.transitioned_at;

-- Stage-level metrics
SELECT
    sm.stage,
    sm.started_at,
    sm.ended_at,
    sm.active_time_seconds,
    sm.wait_time_seconds,
    sm.flow_efficiency_percent
FROM stage_metrics sm
JOIN flow_items fi ON sm.flow_item_id = fi.id
WHERE fi.external_id = 'USER-123'
ORDER BY sm.started_at;

-- Calculate total flow efficiency
SELECT
    SUM(sm.active_time_seconds) as total_active,
    SUM(sm.active_time_seconds + sm.wait_time_seconds) as total_time,
    (SUM(sm.active_time_seconds)::float /
     NULLIF(SUM(sm.active_time_seconds + sm.wait_time_seconds), 0) * 100) as flow_efficiency
FROM stage_metrics sm
JOIN flow_items fi ON sm.flow_item_id = fi.id
WHERE fi.external_id = 'USER-123';
```

---

## Rationale

### Why PostgreSQL for Primary Storage?

**Pros:**

- ✅ Strong relational model (flow items → transitions → metrics)
- ✅ ACID compliance for data integrity
- ✅ Complex JOIN queries for analytics
- ✅ Excellent JSON support (JSONB) for flexible metadata
- ✅ Materialized views for query performance
- ✅ Partitioning for time-series data management
- ✅ Native support in Backstage and other tools
- ✅ Team familiarity (already using for other Fawkes components)
- ✅ Proven at scale (handle millions of rows)

**Cons:**

- ❌ Not optimized for pure time-series queries
- ❌ Requires careful indexing for performance
- ❌ More expensive than NoSQL for massive scale

**Why Not Alternatives?**

**MongoDB:**

- Document model doesn’t fit relational nature of flow items
- Weaker consistency guarantees
- More complex to query across relationships

**Cassandra:**

- Overkill for expected scale (<10M rows/year)
- Complex operational overhead
- Difficult to change schema

**DynamoDB:**

- Expensive at scale
- Limited query flexibility
- Vendor lock-in

### Why Prometheus for Time-Series?

**Pros:**

- ✅ Industry standard for metrics
- ✅ Native Grafana integration
- ✅ Efficient time-series storage
- ✅ Powerful query language (PromQL)
- ✅ Built-in alerting
- ✅ Pull-based model (service exposes /metrics)
- ✅ Already deployed in Fawkes for DORA metrics

**Cons:**

- ❌ Limited retention (15 days default, expensive to extend)
- ❌ Not designed for detailed event storage
- ❌ No JOIN capabilities

**Why Not Alternatives?**

**InfluxDB:**

- Additional infrastructure component
- Licensing concerns (InfluxDB 3.x)
- Less mature Grafana integration

**TimescaleDB:**

- PostgreSQL extension, could consolidate storage
- Considered but adds complexity to single PostgreSQL instance
- Future option if Prometheus retention becomes issue

### Why S3 for Archival?

**Pros:**

- ✅ Extremely cost-effective ($0.023/GB/month)
- ✅ Unlimited retention
- ✅ Parquet format efficient for analytics
- ✅ Compatible with data science tools (Pandas, Spark)
- ✅ Lifecycle policies for automatic tiering

**Cons:**

- ❌ High latency (seconds to retrieve)
- ❌ Not queryable without external tools

---

## Data Retention Strategy

```
┌─────────────────────────────────────────────────────────────────┐
│ Data Lifecycle Management                                        │
└─────────────────────────────────────────────────────────────────┘

0-30 days (HOT):
├─ PostgreSQL: All tables (full detail)
├─ Prometheus: All metrics (15-second resolution)
└─ Query performance: <100ms

30-90 days (WARM):
├─ PostgreSQL: All tables (full detail)
├─ Prometheus: Downsampled to 1-minute resolution (via recording rules)
└─ Query performance: <500ms

90 days - 1 year (COLD):
├─ PostgreSQL: Aggregated metrics only (daily_team_metrics)
├─ S3: Full detail (Parquet files)
├─ Prometheus: Not available (use PostgreSQL)
└─ Query performance: <2s (from PostgreSQL), <30s (from S3)

1+ years (ARCHIVED):
├─ PostgreSQL: Aggregated metrics only
├─ S3: Full detail (Parquet + Glacier)
└─ Query performance: Minutes (from Glacier)

Deletion Policy:
├─ webhook_events: Delete after 90 days
├─ stage_transitions: Archive to S3 after 90 days, delete after 1 year
├─ flow_items: Archive to S3 after 90 days, delete after 3 years
├─ daily_team_metrics: Keep forever (small size)
└─ Prometheus: Automatic deletion after 15 days
```

---

## Performance Optimization Strategies

### 1. Database Indexing

```sql
-- Indexes for common query patterns

-- Dashboard: Team metrics
CREATE INDEX CONCURRENTLY idx_flow_items_team_completed
ON flow_items(team_id, completed_at)
WHERE status = 'completed';

-- Dashboard: WIP count
CREATE INDEX CONCURRENTLY idx_flow_items_team_in_progress
ON flow_items(team_id)
WHERE status = 'in_progress';

-- Drill-down: Flow item lookup
CREATE INDEX CONCURRENTLY idx_flow_items_external_id_hash
ON flow_items USING hash(external_id);

-- Analytics: Stage efficiency
CREATE INDEX CONCURRENTLY idx_stage_metrics_stage_efficiency
ON stage_metrics(stage, flow_efficiency_percent);

-- Webhook processing: Unprocessed events
CREATE INDEX CONCURRENTLY idx_webhook_events_pending
ON webhook_events(source, received_at)
WHERE processing_status = 'pending';
```

### 2. Materialized Views

```sql
-- Refresh strategy
CREATE OR REPLACE FUNCTION refresh_flow_metrics_view()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY current_flow_metrics;
END;
$$ LANGUAGE plpgsql;

-- Schedule via pg_cron (every 5 minutes)
SELECT cron.schedule('refresh-flow-metrics', '*/5 * * * *',
    'SELECT refresh_flow_metrics_view()');
```

### 3. Partitioning

```sql
-- Partition webhook_events by month
CREATE TABLE webhook_events (
    -- ... columns ...
) PARTITION BY RANGE (received_at);

-- Create partitions for 2025
DO $$
DECLARE
    month_start DATE;
BEGIN
    FOR month_num IN 1..12 LOOP
        month_start := DATE '2025-01-01' + (month_num - 1) * INTERVAL '1 month';
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS webhook_events_%s PARTITION OF webhook_events
             FOR VALUES FROM (%L) TO (%L)',
            to_char(month_start, 'YYYY_MM'),
            month_start,
            month_start + INTERVAL '1 month'
        );
    END LOOP;
END $$;

-- Automatic partition creation (pg_partman)
SELECT partman.create_parent(
    p_parent_table := 'public.webhook_events',
    p_control := 'received_at',
    p_type := 'native',
    p_interval := '1 month',
    p_premake := 3  -- Create 3 months ahead
);
```

### 4. Query Optimization

```python
# Use connection pooling
from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool

engine = create_engine(
    'postgresql://flowmetrics:password@postgres:5432/flowmetrics',
    poolclass=QueuePool,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True  # Verify connections before use
)

# Use prepared statements for repeated queries
from sqlalchemy import text

# Bad: Vulnerable to SQL injection, not prepared
def get_team_metrics_bad(team_id):
    query = f"SELECT * FROM daily_team_metrics WHERE team_id = '{team_id}'"
    return engine.execute(query)

# Good: Parameterized, prepared statement
def get_team_metrics_good(team_id):
    query = text("""
        SELECT * FROM daily_team_metrics
        WHERE team_id = :team_id
        ORDER BY metric_date DESC
        LIMIT 30
    """)
    return engine.execute(query, {"team_id": team_id})

# Best: Use SQLAlchemy ORM with lazy loading
from sqlalchemy.orm import sessionmaker

Session = sessionmaker(bind=engine)

def get_team_metrics_best(team_id):
    session = Session()
    return session.query(DailyTeamMetrics)\
        .filter_by(team_id=team_id)\
        .order_by(DailyTeamMetrics.metric_date.desc())\
        .limit(30)\
        .all()
```

### 5. Caching Strategy

```python
# Redis for hot data caching
from redis import Redis
import json

redis_client = Redis(host='redis', port=6379, db=0)

def get_team_flow_metrics(team_id: str, force_refresh: bool = False):
    """
    Get team flow metrics with Redis caching
    Cache TTL: 5 minutes
    """
    cache_key = f"flow_metrics:team:{team_id}"

    # Try cache first
    if not force_refresh:
        cached = redis_client.get(cache_key)
        if cached:
            return json.loads(cached)

    # Cache miss - query database
    metrics = calculate_team_metrics(team_id)

    # Store in cache with 5-minute TTL
    redis_client.setex(
        cache_key,
        300,  # 5 minutes
        json.dumps(metrics)
    )

    return metrics

# Cache invalidation on write
def update_flow_item(flow_item_id: str, updates: dict):
    # Update database
    update_database(flow_item_id, updates)

    # Invalidate team cache
    flow_item = get_flow_item(flow_item_id)
    redis_client.delete(f"flow_metrics:team:{flow_item.team_id}")
```

---

## Disaster Recovery

### Backup Strategy

```yaml
# PostgreSQL backup configuration
backup:
  tool: pg_dump + wal-e
  frequency:
    full: daily at 02:00 UTC
    incremental: continuous (WAL archiving)
  retention:
    full_backups: 30 days
    wal_archives: 30 days
  storage:
    primary: S3 (s3://fawkes-backups/postgres/flow-metrics/)
    encryption: AES-256
  verification:
    test_restore: weekly
    rpo:​​​​​​​​​​​​​​​​
```

---

### Week 3: Optimization (continued)

- [ ] Create materialized views
- [ ] Set up automated view refresh (pg_cron)
- [ ] Implement query performance monitoring
- [ ] Add database indexes based on query patterns
- [ ] Configure connection pooling (PgBouncer)
- [ ] Set up Redis caching for hot queries
- [ ] Enable query result caching
- [ ] Run performance benchmarks (Locust tests)

### Week 4: Monitoring & Alerting

- [ ] Configure Prometheus alerts for database health
- [ ] Set up Grafana dashboards for database metrics
- [ ] Create webhook processing monitoring
- [ ] Implement slow query alerting
- [ ] Configure disk usage alerts
- [ ] Set up replication lag monitoring (if using replicas)
- [ ] Create runbook for common issues
- [ ] Test alert notifications (PagerDuty/Slack)

### Week 5: Backup & Recovery

- [ ] Verify automated backups are running
- [ ] Test point-in-time recovery (PITR)
- [ ] Document recovery procedures
- [ ] Set up S3 lifecycle policies for old backups
- [ ] Test backup restoration (weekly automated test)
- [ ] Create disaster recovery runbook
- [ ] Configure backup monitoring and alerts
- [ ] Validate RPO/RTO targets

### Week 6: Data Migration

- [ ] Backfill historical data (90 days)
- [ ] Run data validation scripts
- [ ] Compare metrics with legacy system (if exists)
- [ ] Enable dual-write mode (if migrating)
- [ ] Monitor data consistency
- [ ] Address any discrepancies
- [ ] Plan cutover timeline
- [ ] Document rollback procedures

### Week 7: Security Hardening

- [ ] Enable SSL/TLS for all connections
- [ ] Rotate database credentials
- [ ] Implement row-level security policies
- [ ] Enable audit logging (pgaudit)
- [ ] Configure WAF rules for API endpoints
- [ ] Perform security scan (Trivy, Snyk)
- [ ] Review IAM policies and roles
- [ ] Document security controls

### Week 8: Production Readiness

- [ ] Conduct load testing (100+ users)
- [ ] Perform chaos engineering tests
- [ ] Validate all monitoring is operational
- [ ] Complete documentation (architecture, runbooks)
- [ ] Train team on operations and troubleshooting
- [ ] Schedule go-live date
- [ ] Prepare rollback plan
- [ ] Conduct final readiness review

---

## Operational Runbooks

### Runbook 1: High Connection Count

**Symptoms:**

- Alert: “PostgreSQL High Connection Count”
- Dashboard shows >80 active connections
- API latency increasing

**Diagnosis:**

```sql
-- Check current connections
SELECT
    datname,
    count(*) as connections,
    usename
FROM pg_stat_activity
WHERE state = 'active'
GROUP BY datname, usename
ORDER BY connections DESC;

-- Check long-running queries
SELECT
    pid,
    now() - pg_stat_activity.query_start AS duration,
    query,
    state
FROM pg_stat_activity
WHERE state != 'idle'
    AND now() - pg_stat_activity.query_start > interval '5 minutes'
ORDER BY duration DESC;
```

**Resolution:**

1. **Immediate**: Kill long-running queries if safe

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE pid = <problematic_pid>;
```

1. **Short-term**: Restart PgBouncer to reset connection pool

```bash
kubectl rollout restart deployment/pgbouncer -n fawkes
```

1. **Long-term**: Increase connection limit or optimize queries

```sql
-- Increase max_connections (requires restart)
ALTER SYSTEM SET max_connections = 200;
SELECT pg_reload_conf();
```

**Prevention:**

- Use connection pooling (PgBouncer)
- Set application connection timeout (30 seconds)
- Implement query timeout limits
- Monitor connection patterns

---

### Runbook 2: Slow Query Performance

**Symptoms:**

- Alert: “PostgreSQL Slow Queries”
- Dashboard query latency >1 second
- User complaints about slow dashboards

**Diagnosis:**

```sql
-- Find slow queries
SELECT
    query,
    calls,
    mean_exec_time,
    max_exec_time,
    stddev_exec_time
FROM pg_stat_statements
WHERE mean_exec_time > 1000  -- 1 second
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check for missing indexes
SELECT
    schemaname,
    tablename,
    seq_scan,
    seq_tup_read,
    idx_scan,
    idx_tup_fetch,
    seq_tup_read / seq_scan as avg_seq_tup
FROM pg_stat_user_tables
WHERE seq_scan > 100
    AND seq_tup_read / NULLIF(seq_scan, 0) > 10000
ORDER BY seq_tup_read DESC;

-- Check table bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    n_live_tup,
    n_dead_tup,
    n_dead_tup * 100.0 / NULLIF(n_live_tup, 0) as dead_tuple_percent
FROM pg_stat_user_tables
WHERE n_dead_tup > 1000
ORDER BY n_dead_tup DESC;
```

**Resolution:**

1. **Immediate**: Refresh materialized views

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY current_flow_metrics;
```

1. **Short-term**: Add missing indexes

```sql
-- Example: Add index for team metrics query
CREATE INDEX CONCURRENTLY idx_flow_items_team_completed_at
ON flow_items(team_id, completed_at)
WHERE status = 'completed';
```

1. **Medium-term**: Vacuum bloated tables

```sql
VACUUM ANALYZE flow_items;
VACUUM ANALYZE stage_transitions;
```

1. **Long-term**: Optimize query or denormalize data

```sql
-- Create aggregated table for better performance
CREATE TABLE team_metrics_summary AS
SELECT
    team_id,
    date_trunc('day', completed_at) as date,
    count(*) as items_completed,
    percentile_cont(0.5) WITHIN GROUP (ORDER BY flow_time) as p50_flow_time
FROM flow_items
WHERE completed_at IS NOT NULL
GROUP BY team_id, date_trunc('day', completed_at);

CREATE INDEX ON team_metrics_summary(team_id, date DESC);
```

**Prevention:**

- Enable auto-vacuum (should be default)
- Monitor pg_stat_statements regularly
- Set query timeout: `SET statement_timeout = '5s'`
- Use EXPLAIN ANALYZE for new queries

---

### Runbook 3: Webhook Processing Backlog

**Symptoms:**

- Alert: “Webhook Processing Backlog”
- 100 pending webhook events
- Metrics not updating in real-time

**Diagnosis:**

```sql
-- Check backlog size
SELECT
    source,
    count(*) as pending_count
FROM webhook_events
WHERE processing_status = 'pending'
GROUP BY source;

-- Check for failures
SELECT
    source,
    event_type,
    error_message,
    count(*) as failure_count
FROM webhook_events
WHERE processing_status = 'failed'
    AND received_at > NOW() - INTERVAL '1 hour'
GROUP BY source, event_type, error_message
ORDER BY failure_count DESC;

-- Check processing rate
SELECT
    date_trunc('minute', processed_at) as minute,
    count(*) as processed_count
FROM webhook_events
WHERE processed_at > NOW() - INTERVAL '30 minutes'
GROUP BY date_trunc('minute', processed_at)
ORDER BY minute DESC;
```

**Resolution:**

1. **Immediate**: Scale up webhook processors

```bash
# Increase replicas
kubectl scale deployment/flow-metrics-service --replicas=5 -n fawkes

# Check pod status
kubectl get pods -n fawkes -l app=flow-metrics
```

1. **Short-term**: Reprocess failed events

```python
# Retry failed events
python scripts/reprocess_failed_webhooks.py --hours=1 --limit=100
```

1. **Medium-term**: Identify and fix error patterns

```python
# Common error: missing flow item
# Fix: Create flow item from webhook data
if error_message == 'Flow item not found':
    create_flow_item_from_webhook(webhook_event)
    retry_webhook_processing(webhook_event.id)
```

1. **Long-term**: Optimize webhook processing

```python
# Add batch processing for high-volume events
def process_webhooks_batch(events: List[WebhookEvent]):
    # Process 100 events at once
    with database.transaction():
        for event in events:
            process_webhook(event)

    # Commit once instead of 100 times
```

**Prevention:**

- Implement circuit breaker pattern
- Add webhook event TTL (delete after 90 days)
- Monitor webhook sources for unusual volume
- Implement rate limiting on webhook endpoints

---

### Runbook 4: Disk Space Critical

**Symptoms:**

- Alert: “PostgreSQL Disk Usage High”
- Disk usage >80%
- Write operations may fail soon

**Diagnosis:**

```sql
-- Check database sizes
SELECT
    datname,
    pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;

-- Check table sizes
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
    pg_size_pretty(pg_table_size(schemaname||'.'||tablename)) as table_size,
    pg_size_pretty(pg_indexes_size(schemaname||'.'||tablename)) as indexes_size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check WAL size
SELECT
    pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), '0/0')) as wal_size;

-- Check bloat
SELECT
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
    n_dead_tup,
    n_dead_tup * 100.0 / NULLIF(n_live_tup + n_dead_tup, 0) as dead_percentage
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_dead_tup DESC;
```

**Resolution:**

1. **Immediate**: Archive old webhook events to S3

```python
# Archive events older than 30 days
python scripts/archive_old_webhooks.py --days=30 --confirm
```

1. **Short-term**: Vacuum full bloated tables (requires downtime)

```sql
-- Reclaim disk space (use CONCURRENTLY to avoid locks if possible)
VACUUM FULL webhook_events;

-- Or without downtime but slower:
VACUUM ANALYZE webhook_events;
```

1. **Medium-term**: Increase disk size

```bash
# AWS RDS
aws rds modify-db-instance \
    --db-instance-identifier fawkes-flowmetrics \
    --allocated-storage 1000 \
    --apply-immediately
```

1. **Long-term**: Implement data lifecycle management

```python
# Automated cleanup job (daily cron)
def cleanup_old_data():
    # Archive flow items older than 90 days
    old_items = FlowItem.query.filter(
        FlowItem.completed_at < datetime.now() - timedelta(days=90)
    ).all()

    for item in old_items:
        # Export to S3
        export_to_s3(item)

        # Delete from database
        database.session.delete(item)

    database.session.commit()
```

**Prevention:**

- Set up automated archival (90-day policy)
- Monitor disk usage trends
- Alert at 70% (warning) and 80% (critical)
- Enable auto-scaling storage (AWS RDS)

---

### Runbook 5: Backup Failure

**Symptoms:**

- Alert: “PostgreSQL Backup Failed”
- No recent backup in S3
- WAL archiving failing

**Diagnosis:**

```bash
# Check last successful backup
aws s3 ls s3://fawkes-backups/postgres/flow-metrics/ --recursive | sort | tail -5

# Check WAL archiving status
psql -U postgres -c "SELECT * FROM pg_stat_archiver;"

# Check for disk space issues
df -h /var/lib/postgresql/data

# Check backup logs
kubectl logs -n fawkes postgres-0 | grep -i backup | tail -50
```

**Resolution:**

1. **Immediate**: Manually trigger backup

```bash
# Manual pg_dump
kubectl exec -it postgres-0 -n fawkes -- bash
pg_dump -Fc -U postgres flowmetrics > /tmp/manual_backup_$(date +%Y%m%d).dump

# Upload to S3
aws s3 cp /tmp/manual_backup_*.dump s3://fawkes-backups/postgres/flow-metrics/manual/
```

1. **Short-term**: Fix WAL archiving

```bash
# Check archive_command
psql -U postgres -c "SHOW archive_command;"

# Test manually
/usr/bin/wal-e wal-push /var/lib/postgresql/data/pg_wal/000000010000000000000001

# If failing due to credentials
# Update AWS credentials in Kubernetes secret
kubectl edit secret postgres-backup-credentials -n fawkes
```

1. **Medium-term**: Verify backup script

```bash
# Check cron job status
kubectl get cronjobs -n fawkes
kubectl describe cronjob postgres-backup -n fawkes

# View recent job runs
kubectl get jobs -n fawkes | grep postgres-backup

# Check job logs
kubectl logs job/postgres-backup-12345 -n fawkes
```

1. **Long-term**: Test restore procedure

```bash
# Scheduled restore test (weekly)
python scripts/test_backup_restore.py --backup-date=2025-01-15
```

**Prevention:**

- Monitor backup success rate (should be 100%)
- Test restores monthly
- Alert on failed backups within 1 hour
- Document recovery procedures
- Maintain backup retention policy

---

## Maintenance Tasks

### Daily

```bash
#!/bin/bash
# daily_maintenance.sh

# Refresh materialized views
psql -U flowmetrics -d flowmetrics -c "REFRESH MATERIALIZED VIEW CONCURRENTLY current_flow_metrics;"

# Update aggregated metrics
python scripts/calculate_daily_team_metrics.py --date=yesterday

# Check for slow queries
psql -U flowmetrics -d flowmetrics -f scripts/check_slow_queries.sql

# Verify backup completed
python scripts/verify_backup.py --date=today

# Archive old webhook events (30+ days)
python scripts/archive_webhooks.py --days=30 --dry-run=false
```

### Weekly

```bash
#!/bin/bash
# weekly_maintenance.sh

# Vacuum analyze all tables
psql -U flowmetrics -d flowmetrics -c "VACUUM ANALYZE;"

# Test backup restore
python scripts/test_restore.py --latest

# Review unused indexes
psql -U flowmetrics -d flowmetrics -f scripts/check_unused_indexes.sql

# Check table bloat
psql -U flowmetrics -d flowmetrics -f scripts/check_table_bloat.sql

# Generate performance report
python scripts/generate_performance_report.py --week

# Update documentation
python scripts/update_metrics_documentation.py
```

### Monthly

```bash
#!/bin/bash
# monthly_maintenance.sh

# Archive completed flow items (90+ days)
python scripts/archive_flow_items.py --days=90

# Optimize database
psql -U flowmetrics -d flowmetrics -c "REINDEX DATABASE flowmetrics;"

# Review and tune configuration
python scripts/analyze_pg_configuration.py --suggest

# Security audit
python scripts/security_audit.py --report

# Cost analysis
python scripts/analyze_costs.py --month=last

# Capacity planning
python scripts/capacity_forecast.py --months=6
```

### Quarterly

```bash
#!/bin/bash
# quarterly_maintenance.sh

# Full database backup verification
python scripts/verify_all_backups.py --quarter

# Disaster recovery drill
python scripts/dr_drill.py --scenario=full_restore

# Performance benchmarking
python scripts/run_benchmarks.py --full

# Schema optimization review
python scripts/analyze_schema.py --recommend

# Update monitoring thresholds
python scripts/tune_alerts.py --analyze=90days

# Review and update runbooks
python scripts/validate_runbooks.py
```

---

## Appendices

### Appendix A: SQL Schema Migration Scripts

```sql
-- Migration: 001_initial_schema.sql
-- Creates base tables for flow metrics

BEGIN;

CREATE TABLE IF NOT EXISTS teams (
    id VARCHAR(100) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    wip_limit INTEGER DEFAULT 20,
    target_flow_time_hours INTEGER DEFAULT 96,
    target_flow_efficiency_percent INTEGER DEFAULT 40,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    config JSONB
);

CREATE TABLE IF NOT EXISTS flow_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    external_id VARCHAR(255) NOT NULL,
    team_id VARCHAR(100) NOT NULL REFERENCES teams(id),
    item_type VARCHAR(50) NOT NULL,
    title VARCHAR(500),
    description TEXT,
    story_points INTEGER,
    current_stage VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMP,
    labels JSONB,
    metadata JSONB,
    CONSTRAINT flow_items_external_id_key UNIQUE (external_id, team_id)
);

CREATE TABLE IF NOT EXISTS stage_transitions (
    id BIGSERIAL PRIMARY KEY,
    flow_item_id UUID NOT NULL REFERENCES flow_items(id) ON DELETE CASCADE,
    from_stage VARCHAR(50),
    to_stage VARCHAR(50) NOT NULL,
    transitioned_at TIMESTAMP NOT NULL DEFAULT NOW(),
    duration_seconds INTEGER,
    triggered_by VARCHAR(100),
    event_type VARCHAR(100),
    event_payload JSONB,
    CONSTRAINT stage_transitions_flow_item_stage UNIQUE (flow_item_id, to_stage)
);

CREATE TABLE IF NOT EXISTS stage_metrics (
    id BIGSERIAL PRIMARY KEY,
    flow_item_id UUID NOT NULL REFERENCES flow_items(id) ON DELETE CASCADE,
    stage VARCHAR(50) NOT NULL,
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    active_time_seconds INTEGER DEFAULT 0,
    wait_time_seconds INTEGER DEFAULT 0,
    flow_efficiency_percent DECIMAL(5,2),
    blockers JSONB,
    metadata JSONB,
    CONSTRAINT stage_metrics_flow_item_stage UNIQUE (flow_item_id, stage)
);

-- Create indexes
CREATE INDEX idx_flow_items_team_status ON flow_items(team_id, status);
CREATE INDEX idx_flow_items_created_at ON flow_items(created_at);
CREATE INDEX idx_flow_items_completed_at ON flow_items(completed_at) WHERE completed_at IS NOT NULL;
CREATE INDEX idx_stage_transitions_flow_item ON stage_transitions(flow_item_id);
CREATE INDEX idx_stage_metrics_flow_item ON stage_metrics(flow_item_id);

COMMIT;
```

### Appendix B: Prometheus Recording Rules

```yaml
# prometheus_rules.yml
# Recording rules for flow metrics aggregation

groups:
  - name: flow_metrics_aggregations
    interval: 60s
    rules:
      # Flow Velocity - Pre-aggregate for performance
      - record: flow_velocity_items_per_week:team
        expr: |
          sum by (team) (
            increase(flow_items_completed_total[7d])
          )

      # Flow Time P50 - Pre-calculate percentile
      - record: flow_time_p50_hours:team
        expr: |
          histogram_quantile(0.5,
            sum by (team, le) (
              rate(flow_time_seconds_bucket[30d])
            )
          ) / 3600

      # Flow Time P95
      - record: flow_time_p95_hours:team
        expr: |
          histogram_quantile(0.95,
            sum by (team, le) (
              rate(flow_time_seconds_bucket[30d])
            )
          ) / 3600

      # Stage Wait Time Average
      - record: stage_wait_time_avg_hours:team:stage
        expr: |
          avg by (team, stage) (
            rate(stage_wait_time_seconds_sum[1h])
            /
            rate(stage_wait_time_seconds_count[1h])
          ) / 3600

      # Webhook Processing Rate
      - record: webhook_events_processing_rate:source
        expr: |
          sum by (source) (
            rate(webhook_events_processed_total[5m])
          )

      # Webhook Processing Error Rate
      - record: webhook_events_error_rate:source
        expr: |
          sum by (source) (
            rate(webhook_events_failed_total[5m])
          )
          /
          sum by (source) (
            rate(webhook_events_received_total[5m])
          )
```

### Appendix C: Database Connection Configuration

```python
# config/database.py
# Production-ready database configuration

from sqlalchemy import create_engine
from sqlalchemy.pool import QueuePool
from sqlalchemy.orm import sessionmaker
import os

# Database URL from environment
DATABASE_URL = os.getenv(
    'DATABASE_URL',
    'postgresql://flowmetrics:password@postgres:5432/flowmetrics'
)

# Connection pool configuration
engine = create_engine(
    DATABASE_URL,
    poolclass=QueuePool,
    pool_size=20,              # Base connection pool size
    max_overflow=40,           # Additional connections when needed
    pool_timeout=30,           # Wait 30s for connection
    pool_recycle=3600,         # Recycle connections after 1 hour
    pool_pre_ping=True,        # Verify connections before use
    echo=False,                # Don't log SQL (use for debugging only)
    echo_pool=False,           # Don't log pool events
    connect_args={
        'connect_timeout': 10,
        'options': '-c statement_timeout=30000'  # 30s query timeout
    }
)

# Session factory
SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)

# Dependency for FastAPI
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

---

## Conclusion

This ADR documents the decision to use a **hybrid storage architecture** combining **PostgreSQL for relational data** and **Prometheus for time-series metrics**, with **S3 for archival storage**.

### Key Decisions

1. **PostgreSQL** as primary storage for flow items and detailed event data
1. **Prometheus** for real-time time-series metrics and alerting
1. **S3** for cost-effective long-term archival
1. **Materialized views** for dashboard query performance
1. **Partitioning** for webhook_events table
1. **90-day retention** in hot storage, 1-year in warm, 3+ years in cold

### Trade-offs Accepted

- Operational complexity of managing two storage systems (PostgreSQL + Prometheus)
- Manual coordination needed between systems (no automatic sync)
- Prometheus retention limited (15 days) - acceptable for MVP

### Future Considerations

- **TimescaleDB** if consolidation desired
- **ClickHouse** if scale reaches 100M+ flow items
- **Thanos** if Prometheus retention becomes issue
- **Aurora PostgreSQL** if RDS scaling limits reached

### Success Metrics

- Query latency P95 < 500ms ✅
- Write throughput > 100 events/sec ✅
- Monthly cost < $500 (optimized) ✅
- Data retention 90 days (hot) ✅

This architecture provides a solid foundation for Value Stream Management in Fawkes while maintaining operational simplicity and cost-effectiveness for the MVP phase.

---

**Status**: Proposed → **Accepted** (pending implementation)

**Next Steps**:

1. Review with platform architecture team
1. Validate cost estimates with finance
1. Begin Week 1 implementation tasks
1. Schedule architecture review after 30 days

**Related ADRs**:

- ADR-006: PostgreSQL for Data Persistence
- ADR-027: Value Stream Management Integration
- ADR-030: Real-Time vs Batch Processing (to be created)

**Last Updated**: 2025-01-15​​​​​​​​​​​​​​​​
