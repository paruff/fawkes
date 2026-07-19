---
name: metric-cardinality-testing
description: "Detect high-cardinality metrics that can overload Prometheus. Use when analyzing label cardinality, detecting unbounded labels, or validating histogram bucket count."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Metric Cardinality Testing

> **Load trigger:** `"load metric-cardinality-testing skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Detect high-cardinality metrics that can overload Prometheus.

## Responsibilities

- Analyze label cardinality
- Detect unbounded labels
- Validate histogram bucket count

## Inputs

- Prometheus metrics

## Outputs

- `cardinality-report.json`

## Cardinality Thresholds

| Metric                   | Warning | Critical |
| ------------------------ | ------- | -------- |
| Label values (per label) | > 100   | > 1000   |
| Total time series        | > 10000 | > 50000  |
| Histogram buckets        | > 20    | > 50     |

## High-Cardinality Risk Labels

| Label         | Risk   | Mitigation               |
| ------------- | ------ | ------------------------ |
| `user_id`     | High   | Hash or bucket           |
| `request_id`  | High   | Remove or sample         |
| `trace_id`    | Medium | Use for correlation only |
| `version`     | Low    | Acceptable               |
| `environment` | Low    | Acceptable               |

## Validation Rules

- [ ] No label exceeds 1000 values
- [ ] Total time series < 50000
- [ ] Histogram buckets < 20
- [ ] No unbounded labels detected

## Output Format

```json
{
  "skill": "metric-cardinality-testing",
  "status": "pass | warn | fail",
  "total_time_series": 5000,
  "labels": {
    "service": { "values": 10, "status": "pass" },
    "environment": { "values": 3, "status": "pass" },
    "user_id": { "values": 5000, "status": "fail" }
  },
  "high_cardinality_labels": ["user_id"],
  "recommendations": ["Hash user_id values"]
}
```

## Success Criteria

- No high-cardinality labels
- Time series within limits
