---
title: Epic 3 Product Discovery & UX APIs Reference
description: Comprehensive API reference for all Epic 3 components
---

# Epic 3 Product Discovery & UX APIs Reference

## Overview

This document provides API references for all Epic 3 Product Discovery & UX components, including REST APIs, webhooks, and integrations.

**Component Coverage:**
- SPACE Metrics Service API
- Feedback Service API
- Feedback Bot Commands
- Unleash Feature Flags API
- Product Analytics API
- Design System (Storybook)

---

## Table of Contents

1. [Authentication](#authentication)
2. [SPACE Metrics API](#space-metrics-api)
3. [Feedback Service API](#feedback-service-api)
4. [Feedback Bot Commands](#feedback-bot-commands)
5. [Unleash API](#unleash-api)
6. [Product Analytics API](#product-analytics-api)
7. [Storybook (Design System)](#storybook-design-system)

---

## Authentication

Different components use different authentication methods:

| Component | Auth Method | How to Obtain | Header/Token Format |
|-----------|-------------|---------------|---------------------|
| SPACE Metrics | API Key | ConfigMap or admin | `X-API-Key: <key>` |
| Feedback Service | Session Cookie | Backstage OAuth | Cookie-based |
| Feedback Bot | Bot Token | Mattermost integration | N/A (internal) |
| Unleash | API Token | Unleash UI → API Access | `Authorization: <token>` |
| Product Analytics | Project API Key | Analytics dashboard | `X-Api-Key: <key>` |

### Obtaining API Keys

```bash
# SPACE Metrics API Key (from ConfigMap)
kubectl get configmap space-metrics-config -n fawkes-local \
  -o jsonpath='{.data.API_KEY}'

# Unleash API Token (from UI)
# Navigate to: https://unleash.fawkes.local → Settings → API Access → Create Token

# Product Analytics API Key (from analytics dashboard)
# Navigate to: Settings → Project Settings → API Keys
```

---

## SPACE Metrics API

**Base URL**: `http://space-metrics.fawkes-local.svc.cluster.local:8000`  
**External Access**: Port-forward with `kubectl port-forward -n fawkes-local svc/space-metrics 8000:8000`

### Health Check

```http
GET /health
```

**Response**:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "database": "connected",
  "timestamp": "2024-12-25T10:30:00Z"
}
```

### Get All SPACE Metrics

```http
GET /api/v1/metrics/space
```

**Query Parameters**:
- `team` (optional): Filter by team name
- `start_date` (optional): ISO 8601 date (default: 30 days ago)
- `end_date` (optional): ISO 8601 date (default: now)
- `granularity` (optional): `daily`, `weekly`, `monthly` (default: `weekly`)

**Response**:
```json
{
  "period": {
    "start": "2024-11-25",
    "end": "2024-12-25"
  },
  "metrics": {
    "satisfaction": {
      "enps_score": 45,
      "avg_rating": 4.2,
      "response_count": 42
    },
    "performance": {
      "deployment_frequency": 12.5,
      "lead_time_hours": 4.2,
      "build_success_rate": 0.95
    },
    "activity": {
      "commits_per_week": 85,
      "prs_merged": 23,
      "active_days": 4.8
    },
    "communication": {
      "mattermost_messages": 450,
      "pr_comments": 156,
      "docs_updates": 12
    },
    "efficiency": {
      "time_to_first_commit_hours": 3.5,
      "time_to_production_hours": 8.2,
      "cognitive_load_index": 3.8
    }
  }
}
```

### Get Specific SPACE Dimension

```http
GET /api/v1/metrics/space/{dimension}
```

**Dimensions**: `satisfaction`, `performance`, `activity`, `communication`, `efficiency`

**Example**:
```http
GET /api/v1/metrics/space/satisfaction?team=platform
```

**Response**:
```json
{
  "dimension": "satisfaction",
  "team": "platform",
  "period": {
    "start": "2024-11-25",
    "end": "2024-12-25"
  },
  "data": {
    "enps_score": 45,
    "nps_breakdown": {
      "promoters": 15,
      "passives": 8,
      "detractors": 3
    },
    "avg_rating": 4.2,
    "response_count": 42,
    "trend": "improving"
  }
}
```

### Submit Pulse Survey

```http
POST /api/v1/surveys/pulse/submit
Content-Type: application/json
X-API-Key: <api-key>
```

**Request Body**:
```json
{
  "user_id": "anonymous_12345",
  "timestamp": "2024-12-25T10:30:00Z",
  "responses": {
    "overall_satisfaction": 4,
    "productivity_this_week": 5,
    "blockers": "None this week",
    "wins": "Deployed new feature successfully"
  }
}
```

**Response**:
```json
{
  "status": "success",
  "survey_id": "survey_67890",
  "message": "Thank you for your feedback!"
}
```

### Submit Friction Log

```http
POST /api/v1/friction-log/submit
Content-Type: application/json
X-API-Key: <api-key>
```

**Request Body**:
```json
{
  "user_id": "anonymous_12345",
  "timestamp": "2024-12-25T10:30:00Z",
  "category": "deployment",
  "description": "Deployment pipeline failed due to timeout",
  "severity": "medium",
  "time_lost_minutes": 30
}
```

**Response**:
```json
{
  "status": "success",
  "friction_id": "friction_99999",
  "message": "Friction point logged. Thank you for reporting!"
}
```

### Cognitive Load Assessment

```http
GET /api/v1/cognitive-load/assessment
```

**Response**: Returns NASA-TLX assessment form

```http
POST /api/v1/cognitive-load/submit
Content-Type: application/json
X-API-Key: <api-key>
```

**Request Body** (NASA-TLX scores, 0-100):
```json
{
  "user_id": "anonymous_12345",
  "task": "Deploying microservice to production",
  "timestamp": "2024-12-25T10:30:00Z",
  "scores": {
    "mental_demand": 60,
    "physical_demand": 20,
    "temporal_demand": 70,
    "performance": 80,
    "effort": 65,
    "frustration": 40
  }
}
```

### Prometheus Metrics

```http
GET /metrics
```

Exposes Prometheus metrics:
- `space_metrics_satisfaction_enps`
- `space_metrics_performance_deployment_frequency`
- `space_metrics_activity_commits_total`
- `space_metrics_communication_messages_total`
- `space_metrics_efficiency_cognitive_load`

---

## Feedback Service API

**Base URL**: `http://feedback-service.fawkes.svc.cluster.local:8080`  
**External Access**: Port-forward with `kubectl port-forward -n fawkes svc/feedback-service 8080:8080`

### Health Check

```http
GET /health
```

**Response**:
```json
{
  "status": "ok",
  "database": "connected"
}
```

### Submit Feedback

```http
POST /api/v1/feedback
Content-Type: application/json
```

**Request Body**:
```json
{
  "rating": 5,
  "category": "UI/UX",
  "message": "The new dashboard is amazing!",
  "context": {
    "page": "/dashboard",
    "component": "backstage",
    "timestamp": "2024-12-25T10:30:00Z"
  },
  "user": {
    "id": "user-123",
    "name": "John Doe",
    "email": "john@example.com",
    "anonymous": false
  },
  "screenshot": "<base64-encoded-image>" // optional
}
```

**Response**:
```json
{
  "id": "fb_12345",
  "status": "new",
  "message": "Thank you for your feedback!",
  "created_at": "2024-12-25T10:30:00Z"
}
```

### List Feedback (Admin)

```http
GET /api/v1/feedback
```

**Query Parameters**:
- `status`: `new`, `validated`, `in_progress`, `resolved`, `archived`
- `category`: Filter by category
- `rating`: Filter by rating (1-5)
- `start_date`: ISO 8601 date
- `end_date`: ISO 8601 date
- `page`: Page number (default: 1)
- `per_page`: Results per page (default: 20, max: 100)

**Response**:
```json
{
  "feedback": [
    {
      "id": "fb_12345",
      "rating": 5,
      "category": "UI/UX",
      "message": "The new dashboard is amazing!",
      "sentiment": "positive",
      "status": "validated",
      "created_at": "2024-12-25T10:30:00Z",
      "user": {
        "name": "John Doe",
        "email": "john@example.com"
      }
    }
  ],
  "pagination": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

### Get Single Feedback

```http
GET /api/v1/feedback/{id}
```

**Response**:
```json
{
  "id": "fb_12345",
  "rating": 5,
  "category": "UI/UX",
  "message": "The new dashboard is amazing!",
  "context": {
    "page": "/dashboard",
    "component": "backstage"
  },
  "sentiment": "positive",
  "status": "validated",
  "created_at": "2024-12-25T10:30:00Z",
  "updated_at": "2024-12-25T11:00:00Z",
  "user": {
    "name": "John Doe",
    "email": "john@example.com"
  },
  "screenshot_url": "/api/v1/feedback/fb_12345/screenshot",
  "github_issue": {
    "number": 250,
    "url": "https://github.com/paruff/fawkes/issues/250"
  }
}
```

### Update Feedback Status (Admin)

```http
PUT /api/v1/feedback/{id}/status
Content-Type: application/json
```

**Request Body**:
```json
{
  "status": "validated",
  "notes": "Confirmed with 3 other users"
}
```

**Response**:
```json
{
  "id": "fb_12345",
  "status": "validated",
  "updated_at": "2024-12-25T11:00:00Z"
}
```

### Get Feedback Statistics

```http
GET /api/v1/feedback/stats
```

**Query Parameters**:
- `start_date`: ISO 8601 date (default: 30 days ago)
- `end_date`: ISO 8601 date (default: now)

**Response**:
```json
{
  "period": {
    "start": "2024-11-25",
    "end": "2024-12-25"
  },
  "total_feedback": 150,
  "by_rating": {
    "1": 5,
    "2": 10,
    "3": 20,
    "4": 45,
    "5": 70
  },
  "by_category": {
    "UI/UX": 50,
    "Performance": 30,
    "Documentation": 25,
    "CI/CD": 20,
    "Other": 25
  },
  "by_status": {
    "new": 30,
    "validated": 50,
    "in_progress": 40,
    "resolved": 25,
    "archived": 5
  },
  "by_sentiment": {
    "positive": 100,
    "neutral": 30,
    "negative": 20
  },
  "avg_rating": 4.1,
  "response_rate": 0.42
}
```

### Process Validated Feedback (Automation)

```http
POST /api/v1/automation/process-validated
Content-Type: application/json
X-API-Key: <automation-key>
```

**Response**:
```json
{
  "processed": 5,
  "github_issues_created": [
    {
      "feedback_id": "fb_12345",
      "issue_number": 250,
      "issue_url": "https://github.com/paruff/fawkes/issues/250"
    }
  ],
  "errors": []
}
```

### Prometheus Metrics

```http
GET /metrics
```

Exposes metrics:
- `feedback_submissions_total`
- `feedback_by_rating`
- `feedback_by_category`
- `feedback_processing_duration_seconds`

---

## Feedback Bot Commands

The Mattermost feedback bot responds to direct messages and mentions.

### Submit Feedback via Bot

**In any channel**:
```
@feedback The new CI/CD pipeline is much faster!
```

**Via Direct Message**:
```
The deployment experience could be improved
```

**Bot Response**:
```
✅ Feedback received! I've analyzed your message:
• Category: CI/CD
• Sentiment: Positive
• Priority: Low

Would you like to add more details? Reply to this thread.
```

### Check Feedback Status

```
@feedback status
```

**Bot Response**:
```
📊 Feedback Summary (Last 30 days):
• Total submissions: 15
• Avg rating: 4.2
• Your submissions: 3
• Recent: "The new CI/CD pipeline..." (2 days ago)
```

### Get Help

```
@feedback help
```

**Bot Response**:
```
🤖 Feedback Bot Commands:
• @feedback <message> - Submit feedback
• @feedback status - View your feedback stats
• @feedback help - Show this help message

You can also DM me directly with feedback!
```

---

## Unleash API

**Base URL**: `http://unleash.fawkes.svc.cluster.local:4242`  
**UI**: `https://unleash.fawkes.local` (port-forward for local access)

### Authentication

All Admin API requests require an API token:

```http
Authorization: <YOUR_API_TOKEN>
```

Obtain from: Unleash UI → Settings → API Access → Create API Token

### Client API (OpenFeature SDK)

**Base URL**: `http://unleash.fawkes.svc.cluster.local:4242/api/client`  
**Authentication**: Client API tokens (different from Admin API)

#### Get Feature Flags

```http
GET /api/client/features
Authorization: <CLIENT_TOKEN>
```

**Response**:
```json
{
  "version": 1,
  "features": [
    {
      "name": "new-dashboard",
      "enabled": true,
      "strategies": [
        {
          "name": "gradualRolloutUserId",
          "parameters": {
            "percentage": "50"
          }
        }
      ],
      "variants": []
    }
  ]
}
```

#### Register Client

```http
POST /api/client/register
Content-Type: application/json
Authorization: <CLIENT_TOKEN>
```

**Request Body**:
```json
{
  "appName": "backstage",
  "instanceId": "instance-12345",
  "sdkVersion": "unleash-client-node:4.0.0",
  "strategies": ["default", "gradualRolloutUserId"],
  "started": "2024-12-25T10:30:00Z",
  "interval": 15000
}
```

#### Send Metrics

```http
POST /api/client/metrics
Content-Type: application/json
Authorization: <CLIENT_TOKEN>
```

**Request Body**:
```json
{
  "appName": "backstage",
  "instanceId": "instance-12345",
  "bucket": {
    "start": "2024-12-25T10:30:00Z",
    "stop": "2024-12-25T10:45:00Z",
    "toggles": {
      "new-dashboard": {
        "yes": 150,
        "no": 50
      }
    }
  }
}
```

### Admin API

#### List Feature Flags

```http
GET /api/admin/features
Authorization: <ADMIN_TOKEN>
```

#### Create Feature Flag

```http
POST /api/admin/features
Content-Type: application/json
Authorization: <ADMIN_TOKEN>
```

**Request Body**:
```json
{
  "name": "new-dashboard",
  "description": "Enable new dashboard UI",
  "type": "release",
  "enabled": true,
  "stale": false,
  "strategies": [
    {
      "name": "gradualRolloutUserId",
      "parameters": {
        "percentage": "25",
        "groupId": "new-dashboard"
      }
    }
  ]
}
```

#### Toggle Feature Flag

```http
POST /api/admin/features/{featureName}/toggle/{on|off}
Authorization: <ADMIN_TOKEN>
```

#### Get Feature Flag Metrics

```http
GET /api/admin/metrics/features/{featureName}
Authorization: <ADMIN_TOKEN>
```

**Response**:
```json
{
  "featureName": "new-dashboard",
  "lastHourUsage": {
    "yes": 1500,
    "no": 500
  },
  "seenApplications": ["backstage", "feedback-service"]
}
```

---

## Product Analytics API

**Base URL**: Depends on analytics platform (PostHog/Plausible)  
**UI**: `https://analytics.fawkes.local` (if deployed)

### Capture Event (PostHog)

```http
POST /api/capture
Content-Type: application/json
```

**Request Body**:
```json
{
  "api_key": "<PROJECT_API_KEY>",
  "event": "service_created",
  "properties": {
    "template": "java-service",
    "environment": "dev",
    "component": "backstage"
  },
  "timestamp": "2024-12-25T10:30:00Z",
  "distinct_id": "user-123"
}
```

### Batch Events

```http
POST /api/batch
Content-Type: application/json
```

**Request Body**:
```json
{
  "api_key": "<PROJECT_API_KEY>",
  "batch": [
    {
      "event": "page_view",
      "properties": {"page": "/dashboard"},
      "timestamp": "2024-12-25T10:30:00Z",
      "distinct_id": "user-123"
    },
    {
      "event": "button_clicked",
      "properties": {"button": "deploy"},
      "timestamp": "2024-12-25T10:31:00Z",
      "distinct_id": "user-123"
    }
  ]
}
```

### Query Events

```http
POST /api/query
Content-Type: application/json
Authorization: Bearer <API_TOKEN>
```

**Request Body**:
```json
{
  "query": {
    "kind": "EventsQuery",
    "select": ["*"],
    "event": "service_created",
    "after": "2024-11-25",
    "before": "2024-12-25"
  }
}
```

---

## Storybook (Design System)

**URL**: `https://storybook.fawkes.local` (or port-forward)  
**Port**: 6006

Storybook is a static site and doesn't have a REST API, but provides:

### Component Documentation

Access via web UI:
- Component list at `/`
- Individual components at `/story/<component-name>`
- Documentation pages at `/docs/<component-name>`

### Accessibility Reports

Each component page includes:
- A11y addon violations panel
- WCAG 2.1 AA compliance status
- Interactive accessibility tree

### Component Export

To use components in your application:

```bash
npm install @fawkes/design-system
```

```javascript
import { Button, Card, Modal } from '@fawkes/design-system';
import '@fawkes/design-system/dist/styles.css';
```

---

## Error Handling

All APIs follow a consistent error response format:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing required field: rating",
    "details": {
      "field": "rating",
      "constraint": "required"
    }
  },
  "status": 400,
  "timestamp": "2024-12-25T10:30:00Z"
}
```

### Common HTTP Status Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 200 | OK | Request successful |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request parameters |
| 401 | Unauthorized | Missing or invalid authentication |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |
| 503 | Service Unavailable | Service temporarily unavailable |

---

## Rate Limiting

| Endpoint | Rate Limit | Window |
|----------|------------|--------|
| SPACE Metrics API | 100 req/min | Per API key |
| Feedback API | 50 req/min | Per user |
| Unleash Client API | 1000 req/min | Per client token |
| Product Analytics | 1000 events/min | Per project |

Rate limit headers are included in responses:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640444400
```

---

## Webhooks

### Feedback Webhook (GitHub Issue Created)

When validated feedback is converted to a GitHub issue, a webhook can be configured:

**Event**: `feedback.github_issue_created`

**Payload**:
```json
{
  "event": "feedback.github_issue_created",
  "timestamp": "2024-12-25T10:30:00Z",
  "feedback": {
    "id": "fb_12345",
    "rating": 5,
    "category": "UI/UX",
    "message": "The new dashboard is amazing!"
  },
  "github_issue": {
    "number": 250,
    "url": "https://github.com/paruff/fawkes/issues/250",
    "title": "[Feedback] The new dashboard is amazing!"
  }
}
```

### Unleash Webhook (Feature Flag Changed)

Unleash can send webhooks when feature flags change:

**Event**: `feature-updated`

**Payload**:
```json
{
  "event": "feature-updated",
  "createdAt": "2024-12-25T10:30:00Z",
  "data": {
    "name": "new-dashboard",
    "enabled": true,
    "project": "default",
    "strategies": [...]
  },
  "createdBy": "admin@example.com"
}
```

---

## SDKs and Client Libraries

### SPACE Metrics

**Python Client**:
```python
from space_metrics_client import SPACEMetricsClient

client = SPACEMetricsClient(
    base_url="http://space-metrics:8000",
    api_key="your-api-key"
)

metrics = client.get_all_metrics(team="platform")
print(metrics.satisfaction.enps_score)
```

### Feedback Service

**JavaScript/TypeScript Client**:
```typescript
import { FeedbackClient } from '@fawkes/feedback-client';

const client = new FeedbackClient({
  baseURL: 'http://feedback-service:8080'
});

await client.submitFeedback({
  rating: 5,
  category: 'UI/UX',
  message: 'Great experience!'
});
```

### Unleash

**OpenFeature SDK** (Recommended):
```javascript
import { OpenFeature } from '@openfeature/server-sdk';
import { UnleashProvider } from '@openfeature/unleash-provider';

OpenFeature.setProvider(new UnleashProvider({
  url: 'http://unleash:4242/api',
  clientKey: 'your-client-key',
  appName: 'my-app'
}));

const client = OpenFeature.getClient();
const enabled = await client.getBooleanValue('new-dashboard', false);
```

---

## Related Documentation

- [Epic 3 Operations Runbook](../../runbooks/epic-3-product-discovery-operations.md)
- [Epic 3 Architecture Diagrams](../../runbooks/epic-3-architecture-diagrams.md)
- [AT-E3-002 SPACE Framework Validation](../../validation/AT-E3-002-IMPLEMENTATION.md)
- [AT-E3-003 Feedback System Validation](../../validation/AT-E3-003-IMPLEMENTATION.md)
- [Unleash Documentation](https://docs.getunleash.io/)
- [OpenFeature Documentation](https://openfeature.dev/)

---

## Support

For API support:
- **Platform Team**: #platform-team on Mattermost
- **Issues**: GitHub Issues
- **Documentation**: TechDocs in Backstage
