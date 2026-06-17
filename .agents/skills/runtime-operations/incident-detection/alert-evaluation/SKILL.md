---
name: alert-evaluation
description: "Evaluate alert rules and determine if an incident should be triggered. Use when checking Prometheus alert rules, validating severity, or triggering incident creation."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Alert Rule Evaluation

> **Load trigger:** `"load alert-evaluation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Evaluate alert rules and determine if an incident should be triggered.

## Responsibilities

- Evaluate Prometheus alert rules
- Validate severity
- Validate alert routing
- Trigger incident creation

## Inputs

- Alert rules (PrometheusRule resources)
- Metrics

## Outputs

- `alert-evaluation.json`

## Evaluation Rules

### Alert Validity

- [ ] Alert rule exists and is active
- [ ] Alert condition is met
- [ ] Alert duration threshold met (no flapping)
- [ ] Alert severity is appropriate

### Severity Validation

| Alert Severity | Incident Severity | Response          |
| -------------- | ----------------- | ----------------- |
| critical       | SEV1/SEV2         | Immediate         |
| warning        | SEV3/SEV4         | Within 1 hour     |
| info           | SEV5              | Next business day |

### Routing

- [ ] Alert routed to correct team
- [ ] Alert routed to correct channel
- [ ] Escalation policy followed

## Output Format

```json
{
  "skill": "alert-evaluation",
  "alerts_evaluated": 5,
  "alerts_triggered": [
    {
      "alert_name": "HighErrorRate",
      "severity": "critical",
      "condition": "error_rate > 0.05 for 5m",
      "current_value": 0.08,
      "incident_created": true,
      "incident_id": "INC-123"
    }
  ]
}
```

## Success Criteria

- Correct alert evaluation
- Incidents created for triggered alerts
- Severity validated
