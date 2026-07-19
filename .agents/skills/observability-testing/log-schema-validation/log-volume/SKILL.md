---
name: log-volume-rate-testing
description: "Ensure log volume remains within acceptable limits under load. Use when measuring logs/sec, detecting log storms, or validating sampling rules."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Log Volume & Rate Testing

> **Load trigger:** `"load log-volume-rate-testing skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure log volume remains within acceptable limits under load.

## Responsibilities

- Measure logs/sec under load
- Detect log storms
- Validate sampling rules

## Inputs

- Load test logs

## Outputs

- `log-volume.json`

## Volume Thresholds

| Metric                 | Warning       | Critical      |
| ---------------------- | ------------- | ------------- |
| Logs/sec (per service) | > 1000        | > 5000        |
| Log burst (1s spike)   | > 10x average | > 50x average |
| Log volume (per min)   | > 100KB       | > 1MB         |
| Duplicate logs         | > 5%          | > 20%         |

## Validation Rules

- [ ] Logs/sec within threshold
- [ ] No log storms detected
- [ ] Sampling rules applied correctly
- [ ] No duplicate log entries
- [ ] Log volume stable under load

## Output Format

```json
{
  "skill": "log-volume-rate-testing",
  "status": "pass | warn | fail",
  "metrics": {
    "logs_per_second": 450,
    "peak_burst": 2000,
    "volume_per_minute_kb": 50,
    "duplicates_percent": 0.5,
    "threshold_violations": []
  }
}
```

## Success Criteria

- No log storms
- No excessive log volume
- Volume stable under load
