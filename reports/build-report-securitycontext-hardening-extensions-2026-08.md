# Build Report — security: harden securityContext on extensions/data-platform K8s workloads (#1584)

**Status:** COMPLETE

---

## Context

GitHub issue #1584 (P1, `type-security`, `comp-data`, `comp-security`): 11 CodeQL/Trivy
alerts (#359 #358 #347 #341 #340 #331 #325 #324 #314 #301 #300) — "Default security
context configured" / "Root file system is not read-only", all High, open since Jun 12.
Companion to #1583 (`platform/apps/`).

## Design

Hardened container `securityContext` blocks mirroring the in-repo template
(`platform/apps/tracer-bullet/deployment.yaml`):

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

Plus `/tmp` emptyDir mounts where the rootfs was flipped read-only. Full design in
`docs/superpowers/specs/2026-08-09-securitycontext-hardening-extensions-design.md`.

## Key facts

- `acryldata/datahub-ingestion:v0.14.0` (all 3 ingestion CronJobs) already declares
  `USER: datahub` created with `addgroup --gid 1000` — non-root uid 1000 by default,
  so full hardening is safe.
- `data-quality/deployment-exporter.yaml` runs `pip install` at startup as root
  (`python:3.11-slim`) — partial hardening only (approved).

## Judgment calls (flagged for human review)

1. **Exporter partial hardening** — `pip install prometheus-client great-expectations
   ...` writes to root-owned site-packages on the root filesystem at startup;
   `runAsNonRoot`/`readOnlyRootFilesystem` would break it. Follow-up: pre-baked image.

## Tasks completed

| File | Change |
|---|---|
| `datahub/ingestion/cronjob-postgres-ingestion.yaml` | full hardening + /tmp emptyDir |
| `datahub/ingestion/cronjob-kubernetes-ingestion.yaml` | full hardening + /tmp emptyDir |
| `datahub/ingestion/cronjob-git-ci-ingestion.yaml` | full hardening + /tmp emptyDir |
| `data-quality/deployment-exporter.yaml` | partial hardening (no runAsNonRoot/readOnly) |

## Validation results

| Check | Status |
|---|---|
| YAML parse + duplicate-key check (4 files) | PASS |
| kubeconform `-strict -ignore-missing-schemas` | PASS (15/15 resources) |
| kubectl apply `--dry-run=client` (4 files) | PASS |
| No command/args/env/schedule/RBAC/resource changes | PASS (verified via diff) |
| CI (PR #1595) | PASS (20/20 checks: Pre-commit, CodeQL, PR Size Gate, validate-and-scan, e2e-tests, GitGuardian, Main CI Gate) |

## Artifacts

- PR: https://github.com/paruff/fawkes/pull/1595
- Branch: `security/1584-harden-securitycontext-extensions`
- Design doc: `docs/superpowers/specs/2026-08-09-securitycontext-hardening-extensions-design.md`

## Blockers

None.
