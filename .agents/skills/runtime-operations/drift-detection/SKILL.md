---
name: drift-detection
description: "Detect and correct drift between GitOps state and cluster state. Use when detecting cluster drift, GitOps repo drift, or triggering correction."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Drift Detection & Correction

> **Load trigger:** `"load drift-detection skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Detect and correct drift between GitOps state and cluster state.

## Responsibilities

- Detect cluster drift (direct changes to cluster)
- Detect GitOps repo drift (manual edits to repo)
- Validate reconciliation status
- Trigger correction or rollback

## Inputs

- GitOps repo
- Cluster state

## Outputs

- `drift-report.json`
- `drift-diff.txt`

## Sub-Skills

| Skill                           | Purpose                                 |
| ------------------------------- | --------------------------------------- |
| `drift-detection/cluster-drift` | Detect changes made directly to cluster |
| `drift-detection/auto-correct`  | Automatically correct drift             |

## Drift Types

| Type          | Description                  | Detection           |
| ------------- | ---------------------------- | ------------------- |
| Cluster drift | Manual kubectl changes       | Compare to GitOps   |
| Repo drift    | Manual edits to GitOps repo  | Compare to expected |
| Config drift  | Environment variable changes | Compare to config   |

## Detection Rules

- [ ] Cluster state compared to GitOps manifests
- [ ] Drift detected within 1 minute
- [ ] Drift severity classified
- [ ] Correction triggered for auto-correctable drift

## Correction Actions

| Drift Type           | Correction                    |
| -------------------- | ----------------------------- |
| Deployment image tag | GitOps reconciliation         |
| ConfigMap change     | GitOps reconciliation         |
| Secret change        | GitOps reconciliation         |
| RBAC change          | GitOps reconciliation + audit |

## Output Format

```json
{
  "skill": "drift-detection",
  "drift_detected": true,
  "drift_type": "cluster",
  "resources_affected": [
    {
      "resource": "deployment/my-app",
      "expected": { "image": "my-app:v1.2.3" },
      "actual": { "image": "my-app:v1.2.4" },
      "severity": "medium"
    }
  ],
  "correction_triggered": true
}
```

## Success Criteria

- Accurate drift detection
- Drift classified by severity
- Correction triggered when appropriate
