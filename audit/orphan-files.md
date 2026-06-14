# Orphan File Audit — paruff/fawkes

**Date:** 2026-06-13
**Total tracked files:** 2,326
**Method:** Grep-based cross-reference search across all tracked files

---

## Tier 1: Confirmed Orphans (0 references anywhere in the repo)

### Scripts (8 files)

| File | Confidence | Notes |
|------|------------|-------|
| `scripts/brew-install.sh` | HIGH | Only referenced as text in other scripts, never sourced |
| `scripts/create_issues_script.sh` | HIGH | Zero references |
| `scripts/diagnostic-script.sh` | HIGH | Zero references |
| `scripts/project-board-setup-macos.sh` | HIGH | Makefile calls `project-board-setup.sh`, not this |
| `scripts/project-board-setup.sh` | HIGH | Zero references |
| `scripts/tools-install.sh` | HIGH | Zero references |
| `scripts/validate-at-e1-020-trivy.sh` | HIGH | No Makefile target, no CI reference |
| `scripts/validate-at-e1-022-quality-gates.sh` | HIGH | No Makefile target, no CI reference |

### Data / Backup Files (9 files)

| File | Confidence | Notes |
|------|------------|-------|
| `data/issues/epic0.json.backup.20251217_181027` | HIGH | Backup file |
| `data/issues/epic0_json(1).json` | HIGH | Duplicate/temp file |
| `data/issues/epic0_json.json` | HIGH | Duplicate/temp file |
| `data/issues/epic1-v2.json` | HIGH | Never referenced |
| `data/issues/epic3.5.json` | HIGH | Never referenced |
| `data/issues/epic3.json.backup.20251217_180343` | HIGH | Backup file |
| `data/issues/epic3.json.backup.20251217_180414` | HIGH | Backup file |
| `data/issues/epic3.json.backup.20251217_180423` | HIGH | Backup file |
| `data/issues/epic3.json.backup.20251217_180741` | HIGH | Backup file |

### Tests (4 files)

| File | Confidence | Notes |
|------|------------|-------|
| `tests/unit/test_example.py` | HIGH | Never referenced by any test runner |
| `tests/bdd/support/dora_matrics.py` | HIGH | Typo in name ("matrics"); never imported |
| `tests/bdd/support/jenkins_client.py` | HIGH | Never imported by any test |
| `tests/bdd/support/test_data.py` | HIGH | Never imported by any test |

### Infra (16 files)

