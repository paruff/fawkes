---
name: image-push-performance
description: "Measure performance of concurrent image pushes. Use when building and pushing images concurrently, measuring push latency and throughput, or tracking failures."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Image Push Performance Testing

> **Load trigger:** `"load image-push-performance skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Measure performance of concurrent image pushes.

## Responsibilities

- Build and push images concurrently
- Measure push latency and throughput
- Track failures

## Inputs

- Dockerfiles
- Concurrency profile

## Outputs

- `push-performance.json`

## Push Command

```bash
docker push my-registry/my-app:v1.0.0
```

## Validation Rules

- [ ] Stable push performance at target concurrency
- [ ] Push latency within SLA
- [ ] Error rate < 1%
- [ ] No registry timeouts

## Output Format

```json
{
  "skill": "image-push-performance",
  "status": "pass | fail",
  "concurrency": 10,
  "total_pushes": 100,
  "throughput_per_min": 20,
  "latency": {
    "p50_ms": 5000,
    "p95_ms": 8000,
    "p99_ms": 12000
  },
  "error_rate_percent": 0.5,
  "failures": []
}
```

## Success Criteria

- Stable push performance at target concurrency
