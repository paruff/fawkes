#!/bin/bash
set -e

NAMESPACE="${1:-fawkes-local}"

echo "🔍 Validating deployment in namespace: $NAMESPACE"

# Run BDD acceptance tests
echo "Running BDD tests..."
behave tests/bdd/features --tags=@local -D namespace="$NAMESPACE"

# Validate with kubectl
echo "Validating pods..."
kubectl get pods -n "$NAMESPACE" --field-selector=status.phase!=Running

if [ $? -eq 0 ]; then
  echo "❌ Some pods are not running"
  exit 1
fi

# Run policy checks
echo "Validating policies..."
kyverno apply manifests/overlays/local/ --policy policies/

echo "✅ All validations passed"