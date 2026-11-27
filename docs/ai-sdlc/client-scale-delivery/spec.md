# Spec: Beta for a first adopter, then scale

**Traces to:** [`intent.md`](intent.md) | **Plan:** [`plan.md`](plan.md) | **Redefines:** [`../path-to-beta/plan.md`](../path-to-beta/plan.md)

Repo facts were checked against `main` at `0904e2a9` on 2026-11-27, with no
cluster reachable. Anything said here about a cluster is quoted from the cited
docs, not observed.

## Decisions (owner, 2026-11-27)

| ID | Question | Answer |
| --- | --- | --- |
| C1 | What does Fawkes do for the adopter first? | Their delivery pipeline. Monitoring and managing their infrastructure at scale comes second (Goal 2) |
| C2 | Which cloud? | Azure AKS first. AWS EKS once the adopter has AWS access. The move is Goal 2's portability test |
| C3 | Serverless | Plain Kubernetes Deployments in Beta. Serverless on Kubernetes (Knative, KEDA) is the Goal 2 target. Not the cloud's own function services |
| C4 | Is Beta redefined around the adopter? | Yes. This spec is the Beta bar, and it changes path-to-Beta as listed below |
| C5 | Golden paths | Reuse `python-fawkes-path` and `java-fawkes-path`, and add `nodejs-fawkes-path` |
| C6 | Deadline | Goal 1 within six weeks of this spec's approval |
| C7 | SSO | In Beta (#2190) |
| C8 | Where does Fawkes verify itself? | On a Fawkes-owned cluster that CI creates and destroys: AKS now, and EKS once there is AWS access. Never on the adopter's cluster |
| C9 | How does the adopter consume Fawkes? | From versioned releases (tagged Terraform modules, Helm charts and an ArgoCD root app) that their own repos reference. Not a fork |
| C10 | Which languages gate Beta? | Python plus the adopter's chosen language. The third follows after Beta |
| C11 | Source control | GitHub, for Fawkes and for the adopter |
| C12 | #2004 (extract-zip) | Accepted as KL-20 and closed. Only a dev toolchain (Lighthouse CI) reaches it |
| C13 | Customers before Goal 2? | None. The separate production cluster can wait for Goal 2 |

## Goal 1 — Beta: the delivery pipeline (six weeks)

Every criterion closes with evidence linked on its issue: a CI run, a Tekton
PipelineRun, an ArgoCD sync, or a Grafana screenshot taken from a live query.
A merged PR on its own is not evidence (`AGENTS.md` §9).

### Acceptance criteria

- **AC-BETA-01 Self-serve delivery.** A developer who is not a Fawkes
  maintainer scaffolds a service from a Fawkes template in Backstage, pushes
  to `main`, and the service is built, tested, scanned, signed, given an SBOM,
  synced to staging by ArgoCD, and promoted to production through a reviewed
  pull request. No maintainer touches it. Evidence: the run, and the
  developer's own account of it on the issue. The run is on the adopter's
  cluster. If the adopter slips, the same run by any non-maintainer on the
  Fawkes cluster counts.
- **AC-BETA-02 Golden paths.** Python and the adopter's chosen language each
  have a reference repo that passes the `golden-path-verification` workflow
  end to end on AKS. The Backstage template for each language scaffolds what
  its reference repo runs. If the adopter hasn't chosen a language by week 2,
  Node.js/TypeScript is the second.
- **AC-BETA-03 Infrastructure from versioned releases.** An empty Azure
  subscription gets its AKS cluster and the Fawkes platform through tagged
  Fawkes releases referenced from repos the adopter owns. Changes go through
  CI-gated `terraform apply` (#2126) and ArgoCD. No step is applied by hand.
  A runbook in `docs/` takes an adopter from an empty subscription to
  AC-BETA-01.
- **AC-BETA-04 Single sign-on.** The adopter's team signs in to ArgoCD,
  Grafana and Backstage with their GitHub identities. Developers can promote
  to staging; promotion to production needs an approver role. (#2190)
- **AC-BETA-05 Real DORA metrics.** Deployment frequency, lead time, change
  failure rate and time to restore show on the DORA dashboard for each
  adopter service, from Fawkes's own recording rules (ADR-038). The drift
  test from PR #2318 has an empty known-gaps list: every panel queries a series
  the manifests produce. (#2310, #2314)
- **AC-BETA-06 No known P0 security issues.** #1797 is closed. #2004 is closed
  as accepted risk KL-20. No `CHANGE_ME_*` placeholder credentials exist, and
  secrets reach workloads through Sealed Secrets or External Secrets.
- **AC-BETA-07 Claims match reality.** README, `MILESTONES.md`, `VISION.md`
  and `docs/DEPLOYMENT_STRATEGY.md` describe Beta as built: AKS first, EKS
  next, which golden paths gate Beta, and the adopter persona alongside the
  platform-engineer one.

### Prerequisites

Fawkes Alpha (#1804) has not shipped. Its open items are on Beta's critical
path: #1797, and one clean `python-fawkes-path` run on AKS (#1858).

### Design

- **Delivery model.** Unchanged: Tekton in-cluster CI, then a GitOps pull
  request, then ArgoCD sync. Services deploy as plain Kubernetes
  Deployments, or Argo Rollouts where canary analysis already exists.
- **Cluster layout (my call).** For Beta, one AKS cluster per owner (the
  Fawkes verification cluster, and the adopter's own) with a namespace per
  language and environment (path-to-Beta Phase 3). Production moves to its own
  cluster in Goal 2, before customer traffic (C13).
- **Environments.** One overlay directory per environment in each `*-gitops`
  repo (path-to-Beta D4, unchanged).
- **Golden paths.** Each language has a reference repo, `paruff/<lang>-fawkes-path`,
  plus a `-gitops` repo:
  - **Python:** `python-fawkes-path` exists and is the Alpha evidence repo.
  - **Java:** `java-fawkes-path` exists but has no `-gitops` repo yet (#2032).
  - **Node.js:** a new `nodejs-fawkes-path` repo, built the same way.
  The templates in `templates/` stay in step with the reference repos.
- **Registry (my call).** GHCR, which the Alpha pipeline already pushes to,
  and which works the same from either cloud. The `harbor.fawkes.local`
  references in `templates/` are removed.
- **Releases (C9).** Fawkes tags its Terraform modules, Helm charts and an
  ArgoCD root app. The adopter's infra and GitOps repos pin those tags.
  `AGENTS.md` §5 already requires versioned modules in production. This is
  the packaging work that makes it true.
- **Single sign-on.** An ADR picks the broker before any code (#2190 asks for
  this). The identity source is the adopter's GitHub organisation. My
  default for the ADR is the Dex instance that ArgoCD bundles, shared with
  Grafana and Backstage.
- **Clouds.** `infra/azure/` is the Beta target. `infra/aws/` keeps passing
  `terraform plan` in CI so that it doesn't rot before Goal 2.

### Changes to the path-to-Beta plan

| Item | Was | Now |
| --- | --- | --- |
| D1, Beta cloud | Azure AKS | Unchanged for Beta. EKS added in Goal 2 |
| D2, service consolidation as a gate | Not a gate | Unchanged |
| D6, Valkey and SSO | Valkey in, SSO out | SSO in (AC-BETA-04). Valkey moves to Goal 2, because it serves scale, not delivery (my call) |
| P0 #2298, Beta bar | To be written | This spec is the Beta bar. The issue is re-scoped to point here |
| P1 #2299, guards and scaffolds | In Beta | Guards stay in Beta. The monolith scaffolds continue beside it |
| P2 #2300, P3 #2302, ApplicationSet and namespaces | Python only | In Beta, for every language that gates Beta |
| P4 #2301, P5 #2303, service moves and database split | In Beta | Off the Beta path. They continue beside it |
| P6 #2304, Java pilot and footprint | In Beta | The Java golden path gates Beta only if Java is the adopter's language (C10). The footprint measurement moves off the Beta path |

Every re-scoped issue gets a comment that links here. None is closed
silently.

## Goal 2 — Scale (after Goal 1)

Outline only. The full spec is written when Goal 1 passes. These are the
outcomes it will make measurable:

- **Production cluster** separate from staging, before customer traffic.
- **SLOs and alerting** for each adopter service, with error-budget alerts that
  reach a person (#2124, #1857).
- **Load proven at the target rate** before customer traffic arrives.
- **Serverless on Kubernetes**: Knative Serving for request-driven services,
  scaling to zero, and KEDA for event-driven ones, both on the existing
  Tekton and ArgoCD path.
- **Cache**: the shared Valkey app (#2189).
- **AKS to EKS**: one reference app moves with changes only to Terraform
  variables and overlays. Anything more is a defect. This needs AWS
  remote state (#1569).
- **The third golden path** (C10).
- **Incident practice**: runbooks in `docs/runbooks/`, and chaos testing in the
  canary step (#1942, #1943).

Open for the Goal 2 spec: what "millions of transactions" means in numbers
(per day or per month, the peak rate, and the latency target).

## Existing issues

The plan reviews all open issues against this spec. Each one gets exactly
one verdict, recorded as a comment:

- **Verified:** closed, with the linking evidence.
- **Resolved, not verified:** stays open, with the check that would verify it.
- **Superseded:** closed, with a link to what replaced it.
- **Beta:** linked to a Goal 1 goal issue.
- **Goal 2 or later:** left open and unlinked.

What a first pass at `0904e2a9` found:

| Issue | Finding | Proposed verdict |
| --- | --- | --- |
| #2081 | Built by PR #2144 without DevLake. PR #2318 shows the two rules it adds are missing from Prometheus's live rule map | Resolved, not verified (AC-BETA-05) |
| #1569 | The AWS S3 and DynamoDB state module exists (PR #2112). Nothing shows it in use | Goal 2 (AKS to EKS) |
| #1153 | The same work as #1569 | Superseded by #1569 |
| #1572, #1919 | Rule names were aligned (PR #2112). #2310 shows panels still query series nothing produces | Beta (AC-BETA-05) |
| #1680 | Proposes DevLake for DORA. ADR-038 replaced that with native PromQL | Superseded by ADR-038 |
| #2079 | CFR is native per `MILESTONES.md`, but the title still says DevLake | Verify, then close or retitle |
| #2004 | Documented as accepted risk KL-20 in PR #2112 | Close as accepted (C12) |

Closing an issue changes the public board, so the plan lists every proposed
close for the owner to approve in one batch before any is closed.

## Harnesses and models

This extends the routing labels already used on the board (`claude-code`,
`opencode,model:<name>`). The opencode setup is the canonical one from
uFawkesAI (`opencode/`), and this repo does not copy it. Adopters and
contributors install it from there.

| Work | Harness and model | Label |
| --- | --- | --- |
| `goal` issues, specs, ADRs, security, RBAC, `infra/`, cross-layer changes, PR review | Claude Code, Opus 5.5 for planning and review, Sonnet 5.5 for implementation | `goal,claude-code` |
| Multi-file but well-specified work: template ports, manifest cleanups, doc sweeps, test suites | opencode, NVIDIA-hosted Nemotron 3 Ultra (`nvidia/nemotron-3-ultra-550b-a55b`) | `opencode,model:nemotron-3-ultra` |
| Single-file edits, lint fixes, small tests | opencode, NVIDIA-hosted GLM-5.3 Flash or Nemotron 3.5 Lightning | `opencode,model:glm-5.3-flash` |
| First issues for outside contributors who have no API key | opencode free tier (`mimo-v2.6-flash-free`, `nemotron-3-ultra-free`) | `opencode,model:mimo-v2.6-flash`, plus `good first issue` |

Rules, whatever the model:

- Changes to security, RBAC, secrets and `infra/` are always reviewed by a
  human (`AGENTS.md` §12), and they never go to a free-tier model.
- An issue routed to opencode needs files to edit, a reference file and
  measurable acceptance criteria before it is labelled (`AGENTS.md` §11).
- If rework on a model's PRs passes 20% over five PRs, improve the issue
  bodies first, then move that kind of work up a tier.
- Free and hosted model names change often. The routing table lives in
  uFawkesAI. This table names tiers and gives today's model in each.
