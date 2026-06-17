---
name: slo-management
description: "Define, monitor, and enforce service-level objectives (SLOs). Use when tracking error budget burn rate, detecting SLO violations, or producing SLO reports."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: SLO Management

> **Load trigger:** `"load slo-management skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Define, monitor, and enforce service-level objectives (SLOs).

## Responsibilities

- Track error budget burn rate
- Detect SLO violations
- Trigger rollback or remediation
- Produce SLO reports

## Inputs

- SLO definitions
- Metrics (latency, availability, error rate)

## Outputs

- `slo-report.json`
- `error-budget.json`

## Sub-Skills

| Skill                               | Purpose                      |
| ----------------------------------- | ---------------------------- |
| `slo-management/error-budget`       | Track error budget burn rate |
| `slo-management/violation-response` | Respond to SLO violations    |

## SLO Definitions

| SLO           | Target  | Window  |
| ------------- | ------- | ------- |
| Availability  | 99.9%   | 30 days |
| Latency (p99) | < 500ms | 30 days |
| Error rate    | < 0.1%  | 30 days |

## Burn Rate Thresholds

| Burn Rate | Severity | Action                   |
| --------- | -------- | ------------------------ |
| > 14.4x   | CRITICAL | Immediate rollback       |
| > 6x      | HIGH     | Alert + prepare rollback |
| > 3x      | MEDIUM   | Alert + investigate      |
| > 1x      | LOW      | Monitor                  |

## Output Format

```json
{
  "skill": "slo-management",
  "slos": [
    {
      "name": "availability",
      "target": 99.9,
      "current": 99.95,
      "status": "healthy",
      "error_budget_remaining_percent": 50
    }
  ],
  "burn_rates": {
    "1h": 2.5,
    "6h": 1.8,
    "24h": 1.2
  }
}
```

## Success Criteria

- Accurate SLO tracking
- Burn rate calculated correctly
- Violations trigger appropriate response
