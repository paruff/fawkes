# Plan: adopt uFawkesPipe's shared shift-left hooks

**Traces to:** uFawkes.dev [`docs/ai-sdlc/shift-left/spec.md`](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/shift-left/spec.md)
(R1–R6, R9) and its [plan](https://github.com/paruff/uFawkes.dev/blob/main/docs/ai-sdlc/shift-left/plan.md),
phase C6 | **Status:** In progress

uFawkesPipe publishes the suite's shift-left hooks and tools once, by tag.
This repo pins that tag and holds one file of its own, `scripts/shift-left.sh`,
which runs the tools that aren't hooks (doctor, agent gate, triage,
`require-tool`) from the same pinned clone.

fawkes keeps its own selective CI (`.github/workflows/pre-commit.yml`): four
layers, each running named hooks on the PR's changed files. It doesn't call
uFawkesPipe's reusable Pre-flight. The parity check counts those per-hook runs.

| Step | What                                                                                                                                                                            |
| ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| C6a  | Clear semgrep `p/ci` to 0: workflow injections through `env:` (#2203); `secrets: inherit`, mutable action tags, Dependabot cooldowns, the sample app's bind (#2204)              |
| C6b  | The shared hooks (parity, semgrep, Trivy, stamps), actionlint and schema hooks, `require-tool` for tool-backed hooks, unit tests as a hook, every hook in a CI layer or `.shift-left.yml`, the doctor at session start, the agent gate, the devcontainer, `make doctor` |

## Verification Strategy

| Check                                 | How                                                                                     |
| ------------------------------------- | --------------------------------------------------------------------------------------- |
| Every hook runs in CI or says why not | `shift-left-parity` (a hook, and run in CI's base layer)                                |
| The hooks pass                        | `pre-commit run --all-files` and `--hook-stage pre-push`, then CI's layers on the PR    |
| The checks actually run in a clone    | `make doctor`                                                                           |
| Nothing slips back                    | uFawkes.dev's `/status/` matrix, rebuilt daily                                          |
