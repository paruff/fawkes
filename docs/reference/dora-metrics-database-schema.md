---
title: DORA Metrics Database Schema
description: MySQL database schema for DevLake DORA metrics storage
---

# DORA Metrics Database Schema

## Overview

The DORA Metrics Service uses MySQL 8.0 as its primary data store. DevLake creates and manages multiple tables to store raw data from various sources and calculated DORA metrics.

**Database Name**: `lake`
**Character Set**: UTF-8 (utf8mb4)
**Engine**: InnoDB
**Managed By**: DevLake automatic migrations

---

## Schema Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Raw Data Layer                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │  _raw_github_   │  │  _raw_jenkins_  │  │  _raw_argocd_   │    │
│  │  repos          │  │  builds         │  │  applications   │    │
│  │  commits        │  │  jobs           │  │  syncs          │    │
│  │  pull_requests  │  │  test_results   │  │  app_status     │    │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘    │
│           │                    │                     │              │
└───────────┼────────────────────┼─────────────────────┼──────────────┘
            │                    │                     │
            ▼                    ▼                     ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Domain Model Layer                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │  commits        │  │  builds         │  │  deployments    │    │
│  │  pull_requests  │  │  pipelines      │  │  incidents      │    │
│  │  repos          │  │  test_results   │  │  cicd_scopes    │    │
│  └────────┬────────┘  └────────┬────────┘  └────────┬────────┘    │
│           │                    │                     │              │
└───────────┼────────────────────┼─────────────────────┼──────────────┘
            │                    │                     │
            └────────────────────┴─────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────┐
│                       DORA Metrics Layer                             │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  dora_metrics                                                │   │
│  │  - deployment_frequency                                      │   │
│  │  - lead_time_for_changes                                     │   │
│  │  - change_failure_rate                                       │   │
│  │  - mean_time_to_restore                                      │   │
│  │  - operational_performance                                   │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Core Tables

### 1. `deployments` Table

Stores deployment events from ArgoCD (primary source) and Jenkins.

```sql
CREATE TABLE `deployments` (
  `id` varchar(255) NOT NULL PRIMARY KEY,
  `cicd_scope_id` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `result` varchar(100) DEFAULT NULL,
  `status` varchar(100) DEFAULT NULL,
  `original_status` varchar(100) DEFAULT NULL,
  `environment` varchar(255) DEFAULT NULL,
  `created_date` datetime(3) DEFAULT NULL,
  `started_date` datetime(3) DEFAULT NULL,
  `finished_date` datetime(3) DEFAULT NULL,
  `duration_sec` bigint DEFAULT NULL,
  `commit_sha` varchar(255) DEFAULT NULL,
  `ref_name` varchar(255) DEFAULT NULL,
  `repo_id` varchar(255) DEFAULT NULL,
  `repo_url` varchar(255) DEFAULT NULL,
  `prev_success_deployment_commit_id` varchar(255) DEFAULT NULL,
  `display_title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  INDEX idx_cicd_scope_id (cicd_scope_id),
  INDEX idx_commit_sha (commit_sha),
  INDEX idx_finished_date (finished_date),
  INDEX idx_environment (environment),
  INDEX idx_result (result)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Key Fields**:
- `id`: Unique deployment identifier (ArgoCD sync ID or Jenkins build ID)
- `cicd_scope_id`: Links to the project/service scope
- `result`: Deployment result (`SUCCESS`, `FAILURE`, `ABORTED`)
- `environment`: Target environment (`production`, `staging`, `dev`)
- `finished_date`: Deployment completion timestamp (for frequency calculation)
- `commit_sha`: Git commit SHA deployed
- `duration_sec`: Deployment duration in seconds

**Usage**:
- **Deployment Frequency**: Count of successful deployments per time window
- **Lead Time**: Join with `commits` table to calculate commit → deploy time
- **Change Failure Rate**: Ratio of failed to total deployments

---

### 2. `commits` Table

Stores Git commit data from GitHub.

