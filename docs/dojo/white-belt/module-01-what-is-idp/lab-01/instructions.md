# Lab 01: Deploy a Service Using the Fawkes Golden Path Template

**Module**: White Belt — Module 1: What is an Internal Delivery Platform?
**Estimated Time**: 45 minutes
**Difficulty**: Beginner (basic Kubernetes knowledge required)

---

## Objectives

By the end of this lab you will have:

1. Deployed `hello-fawkes` to a local Kubernetes cluster using provided manifests
2. Verified the ArgoCD application synced successfully
3. Confirmed the service responds to HTTP requests
4. Registered the service in the Backstage catalog
5. Confirmed Grafana can reach the observability stack

---

## Prerequisites

Before starting, ensure the local Fawkes platform is running:

```bash
# Start the local development environment (takes ~5–10 minutes first time)
make dev-up

# Check all services are ready
make dev-status
```

You should see output listing URLs for ArgoCD, Backstage, and Grafana.
If any service is not ready, wait 2 minutes and re-run `make dev-status`.

**Tools required** (all installed by `make dev-up` or your local setup):

- `kubectl` — Kubernetes CLI
- `curl` — HTTP client
- `git` — version control

---

## Step 1 — Understand the Golden Path Template (5 minutes)

The Fawkes golden path template for a service consists of:

```
solution/
  namespace.yaml         # Kubernetes Namespace for isolation
  deployment.yaml        # Kubernetes Deployment (your service)
  service.yaml           # Kubernetes Service (internal load balancer)
  catalog-info.yaml      # Backstage catalog entry
  argocd-application.yaml  # ArgoCD Application (GitOps sync)
```

Open and read each file in `lab-01/solution/`. Notice:

- The **namespace** `dojo-lab-01` isolates this lab from other services.
- The **Deployment** uses `ghcr.io/nginxinc/nginx-unprivileged:1.25-alpine` as a
  lightweight stand-in for a real application. In production you would replace this
  with your own image.
- The **catalog-info.yaml** tells Backstage what this service is and who owns it.
- The **ArgoCD Application** tells ArgoCD to sync this directory from Git.

---

## Step 2 — Apply the Kubernetes Manifests (10 minutes)

Apply the solution manifests from the lab directory:

```bash
# Navigate to the repository root
cd /path/to/fawkes

# Create the namespace first
kubectl apply -f docs/dojo/white-belt/module-01-what-is-idp/lab-01/solution/namespace.yaml

# Deploy the service manifests
kubectl apply -f docs/dojo/white-belt/module-01-what-is-idp/lab-01/solution/deployment.yaml
kubectl apply -f docs/dojo/white-belt/module-01-what-is-idp/lab-01/solution/service.yaml
```

Wait for the pod to be ready:

```bash
kubectl rollout status deployment/hello-fawkes -n dojo-lab-01
# Expected: deployment "hello-fawkes" successfully rolled out
```

Check the pod is running:

```bash
kubectl get pods -n dojo-lab-01
# Expected: hello-fawkes-<hash>   1/1   Running   0   <age>
```

---

## Step 3 — Verify the Service Responds to HTTP (5 minutes)

The service is running inside the cluster. Use `kubectl port-forward` to access it
from your local machine:

```bash
# Forward local port 8888 to the service
kubectl port-forward svc/hello-fawkes 8888:80 -n dojo-lab-01 &
PF_PID=$!

# Wait for the port-forward to establish
sleep 2

# Curl the service — expect a 200 response with nginx welcome page HTML
curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/
# Expected output: 200

# Stop the port-forward
kill $PF_PID 2>/dev/null || true
```

If you see `200`, the service is healthy. ✅

---

## Step 4 — Apply the ArgoCD Application (5 minutes)

ArgoCD keeps your service in sync with Git. Apply the ArgoCD Application manifest:

```bash
kubectl apply -f docs/dojo/white-belt/module-01-what-is-idp/lab-01/solution/argocd-application.yaml
```

Check the sync status:

```bash
kubectl get application hello-fawkes -n argocd
# Expected: STATUS=Synced  HEALTH=Healthy
```

> **Note**: If ArgoCD is not available in your local environment, the previous
> `kubectl apply` steps are equivalent — ArgoCD automates what you did manually.
> The check in `validate.sh` will skip the ArgoCD check gracefully if the ArgoCD
> namespace does not exist.

