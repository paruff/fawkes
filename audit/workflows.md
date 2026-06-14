# CI/CD & GitOps Workflow Audit — paruff/fawkes

**Date:** 2026-06-13
**Total workflow files:** 15 (11 trigger + 4 reusable)
**Composite actions:** 1 (`.github/actions/setup-python-env`)

---

## 1. Workflow Inventory

| # | File | Name | Triggers |
|---|------|------|----------|
| 1 | `accessibility-testing.yml` | Accessibility Testing | PR, push main, daily cron, manual |
| 2 | `build-mcp-k8s-server.yml` | Build MCP K8s Server Image | tag push `mcp-k8s-server-v*` |
| 3 | `ci-pr-size.yml` | PR Size Gate | PR (opened/sync/reopen/label) |
| 4 | `code-quality.yml` | Code Quality | PR, push main/develop, manual |
| 5 | `deploy.yml` | Deploy MkDocs to GitHub Pages | push main (docs paths), manual |
| 6 | `idp-e2e-tests.yml` | IDP E2E Tests | PR, 6-hour cron, manual |
| 7 | `pre-commit.yml` | Pre-commit Validation | PR, push main/develop, manual |
| 8 | `security-and-terraform.yml` | Security & Terraform Validation | push main, PR main |
| 9 | `security-plane-adoption.yml` | Security Plane - Complete Adoption | manual only |
| 10 | `terraform-tests.yml` | Terraform Terratest Suite | PR (infra paths), push main, manual |
| 11 | `tracer-bullet-ci.yml` | Tracer Bullet CI/CD | push/PR (tracer-bullet paths) |
| 12 | `reusable-image-signing.yml` | Reusable Image Signing | workflow_call |
| 13 | `reusable-policy-enforcement.yml` | Reusable Policy Enforcement | workflow_call |
| 14 | `reusable-sbom-generation.yml` | Reusable SBOM Generation | workflow_call |
| 15 | `reusable-security-scanning.yml` | Reusable Security Scanning | workflow_call |

---

## 2. Action Version Pinning Audit

### Properly Pinned (version tag)
All first-party actions (`actions/*`) use `@v4`–`@v8` version tags. Most third-party actions are version-tagged.

### CRITICAL: Floating / Unpinned Versions

| Workflow | Action | Version | Risk |
|----------|--------|---------|------|
| `reusable-security-scanning.yml` | `aquasecurity/trivy-action` | **`@master`** | **HIGH** — supply chain risk; tracks HEAD of master branch |
| `security-and-terraform.yml` | `aquasecurity/trivy-action` | **`@master`** | **HIGH** — same issue |
| `pre-commit.yml` | `tflint_version` | `latest` | MEDIUM — non-reproducible |
| `code-quality.yml` | `golangci-lint version` | `latest` | MEDIUM — non-reproducible |
| `security-and-terraform.yml` | `tflint_version` | `latest` | MEDIUM — non-reproducible |

**Note:** `tracer-bullet-ci.yml` correctly pins Trivy to `@0.28.0`.

---

## 3. Permissions Audit

### Workflow-Level Permissions

| Workflow | contents | pull-requests | packages | security-events | issues | checks | id-token |
|----------|----------|---------------|----------|-----------------|--------|--------|----------|
| accessibility-testing | read | write | — | — | write | write | — |
| build-mcp-k8s-server | read | — | write | — | — | — | — |
| ci-pr-size | **NONE** | — | — | — | — | — | — |
| code-quality | read | write | — | write | — | write | — |
| deploy | **write** | — | — | — | — | — | — |
| idp-e2e-tests | read | write | — | — | — | write | — |
| pre-commit | read | write | — | — | — | — | — |
| security-and-terraform | read | — | — | write | — | — | — |
| security-plane-adoption | read | — | write | write | — | — | write |
| terraform-tests | read | write | — | — | — | — | — |
| tracer-bullet-ci | **write** | — | write | — | — | — | — |

**Issues:**
- `ci-pr-size.yml` has NO permissions block — inherits repository defaults
- `deploy.yml` and `tracer-bullet-ci.yml` need `contents: write` (legitimate for gh-deploy and GitOps commits)

---

## 4. Secrets Usage

