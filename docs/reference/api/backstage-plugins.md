---
title: Backstage Plugins API
description: OpenAPI specification for internal Backstage plugins
---

# Backstage Plugins API

## Overview

This document describes the REST APIs exposed by custom Backstage plugins integrated into the Fawkes platform. These plugins extend Backstage's functionality for Fawkes-specific workflows.

**Base URL:** `https://backstage.fawkes.example.com/api`

**Authentication:** Backstage user session or service-to-service tokens.

---

## Che Launcher Plugin

### POST /che-launcher/workspaces

Creates a new Eclipse Che workspace from a Devfile.

#### Request

**Method:** `POST`

**URL:** `/api/che-launcher/workspaces`

**Headers:**

| Header          | Required | Description                          |
| --------------- | -------- | ------------------------------------ |
| `Authorization` | Yes      | Bearer token from Backstage session. |
| `Content-Type`  | Yes      | `application/json`                   |

**Request Body:**

```json
{
  "devfileUrl": "https://raw.githubusercontent.com/paruff/fawkes/main/platform/devfiles/goldenpath-python.yaml",
  "namespace": "dev-workspaces",
  "name": "my-python-workspace"
}
```

| Field        | Type   | Required | Description                                                       |
| ------------ | ------ | -------- | ----------------------------------------------------------------- |
| `devfileUrl` | String | Yes      | URL to Devfile 2.2.2 YAML file.                                   |
| `namespace`  | String | No       | Kubernetes namespace for workspace. Default: `{user}-workspaces`. |
| `name`       | String | No       | Workspace name. Default: auto-generated.                          |

#### Response

**Success (201 Created):**

```json
{
  "workspaceId": "workspace-abc123",
  "name": "my-python-workspace",
  "status": "Starting",
  "ideUrl": "https://che.fawkes.example.com/workspace-abc123",
  "devfile": {
    "name": "goldenpath-python",
    "version": "1.0.0"
  }
}
```

**Error (400 Bad Request):**

```json
{
  "error": "Invalid devfileUrl: URL must be HTTPS"
}
```

**Error (409 Conflict):**

```json
{
  "error": "Workspace with name 'my-python-workspace' already exists"
}
```

---

### GET /che-launcher/workspaces

Lists all workspaces for the authenticated user.

#### Request

**Method:** `GET`

**URL:** `/api/che-launcher/workspaces`

**Headers:**

| Header          | Required | Description   |
| --------------- | -------- | ------------- |
| `Authorization` | Yes      | Bearer token. |

**Query Parameters:**

| Parameter | Type   | Required | Description                                                     |
| --------- | ------ | -------- | --------------------------------------------------------------- |
| `status`  | String | No       | Filter by status: `Running`, `Stopped`, `Starting`, `Stopping`. |

#### Response

**Success (200 OK):**

```json
{
  "workspaces": [
    {
      "workspaceId": "workspace-abc123",
      "name": "my-python-workspace",
      "status": "Running",
      "ideUrl": "https://che.fawkes.example.com/workspace-abc123",
      "devfile": {
        "name": "goldenpath-python",
        "version": "1.0.0"
      },
      "createdAt": "2024-12-01T10:00:00Z",
      "lastUsed": "2024-12-06T09:30:00Z"
    }
  ],
  "total": 1
}
```

---

### DELETE /che-launcher/workspaces/{workspaceId}

Deletes a workspace.

#### Request

**Method:** `DELETE`

**URL:** `/api/che-launcher/workspaces/{workspaceId}`

**Headers:**

| Header          | Required | Description   |
| --------------- | -------- | ------------- |
| `Authorization` | Yes      | Bearer token. |

#### Response

**Success (204 No Content):**

No response body.

**Error (404 Not Found):**

```json
{
  "error": "Workspace not found"
}
```

---

## DevLake Dashboard Plugin

### GET /devlake/dora-metrics

Retrieves DORA metrics for a project or team.

#### Request

**Method:** `GET`

**URL:** `/api/devlake/dora-metrics`

**Headers:**

| Header          | Required | Description   |
| --------------- | -------- | ------------- |
| `Authorization` | Yes      | Bearer token. |

**Query Parameters:**

| Parameter   | Type   | Required | Description                                  |
| ----------- | ------ | -------- | -------------------------------------------- |
| `project`   | String | No       | Project name (from Backstage catalog).       |
| `team`      | String | No       | Team name.                                   |
| `startDate` | String | No       | Start date (ISO 8601). Default: 30 days ago. |
| `endDate`   | String | No       | End date (ISO 8601). Default: today.         |

#### Response

**Success (200 OK):**

```json
{
  "project": "my-service",
  "team": "platform-team",
  "period": {
    "startDate": "2024-11-01",
    "endDate": "2024-12-01"
  },
  "metrics": {
    "deploymentFrequency": {
      "value": 12,
      "unit": "deploys/week",
      "trend": "increasing",
      "performance": "elite"
    },
    "leadTimeForChanges": {
      "value": 2.5,
      "unit": "hours",
      "trend": "stable",
      "performance": "elite"
    },
    "changeFailureRate": {
      "value": 5.2,
      "unit": "percent",
      "trend": "decreasing",
      "performance": "high"
    },
    "timeToRestoreService": {
      "value": 0.8,
      "unit": "hours",
      "trend": "stable",
      "performance": "elite"
    }
  }
}
```

**Performance Levels:**

- `elite`: Top 10% of performers.
- `high`: 60-75th percentile.
- `medium`: 30-60th percentile.
- `low`: Below 30th percentile.

