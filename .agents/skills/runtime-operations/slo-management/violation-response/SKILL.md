---
name: slo-violation-response
description: "Trigger automated actions when SLOs are violated. Use when detecting violations, triggering rollback, or escalating to humans."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: SLO Violation Response

> **Load trigger:** `"load slo-violation-response skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Trigger automated actions when SLOs are violated.

## Responsibilities

- Detect SLO violation
- Trigger rollback
- Trigger auto-remediation
- Escalate if needed

## Inputs

- `error-budget.json`
- SLO definitions

## Outputs

- `slo-violation.json`

## Response Matrix

| Severity | Burn Rate | Action                     |
| -------- | --------- | -------------------------- |
| CRITICAL | > 14.4x   | Immediate rollback + alert |
| HIGH     | > 6x      | Prepare rollback + alert   |
| MEDIUM   | > 3x      | Investigate + monitor      |
| LOW      | > 1x      | Monitor only               |

## Response Actions

### Immediate Rollback

```
1. Identify current deployment version
2. Compare to previous healthy version
3. Trigger rollback via GitOps
4. Validate rollback health
5. Alert team
```

### Prepare Rollback

```
1. Identify current deployment version
2. Validate previous version is healthy
3. Stage rollback (don't execute)
4. Alert team for decision
```

### Investigate

```
1. Collect metrics and logs
2. Identify correlated changes
3. Alert team with context
4. Monitor for escalation
```

## Safety Rules

- [ ] Rollback only to known healthy version
- [ ] Validate health after rollback
- [ ] Maximum 1 rollback per hour (prevent rollback loops)
- [ ] Escalate after 2 failed rollbacks

## Output Format

```json
{
  "skill": "slo-violation-response",
  "slo": "availability",
  "violation": {
    "target": 99.9,
    "actual": 98.5,
    "burn_rate": 20,
    "severity": "CRITICAL"
  },
  "response": {
    "action": "immediate-rollback",
    "from_version": "v1.2.3",
    "to_version": "v1.2.2",
    "result": "success",
    "health_after": "healthy"
  }
}
```

## Success Criteria

- Violations detected promptly
- Response actions executed safely
- Health restored after response
