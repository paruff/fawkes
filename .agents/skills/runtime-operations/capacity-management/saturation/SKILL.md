---
name: resource-saturation
description: "Detect when services or nodes are approaching resource limits. Use when detecting CPU saturation, memory pressure, disk pressure, or network saturation."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Resource Saturation Detection

> **Load trigger:** `"load resource-saturation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Detect when services or nodes are approaching resource limits.

## Responsibilities

- Detect CPU saturation
- Detect memory pressure
- Detect disk pressure
- Detect network saturation

## Inputs

- Metrics (CPU, memory, disk, network)

## Outputs

- `saturation-report.json`

## Detection Rules

### CPU Saturation

| Metric         | Threshold             | Severity |
| -------------- | --------------------- | -------- |
| CPU usage      | > 85% sustained 5 min | HIGH     |
| CPU throttling | > 50%                 | MEDIUM   |
| CPU throttling | > 80%                 | HIGH     |

### Memory Pressure

| Metric             | Threshold | Severity |
| ------------------ | --------- | -------- |
| Memory usage       | > 85%     | HIGH     |
| OOM kills          | > 0       | CRITICAL |
| Memory working set | > 90%     | HIGH     |

### Disk Pressure

| Metric        | Threshold | Severity |
| ------------- | --------- | -------- |
| Disk usage    | > 85%     | HIGH     |
| Disk I/O wait | > 20%     | MEDIUM   |
| Inode usage   | > 80%     | MEDIUM   |

### Network Saturation

| Metric            | Threshold | Severity |
| ----------------- | --------- | -------- |
| Network bandwidth | > 75%     | MEDIUM   |
| Packet drops      | > 0.1%    | MEDIUM   |
| TCP retransmits   | > 1%      | HIGH     |

## Output Format

```json
{
  "skill": "resource-saturation",
  "saturation": [
    {
      "resource": "cpu",
      "scope": "node/worker-1",
      "usage_percent": 92,
      "threshold": 85,
      "severity": "HIGH",
      "duration": "10 minutes"
    }
  ]
}
```

## Success Criteria

- Accurate saturation detection
- All resource types monitored
- Severity classified correctly
