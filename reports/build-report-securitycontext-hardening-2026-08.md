# Build Report — security: harden securityContext on platform/apps K8s workloads (#1583)

**Status:** COMPLETE

---

## Context

GitHub issue #1583 (P1, `type-security`, `comp-security`): 18 CodeQL/Trivy alerts
(#907 #906 #895 #889 #888 #877 #856 #855 #840 #819 #809 #794 #766 #762 #651 #635 #620 #606)
— "Default security context configured" / "Root file system is not read-only", all High,
open since Jun 12 on `main`.

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

Plus a `/tmp` emptyDir mount where the rootfs was flipped read-only (tracer-bullet
pattern). Full design + three resolved conflicts recorded in
`docs/superpowers/specs/2026-08-09-securitycontext-hardening-design.md`.

## Judgment calls (flagged for human review)

1. **Opensearch Jobs** (`ism-retention-policy`, `configure-index-patterns`): partial
   hardening only — `allowPrivilegeEscalation: false`, drop ALL, seccomp. Jobs run
   `apk add --no-cache curl jq` as root at runtime; `runAsNonRoot`/`readOnlyRootFilesystem`
   would break them. Follow-up: pre-baked curl+jq image.
2. **devex pulse-reminders cronjob**: partial hardening for the same reason
   (`pip install` at runtime). Follow-up: pre-baked image.
3. **echo-server fixture** (`ingress-nginx/test-ingress.yaml`): full hardening +
   `NET_BIND_SERVICE` re-added so port 80 still binds as non-root.
4. **feedback-service/cronjob-automation.yaml**: skipped — already fully hardened on
   main; issue list stale for this file.

## Tasks completed

| File | Change |
|---|---|
| `opensearch/ism-retention-policy.yaml` | partial (no runAsNonRoot/readOnly) |
| `opensearch/configure-index-patterns.yaml` | partial (no runAsNonRoot/readOnly) |
| `ingress-nginx/test-ingress.yaml` | full + NET_BIND_SERVICE |
| `hasura/redis.yaml` | full |
| `hasura/deployment.yaml` | full |
| `friction-bot/deployment.yaml` | full (flip readOnly false→true) |
| `feedback-service/deployment.yaml` | full (flip readOnly false→true) |
| `devex-survey-automation/deployment.yaml` | full |
| `devex-survey-automation/cronjob-quarterly.yaml` | full |
| `devex-survey-automation/cronjob-pulse-weekly.yaml` | full |
| `devex-survey-automation/cronjob-pulse-reminders.yaml` | partial (pip install) |

## Validation results

| Check | Status |
|---|---|
| YAML parse (all 11 files) | PASS |
| kubeconform `-strict -ignore-missing-schemas` | PASS (19/19 resources) |
| kubectl apply `--dry-run=client` (all 11 files) | PASS |
| yamllint | PASS (no new findings; pre-existing comment-style warnings only) |
| No image/command/args/env/resource changes | PASS (verified via diff) |
| CI (PR #1594) | PASS (21/21 checks: Pre-commit Platform, CodeQL, PR Size Gate, validate-and-scan, e2e-tests, GitGuardian, Main CI Gate) |

## Artifacts

- PR: https://github.com/paruff/fawkes/pull/1594
- Branch: `security/1583-harden-securitycontext-platform-apps`
- Design doc: `docs/superpowers/specs/2026-08-09-securitycontext-hardening-design.md`

## Blockers

None.
