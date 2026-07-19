---
name: pipeline-throughput-testing
description: "Measure how many pipelines PIPE can execute per unit time under realistic workloads. Use when running concurrent pipelines, measuring throughput, or identifying bottlenecks."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Pipeline Throughput Testing

> **Load trigger:** `"load pipeline-throughput-testing skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Measure how many pipelines PIPE can execute per unit time under realistic workloads.

## Responsibilities

- Run multiple concurrent pipelines
- Measure pipeline start/end times
- Compute throughput (pipelines/minute)
- Identify bottlenecks in scheduling or execution

## Inputs

- Pipeline definitions
- Load profile (number of pipelines, concurrency)

## Outputs

- `throughput.json`
- `latency-distribution.json`

## Sub-Skills

| Skill                                     | Purpose                                        |
| ----------------------------------------- | ---------------------------------------------- |
| `pipeline-throughput/concurrency-profile` | Characterize behavior at different concurrency |
| `pipeline-throughput/latency-breakdown`   | Break down latency by stage                    |

## Load Profile

| Concurrency | Pipelines | Duration |
| ----------- | --------- | -------- |
| 1           | 10        | 5 min    |
| 5           | 50        | 5 min    |
| 10          | 100       | 5 min    |
| 50          | 250       | 5 min    |
| 100         | 500       | 5 min    |

## Validation Rules

- [ ] Stable throughput under target load
- [ ] No starvation or deadlocks
- [ ] No pipeline failures due to load
- [ ] Queue depth within limits

## Output Format

```json
{
  "skill": "pipeline-throughput-testing",
  "status": "pass | fail",
  "throughput": {
    "pipelines_per_minute": 20,
    "total_pipelines": 100,
    "total_time_s": 300
  },
  "latency": {
    "p50_ms": 5000,
    "p95_ms": 8000,
    "p99_ms": 12000
  },
  "bottlenecks": []
}
```

## Success Criteria

- Stable throughput under target load
- No starvation or deadlocks
