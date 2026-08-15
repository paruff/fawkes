# Dojo Spin-out Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development
> (recommended) or superpowers:executing-plans to implement this plan task-by-task.
> Use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract `docs/dojo/` out of the `fawkes` monorepo into a new standalone
public repo, `uFawkesDojo`, preserving git history, then update `fawkes` to link
out to it instead of hosting the content in-tree.

**Architecture:** One-time `git filter-repo` extraction preserves history into a
throwaway clone, which becomes the initial push to the new GitHub repo. `fawkes`
then gets three small, independently-mergeable PRs that remove the in-tree copy
and repoint every reference.

**Tech Stack:** git, git-filter-repo, gh CLI, mkdocs, markdownlint.

**Spec:** `docs/superpowers/specs/2026-08-15-dojo-spinout-design.md`

## Global Constraints

- New repo name: `uFawkesDojo`, visibility: public (spec §"Repo naming").
- Extraction must preserve commit history via `git filter-repo` (spec §"Extraction method").
- `fawkes` keeps no copy of dojo content in-tree after the move — no submodule, no sync job (spec §"Explicitly out of scope").
- Every Fawkes-side change ships as its own small PR (spec §"Fawkes-side changes").
- No mkdocs-deploy CI pipeline in the new repo — markdown-lint only (spec §"New repo bootstrap").

## ⚠️ Confirm-before-execute checkpoints

Two steps in this plan are hard to reverse and touch external/shared state:
creating the real `uFawkesDojo` GitHub repo (Task 1, Step 2) and force-pushing
the filtered history into it (Task 2, Step 4). The executor must pause and get
explicit user go-ahead immediately before each of those two steps, even under
autonomous execution.

---

### Task 1: Create the `uFawkesDojo` GitHub repo

**Files:** none (GitHub API / `gh` CLI only)

**Interfaces:**
- Produces: an empty public GitHub repo at `github.com/paruff/uFawkesDojo` that Task 2 pushes into.

- [ ] **Step 1: Verify the repo doesn't already exist**
  Run: `gh repo view paruff/uFawkesDojo`
  Expected: `GraphQL: Could not resolve to a Repository...` (404) — confirms no collision.
  If it already exists, STOP and report to the user instead of continuing.

- [ ] **Step 2: STOP — confirm with user before creating**
  Present: "About to run `gh repo create paruff/uFawkesDojo --public --description "Fawkes Dojo — belt-level platform engineering curriculum" -y` (no push yet). Proceed?"
  Wait for explicit yes.

- [ ] **Step 3: Create the repo**
  Run: `gh repo create paruff/uFawkesDojo --public --description "Fawkes Dojo — belt-level platform engineering curriculum" -y`
  Expected: prints the new repo URL `https://github.com/paruff/uFawkesDojo`.

- [ ] **Step 4: Verify it's empty and reachable**
  Run: `gh repo view paruff/uFawkesDojo --json isEmpty,visibility`
  Expected: `{"isEmpty":true,"visibility":"PUBLIC"}`

---

### Task 2: Extract `docs/dojo/` history with git filter-repo

**Files:**
- Create (local, throwaway): `/private/tmp/claude-501/-Users-philruff-projects-github-paruff-fawkes/*/scratchpad/uFawkesDojo-extract/` (a filtered clone of `fawkes`)

**Interfaces:**
- Consumes: the public repo URL from Task 1 Step 3.
- Produces: `uFawkesDojo`'s initial commit history, pushed to `main` on GitHub.

- [ ] **Step 1: Confirm git-filter-repo is installed**
  Run: `git filter-repo --version`
  Expected: prints a version string (e.g. `git-filter-repo 2.x.x`). If "command not found", run `brew install git-filter-repo` first.

