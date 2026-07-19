# uFawkes CI Pipeline — Status

> **Session**: 2026-06-14 | **Status**: In Progress
> **Plan**: `fawkes/docs/ci-pipeline-master-plan.md` (comprehensive, 5-gate architecture)

---

## Current State

### PR #109 (uFawkesObs — Phase 2 Build & Security)

**Branch**: `ci/phase2-build-security` | **Status**: MERGED

**Files merged:**
| File | Status |
|------|--------|
| `reusable-preflight.yml` | ✅ Merged |
| `reusable-lint.yml` | ✅ Merged |
| `reusable-build.yml` | ✅ Merged |
| `reusable-security-scanning.yml` | ✅ Merged |
| `reusable-dependency-review.yml` | ✅ Merged |
| `reusable-tests.yml` | ✅ Merged |
| `ci-pipeline.yml` | ✅ Merged |
| `.pipeline.yml` | ✅ Merged (v2 schema) |
| `scripts/preflight.sh` | ✅ Merged |
| `.env.example` | ✅ Merged |
| `.markdownlint.json` | ✅ Merged |

### PR #110 (uFawkesObs — Fix main branch failures)

**Branch**: `fix/ci-main-failures` | **Status**: OPEN

**Issues fixed:**
| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Dependency Review: wrong input | `comment-summary` → `comment-summary-in-pr` | ✅ Fixed |
| Dependency Review: missing refs | No base/head refs on push events | ✅ Fixed |
| Security Scanning: Gitleaks v2 | Node.js 20 deprecated | ✅ Updated to v3 |
| Security Scanning: exit code 1 | False positives from test fixtures | ✅ Added warning handling |
| Trivy version | 0.35.0 outdated | ✅ Updated to 0.38.0 |

**Remaining issue (configuration, not code):**
| Issue | Root Cause | Action Required |
|-------|-----------|-----------------|
| Deploy: missing secrets | DEPLOY_KEY, DEPLOY_USER, DEPLOY_HOST not configured | Add in repo Settings → Secrets |

### Pipeline Coverage (current state)

| Stage               | uFawkesObs | uFawkes.dev | fawkes | uFawkesAI | uFawkesPipe | dora/sec/devx |
| ------------------- | ---------- | ----------- | ------ | --------- | ----------- | ------------- |
| 0: Preflight        | ✅         | ✅          | ✅     | ✅        | ⬜          | ⬜            |
| 1: Lint             | ✅         | ✅          | ✅     | ✅        | ⬜          | ⬜            |
| 1b: SAST            | ⬜         | ⬜          | ✅ NEW | ⬜        | —           | —             |
| 1c: SCA             | ✅         | ⬜          | ✅ NEW | ⬜        | ⬜          | ⬜            |
| 1d: Secrets         | ✅         | ⬜          | ✅ NEW | ⬜        | ⬜          | ⬜            |
| 2: Build            | ✅         | ✅          | ✅     | —         | ⬜          | —             |
| 2b: Policy          | —          | —           | ✅ NEW | —         | ⬜          | —             |
| 3: Tests            | ✅         | —           | ✅     | —         | ⬜          | —             |
| 4: Quality/A11y     | —          | ✅ NEW      | ✅ NEW | —         | —           | —             |
| 5: Deploy readiness | ⬜         | ⬜          | ⬜     | —         | ⬜          | —             |
| 6: Deploy           | ✅         | ✅          | ✅     | —         | ⬜          | —             |

---

## Execution Plan (Next Steps)

| Step | Action                                                          | Branch               | Depends on |
| ---- | --------------------------------------------------------------- | -------------------- | ---------- |
| 1    | Merge PR #110 (fix main failures)                               | fix/ci-main-failures | —          |
| 2    | Configure deploy secrets (DEPLOY_KEY, DEPLOY_USER, DEPLOY_HOST) | main (settings)      | Step 1     |
| 3    | Verify main pipeline passes                                     | main                 | Step 2     |
| 4    | Rollout pipeline to uFawkesPipe                                 | main                 | Step 3     |
| 5    | Rollout pipeline to uFawkesDevX                                 | main                 | Step 3     |
| 6    | Rollout pipeline to fawkes                                      | main                 | Step 3     |
| 7    | Rollout pipeline to remaining repos                             | main                 | Step 3     |

---

## Decisions (Locked)

| Question                 | Decision                                            | Rationale                                           |
| ------------------------ | --------------------------------------------------- | --------------------------------------------------- |
| Pipeline ordering        | Shift-left: all static analysis before build        | Catch issues as early as possible                   |
| Static analysis          | 5 parallel stages: lint, SAST, SCA, secrets, policy | Independent checks, run simultaneously              |
| SAST                     | CodeQL for Python/TS/Go repos only                  | Config-only repos skip SAST                         |
| Policy-as-code           | OPA/Rego via Conftest for K8s repos only            | Docker Compose repos skip policy                    |
| Workflow sharing         | Local copies                                        | Simple, no cross-repo dependency                    |
| Dependency blocking      | Block on critical + high                            | Strict security posture                             |
| SAST approach            | Both Trivy (SCA) + CodeQL (SAST)                    | Defense in depth                                    |
| Unit test coverage       | Diff: 80%, Total: 60% (ratchet)                     | New code tested, no regression                      |
| Acceptance test coverage | Diff: 70%, Total: 50% (ratchet)                     | Business logic verified                             |
| Load testing             | k6 with configurable thresholds                     | Performance regression prevention                   |
| Acceptance tests         | Required for all repos with runtime services        | Verify artifact meets business requirements         |
| SBOM generation          | Syft (SPDX + CycloneDX) per image                   | Supply chain transparency, regulatory compliance    |
| Container signing        | Cosign (keyless OIDC via Sigstore)                  | Tamper-proof artifacts, no key management           |
| Container scanning       | Trivy image scan post-build                         | Find CVEs in built images before deploy             |
| SLSA attestation         | SLSA Generator for provenance                       | Build metadata verification, supply chain integrity |
| Coverage strategy        | Dual thresholds: total + diff with ratchet          | Prevents regression AND ensures new code quality    |

---

## Files Saved

| File                 | Location                                      |
| -------------------- | --------------------------------------------- |
| Master plan          | `fawkes/docs/ci-pipeline-master-plan.md`      |
| Master plan (backup) | `uFawkes.dev/docs/ci-pipeline-master-plan.md` |
| Status (this file)   | `fawkes/docs/ci-pipeline-status.md`           |
| Status (backup)      | `uFawkes.dev/docs/ci-pipeline-status.md`      |
| Schema reference     | `uFawkes.dev/docs/pipeline-schema.md`         |
| Phase 1 PoC doc      | `uFawkes.dev/docs/ci-pipeline-phase1.md`      |

---

_Last updated: 2026-06-14_
