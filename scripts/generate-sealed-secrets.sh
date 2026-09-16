#!/usr/bin/env bash
# =============================================================================
# generate-sealed-secrets.sh
# Convert plaintext Kubernetes Secrets to SealedSecrets using kubeseal.
#
# Usage:
#   ./scripts/generate-sealed-secrets.sh [namespace]
#
# Prerequisites:
#   - kubeseal installed (https://github.com/bitnami-labs/sealed-secrets)
#   - Access to the cluster's sealed-secrets controller (for the sealing key)
#
# This script finds all secrets.yaml files under platform/ that contain
# CHANGE_ME_* placeholders, prompts for actual values, and generates
# corresponding SealedSecret YAML files.
# =============================================================================

set -euo pipefail

NAMESPACE="${1:-fawkes}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLATFORM_DIR="${REPO_ROOT}/platform"

echo "=== Fawkes Sealed Secrets Generator ==="
echo "Namespace: ${NAMESPACE}"
echo "Platform dir: ${PLATFORM_DIR}"
echo ""

# Check kubeseal is installed
if ! command -v kubeseal &> /dev/null; then
  echo "ERROR: kubeseal not found. Install it from:"
  echo "  https://github.com/bitnami-labs/sealed-secrets#installation"
  exit 1
fi

# Find secrets files with CHANGE_ME values
CHANGE_ME_FILES=()
while IFS= read -r file; do
  CHANGE_ME_FILES+=("$file")
done < <(grep -rl "CHANGE_ME" "${PLATFORM_DIR}" --include="*.yaml" --include="*.yml" 2> /dev/null | grep -v sealed | grep -v CHANGELOG || true)

if [ ${#CHANGE_ME_FILES[@]} -eq 0 ]; then
  echo "No secrets files with CHANGE_ME_* values found. Nothing to do."
  exit 0
fi

echo "Found ${#CHANGE_ME_FILES[@]} secrets files with CHANGE_ME_* values:"
for f in "${CHANGE_ME_FILES[@]}"; do
  echo "  - ${f#${REPO_ROOT}/}"
done
echo ""

echo "To generate SealedSecrets:"
echo "  1. Replace CHANGE_ME_* values with actual secrets in each file"
echo "  2. Run: kubeseal --controller-name=sealed-secrets --controller-namespace=kube-system --format yaml < secrets.yaml > secrets-sealed.yaml"
echo "  3. Or use this script interactively (requires cluster access)"
echo ""

read -p "Do you have cluster access and want to generate SealedSecrets now? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted. Replace CHANGE_ME_* values manually and seal with kubeseal."
  exit 0
fi

for file in "${CHANGE_ME_FILES[@]}"; do
  echo ""
  echo "--- Processing: ${file#${REPO_ROOT}/} ---"

  # Determine output path (add -sealed suffix before .yaml)
  dir=$(dirname "$file")
  basename=$(basename "$file" .yaml)
  sealed_file="${dir}/${basename}-sealed.yaml"

  if [ -f "$sealed_file" ]; then
    echo "  SealedSecret already exists: ${sealed_file#${REPO_ROOT}/}"
    read -p "  Overwrite? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
      echo "  Skipping."
      continue
    fi
  fi

  echo "  Sealing ${file#${REPO_ROOT}/} -> ${sealed_file#${REPO_ROOT}/}"
  kubeseal \
    --controller-name=sealed-secrets \
    --controller-namespace=kube-system \
    --namespace="${NAMESPACE}" \
    --format yaml \
    < "$file" > "$sealed_file"

  echo "  Done. Verify the SealedSecret and commit ${sealed_file#${REPO_ROOT}/}"
done

echo ""
echo "=== Complete ==="
echo "Next steps:"
echo "  1. Review generated SealedSecret files"
echo "  2. Remove CHANGE_ME_* plaintext secrets (or move to .gitignore)"
echo "  3. Commit the SealedSecret files"
echo "  4. Run: python -m pytest tests/test_sealed_secrets.py -v"
