---
name: metrics-validation
description: "Ensure all Fawkes components expose correct, meaningful, and standards-compliant metrics. Use when validating Prometheus metric names, cardinality, histogram buckets, or golden signals."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Metrics Validation

> **Load trigger:** `"load metrics-validation skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure all Fawkes components expose correct, meaningful, and standards-compliant metrics.

## Responsibilities

- Validate Prometheus metric names
- Validate cardinality
- Validate histogram buckets
- Validate metric freshness
- Validate golden signals (latency, errors, saturation, traffic)

## Inputs

- Prometheus scrape data

## Outputs

- `metrics-report.json`

## Sub-Skills

| Skill                               | Purpose                         |
| ----------------------------------- | ------------------------------- |
| `metrics-validation/golden-signals` | Validate four golden signals    |
| `metrics-validation/cardinality`    | Detect high-cardinality metrics |

## Metric Naming Convention

| Pattern                                 | Example                               |
| --------------------------------------- | ------------------------------------- |
| `<namespace>_<subsystem>_<name>_<unit>` | `fawkes_pipe_build_duration_seconds`  |
| Counter: `_total` suffix                | `fawkes_pipe_builds_total`            |
| Histogram: `_bucket`, `_sum`, `_count`  | `fawkes_pipe_duration_seconds_bucket` |
| Gauge: no suffix                        | `fawkes_pipe_active_builds`           |

## Validation Rules

- [ ] Metric names follow convention
- [ ] No high-cardinality labels
- [ ] Histogram buckets reasonable
- [ ] Metrics fresh (< 60s stale)
- [ ] Golden signals present

## Tools

- Prometheus
- promtool

## Output Format

```json
{
  "skill": "metrics-validation",
  "status": "pass | fail",
  "total_metrics": 150,
  "valid_names": 148,
  "invalid_names": 2,
  "high_cardinality": 1,
  "golden_signals": "complete",
  "issues": []
}
```

## Success Criteria

- No invalid metrics
- No high-cardinality labels
- Golden signals complete
