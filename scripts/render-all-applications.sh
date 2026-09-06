#!/usr/bin/env bash
# render-all-applications.sh - #1842's "render every Application in CI" gate.
#
# The pre-existing argocd-validate pre-commit hook this replaces called
# `argocd app validate` (a client-side Application-CR schema check that
# never fetches or renders the underlying chart/kustomize source) and
# swallowed every failure into a warning echo - it never once failed a
# build. Six real defects this project (a dead chart repo domain, a
# fictional Helm values schema, an impossible securityContext, RBAC that
# couldn't grant what it claimed, a numeric-vs-string UID mismatch, a
# duplicate env key) were all in config exactly this broken hook was
# supposed to catch, and didn't.
#
# This script actually fetches and renders each Application's real source
# (helm template for a chart, kustomize build / kubectl kustomize for a
# path) and fails loudly on the first error - matching AGENTS.md's rule
# against silently-caught failures in a check or validator.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FAILED=0
CHECKED=0

render_chart() {
  local file="$1" repo_url="$2" chart="$3" revision="$4" values_file="$5"
  local chart_ref

  if [[ "$repo_url" == oci://* ]]; then
    # For an OCI source, repoURL is already the complete chart reference
    # (ArgoCD's own convention) - `chart` is redundant, unlike an HTTP(S)
    # chart repo where repoURL is the repo root and chart names a sub-chart
    # within it. Appending `chart` here doubled the path and 401'd against
    # a nonexistent reference (found live: sealed-secrets's repoURL is
    # oci://registry-1.docker.io/bitnamicharts/sealed-secrets, not a repo
    # root with sealed-secrets as a sub-chart).
    chart_ref="$repo_url"
  else
    local tmp_repo="render-check-$(echo "$repo_url" | md5sum | cut -c1-8)"
    if ! helm repo add "$tmp_repo" "$repo_url" > /dev/null 2>&1; then
      echo "❌ $file: could not add chart repo $repo_url"
      return 1
    fi
    helm repo update "$tmp_repo" > /dev/null 2>&1 || true
    chart_ref="$tmp_repo/$chart"
  fi

  if ! helm template render-check "$chart_ref" --version "$revision" \
    -f "$values_file" > /dev/null 2> /tmp/render-check-err.log; then
    echo "❌ $file: helm template failed for chart=$chart version=$revision"
    sed 's/^/    /' /tmp/render-check-err.log
    return 1
  fi
  return 0
}

render_path() {
  local file="$1" path="$2"
  local full_path="${ROOT_DIR}/${path}"
  if [ ! -d "$full_path" ]; then
    echo "❌ $file: source path $path does not exist"
    return 1
  fi
  if [ -f "${full_path}/kustomization.yaml" ] || [ -f "${full_path}/kustomization.yml" ]; then
    if ! kubectl kustomize "$full_path" > /dev/null 2> /tmp/render-check-err.log; then
      echo "❌ $file: kustomize build failed for path=$path"
      sed 's/^/    /' /tmp/render-check-err.log
      return 1
    fi
  fi
  # A path with no kustomization.yaml is a plain-manifest directory ArgoCD
  # applies as-is - nothing to render/fail here beyond the existence check
  # above, which already covers the one real failure mode (a stale path).
  return 0
}

while IFS= read -r file; do
  CHECKED=$((CHECKED + 1))
  repo_url=$(yq -r '.spec.source.repoURL // ""' "$file")
  chart=$(yq -r '.spec.source.chart // ""' "$file")
  revision=$(yq -r '.spec.source.targetRevision // ""' "$file")
  path=$(yq -r '.spec.source.path // ""' "$file")

  if [ -n "$chart" ]; then
    values_file=$(mktemp)
    yq -r '.spec.source.helm.values // ""' "$file" > "$values_file"
    if ! render_chart "$file" "$repo_url" "$chart" "$revision" "$values_file"; then
      FAILED=$((FAILED + 1))
    fi
    rm -f "$values_file"
  elif [ -n "$path" ]; then
    if ! render_path "$file" "$path"; then
      FAILED=$((FAILED + 1))
    fi
  else
    echo "❌ $file: spec.source has neither chart nor path set"
    FAILED=$((FAILED + 1))
  fi
done < <(find "${ROOT_DIR}/platform/apps" -name "*-application.yaml" 2> /dev/null | sort)

echo ""
echo "Rendered $CHECKED Application sources, $FAILED failed."
if [ "$FAILED" -gt 0 ]; then
  exit 1
fi
