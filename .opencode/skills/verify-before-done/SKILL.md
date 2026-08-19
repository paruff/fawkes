---
name: verify-before-done
description: Use before claiming a fix works, tests pass, or a PR is ready — before committing, pushing, or replying "fixed" on an issue/PR comment.
---

# Verify Before Claiming Done

**Evidence before claims.** Don't tell a human (or write in a commit/PR/issue
comment) that something is fixed, passing, or ready unless you just ran the
command that proves it, in this session, and read its output.

## Gate before any completion claim

1. Identify the exact command that proves the claim (test suite, linter,
   `terraform validate`, `helm lint`, the specific failing CI job re-run).
2. Run it fresh — not "ran it earlier," not "should still pass."
3. Read the full output and exit code, not just the last line.
4. Only then state the claim, citing what you ran and its result.

| Claim | Needs | Not enough |
|---|---|---|
| Tests pass | Fresh test run, 0 failures | "Should pass now" |
| Bug fixed | Test for the original symptom, now green | Code changed, assumed fixed |
| Lint/build clean | Fresh linter/build output, exit 0 | Linter passed (≠ compiler/build) |
| PR ready | Checklist against the issue's acceptance criteria | Tests passing alone |

## On this repo specifically

- `make lint` output goes in the PR body per `AGENTS.md` §8 — run it, don't
  paraphrase it.
- Never delete or weaken a test to make CI green; if a test seems wrong, say
  so and ask, don't route around it.
- If you can't run something in this environment (e.g. no live cluster), say
  exactly that instead of asserting success.
