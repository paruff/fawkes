# ADR-038: Native PromQL DORA Metrics

## Status

Accepted - 2026-09-16

## Context

[ADR-016](ADR-016%20devlake-dora-strategy.md) chose Apache DevLake as a dedicated
DORA-metrics ETL/visualization stack (MySQL + API + UI + collector workers) to avoid
building custom collectors. In practice, running it added a database and three services
for data that Prometheus — already deployed for cluster observability — could compute
directly from metrics ArgoCD and Tekton already expose, once the real metric names were
identified (`argocd_app_sync_total`, `tekton_pipelines_controller_pipelinerun_duration_seconds_bucket`,
confirmed live 2026-09-16 against `fawkes-dev-aks`).

DevLake was decommissioned this date: removed from
`platform/bootstrap/platform-applicationset.yaml`'s generator, live-pruned from the
cluster. `AGENTS.md` §5 already states "All 5 DORA keys computed natively in Prometheus
via recording rules... DevLake is optional (historical analytics only)" — this ADR is the
decision record that statement was missing.

## Decision

**4 of the 5 DORA keys are computed as Prometheus recording rules; the 5th (Rework Rate)
is computed separately from GitHub PR history.**

`platform/apps/prometheus/rules/dora.yml` (deployed via
`prometheus-application.yaml`'s `additionalPrometheusRulesMap`):

| Metric | Rule | Real source |
| --- | --- | --- |
| Deployment Frequency | `dora:deployment_frequency:rate30d` | `argocd_app_sync_total{phase="Succeeded"}` |
| Lead Time for Changes | `dora:lead_time_hours:p50_30d` | `tekton_pipelines_controller_pipelinerun_duration_seconds_bucket` |
| Change Failure Rate | `dora:change_failure_rate:ratio30d` | `argocd_app_sync_total{phase="Failed"}` / total |
| MTTR (FDRT) | `dora:fdrt_hours:p50_30d` | `ALERTS_FOR_STATE{alertname="ArgoCDAppDegraded"}`, a real alerting rule wired to Alertmanager (confirmed live: reached `/api/v2/alerts` during a genuine `devlake` Degraded incident) |
| **Rework Rate** | not a Prometheus rule | `scripts/weekly-metrics.sh`, GitHub PR data via `gh` |

### Rework Rate: resolving a previously-undefined metric

Three conflicting, mutually-inconsistent definitions existed in this repo before this ADR:
ADR-016's "Jenkins rebuilds / unique commits" (dead twice over — Jenkins is gone per
ADR-036, and so is DevLake), `docs/research/dora/README.md`'s "PR labels (rework) / total
PRs" proxy (never implemented — no label convention was adopted), and an earlier
same-session Prometheus proxy (`sum(argocd_app_sync_total) - count(...) / count(...)`,
i.e. extra ArgoCD syncs per app — real data, but not actually measuring rework of
developer output).

**Resolved definition**: the percentage of AI-assisted merged PRs (commits carrying this
repo's own `Co-Authored-By: Claude` attribution trailer) that needed a fix/revert
follow-up PR within 7 days of merging. This is grounded in the DORA 2026 framing already
present in this repo's own Grafana panel
(`platform/apps/grafana-dashboards/dora-metrics-dashboard-configmap.yaml`): *"Fraction of
AI output requiring rework (5th DORA metric, DORA 2026)"* — the most specific definition
this repo had, and the one referenced material (the 2025 DORA AI Capabilities Model, the
2025 State of AI-Assisted Software Development report, and the 2026 DORA ROI report;
listed in `docs/research/dora/README.md`) is consistent with, though those three PDFs are
image/CID-font marketing documents with no extractable text layer via this repo's
available tooling — direct quotation wasn't possible, so this definition is grounded in
the in-repo source, not a verbatim citation.

Implementation: `scripts/weekly-metrics.sh`, rewritten 2026-09-16 to query GitHub directly
via `gh` (previously queried DevLake's now-dead rework-rate API). A pluggable
`RepoSourceCollector` interface (`services/dora-metrics/app/collectors/`) generalizes this
beyond GitHub — GitLab, Bitbucket, AWS/Azure/GCP git+registry, in-cluster git, and Harbor
are named but not yet implemented, gated behind `AGENTS.md` §6's "ask before adding an
external dependency" rule. See `docs/METRICS.md` for the full definition, thresholds, and
known limitations (time-proximity follow-up matching, not file-overlap — see that script's
header comment).

## Consequences

### Positive

- One fewer stateful stack to operate (no MySQL, no DevLake API/UI/collector pods).
- 4 of 5 metrics are genuinely live and real-time (30s recording-rule interval) rather
  than batch-ETL-delayed.
- Rework Rate finally has one authoritative, documented definition instead of three
  conflicting ones scattered across an ADR, a research doc, and undocumented code.

### Negative

- Lead Time uses raw cumulative bucket sums, not `rate()`/`increase()` — with few real
  PipelineRuns so far, a 30d rolling window returns NaN (needs 2+ spaced samples). This is
  effectively an all-time distribution until PipelineRun volume is higher — flagged, not
  hidden, in `dora.yml`'s own comments.
- MTTR only covers currently/recently-firing incidents (`ALERTS_FOR_STATE`); Prometheus
  doesn't retain that series once an alert resolves, so no true historical p50 over 30d yet.
- Rework Rate's "follow-up" match is time-proximity only, not file-overlap — on a
  high-PR-volume week this over-counts (see `docs/METRICS.md`'s "Known limitation" note).
- No Backstage/DevLake-UI-style dashboard for historical drill-down; Grafana is the only
  visualization layer now.

## Related Decisions

- Supersedes [ADR-016: DevLake for DORA Metrics Visualization](ADR-016%20devlake-dora-strategy.md)
- Depends on [ADR-036: Tekton for CI/CD](ADR-036%20tekton-for-ci-cd.md) for the Lead Time
  source metric
- [ADR-012: Metrics Monitoring and Management](ADR-012%20Metrics%20Monitoring%20and%20Management.md)
  — the original custom-DORA-service approach ADR-016 rejected in favor of DevLake; this
  ADR returns to a native-Prometheus approach closer to ADR-012's spirit, without the
  custom webhook service ADR-012 originally proposed
