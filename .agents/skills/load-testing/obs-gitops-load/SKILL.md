---
name: obs-gitops-load-testing
description: "Measure how OBS behaves when performing many GitOps updates in a short time. Use when triggering many image/tag updates, measuring commit rate and repo size growth, or measuring manifest rendering time."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: OBS GitOps Load Testing

> **Load trigger:** `"load obs-gitops-load-testing skill"` > **DORA:** Cap 4 (CI/CD Automation)
> **Token cost:** Low

## Purpose

Measure how OBS behaves when performing many GitOps updates in a short time.

## Responsibilities

- Trigger many image/tag updates
- Measure commit rate and repo size growth
- Measure manifest rendering time under load

## Inputs

- GitOps repo
- Promotion scenarios

## Outputs

- `obs-gitops-load.json`
- `gitops-commit-stats.json`

## Sub-Skills

| Skill                                | Purpose                      |
| ------------------------------------ | ---------------------------- |
| `obs-gitops-load/commit-rate`        | Measure commits per minute   |
| `obs-gitops-load/render-performance` | Measure manifest render time |

## Validation Rules

- [ ] Stable performance under expected promotion rate
- [ ] No Git repo corruption
- [ ] Commit rate within limits
- [ ] Render time predictable

## Output Format

```json
{
  "skill": "obs-gitops-load-testing",
  "status": "pass | fail",
  "commit_rate": {
    "per_minute": 10,
    "total_commits": 100,
    "conflicts": 0
  },
  "repo_size": {
    "initial_mb": 5,
    "final_mb": 8,
    "growth_percent": 60
  },
  "render_time": {
    "p50_ms": 200,
    "p95_ms": 500,
    "p99_ms": 800
  }
}
```

## Success Criteria

- Stable performance under expected promotion rate
- No Git repo corruption