- [ ] **Step 2: Clone fawkes into the scratchpad and filter to docs/dojo/**
  Run (from the scratchpad dir):
  ```bash
  git clone https://github.com/paruff/fawkes uFawkesDojo-extract
  cd uFawkesDojo-extract
  git filter-repo --path docs/dojo/ --path-rename docs/dojo/:
  ```
  Expected: filter-repo reports rewritten commit count; `ls` at repo root now shows the former `docs/dojo/` contents (e.g. `modules/`, `labs/`, `assessments/`, `index.html`) directly at top level, no `docs/dojo/` prefix.

- [ ] **Step 3: Verify the filtered history**
  Run: `git -C uFawkesDojo-extract log --oneline | wc -l` and `git -C uFawkesDojo-extract log --oneline -5`
  Expected: commit count > 0 (only commits that touched `docs/dojo/` survive); the 5 most recent are dojo-related commits from `fawkes` history.

- [ ] **Step 4: STOP — confirm with user before pushing**
  Present: "About to push the filtered history to `git@github.com:paruff/uFawkesDojo.git` main branch (irreversible — becomes the new repo's permanent history). Proceed?"
  Wait for explicit yes.

- [ ] **Step 5: Push to the new repo**
  Run:
  ```bash
  cd uFawkesDojo-extract
  git remote add origin https://github.com/paruff/uFawkesDojo.git
  git push -u origin HEAD:main
  ```
  Expected: push succeeds, no errors.

- [ ] **Step 6: Verify on GitHub**
  Run: `gh repo view paruff/uFawkesDojo --json isEmpty`
  Expected: `{"isEmpty":false}`

---

### Task 3: Bootstrap the new repo (README, LICENSE, catalog-info.yaml, CI)

**Files (all in the `uFawkesDojo-extract` clone from Task 2, then pushed):**
- Create: `uFawkesDojo-extract/README.md`
- Create: `uFawkesDojo-extract/LICENSE`
- Create: `uFawkesDojo-extract/catalog-info.yaml`
- Create: `uFawkesDojo-extract/.github/workflows/markdown-lint.yml`
- Modify: `uFawkesDojo-extract/labs/fawkes-cli.py:161` (hardcoded docs URL)

**Interfaces:**
- Consumes: pushed history from Task 2.
- Produces: a browsable, linted repo other `uFawkes*` repos and `fawkes` can link to.

- [ ] **Step 1: Write the README**
  Create `uFawkesDojo-extract/README.md`:
  ```markdown
  # uFawkesDojo

  [![Markdown Lint](https://github.com/paruff/uFawkesDojo/actions/workflows/markdown-lint.yml/badge.svg)](https://github.com/paruff/uFawkesDojo/actions/workflows/markdown-lint.yml)
  [![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

  **Learning Plane — Fawkes IDP Family.** uFawkesDojo is the belt-level,
  hands-on platform engineering curriculum extracted from
  [fawkes](https://github.com/paruff/fawkes). Progress through White → Yellow
  → Green → Brown → Black belt modules, each with labs and assessments.

  ## Belt Modules

  - [White Belt](modules/white-belt/module-01-what-is-idp.md) — IDP fundamentals, DORA metrics, GitOps principles, first deployment
  - [Yellow Belt](modules/yellow-belt/module-05-ci-fundamentals.md) — CI fundamentals, golden paths, security scanning, artifact management
  - [Green Belt](modules/green-belt/module-09-gitops-argocd.md) — GitOps/ArgoCD, deployment strategies, progressive delivery, rollback
  - [Brown Belt](modules/brown-belt/module-13-observability.md) — Observability, DORA deep-dive, SLIs/SLOs, incident management
  - [Black Belt](modules/black-belt/module-17-platform-product.md) — Platform-as-product, multi-tenancy, zero-trust security, multi-cloud

  ## Labs

  Hands-on lab automation lives in [`labs/`](labs/), driven by
  [`labs/fawkes-cli.py`](labs/fawkes-cli.py). See
  [`white-belt/module-01-what-is-idp/lab-01/instructions.md`](white-belt/module-01-what-is-idp/lab-01/instructions.md)
  for the first lab.

  ## Assessments

  Belt certification exams live in [`assessments/`](assessments/).

  ## Related repos

  Part of the [Fawkes IDP family](https://github.com/paruff/fawkes):
  [fawkes](https://github.com/paruff/fawkes) (core platform) ·
  [uFawkesPipe](https://github.com/paruff/uFawkesPipe) (CI/CD) ·
  [uFawkesObs](https://github.com/paruff/uFawkesObs) (observability) ·
  [uFawkes.dev](https://github.com/paruff/uFawkes.dev) (marketing site)
  ```

- [ ] **Step 2: Add the LICENSE**
  Copy the license text from `fawkes/LICENSE` verbatim (same org, same Apache 2.0 terms):
  Run: `cp /Users/philruff/projects/github/paruff/fawkes/LICENSE uFawkesDojo-extract/LICENSE`

- [ ] **Step 3: Add catalog-info.yaml**
  Create `uFawkesDojo-extract/catalog-info.yaml`:
  ```yaml
  apiVersion: backstage.io/v1alpha1
  kind: Component
  metadata:
    name: ufawkes-dojo
    description: Belt-level platform engineering curriculum for the Fawkes IDP family
    tags:
      - learning
      - dojo
      - fawkes
    links:
      - url: https://github.com/paruff/fawkes
        title: fawkes (core platform)
  spec:
    type: documentation
    lifecycle: production
    owner: paruff
  ```

- [ ] **Step 4: Add markdown-lint CI**
  Create `uFawkesDojo-extract/.github/workflows/markdown-lint.yml`:
  ```yaml
  name: Markdown Lint
  on:
    push:
      branches: [main]
    pull_request:

  jobs:
    markdownlint:
      runs-on: ubuntu-latest
      timeout-minutes: 5
      steps:
        - name: job-start
          run: echo "job-start workflow=markdown-lint job=markdownlint sha=${{ github.sha }} time=$(date -u +%FT%TZ)"
        - uses: actions/checkout@v4
        - uses: DavidAnson/markdownlint-cli2-action@v16
          with:
            globs: '**/*.md'
        - name: job-finish
          if: always()
          run: echo "job-finish workflow=markdown-lint job=markdownlint sha=${{ github.sha }} time=$(date -u +%FT%TZ)"
  ```

- [ ] **Step 5: Fix the hardcoded docs URL in fawkes-cli.py**
  In `uFawkesDojo-extract/labs/fawkes-cli.py` line 161, change:
  ```python
  click.echo(f"\n   Documentation: https://docs.fawkes.io/dojo/module-{module}")
  ```
  to:
  ```python
  click.echo(f"\n   Documentation: https://github.com/paruff/uFawkesDojo/blob/main/modules/module-{module}.md")
  ```

- [ ] **Step 6: Commit and push**
  Run:
  ```bash
  cd uFawkesDojo-extract
  git add README.md LICENSE catalog-info.yaml .github/workflows/markdown-lint.yml labs/fawkes-cli.py
  git commit -m "chore: bootstrap uFawkesDojo repo (README, LICENSE, catalog, CI)"
  git push
  ```
  Expected: push succeeds.

- [ ] **Step 7: Verify CI runs green**
  Run: `gh run list --repo paruff/uFawkesDojo --limit 1`
  Expected: the markdown-lint workflow run shows `completed success` (wait/poll if still `in_progress`).

---

### Task 4: Fawkes PR 1 — remove `docs/dojo/`, add pointer, fix nav

**Files:**
- Delete: `docs/dojo/Fawkes Dojo: Immersive Learning Architecture.md`
- Delete: `docs/dojo/index.html`
- Delete: `docs/dojo/onboarding.html`
- Delete: `docs/dojo/modules/` (entire tree)
- Delete: `docs/dojo/white-belt/` (entire tree)
- Delete: `docs/dojo/labs/` (entire tree)
- Delete: `docs/dojo/assessments/` (entire tree)
- Create: `docs/dojo/README.md`
- Modify: `mkdocs.yml:60-65`

**Interfaces:**
- Consumes: the live `uFawkesDojo` repo URL from Task 3.
- Produces: `fawkes` no longer hosts dojo content; `mkdocs.yml` nav points at the pointer page.

- [ ] **Step 1: Create a branch**
  Run: `git -C /Users/philruff/projects/github/paruff/fawkes checkout main && git -C /Users/philruff/projects/github/paruff/fawkes pull && git -C /Users/philruff/projects/github/paruff/fawkes checkout -b docs/1605-dojo-spinout-remove-in-tree`

- [ ] **Step 2: Delete the moved content, keep a pointer**
  Run (from `fawkes` repo root):
  ```bash
  git rm -r "docs/dojo/Fawkes Dojo: Immersive Learning Architecture.md" docs/dojo/index.html docs/dojo/onboarding.html docs/dojo/modules docs/dojo/white-belt docs/dojo/labs docs/dojo/assessments
  ```
  Expected: `git status` shows all dojo files staged as deleted, `docs/dojo/` directory still exists (empty) pending Step 3.

- [ ] **Step 3: Write the pointer page**
  Create `docs/dojo/README.md`:
  ```markdown
  # Fawkes Dojo

  The Dojo curriculum has moved to its own repo:
  **[github.com/paruff/uFawkesDojo](https://github.com/paruff/uFawkesDojo)**

  Belt modules, labs, and assessments all live there now, so the curriculum
  can be shared across the whole Fawkes/uFawkes stack family instead of
  living only inside this monorepo.
  ```

- [ ] **Step 4: Update mkdocs.yml nav**
  In `mkdocs.yml`, replace the current dojo nav block (around line 60):
  ```yaml
      - Dojo Learning:
        - White Belt: dojo/modules/white-belt/module-01-what-is-idp.md
        - Yellow Belt: dojo/modules/yellow-belt/module-05-ci-fundamentals.md
        - Green Belt: dojo/modules/green-belt/module-09-gitops-argocd.md
        - Brown Belt: dojo/modules/brown-belt/module-13-observability.md
        - Black Belt: dojo/modules/black-belt/module-17-platform-product.md
  ```
  with:
  ```yaml
      - Dojo Learning: dojo/README.md
  ```

- [ ] **Step 5: Verify mkdocs still builds**
  Run: `mkdocs build --strict` (from `fawkes` repo root)
  Expected: exits 0, no broken-link warnings about `dojo/modules/...` or `dojo/white-belt/...` paths.

- [ ] **Step 6: Commit**
  Run:
  ```bash
  git add -A docs/dojo mkdocs.yml
  git commit -m "docs: move dojo curriculum to uFawkesDojo repo

  Belt modules, labs, and assessments now live at
  github.com/paruff/uFawkesDojo so the curriculum can be shared across
  fawkes and the wider uFawkes stack family. docs/dojo/ keeps a pointer
  page; mkdocs.yml nav updated to match."
  ```

- [ ] **Step 7: Push and open PR**
  Run:
  ```bash
  git push -u origin docs/1605-dojo-spinout-remove-in-tree
  gh pr create --title "docs: move dojo curriculum to uFawkesDojo repo" --body "$(cat <<'EOF'
  ## Summary
  - Removes docs/dojo/ content (moved to github.com/paruff/uFawkesDojo, history preserved via git filter-repo)
  - Replaces with a pointer page at docs/dojo/README.md
  - Updates mkdocs.yml nav to reference the pointer page

  ## Test plan
  - [x] mkdocs build --strict passes with no broken dojo links
  - [ ] CI green on this PR

  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  EOF
  )"
  ```
  Expected: PR URL printed.

---

### Task 5: Fawkes PR 2 — update README.md and catalog-info.yaml references

**Files:**
- Modify: `README.md` (all `docs/dojo/...` in-repo links and prose reworded to point outward)
- Modify: `catalog-info.yaml:33`

**Interfaces:**
- Consumes: merged Task 4 (so `docs/dojo/...` paths no longer exist to link to).
- Produces: `README.md` and `catalog-info.yaml` link out to `uFawkesDojo` instead of in-repo paths.

- [ ] **Step 1: Create a branch**
  Run: `git checkout main && git pull && git checkout -b docs/1605-dojo-spinout-readme-links`

- [ ] **Step 2: Find every dojo reference to update**
  Run: `grep -n -i "dojo" README.md catalog-info.yaml`
  Expected: list of line numbers matching the grep output already captured during research (README.md lines ~10, 44, 84, 122, 168, 249, 253, 269, 277, 287, 333, 335, 354-361, 454, 478, 517, 627, 656; catalog-info.yaml line 33).

- [ ] **Step 3: Update in-repo path links**
  For every `README.md` link of the form `docs/dojo/<path>`, replace with the equivalent path on `https://github.com/paruff/uFawkesDojo/blob/main/<path-without-docs/dojo/-prefix>`. Concretely:
  - `docs/dojo/getting-started.md` → `https://github.com/paruff/uFawkesDojo`
  - `docs/dojo/white-belt/README.md` → `https://github.com/paruff/uFawkesDojo/tree/main/white-belt`
  - `docs/dojo/DOJO_ARCHITECTURE.md` → `https://github.com/paruff/uFawkesDojo/blob/main/Fawkes%20Dojo%3A%20Immersive%20Learning%20Architecture.md`
  - `docs/dojo/yellow-belt/`, `docs/dojo/green-belt/`, `docs/dojo/brown-belt/`, `docs/dojo/black-belt/` → `https://github.com/paruff/uFawkesDojo/tree/main/modules/<belt>-belt`
  - `docs/dojo/white-belt/` (enroll link) → `https://github.com/paruff/uFawkesDojo`
  Leave prose mentions of "Dojo" as a concept unchanged — only rewrite actual file-path links.

