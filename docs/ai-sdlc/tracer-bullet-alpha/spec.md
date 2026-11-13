# Spec: fawkes Tracer Bullet Alpha

**Traces to:** [`intent.md`](intent.md) | **Plan:** [`plan.md`](plan.md)

## Acceptance Criteria

The text and the verification of each are in the
[suite spec](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/spec.md#release-6--fawkes-tracer-bullet-alpha).

- **AC-FAWKES-01:** commit to staging works in one clean run.
- **AC-FAWKES-02:** deployment frequency and lead time for changes are
  queryable in Grafana from native PromQL.
- **AC-FAWKES-03:** no known P0 security issues.
- **AC-FAWKES-04:** public claims are scoped to Alpha.

## Design

Alpha changes no architecture: [`docs/ARCHITECTURE.md`](../../ARCHITECTURE.md)
and the ADRs stay as they are. CI runs in-cluster on Tekton (ADR-036, which
supersedes ADR-004), and deploys go through ArgoCD.

## Interfaces

fawkes provides no contract to another suite repo in Alpha. Its own services'
APIs are in [`docs/API_SURFACE.md`](../../API_SURFACE.md). It consumes these
rows of the suite's [cross-repo interface contracts](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/spec.md#cross-repo-interface-contracts):

| Contract | From | Pinned by |
| --- | --- | --- |
| Reusable workflows (`reusable-main-ci-guard.yml`, `reusable-security-scanning.yml`) | uFawkesPipe | Commit SHA |
| `ufawkes-ci` CI job image | uFawkesPipe | Digest |
| `fawkes-space` devcontainer image | uFawkesAI | Digest |

fawkes doesn't use uFawkesPipe's `.fawkespipe.yml` contract or Woodpecker, and
it doesn't send DORA events to uFawkesObs: its DORA metrics come from its own
Prometheus (AC-FAWKES-02).

## Pipeline invariants

The [suite pipeline invariants](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/spec.md#pipeline-invariants) apply here, with one departure:

- **PI-5:** the hook job is this repo's own `pre-commit.yml` (`Pre-commit · Base`), not uFawkesPipe's `reusable-preflight.yml`.

This repo adds:

- A claim is made only after it has been run: a CI log or an ArgoCD sync history, linked from the release notes (`INTENT.md`).
- No `CHANGE_ME_*` credential is committed (AC-FAWKES-03).
