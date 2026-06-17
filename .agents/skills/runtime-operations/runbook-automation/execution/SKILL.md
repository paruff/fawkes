---
name: runbook-execution
description: "Execute runbook steps automatically. Use when running commands, validating each step, and producing execution logs."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Runbook Execution Engine

> **Load trigger:** `"load runbook-execution skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Execute runbook steps automatically.

## Responsibilities

- Execute commands in sequence
- Validate each step
- Stop on failure
- Produce execution log

## Inputs

- `selected-runbook.json`
- Cluster context

## Outputs

- `runbook-execution.json`

## Execution Steps

### restart-pod Runbook

```
1. Identify pod: kubectl get pods -n <ns> | grep <service>
2. Check status: kubectl describe pod <pod> -n <ns>
3. Delete pod: kubectl delete pod <pod> -n <ns>
4. Wait for new pod: kubectl wait --for=condition=Ready pod -l app=<service> -n <ns> --timeout=60s
5. Validate health: kubectl get pods -n <ns> | grep <service>
```

### rollback-deployment Runbook

```
1. Identify deployment: kubectl get deployment <name> -n <ns>
2. Check rollout history: kubectl rollout history deployment/<name> -n <ns>
3. Rollback: kubectl rollout undo deployment/<name> -n <ns>
4. Wait for rollout: kubectl rollout status deployment/<name> -n <ns>
5. Validate health: kubectl get pods -n <ns> -l app=<service>
```

### cleanup-disk Runbook

```
1. Check disk usage: kubectl describe node <node> | grep -A5 "Conditions"
2. Identify large pods: kubectl top pods --sort-by=memory -n <ns>
3. Clean logs: <clean-command>
4. Verify: kubectl describe node <node> | grep -A5 "Conditions"
```

## Execution Rules

- [ ] Each step logged with timestamp
- [ ] Step result recorded (success/failure)
- [ ] Execution stops on failure
- [ ] Timeout per step: 30 seconds
- [ ] Total timeout: 5 minutes

## Output Format

```json
{
  "skill": "runbook-execution",
  "runbook": "restart-pod",
  "status": "success | failed",
  "steps": [
    {
      "step": 1,
      "command": "kubectl get pods -n production | grep my-app",
      "result": "success",
      "output": "my-app-abc123 Running",
      "duration_ms": 1200,
      "timestamp": "2025-01-15T10:30:00Z"
    }
  ],
  "total_duration_ms": 5000
}
```

## Success Criteria

- Runbook executed safely
- All steps completed
- Execution log produced
