# Development Workflow — Plan, Build, Review

This document defines the standard development workflow for Fawkes using **gemma4:e4b** (free tier) and GitOps best practices.

---

## Overview

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  PLAN   │───▶│  BUILD  │───▶│ REVIEW  │───▶│  MERGE  │───▶│ DEPLOY  │
│         │    │         │    │         │    │         │    │         │
│ Issue   │    │ Branch  │    │ PR +    │    │ Main    │    │ ArgoCD  │
│ + Spec  │    │ + Code  │    │ CI Gate │    │ Branch  │    │ Sync    │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
```

---

## Phase 1: PLAN

### Creating Issues

Every feature starts with a GitHub issue. Use this template:

```markdown
## Summary

One-sentence description of the change.

## Motivation

Why this change is needed. Link to DORA research if applicable.

## Scope

- **Layer**: services / infra / platform / scripts / docs
- **Files to edit**: [explicit list]
- **Reference file**: [path to canonical example, if applicable]

## Acceptance Criteria

- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Linters pass
- [ ] Tests added/updated

## Suggested Model: gemma4:e4b

**Task type**: single-file bug / multi-file refactor / docs / YAML
```

### Assigning to gemma4:e4b

gemma4:e4b is the **free default** model. Use it for ALL tasks unless a higher tier is explicitly justified (see `AGENTS.md` §10 Model Selection Policy).

| Task Type                    | Model      | Cost |
| ---------------------------- | ---------- | ---- |
| Python single-file bug fix   | gemma4:e4b | 0    |
| Python multi-file refactor   | gemma4:e4b | 0    |
| FastAPI unit tests           | gemma4:e4b | 0    |
| Fix NameError / import order | gemma4:e4b | 0    |
| Update .gitignore            | gemma4:e4b | 0    |
| Write Markdown docs          | gemma4:e4b | 0    |
| GitHub Actions YAML          | gemma4:e4b | 0    |
| Terraform single module      | gemma4:e4b | 0    |
| Helm / Kubernetes manifests  | gemma4:e4b | 0    |
| Bash script refactoring      | gemma4:e4b | 0    |

---

## Phase 2: BUILD

### Branch Strategy (GitOps)

```
main ─────────────────────────────────────────────────▶
  │
  ├── feat/add-health-endpoint ──────┐
  │                                  │
  ├── fix/resolve-timeout-bug ──────┐│
  │                                 ││
  ├── docs/update-api-surface ─────┐││
  │                                │││
  └── refactor/extract-logging ───┐│││
                                  ││││
                                  ▼▼▼▼
                              (PRs merge back)
```

**Rules:**

1. **Branch per feature** — every change gets its own branch
2. **Naming convention**: `<type>/<short-description>`
   - `feat/add-health-endpoint`
   - `fix/resolve-timeout-bug`
   - `docs/update-api-surface`
   - `refactor/extract-logging`
   - `test/add-unit-tests`
   - `chore/update-dependencies`
3. **Never commit directly to `main`** — all changes go through PRs
4. **Keep branches short-lived** — merge within 2 days (DORA best practice)

### Creating a Branch

```bash
# Fetch latest
git fetch origin

# Create feature branch from main
git checkout -b feat/add-health-endpoint origin/main

# Make changes, commit with conventional commits
git add .
git commit -m "feat(service): add /health endpoint to tracer-bullet"

# Push to remote
git push -u origin feat/add-health-endpoint
```

### Commit Message Format

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:** `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`

**Examples:**

```
feat(service): add /health endpoint to tracer-bullet
fix(ci): pin action versions to SHA hashes
docs: update DEVELOPMENT_WORKFLOW.md with GitOps branching
test(service): add unit tests for /health endpoint
```

### Working with gemma4:e4b in OpenCode

```bash
# Start OpenCode session
opencode

# In the chat, describe the task:
> Add a /health endpoint to services/tracer-bullet/app/main.py
> that returns {"status": "healthy", "service": "tracer-bullet"}
> Follow the existing pattern in the file.

# gemma4:e4b will:
# 1. Read the existing file
# 2. Generate the code
# 3. You review and accept

# After generation, run tests:
pytest tests/ -v

# Run linters:
ruff check services/
black --check services/
```

---

## Phase 3: REVIEW

### Pull Request Workflow

```bash
# Push your branch
git push -u origin feat/add-health-endpoint

