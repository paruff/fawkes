---
name: cluster-health
description: "Monitor the health of the Kubernetes cluster. Use when validating node health, pod health, controller health, or resource usage."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cluster Health Checks

> **Load trigger:** `"load cluster-health skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Monitor the health of the Kubernetes cluster.

## Responsibilities

- Validate node health
- Validate pod health
- Validate controller health
- Validate resource usage

## Inputs

- Cluster metrics
- kubectl state

## Outputs

- `cluster-health.json`

## Health Checks

### Node Health

| Check           | Healthy | Warning       | Critical      |
| --------------- | ------- | ------------- | ------------- |
| Ready condition | True    | False < 5 min | False > 5 min |
| Memory pressure | False   | True          | True > 5 min  |
| Disk pressure   | False   | True          | True > 5 min  |
| PID pressure    | False   | True          | True > 5 min  |

### System Pods

| Namespace     | Expected Status |
| ------------- | --------------- |
| kube-system   | All Running     |
| cert-manager  | All Running     |
| ingress-nginx | All Running     |
| monitoring    | All Running     |

### Controller Health

| Controller              | Healthy | Unhealthy  |
| ----------------------- | ------- | ---------- |
| kube-apiserver          | Running | NotRunning |
| kube-controller-manager | Running | NotRunning |
| kube-scheduler          | Running | NotRunning |
| etcd                    | Running | NotRunning |

### Resource Usage

| Resource       | Healthy | Warning | Critical |
| -------------- | ------- | ------- | -------- |
| Cluster CPU    | < 70%   | 70-85%  | > 85%    |
| Cluster Memory | < 70%   | 70-85%  | > 85%    |
| Pod count      | < 100   | 100-200 | > 200    |

## Output Format

```json
{
  "skill": "cluster-health",
  "cluster": "production",
  "status": "healthy",
  "nodes": { "total": 5, "ready": 5 },
  "system_pods": { "total": 15, "running": 15 },
  "resources": {
    "cpu_percent": 65,
    "memory_percent": 70,
    "pod_count": 85
  }
}
```

## Success Criteria

- Accurate cluster health reporting
- Node and pod issues detected
- Resource usage tracked
