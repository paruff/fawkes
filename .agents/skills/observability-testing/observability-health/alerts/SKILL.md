---
name: alert-coverage-testing
description: "Ensure all critical failure modes have alerts. Use when validating alert rules, alert severity, or alert routing."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Alert Coverage Testing

> **Load trigger:** `"load alert-coverage-testing skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure all critical failure modes have alerts.

## Responsibilities

- Validate alert rules
- Validate alert severity
- Validate alert routing

## Inputs

- Prometheus alert rules

## Outputs

- `alert-coverage.json`

## Required Alerts

| Alert                  | Severity | Threshold        | Service |
| ---------------------- | -------- | ---------------- | ------- |
| `BuildFailureRateHigh` | critical | > 10% for 5m     | PIPE    |
| `BuildDurationHigh`    | warning  | p95 > 10m for 5m | PIPE    |
| `ReconcileErrorsHigh`  | critical | > 5 for 5m       | OBS     |
| `ReconcileLatencyHigh` | warning  | p95 > 30s for 5m | OBS     |
| `SyncErrorsHigh`       | critical | > 3 for 5m       | GitOps  |
| `PodRestartRateHigh`   | critical | > 3 for 10m      | Cluster |
| `ErrorRateHigh`        | critical | > 5% for 5m      | All     |
| `SLOBudgetExhausted`   | critical | < 10% remaining  | All     |

## Severity Levels

| Level    | Response Time     | Notification      |
| -------- | ----------------- | ----------------- |
| critical | < 15 min          | PagerDuty + Slack |
| warning  | < 1 hour          | Slack             |
| info     | Next business day | Log only          |

## Validation Rules

- [ ] All required alerts defined
- [ ] Severity levels correct
- [ ] Thresholds reasonable
- [ ] Routing configured
- [ ] Runbooks linked

## Output Format

```json
{
  "skill": "alert-coverage-testing",
  "status": "pass | fail",
  "total_alerts": 15,
  "required_alerts": 8,
  "present_alerts": 7,
  "missing_alerts": ["SLOBudgetExhausted"],
  "severity_distribution": {
    "critical": 5,
    "warning": 2,
    "info": 0
  },
  "issues": ["SLOBudgetExhausted alert missing"]
}
```

## Success Criteria

- All critical alerts present
- Severity levels appropriate
- Routing configured
