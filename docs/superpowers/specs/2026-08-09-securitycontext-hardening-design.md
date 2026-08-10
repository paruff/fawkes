# Design — Harden securityContext on platform/apps K8s workloads

**Date:** 2026-08-09
**Issue:** #1583 (closes CodeQL/Trivy alerts #907 #906 #895 #889 #888 #877 #856 #855 #840 #819 #809 #794 #766 #762 #651 #635 #620 #606)
**Status:** Approved

## Goal

Eliminate "Default security context configured" / "Root file system is not read-only"
alerts for `platform/apps/` workloads by adding hardened container `securityContext`
blocks, mirroring the existing `platform/apps/tracer-bullet/deployment.yaml` template.

## Template

Full hardening block (matches tracer-bullet):

```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: [ALL]
  seccompProfile:
    type: RuntimeDefault
```

For every container flipped to `readOnlyRootFilesystem: true` that lacks a writable
mount, add a `/tmp` emptyDir volumeMount + volume (the tracer-bullet pattern), so temp
writes keep working on a read-only root filesystem.

## Files and changes

### A. Full template (missing / nearly complete)

| File | Current state | Change |
|---|---|---|
| `devex-survey-automation/deployment.yaml` | pod ctx only (1000), no container block | add full container block + `/tmp` emptyDir |
| `devex-survey-automation/cronjob-quarterly.yaml` | only runAsNonRoot:true, runAsUser:65534 | add allowPrivilegeEscalation:false, drop ALL, readOnly:true, seccomp, `/tmp` emptyDir |
| `devex-survey-automation/cronjob-pulse-weekly.yaml` | same | same |
| `devex-survey-automation/cronjob-pulse-reminders.yaml` | same | same |
| `hasura/deployment.yaml` | allowPrivilegeEscalation:false, drop ALL, readOnly:false | add runAsNonRoot:true, flip readOnly:true, add seccomp, `/tmp` emptyDir |
| `hasura/redis.yaml` | allowPrivilegeEscalation:false, drop ALL | add runAsNonRoot:true, readOnly:true, seccomp, `/tmp` emptyDir (persistence disabled: `save ""`, `appendonly no`) |
| `friction-bot/deployment.yaml` | most fields present, readOnly:false | flip readOnly:true, add seccomp, `/tmp` emptyDir |
| `feedback-service/deployment.yaml` | most fields present, readOnly:false | flip readOnly:true, add seccomp, `/tmp` emptyDir |

### B. Full template + NET_BIND_SERVICE (privileged-port fixture)

| File | Change |
|---|---|
| `ingress-nginx/test-ingress.yaml` | full template + `capabilities.add: [NET_BIND_SERVICE]`, runAsUser 65534, `/tmp` emptyDir. Container binds port 80; a non-root user without NET_BIND_SERVICE cannot bind ports < 1024. |

### C. Partial hardening (root + writable fs required at runtime)

| File | Change |
|---|---|
| `opensearch/ism-retention-policy.yaml` | allowPrivilegeEscalation:false + drop ALL + seccomp RuntimeDefault only. Job runs `apk add --no-cache curl jq` as root — runAsNonRoot + readOnly would break it. |
| `opensearch/configure-index-patterns.yaml` | same |

**Follow-up (not in this PR):** pre-bake a curl+jq image for the opensearch Jobs so they
can be fully hardened (runAsNonRoot + readOnlyRootFilesystem) in a later change.

## Out of scope / excluded

- `feedback-service/cronjob-automation.yaml` — already fully hardened on main
  (allowPrivilegeEscalation:false, drop ALL, readOnly:true, runAsNonRoot:true,
  runAsUser:65534, seccomp RuntimeDefault). Issue list is stale for this file.
- No image / command / args / env / resource-limit changes in any file.
- No pod-level securityContext changes (existing pod contexts are preserved as-is).

## Validation

- `kubeconform -strict -ignore-missing-schemas -summary` across all 11 files
  (CI pre-commit hook only covers `infra/kubernetes/`, so `platform/apps/` is validated manually).
- `python -c "import yaml; yaml.safe_load(open('FILE'))"` syntax check each file.
- Confirm no `latest` image tags introduced and no resource limit changes.

## Open questions resolved

1. **Opensearch Jobs + `apk add`** → partial hardening + follow-up issue for pre-baked image (approved).
2. **echo-server port 80** → full harden + NET_BIND_SERVICE (approved).
3. **feedback cronjob already compliant** → skip (approved).
