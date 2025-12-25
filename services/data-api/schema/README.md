# Hasura GraphQL Schema Configuration

This directory contains Hasura metadata and schema configurations for exposing platform data via GraphQL.

## Overview

Hasura automatically generates a GraphQL schema from PostgreSQL databases. This directory contains:

- **Tables**: Configurations for tracked tables
- **Relationships**: Foreign key and manual relationships between tables
- **Views**: Custom views for common query patterns
- **Custom Functions**: PostgreSQL functions exposed as GraphQL queries

## Directory Structure

```
services/data-api/schema/
├── README.md                    # This file
├── metadata/                    # Hasura metadata exports
│   ├── databases.yaml          # Database connection configs
│   ├── tables.yaml             # Table tracking and permissions
│   ├── relationships.yaml      # Entity relationships
│   └── custom_functions.yaml  # Custom SQL functions
├── views/                      # SQL views for common queries
│   ├── dora_metrics_view.sql
│   ├── catalog_summary_view.sql
│   └── vsm_flow_metrics_view.sql
└── migrations/                 # Database migrations (if needed)
```

## Data Sources

### 1. VSM Database (db-vsm-dev)

Tables to track:
- `work_items` - Work items (features, bugs, tasks)
- `stages` - Value stream stages
- `stage_transitions` - Work item transitions between stages
- `flow_metrics` - Aggregated flow metrics

### 2. Backstage Database (db-backstage-dev)

Tables to track:
- `catalog_entities` - Software catalog entities (components, systems, APIs)
- `catalog_entity_metadata` - Entity metadata and annotations
- `techdocs` - TechDocs documentation

### 3. DevLake Database

Tables to track:
- `deployments` - Deployment events
- `builds` - CI/CD build data
- `pull_requests` - PR metrics
- `dora_metrics` - Aggregated DORA metrics

## Schema Management

### Exporting Metadata

To export current Hasura metadata:

```bash
# Export all metadata
hasura metadata export --endpoint http://hasura.local --admin-secret <secret>

# This creates metadata files in hasura/metadata/
```

### Applying Metadata

To apply metadata configuration:

```bash
# Apply metadata
hasura metadata apply --endpoint http://hasura.local --admin-secret <secret>

# Or reload to pick up changes
hasura metadata reload --endpoint http://hasura.local --admin-secret <secret>
```

### Tracking Tables

Track tables via CLI:

```bash
# Track a single table
hasura metadata apply --endpoint http://hasura.local --admin-secret <secret> \
  --database vsm \
  --table work_items

# Or use the console at http://hasura.local/console
```

## Common Queries

### Example GraphQL Queries

#### DORA Metrics
```graphql
query GetDORAMetrics {
  doraMetrics(
    where: { date: { _gte: "2024-01-01" } }
    order_by: { date: desc }
    limit: 30
  ) {
    date
    deploymentFrequency
    leadTimeForChanges
    timeToRestoreService
    changeFailureRate
  }
}
```

#### Backstage Catalog
```graphql
query GetComponents {
  catalogEntities(
    where: { kind: { _eq: "Component" } }
  ) {
    id
    name
    kind
    spec
    metadata
  }
}
```

#### VSM Work Items
```graphql
query GetWorkItems {
  workItems(
    where: { status: { _neq: "done" } }
    order_by: { createdAt: desc }
  ) {
    id
    title
    type
    status
    currentStage {
      name
      type
    }
    transitions {
      fromStage
      toStage
      timestamp
    }
  }
}
```

#### Flow Metrics
```graphql
query GetFlowMetrics {
  flowMetrics(
    order_by: { date: desc }
    limit: 7
  ) {
    date
    wipByStage
    throughput
    averageCycleTime
    averageLeadTime
  }
}
```

## Relationships

### VSM Relationships

```yaml
# work_items -> stages (current_stage)
object_relationship:
  name: currentStage
  using:
    foreign_key_constraint_on: stage_id

# work_items -> stage_transitions (transitions)
array_relationship:
  name: transitions
  using:
    foreign_key_constraint_on:
      column: work_item_id
      table: stage_transitions
```

### Cross-Database Relationships

Hasura supports relationships across databases:

```yaml
# Example: VSM work_item -> Backstage component
remote_relationship:
  name: component
  definition:
    to_source:
      source: backstage
      table: catalog_entities
      relationship_type: object
      field_mapping:
        component_id: id
```

## Views

### DORA Metrics Summary View

Create aggregated view for common DORA queries:

