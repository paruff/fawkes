# Golden Path Verification Planes

This is the canonical reference for the python-fawkes-path / smart-alerting golden-path
verification effort tracked under [#1751](https://github.com/paruff/fawkes/issues/1751)
Phase 3. It answers: what does "the golden path is verified" actually mean, plane by
plane, and where does each plane's check live?

Do not confuse this with `docs/golden-path-usage.md`, which documents the Jenkins-based
`goldenPathPipeline` shared-library pipeline for application teams — an older, separate
concept that predates this GitHub-Actions-based verification effort.

**Update (2026-09-07, #1804):** the reference service these planes verify against —
python-fawkes-path — was extracted out of the monorepo into its own repo pair:
[`paruff/python-fawkes-path`](https://github.com/paruff/python-fawkes-path) (app source, plus the
Tekton `golden-path` pipeline definition it runs against —
`platform/apps/tekton/golden-path-pipeline.yaml`, in-cluster, not GitHub Actions) and
[`paruff/python-fawkes-path-gitops`](https://github.com/paruff/python-fawkes-path-gitops) (desired
state, watched by `platform/apps/python-fawkes-path/python-fawkes-path-application.yaml`). All
seven planes were exercised live on a local kind cluster this session against this real
pipeline run. That live run surfaced 4 concrete bugs in the plane scripts themselves,
filed as [#1909](https://github.com/paruff/fawkes/issues/1909): the Pipeline script
hardcodes a workflow filename deleted in #1813 and the monorepo's own repo slug (needs to
target the external repo); the GitOps script's namespace default doesn't match where
`Application` CRs actually live (`argocd`, not `fawkes`); the DORA script looks for a pod
that doesn't exist. The Observability script was the one plane confirmed accurate as-is.
The "Implemented" status below predates this finding — treat it as "script exists," not
"script is correct," until #1909 is fixed.

## What a "plane" is

A **plane** is one independently-verifiable slice of the golden path: `git push` → CI
build/scan/sign → ArgoCD auto-sync → traces/metrics/DORA visible → running healthy
workload. Each plane has its own `scripts/validate-golden-path-<plane>.sh` script that:

- Is independently runnable (no dependency on the other planes' scripts)
- Exits 0/1 (pass/fail) so it can gate CI or be run ad hoc
- Writes its own timestamped JSON report to `reports/golden-path-<plane>-validation-*.json`

## Planes

| Plane             | Purpose                                                                                          | Script                                            | Status                        |
| ------------------ | ------------------------------------------------------------------------------------------------- | -------------------------------------------------- | ------------------------------ |
| **Pipeline**      | The latest CI run actually built, scanned, SBOM'd, and signed a real image — not just that the workflow file exists | `scripts/validate-golden-path-pipeline.sh`        | Implemented                   |
| **GitOps**        | ArgoCD's Application is Synced/Healthy and the live Deployment's image matches git HEAD          | `scripts/validate-golden-path-gitops.sh`          | Implemented                   |
| **Observability** | Real traces reach Tempo, real metrics reach Prometheus, the OpenTelemetry Collector is healthy, and Loki (log backend) is reachable and ready | `scripts/validate-golden-path-observability.sh`   | Implemented                   |
| **DORA**          | Deployment-frequency/lead-time metrics for the service are visible and populated                 | `scripts/validate-golden-path-dora.sh`            | Implemented                   |
| **Security**      | Live image signature verifies, pod securityContext is hardened, smart-alerting rejects unauthenticated alert-ingestion requests (AUD-2), no plaintext credential placeholders remain | `scripts/validate-golden-path-security.sh`        | Implemented — core checks. See below for planned additions (secrets management, policy, code analysis, network security) |
| **Resources**     | Every golden-path container declares CPU/memory requests and limits, actual usage is known, PVCs are Bound, and the PostgreSQL (CloudNativePG) backing cluster is healthy | `scripts/validate-golden-path-resources.sh`       | Implemented — core checks. See below for planned additions (messaging, key-value, SSO) |
| **DevEx**         | The service is discoverable and usable through the platform's developer-facing surface — catalog-info.yaml exists, Backstage is deployed, and the component is registered in its live catalog | `scripts/validate-golden-path-devex.sh`           | Implemented — core checks. See below for planned additions (CDE, chat, kanban) |
| **Progressive Delivery** | Argo Rollouts' Rollout CRD exists with a canary strategy, an AnalysisTemplate is referenced, and any rollback event in status/history completed successfully | `scripts/validate-golden-path-progressive-delivery.sh` | Implemented |

### Planned additions

Recorded here so scope is tracked before it's built — none of these have a script yet.
Each row notes whether the underlying platform component already exists (a check-script
task) or would need new platform infrastructure first (a bigger undertaking, out of scope
for a quick follow-up).

**Security plane:**

| Addition | Existing platform component? |
| -------- | ------------------------------ |
| Secrets management (no secrets reachable outside Vault/Sealed Secrets/External Secrets) | Yes — `platform/apps/vault`, `sealed-secrets`, `external-secrets` |
| Policy enforcement (Kyverno policies are actually enforced, not just installed) | Yes — `platform/apps/kyverno`, `platform/policies/generation-policies.yaml` |
| Code analysis (SonarQube quality gate passes for the service) | Yes — `platform/apps/sonarqube-application.yaml` |
| Network-based security (NetworkPolicies actually restrict traffic, not just exist) | Yes — e.g. `platform/apps/eclipse-che/network-policies.yaml`; golden-path services don't have their own yet |

**Resources plane:**

| Addition | Existing platform component? |
| -------- | ------------------------------ |
| Messaging (e.g. RabbitMQ) | **No** — not yet in `platform/apps/` |
| Key-value store (e.g. Redis) | **No** — not yet in `platform/apps/` |
| Single sign-on | **No** — not yet in `platform/apps/` |

**DevEx plane:**

| Addition | Existing platform component? |
| -------- | ------------------------------ |
| CDE (cloud development environment) | Yes — `platform/apps/eclipse-che` fills this role today |
| Team chat | Yes — `platform/apps/mattermost` |
| Kanban / project board | Yes — `platform/apps/focalboard` |

The Resources-plane items have no existing platform component — verifying them means
standing up new infrastructure first, not just writing a check script. Recommend scoping
that as its own issue rather than folding it into #1751 Phase 3, which is specifically
about proving the python-fawkes-path/smart-alerting golden path, not building out new platform
capabilities.

## Adding or changing a plane

1. Add a row to the table above before writing code — this doc is the source of truth for
   what "verified" means, not the script itself.
2. Follow the existing `scripts/validate-golden-path-*.sh` structure (see any implemented
   script for the pattern: `record_test`, `generate_report`, `print_summary`).
3. Link the new script from this table and from the relevant phase in
   [#1751](https://github.com/paruff/fawkes/issues/1751) or its successor issue.

## Related

- `reports/production-audit-2026-09.md` — live-cluster findings that motivated this plan
- `reports/observability-plane-live-verification-2026-09.md`
- `docs/DEPLOYMENT_STRATEGY.md` — MVP Definition of Done, rollback protocol
- `docs/BACKLOG.md` — wave plan and service inventory
- [#1909](https://github.com/paruff/fawkes/issues/1909) — the 4 plane-script bugs found during the 2026-09-07 live verification, with acceptance criteria to fix them and wire them into a scheduled (≥weekly) CI job
