---
name: cluster-chaos
description: "Validate Kubernetes resilience under node failures, pod failures, and API degradation. Use when killing pods, killing nodes, introducing API latency, or validating controller recovery."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cluster Chaos & Recovery

> **Load trigger:** `"load cluster-chaos skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Validate Kubernetes resilience under node failures, pod failures, and API degradation.

## Responsibilities

- Kill pods
- Kill nodes
- Introduce API latency
- Validate controller recovery

## Inputs

- Cluster

## Outputs

- `cluster-chaos.json`
- `recovery-report.json`

## Sub-Skills

| Skill                        | Purpose                    |
| ---------------------------- | -------------------------- |
| `cluster-chaos/pod-failure`  | Kill pods to test recovery |
| `cluster-chaos/node-failure` | Simulate node failures     |

## Chaos Scenarios

| Scenario      | Tool       | Expected Behavior                |
| ------------- | ---------- | -------------------------------- |
| Pod failure   | Chaos Mesh | Pod restarted, service available |
| Node failure  | Chaos Mesh | Workloads rescheduled            |
| API latency   | Chaos Mesh | Controller retries, queues work  |
| Disk pressure | Chaos Mesh | Eviction, reschedule             |

## Validation Rules

- [ ] Successful recovery
- [ ] No GitOps drift
- [ ] No data loss
- [ ] Service availability maintained
- [ ] Controller self-healing works

## Output Format

```json
{
  "skill": "cluster-chaos",
  "status": "success",
  "scenarios": {
    "pod_failure": { "recovered": true, "time_s": 30 },
    "node_failure": { "rescheduled": true, "time_s": 120 }
  },
  "gitops_drift": "none",
  "data_loss": "none",
  "availability": "maintained"
}
```

## Success Criteria

- Successful recovery
- No GitOps drift
- Service availability maintained
