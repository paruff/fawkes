---
name: root-cause-hypothesis
description: "Generate a likely root cause hypothesis based on telemetry. Use when analyzing logs, metrics, and traces to identify probable root causes."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Root Cause Hypothesis

> **Load trigger:** `"load root-cause-hypothesis skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Generate a likely root cause hypothesis based on telemetry.

## Responsibilities

- Analyze logs for error patterns
- Analyze metrics for anomalies
- Analyze traces for latency/errors
- Identify probable root cause

## Inputs

- Telemetry data (logs, metrics, traces)

## Outputs

- `root-cause.json`

## Analysis Methods

### Log Analysis

- [ ] Identify error messages
- [ ] Identify error frequency
- [ ] Identify error correlation with time
- [ ] Identify affected components

### Metric Analysis

- [ ] Identify anomalous metrics
- [ ] Identify metric correlations
- [ ] Identify timing of anomalies
- [ ] Identify affected services

### Trace Analysis

- [ ] Identify slow spans
- [ ] Identify error spans
- [ ] Identify dependency failures
- [ ] Identify bottleneck services

## Common Root Causes

| Symptom                 | Likely Root Cause                        |
| ----------------------- | ---------------------------------------- |
| Connection timeout      | Network issue or downstream service down |
| OOMKilled               | Memory leak or insufficient limits       |
| 500 errors after deploy | Bad deployment, rollback                 |
| Slow responses          | Resource contention, database query      |
| Disk full               | Log accumulation, data growth            |

## Output Format

```json
{
  "skill": "root-cause-hypothesis",
  "incident_id": "INC-123",
  "hypotheses": [
    {
      "rank": 1,
      "root_cause": "Database connection pool exhausted",
      "confidence": "HIGH",
      "evidence": [
        "Error log: 'connection pool exhausted'",
        "Metric: db_connections_used at 100%",
        "Trace: db span shows timeout"
      ]
    }
  ]
}
```

## Success Criteria

- Useful root cause hypothesis
- Evidence provided for each hypothesis
- Confidence level assigned
