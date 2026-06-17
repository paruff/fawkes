# uFawkes CI Pipeline — Production-Ready Artifact Plan

> **Created**: 2026-06-14 | **Status**: Ready for execution
> **Goal**: Every pipeline completion produces a verified, production-ready artifact.
> **Source repos**: All 8 uFawkes repos audited.

---

## 1. Core Insight

The pipeline answer depends on **what the repo produces**. There is no universal pipeline. There are 5 repo types, each with different artifacts, different "production ready" criteria, and different stages.

```
"Production ready" = the pipeline VERIFIED the artifact works,
                    the artifact CAN be deployed, and
                    the artifact MEETS quality standards.
```

---

## 2. The 5 Repo Types

| Type          | Repos                                | Artifact                    | Deploy Method       |
| ------------- | ------------------------------------ | --------------------------- | ------------------- |
| **stack**     | uFawkesObs, uFawkesPipe, uFawkesDevX | Docker Compose stack        | SSH GitOps / manual |
| **core**      | fawkes                               | K8s platform (30+ services) | ArgoCD on AKS       |
| **site**      | uFawkes.dev                          | Static Jekyll site          | GitHub Pages        |
| **template**  | uFawkesAI                            | No artifact (config files)  | N/A                 |
| **bootstrap** | ufawkesdora, ufawkessec              | Placeholder (empty)         | N/A                 |

---

