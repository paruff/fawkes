# Plan: path to Beta — Beta bar, golden-path ApplicationSets, service consolidation

**Traces to:** fawkes#2191 (define the path from pre-alpha k3d to cloud Beta),
fawkes#2120 (golden-path ApplicationSet redesign), fawkes#2116 (17 services → 2
domain monoliths) | uFawkes.dev
[suite release plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/plan.md),
"After Alpha" item 3 | **Status:** Approved by the owner 2026-11-11. One `goal`
issue per phase, #2298 to #2304.

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
| F1  | #2116's mapping names 16 services. `services/` has 19 directories. `dora-metrics`, `experimentation`, `feedback-cli` and `samples` have no target. `tracer-bullet` is no longer under `services/`. The issue spells `devx-survey-automation`; the directory is `devex-survey-automation`.          | Answered in D3                                                                                                       |
| F2  | #2116 puts `vsm` in the telemetry engine. `docs/ARCHITECTURE.md` lines 213-214, which the issue calls ground truth, lists VSM under the DevEx service's purpose and not under telemetry.                                                                                                        | Answered in D3                                                                                                       |
| F3  | `services/data-api` has no Python (README, catalog entry, `rbac/`, `schema/`). `friction-cli` and `feedback-cli` are command-line clients with no Dockerfile. `mcp-k8s-server` is 31 lines, and a second copy lives in `infra/mcp-k8s-server/`.                                                    | Four of the 16 "migrations" are not service migrations. See D3                                                  |
| F4  | Cross-service HTTP calls found by grep (heuristic, may miss some): `feedback-bot → feedback`, `feedback-cli → feedback`, `devex-survey-automation → nps`, `devex-survey-automation → space-metrics`, `friction-bot → insights`, `friction-cli → insights`, `analytics-dashboard → feedback`, `analytics-dashboard → experimentation`. | Only two edges fall inside one monolith. The rest stay HTTP, so "eliminated HTTP latency" will be small              |
| F5  | Only `space-metrics` and `dora-metrics` are in an ApplicationSet generator. `feedback-bot` and `insights` have partial manifests under `platform/apps/`. The other services have no deploy path in git.                                                                                            | There is no 17-service footprint to measure "~70% reduction" against. Phase 6 measures what exists and may show a rise |
| F6  | The databases are CloudNativePG roles in `platform/apps/postgresql/db-shared-dev-cluster.yaml`. No `telemetry_db` or `devex_db` appears in any `.tf`, `.yaml` or `.py` file.                                                                                                                      | #2116's database split looks like a `platform/` GitOps change, not Terraform. Confirm in Phase 5                      |
| F7  | The three `python-fawkes-path-{alpha,beta,prod}-applicationset.yaml` files are referenced by no kustomization and no generator. They target `fawkes-alpha`, `fawkes-beta` and `fawkes-prod`, and all three point at the same GitOps repo, branch `main`, path `.`.                                  | The environments do not differ in git. A matrix generator alone deploys the same manifests three times. See D4   |
| F8  | No test checks that the paths in an ApplicationSet's `files:` generator exist. `scripts/render-all-applications.sh` checks each Application's source, not the generator lists. This is the gap behind the #2118 incident.                                                                          | Phase 1 adds the guard before any list is edited                                                                     |
| F9  | Services pin different versions of the same package: six `fastapi` versions (0.104.1 to 0.141.1), six `uvicorn`, five `httpx`, four `sqlalchemy`.                                                                                                                                                  | Each monolith needs one set of pins. Version unification is real work and the main migration risk                    |
| F10 | `ai-code-review`, `anomaly-detection`, `nps` and `smart-alerting` each have their own workflow and are excluded from `service-python-tests.yml`'s discovery.                                                                                                                                       | Migrating them edits `.github/workflows/`, which needs the owner's approval (`AGENTS.md` §6)                          |
| F11 | The PR size gate (`ci-pr-size.yml`) sums additions and deletions. A service is 400 to 2,700 lines of Python.                                                                                                                                                                                       | Moves must be rename-only or split. Whether GitHub counts a pure rename as zero is assumed, not verified: the pilot proves it |
| F12 | `docs/DEPLOYMENT_STRATEGY.md` ("`services/` consolidated", "2 monoliths: 🟡 In progress") and `docs/ARCHITECTURE.md` ("Fawkes now runs two unified platform services") still state the consolidation as done or under way.                                                                        | #2116 says not to restate it. Phase 0 corrects the text                                                              |
| F13 | README sends cloud users to AWS EKS ("Path B"). `EXECUTION_QUEUE.md` says the live cluster is Azure `fawkes-dev-aks`, rebuilt by hand and destroyed nightly. #2126 (CI-gated `terraform apply`) is open.                                                                                           | Beta needs one named cloud. See D1                                                                              |
| F14 | fawkes Alpha has not shipped. The suite plan's status table has AC-FAWKES-03 failing on #2004 and #1797, and AC-FAWKES-01 needs one clean run (#1858) through `python-fawkes-path`.                                                                                                                | Do not change `python-fawkes-path`'s Application on a cluster while #1858's evidence run is pending                   |

