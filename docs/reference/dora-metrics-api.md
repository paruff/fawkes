---
title: DORA Metrics API Reference
description: API endpoints for querying DORA metrics from DevLake service
---

# DORA Metrics API Reference

## Overview

The DORA Metrics Service (powered by Apache DevLake) exposes REST and GraphQL APIs for querying the five DORA metrics (four key metrics plus operational performance).

**Base URL**: `http://devlake.127.0.0.1.nip.io/api` (local)  
**Production URL**: `https://devlake.fawkes.idp/api`  
**Authentication**: Bearer token (see [Authentication](#authentication))

---

## Authentication

All API requests require a valid bearer token:

```bash
export DEVLAKE_TOKEN="your-api-token"
curl -H "Authorization: Bearer $DEVLAKE_TOKEN" \
  http://devlake.127.0.0.1.nip.io/api/dora/metrics
```

To obtain a token:

```bash
# Get token from Kubernetes secret
kubectl get secret -n fawkes devlake-api-token \
  -o jsonpath='{.data.token}' | base64 -d
```

---

## REST API Endpoints

### 1. Get All DORA Metrics

Returns all five DORA metrics for a project.

**Endpoint**: `GET /api/dora/metrics`

**Query Parameters**:
- `project` (required): Project name or service name
- `timeRange` (optional): Time range for metrics (default: `last30days`)
  - Values: `last7days`, `last30days`, `last90days`, `custom`
- `startDate` (optional): Start date for custom range (ISO 8601)
- `endDate` (optional): End date for custom range (ISO 8601)

**Example Request**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/metrics?project=payment-service&timeRange=last30days" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Example Response**:

```json
{
  "project": "payment-service",
  "timeRange": {
    "start": "2024-11-15T00:00:00Z",
    "end": "2024-12-15T23:59:59Z"
  },
  "metrics": {
    "deploymentFrequency": {
      "value": 2.4,
      "unit": "per_day",
      "level": "elite",
      "description": "Multiple deploys per day"
    },
    "leadTimeForChanges": {
      "value": 45,
      "unit": "minutes",
      "level": "elite",
      "p50": 32,
      "p95": 85,
      "description": "Less than one hour"
    },
    "changeFailureRate": {
      "value": 8.5,
      "unit": "percent",
      "level": "elite",
      "total_deployments": 72,
      "failed_deployments": 6,
      "description": "0-15% failure rate"
    },
    "meanTimeToRestore": {
      "value": 28,
      "unit": "minutes",
      "level": "elite",
      "p50": 18,
      "p95": 65,
      "description": "Less than one hour"
    },
    "operationalPerformance": {
      "value": 99.95,
      "unit": "percent",
      "sloTarget": 99.9,
      "p99Latency": 285,
      "errorRate": 0.05,
      "description": "SLO adherence and reliability"
    }
  }
}
```

### 2. Get Deployment Frequency

Returns deployment frequency metric only.

**Endpoint**: `GET /api/dora/deployment-frequency`

**Query Parameters**:
- `project` (required): Project name
- `timeRange` (optional): Time range (default: `last7days`)
- `groupBy` (optional): Group results by `day`, `week`, or `month`

**Example Request**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/deployment-frequency?project=payment-service&groupBy=day" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Example Response**:

```json
{
  "project": "payment-service",
  "metric": "deployment_frequency",
  "summary": {
    "value": 2.4,
    "unit": "per_day",
    "level": "elite"
  },
  "timeseries": [
    {"date": "2024-12-08", "deployments": 3},
    {"date": "2024-12-09", "deployments": 2},
    {"date": "2024-12-10", "deployments": 4},
    {"date": "2024-12-11", "deployments": 1},
    {"date": "2024-12-12", "deployments": 3},
    {"date": "2024-12-13", "deployments": 2},
    {"date": "2024-12-14", "deployments": 2}
  ]
}
```

### 3. Get Lead Time for Changes

Returns lead time metric with breakdown by stage.

**Endpoint**: `GET /api/dora/lead-time`

**Query Parameters**:
- `project` (required): Project name
- `timeRange` (optional): Time range
- `includeStages` (optional): Include stage breakdown (default: `false`)

**Example Request**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/lead-time?project=payment-service&includeStages=true" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Example Response**:

```json
{
  "project": "payment-service",
  "metric": "lead_time_for_changes",
  "summary": {
    "value": 45,
    "unit": "minutes",
    "level": "elite",
    "p50": 32,
    "p95": 85
  },
  "stages": [
    {
      "name": "commit_to_build",
      "duration": 8,
      "unit": "minutes"
    },
    {
      "name": "build_to_test",
      "duration": 12,
      "unit": "minutes"
    },
    {
      "name": "test_to_deploy",
      "duration": 15,
      "unit": "minutes"
    },
    {
      "name": "deploy_to_verify",
      "duration": 10,
      "unit": "minutes"
    }
  ]
}
```

### 4. Get Change Failure Rate

Returns change failure rate with details on failures.

**Endpoint**: `GET /api/dora/change-failure-rate`

**Query Parameters**:
- `project` (required): Project name
- `timeRange` (optional): Time range

**Example Request**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/change-failure-rate?project=payment-service" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Example Response**:

```json
{
  "project": "payment-service",
  "metric": "change_failure_rate",
  "summary": {
    "value": 8.5,
    "unit": "percent",
    "level": "elite",
    "total_deployments": 72,
    "failed_deployments": 6,
    "successful_deployments": 66
  },
  "failures": [
    {
      "deployment_id": "argocd-sync-12345",
      "timestamp": "2024-12-10T14:30:00Z",
      "reason": "Database migration error",
      "severity": "high",
      "resolved_at": "2024-12-10T15:15:00Z",
      "mttr_minutes": 45
    }
  ]
}
```

### 5. Get Mean Time to Restore

Returns MTTR with incident details.

**Endpoint**: `GET /api/dora/mttr`

**Query Parameters**:
- `project` (required): Project name
- `timeRange` (optional): Time range
- `severity` (optional): Filter by severity (`high`, `medium`, `low`)

**Example Request**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/mttr?project=payment-service&severity=high" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Example Response**:

```json
{
  "project": "payment-service",
  "metric": "mean_time_to_restore",
  "summary": {
    "value": 28,
    "unit": "minutes",
    "level": "elite",
    "p50": 18,
    "p95": 65,
    "total_incidents": 6,
    "avg_severity": "medium"
  },
  "incidents": [
    {
      "id": "incident-001",
      "created_at": "2024-12-10T14:30:00Z",
      "resolved_at": "2024-12-10T15:15:00Z",
      "duration_minutes": 45,
      "severity": "high",
      "title": "Database connection timeout"
    }
  ]
}
```

### 6. Get CI/Rework Metrics

Returns Jenkins CI metrics including rework rate.

**Endpoint**: `GET /api/dora/rework`

**Query Parameters**:
- `project` (required): Project name
- `timeRange` (optional): Time range

**Example Request**:

```bash
curl -X GET "http://devlake.127.0.0.1.nip.io/api/dora/rework?project=payment-service" \
  -H "Authorization: Bearer $DEVLAKE_TOKEN"
```

**Example Response**:

```json
{
  "project": "payment-service",
  "metric": "ci_rework_metrics",
  "summary": {
    "build_success_rate": 92.5,
    "rework_rate": 10.0,
    "quality_gate_pass_rate": 88.0,
    "test_flakiness": 2.5,
    "avg_build_duration_minutes": 6.5
  },
  "details": {
    "total_builds": 150,
    "successful_builds": 139,
    "failed_builds": 11,
    "retry_builds": 15,
    "quality_gate_failures": 18
  }
}
```

---

## GraphQL API

The GraphQL API provides flexible querying with nested relationships.

**Endpoint**: `POST /api/graphql`

### Schema Overview

```graphql
type Query {
  doraMetrics(project: String!, timeRange: TimeRange): DORAMetrics
  projects: [Project!]!
  deployments(project: String!, timeRange: TimeRange): [Deployment!]!
  incidents(project: String!, timeRange: TimeRange): [Incident!]!
}

type DORAMetrics {
  project: String!
  deploymentFrequency: DeploymentFrequency
  leadTimeForChanges: LeadTime
  changeFailureRate: ChangeFailureRate
  meanTimeToRestore: MTTR
  operationalPerformance: OperationalPerformance
}

type DeploymentFrequency {
  value: Float!
  unit: String!
  level: String!
  timeseries: [TimeseriesDataPoint!]!
}
```

### Example GraphQL Query

```graphql
query GetDORAMetrics {
  doraMetrics(project: "payment-service", timeRange: LAST_30_DAYS) {
    project
    deploymentFrequency {
      value
      unit
      level
      timeseries {
        date
        count
      }
    }
    leadTimeForChanges {
      value
      unit
      level
      p50
      p95
      stages {
        name
        duration
      }
    }
    changeFailureRate {
      value
      level
      totalDeployments
      failedDeployments
    }
    meanTimeToRestore {
      value
      unit
      level
      p50
      p95
    }
  }
}
```

**Example Request**:

```bash
curl -X POST http://devlake.127.0.0.1.nip.io/api/graphql \
  -H "Authorization: Bearer $DEVLAKE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query GetDORAMetrics { doraMetrics(project: \"payment-service\", timeRange: LAST_30_DAYS) { deploymentFrequency { value unit level } } }"
  }'
```

---

## Prometheus Metrics

DevLake exposes Prometheus metrics at `/metrics` endpoint.

### Available Metrics

```prometheus
# HELP dora_deployment_frequency_total Total number of deployments
# TYPE dora_deployment_frequency_total counter
dora_deployment_frequency_total{project="payment-service",environment="production"} 72

# HELP dora_lead_time_seconds Lead time for changes in seconds
# TYPE dora_lead_time_seconds histogram
dora_lead_time_seconds_bucket{project="payment-service",le="3600"} 65
dora_lead_time_seconds_bucket{project="payment-service",le="86400"} 70
dora_lead_time_seconds_bucket{project="payment-service",le="+Inf"} 72
dora_lead_time_seconds_sum{project="payment-service"} 194400
dora_lead_time_seconds_count{project="payment-service"} 72

# HELP dora_change_failure_rate Percentage of failed deployments
# TYPE dora_change_failure_rate gauge
dora_change_failure_rate{project="payment-service"} 0.085

# HELP dora_mttr_seconds Mean time to restore in seconds
# TYPE dora_mttr_seconds histogram
dora_mttr_seconds_bucket{project="payment-service",le="3600"} 5
dora_mttr_seconds_bucket{project="payment-service",le="86400"} 6
dora_mttr_seconds_bucket{project="payment-service",le="+Inf"} 6
dora_mttr_seconds_sum{project="payment-service"} 10080
dora_mttr_seconds_count{project="payment-service"} 6
```

### Example PromQL Queries

```promql
# Average deployment frequency per day (last 7 days)
rate(dora_deployment_frequency_total[7d]) * 86400

# P95 lead time in minutes
histogram_quantile(0.95, dora_lead_time_seconds_bucket) / 60

# Current change failure rate
dora_change_failure_rate

# P95 MTTR in minutes
histogram_quantile(0.95, dora_mttr_seconds_bucket) / 60
```

---

## Error Responses

All API endpoints return consistent error responses:

```json
{
  "error": {
    "code": "INVALID_PROJECT",
    "message": "Project 'invalid-service' not found",
    "details": {
      "available_projects": ["payment-service", "user-service", "api-gateway"]
    }
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_PROJECT` | 404 | Project not found |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `INVALID_TIME_RANGE` | 400 | Invalid time range specified |
| `NO_DATA` | 404 | No data available for time range |
| `INTERNAL_ERROR` | 500 | Server error |

---

## Rate Limiting

API requests are rate-limited to prevent abuse:

- **Anonymous requests**: 60 requests per hour
- **Authenticated requests**: 5000 requests per hour

Rate limit headers are included in all responses:

```
X-RateLimit-Limit: 5000
X-RateLimit-Remaining: 4999
X-RateLimit-Reset: 1702828800
```

---

## Webhooks

DevLake accepts webhook events for real-time metrics updates.

### Deployment Event Webhook

**Endpoint**: `POST /api/plugins/webhook/1/deployments`

**Payload**:

```json
{
  "project": "payment-service",
  "commit_sha": "abc123def456",
  "deployment_id": "argocd-sync-12345",
  "status": "success",
  "environment": "production",
  "timestamp": "2024-12-15T10:30:00Z",
  "duration_seconds": 120
}
```

### Incident Event Webhook

**Endpoint**: `POST /api/plugins/webhook/1/incidents`

**Payload**:

```json
{
  "id": "incident-001",
  "title": "Database connection timeout",
  "service": "payment-service",
  "severity": "high",
  "status": "open",
  "createdDate": "2024-12-15T14:30:00Z",
  "resolvedDate": null,
  "environment": "production"
}
```

---

## SDK and Libraries

### Python SDK

```python
from devlake import DevLakeClient

client = DevLakeClient(
    base_url="http://devlake.127.0.0.1.nip.io/api",
    token="your-api-token"
)

# Get DORA metrics
metrics = client.get_dora_metrics(
    project="payment-service",
    time_range="last30days"
)

print(f"Deployment Frequency: {metrics.deployment_frequency.value} {metrics.deployment_frequency.unit}")
print(f"Lead Time: {metrics.lead_time.value} {metrics.lead_time.unit}")
```

### JavaScript SDK

```javascript
import { DevLakeClient } from '@devlake/sdk';

const client = new DevLakeClient({
  baseURL: 'http://devlake.127.0.0.1.nip.io/api',
  token: 'your-api-token'
});

// Get DORA metrics
const metrics = await client.getDoraMetrics({
  project: 'payment-service',
  timeRange: 'last30days'
});

console.log(`Deployment Frequency: ${metrics.deploymentFrequency.value} ${metrics.deploymentFrequency.unit}`);
```

---

## Related Documentation

- [View DORA Metrics in DevLake](../how-to/observability/view-dora-metrics-devlake.md)
- [DORA Metrics Implementation Playbook](../playbooks/dora-metrics-implementation.md)
- [Architecture: DORA Metrics Service](../architecture.md#6-dora-metrics-service)
- [ADR-016: DevLake DORA Strategy](../adr/ADR-016%20devlake-dora-strategy.md)
