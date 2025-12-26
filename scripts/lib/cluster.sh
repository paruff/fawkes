#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/cluster.sh

set -euo pipefail
# Purpose: Cluster provisioning orchestration
# =============================================================================


provision_cluster() {
  if [[ -n "${PROVIDER}" ]]; then
    case "${PROVIDER}" in
      local)
        provision_local_cluster
        ;;
      aws)
        provision_aws_cluster
        ;;
      azure)
        provision_azure_cluster
        ;;
      gcp)
        provision_gcp_cluster
        ;;
      *)
        error_exit "Unhandled provider '${PROVIDER}'"
        ;;
    esac
    echo "✅ Kubernetes context set and reachable."
    return 0
  fi
  
  echo "🔍 Checking available Kubernetes contexts..."
  kubectl config get-contexts || true
  local ACTIVE_CONTEXT
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
      if [[ "${ENV}" == "local" ]]; then
        provision_local_cluster
      else
        error_exit "Current context not reachable. Aborting."
      fi
    fi
  else
    if [[ "${ENV}" == "local" ]]; then
      provision_local_cluster
    else
      error_exit "No active Kubernetes context found. Configure kubectl and try again."
    fi
  fi
  echo "✅ Kubernetes context set and reachable."
}
