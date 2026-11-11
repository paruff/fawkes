# Plan: path to Beta — Beta bar, golden-path ApplicationSets, service consolidation

**Traces to:** fawkes#2191 (define the path from pre-alpha k3d to cloud Beta),
fawkes#2120 (golden-path ApplicationSet redesign), fawkes#2116 (17 services → 2
domain monoliths) | uFawkes.dev
[suite release plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md),
"After Alpha" item 3 | **Status:** Draft. Waits on the owner (Gate: plan).
No issue below exists on GitHub yet.

This plan sequences the three issues as one piece of work, because they share
a cluster, an ApplicationSet file and a definition of done. #2191 says what
Beta must prove; #2120 and #2116 are two of the things it may have to prove.

Repo facts below were checked against `main` at `8d13acc` on 2026-11-11. No
cluster was reachable from the planning session, so nothing here is a live
observation. Statements about a cluster come from the cited docs and are
marked as such.

## What the repo says today, where it differs from the issues

These change the plan, so they come first.

| #   | Finding                                                                                                                                                                                                                                                                                        | Effect on the plan                                                                                                   |
| --- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| F1  | #2116's mapping names 16 services. `services/` has 19 directories. `dora-metrics`, `experimentation`, `feedback-cli` and `samples` have no target. `tracer-bullet` is no longer under `services/`. The issue spells `devx-survey-automation`; the directory is `devex-survey-automation`.          | Decision D3                                                                                                          |
| F2  | #2116 puts `vsm` in the telemetry engine. `docs/ARCHITECTURE.md` lines 213-214, which the issue calls ground truth, lists VSM under the DevEx service's purpose and not under telemetry.                                                                                                        | Decision D3                                                                                                          |
| F3  | `services/data-api` has no Python (README, catalog entry, `rbac/`, `schema/`). `friction-cli` and `feedback-cli` are command-line clients with no Dockerfile. `mcp-k8s-server` is 31 lines, and a second copy lives in `infra/mcp-k8s-server/`.                                                    | Four of the 16 "migrations" are not service migrations. Decision D3                                                  |
| F4  | Cross-service HTTP calls found by grep (heuristic, may miss some): `feedback-bot → feedback`, `feedback-cli → feedback`, `devex-survey-automation → nps`, `devex-survey-automation → space-metrics`, `friction-bot → insights`, `friction-cli → insights`, `analytics-dashboard → feedback`, `analytics-dashboard → experimentation`. | Only two edges fall inside one monolith. The rest stay HTTP, so "eliminated HTTP latency" will be small              |
| F5  | Only `space-metrics` and `dora-metrics` are in an ApplicationSet generator. `feedback-bot` and `insights` have partial manifests under `platform/apps/`. The other services have no deploy path in git.                                                                                            | There is no 17-service footprint to measure "~70% reduction" against. Phase 6 measures what exists and may show a rise |
| F6  | The databases are CloudNativePG roles in `platform/apps/postgresql/db-shared-dev-cluster.yaml`. No `telemetry_db` or `devex_db` appears in any `.tf`, `.yaml` or `.py` file.                                                                                                                      | #2116's database split looks like a `platform/` GitOps change, not Terraform. Confirm in Phase 5                      |
| F7  | The three `python-fawkes-path-{alpha,beta,prod}-applicationset.yaml` files are referenced by no kustomization and no generator. They target `fawkes-alpha`, `fawkes-beta` and `fawkes-prod`, and all three point at the same GitOps repo, branch `main`, path `.`.                                  | The environments do not differ in git. A matrix generator alone deploys the same manifests three times. Decision D4   |
| F8  | No test checks that the paths in an ApplicationSet's `files:` generator exist. `scripts/render-all-applications.sh` checks each Application's source, not the generator lists. This is the gap behind the #2118 incident.                                                                          | Phase 1 adds the guard before any list is edited                                                                     |
| F9  | Services pin different versions of the same package: six `fastapi` versions (0.104.1 to 0.141.1), six `uvicorn`, five `httpx`, four `sqlalchemy`.                                                                                                                                                  | Each monolith needs one set of pins. Version unification is real work and the main migration risk                    |
| F10 | `ai-code-review`, `anomaly-detection`, `nps` and `smart-alerting` each have their own workflow and are excluded from `service-python-tests.yml`'s discovery.                                                                                                                                       | Migrating them edits `.github/workflows/`, which needs the owner's approval (`AGENTS.md` §6)                          |
| F11 | The PR size gate (`ci-pr-size.yml`) sums additions and deletions. A service is 400 to 2,700 lines of Python.                                                                                                                                                                                       | Moves must be rename-only or split. Whether GitHub counts a pure rename as zero is assumed, not verified: the pilot proves it |
| F12 | `docs/DEPLOYMENT_STRATEGY.md` ("`services/` consolidated", "2 monoliths: 🟡 In progress") and `docs/ARCHITECTURE.md` ("Fawkes now runs two unified platform services") still state the consolidation as done or under way.                                                                        | #2116 says not to restate it. Phase 0 corrects the text                                                              |
| F13 | README sends cloud users to AWS EKS ("Path B"). `EXECUTION_QUEUE.md` says the live cluster is Azure `fawkes-dev-aks`, rebuilt by hand and destroyed nightly. #2126 (CI-gated `terraform apply`) is open.                                                                                           | Beta needs one named cloud. Decision D1                                                                              |
| F14 | fawkes Alpha has not shipped. The suite plan's status table has AC-FAWKES-03 failing on #2004 and #1797, and AC-FAWKES-01 needs one clean run (#1858) through `python-fawkes-path`.                                                                                                                | Do not change `python-fawkes-path`'s Application on a cluster while #1858's evidence run is pending                   |

