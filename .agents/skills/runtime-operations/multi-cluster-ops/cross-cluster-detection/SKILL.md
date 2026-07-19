---
name: cross-cluster-detection
description: "Detect incidents that span multiple clusters. Use when comparing cluster metrics, detecting correlated failures, or identifying regional outages."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cross-Cluster Incident Detection

> **Load trigger:** `"load cross-cluster-detection skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Detect incidents that span multiple clusters.

## Responsibilities

- Compare cluster metrics
- Detect correlated failures
- Identify regional outages

## Inputs

- Cluster metrics (per cluster)

## Outputs

- `cross-cluster-incident.json`

## Detection Rules

### Correlated Failures

| Pattern                              | Classification         | Severity |
| ------------------------------------ | ---------------------- | -------- |
| Same service failing in 2+ clusters  | Multi-cluster incident | HIGH     |
| All services failing in 1 cluster    | Cluster outage         | CRITICAL |
| All clusters affected simultaneously | Global incident        | CRITICAL |
| Same symptom in same region          | Regional outage        | HIGH     |

### Detection Methods

- [ ] Compare error rates across clusters
- [ ] Compare latency across clusters
- [ ] Compare pod health across clusters
- [ ] Detect simultaneous failures

## Output Format

```json
{
  "skill": "cross-cluster-detection",
  "incident_detected": true,
  "incident_type": "multi-cluster",
  "affected_clusters": ["us-east-1", "eu-west-1"],
  "symptom": "payment-api high error rate",
  "evidence": [
    { "cluster": "us-east-1", "error_rate": 0.15 },
    { "cluster": "eu-west-1", "error_rate": 0.12 }
  ],
  "severity": "HIGH"
}
```

## Success Criteria

- Accurate cross-cluster detection
- Incident type classified
- Affected clusters identified
