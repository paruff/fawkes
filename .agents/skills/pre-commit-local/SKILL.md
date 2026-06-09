---
name: pre-commit-local
description: Run targeted pre-commit checks locally before commit — detect staged files, run only relevant layer(s), prevent commit on failure. Load when about to commit or when user asks to validate changes.
license: MIT
compatibility: opencode
---

# Pre-commit Local Validation — Fawkes

## Layer mapping

| Layer | Make target | Hooks |
|---|---|---|
| Base | `make lint-base` | trailing-whitespace, end-of-file-fixer, check-yaml, check-json, check-added-large-files, check-merge-conflict, mixed-line-ending, detect-private-key, prettier, insert-license |
| Language | `make lint-lang` | black, ruff, flake8, shellcheck, shfmt, golangci-lint, markdownlint |
| Tool | `make lint-tool` | yamllint, terraform_fmt, terraform_validate, terraform_tflint, terraform_docs, terraform_tfsec |
| Platform | `make lint-platform` | kubeval, kustomize-validate, backstage-catalog-validate, argocd-validate, helm-lint, check-k8s-secrets, mkdocs-validate, gitleaks, detect-secrets |

## Workflow

### Step 1 — Detect staged files
```bash
git diff --cached --name-only
```

### Step 2 — Map files to layers

| File pattern | Layer(s) to run |
|---|---|
| `*.py` | Base + Language |
| `*.sh` | Base + Language |
| `*.go` | Base + Language |
| `*.md` | Base + Language |
| `*.yaml` / `*.yml` | Base + Tool + Platform |
| `*.tf` | Base + Tool |
| `infra/kubernetes/**` | Base + Platform |
| `platform/**` | Base + Platform |
| `services/**` | Base + Language |
| `scripts/**` | Base + Language |
| `tests/**` | Base + Language |
| `docs/**` | Base + Language |
| `.github/**` | Base + Tool |

### Step 3 — Run targeted layer(s)
```bash
# Always run base first (fast-fail)
make lint-base

# Then run relevant layers based on staged files
make lint-lang    # if *.py, *.sh, *.go, *.md staged
make lint-tool    # if *.yaml, *.yml, *.tf staged
make lint-platform # if infra/kubernetes/**, platform/** staged
```

### Step 4 — Auto-fix and re-stage
```bash
# If hooks fail, run auto-fix variants
pre-commit run trailing-whitespace --all-files
pre-commit run end-of-file-fixer --all-files
pre-commit run black --all-files
pre-commit run shfmt --all-files
pre-commit run prettier --all-files

# Re-stage auto-fixed files
git add -u
```

## Quick reference

```bash
# Run all hooks (full validation)
make lint

# Run specific layers
make lint-base
make lint-lang
make lint-tool
make lint-platform

# Run single hook
pre-commit run <hook-id> --all-files

# Run on staged files only (not --all-files)
pre-commit run
```

## CI parity
The CI workflow (`.github/workflows/pre-commit.yml`) runs the same 4 layers in parallel on separate runners. Running `make lint-base && make lint-lang && make lint-tool && make lint-platform` locally produces the same result as CI.

## Validate
```bash
# Verify all layers pass locally
make lint-base && make lint-lang && make lint-tool && make lint-platform
echo "All layers passed"
```
