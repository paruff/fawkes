---
name: severity-classification
description: "Assign severity levels (SEV1–SEV5) to incidents. Use when evaluating impact, blast radius, error budget burn rate, or assigning severity."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Severity Classification

> **Load trigger:** `"load severity-classification skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Assign severity levels (SEV1–SEV5) to incidents.

## Responsibilities

- Evaluate impact
- Evaluate blast radius
- Evaluate error budget burn rate
- Assign severity

## Inputs

- Incident data
- Impact analysis
- Error budget data

## Outputs

- `severity.json`

## Severity Rules

### Impact Factors

| Factor         | Low   | Medium      | High     |
| -------------- | ----- | ----------- | -------- |
| Users affected | < 10% | 10-50%      | > 50%    |
| Revenue impact | None  | < $1K/hr    | > $1K/hr |
| Data loss      | None  | Partial     | Complete |
| SLA breach     | No    | Approaching | Yes      |

### Blast Radius

| Scope             | Severity  |
| ----------------- | --------- |
| Single pod        | SEV4/SEV5 |
| Single service    | SEV3      |
| Multiple services | SEV2      |
| Entire cluster    | SEV1      |
| Multiple clusters | SEV1      |

### Error Budget Burn Rate

| Burn Rate | Severity |
| --------- | -------- |
| > 14.4x   | SEV1     |
| > 6x      | SEV2     |
| > 3x      | SEV3     |
| > 1x      | SEV4     |

## Output Format

```json
{
  "skill": "severity-classification",
  "incident_id": "INC-123",
  "severity": "SEV2",
  "factors": {
    "users_affected_percent": 35,
    "revenue_impact_per_hour": 500,
    "blast_radius": "multiple-services",
    "error_budget_burn_rate": 8
  }
}
```

## Success Criteria

- Correct severity classification
- Factors documented
- Consistent classification across incidents
