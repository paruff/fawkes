# Local Dev Setup — Run Fawkes on Your Laptop

This tutorial walks you through bringing up a complete, fully functional Fawkes
environment on your local machine using **k3d** (a lightweight Kubernetes-in-Docker
runtime). No cloud account required.

The single command `make dev-up` installs **five components**:

| Component | Role |
|---|---|
| **ArgoCD** | GitOps controller — syncs Git state to Kubernetes |
| **Vault** (dev mode) | Secrets management |
| **Backstage** | Developer portal and service catalog |
| **Prometheus + Grafana** | Metrics collection and dashboards |
| **podinfo** (sample app) | Demo workload managed end-to-end by ArgoCD |

**Expected time:** < 10 minutes on a machine with 8 GB RAM and Docker installed.

---

## Prerequisites

Install these tools before running `make dev-up`:

| Tool | Version | Install |
|---|---|---|
| Docker | 24+ | <https://docs.docker.com/get-docker/> |
| k3d | 5+ | `brew install k3d` or <https://k3d.io> |
| kubectl | 1.28+ | `brew install kubectl` |
| Helm | 3.14+ | `brew install helm` |

> **macOS one-liner:**
> ```bash
> brew install k3d kubectl helm
> ```

Verify everything is installed:

```bash
make check-deps
```

---

## Quick Start

```bash
# 1. Clone the repository (skip if you already have it)
git clone https://github.com/paruff/fawkes.git
cd fawkes

# 2. Bring up the local platform
make dev-up

# 3. Check status and service URLs
make dev-status
```

That's it. `make dev-up` handles cluster creation, Helm installs, and the ArgoCD
application manifest for the sample app automatically.

---

## Accessing the Services

`make dev-status` prints the exact `kubectl port-forward` command for each service.
Open a separate terminal tab for each one you want to access:

### ArgoCD

```bash
kubectl port-forward -n argocd svc/argocd-server 8888:80
```

Open <http://localhost:8888>  
Username: `admin`  
Password: printed by `make dev-status` (retrieved from the `argocd-initial-admin-secret` Secret)

### Vault

```bash
kubectl port-forward -n vault svc/vault 8200:8200
```

Open <http://localhost:8200>  
Root token: `fawkes-dev-root`

> Vault runs in **dev mode** — data is in-memory only and is reset when the pod restarts.
> This is intentional for local development; do not use dev mode in production.

### Backstage

```bash
kubectl port-forward -n backstage svc/backstage 7007:7007
```

Open <http://localhost:7007>

### Grafana

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```

Open <http://localhost:3000>  
Username: `admin`  
Password: `fawkes-grafana`

### Prometheus

```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Open <http://localhost:9090>

### Sample App (podinfo)

```bash
kubectl port-forward -n sample-apps svc/podinfo 9898:9898
```

Open <http://localhost:9898>  
podinfo is deployed and managed by ArgoCD — you can watch the sync in the ArgoCD UI.

---

## Tearing Down

When you are done, delete the entire cluster with a single command:

```bash
make dev-down
```

This removes the k3d cluster and all associated containers. Your local Docker
installation and kubeconfig are cleaned up automatically.

---

## Troubleshooting

### `make dev-up` fails at Helm install

Helm installs time out after 5–8 minutes per chart. If your machine is under
heavy load or has a slow network, individual charts may time out. Re-run
`make dev-up` — it is idempotent and skips any already-installed releases.

### Cluster already exists

```
⚠️  Cluster 'fawkes-dev' already exists — skipping creation
```

This is expected if you ran `make dev-up` before. The script continues with the
Helm installs. To start completely fresh:

```bash
make dev-down
make dev-up
```

### Cannot connect to Docker

```
❌ Docker required
```

Make sure Docker Desktop (or Docker Engine on Linux) is running before calling
`make dev-up`.

### `argocd-initial-admin-secret` not found

ArgoCD 2.7+ auto-deletes the initial admin secret after first login. If you have
already logged in, reset the password via:

```bash
argocd account update-password --account admin
```

### Port already in use

If 8080 is already bound on your machine, edit `scripts/dev-up.sh` and change
the `--port "8080:80@loadbalancer"` flag to a free port (e.g., `9080`).

---

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `FAWKES_CLUSTER` | `fawkes-dev` | k3d cluster name used by all three scripts |

Example — use a custom cluster name:

```bash
FAWKES_CLUSTER=my-fawkes make dev-up
FAWKES_CLUSTER=my-fawkes make dev-status
FAWKES_CLUSTER=my-fawkes make dev-down
```

---

## Next Steps

- **White Belt tutorial** — [Deploy your first app →](1-deploy-first-service.md)
- **Full architecture overview** — [docs/ARCHITECTURE.md](../../docs/ARCHITECTURE.md)
- **Dojo tutorials index** — [docs/tutorials/index.md](index.md)
