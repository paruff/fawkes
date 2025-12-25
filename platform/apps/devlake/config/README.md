# Webhook Configuration for DORA Metrics

This directory contains webhook configurations and documentation for integrating GitHub, Jenkins, and ArgoCD with the DevLake DORA metrics service.

## Overview

Webhooks enable real-time event ingestion for DORA metrics calculation:

| Source | Events Captured | Metrics Impact |
|--------|----------------|----------------|
| **GitHub** | Commits, PR merges | Lead Time for Changes |
| **Jenkins** | Build results, tests, quality gates | Build success rate, rework, quality |
| **ArgoCD** | Deployment syncs, health status | Deployment Frequency, Change Failure Rate |
| **Observability** | Incidents | Mean Time to Restore |

## Quick Start

### 1. Deploy Webhook Configurations

```bash
# Apply webhook configuration
kubectl apply -f platform/apps/devlake/config/webhooks.yaml

# Apply ArgoCD notifications
kubectl apply -f platform/apps/devlake/config/argocd-notifications.yaml
```

### 2. Configure GitHub Webhook

Follow the detailed guide: [github-webhook-setup.md](github-webhook-setup.md)

**Quick steps:**
1. Get webhook secret from Kubernetes
2. Add webhook in GitHub repository settings
3. Point to: `https://devlake.fawkes.idp/api/plugins/webhook/1/commits`
4. Test with a commit push

### 3. Configure Jenkins Integration

Jenkins integration uses the `doraMetrics.groovy` shared library.

Follow the guide: [jenkins-webhook-setup.md](jenkins-webhook-setup.md)

**Quick integration:**
```groovy
@Library('fawkes-pipeline-library') _

pipeline {
    stages {
        stage('Build') {
            steps { sh 'mvn package' }
            post {
                success {
                    doraMetrics.recordBuild(
                        service: env.JOB_BASE_NAME,
                        status: 'success',
                        stage: 'build'
                    )
                }
            }
        }
    }
    post {
        always {
            doraMetrics.recordPipelineComplete(
                service: env.JOB_BASE_NAME
            )
        }
    }
}
```

### 4. Configure ArgoCD Notifications

ArgoCD notifications are configured via the ConfigMap in `argocd-notifications.yaml`.

**Verification:**
```bash
# Check ArgoCD notifications ConfigMap
kubectl get configmap argocd-notifications-cm -n argocd

# Test by triggering an ArgoCD sync
argocd app sync my-app
```

## Webhook Endpoints

All webhooks point to DevLake:

| Webhook | Endpoint | Source |
|---------|----------|--------|
| Commits | `/api/plugins/webhook/1/commits` | GitHub |
| CI/CD Events | `/api/plugins/webhook/1/cicd` | Jenkins |
| Deployments | `/api/plugins/webhook/1/deployments` | ArgoCD |
| Incidents | `/api/plugins/webhook/1/incidents` | Observability |

**Base URL (Production)**: `https://devlake.fawkes.idp`
**Base URL (Local Dev)**: `http://devlake.127.0.0.1.nip.io`

## Testing Webhooks

### Run Test Script

```bash
# Run comprehensive webhook tests
./scripts/test-dora-webhooks.sh
```

This tests:
- ✅ DevLake service is running
- ✅ Webhook endpoints are accessible
- ✅ GitHub webhook endpoint responds
- ✅ Jenkins webhook endpoint responds
- ✅ ArgoCD webhook endpoint responds
- ✅ Incident webhook endpoint responds
- ✅ Network policies allow ingress
- ✅ Configuration files exist

### Run BDD Tests

```bash
# Run BDD acceptance tests
cd tests/bdd
pytest features/dora-webhooks.feature -v
```

### Manual Testing

#### Test GitHub Webhook
```bash
# Get webhook secret
WEBHOOK_SECRET=$(kubectl get secret devlake-webhook-secrets -n fawkes-devlake \
  -o jsonpath='{.data.github-webhook-secret}' | base64 -d)

# Create test payload
PAYLOAD='{"ref":"refs/heads/main","commits":[{"id":"test123"}]}'

# Generate signature
SIGNATURE=$(echo -n "$PAYLOAD" | openssl dgst -sha256 -hmac "$WEBHOOK_SECRET" | awk '{print $2}')

# Send webhook
curl -X POST https://devlake.fawkes.idp/api/plugins/webhook/1/commits \
  -H "Content-Type: application/json" \
  -H "X-Hub-Signature-256: sha256=$SIGNATURE" \
  -H "X-GitHub-Event: push" \
  -d "$PAYLOAD"
```

#### Test Jenkins Webhook
```bash
curl -X POST http://devlake.fawkes-devlake.svc:8080/api/plugins/webhook/1/cicd \
  -H "Content-Type: application/json" \
  -d '{
    "service": "test-service",
    "commit_sha": "abc123",
    "status": "success",
    "stage": "build",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

#### Test ArgoCD Webhook
```bash
curl -X POST http://devlake.fawkes-devlake.svc:8080/api/plugins/webhook/1/deployments \
  -H "Content-Type: application/json" \
  -H "X-Webhook-Source: argocd" \
  -d '{
    "event_type": "deployment",
    "status": "success",
    "application": "test-app",
    "revision": "abc123",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
  }'
