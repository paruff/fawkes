---
name: signal-correlation
description: "Correlate logs, metrics, and traces into a unified signal. Use when identifying shared trace IDs, error patterns, or timestamps across telemetry."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Signal Correlation

> **Load trigger:** `"load signal-correlation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Correlate logs, metrics, and traces into a unified signal.

## Responsibilities

- Identify shared trace IDs
- Identify shared error patterns
- Identify shared timestamps
- Produce unified signal

## Inputs

- Telemetry data (logs, metrics, traces)

## Outputs

- `signal-correlation.json`

## Correlation Keys

| Key              | Source      | Confidence |
| ---------------- | ----------- | ---------- |
| trace_id         | Traces      | HIGH       |
| request_id       | Logs/Traces | HIGH       |
| span_id          | Traces      | HIGH       |
| error_pattern    | Logs        | MEDIUM     |
| timestamp_window | All         | LOW        |

## Correlation Logic

### Trace ID Match

```
1. Extract trace_id from all signals
2. Group signals by trace_id
3. Signals with same trace_id = correlated
```

### Error Pattern Match

```
1. Extract error messages from logs
2. Normalize error messages (remove IDs, timestamps)
3. Group by normalized error
4. Signals with same error pattern = correlated
```

### Timestamp Window

```
1. Collect all signal timestamps
2. Group signals within time window (default 5 min)
3. Signals in same window = candidates
```

## Output Format

```json
{
  "skill": "signal-correlation",
  "correlation_groups": [
    {
      "correlation_key": "trace_id:abc123",
      "method": "trace-id",
      "signals": [
        {
          "type": "trace",
          "source": "payment-api",
          "timestamp": "2025-01-15T10:30:00Z"
        },
        {
          "type": "log",
          "source": "payment-api",
          "message": "Connection timeout"
        },
        {
          "type": "metric",
          "source": "payment-api",
          "metric": "error_rate",
          "value": 0.05
        }
      ]
    }
  ]
}
```

## Success Criteria

- Accurate signal correlation
- Correlation method identified
- Signals grouped correctly
