# ============================================================

# GitHub Webhook Configuration for DORA Metrics

# ============================================================

# This document provides instructions for configuring GitHub

# webhooks to send commit events to DevLake for DORA metrics

#

# Events captured

# - Push events → Commit tracking for lead time

# - Pull request merged → Release preparation tracking

# ============================================================

## Overview

GitHub webhooks send real-time events to DevLake when code is pushed or PRs are merged. This data is used to calculate **Lead Time for Changes** by tracking the time from commit to deployment.

## Prerequisites

- [ ] DevLake deployed and accessible
- [ ] GitHub repository admin access
- [ ] Webhook secret configured in Vault/External Secrets
- [ ] Ingress configured for external GitHub access

## Webhook Endpoint

**Production URL**: `https://devlake.fawkes.idp/api/plugins/webhook/1/commits`
**Local Dev URL**: `http://devlake.127.0.0.1.nip.io/api/plugins/webhook/1/commits`

## GitHub Webhook Configuration

### Step 1: Get Webhook Secret

```bash
# Get the webhook secret from Kubernetes
kubectl get secret devlake-webhook-secrets -n fawkes-devlake \
  -o jsonpath='{.data.github-webhook-secret}' | base64 -d

# Save this secret - you'll need it in GitHub settings
```

### Step 2: Configure in GitHub Repository

1. Navigate to your repository on GitHub
2. Go to **Settings** → **Webhooks** → **Add webhook**

3. Configure the webhook:

   - **Payload URL**: `https://devlake.fawkes.idp/api/plugins/webhook/1/commits`
   - **Content type**: `application/json`
   - **Secret**: (paste the secret from Step 1)
   - **SSL verification**: Enable SSL verification (production)
   - **Which events**: Select individual events:
     - ✅ Pushes
     - ✅ Pull requests
   - **Active**: ✅ Enabled

4. Click **Add webhook**

### Step 3: Test Webhook

1. After creating the webhook, GitHub sends a test ping
2. Check **Recent Deliveries** tab in webhook settings
3. Verify the ping returned a `200 OK` response

Or manually test:

```bash
# Make a test commit
git commit --allow-empty -m "test: webhook test"
git push origin main

# Check webhook delivery in GitHub
# Settings → Webhooks → Recent Deliveries

# Check DevLake received the event
kubectl logs -n fawkes-devlake -l app.kubernetes.io/component=lake | grep "webhook"
```

## Webhook Payload Example

GitHub sends payloads like this:

```json
{
  "ref": "refs/heads/main",
  "before": "abc123...",
  "after": "def456...",
  "repository": {
    "name": "fawkes",
    "full_name": "paruff/fawkes",
    "html_url": "https://github.com/paruff/fawkes"
  },
  "pusher": {
    "name": "developer",
    "email": "dev@example.com"
  },
  "commits": [
    {
      "id": "def456...",
      "message": "feat: add new feature",
      "timestamp": "2024-12-15T10:30:00Z",
      "author": {
        "name": "Developer",
        "email": "dev@example.com"
      },
      "added": ["file1.py"],
      "modified": ["file2.py"],
      "removed": []
    }
  ]
}
```

DevLake processes this to extract:

- Commit SHA
- Author
- Timestamp (for lead time start)
- Branch/repository info

## Organization-Level Webhook

For multiple repositories, configure an **organization webhook**:

1. Go to GitHub Organization **Settings**
2. Navigate to **Webhooks** → **Add webhook**
3. Use the same configuration as above
4. This webhook will receive events from all repos in the org

## Security Considerations

### Webhook Secret Validation

DevLake validates webhook signatures using HMAC-SHA256:

```
X-Hub-Signature-256: sha256=<signature>
```

The signature is computed as:

```
HMAC-SHA256(webhook-secret, request-body)
```

DevLake automatically validates this header before processing events.

### Network Security

**Production**: Use HTTPS with valid TLS certificate

**Firewall Rules**: Allow GitHub webhook IPs

```
# GitHub webhook IP ranges (check GitHub meta API for latest)
192.30.252.0/22
185.199.108.0/22
140.82.112.0/20
143.55.64.0/20
```

### Rate Limiting

DevLake webhook endpoint has rate limits:

- 1000 requests per minute per IP
- 10000 requests per hour per repository

## Troubleshooting

### Webhook Deliveries Failing

**Check Recent Deliveries** in GitHub webhook settings:

1. **Response code 404**:

   - Verify webhook URL is correct
   - Check DevLake service is running
   - Verify ingress route is configured

2. **Response code 401/403**:

   - Verify webhook secret matches
   - Check signature validation

