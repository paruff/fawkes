# Quick Wins

These five improvements can each be completed in a single sprint and will immediately
improve your team's DORA metrics and developer experience. Start with the one that
addresses your biggest pain point today.

## Quick Win 1: Measure Deployment Frequency

**Time**: 2–4 hours · **Impact**: Baseline DORA data, shows where you are today

You cannot improve what you cannot measure. DevLake ingests deployment events from
ArgoCD and calculates deployment frequency automatically.

```bash
# Check DevLake is deployed
kubectl get pods -n devlake

# Open the DORA dashboard in Grafana
make argocd-status ENVIRONMENT=dev
```

If deployments are not being recorded, follow the
[DevLake setup guide](../how-to/observability/view-dora-metrics-devlake.md).

## Quick Win 2: Add a Basic CI Pipeline

**Time**: 1 day · **Impact**: Catch bugs before production, reduce CFR

If your service does not yet have automated tests running on every PR, add a GitHub
Actions workflow or a `Jenkinsfile` that runs lint and unit tests.

```yaml
# .github/workflows/ci.yaml (minimal example)
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: pip install -r requirements.txt
      - run: pytest tests/unit --tb=short
```

See [GitHub Actions Workflows](../how-to/development/github-actions-workflows.md) for
the full Fawkes CI template.

## Quick Win 3: Containerise One Service

**Time**: 2–4 hours · **Impact**: Enables consistent deployments, reduces "works on my machine"

Pick your simplest service and add a `Dockerfile`. Use a multi-stage build to keep
the image small:

```dockerfile
FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY . .
USER nobody
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

## Quick Win 4: Add a Health Check and Basic Alert

**Time**: 2–3 hours · **Impact**: Detect failures before users report them

Add a `/health` endpoint to your service and a Prometheus alert that fires when it
stops returning 200:

```yaml
# PrometheusRule
- alert: ServiceDown
  expr: up{job="my-service"} == 0
  for: 1m
  annotations:
    summary: "{{ $labels.job }} is not responding"
```

Then connect the alert to your team's Mattermost channel via Alertmanager.

## Quick Win 5: First GitOps Deployment

**Time**: 1 day · **Impact**: Eliminates manual deployment steps, makes deployments auditable

Move your service from `kubectl apply` to ArgoCD-managed GitOps in one sprint:

1. Package your deployment as a Helm chart (use the Backstage template as a starting point)
2. Add an ArgoCD `Application` manifest to `platform/apps/`
3. Commit → ArgoCD syncs → deployment is automated forever after

Follow [Onboard a Service to ArgoCD](../how-to/gitops/onboard-service-argocd.md).

## Next Steps

After completing these quick wins, revisit your [capability assessment](assessment.md)
and choose your [implementation path](implementation-paths.md) for the next quarter.

## See Also

- [Tutorials](../tutorials/index.md)
- [Getting Started](../getting-started.md)
