#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/providers/local.sh

set -euo pipefail
# Purpose: Local cluster provisioning (minikube, docker-desktop)
# =============================================================================


compute_minikube_resources() {
  local default_mem=8192
  local default_cpus=4
  local mem_mb="${MINIKUBE_MEMORY:-}"
  local cpus="${MINIKUBE_CPUS:-$default_cpus}"

  if [[ -z "$mem_mb" ]]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      local total_line total_val
      total_line=$(docker info 2>/dev/null | awk -F': ' '/Total Memory/ {print $2; exit}')
      if [[ -n "$total_line" ]]; then
        if [[ "$total_line" =~ ^([0-9]+\.[0-9]+|[0-9]+)GiB$ ]]; then
          total_val=${BASH_REMATCH[1]}
          mem_mb=$(awk -v v="$total_val" 'BEGIN { printf "%d", v*1024 }')
        elif [[ "$total_line" =~ ^([0-9]+)MiB$ ]]; then
          mem_mb=${BASH_REMATCH[1]}
        fi
        if [[ -n "${mem_mb}" ]]; then
          local safe_mb=$((mem_mb > 256 ? mem_mb - 256 : mem_mb))
          if ((safe_mb >= default_mem)); then
            mem_mb=$default_mem
          else
            mem_mb=$safe_mb
          fi
        fi
      fi
    fi
  fi

  if [[ -z "$mem_mb" || "$mem_mb" -lt 4096 ]]; then
    mem_mb=6144
  fi

  echo "${mem_mb}" "${cpus}"
}

compute_minikube_disk_size() {
  local default_disk="20g"
  local disk="${MINIKUBE_DISK_SIZE:-$default_disk}"
  echo "$disk"
}

detect_minikube_arch() {
  local m
  m=$(uname -m)
  case "$m" in
    arm64 | aarch64) echo "arm64" ;;
    x86_64 | amd64) echo "amd64" ;;
    *) echo "amd64" ;;
  esac
}

choose_minikube_driver() {
  if [[ -n "${MINIKUBE_DRIVER:-}" ]]; then
    echo "${MINIKUBE_DRIVER}"
    return 0
  fi
  local os="$(uname -s)"
  if [[ "$os" == "Darwin" ]]; then
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      echo "docker"
      return 0
    fi
    if minikube start --help 2>/dev/null | grep -q "vfkit"; then
      echo "vfkit"
      return 0
    fi
    if command -v qemu-system-x86_64 >/dev/null 2>&1 || command -v qemu-system-aarch64 >/dev/null 2>&1; then
      echo "qemu"
      return 0
    fi
    echo "docker"
    return 0
  else
    if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
      echo "docker"
      return 0
    fi
    if command -v qemu-system-x86_64 >/dev/null 2>&1; then
      echo "qemu"
      return 0
    fi
    echo "auto"
    return 0
  fi
}

use_first_reachable_local_context() {
  local contexts
  contexts=$(kubectl config get-contexts -o name 2>/dev/null || true)
  if [[ -z "$contexts" ]]; then return 1; fi
  local -a candidates=()
  if [[ ${PREFER_MINIKUBE:-0} -eq 1 ]]; then
    echo "$contexts" | grep -qx "minikube" && candidates+=("minikube")
    echo "$contexts" | grep -qx "docker-desktop" && candidates+=("docker-desktop")
  else
    echo "$contexts" | grep -qx "docker-desktop" && candidates+=("docker-desktop")
    echo "$contexts" | grep -qx "minikube" && candidates+=("minikube")
  fi
  while IFS= read -r ctx; do
    [[ "$ctx" == kind-* ]] && candidates+=("$ctx")
  done < <(echo "$contexts")
  echo "$contexts" | grep -qx "rancher-desktop" && candidates+=("rancher-desktop")
  echo "$contexts" | grep -qx "colima" && candidates+=("colima")

  local ctx
  for ctx in "${candidates[@]}"; do
    if kubectl --context "$ctx" cluster-info >/dev/null 2>&1; then
      if [[ ${DRY_RUN:-0} -eq 1 ]]; then
        echo "[DRY-RUN] Would use local Kubernetes context '$ctx'"
        return 0
      fi
      kubectl config use-context "$ctx" >/dev/null 2>&1 || true
      echo "Using local Kubernetes context '$ctx'."
      return 0
    fi
  done
  return 1
}

driver_extra_args() {
  local driver="$1"
  local -a args=()
  if minikube start --help 2>/dev/null | grep -q -- "--arch"; then
    local arch
    arch=$(detect_minikube_arch)
    args+=("--arch=${arch}")
  fi
  if [[ "$driver" == "qemu" ]]; then
    if command -v socket_vmnet >/dev/null 2>&1; then
      args+=("--network=socket_vmnet")
    else
      echo "[WARN] QEMU running without socket_vmnet; minikube service/tunnel may not work." >&2
    fi
  fi
  if ((${#args[@]} > 0)); then
    printf "%s " "${args[@]}"
  fi
}

provision_local_cluster() {
  if use_first_reachable_local_context; then
    return 0
  fi

  if ! command -v minikube >/dev/null 2>&1; then
    error_exit "minikube not installed and Docker Desktop K8s not reachable; install minikube or enable Docker Desktop Kubernetes."
  fi
  echo "Provisioning local cluster via minikube..."
  if [[ ${DRY_RUN:-0} -eq 1 ]]; then
    echo "[DRY-RUN] Would start minikube with computed resources and chosen driver."
    return 0
  fi
  local DRIVER
  DRIVER="$(choose_minikube_driver)"
  if command -v docker >/dev/null 2>&1 && ! docker info >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
    echo "Docker CLI found but daemon is not running. Attempting to start Docker Desktop..."
    open -a Docker || true
    echo "Waiting for Docker engine to become ready (up to 90s)..."
    local end=$((SECONDS + 90))
    until docker info >/dev/null 2>&1 || [[ ${SECONDS} -ge ${end} ]]; do sleep 3; done
    if docker info >/dev/null 2>&1; then echo "Docker engine is ready."; else echo "Docker engine not ready; will try other drivers."; fi
  fi
  if [[ "$DRIVER" == "docker" ]] && { ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; }; then
    echo "Docker driver selected but daemon not running; attempting anyway."
  fi
  local MEM CPUS DISK EXTRA_ARGS
  read MEM CPUS < <(compute_minikube_resources)
  EXTRA_ARGS=$(driver_extra_args "${DRIVER}")
  DISK=$(compute_minikube_disk_size)
  echo "Starting minikube (driver=${DRIVER}, memory=${MEM}MB, cpus=${CPUS}, disk=${DISK})..."
  # shellcheck disable=SC2086
  minikube start --driver="${DRIVER}" --memory="${MEM}" --cpus="${CPUS}" --disk-size="${DISK}" ${EXTRA_ARGS}
  kubectl config use-context minikube || true
}
