# Fawkes AI Stance

> **Reviewed**: 2026-09-11 | **Next review**: 2026-12-11 (quarterly with roadmap)

## Position

Fawkes **uses AI assistance for delivery and teaches it via the Dojo**, within guardrails. AI accelerates strong foundations; it does not replace tests, review, or human approval on security-sensitive changes.

## Allowed

- AI-generated code, tests, docs, and manifests — declared in the PR body per `AGENTS.md` (Read → Run → Review → Declare).
- AI-assisted triage, debugging, and metrics analysis with evidence (`kubectl`, test output) attached.

## Required

- **Read → Run → Review**: read the module/test first, run tests green before opening a PR, human review for security/RBAC/infra changes.
- Small batches: PRs ≤ 400 lines (`large-pr-approved` label is human-only).
- Never commit secrets; never push to `main`; never delete tests to make CI pass.
- Conventional Commits on every commit (`ci-commit-lint.yml` enforces).

## Not allowed

- AI-merged PRs (humans merge), `infra/` changes without a second human reviewer, unaudited model/dependency upgrades in supply-chain paths.

## DORA linkage

Implements DORA AI Capability 1 (clear, communicated AI stance). Capability mapping for the suite lives in [ROADMAP](ROADMAP.md). Agent rules live in [AGENTS](AGENTS.md).
