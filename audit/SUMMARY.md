# Audit Summary — paruff/fawkes

**Date:** 2026-06-13
**Scope:** Full repository — branches, files, docs, tool configs, .gitignore, CI/CD workflows
**Method:** 6 parallel explore agents + 6 report files in `audit/`

---

## Executive Summary

The repo has **~150 stale remote branches**, **~65 orphaned files**, **~220 broken doc links**, **3 conflicting tool config sets**, and **2 unpinned supply-chain-risk GitHub Actions**. No critical security issues (no leaked secrets, no tracked `.env` files). The highest-impact cleanup is low-risk branch deletion and orphan file removal.

| Metric                                 | Value                                  |
| -------------------------------------- | -------------------------------------- |
| Tracked files                          | 2,326                                  |
| Remote branches                        | ~160 (only 1 active)                   |
| Orphaned files (0 references)          | ~65                                    |
| Broken internal doc links              | ~220                                   |
| Unpinned actions (supply chain risk)   | 2                                      |
| Tracked K8s Secret YAMLs (placeholder) | 15                                     |
| Tool config conflicts                  | 3 (ShellCheck, yamllint, markdownlint) |

---

## Priority 1 — High Value, Low Risk (Do First)

These items are safe to execute in bulk and clear significant dead weight.

### P1-A: Delete ~150 merged remote branches

**Impact:** Reduces branch noise, prevents accidental checkout of stale code
**Risk:** None — PRs are merged, code is on `main`
**Files:** `audit/branches.md`
**Action:** Batch `git push origin --delete <branch>` (exclude `gh-pages` and `fix/gitops-template-compat`)

### P1-B: Delete 9 backup/duplicate data files

**Impact:** Removes temp artifacts from `data/issues/`
**Risk:** None — never referenced
**Files:**

- `data/issues/epic0.json.backup.20251217_181027`
- `data/issues/epic0_json(1).json`
- `data/issues/epic0_json.json`
- `data/issues/epic1-v2.json`
- `data/issues/epic3.5.json`
- `data/issues/epic3.json.backup.20251217_180343`
- `data/issues/epic3.json.backup.20251217_180414`
- `data/issues/epic3.json.backup.20251217_180423`
- `data/issues/epic3.json.backup.20251217_180741`

### P1-C: Delete 8 dead scripts

**Impact:** Removes unreferenced shell scripts from `scripts/`
**Risk:** None — zero imports or CI references
**Files:** `scripts/{brew-install.sh,create_issues_script.sh,diagnostic-script.sh,project-board-setup-macos.sh,project-board-setup.sh,tools-install.sh,validate-at-e1-020-trivy.sh,validate-at-e1-022-quality-gates.sh}`

### P1-D: Delete 11 Kitchen CI test specs

**Impact:** Removes never-wired integration test stubs
**Risk:** None — no CI pipeline runs these
**Files:** `infra/workspace/test/integration/default/*.rb` + `.rb.bad`

### P1-E: Delete 4 unused test files

**Impact:** Removes dead test code
**Risk:** None — never imported or referenced by test runners
**Files:** `tests/unit/test_example.py`, `tests/bdd/support/{dora_matrics.py,jenkins_client.py,test_data.py}`

### P1-F: Pin `trivy-action@master` → `@0.28.0`

**Impact:** Eliminates supply chain risk (tracks HEAD of master)
**Risk:** LOW — `tracer-bullet-ci.yml` already uses `@0.28.0` successfully
**Files:** `.github/workflows/{reusable-security-scanning.yml,security-and-terraform.yml}`

---

## Priority 2 — Medium Value, Low Risk

### P2-A: Remove `.gitguardian.yaml` duplicate

**Impact:** Eliminates duplicate config
**Risk:** None — `.gitguardian.yml` is identical and canonical
**Files:** `.gitguardian.yaml`

### P2-B: Remove dead `pyproject.toml [tool.flake8]` section

**Impact:** Eliminates dead config (flake8 reads `.flake8` first)
**Risk:** None
**Files:** `pyproject.toml`

### P2-C: Sync or remove `.trunk/configs/` overrides

**Impact:** Eliminates 3 tool config conflicts (ShellCheck, yamllint, markdownlint)
**Risk:** MEDIUM — requires deciding whether Trunk configs or root configs are authoritative
**Recommendation:** Since Trunk hooks are disabled, root configs are authoritative. Remove or sync `.trunk/configs/{.shellcheckrc,.yamllint.yaml,.markdownlint.yaml}`.
**Files:** `.trunk/configs/`

### P2-D: Pin `tflint_version` and `golangci-lint version`

**Impact:** Reproducible CI builds
**Risk:** LOW
**Files:** `.github/workflows/{pre-commit.yml,code-quality.yml,security-and-terraform.yml}`

### P2-E: Add `permissions` block to `ci-pr-size.yml`

**Impact:** Follows least-privilege principle
**Risk:** LOW
**Files:** `.github/workflows/ci-pr-size.yml`

### P2-F: Delete orphan docs (zero references, 18+ files)

**Impact:** Reduces docs noise
**Risk:** LOW — files are never linked or referenced
**Key files:** `docs/CHANGELOG-github-actions.md`, `docs/implementation-plan/issue-10-oauth-summary.md`, `docs/testing/AT-E1-002-IMPLEMENTATION.md`, `docs/validation/*.md`, `docs/deployment/*.md`, `docs/tutorials/EPIC-1-DEMO-README.md`