```

## Monitoring Webhooks

### Check Webhook Delivery

**GitHub**: Repository → Settings → Webhooks → Recent Deliveries

**Jenkins**: Check console output for DORA messages:
```
✅ DORA: Build event recorded for payment-service (build)
```

**ArgoCD**: Check ArgoCD notifications logs:
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller
```

### Prometheus Metrics

Query webhook metrics in Prometheus:

```promql
# Total webhook requests
devlake_webhook_requests_total{source="github"}
devlake_webhook_requests_total{source="jenkins"}
devlake_webhook_requests_total{source="argocd"}

# Webhook errors
devlake_webhook_errors_total

# Webhook latency
histogram_quantile(0.95, devlake_webhook_duration_seconds_bucket)
```

### Grafana Dashboard

View webhook health:
1. Open Grafana: `http://devlake-grafana.127.0.0.1.nip.io`
2. Navigate to **DevLake Webhooks** dashboard
3. View request rates, error rates, and latency

## Troubleshooting

### GitHub Webhooks Not Firing

1. **Check webhook in GitHub**: Settings → Webhooks → Recent Deliveries
2. **Common issues**:
   - ❌ Response 404: Verify URL is correct
   - ❌ Response 401: Check webhook secret
   - ❌ Timeout: DevLake may be overloaded

### Jenkins Events Not Sending

1. **Check doraMetrics calls**: Search Jenkinsfile for `doraMetrics.record`
2. **Check Jenkins logs**: `kubectl logs -n fawkes jenkins-0 | grep DORA`
3. **Test connectivity**: Add `sh 'curl http://devlake.fawkes-devlake.svc:8080/api/ping'` to pipeline

### ArgoCD Notifications Not Sending

1. **Check notifications ConfigMap**:
   ```bash
   kubectl get configmap argocd-notifications-cm -n argocd -o yaml
   ```

2. **Check notifications controller logs**:
   ```bash
   kubectl logs -n argocd -l app.kubernetes.io/name=argocd-notifications-controller
   ```

3. **Verify service is reachable**:
   ```bash
   kubectl run -it --rm debug --image=alpine -n argocd -- \
     wget -O- http://devlake.fawkes-devlake.svc:8080/api/ping
   ```

### Webhook Events Not in DevLake

1. **Check DevLake logs**:
   ```bash
   kubectl logs -n fawkes-devlake -l app.kubernetes.io/component=lake | grep webhook
   ```

2. **Check database**:
   ```bash
   kubectl exec -it -n fawkes-devlake devlake-mysql-0 -- mysql -u root -p lake
   ```
   ```sql
   SELECT * FROM commits ORDER BY authored_date DESC LIMIT 5;
   SELECT * FROM deployments ORDER BY created_at DESC LIMIT 5;
   SELECT * FROM cicd_deployments ORDER BY created_at DESC LIMIT 5;
   ```

3. **Query via API**:
   ```bash
   curl http://devlake.127.0.0.1.nip.io/api/commits?repo=paruff/fawkes
   ```

## Security

### Webhook Secrets

All webhook secrets are stored in Kubernetes secrets and managed via External Secrets Operator:

```bash
# View secrets (values are base64 encoded)
kubectl get secret devlake-webhook-secrets -n fawkes-devlake -o yaml
```

### Network Policies

Network policies control webhook ingress:
- GitHub webhooks: via ingress controller
- Jenkins webhooks: from `fawkes` namespace
- ArgoCD webhooks: from `argocd` namespace

### HMAC Validation

GitHub webhooks use HMAC-SHA256 signatures for validation. DevLake automatically validates the `X-Hub-Signature-256` header.

## Files

| File | Purpose |
|------|---------|
| `webhooks.yaml` | Central webhook configuration, secrets, network policies |
| `argocd-notifications.yaml` | ArgoCD notifications to send deployment events |
| `github-webhook-setup.md` | Step-by-step GitHub webhook configuration guide |
| `jenkins-webhook-setup.md` | Jenkins integration guide using doraMetrics library |
| `README.md` | This file - overview and quick start |

## Next Steps

After configuring webhooks:

1. **Wait for data collection** (30 minutes to 1 hour)
2. **View DORA metrics** in Grafana: `http://devlake-grafana.127.0.0.1.nip.io`
3. **Query metrics via API**:
   ```bash
   curl http://devlake.127.0.0.1.nip.io/api/dora/metrics?project=my-service
   ```
4. **Check DORA performance levels**: Elite, High, Medium, or Low

## Related Documentation

- [DORA Metrics API Reference](../../../docs/reference/dora-metrics-api.md)
- [DevLake Service README](../README.md)
- [DORA Metrics Implementation Playbook](../../../docs/playbooks/dora-metrics-implementation.md)
- [Architecture: DORA Metrics Service](../../../docs/architecture.md#6-dora-metrics-service)

## Support

- **Issues**: Create an issue in the Fawkes repository
- **Slack**: #fawkes-platform
- **Documentation**: https://github.com/paruff/fawkes/tree/main/docs