## 3. Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                    PRODUCTION-READY PIPELINE                          │
│                    (repo-type determines which stages run)            │
├──────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌─── GATE 0: Should this code exist at all? ────────────────────┐  │
│  │  Preflight: pre-commit, PR size, commit format, secrets        │  │
│  │  Source of truth: .pre-commit-config.yaml (local + CI)         │  │
│  └─────────────────────────────┬──────────────────────────────────┘  │
│                                │                                      │
│  ┌─── GATE 1: Is the code clean? (parallel static analysis) ────┐  │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐             │  │
│  │  │ Lint    │ │ SAST    │ │ SCA     │ │ Secrets │             │  │
│  │  │ (ruff,  │ │ (CodeQL)│ │ (Trivy  │ │ (Gitleaks│             │  │
│  │  │  black, │ │         │ │  FS,    │ │  + .env) │             │  │
│  │  │  shell) │ │         │ │  pip,   │ │         │             │  │
│  │  │         │ │         │ │  npm)   │ │         │             │  │
│  │  └────┬────┘ └────┬────┘ └────┬────┘ └────┬────┘             │  │
│  │       └───────────┴───────────┴───────────┘                   │  │
│  │       ALL 4 RUN IN PARALLEL — wall clock = max(all)           │  │
│  └─────────────────────────────┬──────────────────────────────────┘  │
│                                │                                      │
│  ┌─── GATE 2: Does it build? ───────────────────────────────────┐  │
│  │  Build: config validation + image build + artifact production │  │
│  │  Policy: OPA/Rego (K8s repos only)                            │  │
│  │  Supply chain: :latest check + SBOM + image signing + SLSA    │  │
│  │  Container scan: Trivy image scan (post-build)                │  │
│  └─────────────────────────────┬──────────────────────────────────┘  │
│                                │                                      │
│  ┌─── GATE 3: Does it work? ────────────────────────────────────┐  │
│  │  Tests: unit + integration + smoke                             │  │
│  │  Quality: a11y (sites), link-check (sites), config valid      │  │
│  └─────────────────────────────┬──────────────────────────────────┘  │
│                                │                                      │
│  ┌─── GATE 4: Can we deploy? ───────────────────────────────────┐  │
│  │  Deploy readiness: manifest validation, env check, rollback   │  │
│  └─────────────────────────────┬──────────────────────────────────┘  │
│                                │                                      │
│  ┌─── GATE 5: Did it deploy? ───────────────────────────────────┐  │
│  │  Deploy: actual deployment + health check + rollback plan     │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                                                       │
│  PIPELINE COMPLETE (all gates must pass)                              │
│                                                                       │
└──────────────────────────────────────────────────────────────────────┘
```

---

## 4. Per-Repo Stage Matrix

Which stages run for each repo type:

| Stage                        | stack                                | core                               | site           | template    | bootstrap |
| ---------------------------- | ------------------------------------ | ---------------------------------- | -------------- | ----------- | --------- |
| **GATE 0: Preflight**        | ✅                                   | ✅                                 | ✅             | ✅          | ✅        |
| **GATE 1: Lint**             | ✅                                   | ✅                                 | ✅             | ✅          | ✅        |
| **GATE 1: SAST**             | ⚠️ Python                            | ✅ Py+TS+Go                        | ⚠️ if JS       | ⚠️ if Shell | —         |
| **GATE 1: SCA**              | ✅                                   | ✅                                 | ✅             | ✅          | —         |
| **GATE 1: Secrets**          | ✅                                   | ✅                                 | ✅             | ✅          | ✅        |
| **GATE 2: Build**            | ✅ compose+Docker                    | ✅ Docker+Helm+TF                  | ✅ Jekyll      | —           | —         |
| **GATE 2: Policy**           | ⚠️ Dockerfiles                       | ✅ K8s+Docker                      | —              | —           | —         |
| **GATE 2: SBOM**             | ✅ SPDX+CycloneDX                    | ✅ SPDX+CycloneDX                  | ⚠️ sha256      | —           | —         |
| **GATE 2: Image signing**    | ✅ cosign                            | ✅ cosign                          | —              | —           | —         |
| **GATE 2: Container scan**   | ✅ Trivy image                       | ✅ Trivy image                     | —              | —           | —         |
| **GATE 2: SLSA attestation** | ✅                                   | ✅                                 | —              | —           | —         |
| **GATE 3: Tests**            | ✅ unit+integ+smoke+accept+load+perf | ✅ unit+integ+e2e+accept+load+perf | ✅ link+spell  | —           | —         |
| **GATE 3: Accessibility**    | —                                    | ✅ axe-core                        | ✅ pa11y+axe   | —           | —         |
| **GATE 4: Deploy readiness** | ✅ compose valid                     | ✅ Helm+ArgoCD                     | ✅ pages build | —           | —         |
| **GATE 5: Deploy**           | ✅ SSH GitOps                        | ✅ ArgoCD sync                     | ✅ GH Pages    | —           | —         |

**Legend**: ✅ = always runs | ⚠️ = conditional on repo contents | — = not applicable

---

## 5. Detailed Stage Specifications

### GATE 0: Preflight

**Purpose**: Fastest feedback. Should this code be allowed into the pipeline?

| Check            | Tool                                  | Timeout | Failure action                                    |
| ---------------- | ------------------------------------- | ------- | ------------------------------------------------- |
| Pre-commit hooks | `pre-commit run --all-files`          | 2min    | Block merge                                       |
| PR size          | `actions/github-script` (≤400 lines)  | 10s     | Block merge (override: `large-pr-approved` label) |
| Commit format    | Conventional Commits regex            | 10s     | Block merge                                       |
| Secret detection | `.env.example` placeholder validation | 10s     | Block merge                                       |
| Secret scanning  | Gitleaks                              | 30s     | Block merge                                       |

**Single source of truth**: `.pre-commit-config.yaml` — local pre-commit and CI preflight run the same hooks.

### GATE 1: Static Analysis (All Parallel)

**Purpose**: Is the code clean? Catch all issues before expensive build.

| Stage       | Tool                                                      | What it finds                          | Runs on                     |
| ----------- | --------------------------------------------------------- | -------------------------------------- | --------------------------- |
| **Lint**    | ruff, black, shellcheck, hadolint, markdownlint, prettier | Code quality, formatting, style        | Source code                 |
| **SAST**    | CodeQL (if Python/TS/Go present)                          | Security vulnerabilities in code logic | Source code                 |
| **SCA**     | Trivy FS + pip safety + npm audit                         | Known CVEs in dependencies             | lockfiles, requirements.txt |
| **Secrets** | Gitleaks + `.env.example` validation                      | Leaked credentials                     | All files                   |

**All 4 run in parallel** after lint passes. Wall clock = max(all 4) ≈ 30-60s.

**Key decision**: SAST only runs if repo has significant application code (Python, TS, Go). Config-only repos (YAML, Markdown) skip SAST — Trivy SCA already catches dependency CVEs.

### GATE 2: Build & Validate

**Purpose**: Produce the artifact and validate it.

**stack (uFawkesObs, uFawkesPipe, uFawkesDevX):**

| Check              | Tool                                           | What it validates                        |
| ------------------ | ---------------------------------------------- | ---------------------------------------- |
| Config validation  | `promtool check config`, `otel validate`, etc. | Configs parse and are valid              |
| Supply chain       | `grep -R "image: .*:latest"`                   | No `:latest` tags                        |
| Docker build       | `docker compose build`                         | Images build successfully                |
| Compose validation | `docker compose config`                        | Compose file is valid                    |
| SBOM               | Syft                                           | Generate SPDX + CycloneDX SBOM per image |
| Image signing      | Cosign (keyless OIDC)                          | Sign images with Sigstore                |
| Container scan     | Trivy image                                    | Find CVEs in built images                |
| SLSA attestation   | SLSA Generator                                 | Provenance attestation (build metadata)  |

**core (fawkes):**

| Check            | Tool                           | What it validates                           |
| ---------------- | ------------------------------ | ------------------------------------------- |
| Terraform        | `terraform validate`, `tflint` | Infra code is valid                         |
| Helm             | `helm lint`, `helm template`   | Charts render correctly                     |
| K8s manifests    | `kubeconform`                  | Manifests are valid K8s resources           |
| Docker build     | `docker build`                 | All images build                            |
| Policy           | OPA/Rego via Conftest          | K8s manifests comply with security policies |
| SBOM             | Syft                           | Generate SPDX + CycloneDX SBOM per image    |
| Image signing    | Cosign (keyless OIDC)          | Sign images with Sigstore                   |
| Container scan   | Trivy image                    | Find CVEs in built images                   |
| SLSA attestation | SLSA Generator                 | Provenance attestation (build metadata)     |

**site (uFawkes.dev):**

| Check           | Tool                           | What it validates                 |
| --------------- | ------------------------------ | --------------------------------- |
| Jekyll build    | `bundle exec jekyll build`     | Site builds without errors        |
| HTML validation | `htmlproofer`                  | No broken links, missing alt text |
| External links  | `htmlproofer --followlocation` | External URLs are reachable       |
| Artifact hash   | sha256sum                      | `_site/` integrity check          |

### GATE 3: Tests, Performance & Quality

**Purpose**: Does the built artifact work correctly, perform under load, and meet quality standards?

#### Test Tiers (in order of execution)

| Tier            | Purpose                                   | When it runs          | Failure action        |
| --------------- | ----------------------------------------- | --------------------- | --------------------- |
| **Unit**        | Individual functions work                 | After build           | Block merge           |
| **Integration** | Services communicate correctly            | After unit tests pass | Block merge           |
| **Smoke**       | Stack starts and is healthy               | After build           | Block merge           |
| **Acceptance**  | Artifact meets business requirements      | After integration     | Block merge           |
| **Load**        | Artifact performs under expected traffic  | After acceptance      | Block merge           |
| **Performance** | Artifact meets latency/throughput targets | After load            | Block merge (or warn) |

#### Per-Repo Test Specifications

**stack (uFawkesObs, uFawkesPipe, uFawkesDevX):**

| Tier        | What it tests                                                                    | Tool                         | Pass criteria                                                    |
| ----------- | -------------------------------------------------------------------------------- | ---------------------------- | ---------------------------------------------------------------- |
| Unit        | Python code logic                                                                | pytest                       | All tests pass                                                   |
| Smoke       | `docker compose up` → health checks                                              | docker compose + curl        | All containers healthy within 90s                                |
| Integration | Prometheus scraping, Grafana queries, OTel pipeline                              | pytest + HTTP                | All endpoints respond, metrics flow                              |
| Acceptance  | End-to-end observability flow: generate metrics → scrape → store → query → alert | pytest + telemetry-generator | Metrics appear in Prometheus, dashboards render, alerts fire     |
| Load        | High metric volume ingestion                                                     | k6 or custom script          | Prometheus handles 10k metrics/s, Grafana renders dashboards <2s |
| Performance | Query latency under load                                                         | k6 or custom script          | p95 query latency <500ms, memory <2GB                            |

**core (fawkes):**

| Tier        | What it tests                                          | Tool                      | Pass criteria                                          |
| ----------- | ------------------------------------------------------ | ------------------------- | ------------------------------------------------------ |
| Unit        | Python/TS/Go code logic                                | pytest, go test, npm test | All tests pass                                         |
| Integration | K8s services, Terraform provisioning                   | Terratest                 | Resources provision correctly                          |
| E2E         | Full platform workflow (clone → build → deploy → test) | BATS, Playwright          | End-to-end flow works                                  |
| Acceptance  | Platform meets CNCF maturity criteria                  | Custom scorecard          | Score ≥80% on maturity model                           |
| Load        | API gateway, K8s ingress under traffic                 | k6                        | p95 latency <500ms at 1000 RPS                         |
| Performance | Resource utilization, scaling behavior                 | k6 + kubectl metrics      | HPA scales correctly, pods stay within resource limits |

**site (uFawkes.dev):**

| Tier        | What it tests                                    | Tool          | Pass criteria                             |
| ----------- | ------------------------------------------------ | ------------- | ----------------------------------------- |
| Link check  | No broken internal/external links                | htmlproofer   | 0 broken links                            |
| Spell check | No spelling errors                               | typos         | 0 errors                                  |
| Acceptance  | All pages render, navigation works, forms submit | Playwright    | All pages accessible, all CTAs functional |
| Load        | Concurrent user simulation                       | k6            | p95 TTFB <1s at 100 concurrent users      |
| Performance | Core Web Vitals                                  | Lighthouse CI | LCP <2.5s, FID <100ms, CLS <0.1           |

#### Acceptance Test Pattern (uFawkesObs Example)

```python
# tests/acceptance/test_observability_flow.py
def test_metric_flows_from_app_to_prometheus():
    """Generate a metric, verify it appears in Prometheus."""
    # 1. Hit telemetry-generator endpoint
    requests.get("http://localhost:8080/metrics")
    # 2. Wait for scrape cycle (15s)
    time.sleep(20)
    # 3. Query Prometheus
    resp = requests.get("http://localhost:9090/api/v1/query",
        params={"query": "telemetry_generator_requests_total"})
    # 4. Assert metric exists and has correct labels
    assert resp.json()["data"]["result"][0]["metric"]["job"] == "telemetry-generator"

