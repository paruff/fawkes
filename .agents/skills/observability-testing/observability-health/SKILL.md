---
name: observability-health
description: "Validate that the observability stack itself is healthy, complete, and capturing all required telemetry. Use when validating Prometheus scrape health, Loki ingestion, OTel collector pipelines, dashboard coverage, or alert coverage."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Observability System Health & Coverage

> **Load trigger:** `"load observability-health skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Validate that the observability stack itself is healthy, complete, and capturing all required telemetry.

## Responsibilities

- Validate Prometheus scrape health
- Validate Loki ingestion
- Validate OTel collector pipelines
- Validate dashboard coverage
- Validate alert coverage

## Inputs

- Observability stack

## Outputs

- `observability-health.json`
- `missing-telemetry.txt`

## Sub-Skills

| Skill                             | Purpose                     |
| --------------------------------- | --------------------------- |
| `observability-health/dashboards` | Validate dashboard coverage |
| `observability-health/alerts`     | Validate alert coverage     |

## Health Checks

| Component      | Check             | Threshold |
| -------------- | ----------------- | --------- |
| Prometheus     | scrape targets up | 100%      |
| Prometheus     | scrape duration   | < 10s     |
| Loki           | ingestion rate    | > 0       |
| Loki           | query latency     | < 5s      |
| OTel Collector | dropped spans     | 0         |
| OTel Collector | export failures   | 0         |

## Validation Rules

- [ ] All scrape targets up
- [ ] Loki ingesting logs
- [ ] OTel collector dropping 0 spans
- [ ] All dashboards present
- [ ] All alerts configured

## Tools

- Prometheus
- Loki
- Grafana
- OTel Collector

## Output Format

```json
{
  "skill": "observability-health",
  "status": "healthy | degraded | unhealthy",
  "components": {
    "prometheus": { "status": "healthy", "targets_up": 20, "targets_down": 0 },
    "loki": { "status": "healthy", "ingestion_rate": "500/sec" },
    "otel_collector": { "status": "healthy", "dropped_spans": 0 },
    "grafana": { "status": "healthy" }
  },
  "missing_dashboards": [],
  "missing_alerts": []
}
```

## Success Criteria

- All telemetry pipelines healthy
- No missing dashboards or alerts
