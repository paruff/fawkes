#!/usr/bin/env bash

# Lightweight rename of bootstrap.sh -> ignite.sh (keeps behavior but with a new name)
set -euo pipefail

echo "Current working directory: $(pwd)"

function error_exit { echo "[ERROR] $1"; exit 1; }

function usage {
  echo "Usage: $0 <environment|cleanup>"
  echo "  environment: local | dev | stage | production"
  echo "  cleanup: remove ArgoCD and Fawkes resources for a fresh start"
  exit 1
}

if [[ "${1:-}" == "cleanup" ]]; then
  echo "🧹 Cleaning up ArgoCD and Fawkes namespaces..."
  kubectl delete namespace argocd --wait || echo "argocd namespace not found"
  kubectl delete namespace fawkes --wait || echo "fawkes namespace not found"
  kubectl delete namespace jenkins --wait  || echo "argocd namespace not found"
  echo "✅ Cleanup complete."
  exit 0
fi

ENV="${1:-}"
if [[ -z "$ENV" ]]; then
  usage
fi

case "$ENV" in
  local|dev|stage|production) ;;
  *) error_exit "Invalid environment: $ENV. Must be one of: local, dev, stage, production." ;;
esac

echo "🔎 Validating prerequisites..."

if [[ -f "$(dirname "${BASH_SOURCE[0]}")/tools.sh" ]]; then
  echo "➡ Running tools check via scripts/tools.sh"
  if ! "$(dirname "${BASH_SOURCE[0]}")/tools.sh" check; then
    echo "Some required tools are missing in your environment."
    echo "You can enter the Nix dev shell to get a reproducible environment:"
    echo "  ./scripts/tools.sh shell"
    if command -v bash >/dev/null 2>&1 && [[ -f "$(dirname "${BASH_SOURCE[0]}")/tools-install.sh" || -f "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" ]]; then
      # Detect auto-install flags: either env AUTO_INSTALL=1/true or second positional arg --auto-install
      AUTO_INSTALL=0
      if [[ "${AUTO_INSTALL:-}" == "1" || "${AUTO_INSTALL:-}" == "true" || "${2:-}" == "--auto-install" ]]; then
        AUTO_INSTALL=1
      fi

      if [[ ${AUTO_INSTALL} -eq 1 ]]; then
        echo "AUTO_INSTALL enabled — running installer non-interactively..."
        if [[ "$(uname -s)" == "Darwin" && -f "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" ]]; then
          bash "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" --yes --accept-driver-permissions
        else
          bash "$(dirname "${BASH_SOURCE[0]}")/tools-install.sh" --yes
        fi
        echo "Re-running tools check..."
        if ! "$(dirname "${BASH_SOURCE[0]}")/tools.sh" check; then
          error_exit "Prerequisite check failed after installer. Please resolve remaining issues and try again."
        fi
      else
        read -r -p "Would you like to run the interactive installer to provision prerequisites now? [y/N]: " RUN_INSTALL
        if [[ "$RUN_INSTALL" =~ ^[Yy]$ ]]; then
          echo "Running installer helper..."
          if [[ "$(uname -s)" == "Darwin" && -f "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh" ]]; then
            bash "$(dirname "${BASH_SOURCE[0]}")/brew-install.sh"
          else
            bash "$(dirname "${BASH_SOURCE[0]}")/tools-install.sh"
          fi
          echo "Re-running tools check..."
          if ! "$(dirname "${BASH_SOURCE[0]}")/tools.sh" check; then
            error_exit "Prerequisite check failed after installer. Please resolve remaining issues and try again."
          fi
        else
          error_exit "Prerequisite check failed."
        fi
      fi
    else
      error_exit "Prerequisite check failed."
    fi
  fi
  echo "✅ All required tools are available."
else
  for tool in kubectl jq base64 terraform; do
    if ! command -v $tool &>/dev/null; then
      error_exit "$tool is required but not installed. Please install $tool and try again."
    fi
  done
  echo "✅ All required tools are installed."
fi

echo "🔍 Checking available Kubernetes contexts..."
kubectl config get-contexts || true

