# INTENT — Read This Before Touching Anything

**Fawkes** is the core internal delivery platform of the uFawkes suite: the
platform-orchestration layer (Kubernetes, in-cluster Tekton CI, GitOps with
ArgoCD) that the composable Docker stacks (uFawkesObs, uFawkesPipe,
uFawkesDevX) grow into. It's also the **Kubernetes graduation track** for
the learning path: a learner who has run a stack on Docker Compose moves
here to run the same ideas on a cluster.

## The one thing to know

**Fawkes is pre-alpha (`v0.3.95`, September 2026).** Evaluating it on a
laptop with k3d works (`make dev-up`). Cloud production does not. The README
and the site must say that, and nothing public may imply Beta or Production
readiness. The first milestone is **Tracer Bullet Alpha**: one service going
from a commit to staging in a single clean run, with two DORA metrics
visible.

## Where this sits in the suite

| Role                                       | Repo                                 |
| ------------------------------------------ | ------------------------------------ |
| Core IDP (platform orchestration)          | **fawkes** (this repo)               |
| Observability, CI/CD, developer experience | uFawkesObs, uFawkesPipe, uFawkesDevX |
| Learning (the Dojo curriculum)             | uFawkesDojo                          |
| AI-SDLC template and devcontainer image    | uFawkesAI                            |

The suite release plan is at
[uFawkes.dev `docs/ai-sdlc/suite-release/`](https://github.com/paruff/uFawkes.dev/tree/main/docs/ai-sdlc/suite-release).
This repo's first release, Tracer Bullet Alpha, is Phase 6 of that plan. It
is gated on AC-FAWKES-01 to AC-FAWKES-04. It is deliberately last: the
stacks release first, and fawkes follows once they have.

## What "done" means here

- **Alpha ships when its four acceptance criteria pass:** commit to staging
  in one clean run; two DORA metrics queryable in Grafana from native PromQL;
  no known P0 security issues; public claims scoped to Alpha.
- **A claim is made only after it has been run.** A passing run is a CI log
  or an ArgoCD sync history, linked from the release notes.
- **Planning follows the `intent → spec → plan` chain:**
  `docs/ai-sdlc/<feature-or-release>/intent.md` → `spec.md` → `plan.md`. The
  release folder `docs/ai-sdlc/tracer-bullet-alpha/` is written before the
  tag. Decisions that last go in ADRs (superseded ADRs say so at the top, as
  ADR-004 does for Jenkins).
- **The existing milestones stay.** The Alpha epic's children and its labels
  are the only things re-scoped to the suite plan.

## Explicit non-goals

- **The Dojo curriculum.** That lives in uFawkesDojo.
- **A hosted CI service.** Fawkes runs CI for itself and for the services on
  it; it doesn't offer CI to others.
- **Beta and Production.** Not built, and not promised. They're listed in
  the README as not yet built.
- **Replacing the Docker stacks.** The stacks remain the fast path for one
  concern at a time. Fawkes is for running the whole platform on Kubernetes.