def test_grafana_dashboard_renders():
    """Verify Grafana dashboards load and show data."""
    resp = requests.get("http://localhost:3000/api/dashboards/uid/observability")
    assert resp.status_code == 200
    assert len(resp.json()["dashboard"]["panels"]) > 0
```

#### Load Test Pattern (k6 Example)

```javascript
// tests/load/metric_ingestion.js
import http from "k6/http";
import { check, sleep } from "k6";

export let options = {
  stages: [
    { duration: "30s", target: 50 }, // ramp up
    { duration: "1m", target: 50 }, // sustained load
    { duration: "30s", target: 0 }, // ramp down
  ],
  thresholds: {
    http_req_duration: ["p(95)<500"], // 95% of requests under 500ms
    http_req_failed: ["rate<0.01"], // <1% error rate
  },
};

export default function () {
  let res = http.get("http://localhost:9090/api/v1/query?up");
  check(res, { "status is 200": (r) => r.status === 200 });
  sleep(1);
}
```

#### Performance Thresholds

| Metric                  | Stack (Obs) | Core (fawkes)  | Site (uFawkes.dev) |
| ----------------------- | ----------- | -------------- | ------------------ |
| p95 latency (queries)   | <500ms      | <500ms         | —                  |
| p95 latency (page load) | —           | —              | <2s                |
| TTFB                    | —           | —              | <1s                |
| LCP                     | —           | —              | <2.5s              |
| CLS                     | —           | —              | <0.1               |
| Memory under load       | <2GB        | <4GB (per pod) | —                  |
| Error rate              | <1%         | <1%            | <0.1%              |
| Max concurrent users    | 100         | 1000           | 100                |
| Metric ingestion rate   | 10k/s       | —              | —                  |

#### Coverage Thresholds

| Tier                  | Total Coverage        | Diff Coverage  | Enforcement                   | Tool                           |
| --------------------- | --------------------- | -------------- | ----------------------------- | ------------------------------ |
| **Unit tests**        | 60% (baseline)        | 80% (new code) | Block merge if diff below 80% | pytest-cov, istanbul, go cover |
| **Acceptance tests**  | 50% (baseline)        | 70% (new code) | Block merge if diff below 70% | Custom coverage tracking       |
| **Integration tests** | 50% (baseline)        | 70% (new code) | Warn if below                 | pytest-cov                     |
| **Load tests**        | N/A (threshold-based) | N/A            | Block if thresholds exceeded  | k6                             |
| **Performance tests** | N/A (threshold-based) | N/A            | Block if thresholds exceeded  | k6, Lighthouse CI              |

**Coverage strategy — intelligent thresholds:**

- **Total coverage**: Minimum across entire codebase. Prevents regression on existing code.
- **Diff coverage**: Coverage of lines changed in this PR. Ensures new code is tested.
- **Why both**: Total coverage alone lets legacy code rot. Diff coverage alone lets you merge risky changes to untested code. Both together catch regressions AND ensure new code quality.
- **Baseline enforcement**: Total coverage cannot decrease. If current is 65%, merging a PR that drops it to 58% is blocked.
- **Ratchet effect**: Coverage only goes up over time. Each PR must maintain or improve both metrics.

**Enforcement logic:**

```
PASS if:
  diff_coverage >= threshold  (new code is tested)
  AND total_coverage >= current_total  (no regression)
