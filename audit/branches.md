# Branch Audit — paruff/fawkes

**Date:** 2026-06-13
**Default branch:** `main`
**Total remote branches:** ~160
**Local branches:** 3 (`fix/gitops-template-compat`, `main`, `paruff-patch-1`)

---

## Active / Open PRs

| Branch | Last Commit | PR # | State | Ahead of main | Behind main |
|--------|------------|------|-------|---------------|-------------|
| `fix/gitops-template-compat` | 2026-06-13 | #1442 | OPEN | 14 | 0 |

---

## Recently Merged (branch still exists, PR merged)

| Branch | PR # | Merged | Behind main |
|--------|------|--------|-------------|
| `paruff-patch-1` | #1443 | 2026-06-12 | 1 |
| `dependabot/pip/extensions/ai/services/rag/pip-6f043a2b70` | #1441 | 2026-06-12 | 1 |
| `dependabot/pip/pip-2c6491f7af` | #1440 | 2026-06-12 | 1 |
| `copilot/audit-github-copilot-costs` | #1425 | 2026-06-03 | 41 |
| `copilot/add-concurrency-group-security-yml` | #1380 | 2026-05-09 | 41 |
| `copilot/fix-tflint-and-golangci-lint-versions` | #1379 | 2026-05-09 | 41 |
| `copilot/fix-broken-path-change-detection` | #1378 | 2026-05-09 | 41 |
| `copilot/pin-third-party-actions-shas` | #1377 | 2026-05-09 | 41 |
| `copilot/fix-pytest-vulnerable-tmpdir-handling` | #1360 | 2026-05-09 | 41 |
| `copilot/implement-terraform-state-best-practices` | #1345 | 2026-04-27 | 41 |
| `copilot/refactor-terraform-modules-again` | #1344 | 2026-04-27 | 41 |
| `copilot/refactor-terraform-modules` | #1277 | 2026-04-27 | 41 |
| `copilot/implement-argocd-local-dev-workflow` | #1279 | 2026-03-25 | 41 |
| `copilot/fix-urllib3-security-cve-issues` | #1275 | 2026-03-24 | 41 |
| `copilot/add-security-md-with-disclosure-policy` | #1274 | 2026-03-24 | 41 |
| `copilot/add-dora-five-metric-baseline` | #1276 | 2026-03-24 | 41 |
| `copilot/update-readme-value-proposition` | #1273 | 2026-03-23 | 41 |
| `copilot/add-codeowners-branch-protection-docs` | #1272 | 2026-03-23 | 41 |
| `copilot/rewrite-readme-quick-start` | #1271 | 2026-03-23 | 41 |
| `copilot/audit-stub-fill-mkdocs-nav` | #1270 | 2026-03-23 | 41 |
| `copilot/create-dojo-progress-tracking` | #1262 | 2026-03-23 | 41 |
| `copilot/upgrade-protobuf-to-5-29-6` | #1261 | 2026-03-21 | 41 |
| `copilot/upgrade-opentelemetry-sdk` | #1260 | 2026-03-21 | 41 |
| `copilot/upgrade-fastapi-to-0-116-0` | #1259 | 2026-03-21 | 41 |
| `copilot/audit-dependency-vulnerabilities` | #1252 | 2026-03-21 | 41 |

_(Plus ~125 more merged branches from 2025-11 through 2026-03 — all behind main by 62–1529 commits)_

---

## Closed Without Merge (PR closed, not merged)

| Branch | PR # | Last Commit | Behind main |
|--------|------|-------------|-------------|
| `copilot/at-e0-001-validate-code-quality-standards` | #1198 | 2026-03-12 | 152 |
| `copilot/at-e0-002-validate-script-refactoring` | #1216 | 2026-03-14 | 102 |
| `copilot/fix-prometheus-image-pull` | #1053 | 2026-01-07 | 523 |
| `copilot/fix-jenkins-service-access` | #12 | 2025-11-29 | 1488 |
| `copilot/implement-ingress-access` | #28 | 2025-11-30 | 1473 |
| `copilot/publish-fawkes-roadmap` | #72 | 2025-12-06 | 1355 |
| `copilot/resolve-pr-12-secret` | #14 | 2025-11-29 | 1486 |
| `copilot/sub-pr-569-another-one` | #1009 | 2025-12-25 | 917 |

---

## Orphan / Stale (no PR found)

| Branch | Last Commit | Behind main | Notes |
|--------|-------------|-------------|-------|
| `add/issue-forms` | 2025-12-06 | 1358 | No PR found |
| `develop` | 2025-05-02 | 1682 | Legacy; PRs #2–#7 merged to old `master` branch |
| `gh-pages` | 2026-06-12 | 2021 | Separate history; 170 ahead of main |

---

## Categorization

### Safe to Delete (merged PR, fully merged into main)
**~150 branches** — All branches listed in "Recently Merged" and the ~125 older merged branches. These have PRs that are merged/closed and the remote tracking branches were never cleaned up.

### Needs Review (stale >90 days, no PR)
- `add/issue-forms` — 1358 commits behind, no PR
- `develop` — 1682 commits behind, legacy branch

### Active
- `fix/gitops-template-compat` — PR #1442, OPEN, 14 ahead

### Special
- `gh-pages` — Separate history (GitHub Pages deployment), should NOT be deleted

---

## Recommended Actions

| Priority | Action | Branch Count |
|----------|--------|-------------|
| **HIGH** | Delete merged remote branches (batch `git push origin --delete`) | ~150 |
| **HIGH** | Delete closed-not-merged branches | 8 |
| **MEDIUM** | Review `add/issue-forms` — is this still needed? | 1 |
| **MEDIUM** | Review `develop` — is this still needed or can it be deleted? | 1 |
| **LOW** | Leave `gh-pages` as-is (GitHub Pages) | 0 |
| **NONE** | Leave `fix/gitops-template-compat` open (PR #1442) | 0 |
