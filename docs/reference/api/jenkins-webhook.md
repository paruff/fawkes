---
title: Jenkins Webhook API
description: API reference for triggering Jenkins pipelines via webhooks
---

# Jenkins Webhook API

## Overview

The Jenkins Webhook API enables external systems (GitHub, GitLab, CI/CD orchestrators) to trigger pipeline builds programmatically. This API is used for event-driven automation and GitOps integration.

**Base URL:** `https://jenkins.fawkes.example.com`

**Authentication:** API Token or GitHub webhook secret validation.

---

## Endpoints

### POST /generic-webhook-trigger/invoke

Triggers a Jenkins job via the Generic Webhook Trigger plugin.

#### Request

**Method:** `POST`

**URL:** `/generic-webhook-trigger/invoke`

**Headers:**

| Header                | Required | Description                                       |
| --------------------- | -------- | ------------------------------------------------- |
| `Content-Type`        | Yes      | Must be `application/json`.                       |
| `X-GitHub-Event`      | No       | GitHub event type (for GitHub webhooks).          |
| `X-Hub-Signature-256` | No       | HMAC signature for webhook verification (GitHub). |

**Query Parameters:**

| Parameter | Type   | Required | Description                              |
| --------- | ------ | -------- | ---------------------------------------- |
| `token`   | String | Yes      | Webhook token configured in Jenkins job. |

**Request Body (JSON):**

```json
{
  "repository": {
    "name": "my-service",
    "url": "https://github.com/paruff/my-service",
    "clone_url": "https://github.com/paruff/my-service.git"
  },
  "ref": "refs/heads/main",
  "before": "abc123...",
  "after": "def456...",
  "commits": [
    {
      "id": "def456...",
      "message": "feat: add new feature",
      "author": {
        "name": "Developer",
        "email": "dev@example.com"
      }
    }
  ]
}
```

#### Response

**Success (200 OK):**

```json
{
  "jobs": {
    "my-service-pipeline": {
      "triggered": true,
      "url": "https://jenkins.fawkes.example.com/job/my-service-pipeline/123/",
      "buildNumber": 123
    }
  }
}
```

**Error (400 Bad Request):**

```json
{
  "message": "Missing required parameter: token"
}
```

**Error (401 Unauthorized):**

```json
{
  "message": "Invalid webhook token"
}
```

---

### POST /job/{jobName}/build

Triggers a Jenkins job directly (requires authentication).

#### Request

**Method:** `POST`

**URL:** `/job/{jobName}/build`

**Headers:**

| Header          | Required | Description                                      |
| --------------- | -------- | ------------------------------------------------ |
| `Authorization` | Yes      | Basic Auth (`username:apiToken` Base64 encoded). |

**Query Parameters:**

| Parameter | Type    | Required | Description                                          |
| --------- | ------- | -------- | ---------------------------------------------------- |
| `token`   | String  | No       | Build token (if configured in job).                  |
| `delay`   | Integer | No       | Delay before starting build (seconds). Default: `0`. |

**Request Body:**

None for parameterless jobs. For parameterized jobs, send form data:

```
BRANCH=main
ENVIRONMENT=dev
```

#### Response

**Success (201 Created):**

```json
{
  "location": "https://jenkins.fawkes.example.com/queue/item/456/"
}
```

**Response Headers:**

- `Location`: URL to the queued build item.

**Error (401 Unauthorized):**

```json
{
  "message": "Authentication required"
}
```

---

### POST /job/{jobName}/buildWithParameters

Triggers a parameterized Jenkins job.

#### Request

**Method:** `POST`

**URL:** `/job/{jobName}/buildWithParameters`

**Headers:**

| Header          | Required | Description                                                |
| --------------- | -------- | ---------------------------------------------------------- |
| `Authorization` | Yes      | Basic Auth (`username:apiToken` Base64 encoded).           |
| `Content-Type`  | Yes      | `application/x-www-form-urlencoded` or `application/json`. |

**Request Body (Form Data):**

```
BRANCH=main
ENVIRONMENT=prod
IMAGE_TAG=v1.2.3
```

**Request Body (JSON):**

```json
{
  "parameter": [
    { "name": "BRANCH", "value": "main" },
    { "name": "ENVIRONMENT", "value": "prod" },
    { "name": "IMAGE_TAG", "value": "v1.2.3" }
  ]
}
```

#### Response

**Success (201 Created):**

Headers include `Location: /queue/item/789/`.

**Error (400 Bad Request):**

```json
{
  "message": "Missing required parameter: BRANCH"
}
```

---

### GET /job/{jobName}/lastBuild/api/json

Retrieves status of the last build.

#### Request

