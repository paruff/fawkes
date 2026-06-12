---
name: pipeline-bootstrap
description: "Step-by-step guide to connect a uFawkesAI project to uFawkesPipe and fawkes platform: Dockerfile, ArgoCD manifest, DORA deployment spans. Use when setting up CI/CD for a new service."
license: MIT
compatibility: Claude Code, GitHub Copilot, OpenCode, Cursor, Codex, Gemini CLI
metadata:
  author: paruff
  suite: uFawkesAI
---

# Skill: Pipeline Bootstrap

> **Load trigger:** `"load pipeline-bootstrap skill"` > **Agent:** Used by pipe-agent
> **DORA:** Cap 4 + Cap 6
> **Token cost:** Medium

## Purpose

Step-by-step guide for connecting a uFawkesAI project to uFawkesPipe (paruff/uFawkesPipe)
and the fawkes platform delivery infrastructure.

## Prerequisites

Before starting, confirm these are in place:

- [ ] `AGENTS.md` populated (run onboarding agent if not)
- [ ] `ci-quality.yml` passing on main branch
- [ ] `OTEL_SERVICE_NAME` decided (format: `[org]-[service]-[env]`, e.g. `fawkes-payments-prod`)
- [ ] ArgoCD application name decided (same as service name by convention)

## Step 1 — Create Pipeline Contract Document

Create `docs/PIPELINE_CONTRACT.md`:

```markdown
# Pipeline Contract — [Service Name]

## CI Gates (uFawkesAI)

| Gate         | Tool     | Threshold     |
| ------------ | -------- | ------------- |
| PR size      | git diff | 400 lines max |
| Lint         | [tool]   | 0 errors      |
| Typecheck    | [tool]   | 0 errors      |
| Coverage     | [tool]   | 80% minimum   |
| Architecture | [tool]   | 0 violations  |

## Delivery Config (uFawkesPipe)

- ArgoCD app name: `[service-name]`
- Target namespace: `[namespace]`
- Image registry: `ghcr.io/[org]/[service-name]`
- Deploy on: merge to `main`

## Observability

- OTEL service name: `[OTEL_SERVICE_NAME]`
- OTLP endpoint: from env `OTEL_EXPORTER_OTLP_ENDPOINT`
- Grafana dashboard: `docs/obs/[service-name]-dashboard.json`

## Rollback

- Automated: ArgoCD health checks trigger rollback on failed deployment
- Manual: `argocd app rollback [service-name]`
```

## Step 2 — Generate Dockerfile (if containerized)

```dockerfile
# Minimal production Dockerfile
FROM [language-base-image]:latest AS builder
WORKDIR /app
COPY . .
RUN [build command]

FROM [language-runtime]:slim
WORKDIR /app
COPY --from=builder /app/[binary or dist] .
# Run as non-root
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser
EXPOSE 8080
ENTRYPOINT ["./[binary]"]
```

Note: paruff/fawkes uses Trivy for container scanning. Ensure base images are
not flagged by Trivy before pushing.

## Step 3 — Create ArgoCD Application Manifest

```yaml
# infra/argocd/[service-name].yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: [service-name]
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/[org]/[repo]
    targetRevision: main
    path: infra/k8s/[service-name]
  destination:
    server: https://kubernetes.default.svc
    namespace: [namespace]
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

## Step 4 — Add DORA Deployment Spans

Deployment spans must be emitted reliably. The correct approach depends on
your stack. Choose one — do not use raw curl in production CI.

**Option A — OTEL SDK in application code (preferred)**
Emit `deployment.completed` span from the application's own startup sequence
after a successful health check. This is the most reliable — it only fires
when the application is actually running. See obs-bootstrap skill for SDK patterns.

**Option B — GitHub Actions OTEL action (recommended for CI emission)**

```yaml
- name: Emit deployment span
  uses: inception-health/otel-export-trace-action@v1 # verify current version
  with:
    otlpEndpoint: ${{ secrets.OTEL_ENDPOINT }}
    otlpHeaders: ""
    githubToken: ${{ secrets.GITHUB_TOKEN }}
    serviceName: ${{ vars.OTEL_SERVICE_NAME }}
```

⚠ Verify the action name and version at github.com/marketplace before using.
Do not pin to a floating tag — use a full commit SHA in production.

**Option C — Raw HTTP call (acceptable for prototyping only)**

```yaml
- name: Emit deployment span (prototype — harden before production)
  run: |
    # WARNING: no retry, no error handling, fails silently if endpoint is down.
    # Replace with Option A or B before production use.
    curl --silent --fail --max-time 5 \
      -X POST "${OTEL_EXPORTER_OTLP_ENDPOINT}/v1/traces" \
      -H "Content-Type: application/json" \
      -d "{\"service\":\"${OTEL_SERVICE_NAME}\",\"event\":\"deployment.completed\",\"sha\":\"${GITHUB_SHA}\"}" \
    || echo "WARN: OTEL span emission failed — deployment proceeds regardless"
  env:
    OTEL_EXPORTER_OTLP_ENDPOINT: ${{ secrets.OTEL_ENDPOINT }}
    OTEL_SERVICE_NAME: ${{ vars.OTEL_SERVICE_NAME }}
```

The `|| echo` ensures CI does not fail on observability failure. Observability
is a non-blocking side-effect of deployment, not a gate condition.

## Step 5 — Validate Integration

Checklist after completing above steps:

- [ ] `make dev-up` in paruff/fawkes starts local k3d cluster
- [ ] ArgoCD UI shows new application (http://localhost:8080/argocd)
- [ ] Deployment span appears in Grafana Tempo traces
- [ ] Deployment frequency metric appears in DORA dashboard
- [ ] `@dora-agent` can see the new service in metrics output

## Common Failure Modes

| Symptom                      | Likely Cause                    | Fix                                       |
| ---------------------------- | ------------------------------- | ----------------------------------------- |
| ArgoCD app stuck `OutOfSync` | Namespace doesn't exist         | Add `CreateNamespace=true` sync option    |
| No OTEL spans in Tempo       | Endpoint env var not set in pod | Add to Kubernetes Secret + env ref        |
| Trivy blocks image push      | Base image has CVEs             | Switch to `distroless` or `slim` variant  |
| Coverage gate fails in CI    | Test env differs from local     | Ensure `CI=true` env var set in test step |
