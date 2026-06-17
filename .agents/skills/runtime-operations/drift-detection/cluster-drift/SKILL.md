---
name: cluster-drift
description: "Detect changes made directly to the cluster outside GitOps. Use when comparing live cluster state to GitOps manifests or producing drift diffs."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Cluster Drift Detection

> **Load trigger:** `"load cluster-drift skill"` > **DORA:** Cap 4 (AI Policy)
> **Token cost:** Low

## Purpose

Detect changes made directly to the cluster outside GitOps.

## Responsibilities

- Compare live cluster state to GitOps manifests
- Detect unauthorized changes
- Produce drift diff
- Classify drift severity

## Inputs

- Cluster state (from kubectl)
- GitOps manifests

## Outputs

- `cluster-drift.json`

## Comparison Scope

| Resource Type   | Comparison                      |
| --------------- | ------------------------------- |
| Deployments     | Image, replicas, env, resources |
| Services        | Ports, selector, type           |
| ConfigMaps      | Data content                    |
| Secrets         | Key names (not values)          |
| Ingresses       | Rules, TLS config               |
| NetworkPolicies | Rules                           |

## Drift Classification

| Drift                   | Severity | Example                 |
| ----------------------- | -------- | ----------------------- |
| Image tag changed       | HIGH     | Manual image update     |
| Replicas changed        | MEDIUM   | Manual scale            |
| Config changed          | HIGH     | ConfigMap edited        |
| Secret added            | HIGH     | Secret created manually |
| Resource limits changed | MEDIUM   | Resource edited         |

## Detection Logic

```
1. Get live cluster state: kubectl get <resource> -o yaml
2. Get GitOps state: kustomize build overlays/<env> | kubectl diff -
3. Identify differences
4. Classify drift severity
```

## Output Format

```json
{
  "skill": "cluster-drift",
  "drift_detected": true,
  "drift": [
    {
      "resource": "deployment/my-app",
      "namespace": "production",
      "type": "image_changed",
      "expected": "my-app:v1.2.3",
      "actual": "my-app:v1.2.4",
      "severity": "HIGH",
      "detected_at": "2025-01-15T10:30:00Z"
    }
  ]
}
```

## Success Criteria

- Accurate cluster drift detection
- All resource types compared
- Drift severity classified
