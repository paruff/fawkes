---
name: incident-triage
description: "Classify incidents, determine severity, and identify likely root causes. Use when triaging incidents, classifying severity, or hypothesizing root causes."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Incident Triage

> **Load trigger:** `"load incident-triage skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Classify incidents, determine severity, and identify likely root causes.

## Responsibilities

- Classify incident severity
- Identify impacted services
- Identify likely root cause
- Generate triage summary

## Inputs

- `incident-detection.json`
- Logs
- Metrics

## Outputs

- `triage-report.json`
- `suspected-root-cause.txt`

## Sub-Skills

| Skill                        | Purpose                        |
| ---------------------------- | ------------------------------ |
| `incident-triage/severity`   | Assign severity levels         |
| `incident-triage/root-cause` | Generate root cause hypothesis |

## Triage Process

1. **Classify** — Determine incident type and severity
2. **Scope** — Identify all impacted services
3. **Prioritize** — Order response actions
4. **Hypothesize** — Generate root cause hypothesis
5. **Escalate** — Notify appropriate responders

## Severity Matrix

| Severity | Description                         | Response Time | Escalation    |
| -------- | ----------------------------------- | ------------- | ------------- |
| SEV1     | Complete outage, data loss          | 15 min        | Immediate     |
| SEV2     | Major feature broken, no workaround | 30 min        | Within 15 min |
| SEV3     | Feature degraded, workaround exists | 1 hour        | Within 30 min |
| SEV4     | Minor issue, low impact             | 4 hours       | Within 1 hour |
| SEV5     | Cosmetic, no user impact            | Next day      | None          |

## Output Format

```json
{
  "skill": "incident-triage",
  "incident_id": "INC-123",
  "severity": "SEV2",
  "impacted_services": ["payment-api", "checkout"],
  "suspected_root_cause": "Payment API returning 500 errors",
  "recommended_actions": [
    "Check payment API logs",
    "Validate database connectivity",
    "Check upstream dependency health"
  ]
}
```

## Success Criteria

- Accurate severity classification
- Impacted services identified
- Root cause hypothesis generated
