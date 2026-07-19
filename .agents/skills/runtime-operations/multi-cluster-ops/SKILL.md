---
name: multi-cluster-ops
description: "Monitor and manage multiple clusters across regions. Use when validating cluster health, detecting cross-cluster incidents, or coordinating remediation."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Multi-Cluster Operations

> **Load trigger:** `"load multi-cluster-ops skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Monitor and manage multiple clusters across regions.

## Responsibilities

- Validate cluster health
- Detect cross-cluster incidents
- Coordinate remediation
- Aggregate cluster metrics

## Inputs

- Cluster list
- Telemetry data

## Outputs

- `multi-cluster-report.json`

## Sub-Skills

| Skill                                       | Purpose                              |
| ------------------------------------------- | ------------------------------------ |
| `multi-cluster-ops/cross-cluster-detection` | Detect cross-cluster incidents       |
| `multi-cluster-ops/coordination`            | Coordinate multi-cluster remediation |

## Cluster Health Checks

| Check       | Healthy     | Warning       | Critical      |
| ----------- | ----------- | ------------- | ------------- |
| API server  | responding  | slow          | unreachable   |
| Nodes ready | all ready   | 1-2 not ready | > 2 not ready |
| System pods | all running | some failing  | most failing  |
| Certificate | valid > 30d | valid < 30d   | expired       |

## Multi-Cluster Patterns

| Pattern        | Description                        |
| -------------- | ---------------------------------- |
| Active-Active  | All clusters serve traffic         |
| Active-Passive | One cluster serves, others standby |
| Regional       | Clusters per region, isolated      |

## Output Format

```json
{
  "skill": "multi-cluster-ops",
  "clusters": [
    {
      "name": "us-east-1",
      "status": "healthy",
      "nodes": 5,
      "cpu_percent": 65,
      "memory_percent": 70
    },
    {
      "name": "eu-west-1",
      "status": "degraded",
      "nodes": 3,
      "cpu_percent": 85,
      "memory_percent": 75
    }
  ],
  "cross_cluster_incidents": []
}
```

## Success Criteria

- All clusters monitored
- Cross-cluster incidents detected
- Remediation coordinated
