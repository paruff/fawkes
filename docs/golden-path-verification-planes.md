# Golden Path Verification Planes

This is the canonical reference for the tracer-bullet / smart-alerting golden-path
verification effort tracked under [#1751](https://github.com/paruff/fawkes/issues/1751)
Phase 3. It answers: what does "the golden path is verified" actually mean, plane by
plane, and where does each plane's check live?

Do not confuse this with `docs/golden-path-usage.md`, which documents the Jenkins-based
`goldenPathPipeline` shared-library pipeline for application teams — an older, separate
concept that predates this GitHub-Actions-based verification effort.

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
| **Observability** | Real traces reach Tempo and real metrics reach Prometheus for the service                        | `scripts/validate-golden-path-observability.sh`   | Implemented — needs extension (OpenSearch log correlation, OpenTelemetry Collector pipeline health) |
| **DORA**          | Deployment-frequency/lead-time metrics for the service are visible and populated                 | `scripts/validate-golden-path-dora.sh`            | Implemented                   |
| **Security**      | No unauthenticated write endpoints, no exposed secrets, image signature verifies, no unresolved CRITICAL/HIGH vulnerabilities | `scripts/validate-golden-path-security.sh`        | Planned                       |
| **Resources**     | The workload's actual pod/CPU/memory/storage footprint is known and within budget; PostgreSQL (CloudNativePG) backing store is healthy and reachable | `scripts/validate-golden-path-resources.sh`       | Planned                       |
| **DevEx**         | The service is discoverable and usable through the platform's developer-facing surface — Backstage catalog entry, TechDocs, scaffolder template | `scripts/validate-golden-path-devex.sh`           | Planned                       |

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
