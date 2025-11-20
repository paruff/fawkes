#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="fawkes"

# Check for required tools
for tool in helm kubectl; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed or not in PATH."
    exit 1
  fi
done

# Create namespace if it doesn't exist
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
  kubectl create namespace "$NAMESPACE"
fi

# Function to add a Helm repo only if it doesn't already exist
add_helm_repo() {
  local name="$1"
  local url="$2"
  if ! helm repo list | grep -q "^$name"; then
    #!/usr/bin/env bash
    set -euo pipefail

    echo "[DEPRECATED] scripts/buildplatform.sh has been replaced by scripts/ignite.sh"
    echo "Use: ./scripts/ignite.sh --provider <local|aws|azure|gcp> <environment>"
    exit 2
test_chart apache-devlake

echo "Helm tests completed for all platform components in the '$NAMESPACE' namespace."

