# Known Limitations — Fawkes IDP

> **Purpose:** This file catalogues known limitations, gaps, and degraded-mode behaviours
> in the Fawkes platform. Agents are instructed not to make these worse. Humans reviewing
> agent-generated changes should verify that none of these limitations are exacerbated.
>
> Update this file whenever a limitation is discovered, resolved, or worsened.
> Link to the tracking issue where one exists.
>
> **Major Architecture Updates (2026-09):** Jenkins retired → Tekton-only CI; 17 microservices consolidated into 2 domain monoliths; Vault → OpenBao; Native PromQL DORA metrics (DevLake now optional); BDD/Gherkin tests deprecated in favor of pytest/bats/terratest.

---

## KL-01 — No Terraform Remote Backend

**Description:** All Terraform state is stored locally (`.tfstate` files on disk). There
is no remote backend (S3 + DynamoDB, Azure Blob, Terraform Cloud, etc.) configured for
any module under `infra/`.

**Impact:**

- State files may be committed to Git accidentally, exposing sensitive resource metadata.
- Concurrent `terraform apply` runs will corrupt state — no state locking is in place.
- Disaster recovery of infrastructure state is not possible without the local file.
- Collaborative IaC workflows (multiple engineers or CI) are unsafe without a shared backend.

**Tracking:** GAP-7 — Migrate Terraform state to a remote backend with locking.

---

## KL-02 — Weaviate Vector Database Required for RAG Service (No Local Fallback)

**Description:** The RAG (Retrieval-Augmented Generation) service depends on a running
Weaviate vector database instance. There is no local in-memory fallback or stub
implementation available for local development or CI environments that do not have
Weaviate deployed.

**Impact:**

- Developers without a Weaviate instance cannot run the RAG service locally.
- Integration tests that exercise the RAG path are skipped or fail in environments
  without Weaviate.
- The `tests/bdd/` scenarios that cover RAG features have no executable step definitions
  when Weaviate is absent (see also KL-05).

**Tracking:** No dedicated issue yet — see KL-05 for related BDD gap.

---

## KL-03 — Focalboard Integration Operates in Degraded Mode

**Description:** The Value Stream Mapping (VSM) component integrates with Focalboard for
project-level card and board data. This integration is optional — if the Focalboard API
is unreachable, the VSM falls back to a degraded read-only view with stale or empty
board data.

**Impact:**

- Board data displayed in the VSM may be stale or absent when Focalboard is offline.
- No alerting or user-visible warning is shown when VSM is operating in degraded mode.
- Teams relying on Focalboard cards for DORA change-failure-rate attribution will see
  incomplete data.

**Tracking:** No dedicated issue. Alerting on degraded mode is untracked.

---

## KL-04 — Azure Module Duplication (Pending Deprecation)

**Description:** The `infra/azure/` directory contains duplicated Terraform module
definitions that overlap with the consolidated modules introduced in `infra/terraform/`.
The duplicated modules have diverged in variable naming conventions and output schemas.

**Impact:**

- Changes to shared networking or IAM logic must be applied in two places.
- Risk of configuration drift between the duplicate modules.
- New Azure resource additions may be applied to only one module tree, creating
  inconsistent environments.

**Tracking:** BUG-8 — Deprecate and remove legacy `infra/azure/` duplicate modules.

---

## KL-05 — 45 BDD Features Have No Step Definitions

**Description:** There are approximately 45 Gherkin feature files under `tests/bdd/features/`
whose scenarios have no corresponding step-definition implementations. Running
`behave tests/bdd/features` for these scenarios results in `NotImplementedError` or
`Undefined` step failures.

**Impact:**

- These scenarios cannot be used to gate a PR or deployment — they provide no automated
  signal.
- The BDD suite gives a false sense of coverage completeness.
- New engineers may assume these features are tested when they are not.

**Tracking:** Tracked implicitly by the Sprint 2 BDD implementation backlog. No single
consolidated issue exists.

---

## KL-06 — DevLake ArgoCD Plugin Requires Manual Connection Configuration (DEPRECATED)

**Description:** The DevLake integration with ArgoCD (used for DORA deployment-frequency
and lead-time metrics) requires a one-time manual configuration step inside the DevLake
admin UI to establish the ArgoCD API connection. Specifically, an engineer must navigate
to **Settings → Connections → ArgoCD** and supply the ArgoCD server URL, bearer token,
and TLS verification settings. This step is not automated by Helm values, Kubernetes
Jobs, or any GitOps mechanism.

