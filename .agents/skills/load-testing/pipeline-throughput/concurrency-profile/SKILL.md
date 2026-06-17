---
name: pipeline-concurrency-profiling
description: "Characterize PIPE behavior at different concurrency levels. Use when running pipelines at varying concurrency, measuring queue depth and wait time, or identifying saturation points."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Pipeline Concurrency Profiling

> **Load trigger:** `"load pipeline-concurrency-profiling skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Characterize PIPE behavior at different concurrency levels.

## Responsibilities

- Run pipelines at varying concurrency (1, 5, 10, 50, 100)
- Measure queue depth, wait time, and execution time
- Identify saturation points

## Inputs

- Concurrency matrix
- Pipeline definitions

## Outputs

- `concurrency-profile.json`

## Concurrency Matrix

| Level | Pipelines | Expected Behavior    |
| ----- | --------- | -------------------- |
| 1     | 10        | Linear execution     |
| 5     | 50        | Near-linear          |
| 10    | 100       | Slight queue buildup |
| 50    | 250       | Queue noticeable     |
| 100   | 500       | Saturation near      |

## Validation Rules

- [ ] Clear saturation threshold identified
- [ ] Queue depth measured at each level
- [ ] Wait time within SLA
- [ ] No pipeline failures

## Output Format

```json
{
  "skill": "pipeline-concurrency-profiling",
  "status": "pass | fail",
  "levels": [
    {
      "concurrency": 1,
      "queue_depth": 0,
      "wait_time_ms": 0,
      "exec_time_ms": 5000
    },
    {
      "concurrency": 5,
      "queue_depth": 2,
      "wait_time_ms": 500,
      "exec_time_ms": 5500
    },
    {
      "concurrency": 10,
      "queue_depth": 8,
      "wait_time_ms": 2000,
      "exec_time_ms": 7000
    },
    {
      "concurrency": 50,
      "queue_depth": 40,
      "wait_time_ms": 10000,
      "exec_time_ms": 15000
    },
    {
      "concurrency": 100,
      "queue_depth": 90,
      "wait_time_ms": 25000,
      "exec_time_ms": 30000
    }
  ],
  "saturation_point": 50
}
```

## Success Criteria

- Clear saturation threshold identified
