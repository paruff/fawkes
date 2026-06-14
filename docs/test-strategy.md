# uFawkes Test Strategy

> **Created**: 2026-06-14 | **Status**: Active
> **Goal**: Every repo has verified, production-ready artifacts through systematic testing.

---

## 1. Test Tier Definitions

| Tier | Purpose | When it runs | Failure action | Timeout |
|------|---------|-------------|----------------|---------|
| **Unit** | Individual functions/components work in isolation | After build | Block merge | 5min |
| **Integration** | Services communicate correctly, configs parse | After unit | Block merge | 10min |
| **Smoke** | Stack starts and is healthy | After build | Block merge | 5min |
| **Acceptance** | Artifact meets business requirements | After integration | Block merge | 15min |
| **Load** | Artifact performs under expected traffic | After acceptance | Block/_warn | 10min |
| **Performance** | Artifact meets latency/throughput targets | After load | Block/_warn | 10min |

---

## 2. Per-Repo Test Matrix

### uFawkesObs (Observability Plane — Docker Compose)

| Tier | What to test | Tool | Files | Pass criteria |
|------|-------------|------|-------|---------------|
| **Unit** | Config validation functions (Python) | pytest | `tests/unit/test_*_config_validation.py` | All tests pass |
| **Integration** | Prometheus scraping, Grafana queries, OTel pipeline, Tempo traces, Loki logs | pytest + HTTP | `tests/integration/test_*.py` | All endpoints respond, metrics flow |
| **Smoke** | `docker compose up` → health checks | docker compose + curl | `tests/acceptance/observability-pipeline/test-*.sh` | All containers healthy within 90s |
| **Acceptance** | End-to-end observability: generate → scrape → store → query → alert | pytest + telemetry-generator | `tests/e2e/test_telemetry_flow.py` | Metrics appear in Prometheus, dashboards render, alerts fire |
| **Load** | High metric volume ingestion | k6 | `tests/load/metric_ingestion.js` | Prometheus handles 10k metrics/s, Grafana <2s |
| **Performance** | Query latency under load | k6 | `tests/performance/query_latency.js` | p95 <500ms, memory <2GB |

**Current state**: Unit ✅ | Integration ✅ | Smoke ✅ | Acceptance ✅ | Load ❌ | Performance ❌

### uFawkesPipe (Integration & Delivery Plane — Jenkins)

| Tier | What to test | Tool | Files | Pass criteria |
|------|-------------|------|-------|---------------|
| **Unit** | JCasC parsing, .fawkespipe.yml contract parsing, shared library functions | pytest + Groovy tests | `tests/unit/test_*.py` | All configs parse, contract fields validated |
| **Integration** | Docker Compose startup, Jenkins API connectivity, seed job execution | pytest + Docker + HTTP | `tests/integration/test_*.py` | Jenkins starts, API responds, jobs created |
| **Smoke** | `docker compose up` → Jenkins healthy → pipeline created | docker compose + curl | `tests/smoke/test_jenkins_health.sh` | Jenkins UI accessible, all plugins loaded |
| **Acceptance** | Full pipeline execution: checkout → build → test → scan → publish | Jenkins API + pytest | `tests/acceptance/test_pipeline_e2e.py` | Pipeline completes, all stages pass, artifacts published |
| **Load** | Concurrent pipeline execution | k6 or custom script | `tests/load/concurrent_pipelines.js` | 10 concurrent pipelines complete without errors |
| **Performance** | Pipeline execution time | custom timing | `tests/performance/pipeline_timing.js` | Build <5min, test <3min, scan <2min |

**Current state**: Unit ❌ | Integration ❌ | Smoke ❌ | Acceptance ❌ | Load ❌ | Performance ❌

### fawkes (Core Platform — Kubernetes)

| Tier | What to test | Tool | Files | Pass criteria |
|------|-------------|------|-------|---------------|
| **Unit** | Helm chart values, Terraform variables, K8s manifest validation | pytest + helm lint + terraform validate | `tests/unit/test_*.py` | All configs valid |
| **Integration** | K8s services, Terraform provisioning, Helm template rendering | Terratest | `tests/integration/test_*.go` | Resources provision correctly |
| **Smoke** | ArgoCD sync → pods running | kubectl + curl | `tests/smoke/test_k8s_health.sh` | All pods Running, services accessible |
| **Acceptance** | Full platform workflow: clone → build → deploy → test | BATS + Playwright | `tests/acceptance/test_platform_e2e.sh` | End-to-end flow works |
| **Load** | API gateway under traffic | k6 | `tests/load/api_gateway.js` | p95 <500ms at 1000 RPS |
| **Performance** | Resource utilization, scaling | k6 + kubectl metrics | `tests/performance/scaling.js` | HPA scales correctly |

**Current state**: Unknown (need to audit)

### uFawkes.dev (Marketing Site — Jekyll)

| Tier | What to test | Tool | Files | Pass criteria |
|------|-------------|------|-------|---------------|
| **Unit** | N/A (static content) | N/A | N/A | N/A |
| **Integration** | N/A | N/A | N/A | N/A |
| **Smoke** | `jekyll build` → `_site/` produced | jekyll + file check | CI workflow | Build succeeds, no errors |
| **Acceptance** | All pages render, navigation works, forms submit | Playwright | `tests/acceptance/test_pages.py` | All pages accessible, CTAs functional |
| **Load** | Concurrent user simulation | k6 | `tests/load/site_traffic.js` | p95 TTFB <1s at 100 users |
| **Performance** | Core Web Vitals | Lighthouse CI | CI workflow | LCP <2.5s, FID <100ms, CLS <0.1 |

