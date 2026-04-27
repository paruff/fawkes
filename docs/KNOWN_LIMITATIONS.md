# Known Limitations — Fawkes IDP

> **Purpose:** This file catalogues known limitations, gaps, and degraded-mode behaviours
> in the Fawkes platform. Agents are instructed not to make these worse. Humans reviewing
> agent-generated changes should verify that none of these limitations are exacerbated.
>
> Update this file whenever a limitation is discovered, resolved, or worsened.
> Link to the tracking issue where one exists.

---

## KL-01 — No Terraform Remote Backend

**Status: RESOLVED** — Remote state backend modules, environment backend configs, and a
bootstrap script have been added. See below for details.

**Resolution:**

- **AWS**: `infra/terraform/modules/aws/state-backend/` provisions an S3 bucket (versioned,
  KMS-encrypted, TLS-enforced) + DynamoDB lock table (PITR enabled) per environment.
- **Azure**: `infra/terraform/modules/azure/state-backend/` provisions an Azure Storage
  Account (GRS, versioning, soft-delete 30 days) + private `tfstate` container.
- **Environment configs**: `infra/terraform/environments/` contains per-environment
  `backend.hcl` files for both AWS and Azure.
- **Bootstrap script**: `scripts/bootstrap-terraform-state.sh` creates the state
  infrastructure before Terraform itself can run.
- **Workspace strategy**: documented in `infra/terraform/environments/README.md`.

To bootstrap a new environment:

```bash
# AWS
./scripts/bootstrap-terraform-state.sh --cloud aws --environment dev --region us-east-1

# Azure
./scripts/bootstrap-terraform-state.sh --cloud azure --environment dev --location eastus2
```

Then initialise any root module:

```bash
terraform init -backend-config=infra/terraform/environments/dev/backend.hcl
```

**Tracking:** GAP-7 — Closed by PR implementing issue #119.

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