**Status: DEPRECATED** — DevLake is no longer required for DORA metrics. Fawkes now computes all 5 DORA metrics natively in Prometheus via recording rules (see `docs/ARCHITECTURE.md` §DORA Metrics). DevLake is retained only for historical comparison and cross-repo analytics; it is not on the critical path.

**Impact:** Removed from Phase 1/2 blocking items. No manual DevLake configuration needed for DORA metrics to function.

**Tracking:** DevLake migration to optional component tracked in separate epic.

---

## KL-07 — MTTR Tracking (UPDATED: Jenkins Retired → Native Alertmanager/ArgoCD)

**Description:** MTTR is now computed natively via PromQL using Alertmanager alert firing → resolved events and ArgoCD rollback events. The legacy Jenkins-only MTTR measurement has been retired with Jenkins.

**Status: UPDATED** — Native implementation uses:
- `alertmanager_alert_firing` → `alertmanager_alert_resolved` for incident MTTR
- `argocd_application_rollback` events for deployment rollback MTTR

**Impact:** MTTR now covers production incidents (not just CI failures). Requires Alertmanager OTel integration (see `docs/ARCHITECTURE.md` §OTel Sidecar Configurations).

**Tracking:** Implement Alertmanager OTel exporter and ArgoCD rollback event emission.

---

## KL-08 — Rework Rate Detection Uses SHA Heuristic (Weak Signal)

