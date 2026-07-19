---
name: registry-failure-simulation
description: "Validate PIPE and OBS behavior when the registry is unavailable. Use when blocking registry access, validating PIPE retry logic, or checking OBS digest resolution fallback."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Registry Failure Simulation

> **Load trigger:** `"load registry-failure-simulation skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Validate PIPE and OBS behavior when the registry is unavailable.

## Responsibilities

- Block registry access
- Validate PIPE retry logic
- Validate OBS digest resolution fallback

## Inputs

- Registry endpoint

## Outputs

- `registry-failure.json`

## Failure Modes

| Mode            | Duration | Expected PIPE  | Expected OBS      |
| --------------- | -------- | -------------- | ----------------- |
| Complete outage | 60s      | Retry, fail    | Use cached digest |
| Partial outage  | 30s      | Retry, succeed | Retry, succeed    |
| Slow response   | 120s     | Timeout, retry | Timeout, retry    |
| Auth failure    | 60s      | Fail, alert    | Fail, alert       |

## Toxiproxy Config

```json
{
  "name": "registry-outage",
  "listen": "0.0.0.0:5000",
  "upstream": "registry:5000",
  "enabled": true
}
```

## Validation Rules

- [ ] PIPE retries correctly
- [ ] PIPE fails gracefully after max retries
- [ ] OBS falls back to cached digest
- [ ] No invalid image references
- [ ] Alerts triggered

## Output Format

```json
{
  "skill": "registry-failure-simulation",
  "status": "success",
  "scenarios": [
    {
      "mode": "complete_outage",
      "pipe": "fail_gracefully",
      "obs": "cached_digest"
    },
    {
      "mode": "partial_outage",
      "pipe": "retry_succeed",
      "obs": "retry_succeed"
    }
  ],
  "invalid_image_references": 0
}
```

## Success Criteria

- No invalid image references
- Correct retry and fallback behavior
