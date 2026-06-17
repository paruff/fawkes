---
name: gitops-repo-failure-simulation
description: "Validate OBS behavior when GitOps repo is unavailable or locked. Use when simulating repo lock, unreachable repo, or validating retry and backoff logic."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: GitOps Repo Failure Simulation

> **Load trigger:** `"load gitops-repo-failure-simulation skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Validate OBS behavior when GitOps repo is unavailable or locked.

## Responsibilities

- Simulate repo lock
- Simulate unreachable repo
- Validate retry and backoff logic

## Inputs

- GitOps repo

## Outputs

- `gitops-repo-failure.json`

## Failure Modes

| Mode             | Duration | Expected OBS             |
| ---------------- | -------- | ------------------------ |
| Repo locked      | 60s      | Wait, retry with backoff |
| Repo unreachable | 120s     | Retry, fail gracefully   |
| Auth expired     | 60s      | Fail, alert              |
| Disk full        | 60s      | Fail, alert              |

## Validation Rules

- [ ] OBS retries with backoff
- [ ] No partial commits
- [ ] No corrupted repo
- [ ] Alerts triggered
- [ ] State consistent after recovery

## Output Format

```json
{
  "skill": "gitops-repo-failure-simulation",
  "status": "success",
  "scenarios": [
    { "mode": "repo_locked", "retry": "pass", "backoff": "pass" },
    { "mode": "repo_unreachable", "retry": "pass", "graceful_fail": "pass" }
  ],
  "partial_commits": 0,
  "repo_corruption": 0
}
```

## Success Criteria

- No partial commits
- No corrupted repo
- Correct retry and backoff logic
