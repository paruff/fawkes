---
name: cluster-drift-injection
description: "Modify cluster state outside GitOps to test drift detection. Use when changing replicas, environment variables, or configmaps directly in the cluster."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cluster Drift Injection

> **Load trigger:** `"load cluster-drift-injection skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Modify cluster state outside GitOps to test drift detection.

## Responsibilities

- Change replicas
- Change environment variables
- Change configmaps

## Inputs

- Cluster

## Outputs

- `cluster-drift.json`

## Injection Commands

```bash
# Change replica count
kubectl scale deployment/my-app --replicas=5 -n fawkes

# Change environment variable
kubectl set env deployment/my-app NEW_VAR=drifted -n fawkes

# Change configmap
kubectl create configmap my-config --from-literal=key=drifted -n fawkes --dry-run=client -o yaml | kubectl apply -f -
```

## Validation Rules

- [ ] Drift injected successfully
- [ ] Drift detected by OBS or controller
- [ ] Drift corrected automatically
- [ ] No manual intervention required

## Output Format

```json
{
  "skill": "cluster-drift-injection",
  "status": "success",
  "drifts": [
    {
      "type": "replica_count",
      "injected": 5,
      "detected": true,
      "corrected": true,
      "time_s": 120
    },
    {
      "type": "env_var",
      "injected": "drifted",
      "detected": true,
      "corrected": true,
      "time_s": 150
    }
  ]
}
```

## Success Criteria

- Drift detected by OBS or controller
- Drift corrected automatically
