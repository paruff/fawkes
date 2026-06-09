---
name: dora-instrumentor
description: Add DORA metrics instrumentation to GitHub Actions workflows — job timestamps, deployment tracking, lead time calculation. Load when adding DORA logging to workflows.
license: MIT
compatibility: opencode
---

# DORA Instrumentor — Fawkes

## What DORA metrics we track

| Metric                    | Source               | How                                      |
| ------------------------- | -------------------- | ---------------------------------------- |
| **Deployment Frequency**  | ArgoCD sync events   | `dora_deployments_total` counter         |
| **Lead Time for Changes** | Git push → deploy    | `dora_lead_time_seconds` histogram       |
| **Change Failure Rate**   | ArgoCD sync failures | `dora_deployment_failures_total` counter |
| **Mean Time to Restore**  | Incident → resolve   | `dora_mttr_seconds` histogram            |

## Required DORA timestamps

Every workflow job MUST have start and finish timestamps:

```yaml
steps:
  - name: DORA job start
    run: |
      echo "job-start:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      echo "sha:${{ github.sha }}"
      echo "workflow:${{ github.workflow }}"
      echo "job:${{ github.job }}"

  # ... actual steps ...

  - name: DORA job finish
    if: always()
    run: echo "job-finish:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## Deployment event format

For deployment jobs, emit a structured event:

```yaml
- name: Emit deployment event
  if: success() && github.ref == 'refs/heads/main'
  run: |
    echo "::deployment::"
    echo "service=${{ matrix.service }}"
    echo "environment=production"
    echo "commit_sha=${{ github.sha }}"
    echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## Lead time calculation

Lead time = `deploy_timestamp - first_commit_timestamp`

First commit timestamp is captured in the earliest workflow job. The deployment
timestamp is captured when ArgoCD reports sync complete.

```yaml
- name: Record lead time start
  if: github.event_name == 'push'
  run: |
    echo "lead-time-start=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$GITHUB_ENV"
```

## DORA metrics exporter

`services/dora-metrics/` queries:

- ArgoCD API: `GET /api/v1/applications` for sync status
- GitHub API: `GET /repos/{owner}/{repo}/actions/runs` for workflow runs

Prometheus metrics exposed on port 8000:

- `dora_deployments_total{service, environment, status}`
- `dora_lead_time_seconds{service, environment}`
- `dora_deployment_failures_total{service, environment, reason}`
- `dora_mttr_seconds{service, environment}`

## Validate

```bash
# Check all workflows have DORA timestamps
for f in .github/workflows/*.yml; do
  grep -q "DORA job start" "$f" || echo "MISSING start: $f"
  grep -q "DORA job finish" "$f" || echo "MISSING finish: $f"
done

# Check finish timestamps have if: always()
grep -A1 "DORA job finish" .github/workflows/*.yml | grep "if: always()"
```