ACTIVE_CONTEXT=$(kubectl config current-context 2>/dev/null || echo "")
if [[ -n "$ACTIVE_CONTEXT" ]]; then
  echo "Current active context: $ACTIVE_CONTEXT"
  if kubectl cluster-info &>/dev/null; then
    read -p "Do you want to use the current context '$ACTIVE_CONTEXT'? [y/N]: " USE_CURRENT
    if [[ ! "$USE_CURRENT" =~ ^[Yy]$ ]]; then
      error_exit "Aborted by user."
    fi
    echo "✅ Using current context: $ACTIVE_CONTEXT"
  else
    echo "Current context '$ACTIVE_CONTEXT' is not reachable."
    # If local environment requested, try to start minikube automatically
    if [[ "$ENV" == "local" ]]; then
      if command -v minikube >/dev/null 2>&1; then
        echo "Attempting to start minikube for local environment..."
        # select driver heuristically
        DRIVER=""
        # On macOS, if docker CLI exists but daemon isn't started, try to start Docker Desktop and wait
        if command -v docker >/dev/null 2>&1 && ! docker info >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
          echo "Docker CLI found but daemon is not running. Attempting to start Docker Desktop..."
          open -a Docker || true
          echo "Waiting for Docker engine to become ready (up to 90s)..."
          end=$((SECONDS + 90))
          until docker info >/dev/null 2>&1 || [[ ${SECONDS} -ge ${end} ]]; do
            sleep 3
          done
          if docker info >/dev/null 2>&1; then
            echo "Docker engine is ready."
          else
            echo "Docker engine did not become ready within 90s; will try other drivers."
          fi
        fi

        if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
          DRIVER=docker
        elif command -v docker-machine-driver-hyperkit >/dev/null 2>&1; then
          DRIVER=hyperkit
        elif command -v VBoxManage >/dev/null 2>&1; then
          DRIVER=virtualbox
        else
          DRIVER=auto
        fi
        echo "Starting minikube (driver=${DRIVER}) — this may take a minute..."
        minikube start --driver=${DRIVER} --memory=8192 --cpus=4 --disk-size=40g
        echo "minikube started. Setting context to 'minikube'"
        kubectl config use-context minikube || true
      else
        error_exit "kubectl context is unreachable and minikube is not installed. Install minikube or choose another cluster."
      fi
    else
      error_exit "Current context not reachable. Aborting."
    fi
  fi
else
  # No active context — for local, try to start minikube; otherwise abort
  if [[ "$ENV" == "local" ]]; then
    if command -v minikube >/dev/null 2>&1; then
      echo "No active Kubernetes context found; starting minikube for local development..."
      DRIVER=""
      if command -v docker >/dev/null 2>&1 && ! docker info >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
        echo "Docker CLI found but daemon is not running. Attempting to start Docker Desktop..."
        open -a Docker || true
        echo "Waiting for Docker engine to become ready (up to 90s)..."
        end=$((SECONDS + 90))
        until docker info >/dev/null 2>&1 || [[ ${SECONDS} -ge ${end} ]]; do
          sleep 3
        done
        if docker info >/dev/null 2>&1; then
          echo "Docker engine is ready."
        else
          echo "Docker engine did not become ready within 90s; will try other drivers."
        fi
      fi

      if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
        DRIVER=docker
      elif command -v docker-machine-driver-hyperkit >/dev/null 2>&1; then
        DRIVER=hyperkit
      elif command -v VBoxManage >/dev/null 2>&1; then
        DRIVER=virtualbox
      else
        DRIVER=auto
      fi
      minikube start --driver=${DRIVER} --memory=8192 --cpus=4 --disk-size=40g
      kubectl config use-context minikube || true
    else
      error_exit "No active context and minikube is not installed. Install minikube or configure a cluster."
    fi
  else
    error_exit "No active Kubernetes context found. Configure kubectl and try again."
  fi
fi

echo "✅ Kubernetes context set and reachable."

# Create argocd namespace if it does not exist
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: argocd
EOF

echo "namespace/argocd ensured"

# Deploy ArgoCD using Terraform
TF_MODULE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../infra/terraform/argocd" && pwd)"
echo "Deploying ArgoCD via Terraform module at ${TF_MODULE_DIR}"

# Export a stable kubeconfig for Terraform
TEMP_KUBECONFIG=$(mktemp -t fawkes-kubeconfig-XXXX.yaml)
kubectl config view --raw --minify --flatten > "${TEMP_KUBECONFIG}"
export KUBECONFIG="${TEMP_KUBECONFIG}"
echo "Using temporary KUBECONFIG at ${KUBECONFIG} for Terraform operations"

