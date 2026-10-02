# Intent: enforce the artifact chain in fawkes

**Traces to:** suite release plan, AC-SUITE-03 (fawkes#2174)

## Problem

fawkes follows the `intent → spec → plan` convention but nothing checks it.
The check scripts were copied here from uFawkesAI, yet no workflow runs
them, so a code change can merge with no plan and the convention drifts.

## Desired outcome

Every PR that changes this repo's code paths carries a `plan.md` with a
`## Verification Strategy`, and a `spec.md` never lands without an
`intent.md`. A violation fails a visible check on the PR.

## Constraints

- The code paths are repo-specific, listed in `.artifact-chain-paths`.
- The check starts as a visible, not-yet-required status. It becomes
  required once it has been green on `main` and on a few PRs.
- No change to the checker's rules; this repo only adopts it.