Noticed, out of scope: `docs/KNOWN_LIMITATIONS.md` KL-18 and
`DEPLOYMENT_STRATEGY.md` say OpenBao is migrated, while `AGENTS.md` §5 says it
is not deployed. `services/location.yaml` lists five targets that do not exist
(`cloud-provider`, `data-quality`, `rag`, `python-fawkes-path`, `dora-metrics`).

## Decisions (answered by the owner, 2026-11-11)

| ID  | Question                                                    | Answer                                                                                                                                                                              |
| --- | ----------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| D1  | Which cloud is the Beta target?                             | Azure AKS. README's cloud path changes to match (#2298)                                                                                                                             |
| D2  | Is finishing #2116 a Beta gate?                             | No. Beta is gated on "the docs describe the layout that exists"; consolidation runs beside it                                                                                       |
| D3  | Where do the unmapped and disputed directories go?          | `vsm` → DevEx. `dora-metrics`, `experimentation` → telemetry. `friction-cli` and `feedback-cli` stay command-line clients. `data-api` and `mcp-k8s-server` are still open (#2301)    |
| D4  | How do `alpha`, `beta` and `prod` differ in the GitOps repo? | One overlay directory per environment in each `*-gitops` repo                                                                                                                       |
| D5  | Auto-discovery or an explicit list?                         | A git `files` generator over `platform/apps/golden-paths/*/config.yaml`. A directory deploys only once it holds a `config.yaml`. Check it against the installed ArgoCD version first |
| D6  | Are Valkey (#2189) and SSO (#2190) part of the Beta bar?    | Valkey yes. SSO no                                                                                                                                                                  |
| D7  | `AGENTS.md` §6 approvals this plan needs                    | Approved: ApplicationSet and AppProject edits, catalog descriptors, the four workflows in F10, and tasks over five files for a service move. Every PR still gets maintainer review   |

## Sequence

Each phase is one `goal` issue for Claude Code on Sonnet. Phases 0, 1 and 4
need no cluster and can run beside the live phases; the live phases run one
at a time.

```text
live track      P0 Beta bar ──► P2 new ApplicationSet ──► P3 namespaces ──► P5 deploy + DB ──► P6 java pilot, measure, close
                     │                  ▲                                        ▲
code track      P1 guards, common, scaffolds ──► P4 service migrations (pilot, then waves) ─┘
```

| Phase | Goal issue | Delivers                                     | Needs a cluster | Depends on                                  |
| ----- | ---------- | -------------------------------------------- | --------------- | ------------------------------------------- |
| 0     | #2298      | #2191                                        | No              | Nothing                                     |
| 1     | #2299      | #2116 steps 1-2, #2120's guard               | No              | Nothing. Runs beside Phase 0                |
| 2     | #2300      | #2120 step (a)                               | Yes             | P0, P1's guard, #1858's Alpha run finished  |
| 3     | #2302      | #2120 step (b)                               | Yes             | P2 stable                                   |
| 4     | #2301      | #2116 step 3                                 | No              | P1                                          |
| 5     | #2303      | #2116 steps 4-5                              | Yes             | P4's pilot, P1's guard. Not P2 or P3        |
| 6     | #2304      | #2120 step (c), #2116 step 6, #2191 evidence | Yes             | P3, P5, #2032 phases 1 and 3                |

## Phase 0 — Name what Beta must prove (#2191)

**Goal:** an `intent.md` and `spec.md` in this folder that list numbered Beta
acceptance criteria, each with the evidence that proves it.

Candidate criteria, drawn from `MILESTONES.md` H2, #1805 and the suite plan.
They are input to the spec:

1. The Beta cluster is built from git by CI, with no hand-run `terraform apply` (#2126).
2. No plaintext or placeholder credential in git (#1797, and the Grafana admin
   password `EXECUTION_QUEUE.md` lists as not started).
3. #1805's five criteria. `MILESTONES.md` records three as done; chaos-in-canary
   (#1942) and the Backstage catalog are open.
4. Two golden paths, Python and Java, deploy through one ApplicationSet into
   per-environment namespaces (#2120).
5. The service layout in the docs is the one in the repo (D2).
6. A shared Valkey cache runs on the cluster (#2189, D6).
7. `golden-path-verification` is green on the Beta cluster, with the run linked
   (`AGENTS.md` §9).

**Risks**

| Risk                                                        | Mitigation                                                                 |
| ----------------------------------------------------------- | -------------------------------------------------------------------------- |
| The bar grows into a second roadmap                         | Cap it at criteria that have an owner issue today. Anything else is "after Beta" |
| Criteria are written that nothing can check                 | Each criterion names its evidence, as the suite `spec.md` does             |
| Alpha has not shipped, so "after Alpha" work pulls focus    | Phase 0 writes documents only. Live work waits for #1858 (F14)             |

**Exit criteria**

- `intent.md` and `spec.md` merged; `scripts/check-artifact-chain.sh` passes.
- D1, D2 and D6 recorded in the spec.
- README's status line and cloud path name the D1 cloud; F12's text corrected.
- #2191 closed. The uFawkesRes README table is not touched until a gap closes.

**Issue:** #2298. Its steps, limits and checks are in the issue.

## Phase 1 — Guards and foundations (#2116 steps 1-2, #2120 guard)

**Goal:** everything later phases stand on, with no change to a running
service and no cluster.

**Risks**

| Risk                                                                    | Mitigation                                                                                  |
| ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------- |
| `services/common/` becomes a speculative framework                      | Extract only code that already exists in two or more services (`database.py` ×6, `metrics.py` ×4, `config.py` ×3). Auth is left out until a service needs it, and is `goal` work when it is |
| How a monolith imports `common` is undecided (install, path, build context) | An ADR decides it before any code step starts                                  |
| `service-python-tests.yml` only discovers directories with a `requirements.txt` | Every new directory gets one, so CI runs its tests with no workflow change              |
| Pin drift between `common` and the monoliths (F9)                       | A pin survey comes first; the ADR names one set per monolith                                   |

**Exit criteria**

- The generator-path guard fails on a missing path and passes on `main`.
- `services/common/` has tests green in `service-python-tests.yml`.
- Both monoliths build (`docker build`) and serve `/health` in a test.
- `git diff --stat main -- services/<any existing service>` is empty.

**Issue:** #2299. Its steps, limits and checks are in the issue.

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

**Issue:** #2300. Its steps, limits and checks are in the issue.

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

**Issue:** #2302. Its steps, limits and checks are in the issue.

## Phase 4 — Move services into the monoliths (#2116 step 3)

**Goal:** each mapped service's code runs inside its monolith with its tests
green, one service per pair of small PRs.

**Order.** #2116 says to read the dependency graph before each pick. From F4:
a pilot per monolith first, then services nothing calls, then callers after
their callees, then the two that are deployed today.

| Wave  | Telemetry engine                                              | DevEx service                                           | Why here                                             |
| ----- | ------------------------------------------------------------- | ------------------------------------------------------- | ---------------------------------------------------- |
| Pilot | `insights` (1,157 lines, 4 test files)                        | `friction-bot` (397 lines, 3 test files)                | Has tests, not deployed, no workflow of its own      |
| A     | `discovery-metrics`, `analytics-dashboard`, `experimentation` | `feedback`, then `feedback-bot`                         | `feedback-bot → feedback` becomes an import          |
| B     | `anomaly-detection`, `smart-alerting`                         | `nps`, then `devex-survey-automation`; `ai-code-review` | Four have their own workflow (F10)                   |
| C     | `space-metrics`, `dora-metrics`                               | `vsm`                                                   | Two are deployed today. Code moves here, cut-over in Phase 5 |
| —     | `data-api`                                                    | `mcp-k8s-server`                                        | Not service moves (F3). Still open under D3          |

`discovery-metrics`, `analytics-dashboard` and `experimentation` have no test
files. Each gets a
characterisation test in its old location before it moves.

**Risks**

| Risk                                                             | Mitigation                                                                                                   |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| A move trips the 400-line gate (F11)                             | PR 1 is `git mv` plus import lines only. PR 2 deletes the leftovers. If the pilot shows renames are counted, the owner applies `large-pr-approved`; agents never do |
| One set of pins breaks a service that sat on an older one (F9)   | The service's own tests run inside the monolith before the old directory is deleted                           |
| Two services define the same route, table or metric name         | Mount each under its module prefix per the ADR; a test asserts no duplicate route                             |
| A moved test is edited until it passes                          | The issue forbids editing assertions. Review diffs the test files of every move PR                           |
| #2227 (mypy baseline, one `services/` directory per PR) and #1792 (pipelines for the "remaining 14 services") edit the same directories | Hold #1792 until the monoliths exist; it should target two images, not fourteen. For #2227, move a directory's `.mypy-baseline` line in the same PR as the move |
| Cross-monolith calls are turned into imports by mistake          | Each issue names the edges that stay HTTP (F4)                                                                |

**Exit criteria**

- Every service in waves Pilot to C is a module under its monolith; its old
  directory holds no Python.
- Each monolith's test suite is green in `service-python-tests.yml` and
  contains every test file the old directories had (count before and after).
- `feedback-bot → feedback`, `devex-survey-automation → nps` and
  `analytics-dashboard → experimentation` are imports. The remaining edges in
  F4 are still HTTP and still configured by URL.
- `services/location.yaml` lists only directories that exist.

**Issue:** #2301. Its steps, limits and checks are in the issue.

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

**Issue:** #2303. Its steps, limits and checks are in the issue.

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

**Issue:** #2304. Its steps, limits and checks are in the issue.

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
