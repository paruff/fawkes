---
name: incident-detection
description: "Detect operational issues in real time using logs, metrics, traces, and events. Use when monitoring golden signals, detecting anomalies, or evaluating alert rules."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Incident Detection

> **Load trigger:** `"load incident-detection skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Detect operational issues in real time using logs, metrics, traces, and events.

## Responsibilities

- Monitor golden signals (latency, errors, saturation, traffic)
- Detect anomalies
- Detect alert rule triggers
- Detect regression from SLO targets

## Inputs

- Prometheus metrics
- Loki logs
- OTel traces

## Outputs

- `incident-detection.json`
- `anomaly-report.json`

## Sub-Skills

| Skill                                 | Purpose                                    |
| ------------------------------------- | ------------------------------------------ |
| `incident-detection/anomaly`          | Detect unusual patterns in telemetry       |
| `incident-detection/alert-evaluation` | Evaluate alert rules and trigger incidents |

## Golden Signals

| Signal     | Metric            | Threshold         |
| ---------- | ----------------- | ----------------- |
| Latency    | p99 response time | > 500ms           |
| Errors     | Error rate        | > 1%              |
| Saturation | CPU/Memory usage  | > 80%             |
| Traffic    | Request rate      | Anomaly detection |

## Detection Rules

- [ ] Golden signals monitored continuously
- [ ] Anomalies detected within 1 minute
- [ ] Alert rules evaluated on schedule
- [ ] Incidents created for triggered alerts

## Tools

- Prometheus for metrics
- Loki for logs
- OTel Collector for traces

## Success Criteria

- Accurate detection of incidents and anomalies
- No false negatives for critical issues
