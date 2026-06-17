---
name: pipeline-latency-breakdown
description: "Break down end-to-end pipeline latency by stage. Use when measuring per-stage execution time, identifying slow stages, or producing latency histograms."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Pipeline Latency Breakdown

> **Load trigger:** `"load pipeline-latency-breakdown skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Break down end-to-end pipeline latency by stage.

## Responsibilities

- Measure per-stage execution time
- Identify slow stages (build, test, security, GitOps)
- Produce latency histogram

## Inputs

- Pipeline run logs

## Outputs

- `latency-breakdown.json`

## Stage Latency

| Stage            | p50_ms | p95_ms | p99_ms |
| ---------------- | ------ | ------ | ------ |
| type-check       | 500    | 800    | 1200   |
| lint             | 300    | 500    | 700    |
| sast             | 2000   | 3000   | 5000   |
| build            | 5000   | 8000   | 12000  |
| unit-test        | 3000   | 5000   | 8000   |
| integration-test | 5000   | 10000  | 15000  |
| security-scan    | 2000   | 4000   | 6000   |
| publish          | 1000   | 2000   | 3000   |
| release          | 200    | 300    | 500    |

## Validation Rules

- [ ] All stages measured
- [ ] Top latency contributors identified
- [ ] Latency within SLA
- [ ] No stage > 2x average

## Output Format

```json
{
  "skill": "pipeline-latency-breakdown",
  "status": "pass | fail",
  "total_latency_ms": 20000,
  "stages": [
    {
      "stage": "build",
      "p50_ms": 5000,
      "p95_ms": 8000,
      "p99_ms": 12000,
      "percent": 25
    },
    {
      "stage": "integration-test",
      "p50_ms": 5000,
      "p95_ms": 10000,
      "p99_ms": 15000,
      "percent": 25
    },
    {
      "stage": "unit-test",
      "p50_ms": 3000,
      "p95_ms": 5000,
      "p99_ms": 8000,
      "percent": 15
    }
  ],
  "top_bottlenecks": ["build", "integration-test"]
}
```

## Success Criteria

- Top latency contributors identified
