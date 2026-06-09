---
name: workflow-security-audit
description: Audit GitHub Actions workflows for security issues — secret handling, permissions, injection risks, action pinning. Load before merging workflow changes.
license: MIT
compatibility: opencode
---

# Workflow Security Audit — Fawkes

## Security checklist

### 1. Secret handling
```bash
# Find hardcoded secrets (NEVER OK)
grep -rn "password\|token\|secret\|key" .github/workflows/*.yml | grep -v "secrets\."

# Find env-based secrets (OK if using secrets context)
grep -n "env:" .github/workflows/*.yml -A2 | grep -v "secrets\."
```

Rules:
- **Never** `env: SECRET: hardcode-value`
- **Always** `env: SECRET: ${{ secrets.SECRET_NAME }}`
- **Never** `echo ${{ secrets.X }}` in `run:` — use env binding instead:
  ```yaml
  env:
    SECRET: ${{ secrets.X }}
  run: echo "$SECRET"  # Safe — not interpolated by Actions
  ```

### 2. Permissions
```yaml
# Required — minimal permissions per job
permissions:
  contents: read

# For PR comments
permissions:
  contents: read
  pull-requests: write

# For issue creation
permissions:
  contents: read
  issues: write
```

Rules:
- Set `permissions:` at job level, not workflow level (when possible)
- Never `permissions: write-all` or `permissions: *`
- `contents: read` is the default for most jobs

### 3. Action pinning
```bash
# Find unpinned actions
grep "uses:" .github/workflows/*.yml | grep -v "@[a-f0-9]\{40\}"
```

Rules:
- Every `uses:` must pin to full SHA, not tag or branch
- Exception: first-party Actions (actions/checkout, actions/setup-python) can use `@v4` etc.
- Never `@main` or `@master`

### 4. Injection risks
```yaml
# DANGEROUS — user input in run:
run: echo "${{ github.event.pull_request.title }}"

# SAFE — bind to env first
env:
  TITLE: ${{ github.event.pull_request.title }}
run: echo "$TITLE"
```

Rules:
- Never interpolate `github.event.*` directly in `run:` scripts
- Always bind to `env:` first, then use shell variable
- Review `${{ }}` expressions in `run:` blocks

### 5. Code checkout safety
```yaml
# DANGEROUS — checkout untrusted code with write access
- uses: actions/checkout@SHA
  with:
    ref: ${{ github.event.pull_request.head.sha }}

# SAFER — read-only checkout for PRs
- uses: actions/checkout@SHA
  with:
    ref: ${{ github.event.pull_request.head.sha }}
    fetch-depth: 1
```

### 6. Reusable workflow secrets
```yaml
# Caller must explicitly pass secrets
jobs:
  reusable:
    uses: ./.github/workflows/reusable.yml
    secrets: inherit  # Pass all secrets

# Or explicitly
    secrets:
      MY_SECRET: ${{ secrets.MY_SECRET }}
```

Rules:
- Never hardcode secrets in reusable workflow
- Caller must propagate secrets via `secrets:` block
- `secrets: inherit` is acceptable for trusted reusable workflows

## Validate
```bash
# Full security audit
echo "=== Hardcoded secrets ==="
grep -rn "password\|token\|secret" .github/workflows/*.yml | grep -v "secrets\.\|description\|#"

echo "=== Unpinned actions ==="
grep "uses:" .github/workflows/*.yml | grep -v "@[a-f0-9]\{40\}" | grep -v "actions/"

echo "=== Missing permissions ==="
grep -B10 "runs-on:" .github/workflows/*.yml | grep -v "permissions:" | grep "runs-on:"

echo "=== Direct github.event interpolation ==="
grep -n "github\.event\." .github/workflows/*.yml | grep "run:"
```
