---
name: tdd-workflow
description: Use before implementing any bug fix, new function, or config change — write and run a failing test first, confirm it fails for the right reason, then implement to pass.
---

# Test-Driven: Red, Then Green

**Never write implementation before a test that proves it's needed.** This
applies to bug fixes, new functions, and infra/config changes alike — not
just application code.

## The loop

1. **Write the test first.** For a bug: reproduce it. For new behavior: assert
   the contract you're about to build. For infra/config: the check that
   proves the config has the intended effect (see commands below).
2. **Run it. Confirm it fails — and read *why*.** A test that fails for the
   wrong reason (typo, missing import, wrong file path) proves nothing. Fix
   the test setup until the failure is the one you actually expect, before
   touching implementation.
3. **Write the minimum code to pass.** No extra scope, no "while I'm here"
   changes — see the surgical-changes rule in `AGENTS.md`.
4. **Run it again. Confirm green.** Then run the broader suite for that area,
   not just the one test — see `verify-before-done`.

Never write the test after the code to match what the code already does —
that only proves the code does what it does, not that it's correct.

## Commands by area (this repo)

| Area | Command |
|---|---|
| Python | `pytest <path>` (or `pytest --cov=. --cov-report=term-missing` for coverage) |
| Shell scripts | `make test-bats` (single file: `bats tests/<file>.bats`) |
| Terraform modules | `make terraform-test` (unit-level, no resources deployed) |
| BDD / acceptance | `make test-bdd COMPONENT=<name>` |
| Everything | `make test-unit` then `make test-all` before opening a PR |

For a Kubernetes/Helm config change with no test framework, the equivalent
red/green check is `helm template` / `kubeconform -strict` before vs. after —
render it first, confirm the field you're adding is absent (red), add it,
confirm it's present in the rendered output (green).

## When there's no existing test framework for the file

Still do it: a small standalone script (`scripts/`) or a one-off assertion
block is enough — see `AGENTS.md` §7's per-language required checks for what
already exists to build on before inventing a new pattern.