FAIL if:
  diff_coverage < threshold  (new code untested)
  OR total_coverage < current_total  (regression introduced)
```

### GATE 4: Deploy Readiness

**Purpose**: Can this artifact be deployed safely?

| Check                | Applies to  | What it verifies                      |
| -------------------- | ----------- | ------------------------------------- |
| Compose config valid | stack       | `docker compose config` passes        |
| Helm template valid  | core        | `helm template` renders without error |
| ArgoCD app valid     | core        | Application manifest is valid         |
| GitHub Pages build   | site        | `jekyll build` produces `_site/`      |
| Rollback plan exists | stack, core | Previous version tag exists           |

### GATE 5: Deploy

**Purpose**: Actually deploy the artifact and verify it's running.

| Deploy method       | Trigger      | Health check                | Rollback                 |
| ------------------- | ------------ | --------------------------- | ------------------------ |
| SSH GitOps (stack)  | Push to main | `curl` health endpoints     | `git revert` + `make up` |
| ArgoCD (core)       | Push to main | ArgoCD sync status + health | ArgoCD rollback          |
| GitHub Pages (site) | Push to main | `curl` site URL             | Revert commit            |

---

## 6. `.pipeline.yml` Schema v2 (Final)

```yaml
version: "2"
repo-type: stack | core | site | template | bootstrap

