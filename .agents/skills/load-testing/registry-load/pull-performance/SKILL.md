---
name: image-pull-performance
description: "Measure performance of concurrent image pulls used by OBS or validation steps. Use when pulling images concurrently, measuring latency, or tracking failures."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Image Pull Performance Testing

> **Load trigger:** `"load image-pull-performance skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Measure performance of concurrent image pulls used by OBS or validation steps.

## Responsibilities

- Pull images concurrently
- Measure latency
- Track failures

## Inputs

- Image list

## Outputs

- `pull-performance.json`

## Pull Command

```bash
docker pull my-registry/my-app:v1.0.0
```

## Validation Rules

- [ ] Acceptable pull latency under load
- [ ] Error rate < 0.5%
- [ ] No registry timeouts
- [ ] Pull time within SLA

## Output Format

```json
{
  "skill": "image-pull-performance",
  "status": "pass | fail",
  "concurrency": 50,
  "total_pulls": 500,
  "throughput_per_min": 100,
  "latency": {
    "p50_ms": 2000,
    "p95_ms": 4000,
    "p99_ms": 6000
  },
  "error_rate_percent": 0.1,
  "failures": []
}
```

## Success Criteria

- Acceptable pull latency under load