- [ ] **Step 4: Update catalog-info.yaml**
  Line 33 currently reads:
  ```yaml
      collaboration, observability, and security with integrated dojo learning.
  ```
  Change to:
  ```yaml
      collaboration, observability, and security. Dojo learning curriculum lives
      at github.com/paruff/uFawkesDojo.
  ```

- [ ] **Step 5: Verify no dangling docs/dojo path links remain**
  Run: `grep -n "docs/dojo/" README.md catalog-info.yaml`
  Expected: no output (empty).

- [ ] **Step 6: Commit**
  Run:
  ```bash
  git add README.md catalog-info.yaml
  git commit -m "docs: point README and catalog-info at uFawkesDojo repo"
  ```

- [ ] **Step 7: Push and open PR**
  Run:
  ```bash
  git push -u origin docs/1605-dojo-spinout-readme-links
  gh pr create --title "docs: point README and catalog-info at uFawkesDojo repo" --body "$(cat <<'EOF'
  ## Summary
  - Rewrites README.md dojo file-path links to point at github.com/paruff/uFawkesDojo
  - Updates catalog-info.yaml description to reference the external repo

  ## Test plan
  - [x] grep confirms no remaining docs/dojo/ path links
  - [ ] CI green on this PR

  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  EOF
  )"
  ```

