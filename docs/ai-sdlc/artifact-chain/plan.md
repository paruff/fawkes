# Plan: enforce the artifact chain in fawkes

**Traces to:** [`intent.md`](intent.md) | fawkes#2174

## Changes

1. Update `scripts/check-artifact-chain.sh` and `scripts/test-artifact-chain.sh`
   to the uFawkesAI versions (configurable code paths; the test no longer
   leaks git's hook environment into the real repo).
2. Add `.artifact-chain-paths` listing this repo's code paths:
   `platform/`, `services/`, `charts/`, `infra/`, `extensions/`, `scripts/`.
3. Add `.github/workflows/artifact-chain.yml`, which runs the self-test and
   the check on every pull request.

## Verification Strategy

| Criterion              | Evidence                                                             | How                                                       |
| ---------------------- | -------------------------------------------------------------------- | --------------------------------------------------------- |
| The self-test passes   | All 16 scenarios behave as expected                                  | `bash scripts/test-artifact-chain.sh`                     |
| `main` is not made red | The check passes with no diff, so every existing spec has its intent | `bash scripts/check-artifact-chain.sh HEAD HEAD`          |
| This PR obeys the rule | This PR touches a code path and carries this plan                    | The `Artifact Chain` check on this PR                     |
| A violation is caught  | A throwaway PR touching a code path with no plan fails the check     | Self-test scenarios 'paths-custom-blocks' and 'skip-plan' |

## Follow-up

Make `Artifact Chain` a required check once it has been green on `main` and
on several PRs (a ruleset change, tracked separately).
