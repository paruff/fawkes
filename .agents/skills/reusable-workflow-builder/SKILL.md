---
name: reusable-workflow-builder
description: Create or modify GitHub reusable workflows — input/output contracts, caller patterns, secrets propagation. Load when creating workflows/ or modifying reusable-*.yml files.
license: MIT
compatibility: opencode
---

# Reusable Workflow Builder — Fawkes

## File locations

- Reusable workflows: `.github/workflows/reusable-*.yml`
- Caller workflows: `.github/workflows/*.yml` (not prefixed `reusable-`)
- Composite actions: `.github/actions/*/action.yml`

## Reusable workflow template

```yaml
name: Reusable <Name>

"on":
  workflow_call:
    inputs:
      input-name:
        description: "Description"
        required: true
        type: string
    secrets:
      secret-name:
        required: true
    outputs:
      output-name:
        description: "Description"
        value: ${{ jobs.job-name.outputs.output-name }}

permissions:
  contents: read

jobs:
  job-name:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    outputs:
      output-name: ${{ steps.step-id.outputs.value }}
    steps:
      - uses: actions/checkout@SHA
      - id: step-id
        run: echo "value=..." >> "$GITHUB_OUTPUT"
      - if: always()
        run: echo "job-finish:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

## Caller template

```yaml
jobs:
  caller-job:
    uses: ./.github/workflows/reusable-<name>.yml
    with:
      input-name: "value"
    secrets:
      secret-name: ${{ secrets.SECRET_NAME }}
```

## Rules

1. **Never hardcode secrets** — pass via `secrets:` block
2. **Always `timeout-minutes`** on every job in reusable AND caller
3. **`permissions:` minimal** — both in reusable and caller
4. **DORA timestamps** in reusable workflow jobs too
5. **`outputs:` declared** at both job and workflow level
6. **`inputs:` typed** — use `string`, `boolean`, `number` — never untyped
7. **Caller must reference path** — `./.github/workflows/reusable-*.yml` (not `owner/repo/.github/...`)

## Common mistakes

- Reusable workflow declares `inputs` but caller uses `with:` — these must match exactly
- Missing `secrets: inherit` when caller passes all secrets
- Forgetting `if: always()` on DORA finish timestamp
- Step `id:` missing on output-producing steps

## Validate

```bash
# Check reusable workflow has correct trigger
grep -A5 "workflow_call:" .github/workflows/reusable-*.yml

# Check caller uses correct path
grep "uses: ./.github/workflows/reusable-" .github/workflows/*.yml

# Check all jobs have timeout
grep -B5 "runs-on:" .github/workflows/reusable-*.yml | grep -v "timeout-minutes"
```
