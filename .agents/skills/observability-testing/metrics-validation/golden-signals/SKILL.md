---
name: golden-signal-validation
description: "Ensure each service exposes latency, traffic, errors, and saturation metrics. Use when validating latency histograms, error counters, saturation gauges, or traffic counters."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Golden Signal Validation

> **Load trigger:** `"load golden-signal-validation skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Ensure each service exposes latency, traffic, errors, and saturation metrics.

## Responsibilities

- Validate latency histograms
- Validate error counters
- Validate saturation gauges
- Validate traffic counters

## Inputs

- Prometheus metrics

## Outputs

- `golden-signals.json`

## Golden Signals

| Signal     | Metric Pattern                   | Type      | Example                              |
| ---------- | -------------------------------- | --------- | ------------------------------------ |
| Latency    | `<svc>_request_duration_seconds` | Histogram | `fawkes_pipe_build_duration_seconds` |
| Traffic    | `<svc>_requests_total`           | Counter   | `fawkes_pipe_builds_total`           |
| Errors     | `<svc>_errors_total`             | Counter   | `fawkes_pipe_build_errors_total`     |
| Saturation | `<svc>_utilization_ratio`        | Gauge     | `fawkes_pipe_active_builds`          |

## Per-Service Requirements

| Service | Latency            | Traffic          | Errors           | Saturation    |
| ------- | ------------------ | ---------------- | ---------------- | ------------- |
| PIPE    | build duration     | builds total     | build errors     | active builds |
| OBS     | reconcile duration | reconciles total | reconcile errors | queue depth   |
| GitOps  | sync duration      | syncs total      | sync errors      | pending syncs |
| Cluster | pod restarts       | request total    | 5xx total        | CPU/memory    |

## Validation Rules

- [ ] All four signals present per service
- [ ] Latency is histogram
- [ ] Traffic/Errors are counters
- [ ] Saturation is gauge
- [ ] Labels consistent

## Output Format

```json
{
  "skill": "golden-signal-validation",
  "status": "pass | fail",
  "services": {
    "pipe": {
      "latency": "present",
      "traffic": "present",
      "errors": "present",
      "saturation": "present"
    },
    "obs": {
      "latency": "present",
      "traffic": "present",
      "errors": "missing",
      "saturation": "present"
    }
  },
  "missing_signals": [{ "service": "obs", "signal": "errors" }]
}
```

## Success Criteria

- All four golden signals present for every service
