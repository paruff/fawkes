# PR Standards

## Conventional Commits

Every commit message must follow the Conventional Commits format:

```
type(scope): description
```

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`, `build`, `revert`.

Scope is the component or layer being changed (e.g. `infra`, `platform`, `services`, `docs`, `ci`). Keep the description under 72 characters, lowercase, no trailing period.

Examples:
- `feat(infra): add Azure Key Vault module`
- `fix(services): handle empty response in metrics endpoint`
- `ci(workflows): add job-start/job-finish timestamps`

## Branch Naming

All work happens on feature branches off `main` (trunk-based development, short-lived).

Format: `<type>/<slug>`

Examples: `feat/azure-key-vault`, `fix/metrics-empty-response`, `chore/update-deps`, `docs/architecture-overview`.

## PR Title

PR titles use the same Conventional Commits format and **must** match the first commit's message intent. The first word after `type(scope):` must be lowercase.

## CI Requirements

Every PR must pass the following CI gates before merge:

1. **Main CI Guard** — calls `paruff/ufawkespipe/.github/workflows/reusable-main-ci-guard.yml@v1.2` to validate the main CI workflow (`code-quality.yml`) succeeds
2. **Code Quality** — Python lint, TypeScript lint, Go lint, Shell lint, YAML lint, security scanning
3. **Pre-commit Validation** — base, language, tool, and platform pre-commit hooks
4. **PR Size Gate** — maximum 400 lines changed (override with `large-pr-approved` label)
5. **Accessibility Testing** — axe-core and Lighthouse CI for design-system changes
6. **Security & Terraform Validation** — Gitleaks, Trivy, TFLint, Terraform validate
7. **Terraform Tests** — validation and cost estimation (integration/E2E manual only)
8. **IDP E2E Tests** — smoke tests on kind cluster (full suite on schedule)

All CI checks must be green. A failing CI gate blocks merge. Use `emergency-bypass` label only for validated production incidents.

## PR Body Requirements

Every PR must include:

- **What this PR does** (one sentence)
- **Which layer(s) are touched** (services / infra / platform / scripts / docs / ci)
- **Tests added or updated**
- **Linters passing locally**
- **Any judgment calls flagged for human review**

## Size Limit

PRs exceeding 400 lines changed are blocked by `ci-pr-size.yml`. Override requires `large-pr-approved` label from a human with write access. Large PRs increase review risk and rollback complexity.