Noticed, out of scope: `docs/KNOWN_LIMITATIONS.md` KL-18 and
`DEPLOYMENT_STRATEGY.md` say OpenBao is migrated, while `AGENTS.md` §5 says it
is not deployed. `services/location.yaml` lists five targets that do not exist
(`cloud-provider`, `data-quality`, `rag`, `python-fawkes-path`, `dora-metrics`).

## Decisions for the owner

Each becomes a `Decision:` issue when the plan is approved. The plan's
recommendation is given so that work is not blocked on wording.

| ID  | Question                                                                                         | Recommendation                                                                                                                                                                                                                                              | Blocks  |
| --- | ------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| D1  | Which cloud is the Beta target?                                                                  | Azure AKS, because it is the only cloud the docs record as live-verified. README's Path B then changes to match                                                                                                                                              | Phase 0 |
| D2  | Is finishing #2116 a Beta gate?                                                                  | No. Beta is about cloud readiness, and most of the 16 services are not deployed (F5). Gate Beta on "docs describe the layout that exists" and let consolidation run beside it                                                                                | Phase 0 |
| D3  | Where do `vsm`, `dora-metrics`, `experimentation`, `feedback-cli`, `friction-cli`, `data-api`, `mcp-k8s-server` go? | `vsm` → DevEx (follows ARCHITECTURE.md). `dora-metrics`, `experimentation` → telemetry. The two CLIs stay as CLIs under `scripts/` or their own directory, calling the DevEx service. `data-api` and `mcp-k8s-server`: decide separately, they are not FastAPI services | Phase 4 |
| D4  | How do `alpha`, `beta` and `prod` differ in the GitOps repo?                                     | One overlay directory per environment in each `*-gitops` repo. Without this the environment fan-out has nothing to fan out                                                                                                                                   | Phase 2 |
| D5  | Auto-discovery or an explicit list (#2120 leaves it open)?                                       | A git `files` generator over `platform/apps/golden-paths/*/config.yaml`. A directory deploys only once it holds a `config.yaml`, which answers #2120's "half-built directory auto-deploys" concern without a hand-edited list. Check the generator against the installed ArgoCD version before relying on it | Phase 2 |
| D6  | Are Valkey (#2189) and SSO (#2190) part of the Beta bar?                                         | No recommendation. They are the other two uFawkesRes-successor gaps and neither has a design                                                                                                                                                                 | Phase 0 |
| D7  | Standing approvals this plan needs under `AGENTS.md` §6                                          | Approve per phase, not once: ApplicationSet and AppProject edits (Phases 2, 3, 5, 6), catalog descriptors (Phases 4, 5), the four workflows in F10 (Phase 4), tasks over five files (every service move)                                                     | Phases 2-6 |

## Sequence

Two tracks run under one rule from the suite plan: one `goal` in flight at a
time in Claude Code, OpenCode tasks in parallel underneath.

```text
goal track      P0 Beta bar ──► P2 new ApplicationSet ──► P3 namespaces ──► P5 deploy + DB ──► P6 java pilot, measure, close
                     │                  ▲                                        ▲
opencode track  P1 guards, common, scaffolds ──► P4 service migrations (pilot, then waves) ─┘
```

| Phase | Issue                    | Needs a cluster | Depends on                                             |
| ----- | ------------------------ | --------------- | ------------------------------------------------------ |
| 0     | #2191                    | No              | Nothing                                                |
| 1     | #2116 steps 1-2, #2120   | No              | Nothing. Runs beside Phase 0                           |
| 2     | #2120 step (a)           | Yes             | P0 (D1, D4, D5), P1's guard, #1858's Alpha run finished |
| 3     | #2120 step (b)           | Yes             | P2 stable                                              |
| 4     | #2116 step 3             | No              | P1, D3                                                 |
| 5     | #2116 steps 4-5          | Yes             | P4's pilot, P1's guard. Not P2 or P3                   |
| 6     | #2120 step (c), #2116 step 6, #2191 evidence | Yes | P3, P5, #2032 phases 1 and 3                    |

## Phase 0 — Name what Beta must prove (#2191)

**Goal:** an `intent.md` and `spec.md` in this folder that list numbered Beta
acceptance criteria, each with the evidence that proves it.

Candidate criteria, drawn from `MILESTONES.md` H2, #1805 and the suite plan.
They are input to the owner, not a decision:

1. The Beta cluster is built from git by CI, with no hand-run `terraform apply` (#2126).
2. No plaintext or placeholder credential in git (#1797, and the Grafana admin
   password `EXECUTION_QUEUE.md` lists as not started).
3. #1805's five criteria. `MILESTONES.md` records three as done; chaos-in-canary
   (#1942) and the Backstage catalog are open.
4. Two golden paths, Python and Java, deploy through one ApplicationSet into
   per-environment namespaces (#2120).
5. The service layout in the docs is the one in the repo (D2).
6. `golden-path-verification` is green on the Beta cluster, with the run linked
   (`AGENTS.md` §9).

**Risks**

| Risk                                                        | Mitigation                                                                 |
| ----------------------------------------------------------- | -------------------------------------------------------------------------- |
| The bar grows into a second roadmap                         | Cap it at criteria that have an owner issue today. Anything else is "after Beta" |
| Criteria are written that nothing can check                 | Each criterion names its evidence, as the suite `spec.md` does             |
| Alpha has not shipped, so "after Alpha" work pulls focus    | Phase 0 writes documents only. Live work waits for #1858 (F14)             |

**Exit criteria**

- `intent.md` and `spec.md` merged; `scripts/check-artifact-chain.sh` passes.
- D1, D2 and D6 answered in their issues and recorded in the spec.
- README's status line and cloud path name the D1 cloud; F12's text corrected.
- #2191 closed. The uFawkesRes README table is not touched until a gap closes.

**Draft issues**

- **P0-1 `goal` + `claude-code`** — Write `docs/ai-sdlc/path-to-beta/intent.md`
  and `spec.md`. Start from the six candidates above. Open `Decision:` issues
  D1-D7. Done when the artifact-chain check passes and the owner has approved
  the spec (Gate: spec).
- **P0-2 `opencode` + `model:mimo-v2.6-flash`** — Correct the consolidation
  claims. Files: `docs/DEPLOYMENT_STRATEGY.md` (the "17 services → 2 domain
  monoliths" bullet and the "2 monoliths" table row), `docs/ARCHITECTURE.md`
  ("Fawkes now runs two unified platform services" and the Migration Note).
  Reword to "planned, not started; see #2116". Do not touch any other line.
  Check: `grep -n "have been consolidated\|now runs two unified" docs/ARCHITECTURE.md docs/DEPLOYMENT_STRATEGY.md`
  prints nothing.
- **P0-3 `opencode` + `model:mimo-v2.6-flash`** — After D1 is answered: make
  README's status line and "Deploy to Cloud" row name the chosen cloud. File:
  `README.md` only. Blocked by D1. Check: the row's link target exists in
  `docs/getting-started.md`.

## Phase 1 — Guards and foundations (#2116 steps 1-2, #2120 guard)

**Goal:** everything later phases stand on, with no change to a running
service and no cluster.

**Risks**

| Risk                                                                    | Mitigation                                                                                  |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `services/common/` becomes a speculative framework                      | Extract only code that already exists in two or more services (`database.py` ×6, `metrics.py` ×4, `config.py` ×3). Auth is left out until a service needs it, and is `goal` work when it is |
| How a monolith imports `common` is undecided (install, path, build context) | P1-2 decides it in an ADR before any code issue starts                                  |
| `service-python-tests.yml` only discovers directories with a `requirements.txt` | Every new directory gets one, so CI runs its tests with no workflow change              |
| Pin drift between `common` and the monoliths (F9)                       | P1-3 surveys the pins; the ADR names one set per monolith                                   |

**Exit criteria**

- The generator-path guard fails on a missing path and passes on `main`.
- `services/common/` has tests green in `service-python-tests.yml`.
- Both monoliths build (`docker build`) and serve `/health` in a test.
- `git diff --stat main -- services/<any existing service>` is empty.

**Draft issues**

- **P1-1 `opencode` + `model:nemotron-3-ultra`** — Guard the ApplicationSet
  file lists. New file `tests/unit/test_applicationset_generator_paths.py`:
  load every `platform/bootstrap/*.yaml` of `kind: ApplicationSet`, and assert
  each `spec.generators[].git.files[].path` without a glob exists on disk.
  Red first: run it against a temporary copy with one path misspelt and paste
  the failure. Do not edit any file under `platform/`. Check:
  `pytest tests/unit/test_applicationset_generator_paths.py`.
- **P1-2 `goal` + `claude-code`** — ADR: monolith layout. Decide how
  `services/fawkes-*/` imports `services/common/`, the Docker build context,
  the module name for each migrated service (directory names have hyphens and
  cannot be imported as written), whether old URL paths keep working, and one
  set of pins per monolith. Uses the `adr-writer` skill. Blocks P1-4 onward.
- **P1-3 `opencode` + `model:mimo-v2.6-flash`** — Pin survey. New file
  `docs/ai-sdlc/path-to-beta/pin-survey.md`: one table, package × service,
  from every `services/*/requirements.txt`. Read-only on `services/`. Check:
  the table has a row for each of `fastapi`, `pydantic`, `sqlalchemy`,
  `uvicorn`, `httpx`, `prometheus-client`.
- **P1-4 `opencode` + `model:nemotron-3-ultra`** — `services/common/` config
  helper. Test first, in `services/common/tests/test_config.py`. Reference:
  the three existing `config.py` files. Files: at most five, all under
  `services/common/`. Do not edit any existing service. Check:
  `cd services/common && ruff check . && pytest tests/`.
- **P1-5, P1-6, P1-7 `opencode` + `model:nemotron-3-ultra`** — Same shape as
  P1-4, one each for database session (reference: `services/insights/app/database.py`),
  Prometheus metrics helper (reference: `services/space-metrics/app/metrics.py`),
  and structured logging. One helper per PR.
- **P1-8 `opencode` + `model:nemotron-3-ultra`** — Scaffold
  `services/fawkes-telemetry-engine/`: `app/main.py` with `/health`,
  `requirements.txt` pinned with `==` per the ADR, `Dockerfile` on the same
  pinned base image the existing services use, `tests/test_health.py` written
  first. No migrated logic and no file under `platform/`. Reference:
  `services/friction-bot/`. Check: `ruff check . && pytest tests/` and
  `docker build` succeed.
- **P1-9 `opencode` + `model:nemotron-3-ultra`** — The same for
  `services/fawkes-devex-service/`.

## Phase 2 — New `golden-paths` ApplicationSet, Python only, namespace unchanged (#2120 step a)

**Goal:** `python-fawkes-path` is generated by a new ApplicationSet in its own
AppProject and nothing a user can see changes.

**Risks**

| Risk                                                                                              | Mitigation                                                                                                                         |
| ------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------- |
| Moving an Application between ApplicationSets deletes it, and its workloads with it               | Rehearse the hand-over on k3d first and write the exact order down. `preserveResourcesOnDeletion` on the old set is the expected tool; confirm it against the installed ArgoCD version, do not assume it |
| `platform/bootstrap/` is applied by hand and does not self-heal (KL-14)                           | The cut-over is a documented bootstrap re-apply by the owner, not an agent action                                                  |
| The cut-over lands during Alpha's evidence run                                                    | Blocked by #1858 (F14)                                                                                                             |
| The AppProject is scoped too tightly and blocks a sync, or too loosely and scopes nothing         | Review as a security change (`AGENTS.md` §12). Test by trying to sync into a platform namespace and expecting a refusal            |
| The cluster is rebuilt nightly by hand                                                            | k3d for rehearsal. The AKS run waits for a session where the owner brings the cluster up                                           |

**Exit criteria**

- `golden-paths` ApplicationSet and AppProject are in `platform/bootstrap/`;
  `path-based-applications` no longer lists a golden-path file.
- On the cluster: one `python-fawkes-path` Application, Synced and Healthy,
  owned by the new set, with pod start times older than the cut-over.
- A sync into a namespace outside the AppProject is refused.
- The Phase 1 guard and `scripts/render-all-applications.sh` pass.

**Draft issues**

- **P2-1 `goal` + `claude-code`** — Parent. Write the ApplicationSet (matrix
  of path config × environment list, one environment for now) and the
  AppProject, rehearse the hand-over on k3d, then run it on the D1 cluster
  with the owner. Needs D4, D5 and D7.
- **P2-2 `opencode` + `model:nemotron-3-ultra`** — Structure test, written
  before P2-1's manifests. New file
  `tests/unit/test_golden_paths_applicationset.py`: assert
  `platform/bootstrap/golden-paths-applicationset.yaml` exists, uses
  `goTemplateOptions: ["missingkey=error"]`, sets `project: golden-paths`,
  and that no path containing `fawkes-path` remains in
  `path-based-applications.yaml`. It must fail on `main`. Do not create the
  manifest. Check: paste the failing run.
- **P2-3 `opencode` + `model:mimo-v2.6-flash`** — After P2-1 merges: update
  `platform/bootstrap/README.md` to list the third ApplicationSet and what
  belongs in each. One file.

## Phase 3 — One namespace per language and environment (#2120 step b)

**Goal:** `fawkes-python-alpha`, `fawkes-python-beta` and `fawkes-python-prod`
exist and carry the workload; the shared `fawkes` namespace holds no golden
path.

**Risks**

| Risk                                                                                                   | Mitigation                                                                                          |
| ------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------- |
| Namespaced dependencies stay behind: the AnalysisTemplate, Tekton's tokens, the ServiceAccount for #1578 | List every namespaced object the workload reads before moving. Secrets are `goal` work only          |
| Prometheus stops scraping. `DEPLOYMENT_STRATEGY.md` already records the ServiceMonitor not being picked up in `fawkes` | Fix that gap first, in the old namespace, so the move does not hide it                |
| DORA rules, dashboards and `validate-golden-path-*.sh` assume namespace `fawkes` (#1909)               | Grep before, parameterise, and run all eight plane scripts after                                    |
| The same manifests land in three namespaces and prove nothing (F7)                                     | D4's overlays land before the second environment is switched on                                     |

**Exit criteria**

- Three Applications, one per environment, Synced and Healthy in their own
  namespaces. `kubectl get rollout -n fawkes` shows no golden path.
- A forced bad revision is rolled back by analysis in the new namespace.
- All eight `validate-golden-path-*.sh` scripts pass with the new namespace.
- The three unused per-environment ApplicationSet files and
  `python-fawkes-path-application.yaml` are deleted.

**Draft issues**

- **P3-1 `goal` + `claude-code`** — Parent. Overlays in
  `python-fawkes-path-gitops` (second repo), the environment list, the move,
  the live checks.
- **P3-2 `opencode` + `model:nemotron-3-ultra`** — Namespace as a parameter.
  Files: the eight `scripts/validate-golden-path-*.sh`. Wherever `fawkes` is a
  hard-coded namespace for the golden-path workload, read `${NAMESPACE:-fawkes}`.
  Two PRs of four files. Do not change what any check asserts. Check:
  `shellcheck` on each file, and `grep -n '\-n fawkes\b'` on them prints nothing.
- **P3-3 `opencode` + `model:mimo-v2.6-flash`** — Inventory. New file
  `docs/ai-sdlc/path-to-beta/namespace-inventory.md`: every file under
  `platform/apps/` and `scripts/` that names namespace `fawkes` for
  `python-fawkes-path`, with line numbers. Read-only. Feeds P3-1.
- **P3-4 `opencode` + `model:mimo-v2.6-flash`** — After P3-1's cut-over is
  verified: delete the three `python-fawkes-path-*-applicationset.yaml` files
  and `python-fawkes-path-application.yaml`. Check: the P1-1 and P2-2 tests pass.

## Phase 4 — Move services into the monoliths (#2116 step 3)

**Goal:** each mapped service's code runs inside its monolith with its tests
green, one service per pair of small PRs.

**Order.** #2116 says to read the dependency graph before each pick. From F4:
a pilot per monolith first, then services nothing calls, then callers after
their callees, then the two that are deployed today.

| Wave  | Telemetry engine                                            | DevEx service                                               | Why here                                              |
| ----- | ----------------------------------------------------------- | ----------------------------------------------------------- | ----------------------------------------------------- |
| Pilot | `insights` (1,157 lines, 4 test files)                      | `friction-bot` (397 lines, 3 test files)                    | Has tests, not deployed, no workflow of its own       |
| A     | `discovery-metrics`, `analytics-dashboard`                  | `feedback`, then `feedback-bot`                             | `feedback-bot → feedback` becomes an import           |
| B     | `anomaly-detection`, `smart-alerting`                       | `nps`, then `devex-survey-automation`; `ai-code-review`     | Four have their own workflow (F10): owner approval    |
| C     | `space-metrics`, and `dora-metrics` if D3 says so           | `vsm` if D3 says so                                         | Deployed today. Code moves here, cut-over in Phase 5  |
| —     | `data-api`                                                  | `friction-cli`, `mcp-k8s-server`                            | Not service moves (F3). Waits on D3                   |

`discovery-metrics` and `analytics-dashboard` have no test files. Each gets a
characterisation test in its old location before it moves.

**Risks**

| Risk                                                             | Mitigation                                                                                                   |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| A move trips the 400-line gate (F11)                             | PR 1 is `git mv` plus import lines only. PR 2 deletes the leftovers. If the pilot shows renames are counted, the owner applies `large-pr-approved`; agents never do |
| One set of pins breaks a service that sat on an older one (F9)   | The service's own tests run inside the monolith before the old directory is deleted                           |
| Two services define the same route, table or metric name         | Mount each under its module prefix per the ADR; a test asserts no duplicate route                             |
| A cheap model "fixes" tests to make them pass                    | The issue forbids editing assertions. Claude Code reviews every OpenCode PR and diffs the test files          |
| #2227 (mypy baseline, one `services/` directory per PR) and #1792 (pipelines for the "remaining 14 services") edit the same directories | Hold #1792 until the monoliths exist; it should target two images, not fourteen. For #2227, move a directory's `.mypy-baseline` line in the same PR as the move |
| Cross-monolith calls are turned into imports by mistake          | Each issue names the edges that stay HTTP (F4)                                                                |

**Exit criteria**

- Every service in waves Pilot to C is a module under its monolith; its old
  directory holds no Python.
- Each monolith's test suite is green in `service-python-tests.yml` and
  contains every test file the old directories had (count before and after).
- `feedback-bot → feedback` and `devex-survey-automation → nps` are imports.
  The remaining edges in F4 are still HTTP and still configured by URL.
- `services/location.yaml` lists only directories that exist.

**Draft issues.** One pair per service. The pilot pair in full:

- **P4-1 `opencode` + `model:nemotron-3-ultra`** — Move `insights` into the
  telemetry engine. `git mv services/insights/app services/fawkes-telemetry-engine/app/insights`
  and `git mv services/insights/tests services/fawkes-telemetry-engine/tests/insights`.
  Change only import lines (`from app.` → `from app.insights.`), mount the
  router in `app/main.py`, and add the pins `insights` needs to the monolith's
  `requirements.txt`. Do not edit an assertion. Do not delete
  `services/insights/`. Leave `migrations/` and `alembic.ini` where they are
  (Phase 5). Red first: add `tests/insights/test_mounted.py` asserting the
  insights health route answers inside the monolith, and paste its failure.
  Check: `cd services/fawkes-telemetry-engine && ruff check . && pytest tests/`,
  and the PR's line count as GitHub reports it.
- **P4-2 `opencode` + `model:mimo-v2.6-flash`** — After P4-1 merges: delete
  what is left of `services/insights/` except `migrations/`, `alembic.ini` and
  `catalog-info.yaml`. Move its `README.md` content to
  `services/fawkes-telemetry-engine/docs/insights.md`. Check:
  `find services/insights -name '*.py' -not -path '*/migrations/*'` prints nothing.
- **P4-3, P4-4** — The same pair for `friction-bot` into the DevEx service.
  `INSIGHTS_API_URL` stays an HTTP call.
- **P4-5 `goal` + `claude-code`** — Pilot review. Record in this plan whether
  renames counted against the size gate, how long each PR took, and what the
  template got wrong. Fix the template before wave A is filed.
- **Waves A to C** — One pair per row of the table, from the corrected
  template. A characterisation-test issue (`nemotron`) precedes each of the
  two services without tests. The four services in F10 add a `goal` child for
  the workflow change.
- **P4-last `opencode` + `model:mimo-v2.6-flash`** — Remove from
  `services/location.yaml` every target whose file does not exist. Needs D7
  (catalog descriptor). Check: a loop over the targets finds each path on disk.

## Phase 5 — Deploy the monoliths, split the database, retire the old entries (#2116 steps 4-5)

**Goal:** both monoliths run on the cluster from git, each on its own
database, and no old service Application remains.

**Risks**

| Risk                                                                                   | Mitigation                                                                                           |
| -------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `space-metrics` has a live database; a careless cut-over loses its rows                | Add the new database beside the old one, copy, verify counts, switch, and keep the old one until Phase 6 |
| New database credentials end up in git, or in a free-tier prompt                       | Credentials are `goal` work. They follow whatever #1797 lands; no placeholder is added               |
| Editing `path-based-applications`' list repeats the #2118 incident                     | The Phase 1 guard runs on the PR                                                                     |
| Two alembic histories (`insights` has one) collide in one database                     | One migration directory per module with its own version table, decided in the ADR                    |
| The database split turns out to need Terraform after all (F6)                          | Confirm against the D1 cloud first. If it does, it needs a second reviewer and #2126                 |
| Metric and dashboard names change when the job label changes                           | Keep metric names; add the old `job` label as a relabel until dashboards are updated                 |

**Exit criteria**

- `fawkes-telemetry-engine` and `fawkes-devex-service` Applications are Synced
  and Healthy; each `/health` and `/metrics` answers through the cluster.
- `telemetry_db` and `devex_db` exist with separate roles. `space-metrics`
  row counts match before and after.
- `space-metrics` and `dora-metrics` Applications are gone, and their
  dashboards still show data.
- `helm lint` or `kubeconform` output and the required labels and limits
  (`AGENTS.md` §5) are shown in each manifest PR.
- The catalog shows two components.

**Draft issues**

- **P5-1 `goal` + `claude-code`** — Parent. Databases and credentials, the
  ApplicationSet entries, the `space-metrics` and `dora-metrics` cut-over,
  live checks. Needs D7.
- **P5-2 `opencode` + `model:nemotron-3-ultra`** — Manifests for the telemetry
  engine. New directory `platform/apps/fawkes-telemetry-engine/` with
  `deployment.yaml`, `service.yaml`, `serviceaccount.yaml`,
  `servicemonitor.yaml`, `kustomization.yaml` (five files). Reference:
  `platform/apps/space-metrics/`. Pinned image tag, limits on every container,
  labels `app`, `version`, `component`, `managed-by: fawkes`. No Secret, no
  Application manifest, no ApplicationSet edit. Red first: a test in
  `tests/unit/` asserting the labels and limits, failing because the directory
  is missing. Check: `kubectl kustomize platform/apps/fawkes-telemetry-engine | kubeconform -strict -`.
- **P5-3 `opencode` + `model:nemotron-3-ultra`** — The same for the DevEx service.
- **P5-4 `opencode` + `model:mimo-v2.6-flash`** — After the cut-over is
  verified: delete `platform/apps/space-metrics/`, `platform/apps/dora-metrics/`,
  `platform/apps/feedback-bot/` and `platform/apps/insights/`, one directory
  per PR. Check: the P1-1 guard and `scripts/render-all-applications.sh` pass.
- **P5-5 `opencode` + `model:mimo-v2.6-flash`** — Two `catalog-info.yaml`
  files, one per monolith, replacing the per-service ones. Needs D7.

## Phase 6 — Java pilot, measurement, Beta evidence (#2120 step c, #2116 step 6, #2191)

**Goal:** the second golden path onboards without an ApplicationSet edit, the
footprint claim has a number, and the Beta bar from Phase 0 has evidence.

**Risks**

| Risk                                                                                | Mitigation                                                                                   |
| ----------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `java-fawkes-path` is not ready; its GitOps repo and Tekton pipeline are not started (#2032) | This phase waits. It does not build Java's pipeline                                 |
| Moving `platform/apps/python-fawkes-path/` renames a live Application's source      | Same hand-over rehearsal as Phase 2, on k3d first                                            |
| The footprint number is quoted without its baseline (F5)                            | Publish the before and after figures and what each one counted. Do not publish a percentage alone |
| A phase is called done on merged PRs                                                | `AGENTS.md` §9: a linked `golden-path-verification` run, or it is not done                    |

**Exit criteria**

- `platform/apps/golden-paths/python-fawkes-path/` and `.../java-fawkes-path/`
  exist. The PR that added Java's directory touches no file under `platform/bootstrap/`.
- `java-fawkes-path` is Synced and Healthy in `fawkes-java-alpha`, with one
  Tekton run and one ArgoCD sync linked.
- `docs/METRICS.md` holds the measured footprint, before and after, with the
  command used. KL-17 is updated from that number.
- Every criterion in this folder's `spec.md` has linked evidence.
- #2120 and #2116 are closed with their acceptance criteria checked.

**Draft issues**

- **P6-1 `goal` + `claude-code`** — Parent. Directory move, switch the
  generator to discovery, Java onboarding, footprint measurement, evidence.
- **P6-2 `opencode` + `model:nemotron-3-ultra`** — Onboarding test, written
  before the move. Extend `tests/unit/test_golden_paths_applicationset.py`:
  every directory under `platform/apps/golden-paths/` has a `config.yaml` with
  the keys the template reads, and the ApplicationSet names no language. Must
  fail on `main`.
- **P6-3 `opencode` + `model:mimo-v2.6-flash`** — How-to page
  `docs/how-to/onboard-a-golden-path.md` (Diataxis: how-to): the steps the
  Java onboarding actually took. Written after P6-1, from its PR.
- **P6-4 `opencode` + `model:mimo-v2.6-flash`** — Update KL-17,
  `docs/ARCHITECTURE.md` and `EXECUTION_QUEUE.md` rows for #2116 and #2120
  from the linked evidence. No number that is not in `docs/METRICS.md`.

## How the drafts become issues

On approval each draft is filed from `.github/ISSUE_TEMPLATE/agent-task.yml`
with one routing label, a link to this plan and its check as the exit
criterion, added to Project #7 as _Backlog_, and moved to _Ready for agent_
when its dependencies close. This section and the draft lists are then
replaced by links, because the board rules keep task lists out of plans.

Routing follows the suite rubric. `mimo-v2.6-flash` gets one-file or
grep-and-replace work that one command proves. `nemotron-3-ultra` gets work
bounded to this repo with written criteria and at most five files. Everything
that needs a cluster, a second repo, a credential, an ADR or an AppProject is
`goal`. A flash task that fails twice moves to Nemotron; a Nemotron task that
fails twice becomes a `goal` child.

## Verification Strategy

| Criterion                                         | Evidence                                                                  | How                                                                 |
| ------------------------------------------------- | ------------------------------------------------------------------------- | ------------------------------------------------------------------- |
| The Beta bar is written and approved (#2191)      | `intent.md` and `spec.md` merged, decisions closed                        | `bash scripts/check-artifact-chain.sh origin/main HEAD`             |
| A stale generator path cannot merge               | Guard test fails on a missing path                                        | `pytest tests/unit/test_applicationset_generator_paths.py`          |
| Golden paths have their own ApplicationSet and AppProject | Structure test green; refused sync outside the project            | `pytest tests/unit/test_golden_paths_applicationset.py`; live sync  |
| Each environment has its own namespace            | Three Applications Healthy; plane scripts pass                            | `scripts/validate-golden-path-*.sh` with `NAMESPACE` set            |
| Java onboards with no ApplicationSet edit         | Its PR's file list                                                        | Phase 6 exit criteria                                               |
| Each service runs inside its monolith             | Monolith test suites green, test-file counts equal                        | `service-python-tests.yml` on each PR                               |
| The monoliths are deployed from git               | Applications Synced and Healthy                                           | `scripts/render-all-applications.sh`; live check                    |
| The footprint claim has a number                  | `docs/METRICS.md` entry with before, after and command                    | `kubectl top` on the Beta cluster                                   |
| Each phase is done                                | A linked `golden-path-verification` run                                   | `AGENTS.md` §9                                                      |