# What this repo produces
artifact:
  type: docker-compose | kubernetes | static-site | template | none
  deploy-method: ssh-gitops | argocd | github-pages | manual | none

# Emergency bypass
emergency:
  label: emergency-bypass
  allow-override: true

# Stages (each repo enables what applies)
stages:
  preflight:
    enabled: true
    pr-size-limit: 400
    commit-format: conventional
    secret-detection: true

  lint:
    enabled: true
    languages: auto-detect

  # Static analysis (all parallel, all before build)
  sast:
    enabled: false # Enable if repo has Python/TS/Go
    languages: [python]
    tool: codeql
    fail-on: high

  sca:
    enabled: true
    tools: [trivy-fs, pip-safety, npm-audit]
    fail-on: critical

  secrets:
    enabled: true
    tools: [gitleaks, env-example]

  # Build (after all static checks)
  build:
    enabled: true
    docker: true # Build Docker images
    config-validation: true # Validate configs
    supply-chain:
      :latest-check: true # No :latest tags
      sbom: true # Generate SPDX + CycloneDX SBOM
      signing: true # Sign images with cosign (keyless OIDC)
      slsa: true # Generate SLSA provenance attestation
      container-scan: true # Scan built images with Trivy

  # Policy (K8s repos only)
  policy:
    enabled: false # Enable for K8s repos
    tool: conftest
    policy-path: .security-plane/policies

  # Tests (after build)
  tests:
    enabled: true
    tiers: [unit, integration, smoke, acceptance, load, performance]
    coverage-thresholds:
      unit:
        total: 60 # Minimum total unit test coverage %
        diff: 80 # Minimum diff coverage for new code %
      acceptance:
        total: 50 # Minimum total acceptance test coverage %
        diff: 70 # Minimum diff coverage for new code %
    acceptance:
      enabled: true
      timeout: 10
    load:
      enabled: false # Enable for repos with runtime services
      tool: k6
      stages: [ramp-up, sustained, ramp-down]
      max-vusers: 50
      duration: 90s
    performance:
      enabled: false # Enable for repos with performance targets
      tool: k6
      thresholds:
        p95-latency: 500 # ms
        error-rate: 1 # percent
        memory: 2048 # MB
    timeout: 30 # Total timeout in minutes

  # Quality (after build)
  quality:
    accessibility: false # Enable for sites
    link-check: false # Enable for sites
    lighthouse: false

  # Deploy readiness (after tests)
  deploy-readiness:
    enabled: true

  # Deploy (final gate)
  deploy:
    enabled: true
    strategy: ssh-gitops # gitops | argocd | github-pages | manual
    manual-approval: false

