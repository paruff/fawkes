---
name: Helm & Platform Instructions
description: Applied automatically when working in platform/ or charts/
applyTo: "platform/**/*.yaml,platform/**/*.yml,charts/**/*.yaml,charts/**/*.yml"
---

# Helm & Platform Instructions — Fawkes

## Read First
- `AGENTS.md` → Helm / Kubernetes Rules
- `docs/CHANGE_IMPACT_MAP.md` → platform changes that cascade to services

## Fawkes Helm Standards

### Required Labels on Every Deployment/Pod
```yaml
labels:
  app: {{ .Chart.Name }}
  version: {{ .Chart.AppVersion | quote }}
  component: {{ .Values.component }}
  managed-by: fawkes
  helm.sh/chart: {{ include "chart.chart" . }}
```

### Required Resource Limits on Every Container
```yaml
# ✅ Required
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

# ❌ Never leave empty
resources: {}
```

### No Latest Image Tags
```yaml
# ✅ Pinned digest or version
image:
  repository: ghcr.io/paruff/fawkes-service
  tag: "1.2.3"       # or SHA digest

# ❌ Never
image:
  tag: latest
```

### Environment-Specific Values in Overrides
```yaml
# ✅ base values.yaml — generic defaults only
replicaCount: 1

# ✅ values-prod.yaml — environment override
replicaCount: 3

# ❌ Never in base values.yaml
database:
  host: prod-postgres.internal   # environment-specific
```

### ArgoCD Application Pattern
```yaml
# platform/apps/{app-name}/application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {app-name}
  namespace: argocd
  labels:
    managed-by: fawkes
spec:
  project: fawkes
  source:
    repoURL: https://github.com/paruff/fawkes
    targetRevision: main
    path: charts/{app-name}
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes-platform
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Linters That Must Pass
```bash
helm lint charts/{chart-name}
helm template charts/{chart-name} | kubectl apply --dry-run=client -f -
yamllint platform/
```

## What Requires Human Approval
- New ArgoCD Application manifest
- Changes to Backstage catalog descriptors
- New Helm chart dependencies (`Chart.yaml` changes)
- Changes to NetworkPolicy or RBAC manifests
- Any change to secrets management (Vault, ExternalSecrets)
