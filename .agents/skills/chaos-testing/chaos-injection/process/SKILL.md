---
name: process-chaos
description: "Kill or restart PIPE or OBS processes during critical operations. Use when validating recovery behavior after process termination."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Process Chaos

> **Load trigger:** `"load process-chaos skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Kill or restart PIPE or OBS processes during critical operations.

## Responsibilities

- Kill PIPE during build
- Kill OBS during GitOps update
- Validate recovery behavior

## Inputs

- Target process

## Outputs

- `process-chaos.json`

## Kill Scenarios

| Process           | Kill Point    | Expected Behavior                        |
| ----------------- | ------------- | ---------------------------------------- |
| PIPE              | Mid-build     | Build marked failed, no partial artifact |
| PIPE              | Image push    | Push retried, no orphan image            |
| OBS               | Mid-reconcile | Reconcile retried, no partial write      |
| OBS               | Git commit    | Commit rolled back, no partial commit    |
| GitOps controller | Sync          | Sync retried, no drift                   |

## Pumba Command

```bash
# Kill PIPE process
pumba kill --name "pipe-kill" pipe

# Kill OBS process
pumba kill --name "obs-kill" obs
```

## Validation Rules

- [ ] Process killed successfully
- [ ] No corrupted state
- [ ] No partial GitOps writes
- [ ] Recovery within SLA
- [ ] State consistent after recovery

## Output Format

```json
{
  "skill": "process-chaos",
  "status": "success",
  "kills": [
    {
      "process": "pipe",
      "during": "build",
      "recovered": true,
      "recovery_time_s": 30
    },
    {
      "process": "obs",
      "during": "reconcile",
      "recovered": true,
      "recovery_time_s": 45
    }
  ],
  "state_integrity": "preserved",
  "partial_writes": 0
}
```

## Success Criteria

- No corrupted state
- No partial GitOps writes
- Recovery within SLA