| File | Confidence | Notes |
|------|------------|-------|
| `infra/set-env.bat` | HIGH | Zero references |
| `infra/how-to.md` | HIGH | Zero references |
| `infra/workspace/kitchen.example.local.yml` | HIGH | Zero references |
| `infra/workspace/tool-suite.txt` | HIGH | Zero references |
| `infra/workspace/test/integration/default/aws_spec.rb` | HIGH | Kitchen CI test, never wired up |
| `infra/workspace/test/integration/default/chef_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/docker_spec.rb.bad` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/git_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/java_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/k8s_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/make_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/maven_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/minikube_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/nodejs_spec.rb` | HIGH | Never wired up |
| `infra/workspace/test/integration/default/vagrant_spec.rb` | HIGH | Never wired up |
| `infra/kubernetes/namespace-policies.yaml` | HIGH | Zero references |

### Services (1 file)

| File | Confidence | Notes |
|------|------------|-------|
| `services/vsm/scripts/validate-config.py` | HIGH | Zero references |

### Reports / Scratch (3 files)

| File | Confidence | Notes |
|------|------------|-------|
| `reports/test-report.html` | HIGH | Zero references |
| `scratch/ping.txt` | HIGH | Zero references |
| `scratch/test_utils.py` | MEDIUM | Self-contained scratch file, no imports |

### Templates (1 directory)

| File | Confidence | Notes |
|------|------------|-------|
| `templates/defaults/` (entire directory, 4 files) | HIGH | Never referenced from any docs, CI, or code |

### Docs (18+ files — zero references)

| File | Confidence | Notes |
|------|------------|-------|
| `docs/CHANGELOG-github-actions.md` | HIGH | Never referenced |
| `docs/implementation-plan/issue-10-oauth-summary.md` | HIGH | Never referenced |
| `docs/testing/AT-E1-002-IMPLEMENTATION.md` | HIGH | Never referenced |
| `docs/validation/prometheus-stack-validation.md` | HIGH | Never referenced |
| `docs/validation/sonarqube-acceptance-validation.md` | HIGH | Never referenced |
| `docs/deployment/dora-metrics-service-checklist.md` | HIGH | Never referenced |
| `docs/deployment/jenkins-kubernetes-verification.md` | HIGH | Never referenced |
| `docs/deployment/webhook-configuration-summary.md` | HIGH | Never referenced |
| `docs/tutorials/EPIC-1-DEMO-README.md` | HIGH | Never referenced |
| `docs/dojo/Fawkes Dojo: Immersive Learning Architecture.md` | HIGH | Never referenced from module or index |
| `docs/dojo/assessments/green brown black exams.md` | HIGH | Never referenced |
| `docs/dojo/assessments/white assessment.md` | HIGH | Never referenced |
| `docs/dojo/labs/brown n black labs.md` | HIGH | Never referenced |
| `docs/dojo/labs/lab automation.md` | MEDIUM | Only references fawkes-cli.py (self-referencing pair) |
| `docs/dojo/labs/white.md` | HIGH | Never referenced |
| `docs/dojo/labs/yellow n green.md` | HIGH | Never referenced |
| `docs/dojo/labs/fawkes-cli.py` | MEDIUM | Only referenced by setup.py (self-referencing pair) |
| `docs/dojo/onboarding.html` | HIGH | Never referenced |

---

## Tier 2: Self-Referencing Only (1–2 refs, only from internal/orphan files)

| File | Refs | Analysis |
|------|------|----------|
| `scripts/aggregate-dora-timestamps.sh` | 1 | Only referenced by itself |
| `scripts/create-foundation7-issues.sh` | 1 | Only referenced by itself |
| `scripts/fix-epic3-tasks.sh` | 1 | Only referenced by itself |
| `scripts/validate-at-e0-002.sh` | 1 | Referenced by Makefile (legitimate) |
| `scripts/validate-issue-111.sh` | 1 | Only referenced in implementation notes |
| `scripts/validate-security-plane.sh` | 1 | Only referenced in implementation notes |
| `scripts/standardize-k8s-manifest.py` | 1 | Only referenced in implementation notes |
| `scripts/test-secrets-scanning-integration.sh` | 1 | Only referenced in implementation notes |
| `platform/apps/sonarqube/sonarqube-reinstall.sh` | 1 | Self-referencing only |
| `platform/apps/unleash/validate-unleash.sh` | 1 | Self-referencing only |
| `tests/unit/terraform_utils.py` | 1 | Only referenced by test_terraform_utils.py |
| `tests/unit/test_rag_indexing.py` | 1 | Only self-referenced |

---

## Tier 3: Low-Value (referenced only in other orphan docs)

~20 files in `docs/implementation-notes/` that are only referenced from other implementation notes or the README listing. These are auto-generated summaries that were never curated.

---

## Tier 4: Auto-Generated / Lock Files (tracked, potentially gitignoreable)

| Category | Count | Notes |
|----------|-------|-------|
| `.terraform.lock.hcl` | 42 | Platform/infra terraform lock files |
| `package-lock.json` | 1 | `design-system/package-lock.json` |
| `go.sum` | 3 | Required for Go module verification |
| `.gitkeep` placeholders | 18 | Empty directory markers |

---

## Summary Statistics

| Category | Confirmed Orphans (0 refs) | Self-Referencing | Low-Value |
|----------|---------------------------|------------------|-----------|
| `scripts/` | 8 | 5 | 3 |
| `data/issues/` | 9 | 0 | 0 |
| `tests/` | 4 | 1 | 0 |
| `infra/` | 16 | 0 | 0 |
| `services/` | 1 | 0 | 0 |
| `templates/` | 4 | 0 | 0 |
| `reports/` | 1 | 0 | 0 |
| `scratch/` | 2 | 1 | 0 |
| `docs/` | 18+ | 4 | 17+ |
| **Total** | **~65** | **~11** | **~20** |

---

## Recommended Actions

| Priority | Action | Files |
|----------|--------|-------|
| **HIGH** | Delete backup/duplicate data files in `data/issues/` | 9 |
| **HIGH** | Delete dead scripts in `scripts/` | 8 |
| **HIGH** | Delete Kitchen CI test specs in `infra/workspace/test/` | 11 |
| **HIGH** | Delete unused test files | 4 |
| **MEDIUM** | Delete orphan docs (zero references) | 18+ |
| **MEDIUM** | Review `templates/defaults/` — is this still needed? | 4 |
| **MEDIUM** | Review `services/vsm/scripts/validate-config.py` — dead code? | 1 |
| **LOW** | Consider gitignoring `.terraform.lock.hcl` files | 42 |
| **LOW** | Clean up `scratch/` directory | 3 |
