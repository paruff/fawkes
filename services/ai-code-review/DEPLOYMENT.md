# AI Code Review Service - Deployment Guide

## Prerequisites

Before deploying the AI Code Review Service, ensure you have:

1. **Kubernetes cluster** with ArgoCD installed
2. **GitHub Personal Access Token** with repo and PR permissions
3. **LLM API Key** (OpenAI GPT-4 or Anthropic Claude)
4. **RAG Service** deployed (optional but recommended)
5. **SonarQube** instance (optional)

## Quick Start

### 1. Configure Secrets

Update the secrets in `k8s/secret.yaml`:

```bash
cd services/ai-code-review/k8s

# Create a copy of the secret file
cp secret.yaml secret-local.yaml

# Edit the secret with your actual values
# DO NOT commit secret-local.yaml to git
vim secret-local.yaml
```

Replace the following values:

- `GITHUB_WEBHOOK_SECRET`: Generate with `openssl rand -hex 20`
- `GITHUB_TOKEN`: Your GitHub Personal Access Token
- `LLM_API_KEY`: Your OpenAI or Anthropic API key
- `SONARQUBE_TOKEN`: Your SonarQube token (if using)

### 2. Deploy with ArgoCD

The service is configured to deploy automatically via ArgoCD:

```bash
# Apply the ArgoCD application manifest
kubectl apply -f platform/apps/ai-code-review-application.yaml

# Check deployment status
kubectl get app ai-code-review -n fawkes

# View service pods
kubectl get pods -n fawkes -l app=ai-code-review

# Check logs
kubectl logs -n fawkes -l app=ai-code-review --tail=100
```

### 3. Configure GitHub Webhook

1. Go to your repository settings → Webhooks
2. Click "Add webhook"
3. Configure:
   - **Payload URL**: `https://your-domain.com/webhook/github`
   - **Content type**: `application/json`
   - **Secret**: Same value as `GITHUB_WEBHOOK_SECRET`
   - **Events**: Select "Pull requests"
   - **Active**: ✓

### 4. Test the Integration

Create a test pull request:

```bash
# Create a test branch
git checkout -b test/ai-review

# Make a small change
echo "# Test" >> README.md

# Commit and push
git add README.md
git commit -m "Test AI review"
git push origin test/ai-review

# Create PR via GitHub CLI
gh pr create --title "Test AI Review" --body "Testing automated code review"

# Check PR for AI review comments
gh pr view --json reviews
```

## Configuration Options

### Environment Variables

| Variable                   | Description                               | Required | Default                                      |
| -------------------------- | ----------------------------------------- | -------- | -------------------------------------------- |
| `GITHUB_WEBHOOK_SECRET`    | Secret for webhook signature verification | Yes      | -                                            |
| `GITHUB_TOKEN`             | GitHub PAT for API access                 | Yes      | -                                            |
| `LLM_API_KEY`              | OpenAI or Anthropic API key               | Yes      | -                                            |
| `LLM_API_URL`              | LLM API endpoint                          | No       | `https://api.openai.com/v1/chat/completions` |
| `LLM_MODEL`                | Model to use                              | No       | `gpt-4`                                      |
| `RAG_SERVICE_URL`          | RAG service endpoint                      | No       | `http://rag-service.fawkes.svc:8000`         |
| `SONARQUBE_URL`            | SonarQube server URL                      | No       | `http://sonarqube.fawkes.svc:9000`           |
| `SONARQUBE_TOKEN`          | SonarQube API token                       | No       | -                                            |
| `FALSE_POSITIVE_THRESHOLD` | Confidence threshold for filtering        | No       | `0.8`                                        |

### Adjusting Resource Limits

Edit `k8s/deployment.yaml` to adjust resource requests/limits:

```yaml
resources:
  requests:
    memory: "256Mi" # Increase for larger PRs
    cpu: "200m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

### Scaling

Adjust replica count in `k8s/deployment.yaml`:

```yaml
spec:
  replicas: 2 # Increase for higher throughput
```

## Monitoring

### Prometheus Metrics

The service exposes metrics at `/metrics`:

```bash
# Port forward to access metrics locally
kubectl port-forward -n fawkes svc/ai-code-review 8000:8000

# View metrics
curl http://localhost:8000/metrics
```

Key metrics:

- `ai_review_webhooks_total` - Webhook events received
- `ai_review_reviews_total` - Reviews performed
- `ai_review_duration_seconds` - Review duration
- `ai_review_comments_total` - Comments posted
- `ai_review_false_positive_rate` - Estimated FP rate

### Logs

View service logs:

```bash
# Follow logs
kubectl logs -n fawkes -l app=ai-code-review -f

# View recent logs
kubectl logs -n fawkes -l app=ai-code-review --tail=100

# Logs from specific pod
kubectl logs -n fawkes <pod-name>
```

## Troubleshooting

### Service Not Starting

Check pod status and events:

```bash
kubectl describe pod -n fawkes -l app=ai-code-review
```

Common issues:

- **ImagePullBackOff**: Build and push Docker image
- **CrashLoopBackOff**: Check logs for errors
- **Pending**: Check resource availability

### Webhook Not Triggering

1. Check GitHub webhook delivery status
2. Verify webhook URL is accessible
3. Check webhook signature secret matches
4. Review service logs for errors

### No Review Comments Posted

1. Verify `GITHUB_TOKEN` has correct permissions
2. Check LLM API key is valid and has quota
3. Review logs for API errors
4. Verify PR has actual code changes

### High False Positive Rate

1. Adjust `FALSE_POSITIVE_THRESHOLD` (higher = more filtering)
2. Improve prompt templates in `prompts/`
3. Add more context via RAG service
4. Review and tune LLM model parameters

## Security Best Practices

1. **Never commit secrets** to git
2. **Use External Secrets Operator** for production
3. **Rotate tokens regularly** (GitHub, LLM API, SonarQube)
4. **Enable webhook signature verification**
5. **Review LLM API usage** to control costs
6. **Monitor for abnormal activity**

## Updating

### Update Docker Image

```bash
cd services/ai-code-review
./build.sh

# Tag for registry
docker tag ai-code-review:latest your-registry/ai-code-review:v0.2.0

# Push to registry
docker push your-registry/ai-code-review:v0.2.0

# Update deployment
kubectl set image deployment/ai-code-review -n fawkes \
  ai-code-review=your-registry/ai-code-review:v0.2.0
```

### Update via GitOps

```bash
# Update image tag in k8s/deployment.yaml
vim k8s/deployment.yaml

# Commit and push
git add k8s/deployment.yaml
git commit -m "Update AI code review service to v0.2.0"
git push

# ArgoCD will automatically sync
```

## Uninstalling

```bash
# Delete ArgoCD application
kubectl delete -f platform/apps/ai-code-review-application.yaml

# Manually delete resources if needed
kubectl delete all -n fawkes -l app=ai-code-review
kubectl delete configmap,secret -n fawkes -l app=ai-code-review
```

## Support

- **Documentation**: See `README.md` in service directory
- **Issues**: GitHub Issues
- **Slack**: #ai-tools channel
- **Email**: platform-team@fawkes.idp