**Current state**: Smoke ✅ (Jekyll build) | Acceptance ❌ | Load ❌ | Performance ❌

### uFawkesAI (Template Repo)

| Tier | What to test | Tool | Files | Pass criteria |
|------|-------------|------|-------|---------------|
| **Unit** | N/A (config files only) | N/A | N/A | N/A |
| **Integration** | N/A | N/A | N/A | N/A |
| **Smoke** | Pre-commit passes | pre-commit | CI workflow | All hooks pass |
| **Acceptance** | N/A | N/A | N/A | N/A |

**Current state**: Smoke ✅ (pre-commit)

---

## 3. Coverage Thresholds

Dual thresholds with ratchet effect:

| Repo Type | Unit (Total) | Unit (Diff) | Acceptance (Total) | Acceptance (Diff) |
|-----------|-------------|-------------|-------------------|-------------------|
| **stack** (Obs, Pipe, DevX) | 60% | 80% | 50% | 70% |
| **core** (fawkes) | 60% | 80% | 50% | 70% |
| **site** (uFawkes.dev) | N/A | N/A | N/A | N/A |
| **template** (uFawkesAI) | N/A | N/A | N/A | N/A |

**Enforcement**:
- Diff coverage must meet threshold (new code tested)
- Total coverage cannot decrease (ratchet)
- Coverage only goes up over time

---

## 4. Test File Structure

### Standard directory layout:
```
tests/
├── unit/                    # Isolated function tests
│   ├── conftest.py         # Shared fixtures
│   └── test_*.py           # Unit tests
├── integration/            # Service communication tests
│   ├── conftest.py         # Shared fixtures (Docker, HTTP)
│   └── test_*.py           # Integration tests
├── smoke/                   # Quick health checks
│   └── test_*.sh           # Shell-based health checks
├── acceptance/              # Business requirement verification
│   └── test_*.py           # End-to-end acceptance tests
├── load/                    # Performance under load
│   └── *.js                # k6 load test scripts
└── performance/             # Latency/throughput targets
    └── *.js                # k6 performance test scripts
```

---

## 5. CI Integration

### Pipeline stages (per repo):
```
preflight → lint → [SAST, SCA, secrets, policy] → build → tests → deploy
```

### Test execution order:
1. **Unit tests** — run first, fastest feedback
2. **Integration tests** — run after unit passes
3. **Smoke tests** — run after build produces artifact
4. **Acceptance tests** — run after smoke passes
5. **Load tests** — run after acceptance (optional, can be post-merge)
6. **Performance tests** — run after load (optional, can be nightly)

### Coverage reporting:
- Unit coverage: `pytest-cov`, `istanbul`, `go cover`
- Upload to Codecov or similar for tracking
- PR comments with coverage diff

---

## 6. Test Tools by Language

| Language | Unit Testing | Integration | Load | Performance |
|----------|-------------|-------------|------|-------------|
| **Python** | pytest + pytest-cov | pytest + requests + Docker | k6 | k6 |
| **Groovy** | Spock / JUnit | Jenkins Test Harness | k6 | k6 |
| **Go** | go test + go cover | Terratest | k6 | k6 |
| **Shell** | BATS | BATS + curl | k6 | k6 |
| **JavaScript** | Jest / Vitest | Playwright | k6 | Lighthouse CI |

---

## 7. Implementation Priority

| Priority | Repo | Action | Effort |
|----------|------|--------|--------|
| **P0** | uFawkesObs | Add load + performance tests | 1 day |
| **P0** | uFawkesPipe | Create full test suite + CI pipeline | 3 days |
| **P1** | fawkes | Audit existing tests, fill gaps | 2 days |
| **P1** | uFawkes.dev | Add Playwright acceptance tests | 1 day |
| **P2** | uFawkesDevX | Add test structure (when content exists) | 0.5 day |
| **P2** | uFawkesAI | Already minimal — no changes needed | 0 |

---

## 8. Test Data Management

- **Fixtures**: Use `conftest.py` for shared test data
- **Mocking**: Mock external services (GitHub API, Docker Hub) in unit tests
- **Real services**: Use Docker Compose for integration tests
- **Test secrets**: Use `.env.test` (gitignored) with placeholder values
- **Golden files**: Store expected outputs in `tests/fixtures/` for comparison

---

## 9. Acceptance Test Patterns

### uFawkesObs (observability flow):
```python
def test_metric_flows_to_prometheus():
    # Generate metric → wait for scrape → query Prometheus → assert
```

### uFawkesPipe (pipeline execution):
```python
def test_pipeline_completes():
    # Trigger pipeline → wait for completion → verify stages → check artifacts
```

### fawkes (platform deployment):
```bash
test_k8s_pods_healthy() {
    # kubectl get pods → assert all Running → curl health endpoints
}
```

### uFawkes.dev (site functionality):
```javascript
test_all_pages_accessible() => {
    // Navigate to each page → assert 200 → check key elements
}
```

---

*Last updated: 2026-06-14*
*Review schedule: After each repo's test suite is implemented*