3. **Timeout**:
   - DevLake may be overloaded
   - Check pod resources: `kubectl top pod -n fawkes-devlake`

### Webhook Not Receiving Events

```bash
# Check DevLake logs
kubectl logs -n fawkes-devlake -l app.kubernetes.io/component=lake -f

# Test webhook endpoint manually
WEBHOOK_SECRET=$(kubectl get secret devlake-webhook-secrets -n fawkes-devlake \
  -o jsonpath='{.data.github-webhook-secret}' | base64 -d)

# Generate HMAC signature
PAYLOAD='{"test": "data"}'
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | awk '{print $2}')

# Send test request
curl -X POST https://devlake.fawkes.idp/api/plugins/webhook/1/commits \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "X-GitHub-Event: push" \
  -d "$PAYLOAD"
```

### Verifying Data in Database

```bash
# Connect to DevLake database
kubectl exec -it -n fawkes-devlake devlake-mysql-0 -- mysql -u root -p lake

# Check recent commits
SELECT * FROM commits ORDER BY authored_date DESC LIMIT 10;

# Check commit count
SELECT COUNT(*) FROM commits;
```

## Monitoring

### Webhook Metrics

DevLake exposes Prometheus metrics for webhooks:

```promql
# Webhook requests received
devlake_webhook_requests_total{source="github",endpoint="commits"}

# Webhook processing duration
devlake_webhook_duration_seconds{source="github"}

# Webhook errors
devlake_webhook_errors_total{source="github"}
```

### Grafana Dashboard

View webhook health in Grafana:

- Dashboard: **DevLake Webhooks**
- Panels: Request rate, error rate, latency

## Multiple Repositories

To configure webhooks for multiple repositories:

### Option 1: Organization Webhook (Recommended)

Configure once at organization level - covers all repos

### Option 2: Bulk Configuration via API

```bash
# GitHub API token with admin:repo_hook scope
GITHUB_TOKEN="ghp_your_token"
ORG="paruff"
WEBHOOK_URL="https://devlake.fawkes.idp/api/plugins/webhook/1/commits"
WEBHOOK_SECRET="your-webhook-secret"

# Get all repos in org
REPOS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/orgs/$ORG/repos?per_page=100" | jq -r '.[].name')

# Create webhook for each repo
for REPO in $REPOS; do
  echo "Configuring webhook for $REPO..."
  curl -X POST \
    -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.github.com/repos/$ORG/$REPO/hooks" \
    -d "{
      \"name\": \"web\",
      \"active\": true,
      \"events\": [\"push\", \"pull_request\"],
      \"config\": {
        \"url\": \"$WEBHOOK_URL\",
        \"content_type\": \"json\",
        \"secret\": \"$WEBHOOK_SECRET\",
        \"insecure_ssl\": \"0\"
      }
    }"
done
```

### Option 3: Terraform Configuration

```hcl
# terraform/github-webhooks.tf
resource "github_repository_webhook" "devlake" {
  for_each   = toset(var.repositories)
  repository = each.value

  configuration {
    url          = "https://devlake.fawkes.idp/api/plugins/webhook/1/commits"
    content_type = "json"
    secret       = var.webhook_secret
    insecure_ssl = false
  }

  events = ["push", "pull_request"]
  active = true
}
```

## Validation

### Verify Webhook is Working

1. **Make a test commit**:

   ```bash
   git commit --allow-empty -m "test: DORA webhook validation"
   git push origin main
   ```

2. **Check GitHub delivery**:

   - Go to repository → Settings → Webhooks
   - Click on the webhook
   - Check "Recent Deliveries" tab
   - Verify response is `200 OK`

3. **Check DevLake logs**:

   ```bash
   kubectl logs -n fawkes-devlake -l app.kubernetes.io/component=lake | grep "commit.*received"
   ```

4. **Query DevLake API**:

   ```bash
   curl -X GET "http://devlake.127.0.0.1.nip.io/api/commits?repo=paruff/fawkes" \
     -H "Authorization: Bearer $DEVLAKE_TOKEN"
   ```

5. **Check database**:
   ```sql
   SELECT sha, message, authored_date
   FROM commits
   WHERE repo_name = 'paruff/fawkes'
   ORDER BY authored_date DESC
   LIMIT 5;
   ```

## Related Documentation

- [DevLake Webhooks Configuration](webhooks.yaml)
- [DORA Metrics API Reference](../../../docs/reference/dora-metrics-api.md)
- [GitHub Webhooks Documentation](https://docs.github.com/en/developers/webhooks-and-events/webhooks)
- [DevLake Plugin: Webhook](https://devlake.apache.org/docs/Plugins/webhook)
