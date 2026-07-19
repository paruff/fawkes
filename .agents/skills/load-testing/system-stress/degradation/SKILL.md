---
name: degradation-pattern-analysis
description: "Understand how the system degrades as load increases. Use when incrementally increasing load, observing latency, error rate, and throughput, or identifying tipping points."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Degradation Pattern Analysis

> **Load trigger:** `"load degradation-pattern-analysis skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Understand how the system degrades as load increases.

## Responsibilities

- Incrementally increase load
- Observe latency, error rate, and throughput
- Identify tipping points

## Inputs

- Load profile

## Outputs

- `degradation-curve.json`

## Load Increments

| Load Level | Pipelines | Expected Latency | Expected Error Rate |
| ---------- | --------- | ---------------- | ------------------- |
| 10%        | 10        | 5s               | 0%                  |
| 25%        | 25        | 6s               | 0%                  |
| 50%        | 50        | 8s               | 0.5%                |
| 75%        | 75        | 12s              | 2%                  |
| 100%       | 100       | 20s              | 5%                  |
| 125%       | 125       | 30s              | 10%                 |
| 150%       | 150       | 45s              | 20%                 |

## Validation Rules

- [ ] Degradation curve characterized
- [ ] Tipping point identified
- [ ] No catastrophic failure
- [ ] Recovery after load reduction

## Output Format

```json
{
  "skill": "degradation-pattern-analysis",
  "status": "pass | fail",
  "curve": [
    {
      "load_percent": 10,
      "latency_s": 5,
      "error_rate_percent": 0,
      "throughput": 10
    },
    {
      "load_percent": 50,
      "latency_s": 8,
      "error_rate_percent": 0.5,
      "throughput": 48
    },
    {
      "load_percent": 100,
      "latency_s": 20,
      "error_rate_percent": 5,
      "throughput": 90
    },
    {
      "load_percent": 150,
      "latency_s": 45,
      "error_rate_percent": 20,
      "throughput": 100
    }
  ],
  "tipping_point_percent": 100,
  "catastrophic_failure": false
}
```

## Success Criteria

- Well-characterized degradation curve
- Tipping point identified
