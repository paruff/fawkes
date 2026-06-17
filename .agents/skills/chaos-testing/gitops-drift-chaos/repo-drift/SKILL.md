---
name: repo-drift-injection
description: "Modify GitOps repo outside OBS to test drift detection. Use when changing manifests, overlays, or image tags directly in the GitOps repo."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: GitOps Repo Drift Injection

> **Load trigger:** `"load repo-drift-injection skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Modify GitOps repo outside OBS to test drift detection.

## Responsibilities

- Change manifests
- Change overlays
- Change image tags

## Inputs

- GitOps repo

## Outputs

- `repo-drift.json`

## Injection Commands

```bash
# Change image tag
cd gitops-repo
yq -i '.spec.template.spec.containers[0].image = "my-app:drifted"' overlays/dev/deployment.yaml
git add . && git commit -m "drift: inject image tag drift"

# Change replica count
yq -i '.spec.replicas = 5' overlays/dev/deployment.yaml
git add . && git commit -m "drift: inject replica drift"

# Add extra env var
yq -i '.spec.template.spec.containers[0].env += [{"name": "DRIFT", "value": "true"}]' overlays/dev/deployment.yaml
git add . && git commit -m "drift: inject env drift"
```

## Validation Rules

- [ ] Drift injected successfully
- [ ] Drift detected by controller
- [ ] Drift corrected automatically
- [ ] No manual intervention required

## Output Format

```json
{
  "skill": "repo-drift-injection",
  "status": "success",
  "drifts": [
    {
      "type": "image_tag",
      "injected": "drifted",
      "detected": true,
      "corrected": true
    },
    {
      "type": "replica_count",
      "injected": 5,
      "detected": true,
      "corrected": true
    },
    {
      "type": "env_var",
      "injected": "DRIFT=true",
      "detected": true,
      "corrected": true
    }
  ]
}
```

## Success Criteria

- Drift detected by controller
- Drift corrected automatically
