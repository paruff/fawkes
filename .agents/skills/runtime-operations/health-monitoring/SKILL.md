---
name: health-monitoring
description: "Continuously monitor the health of services, clusters, and pipelines. Use when validating readiness/liveness, rollout health, cluster health, or GitOps reconciliation."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Health Monitoring

> **Load trigger:** `"load health-monitoring skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Continuously monitor the health of services, clusters, and pipelines.

## Responsibilities

- Validate readiness/liveness probes
- Validate rollout health
- Validate cluster health
- Validate GitOps reconciliation health

## Inputs

- Cluster state
- Metrics
- GitOps status

## Outputs

- `health-report.json`
- `degraded-components.txt`

## Sub-Skills

| Skill                              | Purpose                           |
| ---------------------------------- | --------------------------------- |
| `health-monitoring/service-health` | Monitor individual service health |
| `health-monitoring/cluster-health` | Monitor cluster-level health      |

## Health Checks

| Check           | Healthy  | Degraded     | Unhealthy |
| --------------- | -------- | ------------ | --------- |
| Readiness probe | Passing  | Intermittent | Failing   |
| Liveness probe  | Passing  | N/A          | Failing   |
| Rollout status  | Complete | In progress  | Failed    |
| GitOps sync     | Synced   | Behind       | Error     |

## Monitoring Rules

- [ ] Service health checked every 30 seconds
- [ ] Cluster health checked every 1 minute
- [ ] GitOps health checked every 1 minute
- [ ] Degraded services flagged immediately

## Output Format

```json
{
  "skill": "health-monitoring",
  "overall_status": "healthy",
  "services": {
    "my-app": { "status": "healthy", "replicas": 3, "ready": 3 },
    "worker": { "status": "degraded", "replicas": 3, "ready": 2 }
  },
  "cluster": { "status": "healthy", "nodes": 5, "ready": 5 },
  "gitops": { "status": "synced", "last_sync": "2025-01-15T10:30:00Z" }
}
```

## Success Criteria

- Accurate health assessment
- Degraded components identified
- Timely detection