---

### GET /devlake/deployment-history

Retrieves deployment history for a service.

#### Request

**Method:** `GET`

**URL:** `/api/devlake/deployment-history`

**Headers:**

| Header          | Required | Description   |
| --------------- | -------- | ------------- |
| `Authorization` | Yes      | Bearer token. |

**Query Parameters:**

| Parameter     | Type    | Required | Description                                       |
| ------------- | ------- | -------- | ------------------------------------------------- |
| `service`     | String  | Yes      | Service name.                                     |
| `environment` | String  | No       | Filter by environment (`dev`, `staging`, `prod`). |
| `limit`       | Integer | No       | Number of results. Default: `20`. Max: `100`.     |

#### Response

**Success (200 OK):**

```json
{
  "service": "my-service",
  "deployments": [
    {
      "id": "deploy-789",
      "version": "v1.2.3",
      "environment": "prod",
      "status": "SUCCESS",
      "startTime": "2024-12-06T08:00:00Z",
      "endTime": "2024-12-06T08:05:00Z",
      "duration": 300,
      "triggeredBy": "GitHub Push",
      "commit": {
        "sha": "def456...",
        "message": "feat: add new feature",
        "author": "developer@example.com"
      }
    }
  ],
  "total": 1
}
```

---

## Catalog Plugin (Extended)

### POST /catalog/locations

Registers a new entity location (e.g., Git repository with `catalog-info.yaml`).

#### Request

**Method:** `POST`

**URL:** `/api/catalog/locations`

**Headers:**

| Header          | Required | Description        |
| --------------- | -------- | ------------------ |
| `Authorization` | Yes      | Bearer token.      |
| `Content-Type`  | Yes      | `application/json` |

**Request Body:**

```json
{
  "type": "url",
  "target": "https://github.com/paruff/my-service/blob/main/catalog-info.yaml"
}
```

| Field    | Type   | Required | Description                              |
| -------- | ------ | -------- | ---------------------------------------- |
| `type`   | String | Yes      | Location type: `url`, `file`.            |
| `target` | String | Yes      | URL or file path to `catalog-info.yaml`. |

#### Response

**Success (201 Created):**

```json
{
  "locationId": "location-xyz",
  "type": "url",
  "target": "https://github.com/paruff/my-service/blob/main/catalog-info.yaml",
  "status": "processing"
}
```

**Error (400 Bad Request):**

```json
{
  "error": "Invalid catalog-info.yaml: missing required field 'metadata.name'"
}
```

---

### GET /catalog/entities

Retrieves entities from the software catalog.

#### Request

**Method:** `GET`

**URL:** `/api/catalog/entities`

**Headers:**

| Header          | Required | Description   |
| --------------- | -------- | ------------- |
| `Authorization` | Yes      | Bearer token. |

**Query Parameters:**

| Parameter | Type   | Required | Description                                                          |
| --------- | ------ | -------- | -------------------------------------------------------------------- |
| `filter`  | String | No       | Filter expression (e.g., `kind=Component,metadata.name=my-service`). |
| `fields`  | String | No       | Comma-separated list of fields to include.                           |

#### Response

**Success (200 OK):**

```json
[
  {
    "apiVersion": "backstage.io/v1alpha1",
    "kind": "Component",
    "metadata": {
      "name": "my-service",
      "description": "Microservice for user management",
      "labels": {
        "app.fawkes.idp/team": "platform-team"
      }
    },
    "spec": {
      "type": "service",
      "lifecycle": "production",
      "owner": "platform-team"
    }
  }
]
```

---

## Authentication

All API endpoints require authentication via:

1. **Backstage User Session:** Automatically included when using Backstage UI.
2. **Service Token:** For service-to-service calls, use a service account token:

```bash
curl -H "Authorization: Bearer <service-token>" \
  https://backstage.fawkes.example.com/api/catalog/entities
```

**Generate Service Token:**

```bash
# Create Kubernetes Secret with service account token
kubectl create secret generic backstage-service-token \
  --from-literal=token=$(kubectl create token backstage-sa -n backstage)
```

---

## Error Codes

| HTTP Code                 | Meaning                 | Common Causes                                |
| ------------------------- | ----------------------- | -------------------------------------------- |
| 200 OK                    | Success                 | Valid request.                               |
| 201 Created               | Resource created        | Workspace or entity created.                 |
| 204 No Content            | Success (no data)       | Resource deleted.                            |
| 400 Bad Request           | Invalid request         | Malformed JSON, missing fields.              |
| 401 Unauthorized          | Authentication failed   | Invalid or missing token.                    |
| 403 Forbidden             | Permission denied       | User lacks access to resource.               |
| 404 Not Found             | Resource not found      | Invalid workspace ID, entity not in catalog. |
| 409 Conflict              | Resource already exists | Duplicate workspace or entity.               |
| 500 Internal Server Error | Server error            | Check Backstage backend logs.                |

---

## Rate Limits

- **User API Calls:** 100 requests/minute per user.
- **Service Token Calls:** 1000 requests/minute per token.

**Rate Limit Headers:**

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1672531260
```

---

## See Also

- [Backstage Official API Documentation](https://backstage.io/docs/features/software-catalog/software-catalog-api/)
- [Eclipse Che REST API](https://eclipse.dev/che/docs/stable/end-user-guide/che-devfile-v2/)
- [DevLake API Documentation](https://devlake.apache.org/docs/Overview/Introduction)
- [Service Catalog Reference](../catalogue/service-types.md)