# Create PR via GitHub CLI
gh pr create \
  --base main \
  --head feat/add-health-endpoint \
  --title "feat(service): add /health endpoint" \
  --body "## Summary
Adds /health endpoint to tracer-bullet service.

## Changes
- Added GET /health endpoint
- Returns service status JSON

## Testing
- [x] Unit tests added
- [x] Linters pass
- [x] Manual testing done

## AI-Assisted
This PR was generated using gemma4:e4b (free tier)."
```

### PR Requirements (from AGENTS.md §7)

Every PR must include:

```markdown
## AI-Assisted Review Block

- **What this PR does**: [one sentence]
- **Layer(s) touched**: services / infra / platform / scripts / docs
- **Tests added or updated**: [list]
- **Linters passing locally**: ✅ / ❌
- **Judgment calls flagged**: [any concerns]
- **`make lint` output**: ✅ / ❌
```

### CI Gates

Every PR must pass these checks:

| Check              | Description          | Blocker?                |
| ------------------ | -------------------- | ----------------------- |
| PR Size Gate       | < 400 lines changed  | Yes                     |
| Python Lint        | `ruff` + `black`     | Yes                     |
| Type Check         | `mypy`               | Yes                     |
| Unit Tests         | `pytest`             | Yes                     |
| Security Scan      | Trivy + Bandit       | Advisory                |
| Helm Lint          | `helm lint`          | Yes (if charts changed) |
| Terraform Validate | `terraform validate` | Yes (if infra changed)  |

### Review Checklist

- [ ] Code follows language conventions (see Language & Layer Map)
- [ ] No hardcoded secrets or credentials
- [ ] Resource limits on all container specs
- [ ] Labels include: `app`, `version`, `component`, `managed-by: fawkes`
- [ ] No `:latest` image tags
- [ ] Type hints on all function signatures
- [ ] Tests exist and are green
- [ ] PR < 400 lines (or `large-pr-approved` label)

---

## Phase 4: MERGE

### Merge Strategy

Use **Squash and Merge** for feature branches:

```
feat/add-health-endpoint (3 commits)
  ├── feat(service): add /health endpoint
  ├── test(service): add unit tests for /health
  └── fix(service): address review feedback
                    │
                    ▼
        main: feat(service): add /health endpoint (1 commit)
```

**Why squash?**

- Clean git history on `main`
- One commit per feature = easy revert
- DORA best practice: small, atomic commits

### Merge Requirements

1. All CI checks pass
2. At least 1 approval (2 for infra changes)
3. No merge conflicts
4. Branch is up-to-date with `main`

---

## Phase 5: DEPLOY

### GitOps Deployment Flow

```
main branch updated
       │
       ▼
  ArgoCD detects change
       │
       ▼
  ArgoCD syncs to cluster
       │
       ▼
  Application deployed
```

**No manual `kubectl apply`** — ArgoCD handles all deployments.

### Deployment Verification

```bash
# Check ArgoCD sync status
argocd app list

# Check pod status
kubectl get pods -n fawkes

# Check service health
curl http://tracer-bullet.fawkes.svc/health
```

---

## Quick Reference

### Day-to-Day Commands

```bash
# Start a new feature
git fetch origin && git checkout -b feat/my-feature origin/main

# Run tests locally
pytest tests/ -v

# Run linters
ruff check services/ && black --check services/

# Commit changes
git add . && git commit -m "feat(scope): description"

# Push and create PR
git push -u origin feat/my-feature
gh pr create

# After merge, clean up
git checkout main && git pull
git branch -d feat/my-feature
```

### gemma4:e4b Prompt Tips

```
# Good prompt (specific, with context):
> Read services/tracer-bullet/app/main.py
> Add a GET /info endpoint that returns the service version
> from the VERSION file. Follow the existing pattern.

# Bad prompt (vague, no context):
> Add an info endpoint
```

### Escalation Path

If gemma4:e4b fails the same task 3+ times:

1. Improve the prompt (add file paths, constraints, examples)
2. If still failing, check `AGENTS.md` §10 for model escalation
3. Document the rework in the issue

---

## See Also

- `AGENTS.md` — Language map, boundaries, PM contract
- `docs/golden-path-usage.md` — CI/CD pipeline usage
- `.github/copilot-instructions.md` — Copilot-specific standards
- `docs/BACKLOG.md` — Triaged backlog with value/effort scores
