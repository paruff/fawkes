---
name: capacity-management
description: "Monitor and manage cluster and service capacity. Use when tracking CPU/memory usage, detecting saturation, or recommending scaling actions."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Capacity & Resource Management

> **Load trigger:** `"load capacity-management skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Monitor and manage cluster and service capacity.

## Responsibilities

- Track CPU/memory usage
- Detect resource saturation
- Recommend scaling actions
- Trigger auto-scaling

## Inputs

- Metrics (CPU, memory, disk, network)
- Cluster state

## Outputs

- `capacity-report.json`
- `scaling-recommendations.json`

## Sub-Skills

| Skill                            | Purpose                    |
| -------------------------------- | -------------------------- |
| `capacity-management/saturation` | Detect resource saturation |
| `capacity-management/scaling`    | Recommend scaling actions  |

## Capacity Thresholds

| Resource     | Healthy | Warning | Critical |
| ------------ | ------- | ------- | -------- |
| CPU usage    | < 70%   | 70-85%  | > 85%    |
| Memory usage | < 70%   | 70-85%  | > 85%    |
| Disk usage   | < 70%   | 70-85%  | > 85%    |
| Network      | < 50%   | 50-75%  | > 75%    |

## Scaling Rules

| Condition               | Action                 |
| ----------------------- | ---------------------- |
| CPU > 80% for 5 min     | Scale up replicas      |
| Memory > 80% for 5 min  | Increase memory limits |
| CPU < 20% for 30 min    | Scale down replicas    |
| Node count insufficient | Add nodes              |

## Output Format

```json
{
  "skill": "capacity-management",
  "cluster": "production",
  "nodes": 5,
  "capacity": {
    "cpu": { "total": "20 cores", "used": "14 cores", "percent": 70 },
    "memory": { "total": "80Gi", "used": "56Gi", "percent": 70 }
  },
  "services": [
    {
      "name": "my-app",
      "cpu_percent": 45,
      "memory_percent": 60,
      "replicas": 3,
      "scaling_needed": false
    }
  ]
}
```

## Success Criteria

- Accurate capacity insights
- Saturation detected
- Scaling recommendations provided