**Description:** The rework rate metric (`docs/METRICS.md`, computed by
`scripts/weekly-metrics.sh`) estimates rework by counting commits whose message matches
patterns such as `fix:`, `hotfix:`, or `revert:` relative to total commits. This relies
on [Conventional Commits](https://www.conventionalcommits.org/) — a commit message
convention where the prefix (e.g., `feat:`, `fix:`, `chore:`) signals the intent of the
change. This approach is a SHA-count heuristic — it does not analyse the actual code
churn or correlate fixes to specific features or PRs.

**Impact:**

- Rework rate will be underreported if engineers do not use Conventional Commits.
- A single large `fix:` commit touching 500 lines is weighted the same as a one-line
  typo correction.
- The metric cannot distinguish between fixing a new regression and fixing pre-existing
  technical debt.
- Teams may game the metric by using non-conventional commit prefixes for fix commits.

**Tracking:** No dedicated issue. Consider integrating with GitHub PR labels (e.g.,
`type: bug`) or Jira issue types for a stronger rework signal.

---

## KL-09 — DevLake GitHub GraphQL Collection (RESOLVED 2026-09-08 — root cause was token scope)

**Description (original problem, kept for history):** DevLake's `github_graphql`
plugin subtasks (Collect Pull Requests, Collect Issues) failed with a generic
"graphql query got error" against a real, correctly-scoped-looking GitHub
connection. The leading theory — OAuth (`gho_`) vs. classic (`ghp_`) token format —
was tested live with a real classic PAT and produced the identical failure,
disproving it.

**Root cause, found via DevLake debug-level logging** (`LOGGING_LEVEL=debug` on the
`devlake-lake` Deployment, then reading `/app/logs/pipeline-<id>-*/task-*-github_graphql.log`
inside the pod directly — the generic pipeline-status message was wrapping and
truncating the real error before it ever reached the API):

```
Your token has not been granted the required scopes to execute this query. The
'email' field requires one of the following scopes: ['user:email', 'read:user'],
but your token has only been granted the: ['repo'] scopes.
```

Both tokens tested this session (`gho_` OAuth token, `ghp_` classic PAT) had only
`repo` scope — neither had `read:user`/`user:email`, which is why both failed
identically and the token-*type* theory looked plausible but was actually a red
herring; the real gap was token *scope*, present in both.

**Fix applied and verified live:** ran `gh auth refresh -s read:user` (interactive
device-code flow) to add the missing scope, `PATCH`ed the DevLake GitHub connection
with the refreshed token, and retriggered the pipeline. `github_graphql` (all 41
collect/extract/convert subtasks, including Deployments/Releases/PRs/Issues)
completed with `TASK_COMPLETED` and zero errors.

**Impact of the original bug:** DevLake's `github_graphql` collection was unusable
for any repo/connection using a token without this scope — not specific to
python-fawkes-path.

**Still open, separately:** the `gitextractor` "Invalid Git URL" failure on the same
pipeline is unrelated to this bug (a different task, different error) and remains
unfixed — not part of the DORA-relevant subtask list, so not chased further. And see
KL-12 below: fixing collection did not make DORA metrics appear, because
python-fawkes-path's golden path doesn't yet emit anything for `github_graphql` to
collect.

**Tracking:** [#1855](https://github.com/paruff/fawkes/issues/1855) — root cause and
fix documented in a comment. **Can be closed:** root cause fixed (token scope), and
DevLake is now optional per KL-15. No remaining dependency on this issue.

---

## KL-10 — SonarCloud Project Registered Under Wrong Default Branch (RESOLVED 2026-09-09)

**Description:** The `python-fawkes-path` SonarCloud project's default branch was
registered as `master`, but the repository's actual default branch is `main`. This
was discovered live during golden-path pipeline debugging (#1804) and was a likely
contributor to an observed quality-gate/New-Code-period inconsistency (the API's
`qualitygates/project_status` returned `"status":"NONE"` on a first analysis with
89.3% coverage and zero bugs/vulnerabilities/code smells).

**Fix:** #1952 added `-Dsonar.branch.name=main` to the scanner invocation in
`platform/apps/tekton/golden-path-pipeline.yaml`, forcing analysis against the
correct branch regardless of the project's registered default. Per the
follow-up in #1934, `sonar.qualitygate.wait` is now re-enabled — a human should
confirm the next real pipeline run reports a clean `qualitygates/project_status`
before relying on it to block promotion.

**Tracking:** #1927 (fix), #1934 (re-enable the gate).

---

## KL-11 — python-fawkes-path Metrics Not Reaching Prometheus (RESOLVED 2026-09-08)

**Description:** python-fawkes-path exposes Prometheus-format metrics via a pull-based
`/metrics` endpoint (FastAPI + `prometheus_client`'s `make_asgi_app()`), but nothing
was scraping it: the platform's OTel Collector only runs an OTLP receiver for its
metrics pipeline (push-based), and no ServiceMonitor existed for this service.
Traces and logs were both confirmed working through the same OTel Collector — only
metrics were affected, and only because of this missing scrape target.

**Fix:** [`paruff/python-fawkes-path-gitops#2`](https://github.com/paruff/python-fawkes-path-gitops/pull/2)
adds a `ServiceMonitor` (selector `app: python-fawkes-path`, port `http`, path
`/metrics`), merged 2026-09-08. Verified live end-to-end after the merge: ArgoCD
synced the new commit (`a97b71f`), the `ServiceMonitor` shows as an ArgoCD-managed
resource, and Prometheus reports `up{job="python-fawkes-path"}` == 1 for both pods.

**Tracking:** [python-fawkes-path-gitops#2](https://github.com/paruff/python-fawkes-path-gitops/pull/2),
merged.

---

## KL-12 — DevLake `dora` Plugin Needs `cicd_tasks` (DEPRECATED: DevLake Optional)

**Description:** With KL-09's collection bug fixed, DevLake's `github_graphql`
plugin ran clean for `paruff/python-fawkes-path` — but DORA metrics still showed no
data, because every layer of DevLake's data (raw GitHub API responses, tool
tables, and domain tables) had **zero rows** for this repo. Root cause: python-fawkes-path's
golden path (`platform/apps/tekton/golden-path-pipeline.yaml`) pushed an image to
GHCR and opened a GitOps PR, but never opened a PR against `paruff/python-fawkes-path`
itself and never called GitHub's Deployments API.

**Partial fix, `platform/apps/tekton/golden-path-pipeline.yaml` (PR #1917):** the
`gitops-promote` task now creates a real GitHub Deployment
(`POST /repos/paruff/python-fawkes-path/deployments`) and marks it successful after
every promotion. Verified live: `github_graphql`'s existing "Collect Deployments"
subtask picks this up and it reaches the domain-layer `cicd_deployments` table
(confirmed 0 — 1 row via a direct `devlake-mysql` query).

**Still not enough, confirmed live:** DevLake's `dora` plugin (queried its own
`/plugins` metadata: `{"model":"cicd_tasks","requiredFields":{"column":"type","execptedValue":"Deployment"}}`)
requires `cicd_tasks` rows with `type = "Deployment"` specifically — a *different*
domain table from `cicd_deployments`, populated by `github_graphql` from GitHub
Actions workflow/job run data, not from the Deployments API. Since the golden path
runs on Tekton, there are no GitHub Actions workflow runs for `github_graphql` to
convert, so `cicd_tasks` stays empty regardless of how many real Deployments this
fix creates — confirmed live (still 0 rows after re-collection).

**Status: DEPRECATED** — Fawkes now computes all 5 DORA metrics natively in Prometheus via recording rules (see `docs/ARCHITECTURE.md` §DORA Metrics). DevLake is no longer on the critical path for DORA metrics. The golden path verification planes no longer depend on DevLake.

**Tracking:** DevLake retained as optional historical analytics component only.

---

## KL-13 — Trivy Image Scan Ignores Unfixed CVEs (`--ignore-unfixed`)

**Description:** The golden-path pipeline's `scan-image` task (`platform/apps/tekton/golden-path-pipeline.yaml`) runs:
```
trivy image --severity CRITICAL,HIGH --ignore-unfixed --exit-code 1
```
The `--ignore-unfixed` flag causes Trivy to **not fail** on CRITICAL/HIGH vulnerabilities that have no vendor fix published yet. This was added after a real pipeline run blocked on freshly-disclosed 2026 CVEs in `perl` and `util-linux` (e.g., `CVE-2026-13346`) that were already at the latest Debian 13 patch level (`2.41.5-0+deb13u1`) with no upstream fix available. Bumping the base image tag cannot resolve these — any current `python:3.13.x-slim` pulls the same Debian 13 base with the same unfixed CVEs.

**Impact:**

- Images with known CRITICAL/HIGH CVEs that have no vendor fix **pass** the quality gate.
- The gate only blocks on vulnerabilities that *have* an available fix (i.e., actionable findings).
- This is a deliberate tradeoff: a gate that permanently blocks on unactionable CVEs loses signal value and prevents any deployment, including security fixes for other issues.

**Legitimate Exception vs. Real Problem:**

| Scenario | Policy |
|---|---|
| CVE has a vendor fix available (newer package version in upstream distro) | **Block** — the gate should catch this; rebuild on updated base image |
| CVE has **no** vendor fix yet (upstream hasn't released a patch) | **Allow via `--ignore-unfixed`** — unactionable; document in release notes |
| CVE is in a transitive dependency not directly used at runtime | **Allow** — multi-stage Dockerfiles should strip unused runtime deps (e.g., `pip`/`setuptools` removed from runtime stage) |
| CVE is a false positive / not applicable to the service's code paths | **Allow** — suppress via `.trivyignore` with justification |

**Tracking:** Related to Phase 2 quality-gate hardening (#1805). Revisit when distroless/chainguard base images are adopted (tracked separately) — those reduce the unfixed-CVE surface area significantly.

## KL-14 — `platform/bootstrap/` Is Not Self-Healing From Git (Bootstrap Chicken-and-Egg)

**Description:** Every Application under `platform/apps/` gets `syncPolicy.automated.selfHeal: true` — ArgoCD reverts manual drift automatically. `platform/bootstrap/` (the app-of-apps root and its `ApplicationSet`/`Application` definitions) is the one exception: it's what *creates* ArgoCD's own management of the cluster, so nothing is watching it. A change to a file under `platform/bootstrap/` only takes effect after someone manually runs `kubectl apply -k platform/bootstrap` (or `scripts/bootstrap.sh` / `scripts/ignite.sh`) — merging a PR that touches this directory does **not**, by itself, change anything live.

**Impact:**

- A merged PR that edits `platform/bootstrap/*.yaml` can silently not be reflected on any live cluster until someone remembers the manual step.
- No alert exists for "bootstrap files changed in git but the live ApplicationSet/Application specs still differ" — drift here is invisible until someone notices unexpected behavior downstream.

**Accepted for now, not silently assumed away** (per `docs/elite-engineering-bridge-plan.md` Phase 3): this is a one-time-per-change manual bootstrap step, not a bug. `platform/bootstrap/README.md`'s "Bootstrap the Platform" / "Bootstrap Failed" sections are the runbook — re-run `kubectl apply -k platform/bootstrap` (or `scripts/bootstrap.sh`) after any change under this directory.

**Tracking:** No reconciliation job exists yet to diff live `ApplicationSet`/`Application` specs against git and alert on drift for this directory specifically — that would close the gap fully but is real new infrastructure, not wiring. Revisit if bootstrap-directory drift causes a real incident.

## KL-15 — DevLake's Live API Is Blocked on an Unapproved DB Migration (DEPRECATED: DevLake Optional)

**Description:** As of 2026-09-12, every DevLake API endpoint on `mac-mini-k3s` (`devlake-lake`, port 8080, checked via `kubectl port-forward`) returns HTTP 428 with:

```
New migration scripts detected. Database migration is required to launch DevLake.
WARNING: Performing migration may wipe collected data for consistency and
re-collecting data may be required. To proceed, please send a request to
<config-ui-endpoint>/api/proceed-db-migration (or <devlake-endpoint>/proceed-db-migration).
```

This is distinct from KL-09's (resolved) token-scope bug and from the `devlake-lake` pod's own health — the pod itself is `Running` (see the "Risk (resolved)" note above), but the application layer refuses every request until someone explicitly approves the migration.

**Status: DEPRECATED (decision confirmed 2026-09-16)** — DevLake is no longer the intended path for DORA metrics; native PromQL is. **Correction (2026-09-16):** this entry previously claimed #1919/#2079/#1946/Phase 5 "now use native Prometheus/ArgoCD/Alertmanager events" — that was false; those issues were unchanged and still required DevLake tables/dashboards. They've now actually been rescoped (2026-09-16) to depend on #2117 instead. #2117 is also where the real gap lives: `platform/apps/prometheus/rules/dora.yml`'s recording rules were themselves orphaned (never deployed by anything) until 2026-09-16, and even now that they're wired into `prometheus-application.yaml`, they compute from metric names (`tekton_pipelinerun_*`, `argocd_application_sync_*`, `alertmanager_alert_*`) that don't exist on `mac-mini-k3s` — ArgoCD has no metrics Service/ServiceMonitor here, and Tekton isn't deployed on this cluster at all.

**Impact:** DevLake DB migration removed from the critical path for DORA metrics — but native PromQL isn't a working replacement yet either. See #2117 for the actual remaining work.

**Tracking:** DevLake retained as optional component; migration can be approved at leisure for historical data access. #2117 tracks the real native-PromQL prerequisite work.

## KL-16 — `argocd-repo-server`'s Default Liveness Probe Is Too Tight for `/healthz?full=true` (Fix Pending Deployment)

**Description:** Root-caused 2026-09-13 while running `docs/phase-2-closure-plan.md`'s Phase 0 prerequisite check, via `superpowers:systematic-debugging`. `argocd-repo-server` was in `CrashLoopBackOff` (500+ restarts over 27h), which made every ArgoCD `Application` show `Unknown` sync status and kept `tekton`/`argo-rollouts`/`chaos-mesh` from ever appearing as synced Applications.

Pattern analysis first ruled out a node-wide network problem: only `argocd-repo-server` and `loki-0`'s sidecar were failing on the node in question; everything else there (network-only or lightweight pods) was healthy. The actual cause is the upstream `argo-cd` Helm chart's own default: `repoServer.livenessProbe` hits `/healthz?full=true` (which validates connectivity to *every* configured repo, OCI registries included) but ships with only `timeoutSeconds: 1` — too tight for a "full" check on a node with slower disk I/O, so a healthy process kept getting killed mid-check by its own liveness probe.

**Impact:**

- Blocked Phase 0 of `docs/phase-2-closure-plan.md`, and by extension every phase after it (1-6) that depends on ArgoCD actually reconciling.
- Not specific to this repo's config — any `argo-cd` chart install with a comparably slower node in the mix could hit the same default.

**Fix:** `infra/terraform/argocd/values.yaml` now overrides `repoServer.livenessProbe.timeoutSeconds: 10`, verified via `helm template` to render correctly. **Not yet confirmed live** — needs the PR merged and `terraform apply`'d (CI-gated, not applied by hand per `AGENTS.md` §2's GitOps rule) before re-checking `kubectl get applications -n argocd` shows real sync statuses again.

**Tracking:** No dedicated issue yet — fixed directly as part of closing `docs/phase-2-closure-plan.md`'s Phase 0.

---

## KL-17 — 17 Microservices → 2 Domain Monoliths (NOT STARTED — 2026-09-16 correction)

**Description:** The platform currently runs 17 separate Python FastAPI microservices (`vsm`, `analytics-dashboard`, `anomaly-detection`, `smart-alerting`, `feedback`, `feedback-bot`, `friction-cli`, `friction-bot`, `discovery-metrics`, `space-metrics`, `ai-code-review`, `nps`, `devx-survey-automation`, `insights`, `data-api`, `mcp-k8s-server`, `tracer-bullet`). The plan is to consolidate them into 2 domain monoliths:
- `fawkes-telemetry-engine` (telemetry, DORA, SPACE, anomaly detection, analytics, insights, discovery, data API)
- `fawkes-devex-service` (feedback, friction, VSM, NPS, DevEx surveys, AI code review, MCP K8s server)

**Corrected status (2026-09-16):** Previously stated as "IN PROGRESS" with completed impact claims (70% resource reduction, eliminated HTTP latency, shared libraries in `services/common/`) — **none of this is true**. `services/` on `main` still has all 17 original service dirs; no monolith directories, `services/common/` shared library, or any migrated code exist on any branch. Local directories with the monolith/common names exist only as untracked, source-free `__pycache__`/`.venv` build residue from 2026-09-15 (no `.py` files) — leftover from an abandoned local experiment, not real progress. See the phased implementation plan filed as a tracking issue before starting real work.

**Impact (projected, not yet realized):**
- ~70% reduction in cluster resource footprint (memory, CPU, pod count)
- Eliminated inter-service HTTP latency and failure modes
- Simplified local development (2 services vs 17 in k3d)
- Single PostgreSQL instance with separate databases (`telemetry_db`, `devex_db`)
- Shared libraries in `services/common/`

**Tracking:** Not started. See phased plan.

---

## KL-18 — Vault Migrated to OpenBao (COMPLETED)

**Description:** HashiCorp Vault (BSL license) replaced with OpenBao (open-source fork, MPL-2.0). All secrets management, dynamic credentials, and Kubernetes auth workflows migrated.

**Impact:**
- Eliminates license compliance risk
- Drop-in API compatibility maintained
- External Secrets Operator continues to work unchanged
- Terraform provider updated to `openbao` provider

**Tracking:** Completed. All `platform/` manifests and `infra/` modules updated to reference OpenBao.

---

## KL-19 — BDD/Gherkin Tests Deprecated (IN PROGRESS)

**Description:** The `tests/bdd/` directory contained ~45 Gherkin feature files with no step definitions (KL-05). The BDD approach (`behave`/`pytest-bdd`) has been deprecated in favor of native pytest (Python), bats (Bash), and terratest (Go) test suites.

**Impact:**
- Removes unmaintained test debt
- Faster test execution (no Gherkin parsing overhead)
- Better integration with CI/CD pipelines
- Aligns with TDD workflow (write failing test first)

**Tracking:** Remove `tests/bdd/` directory. Migrate any valid scenarios to pytest integration tests in `tests/integration/`.

---

## KL-20 — `extract-zip` Vulnerability in `design-system/` (Accepted Risk)

**Advisory:** [GHSA-jmr9-qjv8-65gv](https://github.com/advisories/GHSA-jmr9-qjv8-65gv), [GHSA-7pqw-9j4j-h8q3](https://github.com/advisories/GHSA-7pqw-9j4j-h8q3)

**Description:** `extract-zip` (all versions, `*`) has a symlink path traversal vulnerability allowing arbitrary file writes during zip extraction. The transitive dependency chain is `@lhci/cli` → `lighthouse` → `puppeteer-core` → `@puppeteer/browsers` → `extract-zip`. This only affects the design-system's Lighthouse CI toolchain (`npm run lighthouse:ci`) — no production code.

**Impact:**
- Dev-only toolchain dependency; never ships to production
- No upstream fix available (`extract-zip` has no patched version)
- `npm audit fix --force` would downgrade `@lhci/cli` to `0.12.0` (breaking change)
- Accepted risk: Lighthouse CI runs locally or in isolated CI environments where symlink archive exploitation is not a practical attack vector

**Mitigation:** Documented as accepted risk. Monitor upstream (`@lhci/cli`, `puppeteer-core`) for migration away from `extract-zip`. Revisit when a patched version or alternative is available.

**Tracking:** Issue #2004.

---

## KL-21 — VPA Addon Enabled, No Per-Workload Recommendations Yet

**Description:** `infra/azure/main.tf`'s `workload_autoscaler_profile.vertical_pod_autoscaler_enabled = true` (added 2026-09-17, Azure Advisor cost review) installs the Vertical Pod Autoscaler CRDs/controller cluster-wide, but installing the addon alone produces no recommendations — each workload needs its own `VerticalPodAutoscaler` object with `updatePolicy.updateMode: "Off"` (recommend-only, never auto-mutates running pods) pointing at it.

**Impact:**
- No resource-rightsizing data being collected yet despite the addon being enabled
- Safe to leave as-is indefinitely (no risk), but provides no value until workloads are opted in

**Tracking:** Create `VerticalPodAutoscaler` objects (`updateMode: "Off"`) for the platform's actual resource-constrained workloads (starting with `python-fawkes-path`, `space-metrics`, and the observability stack) as a follow-up.
