---
name: auto-remediation
description: "Automatically fix common operational issues without human intervention. Use when detecting known failure signatures and triggering remediation actions."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Auto-Remediation

> **Load trigger:** `"load auto-remediation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Automatically fix common operational issues without human intervention.

## Responsibilities

- Detect known failure signatures
- Trigger remediation actions
- Validate post-remediation health
- Escalate if remediation fails

## Inputs

- Incident data
- Health metrics
- Runbooks

## Outputs

- `remediation-report.json`
- `remediation-actions.txt`

## Sub-Skills

| Skill                                 | Purpose                         |
| ------------------------------------- | ------------------------------- |
| `auto-remediation/signature-matching` | Identify known failure patterns |
| `auto-remediation/action-execution`   | Execute remediation actions     |

## Remediation Actions

| Action                | Trigger                       | Risk   |
| --------------------- | ----------------------------- | ------ |
| Restart pod           | CrashLoopBackOff              | Low    |
| Rollback deployment   | Health check failure          | Low    |
| GitOps reconciliation | Config drift                  | Low    |
| Scale up              | Resource exhaustion           | Medium |
| Clear stuck resource  | Resource stuck in terminating | Low    |

## Safety Rules

- [ ] Maximum remediation attempts: 3
- [ ] Escalate after 2 failed attempts
- [ ] Log all remediation actions
- [ ] Validate health after each action
- [ ] No auto-remediation for CRITICAL severity without human approval

## Output Format

```json
{
  "skill": "auto-remediation",
  "status": "remediated | escalated | failed",
  "incident_id": "INC-123",
  "actions_taken": [
    {
      "action": "restart-pod",
      "target": "pod/my-app-abc123",
      "result": "success",
      "timestamp": "2025-01-15T10:30:00Z"
    }
  ],
  "post_remediation_health": "healthy"
}
```

## Success Criteria

- Successful automated remediation
- Health restored after remediation
- Actions logged and auditable