---

## Step 5 — Register the Service in Backstage (5 minutes)

Register the `hello-fawkes` service in the Backstage catalog so the team can
discover it:

```bash
# Port-forward Backstage to your local machine
kubectl port-forward svc/backstage 7007:7007 -n fawkes-local &
BS_PID=$!
sleep 3

# Register the catalog entry via the Backstage API
curl -s -X POST http://localhost:7007/api/catalog/locations \
  -H "Content-Type: application/json" \
  -d '{
    "type": "url",
    "target": "https://github.com/paruff/fawkes/blob/main/docs/dojo/white-belt/module-01-what-is-idp/lab-01/solution/catalog-info.yaml"
  }'

kill $BS_PID 2>/dev/null || true
```

Open the Backstage UI in your browser: **http://localhost:7007**

Navigate to **Catalog → hello-fawkes**. You should see the service registered. ✅

> **Tip**: If the registration does not appear immediately, click the refresh icon
> in the Backstage catalog — it may take 30–60 seconds to process.

---

## Step 6 — Verify Observability (5 minutes)

Grafana provides dashboards for your services. Check it is accessible:

```bash
# Port-forward Grafana
kubectl port-forward svc/grafana 3000:3000 -n monitoring &
GF_PID=$!
sleep 2

# Check Grafana health
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health
# Expected: 200

kill $GF_PID 2>/dev/null || true
```

Open Grafana in your browser: **http://localhost:3000** (default credentials: `admin`/`admin`)

Navigate to **Dashboards → Kubernetes / Workloads** and find `dojo-lab-01`. You should
see metrics for the `hello-fawkes` deployment within a few minutes of it running. ✅

---

## Step 7 — Run the Validation Script

The validation script checks all completion criteria automatically:

```bash
make dojo-validate BELT=white MODULE=01 LAB=01
```

Or run it directly:

```bash
bash docs/dojo/white-belt/module-01-what-is-idp/lab-01/validate.sh
```

**Expected output** (all checks pass):

```
[INFO] Starting White Belt Module 01 Lab 01 validation...

[✓] Prerequisites: kubectl is installed
[✓] Cluster Access: Kubernetes cluster is accessible
[✓] Namespace: dojo-lab-01 exists and is Active
[✓] Deployment: hello-fawkes has 1/1 ready replicas
[✓] Service: hello-fawkes exists in dojo-lab-01
[✓] HTTP Check: hello-fawkes returned HTTP 200
[✓] ArgoCD Application: hello-fawkes is Synced
[✓] Backstage Catalog: Backstage API is reachable
[✓] Grafana Observability: Grafana API is reachable

==========================================
Total Tests: 9
Passed: 9
Failed: 0

[✓] All tests passed! ✅

🎉 Congratulations! You have completed White Belt Module 1 Lab 01.
   Your service is deployed, synced via GitOps, and observable.
   Move on to Module 02: DORA Metrics.
```

---

## Clean Up

When you are done with the lab, remove the resources:

```bash
kubectl delete namespace dojo-lab-01
kubectl delete application hello-fawkes -n argocd 2>/dev/null || true
```

---

## Reference Solution

The complete solution is in the `solution/` directory:

```
lab-01/solution/
  namespace.yaml           # Namespace manifest
  deployment.yaml          # Deployment manifest
  service.yaml             # Service manifest
  catalog-info.yaml        # Backstage catalog entry
  argocd-application.yaml  # ArgoCD Application
```

Study these files to understand the Fawkes golden path pattern. In Module 4 you
will create your own service from scratch using the same pattern.

---

## Troubleshooting

| Problem | Cause | Fix |
|---------|-------|-----|
| `kubectl` cannot connect | `make dev-up` not run or failed | Run `make dev-up` and wait |
| Pod stuck in `Pending` | Insufficient cluster resources | Run `kubectl describe pod -n dojo-lab-01` for details |
| Pod stuck in `ImagePullBackOff` | No internet access to pull image | Check network and run `kubectl describe pod` |
| curl returns non-200 | Pod not ready | Wait for `kubectl rollout status` to succeed |
| Backstage not found | Service not running | Check `make dev-status` |

---

➡️ **Next**: [Module 02 — DORA Metrics: Measuring Delivery Performance](../../module-02-dora-metrics/README.md)
