# Contributing to Fawkes

Thank you for your interest in contributing to Fawkes! This file is the canonical
contributor guide shown by GitHub. For the full documentation site version, see
[docs/contributing.md](../docs/contributing.md).

---

## Quick Start

```bash
# 1. Fork the repository on GitHub, then clone your fork
git clone https://github.com/<your-username>/fawkes.git
cd fawkes

# 2. Add the upstream remote
git remote add upstream https://github.com/paruff/fawkes.git

# 3. Fetch upstream and create a feature branch from latest main
git fetch upstream
git checkout -b feature/your-feature-name upstream/main

# 4. Install pre-commit hooks (one-time)
make pre-commit-setup

# 5. Make changes, then verify locally
make lint
make test-unit

# 6. Commit using Conventional Commits
git commit -m "feat(scope): short description"

# 7. Push your branch and open a PR against main
git push origin feature/your-feature-name
```

---

## Git Workflow

We follow a **fork → feature branch → PR against `main`** model:

1. **Fork** the repository to your own GitHub account.
2. **Clone** your fork and add `upstream` remote (see Quick Start above).
3. **Branch** — always branch from the latest `main`:
   ```bash
   git fetch upstream
   git checkout -b feature/<your-feature> upstream/main
   ```
4. **Commit** frequently with [Conventional Commits](https://www.conventionalcommits.org/):
   - `feat(scope):` — new functionality
   - `fix(scope):` — bug fixes
   - `docs(scope):` — documentation only
   - `test(scope):` — adding or updating tests
   - `chore(scope):` — maintenance, config, tooling
5. **PR** — open a pull request against `main` on the upstream repository.
   - Fill out the PR template fully.
   - Reference the linked issue with `Closes #NNN`.
   - Keep PRs small (< 400 lines of diff); CI enforces this.
6. **Address review** — respond to comments and push fixes to the same branch.
7. **Merge** — a maintainer merges after all checks pass and review is approved.

> **Never push directly to `main`.** All changes go through pull requests.

---

## Branch Protection

The `main` branch is protected with the following rules, enforced by GitHub:

| Rule | Setting |
|------|---------|
| Require pull request before merging | ✅ Enabled — direct push to `main` is blocked |
| Required approvals | 1 maintainer approval minimum (2 for infrastructure changes) |
| Require status checks to pass | ✅ CI (`code-quality`), lint (`pre-commit`), and security scans must pass |
| Require branches to be up to date | ✅ Branch must be current with `main` before merge |
| No force push to `main` | ✅ Force-push is disabled |
| No branch deletion | ✅ `main` cannot be deleted |
| Require conversation resolution | ✅ All review threads must be resolved before merge |

### Required Status Checks

The following CI checks must pass before a PR can be merged:

- **`code-quality`** — Runs linters (ruff, black, mypy, shellcheck, shfmt, tflint, yamllint, golangci-lint, markdownlint)
- **`pre-commit`** — Runs all pre-commit hooks (secrets detection, formatting, YAML validation)
- **`security-and-terraform`** — Runs Trivy, tfsec, and SAST scanning
- **`ci-pr-size`** — Enforces the 400-line PR size limit

### Infrastructure Changes

Pull requests touching `infra/` require:
- Two human approvals (not just one)
- A `terraform plan` output attached to the PR description
- The `large-pr-approved` label if the diff exceeds 400 lines

---

## Code Quality

All contributions must pass automated checks. Run locally before pushing:

```bash
# Install pre-commit hooks (one-time)
make pre-commit-setup

# Run all linters
make lint

# Run unit tests
make test-unit
```

**Language-specific requirements:**

| Language | Tools | Must Pass |
|----------|-------|-----------|
| Python | `ruff` + `black` + `mypy` | ✅ |
| Bash | `shellcheck` + `shfmt` | ✅ |
| Terraform | `tflint` + `terraform fmt` | ✅ |
| YAML | `yamllint` | ✅ |
| Go | `golangci-lint` + `gofmt` | ✅ |
| Markdown | `markdownlint` | ✅ |

---

## Code of Conduct

By participating in this project, you agree to uphold our
[Code of Conduct](../docs/CODE_OF_CONDUCT.md).

---

## Getting Help

- Open an [issue](https://github.com/paruff/fawkes/issues) on GitHub
- Join [GitHub Discussions](https://github.com/paruff/fawkes/discussions)
- Review the [full documentation](https://paruff.github.io/fawkes/)
