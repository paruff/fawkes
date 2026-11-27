#!/usr/bin/env bash
# Install Argo CD on the lab cluster and hand everything else to Git (platform/lab).
# Usage: scripts/lab-up.sh            (LAB_CONTEXT=mmm4)
#        LAB_REVISION=my-branch scripts/lab-up.sh   # try a branch before it merges
set -euo pipefail

CONTEXT="${LAB_CONTEXT:-mmm4}"
CHART_VERSION="10.20.0" # Argo CD v3.6.3
REVISION="${LAB_REVISION:-}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

case "$CONTEXT" in
  *aks*)
    echo "refusing to run against $CONTEXT: this script is for the lab only" >&2
    exit 1
    ;;
esac

helm upgrade --install argocd argo-cd --repo https://argoproj.github.io/argo-helm \
  --kube-context "$CONTEXT" --version "$CHART_VERSION" \
  --namespace argocd --create-namespace \
  --set configs.params."server\.insecure"=true \
  --set configs.params."applicationsetcontroller\.enable\.policy\.override"=true \
  --set dex.enabled=false --set notifications.enabled=false \
  --wait --timeout 10m

if [ -z "$REVISION" ]; then
  kubectl --context "$CONTEXT" apply -f "$ROOT/platform/lab/root-application.yaml"
else
  # A root Application would sync main over the branch, so apply the ApplicationSets directly.
  kubectl kustomize "$ROOT/platform/lab" \
    | sed "s|revision: HEAD|revision: $REVISION|" \
    | kubectl --context "$CONTEXT" apply -f -
fi
