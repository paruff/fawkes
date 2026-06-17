---
name: anomaly-detection
description: "Detect unusual patterns in metrics, logs, or traces. Use when identifying spikes in latency, error rate anomalies, or unusual log patterns."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Anomaly Detection

> **Load trigger:** `"load anomaly-detection skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Detect unusual patterns in metrics, logs, or traces.

## Responsibilities

- Detect spikes in latency
- Detect error rate anomalies
- Detect saturation anomalies
- Detect unusual log patterns

## Inputs

- Metrics (latency, error rate, saturation)
- Logs (structured and unstructured)

## Outputs

- `anomaly-report.json`

## Detection Methods

### Metric Anomalies

| Pattern          | Method               | Sensitivity |
| ---------------- | -------------------- | ----------- |
| Spike            | Threshold breach     | High        |
| Gradual increase | Rate of change       | Medium      |
| Sustained high   | Duration threshold   | Medium      |
| Drop to zero     | Zero-value detection | High        |

### Log Anomalies

| Pattern           | Method             | Sensitivity |
| ----------------- | ------------------ | ----------- |
| Error spike       | Error count rate   | High        |
| New error type    | Pattern uniqueness | Medium      |
| Log volume change | Volume rate        | Low         |

## Thresholds

| Metric       | Warning | Critical |
| ------------ | ------- | -------- |
| Latency p99  | > 500ms | > 1000ms |
| Error rate   | > 1%    | > 5%     |
| CPU usage    | > 70%   | > 85%    |
| Memory usage | > 70%   | > 85%    |

## Output Format

```json
{
  "skill": "anomaly-detection",
  "anomalies": [
    {
      "type": "latency_spike",
      "metric": "http_request_duration_seconds",
      "current_value": 1200,
      "threshold": 500,
      "severity": "critical",
      "detected_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

## Success Criteria

- Accurate anomaly detection
- Low false positive rate
- Timely detection (< 1 minute)
