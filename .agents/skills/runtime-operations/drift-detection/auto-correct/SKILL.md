---
name: drift-auto-correct
description: "Automatically correct drift by reconciling cluster state with GitOps state. Use when triggering GitOps reconciliation, validating correction, or triggering rollback."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Drift Auto-Correction

> **Load trigger:** `"load drift-auto-correct skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Automatically correct drift by reconciling cluster state with GitOps state.

## Responsibilities

- Trigger GitOps reconciliation
- Validate correction
- Trigger rollback if correction fails
- Log correction actions

## Inputs

- `drift-report.json`
- GitOps context

## Outputs

- `drift-correction.json`

## Correction Actions

### GitOps Reconciliation

```bash
# Flux
flux reconcile kustomization <name> -n <namespace>

# ArgoCD
argocd app sync <app-name>
```

### Validation

```bash
# Compare after reconciliation
kubectl get <resource> -o yaml | diff - expected.yaml
```

### Rollback (if correction fails)

```bash
# Flux
flux suspend kustomization <name>
kubectl rollout undo deployment/<name> -n <namespace>

# ArgoCD
argocd app rollback <app-name>
```

## Correction Rules

- [ ] Reconciliation triggered within 1 minute of drift detection
- [ ] Correction validated after execution
- [ ] Rollback triggered if correction fails
- [ ] Maximum 2 correction attempts before escalation

## Safety Rules

- [ ] No auto-correction for SEV1 incidents
- [ ] No auto-correction for RBAC changes
- [ ] No auto-correction for secret values
- [ ] Log all correction actions

## Output Format

```json
{
  "skill": "drift-auto-correct",
  "drift_resource": "deployment/my-app",
  "correction": {
    "action": "reconcile",
    "tool": "flux",
    "result": "success",
    "validated": true
  },
  "post_correction_health": "healthy",
  "duration_ms": 5000
}
```

## Success Criteria

- Drift corrected safely
- Correction validated
- Actions logged
