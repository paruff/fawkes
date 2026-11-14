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

### DORA dashboards and rule names

Read from `main` at `73dfd533` on 2026-11-13, with no cluster (paruff/fawkes#2310):

- `platform/apps/grafana-dashboards/` ships two copies of uFawkesObs
  dashboards. The overview copy queries `dora_*{team_id}` gauges that only
  uFawkesObs's `dora-api` emits, so in fawkes those panels have no data.
- Two rules that carry the Alpha's repo-level metrics,
  `dora:fawkes_repo_deployment_frequency:rate30d` and
  `dora:fawkes_repo_lead_time_hours:avg30d`, are in
  `platform/apps/prometheus/rules/dora.yml` (the reference copy) and not in
  the live map in `prometheus-application.yaml`. Two panels query them.
- `dora:deployment_frequency:rate30d` is deployments per day here and a sum
  of per-week values in uFawkesObs, under the same name.
- One panel reads a `ufawkesres-postgres` datasource that doesn't exist.

What Alpha needs from this, as part of AC-FAWKES-02's evidence and not a new
criterion:

- Every panel on a dashboard that ArgoCD deploys names a metric or rule that
  the manifests produce.
- A rule that shares its name with a uFawkesObs rule states its unit in the
  rule's comment and in the panel title, or takes another name.

## Design tokens

The design system follows the suite's tokens
([`DESIGN.md`](../../../DESIGN.md)), copied by hand.
`scripts/check-design-token-sync.py` compares two colour scales and runs in
no hook or workflow. Outside those scales the code has a teal secondary,
`#16a34a`, five breakpoints and eight radii where the tokens have none of the
first two, two breakpoints and two radii (paruff/fawkes#2311). This is not an
Alpha criterion.

## Pipeline invariants

The [suite pipeline invariants](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/suite-release/spec.md#pipeline-invariants) apply here, with one departure:

- **PI-5:** the hook job is this repo's own `pre-commit.yml` (`Pre-commit · Base`), not uFawkesPipe's `reusable-preflight.yml`.

This repo adds:

- A claim is made only after it has been run: a CI log or an ArgoCD sync history, linked from the release notes (`INTENT.md`).
- No `CHANGE_ME_*` credential is committed (AC-FAWKES-03).
