---
name: gitops-drift-chaos
description: "Introduce drift into the cluster or GitOps repo to validate detection and correction. Use when modifying cluster resources outside GitOps, modifying manifests without OBS, or validating reconciliation behavior."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: GitOps Drift Chaos

> **Load trigger:** `"load gitops-drift-chaos skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Introduce drift into the cluster or GitOps repo to validate detection and correction.

## Responsibilities

- Modify cluster resources outside GitOps
- Modify GitOps manifests without OBS
- Validate drift detection
- Validate reconciliation behavior

## Inputs

- GitOps repo
- Cluster

## Outputs

- `drift-chaos.json`
- `drift-diff.txt`

## Sub-Skills

| Skill                              | Purpose                       |
| ---------------------------------- | ----------------------------- |
| `gitops-drift-chaos/cluster-drift` | Modify cluster state directly |
| `gitops-drift-chaos/repo-drift`    | Modify GitOps repo directly   |

## Drift Types

| Type             | Injection Method           | Expected Detection | Expected Correction  |
| ---------------- | -------------------------- | ------------------ | -------------------- |
| Replica count    | `kubectl scale`            | OBS detect         | Reconcile to desired |
| Environment vars | `kubectl set env`          | OBS detect         | Reconcile to desired |
| ConfigMap        | `kubectl create configmap` | OBS detect         | Reconcile to desired |
| Image tag        | `git commit`               | Controller detect  | Sync to desired      |
| Manifest content | `git commit`               | Controller detect  | Sync to desired      |

## Validation Rules

- [ ] Drift detected within 60s
- [ ] Drift corrected within 300s
- [ ] No manual intervention required
- [ ] State consistent after correction

## Output Format

```json
{
  "skill": "gitops-drift-chaos",
  "status": "success",
  "drifts_injected": 5,
  "detection": {
    "cluster_drift": { "detected": true, "time_s": 30 },
    "repo_drift": { "detected": true, "time_s": 45 }
  },
  "correction": {
    "cluster": { "corrected": true, "time_s": 120 },
    "repo": { "corrected": true, "time_s": 180 }
  }
}
```

## Success Criteria

- Drift detected
- Drift corrected