# Gates
gates:
  require-all-stage-pass: true
  emergency-bypass: true
  bypass-label: emergency-bypass
```

---

## 7. Per-Repo `.pipeline.yml` Examples

### uFawkesObs (stack)

```yaml
version: "2"
repo-type: stack
artifact:
  type: docker-compose
  deploy-method: ssh-gitops

stages:
  preflight: { enabled: true }
  lint: { enabled: true, languages: [python, shell, yaml, markdown] }
  sast: { enabled: true, languages: [python], tool: codeql }
  sca: { enabled: true }
  secrets: { enabled: true }
  build:
    enabled: true
    docker: true
    config-validation: true
    supply-chain:
      :latest-check: true
      sbom: true
      signing: true
      slsa: true
      container-scan: true
  policy: { enabled: false }
  tests:
    enabled: true
    tiers: [unit, compose-smoke, integration, acceptance, load, performance]
    coverage-thresholds:
      unit: { total: 60, diff: 80 }
      acceptance: { total: 50, diff: 70 }
    acceptance: { enabled: true, timeout: 10 }
    load: { enabled: true, tool: k6, max-vusers: 50, duration: 90s }
    performance: { enabled: true, thresholds: { p95-latency: 500, error-rate: 1, memory: 2048 } }
  quality: { enabled: false }
  deploy-readiness: { enabled: true }
  deploy: { enabled: true, strategy: ssh-gitops }
```

### fawkes (core)

```yaml
version: "2"
repo-type: core
artifact:
  type: kubernetes
  deploy-method: argocd

stages:
  preflight: { enabled: true }
  lint: { enabled: true, languages: [python, typescript, go, shell, yaml, terraform] }
  sast: { enabled: true, languages: [python, typescript, go], tool: codeql }
  sca: { enabled: true }
  secrets: { enabled: true }
  build:
    enabled: true
    docker: true
    helm: true
    terraform: true
    supply-chain:
      :latest-check: true
      sbom: true
      signing: true
      slsa: true
      container-scan: true
  policy: { enabled: true, tool: conftest, policy-path: .security-plane/policies }
  tests:
    enabled: true
    tiers: [unit, integration, e2e, terratest, acceptance, load, performance]
    coverage-thresholds:
      unit: { total: 60, diff: 80 }
      acceptance: { total: 50, diff: 70 }
    acceptance: { enabled: true, timeout: 15 }
    load: { enabled: true, tool: k6, max-vusers: 1000, duration: 120s }
    performance: { enabled: true, thresholds: { p95-latency: 500, error-rate: 1, memory: 4096 } }
  quality: { enabled: true, accessibility: true, link-check: true }
  deploy-readiness: { enabled: true }
  deploy: { enabled: true, strategy: argocd }
```

### uFawkes.dev (site)

```yaml
version: "2"
repo-type: site
artifact:
  type: static-site
  deploy-method: github-pages

stages:
  preflight: { enabled: true }
  lint: { enabled: true, languages: [markdown, css, javascript] }
  sast: { enabled: false }
  sca: { enabled: true }
  secrets: { enabled: true }
  build: { enabled: true, jekyll: true, link-check: true }
  policy: { enabled: false }
  tests: { enabled: false }
  quality: { enabled: true, accessibility: true, link-check: true }
  deploy-readiness: { enabled: true }
  deploy: { enabled: true, strategy: github-pages }
```

### uFawkesAI (template)

```yaml
version: "2"
repo-type: template
artifact:
  type: template
  deploy-method: none

stages:
  preflight: { enabled: true }
  lint: { enabled: true, languages: [shell, yaml, markdown] }
  sast: { enabled: false }
  sca: { enabled: true }
  secrets: { enabled: true }
  build: { enabled: false }
  policy: { enabled: false }
  tests: { enabled: false }
  quality: { enabled: false }
  deploy-readiness: { enabled: false }
  deploy: { enabled: false }
