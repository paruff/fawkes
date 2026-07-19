# ADR-034: Tiered Dependency Pinning for Deterministic Builds

> **Status:** Proposed
> **Date:** 2026-07-19
> **Author:** AI-assisted, approved by @paruff
> **DORA Capability:** Cap 2 — Healthy Data Ecosystem
> **Dojo Module:** Black Belt — Supply Chain Integrity

## Context

Fawkes is a polyglot platform with Python (FastAPI services), Go (Terratest), HCL (Terraform), npm (design-system), and Shell (scripts). The current dependency management strategy varies by layer:

- **npm**: `package-lock.json` committed — fully pinned.
- **Terraform**: `.terraform.lock.hcl` committed but `required_providers` use `>=`/`~>` ranges. When dependabot bumps a provider constraint, the lock file goes stale and `terraform init` (without `-upgrade`) fails (observed across PRs #1481-#1490 in July 2026).
- **Go**: `go.sum` committed with checksums; `go.mod` uses minimum versions. Go toolchain resolution is deterministic given the same module cache. The `go` directive controls toolchain version — CI must match (fixed in PR #1492).
- **Python**: ~70% of services already pin with `==`. 6 files still use `>=` ranges (`requirements.txt` root, `dora-metrics`, `feedback-cli`, `friction-bot`, `friction-cli`, `tracer-bullet`). A `pip install` in CI a week apart can produce different dependency trees.

Two concrete failures from non-deterministic dependency resolution:

1. **Terraform lock staleness**: dependabot bumped `hashicorp/azurerm` → new transitive dependency on `hashicorp/aws >= 6.52.0`, but lock had 6.51.0. `terraform init` without `-upgrade` failed.
2. **Go toolchain mismatch**: `go.mod` upgraded to `go 1.25.8`, but CI still used `go-version: 1.24` with `GOTOOLCHAIN=local`. Build reproducibility broken.

**The DORA 2025 finding:** "A healthy data ecosystem" (Cap 2) requires dependency manifests that are "version-controlled and AI-consumable." An `>=` range is neither — it is an instruction to fetch something different each time. Fawkes' own AGENTS.md §11 states: "Type hints, docstrings, and structured logs make Fawkes data AI-consumable." The same principle applies to dependency manifests.

## Decision

We will enforce exact version pinning (`==`) in all Python `requirements.txt` files and maintain committed lock files in all four language layers, treating dependency upgrades as explicit, reviewable changes surfaced through dependabot PRs.

## Rationale

- **Eliminate environmental drift**: CI, local dev, and production must resolve identical dependency trees. Without pinning, `pip install` is non-deterministic — dependabot evolves constraints but does not commit lock files for Python.
- **Reduce the failure class we just fixed**: Three systemic CI failures (terraform lock staleness, go toolchain mismatch, python resolution drift) all share one root cause: constraints and locks out of sync. Pinning makes the constraint _equal to_ the lock — they can't diverge.
- **DORA-aligned**: Cap 2 (Healthy Data Ecosystem) and Cap 5 (Working in Small Batches) both require predictability. A build that succeeds on Monday and fails on Tuesday for no code change is not a small batch — it's a hidden batch triggered by upstream registry changes.
- **Agent-enforceable**: "Use `==` in requirements.txt" is a mechanical rule that can be linted (e.g., pre-commit hook or `pip-audit` / `safety check`), making it a reliable constraint for both human and AI contributors.

## Consequences

**Positive:**

- Every dependabot PR now represents an explicit, testable, version-controlled change
- CI validation is truly deterministic — no "it passed yesterday" incidents
- Supply chain audit trail: exact version changes are visible in git history
- Agent-authored PRs are safer because what the agent tests locally matches what CI tests

**Negative:**

- Dependabot PR volume may increase (every patch bump becomes a PR). Mitigated by dependabot grouping.
- Manual pin bumps required for urgent hotfixes (no `>=` to absorb patches). Mitigated by dependabot.
- `requirements-dev.txt` files also need pinning (currently mostly `>=` ranges). Smaller surface area, but should be included.

**For agents:**

- Agents MUST use `==` (not `>=` or `~=`) when adding or modifying dependencies in any `requirements.txt` or `requirements-dev.txt`
- Agents MUST NOT add new Python dependencies without updating `requirements.txt` with an exact pinned version
- When an agent generates a requirements file, it must run `pip install -r requirements.txt` locally and verify the pinned versions resolve before committing
- Dependabot is the approved mechanism for bumping pinned versions; agents should not bump pins without an explicit instruction

## Alternatives Considered

| Option                                                    | Why Rejected                                                                                                                                                                       |
| --------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `pip-compile` with `requirements.in` + `requirements.txt` | Adds tooling complexity. Fawkes has 23+ `requirements.txt` files; managing `*.in` files doubles the count. For a monorepo of this size, direct pinning with dependabot is simpler. |
| Freeze at major version only (`>=X.0.0,<X+1.0.0`)         | Still allows patch-level drift. The July 2026 CI failures happened because of _transitive_ dependency resolution, not just direct deps.                                            |
| Status quo (keep mixed pinning/lax)                       | Proven failure mode — see PRs #1481-#1490. The mixed strategy creates surprise failures.                                                                                           |
| Pinning with `poetry.lock` / `pipenv`                     | Introduces a new package manager. Fawkes uses `pip` + `requirements.txt` consistently; tooling change is out of scope for this decision.                                           |

## Implementation

- [ ] Convert 6 files from `>=` to `==` with currently-resolved versions (this PR)
- [ ] Add pre-commit hook that warns on `>=` in `requirements*.txt` → Issue to be created
- [ ] Configure dependabot grouping for Python patch bumps → Issue to be created
- [ ] Add weekly CI job to verify `pip install` resolves identically → Issue to be created
- [ ] Update AGENTS.md §6 (Python coding standards) to add pinning rule → this PR
