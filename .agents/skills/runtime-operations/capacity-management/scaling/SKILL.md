---
name: scaling-recommendation
description: "Recommend scaling actions based on resource usage. Use when recommending HPA/VPA adjustments, node scaling, or resource limit changes."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Scaling Recommendation Engine

> **Load trigger:** `"load scaling-recommendation skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Recommend scaling actions based on resource usage.

## Responsibilities

- Recommend HPA/VPA adjustments
- Recommend node scaling
- Recommend resource limit changes
- Predict future capacity needs

## Inputs

- `saturation-report.json`
- Historical metrics

## Outputs

- `scaling-recommendations.json`

## Recommendation Types

### Horizontal Scaling (HPA)

| Condition               | Recommendation        |
| ----------------------- | --------------------- |
| CPU > 80% for 5 min     | Increase min replicas |
| CPU < 20% for 30 min    | Decrease min replicas |
| Custom metric threshold | Adjust HPA target     |

### Vertical Scaling (VPA)

| Condition                      | Recommendation        |
| ------------------------------ | --------------------- |
| Memory consistently near limit | Increase memory limit |
| CPU consistently near limit    | Increase CPU limit    |
| Overprovisioned resource       | Decrease limit        |

### Node Scaling

| Condition            | Recommendation |
| -------------------- | -------------- |
| Cluster CPU > 80%    | Add node       |
| Cluster memory > 80% | Add node       |
| Cluster CPU < 30%    | Remove node    |

### Resource Limit Changes

| Condition            | Recommendation        |
| -------------------- | --------------------- |
| OOMKilled            | Increase memory limit |
| CPU throttling > 50% | Increase CPU limit    |
| Overprovisioned      | Decrease limits       |

## Recommendation Format

```json
{
  "skill": "scaling-recommendation",
  "recommendations": [
    {
      "type": "horizontal",
      "service": "my-app",
      "current_replicas": 3,
      "recommended_replicas": 5,
      "reason": "CPU usage 85% for 10 minutes",
      "confidence": "HIGH",
      "estimated_impact": "Reduce CPU to 60%"
    },
    {
      "type": "vertical",
      "service": "worker",
      "resource": "memory",
      "current_limit": "256Mi",
      "recommended_limit": "512Mi",
      "reason": "OOMKilled 3 times in 24 hours",
      "confidence": "HIGH",
      "estimated_impact": "Eliminate OOM kills"
    }
  ]
}
```

## Success Criteria

- Useful scaling recommendations
- Recommendations include reasoning
- Confidence level assigned