| Secret | Workflow | Purpose |
|--------|----------|---------|
| `LHCI_GITHUB_APP_TOKEN` | accessibility-testing | Lighthouse CI GitHub integration |
| `GITHUB_TOKEN` | build-mcp-k8s-server, tracer-bullet-ci, security-plane-adoption | GHCR login, GitOps commits |
| `INFRACOST_API_KEY` | terraform-tests | Cost estimation |
| `AZURE_CREDENTIALS` | terraform-tests | Azure Login (manual dispatch only) |
| `ARM_*` (4 secrets) | terraform-tests | Azure integration tests (manual only) |

**Security note:** Azure credentials are only used in manually-triggered jobs — not exposed on automatic PR/push triggers.

---

## 5. Caching Configuration

| Cache Type | Mechanism | Workflows |
|------------|-----------|-----------|
| pip | `actions/setup-python@v6` cache | deploy, idp-e2e, pre-commit, tracer-bullet |
| npm | `actions/setup-node@v6` cache | accessibility-testing, code-quality |
| Go modules | `actions/setup-go@v6` cache | code-quality, terraform-tests |
| Pre-commit envs | `actions/cache@v5` | pre-commit (4 jobs) |
| Terraform providers | `actions/cache@v5` | pre-commit, security-and-terraform |
| Docker layers | GHA cache | tracer-bullet-ci only |

**Not cached:** `build-mcp-k8s-server.yml` has no Docker layer caching.

---

## 6. Reusable Workflow Usage

| Reusable Workflow | Called By | Status |
|-------------------|-----------|--------|
| `reusable-security-scanning.yml` | `code-quality.yml` | ACTIVE |
| `reusable-image-signing.yml` | None | UNUSED |
| `reusable-policy-enforcement.yml` | None | UNUSED |
| `reusable-sbom-generation.yml` | None | UNUSED |

**Note:** Image signing (Cosign), SBOM generation (Syft), and policy enforcement (Conftest) are well-defined but never wired into trigger workflows.

---

## 7. DORA Compliance

All workflows (except `ci-pr-size.yml` and most of `security-plane-adoption.yml`) implement DORA logging with job start/finish timestamps, commit SHA, workflow name, and job name. The `if: always()` on finish steps ensures timestamps are logged even on failure.

---

## 8. GitOps Patterns

### Tracer Bullet CI/CD
Complete GitOps pipeline: lint → test → Docker build → Trivy scan → update K8s manifest → commit back to repo → ArgoCD auto-sync.

### ArgoCD Applications
48 ArgoCD Application manifests under `platform/apps/`. Key apps: backstage, prometheus, grafana, tempo, vault, kyverno, harbor, sonarqube, devlake, ingress-nginx, tracer-bullet, plus sample and analytics apps.

---

## 9. Gaps vs Standard CI/CD Practice

| Gap | Severity | Details |
|-----|----------|---------|
| No matrix testing | MEDIUM | All jobs run on `ubuntu-latest` only; no macOS/Windows |
| Trivy pinned to `@master` | HIGH | Supply chain risk in 2 workflows |
| `tflint`/`golangci-lint` at `latest` | MEDIUM | Non-reproducible builds |
| `npm audit` + `safety check` use `continue-on-error` | MEDIUM | Vulnerabilities silently ignored |
| Unused reusable workflows | LOW | Signing, SBOM, policy enforcement not wired |
| `ci-pr-size.yml` missing permissions block | LOW | Inherits repository defaults |
| `security-plane-adoption.yml` jobs are stubs | LOW | Placeholder implementations |
| No SBOM/signing in main CI pipelines | LOW | Tooling defined but not called |

---

## 10. Recommended Actions

| Priority | Action |
|----------|--------|
| **HIGH** | Pin `aquasecurity/trivy-action` to `@0.28.0` in `reusable-security-scanning.yml` and `security-and-terraform.yml` |
| **MEDIUM** | Pin `tflint_version` and `golangci-lint version` to specific versions |
| **MEDIUM** | Add `permissions` block to `ci-pr-size.yml` |
| **MEDIUM** | Wire `reusable-image-signing.yml` and `reusable-sbom-generation.yml` into build pipelines |
| **LOW** | Add Docker layer caching to `build-mcp-k8s-server.yml` |
| **LOW** | Consider matrix testing for cross-platform validation |
| **LOW** | Remove or implement `security-plane-adoption.yml` stub jobs |
