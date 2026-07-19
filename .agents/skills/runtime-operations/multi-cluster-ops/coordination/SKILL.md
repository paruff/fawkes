---
name: cluster-coordination
description: "Coordinate remediation across multiple clusters. Use when triggering per-cluster remediation, validating cluster health, or aggregating results."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cluster Coordination Engine

> **Load trigger:** `"load cluster-coordination skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Coordinate remediation across multiple clusters.

## Responsibilities

- Trigger remediation per cluster
- Validate cluster-specific health
- Aggregate results

## Inputs

- `cross-cluster-incident.json`
- Cluster contexts

## Outputs

- `cluster-coordination.json`

## Coordination Strategies

| Strategy   | Description                            | Use When                  |
| ---------- | -------------------------------------- | ------------------------- |
| Sequential | Fix one cluster at a time              | Low risk, verify approach |
| Parallel   | Fix all clusters simultaneously        | High urgency, known fix   |
| Canary     | Fix one cluster, validate, then others | Uncertain fix             |

## Execution Rules

- [ ] Execute per-cluster remediation
- [ ] Validate each cluster after remediation
- [ ] Aggregate results
- [ ] Escalate if any cluster fails

## Output Format

```json
{
  "skill": "cluster-coordination",
  "strategy": "parallel",
  "clusters": [
    {
      "name": "us-east-1",
      "remediation": "rollback-deployment",
      "result": "success",
      "health_after": "healthy"
    },
    {
      "name": "eu-west-1",
      "remediation": "rollback-deployment",
      "result": "success",
      "health_after": "healthy"
    }
  ],
  "overall_result": "success",
  "total_duration_ms": 30000
}
```

## Success Criteria

- Coordinated multi-cluster remediation
- All clusters validated
- Results aggregated
