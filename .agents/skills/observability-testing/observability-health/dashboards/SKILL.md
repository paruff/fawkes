---
name: dashboard-coverage-testing
description: "Ensure all critical services have dashboards with golden signals. Use when validating dashboard presence, golden signal charts, or alert panels."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Dashboard Coverage Testing

> **Load trigger:** `"load dashboard-coverage-testing skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure all critical services have dashboards with golden signals.

## Responsibilities

- Validate dashboard presence
- Validate golden signal charts
- Validate alert panels

## Inputs

- Grafana dashboards

## Outputs

- `dashboard-coverage.json`

## Required Dashboards

| Dashboard        | Required Panels                                               |
| ---------------- | ------------------------------------------------------------- |
| PIPE Overview    | Build duration, Build success rate, Active builds, Error rate |
| OBS Overview     | Reconcile duration, Queue depth, Reconcile errors             |
| GitOps Overview  | Sync duration, Pending syncs, Sync errors                     |
| Cluster Overview | Pod restarts, Request rate, 5xx rate, CPU/Memory              |
| Release Overview | Release frequency, Lead time, Change failure rate             |

## Panel Requirements

| Golden Signal | Panel Type                  | Metric                              |
| ------------- | --------------------------- | ----------------------------------- |
| Latency       | Time series (p50, p95, p99) | `_duration_seconds`                 |
| Traffic       | Rate                        | `_requests_total`                   |
| Errors        | Rate + Percentage           | `_errors_total` / `_requests_total` |
| Saturation    | Gauge                       | `_utilization_ratio`                |

## Validation Rules

- [ ] Dashboard exists per service
- [ ] All four golden signal panels present
- [ ] Panels use correct metrics
- [ ] Alert panels configured
- [ ] Time range appropriate

## Output Format

```json
{
  "skill": "dashboard-coverage-testing",
  "status": "pass | fail",
  "dashboards": {
    "pipe": { "present": true, "panels": 4, "missing": [] },
    "obs": { "present": true, "panels": 4, "missing": [] },
    "gitops": { "present": false, "panels": 0, "missing": ["all"] },
    "cluster": { "present": true, "panels": 3, "missing": ["saturation"] }
  }
}
```

## Success Criteria

- All services have dashboards
- All golden signal panels present
