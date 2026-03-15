#!/usr/bin/env bash
# =============================================================================
# dev-down.sh — cleanly tear down the Fawkes local environment
#
# Deletes the k3d cluster created by dev-up.sh.
# Usage: ./scripts/dev-down.sh  (or: make dev-down)
# =============================================================================
set -euo pipefail

CLUSTER_NAME="${FAWKES_CLUSTER:-fawkes-dev}"

log() { echo "$(date -u +%H:%M:%S) $*"; }

log "🗑️   Tearing down Fawkes local environment (cluster: ${CLUSTER_NAME})"

if ! command -v k3d &>/dev/null; then
  echo "❌  k3d not found — nothing to tear down"
  exit 1
fi

if k3d cluster list 2>/dev/null | grep -q "^${CLUSTER_NAME} "; then
  k3d cluster delete "${CLUSTER_NAME}"
  log "✅  Cluster '${CLUSTER_NAME}' deleted"
else
  log "⚠️   Cluster '${CLUSTER_NAME}' not found — nothing to delete"
fi
