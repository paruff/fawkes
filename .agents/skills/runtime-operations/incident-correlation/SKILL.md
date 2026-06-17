---
name: incident-correlation
description: "Correlate multiple signals (logs, metrics, traces, events) into a single incident. Use when unifying alerts, anomalies, and dependency information."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Incident Correlation

> **Load trigger:** `"load incident-correlation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Correlate multiple signals (logs, metrics, traces, events) into a single incident.

## Responsibilities

- Correlate alerts
- Correlate anomalies
- Correlate service dependencies
- Produce unified incident

## Inputs

- Telemetry data (logs, metrics, traces)
- Dependency graph

## Outputs

- `correlated-incident.json`

## Sub-Skills

| Skill                                         | Purpose                              |
| --------------------------------------------- | ------------------------------------ |
| `incident-correlation/signal-correlation`     | Correlate logs, metrics, traces      |
| `incident-correlation/dependency-correlation` | Use dependency graph for correlation |

## Correlation Methods

### Time-Based

- Events within a time window (e.g., 5 minutes) are candidates
- Shorter windows = higher confidence
- Longer windows = broader correlation

### Trace-Based

- Events sharing a trace_id are correlated
- Parent-child span relationships link services

### Dependency-Based

- Upstream failure causing downstream symptoms
- Shared root cause across dependent services

### Pattern-Based

- Similar error messages across services
- Similar metric anomalies across services

## Correlation Rules

- [ ] Events within 5 minutes are candidates
- [ ] Shared trace_id = definite correlation
- [ ] Dependency path = probable correlation
- [ ] Similar pattern = possible correlation

## Output Format

```json
{
  "skill": "incident-correlation",
  "incident_id": "INC-123",
  "signals": [
    { "type": "alert", "source": "prometheus", "message": "High error rate" },
    { "type": "log", "source": "loki", "message": "Connection timeout" },
    { "type": "trace", "source": "tempo", "trace_id": "abc123" }
  ],
  "correlation_method": "trace-based",
  "root_cause_service": "payment-api",
  "affected_services": ["checkout", "order-service"]
}
```

## Success Criteria

- Accurate incident correlation
- Root cause identified
- Affected services listed
