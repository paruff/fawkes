---
name: security-hardening
description: Security checks for Fawkes — secrets, RBAC, container security. Load before security changes.
license: MIT
compatibility: opencode
---

# Security — Fawkes

Container security (every pod):

```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  readOnlyRootFilesystem: true
  allowPrivilegeEscalation: false
  capabilities: { drop: [ALL] }
```

Secrets: `secretKeyRef` in K8s, `${{ secrets.X }}` in CI, `sensitive = true` in Terraform. Never plaintext.

RBAC: `Role` not `ClusterRole` unless multi-namespace needed. No wildcard verbs.

SAST checks:

```bash
grep -rn "subprocess.*shell=True\|os\.system\|eval(" services/
grep -rEn "(password|secret|token)\s*=\s*['\"][^'\"]" services/ infra/ platform/
grep -L "runAsNonRoot: true" platform/apps/*/deployment.yaml
```
