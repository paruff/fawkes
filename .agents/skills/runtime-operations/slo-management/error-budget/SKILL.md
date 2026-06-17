---
name: error-budget
description: "Track how quickly the service is burning its error budget. Use when computing burn rate, detecting fast burn, or triggering alerts."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Error Budget Tracking

> **Load trigger:** `"load error-budget skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Track how quickly the service is burning its error budget.

## Responsibilities

- Compute error budget burn rate
- Detect fast burn (1h, 6h windows)
- Trigger alerts or rollback
- Track budget remaining

## Inputs

- Metrics (error rate, latency)
- SLO definitions

## Outputs

- `error-budget.json`

## Burn Rate Calculation

### Formula

```
burn_rate = (1 - actual_success_rate) / (1 - slo_target)
```

### Example

- SLO target: 99.9% availability
- Actual: 99.0% availability
- Burn rate: (1 - 0.99) / (1 - 0.999) = 10x

### Budget Window

| Window  | Budget   | 1% Budget | 14.4x Burn | 6x Burn   | 3x Burn   |
| ------- | -------- | --------- | ---------- | --------- | --------- |
| 30 days | 43.2 min | 43.2s     | 3s/min     | 1.25s/min | 0.43s/min |

## Detection Rules

### Fast Burn (1h window)

- [ ] Burn rate > 14.4x → CRITICAL
- [ ] Burn rate > 6x → HIGH
- [ ] Burn rate > 3x → MEDIUM

### Slow Burn (6h window)

- [ ] Burn rate > 1x → Budget consumed at 100%
- [ ] Burn rate > 3x → Budget consumed at 300%

## Output Format

```json
{
  "skill": "error-budget",
  "slo": "availability",
  "target": 99.9,
  "window": "30d",
  "total_budget_minutes": 43.2,
  "consumed_minutes": 21.6,
  "remaining_minutes": 21.6,
  "remaining_percent": 50,
  "burn_rates": {
    "1h": 2.5,
    "6h": 1.8,
    "24h": 1.2
  },
  "fast_burn_detected": false
}
```

## Success Criteria

- Accurate error budget calculation
- Burn rate calculated for multiple windows
- Fast burn detection working