cleanup_kubeconfig() { rm -f "${TEMP_KUBECONFIG}" || true; }
trap cleanup_kubeconfig EXIT

pushd "${TF_MODULE_DIR}" >/dev/null
echo "Running: terraform init"
terraform init -input=false 2>&1 | tee terraform.log

echo "Running: terraform plan"
terraform plan -input=false -out=plan.tfplan 2>&1 | tee -a terraform.log

echo "Applying plan.tfplan"
terraform apply -input=false plan.tfplan 2>&1 | tee -a terraform.log
rc=${PIPESTATUS[0]}
popd >/dev/null
if [[ ${rc} -ne 0 ]]; then
  error_exit "Terraform apply for ArgoCD failed; see ${TF_MODULE_DIR}/terraform.log"
fi

echo "⏳ Waiting for ArgoCD server to be available..."
kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

ARGOCD_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "🔑 ArgoCD admin password: $ARGOCD_PASSWORD"

echo "🌐 Ensuring ArgoCD deployments are available..."

wait_for_workload() {
  local name="$1" ns="${2:-default}" timeout="${3:-300}"
  echo "⏳ Waiting for workload ${name} in namespace ${ns} (timeout ${timeout}s)..."
  if kubectl get deployment "${name}" -n "${ns}" >/dev/null 2>&1; then
    if ! kubectl wait --for=condition=available deployment/${name} -n "${ns}" --timeout="${timeout}s"; then
      kubectl -n "${ns}" get pods -o wide
      kubectl -n "${ns}" describe deployment/${name} || true
      return 1
    fi
    return 0
  fi
  if kubectl get statefulset "${name}" -n "${ns}" >/dev/null 2>&1; then
    if ! kubectl rollout status statefulset/${name} -n "${ns}" --timeout="${timeout}s"; then
      kubectl -n "${ns}" get pods -o wide
      kubectl -n "${ns}" describe statefulset/${name} || true
      return 1
    fi
    return 0
  fi
  echo "Workload ${name} not found as Deployment or StatefulSet; falling back to pods with prefix ${name}"
  local end=$((SECONDS + timeout))
  while [[ ${SECONDS} -lt ${end} ]]; do
    pod=$(kubectl -n "${ns}" get pods --no-headers -o custom-columns=":metadata.name" | grep "^${name}" | head -n1 || true)
    if [[ -n "$pod" ]]; then
      ready=$(kubectl -n "${ns}" get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}' 2>/dev/null || echo "false")
      if [[ "$ready" == "true" ]]; then
        echo "Pod $pod is ready"
        return 0
      fi
    fi
    sleep 2
  done
  kubectl -n "${ns}" get pods -o wide
  return 1
}

for dep in argocd-server argocd-repo-server argocd-application-controller argocd-dex-server; do
  if ! wait_for_workload "${dep}" argocd 300; then
    error_exit "Deployment ${dep} failed to become available"
  fi
done

echo "⏳ Waiting for argocd-server service endpoints..."
ENDPOINTS_TIMEOUT=120
end=$((SECONDS + ENDPOINTS_TIMEOUT))
while [[ ${SECONDS} -lt ${end} ]]; do
  if kubectl get endpoints argocd-server -n argocd -o jsonpath='{.subsets}' | grep -q .; then
    echo "✅ argocd-server has endpoints"
    break
  fi
  sleep 2
done
if [[ ${SECONDS} -ge ${end} ]]; then
  kubectl -n argocd get endpoints
  error_exit "argocd-server service has no endpoints after ${ENDPOINTS_TIMEOUT}s"
fi

echo "🌐 Creating ArgoCD Application CRs in-cluster (no port-forward required)..."

cat <<'EOF' | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: platform/apps
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
---
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: fawkes-infra
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/paruff/fawkes.git
    path: infra/kubernetes
    targetRevision: HEAD
  destination:
    server: https://kubernetes.default.svc
    namespace: fawkes
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

echo "✅ ArgoCD Application CRs applied — ArgoCD will pick them up and sync the fawkes namespace."
echo "If you want to access the ArgoCD UI locally run: kubectl -n argocd port-forward svc/argocd-server 8080:443"

echo ""
echo "🎉 Ignite complete for '$ENV' environment!"
echo ""
echo "ArgoCD UI:    https://localhost:8080 (user: admin, password above)"
echo ""
exit 0
