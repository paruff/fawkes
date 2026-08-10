# Design — Harden securityContext on extensions/data-platform K8s workloads

**Date:** 2026-08-09
**Issue:** #1584 (closes CodeQL/Trivy alerts #359 #358 #347 #341 #340 #331 #325 #324 #314 #301 #300)
**Status:** Approved

## Goal

Eliminate "Default security context configured" / "Root file system is not read-only"
alerts for `extensions/data-platform/` workloads by adding hardened container
`securityContext` blocks, mirroring the `platform/apps/tracer-bullet/deployment.yaml`
template (same pattern as companion issue #1583).

## Template

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

For containers flipped to `readOnlyRootFilesystem: true` lacking a writable mount,
add a `/tmp` emptyDir volumeMount + volume (tracer-bullet pattern).

## Files and changes

### A. Full template — 3 ingestion CronJobs

Image `acryldata/datahub-ingestion:v0.14.0` already declares `USER: datahub`
(UID/GID 1000, non-root), so full hardening is safe. Existing `config` volumeMount is
already `readOnly: true`. DataHub ingestion writes temp/log files at runtime → add
`/tmp` emptyDir.

| File | Change |
|---|---|
| `datahub/ingestion/cronjob-postgres-ingestion.yaml` | full container block (runAsNonRoot:true, runAsUser:1000, allowPrivilegeEscalation:false, readOnlyRootFilesystem:true, drop ALL, seccomp RuntimeDefault) + `/tmp` emptyDir |
| `datahub/ingestion/cronjob-kubernetes-ingestion.yaml` | same |
| `datahub/ingestion/cronjob-git-ci-ingestion.yaml` | same |

### B. Partial hardening — data-quality exporter

`data-quality/deployment-exporter.yaml` runs `pip install prometheus-client
great-expectations ...` at startup as root (`python:3.11-slim`) — writes to root-owned
site-packages on the root filesystem. Full hardening (runAsNonRoot +
readOnlyRootFilesystem) would break startup.

| File | Change |
|---|---|
| `data-quality/deployment-exporter.yaml` | allowPrivilegeEscalation:false + drop ALL + seccomp RuntimeDefault only. No runAsNonRoot/readOnly. |

**Follow-up (not in this PR):** pre-bake an image with dependencies installed so the
exporter can be fully hardened later.

## Out of scope

- No RBAC changes (issue #337 already fixed in a prior PR — do not re-touch).
- No ingestion logic, command/args, env vars, schedules, or resource-limit changes.
- Existing volumeMounts (config, exporter-script, gx-config, validation-results)
  preserved as-is.

## Validation

- `kubeconform -strict -ignore-missing-schemas` across all 4 files.
- `kubectl apply --dry-run=client -f <file>` succeeds for each.
- YAML parse + duplicate-key check.

## Open questions resolved

1. **Exporter `pip install` at runtime** → partial hardening + follow-up for pre-baked
   image (approved).
