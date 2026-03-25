# Local Development Guide

This guide explains how to run the full Fawkes platform locally using
**kind** (Kubernetes-in-Docker) and **ArgoCD** as the GitOps engine.
All core apps are deployed via the ArgoCD App-of-Apps pattern, keeping
local and production workflows consistent.

---

## Prerequisites

Install the following tools before starting:

| Tool | Version | Install |
|---|---|---|
| Docker | 24+ | <https://docs.docker.com/get-docker/> |
| kind | 0.20+ | `brew install kind` or <https://kind.sigs.k8s.io/> |
| kubectl | 1.28+ | `brew install kubectl` |

> **macOS one-liner:**
> ```bash
> brew install kind kubectl
> ```

Verify everything is installed:

```bash
make check-prerequisites
```

---

## Resource Requirements

- **RAM:** ≥ 8 GB free
- **CPU:** ≥ 4 cores
- **Disk:** ≥ 20 GB free

Tested on:

- macOS (M1/M2 and Intel)
- Linux (Ubuntu 22.04)
- Windows WSL2

---

## Quick Start

```bash
# Bring up the full local platform
make local-dev
```

This single command:

1. Verifies prerequisites (`kind`, `kubectl`, `docker`)
2. Creates a kind cluster named `fawkes-local`
3. Bootstraps ArgoCD in the `argocd` namespace
4. Deploys the App-of-Apps manifest, which manages:
   - **Backstage** — developer portal (`backstage` namespace)
   - **Prometheus + Grafana** — observability (`monitoring` namespace)
5. Validates that all pods are healthy

Expected completion time: **< 15 minutes** on a standard developer machine.

---

## Accessing the Platform

After `make local-dev` completes, use `kubectl port-forward` to access services:

| Service | Port-forward command | URL |
|---|---|---|
| ArgoCD | `kubectl port-forward svc/argocd-server -n argocd 8080:80` | <http://localhost:8080> |
| Backstage | `kubectl port-forward svc/backstage -n backstage 7007:7007` | <http://localhost:7007> |
| Grafana | `kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80` | <http://localhost:3000> |

### ArgoCD credentials

```bash
kubectl get secret argocd-initial-admin-secret -n argocd \
  -o jsonpath='{.data.password}' | base64 --decode
```

Username: `admin`

### Grafana credentials

Username: `admin`  
Retrieve the generated password from the Kubernetes Secret:

```bash
kubectl get secret prometheus-grafana -n monitoring \
  -o jsonpath='{.data.admin-password}' | base64 --decode
```

---

## Architecture

```
kind cluster: fawkes-local
└── argocd (namespace)
    └── ArgoCD — GitOps controller
        └── fawkes-local-apps (App-of-Apps)
            ├── backstage  → backstage namespace
            └── prometheus → monitoring namespace
```

All application manifests live in `platform/local/apps/` and are synced
automatically by ArgoCD when changes are merged to `main`.

---

## File Layout

```
platform/local/
├── kind-config.yaml          # kind cluster configuration
└── apps/
    ├── app-of-apps.yaml      # ArgoCD App-of-Apps (parent)
    ├── backstage.yaml        # Backstage ArgoCD Application
    └── prometheus.yaml       # Prometheus + Grafana ArgoCD Application

scripts/
└── validate-local-deployment.sh  # health-check script
```

---

## Makefile Targets

| Target | Description |
|---|---|
| `make local-dev` | Full setup: cluster + ArgoCD + apps + health check |
| `make local-dev-destroy` | Delete the kind cluster |
| `make check-prerequisites` | Verify required tools are installed |
| `make create-local-cluster` | Create the kind cluster only |
| `make bootstrap-argocd` | Install ArgoCD into the cluster |
| `make deploy-apps` | Apply the App-of-Apps manifest |
| `make validate-health` | Run the platform health check |

---

## Tear Down

```bash
make local-dev-destroy
```

This deletes the `fawkes-local` kind cluster and all its resources.

---

## Troubleshooting

### Pods stuck in `Pending`

```bash
kubectl describe pod <pod-name> -n <namespace>
```

Most common cause: insufficient memory. Increase Docker Desktop resource limits
to at least 8 GB RAM.

### ArgoCD not ready after bootstrap

```bash
kubectl get pods -n argocd
kubectl rollout status deployment/argocd-server -n argocd
```

### Apps not syncing

Check the ArgoCD UI at <http://localhost:8080> (after port-forwarding) or:

```bash
kubectl get applications -n argocd
```

### Re-run health check

```bash
make validate-health
```

---

## Differences from Production

| Aspect | Local (kind) | Production (AKS) |
|---|---|---|
| Cluster type | kind (single node) | Azure AKS (multi-node) |
| Ingress | Port-forward | NGINX Ingress + DNS |
| TLS | None | cert-manager + Let's Encrypt |
| Secrets | Plain values | Azure Key Vault + ESO |
| Storage | hostPath | Azure Managed Disks |
| Monitoring | kube-prometheus-stack | kube-prometheus-stack + Thanos |
| Jenkins | Not included | Deployed |
| Mattermost | Not included | Deployed |

---

## Related Documentation

- [Quick Start Tutorial](tutorials/quick-start.md)
- [Local Dev Setup (k3d variant — Helm-direct)](tutorials/local-dev-setup.md)
  — alternative workflow using k3d and direct Helm installs (`make dev-up`)
- [ArgoCD GitOps Guide](how-to/gitops/sync-argocd-app.md)
- [Architecture Overview](ARCHITECTURE.md)