---

### Task 6: Fawkes PR 3 — update ROADMAP.md Phase 2 status

**Files:**
- Modify: `ROADMAP.md:164-175` (Phase 2 section)
- Modify: `ROADMAP.md:203` (Phase 2 success metrics row)

**Interfaces:**
- Consumes: merged Task 4 and Task 5 (spin-out actually complete).
- Produces: `ROADMAP.md` accurately reflects that Phase 2's repo-split step is done.

- [ ] **Step 1: Create a branch**
  Run: `git checkout main && git pull && git checkout -b docs/1605-dojo-spinout-roadmap-status`

- [ ] **Step 2: Update the Phase 2 table**
  In `ROADMAP.md`, the row:
  ```markdown
  | **Repo location** | New repo `uFawkesDojo`                        | Separates learning from platform; enables community contribution; unbiased positioning |
  ```
  gets a trailing status note appended to the acceptance criteria line below it. Change:
  ```markdown
  **Acceptance criteria**: Dojo repo live, 3+ capability modules published, 100+ learners.
  ```
  to:
  ```markdown
  **Acceptance criteria**: Dojo repo live ✅ (github.com/paruff/uFawkesDojo, 20 modules migrated from fawkes), 3+ capability modules published, 100+ learners.
  ```

- [ ] **Step 3: Update the Phase 2 success metrics row**
  In the metrics table, change:
  ```markdown
  | **Phase 2** | Dojo modules         | 3+ capability-based modules published                                       | Not started |
  ```
  to:
  ```markdown
  | **Phase 2** | Dojo modules         | 3+ capability-based modules published                                       | Repo live, 20 modules migrated |
  ```

