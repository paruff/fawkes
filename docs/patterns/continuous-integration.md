# Continuous Integration Pattern

Continuous Integration (CI) is the practice of frequently merging developer code
changes into a shared branch, triggering an automated build and test pipeline with
every merge. DORA research consistently identifies CI as one of the strongest
predictors of software delivery performance.

## Core Principles

**Commit small and often** — Small commits are easier to test, review, and roll back.
Aim for multiple commits per developer per day, not large weekly merges.

**Fix broken builds immediately** — When the CI pipeline fails, it is the team's
highest priority. A broken main branch blocks everyone.

**Fast feedback** — The pipeline must complete quickly (under 10 minutes for the
fast path). Slow pipelines discourage frequent commits.

**Trunk-based development** — All developers commit to a single shared branch (`main`).
Feature flags replace long-lived feature branches.

## Fawkes CI Pipeline

Fawkes uses both Jenkins (shared library in `jenkins-shared-library/`) and GitHub
Actions (`.github/workflows/`) for CI:

```
PR created → Lint → Unit tests → Integration tests → Build image
                                                          │
                                              SonarQube scan + Quality Gate
                                                          │
                                              Image pushed to GHCR
                                                          │
                                           ArgoCD deploys to test environment
```

## Pipeline Stages

| Stage | Tools | Gate |
|-------|-------|------|
| Lint | ruff, black, shellcheck, tflint | Formatting violations fail |
| Unit tests | pytest, JUnit | < 80% coverage fails |
| Security scan | SonarQube, Trivy | HIGH/CRITICAL issues fail |
| Build | Docker, Buildpacks | Image tag = git SHA |
| Integration | pytest integration tests | All tests must pass |

## Branch Protection

Merge to `main` requires:
- All CI checks passing
- At least one approving review
- No unresolved comments
- Branch up-to-date with `main`

## See Also

- [GitHub Actions Workflows](../how-to/development/github-actions-workflows.md)
- [Code Quality Standards](../how-to/development/code-quality-standards.md)
- [Deployment Automation Pattern](deployment-automation.md)
