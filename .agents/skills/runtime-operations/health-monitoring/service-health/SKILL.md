---
name: service-health
description: "Monitor the health of individual services. Use when validating readiness, liveness, error rates, or latency for specific services."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Service Health Checks

> **Load trigger:** `"load service-health skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Monitor the health of individual services.

## Responsibilities

- Validate readiness probes
- Validate liveness probes
- Validate error rates
- Validate latency

## Inputs

- Service metrics
- kubectl status

## Outputs

- `service-health.json`

## Health Checks

### Probe Validation

| Probe     | Healthy | Unhealthy        |
| --------- | ------- | ---------------- |
| Readiness | Ready   | NotReady         |
| Liveness  | Running | CrashLoopBackOff |
| Startup   | Started | Failed           |

### Metric Thresholds

| Metric       | Healthy | Warning    | Critical |
| ------------ | ------- | ---------- | -------- |
| Error rate   | < 1%    | 1-5%       | > 5%     |
| Latency p99  | < 500ms | 500-1000ms | > 1000ms |
| CPU usage    | < 70%   | 70-85%     | > 85%    |
| Memory usage | < 70%   | 70-85%     | > 85%    |

### Pod Status

| Status    | Health    |
| --------- | --------- |
| Running   | Healthy   |
| Pending   | Degraded  |
| Succeeded | N/A (job) |
| Failed    | Unhealthy |
| Unknown   | Unhealthy |

## Output Format

```json
{
  "skill": "service-health",
  "service": "my-app",
  "status": "healthy",
  "replicas": { "desired": 3, "ready": 3, "available": 3 },
  "probes": { "readiness": "passing", "liveness": "passing" },
  "metrics": {
    "error_rate": 0.5,
    "latency_p99_ms": 250,
    "cpu_percent": 45,
    "memory_percent": 60
  }
}
```

## Success Criteria

- Accurate service health reporting
- All health checks documented
- Issues flagged immediately
