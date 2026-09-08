# Known Limitations — Fawkes IDP

> **Purpose:** This file catalogues known limitations, gaps, and degraded-mode behaviours
> in the Fawkes platform. Agents are instructed not to make these worse. Humans reviewing
> agent-generated changes should verify that none of these limitations are exacerbated.
>
> Update this file whenever a limitation is discovered, resolved, or worsened.
> Link to the tracking issue where one exists.

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

## KL-06 — DevLake ArgoCD Plugin Requires Manual Connection Configuration

**Description:** The DevLake integration with ArgoCD (used for DORA deployment-frequency
and lead-time metrics) requires a one-time manual configuration step inside the DevLake
admin UI to establish the ArgoCD API connection. Specifically, an engineer must navigate
to **Settings → Connections → ArgoCD** and supply the ArgoCD server URL, bearer token,
and TLS verification settings. This step is not automated by Helm values, Kubernetes
Jobs, or any GitOps mechanism.

**Impact:**

- After every fresh DevLake install (or namespace wipe), an engineer must manually
  re-enter the ArgoCD connection details in the DevLake UI.
- Automated environment provisioning (e.g., ephemeral preview environments) will not
  collect DORA metrics until the manual step is completed.
- There is no validation in CI that the connection is healthy.

**Tracking:** No dedicated issue. Add a post-install Helm hook or a `scripts/` helper
to automate this step.

---

## KL-07 — MTTR Tracking Covers Only Jenkins Pipeline Failures

**Description:** Mean Time To Recovery (MTTR) is currently measured only for Jenkins
pipeline failures — specifically the duration between a pipeline failure event and the
next successful run of the same pipeline. Production incidents (PagerDuty alerts, SLO
breaches, rollback events) are not tracked.

**Impact:**

- The MTTR metric shown in Grafana dashboards is not a true production MTTR.
- Elite/High/Medium/Low tier classification based on MTTR may be misleading.
- Post-incident reviews cannot be correlated with MTTR data from the platform.

**Tracking:** No dedicated issue. Extend MTTR collection to ingest PagerDuty or
Alertmanager resolved-alert events.

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
tracer-bullet.

**Still open, separately:** the `gitextractor` "Invalid Git URL" failure on the same
pipeline is unrelated to this bug (a different task, different error) and remains
unfixed — not part of the DORA-relevant subtask list, so not chased further. And see
KL-12 below: fixing collection did not make DORA metrics appear, because
tracer-bullet's golden path doesn't yet emit anything for `github_graphql` to
collect.

**Tracking:** [#1855](https://github.com/paruff/fawkes/issues/1855) — root cause and
fix documented in a comment; recommend closing once reviewed.

---

## KL-10 — SonarCloud Project Registered Under Wrong Default Branch

**Description:** The `tracer-bullet` SonarCloud project's default branch is
registered as `master`, but the repository's actual default branch is `main`. This
was discovered live during golden-path pipeline debugging (#1804) and is a likely
contributor to an observed quality-gate/New-Code-period inconsistency (the API's
`qualitygates/project_status` returned `"status":"NONE"` on a first analysis with
89.3% coverage and zero bugs/vulnerabilities/code smells).

**Impact:**

- Quality gate evaluation and "new code" baselines may be computed against the
  wrong branch's history.
- `sonar.qualitygate.wait` was disabled in the golden-path Tekton pipeline
  (`platform/apps/tekton/golden-path-pipeline.yaml`) as a workaround for Phase 1,
  deliberately not blocking on quality gates — see
  `docs/DEPLOYMENT_STRATEGY.md`'s 2026-09-07 update. That workaround should be
  revisited once this is fixed.

**Tracking:** No dedicated issue yet. Likely fix: pass `-Dsonar.branch.name=main` to
the scanner invocation, or ensure a non-shallow clone so SonarCloud's own SCM
detection identifies `main` correctly.

---

## KL-11 — tracer-bullet Metrics Not Reaching Prometheus (RESOLVED 2026-09-08)

**Description:** tracer-bullet exposes Prometheus-format metrics via a pull-based
`/metrics` endpoint (FastAPI + `prometheus_client`'s `make_asgi_app()`), but nothing
was scraping it: the platform's OTel Collector only runs an OTLP receiver for its
metrics pipeline (push-based), and no ServiceMonitor existed for this service.
Traces and logs were both confirmed working through the same OTel Collector — only
metrics were affected, and only because of this missing scrape target.

**Fix:** [`paruff/tracer-bullet-gitops#2`](https://github.com/paruff/tracer-bullet-gitops/pull/2)
adds a `ServiceMonitor` (selector `app: tracer-bullet`, port `http`, path
`/metrics`), merged 2026-09-08. Verified live end-to-end after the merge: ArgoCD
synced the new commit (`a97b71f`), the `ServiceMonitor` shows as an ArgoCD-managed
resource, and Prometheus reports `up{job="tracer-bullet"}` == 1 for both pods.

**Tracking:** [tracer-bullet-gitops#2](https://github.com/paruff/tracer-bullet-gitops/pull/2),
merged.

---

## KL-12 — DevLake `dora` Plugin Needs `cicd_tasks`, Not Just `cicd_deployments` (Partially Fixed)

**Description:** With KL-09's collection bug fixed, DevLake's `github_graphql`
plugin ran clean for `paruff/tracer-bullet` — but DORA metrics still showed no
data, because every layer of DevLake's data (raw GitHub API responses, tool
tables, and domain tables) had **zero rows** for this repo. Root cause: tracer-bullet's
golden path (`platform/apps/tekton/golden-path-pipeline.yaml`) pushed an image to
GHCR and opened a GitOps PR, but never opened a PR against `paruff/tracer-bullet`
itself and never called GitHub's Deployments API.

**Partial fix, `platform/apps/tekton/golden-path-pipeline.yaml` (PR #1917):** the
`gitops-promote` task now creates a real GitHub Deployment
(`POST /repos/paruff/tracer-bullet/deployments`) and marks it successful after
every promotion. Verified live: `github_graphql`'s existing "Collect Deployments"
subtask picks this up and it reaches the domain-layer `cicd_deployments` table
(confirmed 0 → 1 row via a direct `devlake-mysql` query).

**Still not enough, confirmed live:** DevLake's `dora` plugin (queried its own
`/plugins` metadata: `{"model":"cicd_tasks","requiredFields":{"column":"type","execptedValue":"Deployment"}}`)
requires `cicd_tasks` rows with `type = "Deployment"` specifically — a *different*
domain table from `cicd_deployments`, populated by `github_graphql` from GitHub
Actions workflow/job run data, not from the Deployments API. Since the golden path
runs on Tekton, there are no GitHub Actions workflow runs for `github_graphql` to
convert, so `cicd_tasks` stays empty regardless of how many real Deployments this
fix creates — confirmed live (still 0 rows after re-collection).

**Impact:**

- DORA metrics in DevLake still won't compute for tracer-bullet even after PR
  #1917 merges — this is the precise remaining reason the DORA plane of the
  golden path (`docs/golden-path-verification-planes.md`) can't go green.

**Tracking:** No dedicated issue yet. Next step, not yet attempted: DevLake's
`webhook` plugin, which can accept a directly-shaped deployment task event without
needing GitHub Actions at all — unlike the Deployments-API approach, it isn't
structurally blocked by this being a Tekton-based pipeline. This is new pipeline
instrumentation and new DevLake connection configuration, not a bug fix — scope it
as its own issue.