```sql
CREATE TABLE `commits` (
  `sha` varchar(255) NOT NULL PRIMARY KEY,
  `additions` int DEFAULT NULL,
  `deletions` int DEFAULT NULL,
  `dev_eq` int DEFAULT NULL,
  `message` mediumtext,
  `author_name` varchar(255) DEFAULT NULL,
  `author_email` varchar(255) DEFAULT NULL,
  `authored_date` datetime(3) DEFAULT NULL,
  `author_id` varchar(255) DEFAULT NULL,
  `committer_name` varchar(255) DEFAULT NULL,
  `committer_email` varchar(255) DEFAULT NULL,
  `committed_date` datetime(3) DEFAULT NULL,
  `committer_id` varchar(255) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  INDEX idx_authored_date (authored_date),
  INDEX idx_author_id (author_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Key Fields**:
- `sha`: Commit SHA (primary key)
- `authored_date`: When the commit was created
- `message`: Commit message
- `author_name`: Commit author
- `additions`/`deletions`: Lines of code changed

**Usage**:
- **Lead Time**: Start time for lead time calculation
- **Code churn**: Track code changes over time

---

### 3. `incidents` Table

Stores production incidents for CFR and MTTR calculation.

```sql
CREATE TABLE `incidents` (
  `id` varchar(255) NOT NULL PRIMARY KEY,
  `issue_id` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `number` varchar(255) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `description` mediumtext,
  `priority` varchar(255) DEFAULT NULL,
  `severity` varchar(255) DEFAULT NULL,
  `type` varchar(100) DEFAULT NULL,
  `status` varchar(100) DEFAULT NULL,
  `original_status` varchar(100) DEFAULT NULL,
  `created_date` datetime(3) DEFAULT NULL,
  `updated_date` datetime(3) DEFAULT NULL,
  `closed_date` datetime(3) DEFAULT NULL,
  `lead_time_minutes` bigint DEFAULT NULL,
  `resolution_date` datetime(3) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  INDEX idx_created_date (created_date),
  INDEX idx_resolution_date (resolution_date),
  INDEX idx_severity (severity),
  INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Key Fields**:
- `id`: Incident unique identifier
- `severity`: Incident severity (`high`, `medium`, `low`)
- `created_date`: Incident detection time
- `resolution_date`: Incident resolution time
- `lead_time_minutes`: Time to restore (calculated)

**Usage**:
- **Change Failure Rate**: Count of incidents caused by deployments
- **Mean Time to Restore**: Average time from incident creation to resolution

---

### 4. `cicd_deployments` Table

Links deployments to CICD pipelines and commits.

```sql
CREATE TABLE `cicd_deployments` (
  `id` varchar(255) NOT NULL PRIMARY KEY,
  `cicd_scope_id` varchar(255) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  `result` varchar(100) DEFAULT NULL,
  `status` varchar(100) DEFAULT NULL,
  `environment` varchar(255) DEFAULT NULL,
  `created_date` datetime(3) DEFAULT NULL,
  `started_date` datetime(3) DEFAULT NULL,
  `finished_date` datetime(3) DEFAULT NULL,
  `duration_sec` bigint DEFAULT NULL,
  `queued_duration_sec` bigint DEFAULT NULL,
  `commit_sha` varchar(255) DEFAULT NULL,
  `ref_name` varchar(255) DEFAULT NULL,
  `repo_id` varchar(255) DEFAULT NULL,
  `display_title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  INDEX idx_cicd_scope_id (cicd_scope_id),
  INDEX idx_commit_sha (commit_sha),
  INDEX idx_environment (environment),
  INDEX idx_finished_date (finished_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Key Fields**:
- `cicd_scope_id`: Project/service scope identifier
- `commit_sha`: Links deployment to commit
- `environment`: Deployment target environment
- `finished_date`: Deployment completion time

**Usage**:
- Links ArgoCD syncs to commits for lead time calculation

---

### 5. `project_metric_settings` Table

Stores DORA metric configuration per project.

```sql
CREATE TABLE `project_metric_settings` (
  `id` bigint AUTO_INCREMENT PRIMARY KEY,
  `project_name` varchar(255) NOT NULL,
  `plugin_name` varchar(255) NOT NULL,
  `plugin_option` text,
  `enable` tinyint(1) DEFAULT 1,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  UNIQUE KEY uk_project_plugin (project_name, plugin_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Key Fields**:
- `project_name`: Project identifier
- `plugin_name`: Metric type (e.g., `dora`)
- `plugin_option`: JSON configuration for the metric
- `enable`: Whether metric is enabled

**Example plugin_option**:

```json
{
  "deployment_frequency": {
    "window_days": 7,
    "environment": "production"
  },
  "lead_time": {
    "stages": ["development", "review", "production"]
  },
  "cfr": {
    "window_days": 30
  }
}
```

---

### 6. `dora_benchmarks` Table

Stores DORA performance benchmarks for comparison.

```sql
CREATE TABLE `dora_benchmarks` (
  `id` bigint AUTO_INCREMENT PRIMARY KEY,
  `metric_name` varchar(100) NOT NULL,
  `performance_level` varchar(50) NOT NULL,
  `min_value` decimal(10,2) DEFAULT NULL,
  `max_value` decimal(10,2) DEFAULT NULL,
  `unit` varchar(50) DEFAULT NULL,
  `description` text,
  `created_at` datetime(3) DEFAULT NULL,
  `updated_at` datetime(3) DEFAULT NULL,
  UNIQUE KEY uk_metric_level (metric_name, performance_level)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

**Example Data**:

```sql
INSERT INTO dora_benchmarks (metric_name, performance_level, min_value, max_value, unit, description) VALUES
('deployment_frequency', 'elite', 0, NULL, 'per_day', 'Multiple deploys per day'),
('deployment_frequency', 'high', 1, 7, 'per_week', 'Between once per day and once per week'),
('lead_time', 'elite', 0, 60, 'minutes', 'Less than one hour'),
('lead_time', 'high', 60, 10080, 'minutes', 'Less than one week'),
('change_failure_rate', 'elite', 0, 15, 'percent', '0-15%'),
('change_failure_rate', 'high', 16, 30, 'percent', '16-30%'),
('mttr', 'elite', 0, 60, 'minutes', 'Less than one hour'),
('mttr', 'high', 60, 1440, 'minutes', 'Less than one day');
```

---

## Calculated Metrics Views

DevLake creates views for pre-calculated DORA metrics.

### `v_dora_deployment_frequency`

```sql
CREATE VIEW v_dora_deployment_frequency AS
SELECT
    cicd_scope_id AS project_id,
    environment,
    DATE(finished_date) AS deployment_date,
    COUNT(*) AS deployment_count,
    COUNT(*) / 1.0 AS deployments_per_day
FROM deployments
WHERE
    result = 'SUCCESS'
    AND environment = 'production'
    AND finished_date IS NOT NULL
GROUP BY cicd_scope_id, environment, DATE(finished_date);
```

### `v_dora_lead_time`

```sql
CREATE VIEW v_dora_lead_time AS
SELECT
    d.cicd_scope_id AS project_id,
    d.id AS deployment_id,
    d.commit_sha,
    c.authored_date AS commit_date,
    d.finished_date AS deployment_date,
    TIMESTAMPDIFF(SECOND, c.authored_date, d.finished_date) AS lead_time_seconds,
    TIMESTAMPDIFF(MINUTE, c.authored_date, d.finished_date) AS lead_time_minutes
FROM deployments d
JOIN commits c ON d.commit_sha = c.sha
WHERE d.result = 'SUCCESS' AND d.environment = 'production';
```

### `v_dora_cfr`

```sql
CREATE VIEW v_dora_cfr AS
SELECT
    cicd_scope_id AS project_id,
    COUNT(*) AS total_deployments,
    SUM(CASE WHEN result = 'FAILURE' THEN 1 ELSE 0 END) AS failed_deployments,
    (SUM(CASE WHEN result = 'FAILURE' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)) AS failure_rate_percent
FROM deployments
WHERE environment = 'production'
GROUP BY cicd_scope_id;
```

### `v_dora_mttr`

```sql
CREATE VIEW v_dora_mttr AS
SELECT
    i.id AS incident_id,
    i.severity,
    i.created_date AS incident_created,
    i.resolution_date AS incident_resolved,
    TIMESTAMPDIFF(MINUTE, i.created_date, i.resolution_date) AS mttr_minutes
FROM incidents i
WHERE i.resolution_date IS NOT NULL
    AND i.severity IN ('high', 'medium');
```

---

## Indexes

Performance indexes for common DORA metric queries:

```sql
-- Deployment frequency queries
CREATE INDEX idx_deployments_frequency
ON deployments(cicd_scope_id, environment, result, finished_date);

-- Lead time queries
CREATE INDEX idx_deployments_leadtime
ON deployments(commit_sha, finished_date);

-- CFR queries
CREATE INDEX idx_deployments_cfr
ON deployments(cicd_scope_id, environment, result);

-- MTTR queries
CREATE INDEX idx_incidents_mttr
ON incidents(severity, created_date, resolution_date);
```

---

## Data Retention

Data retention policies for DORA metrics:

| Table | Retention Period | Cleanup Policy |
|-------|------------------|----------------|
| `deployments` | 2 years | Archive after 1 year |
| `commits` | Indefinite | Never deleted |
| `incidents` | 2 years | Archive after 1 year |
| `_raw_*` tables | 90 days | Purged after processing |
| Aggregated metrics | Indefinite | Rolled up to daily/monthly |

---

## Backup and Recovery

### Automated Backups

```bash
# Daily backup script (runs at 02:00 UTC)
#!/bin/bash
BACKUP_DIR=/backup/devlake
DATE=$(date +%Y%m%d)

kubectl exec -n fawkes devlake-mysql-0 -- \
  mysqldump -u root -p${MYSQL_ROOT_PASSWORD} lake \
  > ${BACKUP_DIR}/devlake-${DATE}.sql

# Compress backup
gzip ${BACKUP_DIR}/devlake-${DATE}.sql

# Upload to S3
aws s3 cp ${BACKUP_DIR}/devlake-${DATE}.sql.gz \
  s3://fawkes-backups/devlake/
```

### Restore from Backup

```bash
# Download backup
aws s3 cp s3://fawkes-backups/devlake/devlake-20241215.sql.gz .
gunzip devlake-20241215.sql.gz

# Restore database
kubectl exec -i -n fawkes devlake-mysql-0 -- \
  mysql -u root -p${MYSQL_ROOT_PASSWORD} lake \
  < devlake-20241215.sql
```

---

## Schema Migrations

DevLake handles schema migrations automatically using Flyway.

Migration files are located in the DevLake container:

```
/app/migrations/
├── V1__init_schema.sql
├── V2__add_deployments_table.sql
├── V3__add_incidents_table.sql
├── V4__add_dora_views.sql
└── V5__add_indexes.sql
```

### Manual Migration

To manually run migrations:

```bash
kubectl exec -it -n fawkes devlake-0 -- /app/devlake migrate
```

---

## Monitoring Database Health

### Check Table Sizes

```sql
SELECT
    table_name,
    ROUND(((data_length + index_length) / 1024 / 1024), 2) AS size_mb
FROM information_schema.TABLES
WHERE table_schema = 'lake'
ORDER BY size_mb DESC;
```

### Check Index Usage

```sql
SELECT
    table_schema,
    table_name,
    index_name,
    cardinality
FROM information_schema.STATISTICS
WHERE table_schema = 'lake'
ORDER BY cardinality DESC;
```

### Query Performance

```sql
-- Enable slow query log
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;

-- View slow queries
SELECT * FROM mysql.slow_log
ORDER BY query_time DESC
LIMIT 10;
```

---

## Related Documentation

- [DORA Metrics API Reference](dora-metrics-api.md)
- [View DORA Metrics in DevLake](../how-to/observability/view-dora-metrics-devlake.md)
- [Architecture: DORA Metrics Service](../architecture.md#6-dora-metrics-service)
- [ADR-016: DevLake DORA Strategy](../adr/ADR-016%20devlake-dora-strategy.md)
