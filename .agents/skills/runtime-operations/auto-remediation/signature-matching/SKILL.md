---
name: signature-matching
description: "Identify known failure patterns that can be auto-remediated. Use when matching logs or metrics to known signatures."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Failure Signature Matching

> **Load trigger:** `"load signature-matching skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Identify known failure patterns that can be auto-remediated.

## Responsibilities

- Match logs to known signatures
- Match metrics to known patterns
- Produce remediation recommendation
- Classify severity of match

## Inputs

- Logs
- Metrics
- Known signature database

## Outputs

- `signature-match.json`

## Known Signatures

| Signature         | Pattern                         | Auto-Remediable   |
| ----------------- | ------------------------------- | ----------------- |
| CrashLoopBackOff  | Pod restart count > 5 in 10 min | Yes               |
| OOMKilled         | Exit code 137                   | Yes               |
| ImagePullBackOff  | Image not found                 | No (config issue) |
| Stuck terminating | Pod in Terminating > 5 min      | Yes               |
| Memory pressure   | Node memory > 90%               | Yes               |
| CPU throttling    | CPU throttling > 50%            | Yes               |

## Matching Rules

### Log Signatures

- [ ] Exact string match
- [ ] Regex pattern match
- [ ] Log rate anomaly (too many errors)

### Metric Signatures

- [ ] Threshold breach (value > threshold)
- [ ] Rate of change (spike detection)
- [ ] Duration (sustained condition)

### Confidence Levels

| Level  | Description                      | Action                         |
| ------ | -------------------------------- | ------------------------------ |
| HIGH   | Exact match to known signature   | Auto-remediate                 |
| MEDIUM | Partial match, likely same issue | Auto-remediate with validation |
| LOW    | Similar pattern, uncertain       | Escalate to human              |

## Output Format

```json
{
  "skill": "signature-matching",
  "matches": [
    {
      "signature": "CrashLoopBackOff",
      "resource": "pod/my-app-abc123",
      "confidence": "HIGH",
      "evidence": "Pod restarted 7 times in last 10 minutes",
      "remediation": "restart-pod"
    }
  ]
}
```

## Success Criteria

- Accurate signature detection
- Confidence level assigned
- Remediation action recommended