- [ ] **Step 4: Commit**
  Run:
  ```bash
  git add ROADMAP.md
  git commit -m "docs: mark dojo repo spin-out complete in ROADMAP"
  ```

- [ ] **Step 5: Push and open PR**
  Run:
  ```bash
  git push -u origin docs/1605-dojo-spinout-roadmap-status
  gh pr create --title "docs: mark dojo repo spin-out complete in ROADMAP" --body "$(cat <<'EOF'
  ## Summary
  - Updates ROADMAP.md Phase 2 status now that uFawkesDojo repo is live and content migrated

  ## Test plan
  - [x] Manual read-through of updated rows for accuracy

  🤖 Generated with [Claude Code](https://claude.com/claude-code)
  EOF
  )"
  ```

---

## Self-review notes

- **Spec coverage:** Extraction method (Task 2), new repo bootstrap incl. README/LICENSE/catalog/CI (Task 3), Fawkes PR 1/2/3 (Tasks 4-6), risk items — external links and hardcoded docs URL — both addressed (Task 3 Step 5 fixes the URL; Task 4 Step 3's pointer page is the redirect target for any stale external links).
  Repo *creation* itself (spec assumed it exists) is made explicit as Task 1 since the spec didn't cover who/how creates it.
- **Placeholder scan:** no TBD/TODO; every step has literal commands or file content.
- **Type/name consistency:** repo name `uFawkesDojo` used consistently; branch names carry the `1605` issue-number-style prefix consistently across Tasks 4-6 matching this repo's existing branch-naming convention (`security/1584-...` seen in git history).
