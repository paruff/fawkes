> Load with: "pr-contract skill" in your prompt
> Example: "Use the pr-contract skill to implement this feature."

# Fawkes PR Contract Skill

## PM-Agent contract

- PM or issue writer defines the goal, file scope, acceptance criteria, and suggested model.
- The coding agent implements only the scoped change, validates it, and documents judgment calls.
- Human reviewers approve architecture, security, infra, workflow, and rollout risk.
- Humans merge PRs; agents do not self-merge or rewrite shared history.

## PR size limit and enforcement

- Target one concern per PR.
- CI blocks pull requests above 400 changed lines via `.github/workflows/ci-pr-size.yml`.
- Only a human with write access may apply the `large-pr-approved` override label.

## Required PR description block

Include this AI-Assisted Review Block in the PR body:

```text
AI-Assisted Review Block
- What this PR does:
- Layers touched:
- Tests added or updated:
- Linters/validation run:
- Judgment calls for human review:
- AI-generated or AI-reviewed sections:
```

## Agents MAY do without asking

- Read any repository file.
- Edit scoped files in services, scripts, docs, tests, charts, or platform manifests.
- Run existing linters, tests, docs builds, `terraform validate`, and `helm lint`.
- Open draft PRs and update developer documentation that matches the implemented change.

## Agents MUST ask before doing

- Modifying `.github/workflows/`.
- Creating or changing ArgoCD `Application` manifests.
- Editing Backstage catalog descriptors.
- Adding a new Terraform provider, backend, or external service dependency.
- Expanding a task beyond the agreed file scope or above the PR size gate.

## Agents must NEVER do

- Commit secrets or sensitive environment values.
- Delete tests to make CI pass.
- Bypass hooks, branch protections, or PR review requirements.
- Push to `main`, merge their own PRs, or apply human-only labels.
- Invent acceptance criteria that were not approved by the issue or maintainer.

## Coding standards

- Naming: follow existing directory and file conventions; prefer descriptive scope names in commits.
- Types: add type hints to new Python functions and keep errors explicit.
- Tests: update the smallest relevant existing test surface; run what you changed.
- Commits: use conventional commits such as `feat(scope):`, `fix(scope):`, `docs(scope):`.
- Coverage: preserve or improve current coverage; root CI enforces `pytest --cov=. --cov-fail-under=60 tests/unit/`.
