---
name: resource-usage-profiling
description: "Profile CPU, memory, and I/O usage under load. Use when collecting resource metrics, correlating usage with pipeline load, or identifying hotspots."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Resource Usage Profiling

> **Load trigger:** `"load resource-usage-profiling skill"` > **DORA:** Cap 6 (Operational Visibility)
> **Token cost:** Low

## Purpose

Profile CPU, memory, and I/O usage under load.

## Responsibilities

- Collect resource metrics
- Correlate usage with pipeline load
- Identify hotspots

## Inputs

- Metrics from Prometheus

## Outputs

- `resource-usage.json`

## Resource Metrics

| Metric       | Source        | Threshold      |
| ------------ | ------------- | -------------- |
| CPU usage    | node_exporter | > 80% warning  |
| Memory usage | node_exporter | > 80% warning  |
| Disk I/O     | node_exporter | > 90% critical |
| Network I/O  | node_exporter | > 80% warning  |
| Pod CPU      | kubelet       | > 80% warning  |
| Pod Memory   | kubelet       | > 80% warning  |

## Validation Rules

- [ ] All resource metrics collected
- [ ] Hotspots identified
- [ ] Resource bottlenecks documented
- [ ] Recommendations provided

## Output Format

```json
{
  "skill": "resource-usage-profiling",
  "status": "pass | fail",
  "resources": {
    "cpu": { "peak_percent": 75, "avg_percent": 60, "hotspot": "pipe-build" },
    "memory": {
      "peak_percent": 70,
      "avg_percent": 55,
      "hotspot": "obs-reconcile"
    },
    "disk_io": { "peak_percent": 40, "avg_percent": 25 },
    "network_io": { "peak_percent": 50, "avg_percent": 30 }
  },
  "hotspots": ["pipe-build", "obs-reconcile"],
  "recommendations": ["Scale pipe-build horizontally"]
}
```

## Success Criteria

- Clear resource bottlenecks identified