```

---

## 8. Execution Plan

| Step | Phase            | Action                                                                    | Repo        | Creates/Modifies        |
| ---- | ---------------- | ------------------------------------------------------------------------- | ----------- | ----------------------- |
| 1    | Foundation       | Reorder `ci-pipeline.yml`: security before build                          | uFawkesObs  | `ci-pipeline.yml`       |
| 2    | Foundation       | Create focused static stages (`reusable-sca.yml`, `reusable-secrets.yml`) | uFawkesObs  | New workflow files      |
| 3    | SAST             | Add `reusable-sast.yml` (CodeQL)                                          | uFawkesObs  | New workflow file       |
| 4    | Tests            | Add `reusable-tests.yml` (configurable tiers)                             | uFawkesObs  | New workflow file       |
| 5    | Deploy readiness | Add `reusable-deploy-readiness.yml`                                       | uFawkesObs  | New workflow file       |
| 6    | Schema           | Update `.pipeline.yml` to v2 with artifact metadata                       | uFawkesObs  | `.pipeline.yml`         |
| 7    | Documentation    | Update `ci-pipeline-status.md` with full architecture                     | fawkes/docs | `ci-pipeline-status.md` |
| 8    | Rollout          | Copy reusables + create `ci-pipeline.yml` for each repo                   | All 8       | Per-repo files          |

**Steps 1-6 are on branch `ci/phase2-build-security` (PR #109).**
**Steps 7-8 are follow-up PRs.**

---

## 9. What "Production Ready" Means (Per Repo)

| Repo              | Production Ready =                                                                                                                                                                                                     |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **uFawkesObs**    | Pipeline verified: `docker compose up` → all 8 containers healthy → Prometheus scraping → Grafana dashboards loading → alerts firing. Supply chain: images signed, SBOM generated, SLSA attestation, no critical CVEs. |
| **uFawkesPipe**   | Pipeline verified: `docker compose up` → Jenkins + SonarQube + OWASP running → pipeline templates work. Supply chain: images signed, SBOM generated, SLSA attestation, no critical CVEs.                               |
| **fawkes**        | Pipeline verified: ArgoCD sync → all 30+ pods running → Terraform state clean → Helm charts deployed. Supply chain: images signed, SBOM generated, SLSA attestation, no critical CVEs, policy compliant.               |
| **uFawkes.dev**   | Pipeline verified: `jekyll build` → `_site/` → GitHub Pages serves → all links work → WCAG 2.1 AA. Artifact: `_site/` hash verified.                                                                                   |
| **uFawkesAI**     | Pipeline verified: Template files valid → pre-commit passes → documentation correct.                                                                                                                                   |
| **dora/sec/devx** | Pipeline verified: Pre-commit passes → ready for content.                                                                                                                                                              |

---

## 10. Pre-commit ↔ Pre-flight Relationship

```
Developer's machine (local)              GitHub Actions (CI)
─────────────────────────                ──────────────────────
git commit                               PR opened
  │                                        │
  ▼                                        ▼
pre-commit hooks                         preflight stage
  ├── trailing-whitespace                  ├── pre-commit run --all-files
  ├── end-of-file-fixer                   ├── PR size gate (≤400 lines)
  ├── check-yaml                          ├── Commit format (conventional)
  ├── check-json                          ├── Secret detection (.env.example)
  ├── yamllint                            └── Gitleaks
  ├── markdownlint
  ├── prettier
  ├── gitleaks
  └── detect-secrets
```

| Aspect                   | Pre-commit (local)        | Pre-flight (CI)                                        |
| ------------------------ | ------------------------- | ------------------------------------------------------ |
| **When**                 | Before commit             | On PR / push                                           |
| **Where**                | Developer's machine       | GitHub runner                                          |
| **Config**               | `.pre-commit-config.yaml` | Same file — `pre-commit run --all-files`               |
| **Purpose**              | Fast local feedback       | Safety net + checks that need CI context               |
| **Optional?**            | Developer must install    | Runs automatically                                     |
| **Extra CI-only checks** | N/A                       | PR size gate, commit format, `.env.example` validation |

**Key principle**: `.pre-commit-config.yaml` is the **single source of truth**. The CI preflight stage runs the exact same hooks via `pre-commit run --all-files`. No duplication, no drift.

---

_Last updated: 2026-06-14_
_Review schedule: After each phase completion_
