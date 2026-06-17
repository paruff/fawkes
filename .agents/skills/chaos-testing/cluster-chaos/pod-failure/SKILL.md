---
name: pod-failure-chaos
description: "Kill pods to validate controller and application recovery. Use when killing application pods, OBS/PIPE pods, or validating restart behavior."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Pod Failure Chaos

> **Load trigger:** `"load pod-failure-chaos skill"` > **DORA:** Cap 5 (Operational Resilience)
> **Token cost:** Low

## Purpose

Kill pods to validate controller and application recovery.

## Responsibilities

- Kill application pods
- Kill OBS/PIPE pods
- Validate restart behavior

## Inputs

- Target pods

## Outputs

- `pod-failure.json`

## Kill Targets

| Pod               | Kill Method          | Expected Recovery       |
| ----------------- | -------------------- | ----------------------- |
| Application pod   | `kubectl delete pod` | Deployment restarts pod |
| OBS pod           | `kubectl delete pod` | Deployment restarts pod |
| PIPE pod          | `kubectl delete pod` | Deployment restarts pod |
| GitOps controller | `kubectl delete pod` | Deployment restarts pod |

## Chaos Mesh Config

```yaml
apiVersion: chaos-mesh.org/v1alpha1
kind: PodChaos
metadata:
  name: pod-kill
  namespace: fawkes
spec:
  action: pod-kill
  mode: one
  selector:
    namespaces: [fawkes]
    labelSelectors:
      app: my-app
```

## Validation Rules

- [ ] Pod killed successfully
- [ ] Pod restarted by controller
- [ ] Service availability maintained
- [ ] No data loss

## Output Format

```json
{
  "skill": "pod-failure-chaos",
  "status": "success",
  "pods_killed": 3,
  "recovery": [
    { "pod": "my-app-abc123", "killed": true, "restarted": true, "time_s": 15 },
    { "pod": "obs-def456", "killed": true, "restarted": true, "time_s": 20 }
  ],
  "availability": "maintained"
}
```

## Success Criteria

- Successful pod recovery
- Service availability maintained
