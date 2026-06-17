---
name: registry-load-testing
description: "Understand how PIPE and OBS behave when pushing/pulling many images under load. Use when pushing many images concurrently, pulling images for validation, or measuring registry response times and error rates."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Registry Load Testing

> **Load trigger:** `"load registry-load-testing skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Understand how PIPE and OBS behave when pushing/pulling many images under load.

## Responsibilities

- Push many images concurrently
- Pull images for validation
- Measure registry response times and error rates

## Inputs

- Local or remote registry
- Image build definitions

## Outputs

- `registry-load.json`
- `error-rate.json`

## Sub-Skills

| Skill                            | Purpose                             |
| -------------------------------- | ----------------------------------- |
| `registry-load/push-performance` | Measure concurrent push performance |
| `registry-load/pull-performance` | Measure concurrent pull performance |

## Validation Rules

- [ ] Acceptable error rate under target load
- [ ] No registry saturation causing pipeline failure
- [ ] Response times within SLA

## Output Format

```json
{
  "skill": "registry-load-testing",
  "status": "pass | fail",
  "push": {
    "throughput_per_min": 20,
    "p50_ms": 5000,
    "error_rate_percent": 0.5
  },
  "pull": {
    "throughput_per_min": 50,
    "p50_ms": 2000,
    "error_rate_percent": 0.1
  },
  "total_images": 100
}
```

## Success Criteria

- Acceptable error rate under target load
- No registry saturation
