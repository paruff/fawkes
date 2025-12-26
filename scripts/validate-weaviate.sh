#!/bin/bash
# Validation script for Weaviate deployment
# Usage: ./scripts/validate-weaviate.sh [--namespace NAMESPACE]

set -euo pipefail

NAMESPACE="${NAMESPACE:-fawkes}"

echo "========================================================================"
echo "Weaviate Deployment Validation"
echo "========================================================================"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --namespace)
      NAMESPACE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "Namespace: ${NAMESPACE}"
echo ""

# Check if namespace exists
echo "1. Checking namespace..."
if kubectl get namespace "${NAMESPACE}" &> /dev/null; then
  echo "   ✅ Namespace '${NAMESPACE}' exists"
else
  echo "   ❌ Namespace '${NAMESPACE}' does not exist"
  exit 1
fi

# Check ArgoCD Application
echo ""
echo "2. Checking ArgoCD Application..."
if kubectl get application weaviate -n "${NAMESPACE}" &> /dev/null; then
  echo "   ✅ ArgoCD Application 'weaviate' exists"

  # Check sync status
  SYNC_STATUS=$(kubectl get application weaviate -n "${NAMESPACE}" -o jsonpath='{.status.sync.status}')
  HEALTH_STATUS=$(kubectl get application weaviate -n "${NAMESPACE}" -o jsonpath='{.status.health.status}')

  echo "   Sync Status: ${SYNC_STATUS}"
  echo "   Health Status: ${HEALTH_STATUS}"
else
  echo "   ⚠️  ArgoCD Application 'weaviate' not found (may not be deployed yet)"
fi

# Check Weaviate pod
echo ""
echo "3. Checking Weaviate pods..."
if kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=weaviate &> /dev/null; then
  POD_COUNT=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=weaviate --no-headers | wc -l)
  RUNNING_COUNT=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=weaviate --field-selector=status.phase=Running --no-headers | wc -l)

  echo "   Total pods: ${POD_COUNT}"
  echo "   Running pods: ${RUNNING_COUNT}"

  if [ "${RUNNING_COUNT}" -gt 0 ]; then
    echo "   ✅ Weaviate pod(s) are running"
  else
    echo "   ⚠️  No running Weaviate pods"
  fi

  # Show pod details
  echo ""
  kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=weaviate
else
  echo "   ⚠️  No Weaviate pods found (may not be deployed yet)"
fi

# Check Weaviate service
echo ""
echo "4. Checking Weaviate service..."
if kubectl get service weaviate -n "${NAMESPACE}" &> /dev/null; then
  echo "   ✅ Weaviate service exists"

  # Show service details
  CLUSTER_IP=$(kubectl get service weaviate -n "${NAMESPACE}" -o jsonpath='{.spec.clusterIP}')
  PORT=$(kubectl get service weaviate -n "${NAMESPACE}" -o jsonpath='{.spec.ports[0].port}')

  echo "   Cluster IP: ${CLUSTER_IP}"
  echo "   Port: ${PORT}"
else
  echo "   ⚠️  Weaviate service not found"
fi

# Check PVC
echo ""
echo "5. Checking Persistent Volume Claim..."
if kubectl get pvc -n "${NAMESPACE}" | grep -q weaviate; then
  echo "   ✅ Weaviate PVC exists"
  kubectl get pvc -n "${NAMESPACE}" | grep weaviate
else
  echo "   ⚠️  Weaviate PVC not found (may not be deployed yet)"
fi

# Check if Weaviate is accessible
echo ""
echo "6. Testing Weaviate accessibility..."
if kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=weaviate --field-selector=status.phase=Running &> /dev/null; then
  POD_NAME=$(kubectl get pods -n "${NAMESPACE}" -l app.kubernetes.io/name=weaviate --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')

  if [ -n "${POD_NAME}" ]; then
    echo "   Testing via pod ${POD_NAME}..."

    # Test health endpoint
    if kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- curl -s -f http://localhost:8080/v1/.well-known/ready &> /dev/null; then
      echo "   ✅ Weaviate is ready"
    else
      echo "   ⚠️  Weaviate health check failed"
    fi

    # Test meta endpoint
    if kubectl exec -n "${NAMESPACE}" "${POD_NAME}" -- curl -s -f http://localhost:8080/v1/meta &> /dev/null; then
      echo "   ✅ Weaviate meta endpoint accessible"
    else
      echo "   ⚠️  Weaviate meta endpoint not accessible"
    fi
  else
    echo "   ⚠️  No running pod found to test"
  fi
else
  echo "   ⚠️  Cannot test - no running pods"
fi

echo ""
echo "========================================================================"
echo "Validation Summary"
echo "========================================================================"
echo ""
echo "Next Steps:"
echo "1. If Weaviate is not deployed, apply the ArgoCD application:"
echo "   kubectl apply -f platform/apps/weaviate-application.yaml"
echo ""
echo "2. Wait for deployment to complete:"
echo "   kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=weaviate -n ${NAMESPACE} --timeout=300s"
echo ""
echo "3. Port-forward to test locally:"
echo "   kubectl port-forward -n ${NAMESPACE} svc/weaviate 8080:80"
echo ""
echo "4. Run the test indexing script:"
echo "   python services/rag/scripts/test-indexing.py"
echo ""
echo "========================================================================"
