# Quick Start Tutorial

Deploy your first service on the Fawkes platform in 15 minutes. This quick start
gives you a taste of the full workflow: scaffold a service, run it locally, and
watch ArgoCD deploy it to Kubernetes.

## Prerequisites

Before you begin:
- Docker installed and running
- `kubectl` installed and configured
- Access to a Fawkes cluster (local or shared sandbox)
- Repository cloned: `git clone https://github.com/paruff/fawkes.git`

## Step 1: Start the Local Platform

```bash
cd fawkes
make dev-up
```

This command provisions a local Kubernetes cluster (kind), installs ArgoCD in the
`argocd` namespace, Backstage in `backstage`, and Prometheus/Grafana in `monitoring`.
Wait for all pods to be ready (approximately 3–5 minutes).

```bash
kubectl get pods -A | grep -v Running  # should show nothing after a few minutes
```

## Step 2: Open Backstage

```bash
make backstage-open
# Opens http://localhost:7007
```

Navigate to **Create** → **Service** and select the **Python FastAPI Service** golden-path
template. Fill in:
- **Name**: `hello-world`
- **Owner**: your team name
- **Description**: My first Fawkes service

Click **Create** and wait for the repository to be scaffolded.

## Step 3: Clone and Explore Your New Service

```bash
git clone https://github.com/your-org/hello-world.git
cd hello-world
ls
# app/main.py  Dockerfile  charts/  Jenkinsfile  catalog-info.yaml
```

The template created a ready-to-run FastAPI service with:
- A `Dockerfile` using a multi-stage build
- A Helm chart under `charts/`
- A `Jenkinsfile` for CI
- A `catalog-info.yaml` for Backstage registration

## Step 4: Run Locally

```bash
docker build -t hello-world:dev .
docker run -p 8000:8000 hello-world:dev
curl http://localhost:8000/health  # → {"status": "healthy"}
```

## Step 5: Deploy via GitOps

Push a change to `main`:

```bash
echo "# Updated" >> README.md
git add README.md && git commit -m "feat: first change"
git push origin main
```

Jenkins detects the push, runs the CI pipeline, builds a new image, and updates
the Helm chart tag in the GitOps repository. ArgoCD detects the manifest change
and syncs the deployment to Kubernetes.

```bash
# Watch the deployment happen
kubectl get pods -n hello-world -w
```

## Step 6: Verify in Grafana

```bash
make grafana-open
# Opens http://localhost:3000
```

Navigate to the **Platform Overview** dashboard. Your new service appears with
health metrics within a few minutes of deployment.

## Next Steps

- [Tutorial 1: Deploy Your First Service (Full)](1-deploy-first-service.md)
- [Tutorial 2: Add Distributed Tracing](2-add-tracing-tempo.md)
- [Assessment: Check Your Current Capabilities](../getting-started/assessment.md)

## See Also

- [Getting Started](../getting-started.md)
- [Tutorials Overview](index.md)
