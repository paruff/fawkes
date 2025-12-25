---
title: Epic 1 Platform APIs Reference
description: Comprehensive API reference for all Epic 1 platform components
---

# Epic 1 Platform APIs Reference

## Overview

This document provides API references for all Epic 1 platform components, including REST APIs, webhooks, and integrations.

**Component Coverage:**
- ArgoCD REST API
- Backstage Plugin APIs
- Jenkins REST API & Webhooks
- Prometheus Query API
- Grafana API
- Harbor Registry API
- Vault API
- DevLake DORA Metrics API
- Kyverno Policy API

---

## Table of Contents

1. [Authentication](#authentication)
2. [ArgoCD API](#argocd-api)
3. [Backstage APIs](#backstage-apis)
4. [Jenkins API](#jenkins-api)
5. [Prometheus API](#prometheus-api)
6. [Grafana API](#grafana-api)
7. [Harbor API](#harbor-api)
8. [Vault API](#vault-api)
9. [DevLake API](#devlake-api)
10. [Kyverno API](#kyverno-api)

---

## Authentication

Different components use different authentication methods:

| Component | Auth Method | How to Obtain |
|-----------|-------------|---------------|
| ArgoCD | Bearer Token | `argocd account get-user-token` |
| Backstage | Session Cookie | OAuth flow via UI |
| Jenkins | API Token | User settings → API Token |
| Prometheus | None (internal) | Port-forward only |
| Grafana | API Key | Settings → API Keys |
| Harbor | Basic Auth | Username/password |
| Vault | Token | `vault login` or service account |
| DevLake | Bearer Token | Kubernetes secret |
| Kyverno | Kubernetes RBAC | kubectl with proper permissions |

---

## ArgoCD API

**Base URL:** `https://argocd.fawkes.local/api/v1`
**Authentication:** Bearer token in `Authorization` header

### Get Applications

```http
GET /applications
```

**Response:**
```json
{
  "items": [
    {
      "metadata": {
        "name": "backstage",
        "namespace": "argocd"
      },
      "spec": {
        "source": {
          "repoURL": "https://github.com/paruff/fawkes",
          "path": "platform/apps/backstage",
          "targetRevision": "main"
        },
        "destination": {
          "server": "https://kubernetes.default.svc",
          "namespace": "backstage"
        }
      },
      "status": {
        "sync": {
          "status": "Synced"
        },
        "health": {
          "status": "Healthy"
        }
      }
    }
  ]
}
```

### Sync Application

```http
POST /applications/{name}/sync
```

**Request Body:**
```json
{
  "revision": "main",
  "prune": false,
  "dryRun": false,
  "strategy": {
    "hook": {}
  }
}
```

**Response:**
```json
{
  "metadata": {
    "name": "backstage"
  },
  "status": "running"
}
```

### Get Application Details

```http
GET /applications/{name}
```

**Response:** Full application manifest with status

### Rollback Application

```http
POST /applications/{name}/rollback
```

**Request Body:**
```json
{
  "id": "12345"
}
```

---

## Backstage APIs

**Base URL:** `https://backstage.fawkes.local/api`
**Authentication:** Session cookie or service token

### Catalog API

#### List Entities

```http
GET /catalog/entities
```

**Query Parameters:**
- `filter` - Filter expression (e.g., `kind=component,metadata.name=payment-service`)
- `limit` - Number of results (default: 20)
- `offset` - Pagination offset

**Response:**
```json
{
  "items": [
    {
      "apiVersion": "backstage.io/v1alpha1",
      "kind": "Component",
      "metadata": {
        "name": "payment-service",
        "namespace": "default",
        "annotations": {
          "backstage.io/source-location": "url:https://github.com/paruff/payment-service"
        }
      },
      "spec": {
        "type": "service",
        "lifecycle": "production",
        "owner": "team-payments"
      }
    }
  ],
  "totalItems": 1,
  "pageInfo": {
    "hasNextPage": false
  }
}
```

#### Get Entity

```http
GET /catalog/entities/by-name/{kind}/{namespace}/{name}
```

**Example:**
```bash
curl https://backstage.fawkes.local/api/catalog/entities/by-name/component/default/payment-service
```

#### Create Entity

```http
POST /catalog/entities
```

**Request Body:**
```json
{
  "apiVersion": "backstage.io/v1alpha1",
  "kind": "Component",
  "metadata": {
    "name": "my-service",
    "description": "My new service"
  },
  "spec": {
    "type": "service",
    "lifecycle": "experimental",
    "owner": "team-platform"
  }
}
```

### Scaffolder API

#### List Templates

```http
GET /scaffolder/v2/templates
```

#### Trigger Template

```http
POST /scaffolder/v2/tasks
```

**Request Body:**
```json
{
  "templateRef": "template:default/python-service",
  "values": {
    "name": "my-python-service",
    "description": "My Python microservice",
    "owner": "team-platform"
  }
}
```

**Response:**
```json
{
  "id": "task-uuid-123",
  "status": "processing",
  "createdAt": "2024-12-16T10:00:00Z"
}
```

#### Get Task Status

```http
GET /scaffolder/v2/tasks/{taskId}
```

### TechDocs API

#### Get Documentation

```http
GET /techdocs/default/component/{name}/index.html
```

---

## Jenkins API

**Base URL:** `https://jenkins.fawkes.local`
**Authentication:** Username + API token (Basic Auth)

### Get Jenkins Info

```http
GET /api/json
```

### List Jobs

```http
GET /api/json?tree=jobs[name,url,color]
```

**Response:**
```json
{
  "jobs": [
    {
      "name": "payment-service-pipeline",
      "url": "https://jenkins.fawkes.local/job/payment-service-pipeline/",
      "color": "blue"
    }
  ]
}
```

### Get Job Info

```http
GET /job/{job-name}/api/json
```

### Trigger Build

```http
POST /job/{job-name}/build
```

**With Parameters:**
```http
POST /job/{job-name}/buildWithParameters?BRANCH=main&TAG=v1.0.0
```

### Get Build Status

```http
GET /job/{job-name}/{build-number}/api/json
```

**Response:**
```json
{
  "number": 42,
  "result": "SUCCESS",
  "duration": 120000,
  "timestamp": 1702731600000,
  "building": false
}
```

### Get Console Output

```http
GET /job/{job-name}/{build-number}/consoleText
```

### Jenkins Webhook Events

Jenkins sends webhooks to registered URLs on build events:

**Webhook Payload:**
```json
{
  "name": "payment-service-pipeline",
  "build": {
    "number": 42,
    "phase": "COMPLETED",
    "status": "SUCCESS",
    "url": "https://jenkins.fawkes.local/job/payment-service-pipeline/42/",
    "full_url": "https://jenkins.fawkes.local/job/payment-service-pipeline/42/",
    "timestamp": "2024-12-16T10:00:00Z",
    "duration": 120000,
    "parameters": {
      "BRANCH": "main"
    },
    "scm": {
      "commit": "abc123",
      "branch": "main",
      "url": "https://github.com/paruff/payment-service"
    }
  }
}
```

---

## Prometheus API

**Base URL:** `http://prometheus-kube-prometheus-prometheus.prometheus.svc:9090/api/v1`
**Authentication:** None (internal only)

### Query API

#### Instant Query

```http
GET /query?query={promql-query}
```

**Example:**
```bash
curl 'http://prometheus.prometheus.svc:9090/api/v1/query?query=up'
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "job": "kubernetes-pods",
          "pod": "backstage-7d8f9b5c6d-abc123"
        },
        "value": [1702731600, "1"]
      }
    ]
  }
}
```

#### Range Query

```http
GET /query_range?query={promql-query}&start={timestamp}&end={timestamp}&step={duration}
```

**Example:**
```bash
curl 'http://prometheus.prometheus.svc:9090/api/v1/query_range?query=rate(http_requests_total[5m])&start=2024-12-16T09:00:00Z&end=2024-12-16T10:00:00Z&step=60s'
```

### Targets API

#### List Targets

```http
GET /targets
```

**Response:**
```json
{
  "status": "success",
  "data": {
    "activeTargets": [
      {
        "labels": {
          "job": "backstage"
        },
        "scrapeUrl": "http://backstage.backstage.svc:7007/metrics",
        "health": "up",
        "lastError": ""
      }
    ]
  }
}
```

### Alerts API

```http
GET /alerts
```

---

## Grafana API

**Base URL:** `https://grafana.fawkes.local/api`
**Authentication:** API Key in `Authorization: Bearer {key}` header

### Dashboards

#### List Dashboards

```http
GET /search?type=dash-db
```

#### Get Dashboard by UID

```http
GET /dashboards/uid/{uid}
```

#### Create Dashboard

```http
POST /dashboards/db
```

**Request Body:**
```json
{
  "dashboard": {
    "title": "DORA Metrics",
    "panels": [],
    "tags": ["dora", "metrics"]
  },
  "overwrite": false
}
```

### Data Sources

#### List Data Sources

```http
GET /datasources
```

#### Get Data Source by ID

```http
GET /datasources/{id}
```

### Annotations

#### Create Annotation

```http
POST /annotations
```

**Request Body:**
```json
{
  "dashboardUID": "dashboard-uid",
  "panelId": 1,
  "time": 1702731600000,
  "text": "Deployment v1.2.3",
  "tags": ["deployment", "production"]
}
```

---

## Harbor API

**Base URL:** `https://harbor.fawkes.local/api/v2.0`
**Authentication:** Basic Auth (username:password)

### Projects

#### List Projects

```http
GET /projects
```

#### Create Project

```http
POST /projects
```

**Request Body:**
```json
{
  "project_name": "fawkes-platform",
  "public": false,
  "metadata": {
    "auto_scan": "true",
    "severity": "high"
  }
}
```

### Repositories

#### List Repositories

```http
GET /projects/{project}/repositories
```

#### Get Repository

```http
GET /projects/{project}/repositories/{repository}
```

### Artifacts

#### List Artifacts

```http
GET /projects/{project}/repositories/{repository}/artifacts
```

**Response:**
```json
{
  "artifacts": [
    {
      "id": 123,
      "digest": "sha256:abc123...",
      "tags": [
        {
          "name": "v1.0.0"
        }
      ],
      "scan_overview": {
        "severity": "Low",
        "total": 5,
        "summary": {
          "Low": 5
        }
      }
    }
  ]
}
```

#### Scan Artifact

```http
POST /projects/{project}/repositories/{repository}/artifacts/{reference}/scan
```

### Scan Results

#### Get Scan Report

```http
GET /projects/{project}/repositories/{repository}/artifacts/{reference}/additions/vulnerabilities
```

---

## Vault API

**Base URL:** `https://vault.fawkes.local/v1`
**Authentication:** X-Vault-Token header

### KV Secrets Engine

#### Read Secret

```http
GET /secret/data/{path}
```

**Response:**
```json
{
  "data": {
    "data": {
      "username": "admin",
      "password": "secret123"
    },
    "metadata": {
      "created_time": "2024-12-16T10:00:00Z",
      "version": 1
    }
  }
}
```

#### Write Secret

```http
POST /secret/data/{path}
```

**Request Body:**
```json
{
  "data": {
    "username": "admin",
    "password": "newsecret"
  }
}
```

#### Delete Secret

```http
DELETE /secret/data/{path}
```

### Auth Methods

#### Kubernetes Auth

```http
POST /auth/kubernetes/login
```

**Request Body:**
```json
{
  "jwt": "{service-account-jwt}",
  "role": "backstage"
}
```

**Response:**
```json
{
  "auth": {
    "client_token": "hvs.CAESIxxxxxx",
    "accessor": "xxxxx",
    "policies": ["default", "backstage-policy"],
    "lease_duration": 3600
  }
}
```

### System Endpoints

#### Health Check

```http
GET /sys/health
```

#### Seal Status

```http
GET /sys/seal-status
```

---

## DevLake API

**Base URL:** `https://devlake.fawkes.local/api`
**Authentication:** Bearer token

For detailed DORA metrics API, see [DORA Metrics API Reference](../dora-metrics-api.md).

### Quick Reference

#### Get DORA Metrics

```http
GET /dora/metrics?project={name}&timeRange={range}
```

#### Get Deployment Frequency

```http
GET /dora/deployment-frequency?project={name}
```

#### Get Lead Time

```http
GET /dora/lead-time?project={name}
```

#### Get Change Failure Rate

```http
GET /dora/change-failure-rate?project={name}
```

#### Get MTTR

```http
GET /dora/mttr?project={name}
```

### Webhooks

#### ArgoCD Deployment Webhook

DevLake receives deployment events from ArgoCD:

**Endpoint:** `POST /webhooks/argocd`

**Payload:**
```json
{
  "type": "sync",
  "application": "payment-service",
  "status": "Succeeded",
  "revision": "abc123",
  "timestamp": "2024-12-16T10:00:00Z"
}
```

#### Jenkins Build Webhook

**Endpoint:** `POST /webhooks/jenkins`

**Payload:**
```json
{
  "job": "payment-service-pipeline",
  "build": 42,
  "status": "SUCCESS",
  "commit": "abc123",
  "timestamp": "2024-12-16T10:00:00Z"
}
```

---

## Kyverno API

**Base URL:** Kubernetes API Server
**Authentication:** Kubernetes RBAC via kubectl

### Policies

#### List Cluster Policies

```bash
kubectl get clusterpolicies
```

#### Get Policy Details

```bash
kubectl get clusterpolicy {name} -o yaml
```

### Policy Reports

#### List Policy Reports

```bash
kubectl get policyreports -A
```

**Or via API:**
```http
GET /apis/wgpolicyk8s.io/v1alpha2/policyreports
```

#### Get Policy Report

```bash
kubectl get policyreport {name} -n {namespace} -o json
```

**Response:**
```json
{
  "apiVersion": "wgpolicyk8s.io/v1alpha2",
  "kind": "PolicyReport",
  "metadata": {
    "name": "polr-ns-default",
    "namespace": "default"
  },
  "results": [
    {
      "policy": "require-labels",
      "rule": "check-for-labels",
      "result": "fail",
      "message": "Missing required label: app",
      "resources": [
        {
          "kind": "Pod",
          "name": "my-pod"
        }
      ]
    }
  ],
  "summary": {
    "pass": 10,
    "fail": 2,
    "skip": 1
  }
}
```

---

## Common Use Cases

### Use Case 1: Trigger Deployment from External System

```bash
# 1. Trigger Jenkins build
curl -X POST https://jenkins.fawkes.local/job/payment-service/buildWithParameters \
  -u user:token \
  -d "BRANCH=main&TAG=v1.0.0"

# 2. Wait for build to complete
# 3. ArgoCD auto-syncs deployment
# 4. DevLake webhook receives deployment event
```

### Use Case 2: Query DORA Metrics

```bash
# Get all metrics for a service
curl -H "Authorization: Bearer $TOKEN" \
  https://devlake.fawkes.local/api/dora/metrics?project=payment-service&timeRange=last30days
```

### Use Case 3: Create New Service in Backstage

```bash
# 1. Create catalog entry
curl -X POST https://backstage.fawkes.local/api/catalog/entities \
  -H "Content-Type: application/json" \
  -d '{
    "apiVersion": "backstage.io/v1alpha1",
    "kind": "Component",
    "metadata": {"name": "my-service"},
    "spec": {"type": "service", "owner": "team"}
  }'

# 2. Or scaffold from template
curl -X POST https://backstage.fawkes.local/api/scaffolder/v2/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "templateRef": "template:default/python-service",
    "values": {"name": "my-service"}
  }'
```

### Use Case 4: Check Service Health

```bash
# 1. Check ArgoCD sync status
curl https://argocd.fawkes.local/api/v1/applications/my-service \
  -H "Authorization: Bearer $ARGOCD_TOKEN"

# 2. Check Prometheus metrics
curl 'http://prometheus.prometheus.svc:9090/api/v1/query?query=up{service="my-service"}'

# 3. Check for policy violations
kubectl get policyreport -n my-service
```

---

## API Rate Limits

| Component | Rate Limit | Notes |
|-----------|------------|-------|
| ArgoCD | 30 req/min | Per user/token |
| Backstage | 100 req/min | Per session |
| Jenkins | 60 req/min | Per API token |
| Prometheus | Unlimited | Internal only |
| Grafana | 100 req/min | Per API key |
| Harbor | 100 req/min | Per user |
| Vault | 100 req/min | Per token |
| DevLake | 60 req/min | Per token |

---

## Error Responses

All APIs follow a consistent error format:

```json
{
  "error": {
    "code": "INVALID_REQUEST",
    "message": "Missing required parameter: project",
    "details": {
      "field": "project",
      "reason": "required"
    }
  }
}
```

**Common HTTP Status Codes:**
- `200 OK` - Request succeeded
- `201 Created` - Resource created
- `400 Bad Request` - Invalid request
- `401 Unauthorized` - Missing/invalid authentication
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `409 Conflict` - Resource already exists
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error
- `503 Service Unavailable` - Service temporarily unavailable

---

## SDK & Client Libraries

| Language | ArgoCD | Jenkins | Prometheus | Grafana |
|----------|--------|---------|------------|---------|
| Python | `argocd-python` | `python-jenkins` | `prometheus-api-client` | `grafana-client` |
| Go | `argocd-client-go` | - | `prometheus/client_golang` | `grafana-api-golang-client` |
| JavaScript | - | `jenkins` | `prom-client` | `grafana-api-client` |

---

## Related Documentation

- [Backstage Plugins API](./backstage-plugins.md)
- [Jenkins Webhook API](./jenkins-webhook.md)
- [DORA Metrics API](../dora-metrics-api.md)
- [DORA Metrics Database Schema](../dora-metrics-database-schema.md)
- [Epic 1 Platform Operations Runbook](../../runbooks/epic-1-platform-operations.md)

---

## Support

For API issues or questions:
- Check component-specific documentation
- Review logs via `kubectl logs`
- Open issue on GitHub with API request/response examples
- Contact platform team

---

## Change Log

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2024-12 | 1.0 | Initial Epic 1 API documentation | Platform Team |
