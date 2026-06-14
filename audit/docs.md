# Docs Audit — paruff/fawkes

**Date:** 2026-06-13
**Total markdown files in `docs/`:** 351
**Files in `mkdocs.yml` nav:** 88
**Orphaned from nav:** 263 (75%)

---

## 1. mkdocs.yml Nav Coverage

All 88 file paths referenced in the nav exist on disk — zero dangling nav entries.

### Files in Nav (88)
Covering: Home, Getting Started, Tutorials (6 + Dojo 5 belts), How-To Guides (15), Explanation (7), Reference (13), Extensions (2), Operations (7 sections), Maintainer Guide (6), Playbooks (4).

---

## 2. Orphaned Documentation (not in nav)

### ADR Files — 29 orphaned (only `adr/index.md` in nav)

| ADR | Title (from filename) |
|-----|----------------------|
| ADR-001 | Use FastAPI for Python microservices |
| ADR-002 | ArgoCD for GitOps delivery |
| ADR-003 | Backstage as IDP portal |
| ADR-004 | Kubernetes as container orchestration |
| ADR-005 | Prometheus + Grafana for monitoring |
| ADR-006 | Loki for log aggregation |
| ADR-007 | Tempo for distributed tracing |
| ADR-008 | Vault for secrets management |
| ADR-009 | Kyverno for policy enforcement |
| ADR-010 | Ingress Controller for Service Access |
| ADR-011 | Trivy for container scanning |
| ADR-012 | SonarQube for code quality |
| ADR-013 | Harbor for container registry |
| ADR-014 | Jenkins for CI/CD |
| ADR-015 | Tekton for CI/CD (deprecated) |
| ADR-016 | PostgreSQL for relational data |
| ADR-017 | OpenSearch for search/analytics |
| ADR-018 | Focalboard for project management |
| ADR-019 | Eclipse Che for cloud IDE |
| ADR-020 | DevLake for DORA metrics |
| ADR-021 | Canonical Data Model |
| ADR-025 | Event-driven architecture |
| ADR-026 | API Gateway pattern |
| ADR-027 | Service mesh (Istio) |
| ADR-029 | Multi-tenancy model |
| ADR-030 | Disaster recovery |
| ADR-031 | Blue-green deployments |
| ADR-032 | Feature flags |
| ADR-033 | Observability pipeline |

**Note:** ADR numbering has gaps: 022, 023, 024, 028 are missing. ADR-010 filename uses a colon character.

### Runbooks — 7 orphaned (only `runbooks/index.md` in nav)

- `at-e1-001-validation.md`
- `azure-aks-setup.md`
- `azure-aks-validation-checklist.md`
- `epic-1-architecture-diagrams.md`
- `epic-1-platform-operations.md`
- `epic-3-architecture-diagrams.md`
- `epic-3-product-discovery-operations.md`

### Implementation Notes — 58 orphaned (only `implementation-notes/README.md` in nav)

59 files total. These appear to be auto-generated issue summaries that were never curated into the nav.

### Other Orphaned Sections

| Section | Total Files | In Nav | Orphaned |
|---------|-------------|--------|----------|
| `how-to/` | ~28 | ~15 | ~13 |
| `research/` | ~40 | 3 (templates) | ~37 |
| `validation/` | 8 | 1 | 7 |
| `testing/` | 4 | 1 | 3 |
| `deployment/` | 7 | 1 | 6 |
| `security-plane/` | 5 | 1 | 4 |
| `dojo/` (labs, assessments) | ~20 | 5 | ~15 |
| `implementation-plan/` | 5 | 0 | 5 |
| Root-level docs | ~25 | 4 | ~21 |

---

## 3. Broken Internal Links (~220 total)

### Worst Offenders

| File | Broken Links |
|------|-------------|
| `docs/capabilities.md` | 18 |
| `docs/index.md` | 15 |
| `docs/tutorials/epic-3-demo-video.md` | 9 |
| `docs/implementation-notes/USABILITY_TESTING_IMPLEMENTATION.md` | 8 |
| `docs/tools/index.md` | 6 |
| `docs/patterns/index.md` | 6 |
| `docs/how-to/development/github-actions-workflows.md` | 5 |

### Common Broken Link Patterns

1. **Files never created:** `patterns/monitoring.md`, `patterns/security.md`, `patterns/chaos-engineering.md`, `patterns/continuous-integration.md`, `tools/grafana.md`, `tools/terraform.md`, `tools/kubernetes.md`, `tools/sonarqube.md`, `reference/roadmap.md`
2. **Wrong relative paths:** Many `docs/`-prefixed paths from within `docs/`
3. **Links to repo-root files:** `CONTRIBUTING.md` (does not exist)
4. **Links to `platform/apps/` directories:** References to READMEs that may differ from docs expectations

---

## 4. Repo-Root Markdown Files

| File | In Nav | Referenced in docs/ |
|------|--------|-------------------|
| `AGENTS.md` | No | No |
| `CHANGELOG.md` | No | Yes (a few) |
| `CODING_STANDARDS.md` | No | Yes (a few) |
| `README.md` | No | Yes (many) |
| `ROADMAP.md` | No | No |

---

## 5. Non-Markdown Files in docs/

34 non-markdown files including:
- 16 images (PNG) — some over 1MB
- 2 HTML files (dojo)
- 2 Python files (dojo labs)
- 5 YAML files (K8s manifests in dojo lab solutions)
- 1 shell script (dojo lab validation)
- 1 CSS file (extra styles)
- 10 `.gitkeep` placeholders

---

## 6. Issues Found

| # | Issue | Severity |
|---|-------|----------|
| 1 | 75% of docs are orphaned from nav (263/351 files) | HIGH |
| 2 | ~220 broken internal markdown links | HIGH |
| 3 | 29 ADRs not in nav (only index linked) | MEDIUM |
| 4 | 7 runbooks not in nav | MEDIUM |
| 5 | 58 implementation notes not in nav | LOW |
| 6 | 39 files with spaces in names (URL encoding issues) | LOW |
| 7 | Typo: `GOVERNACE.md` should be `GOVERNANCE.md` | LOW |
| 8 | `ROADMAP.md` orphaned at repo root | LOW |
| 9 | ADR numbering gaps (022-024, 028) | LOW |

---

## Recommended Actions

| Priority | Action |
|----------|--------|
| **HIGH** | Fix ~220 broken internal links |
| **HIGH** | Add ADR files to mkdocs nav under Reference > ADRs |
| **MEDIUM** | Add runbooks to nav under Operations > Runbooks |
| **MEDIUM** | Curate implementation notes or remove from docs tree |
| **LOW** | Fix filename typo `GOVERNACE.md` → `GOVERNANCE.md` |
| **LOW** | Rename files with spaces to use hyphens |
| **LOW** | Link `ROADMAP.md` from nav or docs |
