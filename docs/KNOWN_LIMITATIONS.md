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

## KL-09 — DevLake GitHub GraphQL Collection Fails for Any Repo (Root Cause Unknown)

**Description:** DevLake's `github_graphql` plugin subtasks (Collect Pull Requests,
Collect Issues) fail with a generic "graphql query got error" against a real,
correctly-scoped GitHub connection. Confirmed against `paruff/tracer-bullet` with a
working connection (`GET /proceed-db-migration` completed, `PUT
.../connections/{id}/scopes` accepted the repo's real numeric GitHub ID). The
leading theory — OAuth (`gho_`) vs. classic (`ghp_`) token format — was tested live
with a real classic PAT swapped into the connection and produced the identical
failure, disproving it.

**Impact:**

- DORA deployment-frequency/lead-time metrics cannot be collected for any repo via
  this DevLake instance until this is fixed — the DORA plane of the golden path
  (see `docs/golden-path-verification-planes.md`) is unverifiable end-to-end.
- The separately-observed `gitextractor` "Invalid Git URL" failure was set aside
  during triage (not needed for the DORA-relevant subtask list) and remains
  undiagnosed too.

**Tracking:** [#1855](https://github.com/paruff/fawkes/issues/1855) — comment added
2026-09-07 documenting the disproven token-type theory. Next step per that comment:
enable DevLake's debug-level logging for `github_graphql`, or read its source for
where the raw GraphQL error response is being swallowed before it reaches the
pipeline's task-level error message.

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

## KL-11 — tracer-bullet Metrics Not Reaching Prometheus (Traces and Logs Unaffected)

**Description:** Live re-verification on 2026-09-08 found zero Prometheus series for
`tracer-bullet` (`{job=~".*tracer.*"}` and `__name__` search both empty), while the
same OpenTelemetry Collector pipeline's traces and logs paths for the same service
are confirmed working (5 recent traces in Tempo, logs in Loki, both same-session).
The collector pod is healthy (1/1 Ready, health-check extension OK), its metrics
pipeline is configured with a `prometheusremotewrite` exporter pointed at
`prometheus-prometheus.monitoring.svc.cluster.local:9090/api/v1/write`, and the
target Prometheus has `enableRemoteWriteReceiver: true` — so the wiring that
*should* carry metrics end-to-end looks correct on both ends, but no data is
arriving. Root cause not yet diagnosed (not investigated further this session
given cost — see [[fawkes_tracer_bullet_golden_path_1804]]).

**Impact:**

- The Observability plane of the golden path (see
  `docs/golden-path-verification-planes.md`) is 7/8 passing, not fully green, purely
  on this metrics gap — traces and logs are unaffected.
- Any Grafana dashboard or alert relying on live `tracer-bullet` metrics will show no
  data.

**Tracking:** No dedicated issue yet. Next step: check the otel-collector-agent's own
logs for `prometheusremotewrite` export errors (none seen in a quick tail this
session, but a longer window wasn't checked), and confirm the tracer-bullet app is
actually configured to emit OTLP metrics at all (vs. only traces/logs) — the app-side
instrumentation should be checked in `paruff/tracer-bullet` before assuming the
platform side is at fault.
