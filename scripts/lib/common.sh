#!/usr/bin/env bash
# =============================================================================
# File: scripts/lib/common.sh
# Purpose: Common utilities - error handling, logging, state management
# =============================================================================

set -euo pipefail

# Error handling
error_exit() {
  echo "[ERROR] $1" >&2
  exit "${2:-1}"
}

# State tracking for --resume functionality
context_id() {
  local env_part="${ENV:-unknown}"
  local prov_part="${PROVIDER:-none}"
  local name_part="${CLUSTER_NAME:-}"
  local reg_part="${REGION:-}"
  local loc_part="${LOCATION:-}"
  if [[ -z "$name_part" ]]; then
    name_part="$(kubectl config current-context 2>/dev/null || echo unknown)"
  fi
  local key="${env_part}:${prov_part}:${name_part}:${reg_part}:${loc_part}"
  echo "${key// /_}"
}

state_setup() {
  if [[ ! -f "$STATE_FILE" ]]; then
    echo '{}' > "$STATE_FILE"
  fi
  local tmp
  tmp=$(mktemp -t ignite-state-XXXX.json)
  jq '(.runs //= {})' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

state_clear_context() {
  local ctx="$1"
  local tmp
  tmp=$(mktemp -t ignite-state-XXXX.json)
  jq --arg ctx "$ctx" '(.runs[$ctx]) = null | del(.runs[$ctx])' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

state_is_done() {
  local step="$1" ctx="$CONTEXT_ID"
  jq -e --arg ctx "$ctx" --arg step "$step" '.runs[$ctx].steps[$step].status == "done"' "$STATE_FILE" >/dev/null 2>&1
}

state_mark_done() {
  local step="$1" ctx="$CONTEXT_ID" ts
  ts=$(date -u +%FT%TZ)
  local tmp
  tmp=$(mktemp -t ignite-state-XXXX.json)
  jq --arg ctx "$ctx" --arg step "$step" --arg ts "$ts" '
    .runs[$ctx] //= {steps:{}} | .runs[$ctx].steps //= {} | .runs[$ctx].steps[$step] = {status:"done", ts:$ts}
  ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

run_step() {
  local step_name="$1"
  shift
  local fn="$1"
  shift || true
  if [[ ${RESUME:-0} -eq 1 ]] && state_is_done "$step_name"; then
    echo "⏭️  Skipping step '$step_name' (resume)"
    return 0
  fi
  "$fn" "$@"
  local rc=$?
  if [[ $rc -ne 0 ]]; then
    return $rc
  fi
  if [[ ${DRY_RUN:-0} -eq 0 ]]; then
    state_mark_done "$step_name"
  else
    echo "[DRY-RUN] Not marking step '$step_name' as done"
  fi
}

# Cleanup resources
cleanup_resources() {
  echo "🧹 Cleaning up ArgoCD and Fawkes namespaces..."
  kubectl delete namespace argocd --wait --ignore-not-found || true
  kubectl delete namespace fawkes --wait --ignore-not-found || true
  kubectl delete namespace jenkins --wait --ignore-not-found || true

  echo "🧹 Cleaning up Argo CD cluster-scoped resources (may be absent)..."
  local CRDS
  CRDS=$(kubectl get crd -o name 2>/dev/null | grep -E 'argoproj.io' || true)
  if [[ -n "$CRDS" ]]; then
    echo "$CRDS" | xargs kubectl delete --wait --ignore-not-found || true
  fi
  local CROLES
  CROLES=$(kubectl get clusterrole -o name 2>/dev/null | grep -E '^clusterrole/argocd' || true)
  if [[ -n "$CROLES" ]]; then
    echo "$CROLES" | xargs kubectl delete --wait --ignore-not-found || true
  fi
  local CRBINDINGS
  CRBINDINGS=$(kubectl get clusterrolebinding -o name 2>/dev/null | grep -E '^clusterrolebinding/argocd' || true)
  if [[ -n "$CRBINDINGS" ]]; then
    echo "$CRBINDINGS" | xargs kubectl delete --wait --ignore-not-found || true
  fi
  echo "✅ Cleanup complete."
}
