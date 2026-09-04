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
| `opensearch` | chart 2.17.0 / app 2.11.1 | chart 3.8.0 / app 3.8.0 | **Bumped and live-verified.** Cluster status `green`, 1/1 node, all shards active. See below — 3 real bugs found and fixed along the way, none of them actually caused by the version bump itself (all present at the pinned baseline too, just never live-tested before). |
| `opentelemetry-collector` | chart 0.108.0 / image 0.114.0 | chart 0.172.0 / image 0.159.0 | **Bumped and live-verified.** DaemonSet pod `1/1 Running`, zero errors in logs over a 90s window. 3 real bugs found and fixed, one of which (env-var expansion syntax) is a genuine behavior change in newer collector cores; the other two were pre-existing and just never surfaced before (see below). |
| `tempo` | chart 1.10.3 / app 2.x (single-binary) | chart 1.24.4 / app 2.9.0 | **Bumped and live-verified.** Pod `1/1 Running`, `/ready` returns `ready`, zero errors in logs. Clean major-version jump, no config changes needed. Chart itself prints `this chart is deprecated` on every install — Grafana is steering users toward `tempo-distributed`; worth a follow-up issue, not urgent for a single-node MVP deployment. |

## OpenSearch: 3 real bugs found and fixed during live-testing (all pre-existing, not caused by the bump)

All three were exposed by actually deploying OpenSearch live for the first time this session — the manifest had apparently never been deployed and exercised end-to-end before, at any version:

1. **`fsGroup` on container-level `securityContext` — invalid field, blocks every deploy.** The manifest had `fsGroup: 1000` under the pod's *container* `securityContext` (line ~144), duplicating the (correct) pod-level `podSecurityContext.fsGroup`. `fsGroup` isn't a valid container-securityContext field at all — Kubernetes rejected the StatefulSet outright with `field not declared in schema`. This would have blocked deployment at the currently-pinned 2.17.0 too; it was never actually tried. Fixed by removing the duplicate/invalid field.
2. **`sysctl.enabled: true` alongside `sysctlInit.enabled: true` — pod stuck `SysctlForbidden`.** The chart offers two ways to set `vm.max_map_count`: a privileged initContainer (`sysctlInit`, portable, no cluster prerequisites) and a pod-level `securityContext.sysctls` entry (`sysctl`, requires the kubelet to have that sysctl explicitly allowlisted via `--allowed-unsafe-sysctls`). Both were enabled; the `sysctl` path failed immediately on this cluster (and would fail identically on the real AKS node pools, which don't have that flag set either). Fixed by disabling `sysctl` and keeping only `sysctlInit`.
3. **`discovery.type: single-node` set manually alongside the chart's default multi-node bootstrap — OpenSearch process crashes on startup.** The chart always injects `cluster.initial_master_nodes` as an env var for node 0's bootstrap; OpenSearch refuses to start if `discovery.type: single-node` is *also* set, since the two are mutually exclusive by design (`IllegalArgumentException: setting [cluster.initial_master_nodes] is not allowed when [discovery.type] is set to [single-node]`). The chart has a documented `singleNode: true` top-level value specifically for this case — it suppresses the multi-node bootstrap env var *and* sets `discovery.type: single-node` correctly. Fixed by setting `singleNode: true` and removing the manual `discovery.type` override from the custom `opensearch.yml`.

After all three fixes: `curl localhost:9200/_cluster/health` → `"status":"green"`, 3/3 shards active, both at the 2.17.0/2.11.1 baseline and after the 3.8.0 bump.

## OpenTelemetry Collector: 3 real bugs found and fixed during live-testing

Like OpenSearch, this component had never actually been deployed and run before this session — even the baseline pinned version (chart 0.108.0 / image 0.114.0) crash-looped on first real deploy:

1. **Wrong config keys for the `opensearch` exporter — crash-loop at any version.** The manifest used `retry:` and `sending_queue:` under the `opensearch` exporter config. Neither key exists on that exporter: the correct name is `retry_on_failure` (confirmed against `opensearchexporter`'s actual config struct), and the exporter has **no queueing support at all** — `sending_queue` isn't a valid field, full stop. The collector refused to start: `'' has invalid keys: retry, sending_queue`. This means the "5+ minute log buffering on failure" the surrounding comments describe has never actually been in effect. Fixed by renaming to `retry_on_failure` and dropping the unsupported `sending_queue` block.
2. **`$${NODE_IP}` never actually expands — kubeletstats receiver silently broken since day one.** The chart does not pass `.Values.config` through Helm's `tpl`, so `$$` is never collapsed to a literal `$` by Helm — it reaches the collector's own config resolver as literal `$$`. The *collector's* resolver treats `$$` as its own escape-to-literal-`$` sequence, so `$${NODE_IP}` resolves to the literal text `${NODE_IP}` — never expanded to an actual IP, at any collector version, ever. This didn't crash the pod (metrics scraping just failed silently in the background), so it went undetected until logs were actually read live. Also updated to the current `${env:VAR}` syntax while fixing this, since newer collector cores no longer auto-expand bare `${VAR}`. Fixed: `${env:NODE_IP}` (single `$`).
3. **Missing `nodes/stats` RBAC rule — masked by bug #2 until fixed.** Once NODE_IP started resolving to a real address, the `kubeletstats` receiver could finally reach the kubelet — and hit `403 Forbidden ... resource=nodes, subresource(s)=[stats]`. The ClusterRole granted `nodes`, `nodes/proxy`, `nodes/metrics` but not `nodes/stats`, which this receiver specifically needs for the `/stats/summary` endpoint. Fixed by adding `nodes/stats` to the ClusterRole.

After all three fixes: DaemonSet pod `1/1 Running`, zero `error`/`forbidden` log lines over a 90-second window, at both baseline and the 0.172.0/0.159.0 bump.

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
