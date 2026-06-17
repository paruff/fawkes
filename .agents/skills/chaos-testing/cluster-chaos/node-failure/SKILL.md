---
name: node-failure-chaos
description: "Simulate node failures to validate cluster resilience. Use when draining nodes, deleting nodes, or validating workload rescheduling."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Node Failure Chaos

> **Load trigger:** `"load node-failure-chaos skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Simulate node failures to validate cluster resilience.

## Responsibilities

- Drain nodes
- Delete nodes
- Validate workload rescheduling

## Inputs

- Cluster nodes

## Outputs

- `node-failure.json`

## Node Failure Methods

| Method     | Tool                  | Impact                         |
| ---------- | --------------------- | ------------------------------ |
| Drain      | `kubectl drain`       | Pods evicted, rescheduled      |
| Delete     | `kubectl delete node` | Node removed, pods rescheduled |
| Cordon     | `kubectl cordon`      | No new pods scheduled          |
| Chaos Mesh | NodeChaos             | Automated node failure         |

## Chaos Mesh Config

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: NodeChaos
metadata:
  name: node-failure
spec:
  action: node-failure
  mode: one
  selector:
    labelSelectors:
      "node-role": "worker"
```

## Validation Rules

- [ ] Node failure simulated
- [ ] Workloads rescheduled
- [ ] Service availability maintained
- [ ] No data loss
- [ ] PVC migration successful

## Output Format

```json
{
  "skill": "node-failure-chaos",
  "status": "success",
  "node": "worker-2",
  "method": "drain",
  "pods_evicted": 5,
  "pods_rescheduled": 5,
  "reschedule_time_s": 60,
  "availability": "maintained",
  "data_loss": "none"
}
```

## Success Criteria

- Successful rescheduling
- Service availability maintained
- No data loss