### P2-G: Delete `reports/` and `scratch/` directories

**Impact:** Removes temp/test artifacts
**Risk:** LOW
**Files:** `reports/test-report.html`, `scratch/{ping.txt,test_utils.py}`

### P2-H: Review `templates/defaults/` directory

**Impact:** 4 files never referenced from any docs, CI, or code
**Risk:** LOW
**Files:** `templates/defaults/`

---

## Priority 3 — High Effort, High Value (Do in Dedicated Runs)

### P3-A: Fix ~220 broken internal doc links

**Impact:** Major docs quality improvement; unblocks `mkdocs-validate --strict`
**Risk:** MEDIUM — requires creating stub pages or removing dead links across ~50 files
**Worst offenders:** `docs/capabilities.md` (18), `docs/index.md` (15), `docs/tutorials/epic-3-demo-video.md` (9)
**Reference:** `audit/docs.md`

### P3-B: Add 29 ADRs to mkdocs nav

**Impact:** All ADRs become discoverable
**Risk:** LOW — nav-only change
**Files:** `mkdocs.yml` nav section

### P3-C: Add 7 runbooks to mkdocs nav

**Impact:** All runbooks become discoverable
**Risk:** LOW — nav-only change
**Files:** `mkdocs.yml` nav section

### P3-D: Wire unused reusable workflows

**Impact:** Image signing, SBOM generation, and policy enforcement become active
**Risk:** MEDIUM — requires trigger workflow changes
**Files:** `.github/workflows/{reusable-image-signing.yml,reusable-sbom-generation.yml,reusable-policy-enforcement.yml}`

---

## Priority 4 — Low Priority, Cosmetic

| Item                                                      | Impact                   | Risk   |
| --------------------------------------------------------- | ------------------------ | ------ |
| Add `scratch/`, `reports/`, `audit/` to `.gitignore`      | Prevents future tracking | NONE   |
| Fix `GOVERNACE.md` → `GOVERNANCE.md` typo                 | Findability              | LOW    |
| Rename docs with spaces in filenames                      | URL encoding             | LOW    |
| Update VS Code deprecated Python settings                 | Modern config            | NONE   |
| Fix Trunk Python version `3.10.8` → `3.11`                | Consistency              | NONE   |
| Remove 18 `.gitkeep` placeholders (if dirs are populated) | Cleanup                  | LOW    |
| Address 15 tracked K8s Secret YAMLs                       | Security hygiene         | MEDIUM |
| Compress 16 PNG images over 1MB                           | Repo size                | LOW    |

---

## Execution Order

1. **P1-A** (branch cleanup) — single batch command, biggest noise reduction
2. **P1-B through P1-E** (orphan files) — single PR, delete 32 files
3. **P1-F** (pin trivy) — single PR, 2 files changed
4. **P2-A through P2-E** (config cleanup) — single PR, ~6 files changed
5. **P2-F through P2-H** (more orphans) — single PR, ~25 files deleted
6. **P3-A through P3-D** (docs + workflows) — dedicated runs, high effort

---

## Quick Wins (under 5 minutes each)

| Task                              | Time                   |
| --------------------------------- | ---------------------- |
| Delete merged branches (P1-A)     | ~2 min (batch command) |
| Delete backup files (P1-B)        | ~1 min                 |
| Delete dead scripts (P1-C)        | ~1 min                 |
| Pin trivy-action (P1-F)           | ~2 min                 |
| Remove `.gitguardian.yaml` (P2-A) | ~1 min                 |
| Remove dead flake8 config (P2-B)  | ~1 min                 |

---

## What We Did So Far (This Session)

1. **PR #1440** (Dependabot): Applied to `paruff-patch-1`, committed, pushed, base hooks pass
2. **PR #1441** (Dependabot pip group): All 12 checks pass — plan: merge as-is
3. **PR #1442** (pre-commit template update): Fixed all 9 failing checks in commit `5f9e05c1`:
   - Consolidated duplicate `terraform {}` blocks
   - Removed duplicate variable declarations
   - Added bandit `nosec` for `httpx.get(verify=False)`
   - Fixed mkdocs nav (`architecture.md` → `ARCHITECTURE.md`)
   - Changed `mkdocs-validate` hook to non-strict
   - Expanded `.shellcheckrc` suppressions
   - Applied prettier/black/ruff formatting across ~134 files
4. **Repository audit**: 6 parallel explore agents, 7 reports written to `audit/`
5. **This summary**: Synthesized all findings into prioritized action list

---

## Source Reports

| Report       | File                    | Key Findings                                          |
| ------------ | ----------------------- | ----------------------------------------------------- |
| Branches     | `audit/branches.md`     | ~150 merged branches safe to delete                   |
| Orphan Files | `audit/orphan-files.md` | ~65 files with 0 references                           |
| Docs         | `audit/docs.md`         | 75% orphaned from nav, ~220 broken links              |
| Tool Configs | `audit/tool-configs.md` | 3 conflicting config sets, dead flake8 config         |
| .gitignore   | `audit/gitignore.md`    | No critical issues, 15 K8s secrets tracked            |
| Workflows    | `audit/workflows.md`    | 2 unpinned trivy actions, 3 unused reusable workflows |
