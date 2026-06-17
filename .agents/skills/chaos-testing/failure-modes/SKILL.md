---
name: failure-modes
description: "Validate PIPE and OBS behavior under predictable failure scenarios. Use when simulating registry outages, GitOps repo unavailability, K8s API degradation, or testing fallback and retry logic."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Failure Mode Testing

> **Load trigger:** `"load failure-modes skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Validate PIPE and OBS behavior under predictable failure scenarios.

## Responsibilities

- Simulate registry outages
- Simulate GitOps repo unavailability
- Simulate K8s API degradation
- Validate fallback and retry logic

## Inputs

- Failure scenarios

## Outputs

- `failure-mode-report.json`

## Sub-Skills

| Skill                       | Purpose                        |
| --------------------------- | ------------------------------ |
| `failure-modes/registry`    | Registry failure simulation    |
| `failure-modes/gitops-repo` | GitOps repo failure simulation |

## Failure Scenarios

| Scenario           | Trigger           | Expected Behavior                |
| ------------------ | ----------------- | -------------------------------- |
| Registry down      | Network block     | PIPE retries, fails gracefully   |
| GitOps repo locked | File lock         | OBS waits, retries with backoff  |
| K8s API degraded   | Latency injection | Controller retries, queues work  |
| DNS failure        | DNS block         | Service falls back to cache      |
| Disk full          | Space exhaustion  | Graceful shutdown, no corruption |

## Validation Rules

- [ ] Correct fallback behavior
- [ ] No invalid GitOps updates
- [ ] Retry logic works correctly
- [ ] Backoff implemented
- [ ] No cascading failures

## Output Format

```json
{
  "skill": "failure-modes",
  "status": "success",
  "scenarios": {
    "registry_outage": { "fallback": "pass", "retry": "pass" },
    "gitops_repo_locked": { "fallback": "pass", "backoff": "pass" },
    "k8s_api_degraded": { "fallback": "pass", "queue": "pass" }
  },
  "invalid_gitops_updates": 0,
  "cascading_failures": 0
}
```

## Success Criteria

- Correct fallback behavior
- No invalid GitOps updates