**Method:** `GET`

**URL:** `/job/{jobName}/lastBuild/api/json`

**Headers:**

| Header          | Required | Description |
| --------------- | -------- | ----------- |
| `Authorization` | Yes      | Basic Auth. |

#### Response

**Success (200 OK):**

```json
{
  "number": 123,
  "result": "SUCCESS",
  "building": false,
  "duration": 45000,
  "timestamp": 1672531200000,
  "url": "https://jenkins.fawkes.example.com/job/my-service/123/",
  "changeSet": {
    "items": [
      {
        "commitId": "def456...",
        "msg": "feat: add new feature",
        "author": {
          "fullName": "Developer"
        }
      }
    ]
  }
}
```

**Build Results:**

- `SUCCESS`: Build completed successfully.
- `FAILURE`: Build failed.
- `UNSTABLE`: Build succeeded but has test failures or warnings.
- `ABORTED`: Build was manually stopped.
- `null`: Build is still running.

---

## Authentication

### API Token

Generate an API token in Jenkins:

1. Navigate to **User Menu → Configure**.
2. Under **API Token**, click **Add new Token**.
3. Copy the token (shown only once).

**Usage (cURL):**

```bash
curl -X POST https://jenkins.fawkes.example.com/job/my-service/build \
  -u username:apiToken
```

### GitHub Webhook Secret

Configure webhook secret in Jenkins job:

1. In job configuration, enable **Generic Webhook Trigger**.
2. Set **Token** to a random string.
3. In GitHub repository settings, add webhook:
   - **URL:** `https://jenkins.fawkes.example.com/generic-webhook-trigger/invoke?token=<TOKEN>`
   - **Secret:** (Optional) HMAC signature validation.

---

## Example Workflows

### Trigger Pipeline from GitHub Push

**GitHub Webhook Configuration:**

- **Payload URL:** `https://jenkins.fawkes.example.com/generic-webhook-trigger/invoke?token=abc123xyz`
- **Content type:** `application/json`
- **Events:** `push`

**Jenkins Job Configuration (Jenkinsfile):**

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'python'
}
```

---

### Manual Build with Parameters

**cURL Command:**

```bash
curl -X POST https://jenkins.fawkes.example.com/job/my-service/buildWithParameters \
  -u username:apiToken \
  -d "BRANCH=feature/new-api" \
  -d "ENVIRONMENT=dev"
```

---

### Check Build Status

**cURL Command:**

```bash
curl -X GET https://jenkins.fawkes.example.com/job/my-service/lastBuild/api/json \
  -u username:apiToken
```

**Parse Result in Script:**

```bash
BUILD_RESULT=$(curl -s -u username:apiToken \
  https://jenkins.fawkes.example.com/job/my-service/lastBuild/api/json \
  | jq -r '.result')

if [ "$BUILD_RESULT" == "SUCCESS" ]; then
  echo "Build succeeded"
else
  echo "Build failed: $BUILD_RESULT"
fi
```

---

## Rate Limits

Jenkins does not enforce API rate limits by default. However, excessive requests may trigger throttling at the Ingress or firewall level.

**Best Practices:**

- Use webhook triggers instead of polling.
- Implement exponential backoff for retries.

---

## Error Codes

| HTTP Code                 | Meaning               | Common Causes                       |
| ------------------------- | --------------------- | ----------------------------------- |
| 200 OK                    | Request successful    | Valid request.                      |
| 201 Created               | Build queued          | Job triggered successfully.         |
| 400 Bad Request           | Invalid request       | Missing parameters, malformed JSON. |
| 401 Unauthorized          | Authentication failed | Invalid credentials or API token.   |
| 403 Forbidden             | Permission denied     | User lacks job trigger permissions. |
| 404 Not Found             | Job not found         | Invalid job name in URL.            |
| 500 Internal Server Error | Jenkins error         | Check Jenkins logs.                 |

---

## Security Best Practices

1. **Use API Tokens:** Never use passwords in scripts.
2. **Validate Webhook Signatures:** Use HMAC verification for GitHub webhooks.
3. **Restrict Trigger Permissions:** Limit who can trigger builds via RBAC.
4. **Use HTTPS Only:** Ensure all API calls use TLS encryption.
5. **Rotate Tokens Regularly:** Update API tokens every 90 days.

---

## See Also

- [Jenkins REST API Documentation](https://www.jenkins.io/doc/book/using/remote-access-api/)
- [Generic Webhook Trigger Plugin](https://plugins.jenkins.io/generic-webhook-trigger/)
- [Golden Path Usage Guide](../../golden-path-usage.md)
- [Jenkins Configuration Reference](../config/jenkins-values.md)
