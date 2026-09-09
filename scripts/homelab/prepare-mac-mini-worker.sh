#!/usr/bin/env bash
# =============================================================================
# File: scripts/homelab/prepare-mac-mini-worker.sh
# Purpose: Prepare a bare macOS machine (e.g. Mac Mini) to join a multi-node
#          k3s cluster as a worker. Tracked under issue #1922 (moving local
#          k8s dev off a single MacBook onto a multi-machine pool).
#
# macOS has no Linux kernel, so k3s can't run natively here - this creates a
# lightweight Lima VM (Ubuntu) and installs the k3s agent inside it.
#
# Run directly on the target Mac (or: ssh mac-mini 'bash -s' < this-script).
#
# Usage:
#   K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<token> ./prepare-mac-mini-worker.sh
#
# If K3S_URL/K3S_TOKEN are not set, the script stops after provisioning the
# VM and prints the join command to run once the k3s server exists.
# =============================================================================
set -euo pipefail

VM_NAME="k3s-worker"
VM_CPUS=4
VM_MEMORY=6
VM_DISK=30

echo "== Homebrew =="
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew (non-interactive)..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew already installed."
fi

echo "== Lima =="
if ! command -v limactl &> /dev/null; then
  brew install lima
else
  echo "Lima already installed."
fi

echo "== Lima VM (${VM_NAME}) =="
if limactl list --format '{{.Name}}' 2> /dev/null | grep -qx "${VM_NAME}"; then
  echo "VM ${VM_NAME} already exists."
  limactl start "${VM_NAME}" 2> /dev/null || true
else
  limactl start --name="${VM_NAME}" \
    --cpus="${VM_CPUS}" --memory="${VM_MEMORY}" --disk="${VM_DISK}" \
    template://ubuntu-lts --tty=false
fi

echo "== k3s agent inside ${VM_NAME} =="
if limactl shell "${VM_NAME}" -- sh -c 'command -v k3s' &> /dev/null; then
  echo "k3s already installed in ${VM_NAME}."
elif [[ -n "${K3S_URL:-}" && -n "${K3S_TOKEN:-}" ]]; then
  limactl shell "${VM_NAME}" -- sh -c \
    "curl -sfL https://get.k3s.io | K3S_URL='${K3S_URL}' K3S_TOKEN='${K3S_TOKEN}' sh -s - agent"
  echo "k3s agent installed and joined ${K3S_URL}."
else
  echo "VM ready. K3S_URL/K3S_TOKEN not set - skipping join."
  echo "Once the k3s server exists, run:"
  echo "  K3S_URL=https://<server-ip>:6443 K3S_TOKEN=<token> $0"
fi

echo "== Done =="
limactl list
