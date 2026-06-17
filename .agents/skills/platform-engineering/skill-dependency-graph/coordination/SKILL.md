---
name: cross-agent-coordination
description: "Define how Fawkes agents coordinate across skills. Use when defining skill ordering, retry rules, escalation rules, or parallelization rules."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cross-Agent Coordination Rules

> **Load trigger:** `"load cross-agent-coordination skill"` > **DORA:** Cap 3 (AI-Accessible Internal Data)
> **Token cost:** Low

## Purpose

Define how Fawkes agents coordinate across skills.

## Responsibilities

- Define skill ordering
- Define retry rules
- Define escalation rules
- Define parallelization rules

## Inputs

- `skill-graph.json`

## Outputs

- `coordination-rules.json`

## Coordination Rules

### Ordering

| Rule       | Description                                      |
| ---------- | ------------------------------------------------ |
| Sequential | `spec` → `design` → `plan` (must be ordered)     |
| Parallel   | `test-execution` + `security` (can run together) |
| Gate       | `build-review` requires all prior passing        |

### Retry

| Failure Type        | Retry | Max Retries | Escalate    |
| ------------------- | ----- | ----------- | ----------- |
| Transient (network) | Yes   | 3           | After 3     |
| Flaky test          | Yes   | 2           | After 2     |
| Policy violation    | No    | 0           | Immediately |
| Security finding    | No    | 0           | Immediately |

### Escalation

| Level    | Trigger            | Action             |
| -------- | ------------------ | ------------------ |
| Warning  | Non-blocking issue | Log, continue      |
| Block    | Policy violation   | Stop, notify human |
| Critical | Security finding   | Stop, block merge  |

### Parallelization

| Skills                        | Can Parallelize            |
| ----------------------------- | -------------------------- |
| `test-execution` + `security` | Yes                        |
| `unit-test` + `lint`          | Yes                        |
| `build` + `test-execution`    | No (test depends on build) |

## Output Format

```json
{
  "skill": "cross-agent-coordination",
  "rules": {
    "sequential": [["spec", "design", "plan"]],
    "parallel": [["test-execution", "security"]],
    "gates": ["build-review"]
  },
  "retry": {
    "transient": { "retry": true, "max": 3 },
    "flaky": { "retry": true, "max": 2 },
    "policy": { "retry": false, "escalate": true }
  },
  "escalation": {
    "warning": "log",
    "block": "notify_human",
    "critical": "stop_merge"
  }
}
```

## Success Criteria

- Clear orchestration rules
- All failure modes handled
- Parallelization defined
