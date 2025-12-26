#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/validation.sh
# Purpose: Cluster and workload validation
# =============================================================================

set -euo pipefail

validate_cluster() {
  echo "🔎 Validating Kubernetes cluster health..."
  # API reachability
  if ! kubectl cluster-info >/dev/null 2>&1; then
    error_exit "Kubernetes API is not reachable with current context '$(kubectl config current-context 2>/dev/null || echo unknown)'."
  fi

  # Node readiness (wait up to 120s for at least one Ready node)
  local ready=0
  local end=$((SECONDS + 120))
  while [[ ${SECONDS} -lt ${end} ]]; do
    ready=$(kubectl get nodes -o json 2>/dev/null | jq -r '[.items[].status.conditions[] | select(.type=="Ready") | .status=="True"] | map(select(.==true)) | length' 2>/dev/null || echo 0)
    if [[ -n "$ready" && $ready -ge 1 ]]; then
      break
    fi
    sleep 3
  done
  if [[ -z "$ready" || $ready -lt 1 ]]; then
    kubectl get nodes -o wide || true
    error_exit "No Ready nodes detected after wait. Ensure your cluster has at least one Ready node."
  fi
  echo "✅ Nodes Ready: ${ready}"

  # StorageClass existence and default
  if ! kubectl get storageclass >/dev/null 2>&1; then
    error_exit "No StorageClass resources found. Configure a default StorageClass for dynamic provisioning."
  fi
  local has_default
  has_default=$(
    kubectl get storageclass -o json | jq -e '[.items[] | .metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true" or .metadata.annotations["storageclass.beta.kubernetes.io/is-default-class"]=="true"] | any' >/dev/null 2>&1
    echo $?
  )
  if [[ "$has_default" != "0" ]]; then
    echo "[WARN] No default StorageClass detected. Some workloads may fail to provision PersistentVolumes."
    echo "       Tip (minikube): minikube addons enable storage-provisioner default-storageclass"
  else
    local def_sc
    def_sc=$(kubectl get storageclass -o json | jq -r '.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"]=="true" or .metadata.annotations["storageclass.beta.kubernetes.io/is-default-class"]=="true").metadata.name' | head -n1)
    echo "✅ Default StorageClass: ${def_sc}"
  fi
}

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
    local pod
    pod=$(kubectl -n "${ns}" get pods --no-headers -o custom-columns=":metadata.name" | grep "^${name}" | head -n1 || true)
    if [[ -n "$pod" ]]; then
      local ready
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
