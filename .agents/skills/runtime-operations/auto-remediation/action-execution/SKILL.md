---
name: remediation-action-execution
description: "Execute automated remediation actions. Use when restarting pods, rolling back deployments, triggering GitOps reconciliation, or clearing stuck resources."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Remediation Action Execution

> **Load trigger:** `"load remediation-action-execution skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Execute automated remediation actions.

## Responsibilities

- Restart pods
- Roll back deployments
- Trigger GitOps reconciliation
- Clear stuck resources

## Inputs

- `signature-match.json`
- Cluster context

## Outputs

- `remediation-action.json`

## Action Types

### Restart Pod

```bash
kubectl delete pod <pod-name> -n <namespace>
```

### Rollback Deployment

```bash
kubectl rollout undo deployment/<name> -n <namespace>
# or
flux suspend kustomization <name> && flux resume kustomization <name>
```

### GitOps Reconciliation

```bash
flux reconcile kustomization <name> -n <namespace>
# or
argocd app sync <app-name>
```

### Clear Stuck Resource

```bash
kubectl patch pod <name> -n <namespace> -p '{"metadata":{"finalizers":[]}}'
```

## Execution Rules

- [ ] Pre-action health check recorded
- [ ] Action executed with timeout (30s default)
- [ ] Post-action health check performed
- [ ] Rollback if action fails
- [ ] Maximum 3 attempts per action

## Output Format

```json
{
  "skill": "remediation-action-execution",
  "action": "restart-pod",
  "target": "pod/my-app-abc123",
  "namespace": "production",
  "result": "success",
  "pre_action_health": "unhealthy",
  "post_action_health": "healthy",
  "duration_ms": 5000,
  "attempts": 1
}
```

## Success Criteria

- Remediation executed safely
- Health restored
- Actions logged
