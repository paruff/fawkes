# Observability Plane — Live Acceptance Test Verification (2026-09-04)

Deployed the observability plane for real (via ArgoCD, not raw `kubectl apply`)
to a local kind cluster (Docker Desktop, single node) and ran the actual BDD
acceptance suite against it — not `--dry-run`, real `kubectl`/API calls
against live resources.

## What was deployed

Via ArgoCD `Application` resources already committed in this repo
(`platform/apps/*/`), synced with `automated: {prune: true, selfHeal: true}`:

- `ingress-nginx` (controller healthy, 2 replicas)
- `prometheus-stack` (kube-prometheus-stack Helm chart: Prometheus, Alertmanager,
  Grafana, node-exporter, kube-state-metrics, Prometheus Operator) — all pods
  Running/Ready
- `platform/apps/prometheus/servicemonitors.yaml` (repo-committed ServiceMonitors
  for ArgoCD, Jenkins, SonarQube, PostgreSQL, OTel Collector — applied to see
  which resolve without their target services deployed)

## ArgoCD setup notes (for next time)

A vanilla ArgoCD install (`stable` manifest) does **not** watch Applications
outside its own namespace by default. This repo's `Application` manifests live
in `namespace: fawkes`. Two things were required beyond a plain install:

1. `argocd-cmd-params-cm` needs `application.namespaces: fawkes` (or similar),
   then restart `argocd-application-controller` + `argocd-server`.
2. The `default` `AppProject` needs `fawkes` added to `sourceNamespaces`, then
   **restart `argocd-application-controller` again** — it does not pick up
   `AppProject` changes without a restart in this version.

Neither of these is scripted anywhere in this repo's own bootstrap
(`scripts/lib/argocd.sh` uses Terraform + presumably provisions this
differently) — worth checking whether the real bootstrap path handles this
automatically or would hit the same issue.

## Real acceptance test results (`test_prometheus_stack.py`)

Before any plane was deployed: **0 passed, 22 failed** (all blocked on one
shared `Background` step requiring `ingress-nginx`).

After deploying ingress-nginx + prometheus-stack + servicemonitors.yaml:
**8 passed, 11 failed, 4 skipped** (out of 23).

### Real bugs found (not "expected, nothing deployed" failures)

1. **Missing step definition.** `Then "metrics should be available for:"` (a
   Gherkin data-table step used in 2 scenarios) has no matching
   `@then`/`@when` in `step_definitions/test_prometheus_stack.py` —
   `pytest_bdd.exceptions.StepDefinitionNotFoundError`. This is the exact
   KL-05 pattern: a scenario that looks covered but silently can't run.
2. **Resource-name mismatch.** The step checking Prometheus's StatefulSet
   looks for `prometheus-prometheus` (`kubectl -n monitoring get statefulset
   prometheus-prometheus`), but the actual resource the Helm chart creates is
   `prometheus-prometheus-prometheus` (confirmed: `kubectl -n monitoring get
   statefulset` lists `prometheus-prometheus-prometheus` and
   `alertmanager-prometheus-alertmanager`). Either the step's hardcoded name
   is stale, or the chart's naming changed since the step was written — needs
   whichever side is correct.
3. **Missing resource requests on a real container.** `grafana-sc-dashboard`
   (the Grafana dashboard-sync sidecar, confirmed running and actually doing
   its job — logs show it writing dashboard JSON files) has no CPU/memory
   `requests` set in `prometheus-application.yaml`'s Helm values. Functions
   fine, just doesn't meet the "components have resource limits" acceptance
   criterion.

### Expected failures (infra genuinely not deployed, not bugs)

- `test_prometheus_argocd_application_exists`, `test_servicemonitor_for_...postgresql` —
  need ArgoCD's own metrics endpoint / PostgreSQL actually running to be
  scraped, not just the ServiceMonitor CRD to exist
- `test_prometheus_is_scraping_metrics`, `test_prometheus_api_is_functional`,
  `test_kube_state_metrics_is_collecting_data`, `test_platform_components_are_being_monitored`,
  `test_prometheus_supports_remote_write_for_opentelemetry` — need direct
  Prometheus API access (port-forward or ingress DNS) not yet wired up in
  this pass
- `test_prometheus_datasource_configured_in_grafana`, `test_default_kubernetes_dashboards_are_imported` —
  same, need Grafana API access

