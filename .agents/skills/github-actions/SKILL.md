---
name: github-actions
description: GH Actions rules for Fawkes — pin SHA, timeout-minutes, path filtering. Load when editing workflows.
license: MIT
compatibility: opencode
---

# GitHub Actions — Fawkes

Rules:

1. Pin actions to SHA: `uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`
2. `timeout-minutes` on every job
3. `${{ secrets.NAME }}` only — never hardcoded secrets
4. Minimal `permissions` per job
5. `paths-ignore` for docs-only PRs

Template:

```yaml
jobs:
  job-name:
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    steps:
      - uses: actions/checkout@SHA
```

DORA timestamps:

```yaml
- run: echo "job-start:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
- if: always() run: echo "job-finish:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
```

Validate:

```bash
python -c "import yaml; yaml.safe_load(open('FILE'))"
grep "uses:" FILE | grep -v "@[a-f0-9]\{40\}"  # find unpinned
```
