---
name: runbook-selection
description: "Select the correct runbook based on incident classification. Use when matching incident type to runbook and validating applicability."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Runbook Selection

> **Load trigger:** `"load runbook-selection skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Select the correct runbook based on incident classification.

## Responsibilities

- Match incident type to runbook
- Validate runbook applicability
- Provide runbook metadata

## Inputs

- `triage-report.json`
- Runbook library index

## Outputs

- `selected-runbook.json`

## Selection Rules

### Incident Type → Runbook Mapping

| Incident Type        | Runbook             | Priority |
| -------------------- | ------------------- | -------- |
| Pod CrashLoopBackOff | restart-pod         | HIGH     |
| OOMKilled            | increase-memory     | HIGH     |
| Deployment unhealthy | rollback-deployment | HIGH     |
| Node not ready       | cordon-node         | MEDIUM   |
| Disk pressure        | cleanup-disk        | MEDIUM   |
| Service unreachable  | check-network       | LOW      |

### Applicability Validation

- [ ] Runbook exists for incident type
- [ ] Runbook is marked auto-executable
- [ ] Runbook prerequisites met
- [ ] No conflicting runbooks selected

### Confidence Levels

| Level  | Meaning                            | Action                  |
| ------ | ---------------------------------- | ----------------------- |
| HIGH   | Exact match to known incident type | Execute                 |
| MEDIUM | Likely match, some uncertainty     | Execute with validation |
| LOW    | Uncertain match                    | Escalate to human       |

## Output Format

```json
{
  "skill": "runbook-selection",
  "incident_type": "Pod CrashLoopBackOff",
  "selected_runbook": "restart-pod",
  "confidence": "HIGH",
  "auto_executable": true,
  "prerequisites_met": true,
  "estimated_duration": "30s"
}
```

## Success Criteria

- Correct runbook selected
- Applicability validated
- Confidence level assigned