## Bug fixes applied and verified

All 3 real bugs above are fixed and live-verified on this branch:

1. `@then("metrics should be available for")` → `@then("metrics should be available for:")`
   — matches the feature file's step text exactly.
2. `kubectl get statefulset prometheus-prometheus` → `prometheus-prometheus-prometheus`
   (3 occurrences) — matches the actual resource name the chart + operator create.
3. Added `sidecar.resources` (CPU/memory requests+limits) to
   `prometheus-application.yaml`'s Grafana Helm values.

Result: **9 failed, 12 passed, 2 skipped** (up from 8/11/4).

## Version currency check

Checked all 3 deployed charts/tools against their latest upstream releases:

| Component | Was pinned | Latest | Action |
|---|---|---|---|
| `ingress-nginx` | 4.11.3 | 4.15.1 | **Bumped and live-verified** — synced cleanly, controller healthy |
| `kube-prometheus-stack` | 66.3.1 | 89.2.1 | **Attempted, reverted.** Live-tested the bump: hit a real breaking change — `.spec.enableOTLPReceiver: field not declared in schema` (a genuine CRD schema mismatch between chart versions, likely needs an explicit CRD upgrade step Helm doesn't handle automatically for prometheus-operator). Reverted to 66.3.1 to avoid shipping something broken. This needs its own dedicated upgrade effort with proper CRD migration, not a drive-by bump. |
| ArgoCD (local test install only, not a repo file) | v2.13.2 | v3.5.2 | Not upgraded — this was my own local testing pin, not a committed manifest; the repo's real ArgoCD deploy path is via Terraform (`scripts/lib/argocd.sh`), version currency there wasn't checked in this pass |

## Two more bugs surfaced by fixing the first 3 (not yet fixed)

Fixing bug #1 above (the step definition) meant its body actually ran for the
first time — and immediately hit a real bug: `TypeError: list indices must be
integers or slices, not str` at `test_prometheus_stack.py:643`, inside
`metrics_available()`. The step was silently never executed before (matched
by name for zero scenarios due to the missing colon), so this bug in the
implementation itself was never caught. Needs the datatable-handling code
fixed to match pytest-bdd's actual datatable row format.

Separately, `test_prometheus_components_have_resource_limits` still fails —
not on `grafana-sc-dashboard` anymore (fixed), but now on `config-reloader`
(the sidecar Prometheus/Alertmanager use for hot-reloading config), which has
the same missing-resources gap. Same fix pattern as #3 above, different
container — not yet applied.

## GitOps enforcement (how Applications get deployed)

This repo already has a proper app-of-apps pattern at `platform/bootstrap/`:
an `ApplicationSet` with a Git directory generator watching `platform/apps/*`
— any committed `platform/apps/<name>/*-application.yaml` is auto-discovered
and gets its own ArgoCD `Application`, no manual `kubectl apply` needed. This
is the actual enforcement mechanism.

**Not used for this pass**: applying the full `ApplicationSet` would attempt
to sync all ~40+ platform components at once — well beyond what this local
kind cluster's memory can hold. Individual `Application` manifests were
applied directly instead (same committed files the ApplicationSet would
generate from — still 100% GitOps in the sense that nothing is hand-authored
outside Git, just selectively synced rather than fully auto-discovered).
The full `ApplicationSet` is the right thing to run against a real cluster
(e.g. the existing `fawkes-dev` AKS cluster) with enough capacity for the
whole platform.

Also required, undocumented anywhere in this repo, for a vanilla ArgoCD
install to watch Applications outside its own namespace (this repo's all
live in `fawkes`): patch `argocd-cmd-params-cm` with
`application.namespaces: fawkes`, add `fawkes` to the `default` AppProject's
`sourceNamespaces`, and restart `argocd-application-controller` after **each**
of those two changes separately — it doesn't pick up either live.

## Next steps

- Fix the datatable `TypeError` in `metrics_available()`
- Add `config-reloader` to the resources fix
- Wire up port-forward or ingress-DNS access so the Prometheus/Grafana API
  checks can actually run instead of failing on connectivity
- Scope and attempt the `kube-prometheus-stack` 66→89 upgrade properly, with
  CRD migration, as its own dedicated piece of work
- Repeat this same live-verification pass for the pipeline plane
  (Jenkins/Harbor/SonarQube) once scoped