```sql
CREATE VIEW dora_metrics_summary AS
SELECT
  DATE_TRUNC('week', date) as week,
  AVG(deployment_frequency) as avg_deployment_frequency,
  AVG(lead_time_for_changes) as avg_lead_time,
  AVG(time_to_restore_service) as avg_mttr,
  AVG(change_failure_rate) as avg_change_failure_rate,
  COUNT(*) as days_in_week
FROM dora_metrics
GROUP BY DATE_TRUNC('week', date)
ORDER BY week DESC;
```

### Catalog Summary View

```sql
CREATE VIEW catalog_summary AS
SELECT
  kind,
  COUNT(*) as count,
  COUNT(DISTINCT spec->>'owner') as unique_owners,
  COUNT(CASE WHEN metadata->>'lifecycle' = 'production' THEN 1 END) as production_count
FROM catalog_entities
GROUP BY kind;
```

### VSM Flow Metrics View

```sql
CREATE VIEW vsm_flow_metrics AS
SELECT
  DATE_TRUNC('day', timestamp) as date,
  stage_id,
  COUNT(DISTINCT work_item_id) as items_transitioned,
  AVG(EXTRACT(EPOCH FROM (timestamp - lag(timestamp) OVER (PARTITION BY work_item_id ORDER BY timestamp)))) as avg_stage_time
FROM stage_transitions
GROUP BY DATE_TRUNC('day', timestamp), stage_id
ORDER BY date DESC;
```

## Custom Functions

Expose PostgreSQL functions as GraphQL queries:

```sql
-- Function to calculate cycle time for a work item
CREATE OR REPLACE FUNCTION calculate_cycle_time(item_id UUID)
RETURNS INTERVAL AS $$
  SELECT
    MAX(timestamp) - MIN(timestamp)
  FROM stage_transitions
  WHERE work_item_id = item_id
    AND to_stage IN (SELECT id FROM stages WHERE type = 'done');
$$ LANGUAGE SQL STABLE;
```

Track in Hasura:
```yaml
- function:
    schema: public
    name: calculate_cycle_time
  configuration:
    custom_name: calculateCycleTime
```

## Performance Optimization

### Indexes

Ensure critical indexes exist:

```sql
-- VSM indexes
CREATE INDEX idx_work_items_status ON work_items(status);
CREATE INDEX idx_stage_transitions_work_item ON stage_transitions(work_item_id);
CREATE INDEX idx_stage_transitions_timestamp ON stage_transitions(timestamp);

-- Backstage indexes
CREATE INDEX idx_catalog_entities_kind ON catalog_entities(kind);
CREATE INDEX idx_catalog_entities_owner ON catalog_entities((spec->>'owner'));

-- DORA indexes
CREATE INDEX idx_dora_metrics_date ON dora_metrics(date DESC);
```

### Query Limits

Configure query limits in Hasura:

```yaml
api_limits:
  depth_limit:
    global: 10
    per_role:
      admin: 20
      developer: 10
      viewer: 5

  node_limit:
    global: 100
    per_role:
      admin: 1000
      developer: 500
      viewer: 100

  rate_limit:
    global:
      max_req_per_min: 1000
      unique_params: IP
    per_role:
      admin:
        max_req_per_min: 10000
      developer:
        max_req_per_min: 1000
      viewer:
        max_req_per_min: 100
```

## Testing

### Schema Validation

```bash
# Validate metadata
hasura metadata validate --endpoint http://hasura.local --admin-secret <secret>

# Check for inconsistencies
hasura metadata inconsistency list --endpoint http://hasura.local --admin-secret <secret>
```

### Query Testing

Use GraphQL Playground at http://hasura.local/console to test queries interactively.

## Maintenance

### Metadata Backup

```bash
# Export and backup metadata regularly
hasura metadata export --endpoint http://hasura.local --admin-secret <secret>
cp -r metadata/ metadata.backup.$(date +%Y%m%d)
```

### Schema Updates

When database schema changes:

1. Update the database schema (migrations)
2. Reload metadata: `hasura metadata reload`
3. Update relationships and permissions if needed
4. Test queries in GraphQL Playground
5. Export updated metadata: `hasura metadata export`
6. Commit to Git

## References

- [Hasura Metadata Format](https://hasura.io/docs/latest/migrations-metadata-seeds/metadata-format/)
- [GraphQL Schema Design](https://hasura.io/docs/latest/schema/postgres/)
- [Relationships](https://hasura.io/docs/latest/schema/postgres/table-relationships/)
- [Custom Functions](https://hasura.io/docs/latest/schema/postgres/custom-functions/)
