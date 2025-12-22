#!/bin/bash
# Validation script for AI Code Review Service deployment

set -e

NAMESPACE="${NAMESPACE:-fawkes}"
SERVICE_NAME="ai-code-review"

echo "=================================="
echo "AI Code Review Service Validation"
echo "=================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}✗ kubectl not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ kubectl found${NC}"

# Check namespace exists
echo -n "Checking namespace ${NAMESPACE}... "
if kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✓ exists${NC}"
else
    echo -e "${RED}✗ not found${NC}"
    exit 1
fi

# Check deployment
echo -n "Checking deployment... "
if kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} &> /dev/null; then
    REPLICAS=$(kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.status.availableReplicas}')
    DESIRED=$(kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.replicas}')
    
    if [ "$REPLICAS" == "$DESIRED" ]; then
        echo -e "${GREEN}✓ ${REPLICAS}/${DESIRED} replicas ready${NC}"
    else
        echo -e "${YELLOW}⚠ ${REPLICAS}/${DESIRED} replicas ready${NC}"
    fi
else
    echo -e "${RED}✗ not found${NC}"
    exit 1
fi

# Check pods
echo "Checking pods:"
kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME}

# Check service
echo -n "Checking service... "
if kubectl get service ${SERVICE_NAME} -n ${NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✓ exists${NC}"
else
    echo -e "${RED}✗ not found${NC}"
    exit 1
fi

# Check configmap
echo -n "Checking configmap... "
if kubectl get configmap ${SERVICE_NAME}-config -n ${NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✓ exists${NC}"
else
    echo -e "${YELLOW}⚠ not found${NC}"
fi

# Check secret
echo -n "Checking secrets... "
if kubectl get secret ${SERVICE_NAME}-secrets -n ${NAMESPACE} &> /dev/null; then
    echo -e "${GREEN}✓ exists${NC}"
    
    # Check if secrets are configured (not default "changeme")
    SECRET_DATA=$(kubectl get secret ${SERVICE_NAME}-secrets -n ${NAMESPACE} -o jsonpath='{.data.GITHUB_TOKEN}' | base64 -d)
    if [ "$SECRET_DATA" == "changeme" ]; then
        echo -e "${YELLOW}⚠ WARNING: Secrets still set to default 'changeme'${NC}"
    fi
else
    echo -e "${RED}✗ not found${NC}"
    exit 1
fi

# Check service health
echo -n "Checking service health... "
POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l app=${SERVICE_NAME} -o jsonpath='{.items[0].metadata.name}')

if [ -n "$POD_NAME" ]; then
    HEALTH_STATUS=$(kubectl exec -n ${NAMESPACE} ${POD_NAME} -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health || echo "000")
    
    if [ "$HEALTH_STATUS" == "200" ]; then
        echo -e "${GREEN}✓ healthy${NC}"
    else
        echo -e "${RED}✗ unhealthy (HTTP ${HEALTH_STATUS})${NC}"
    fi
else
    echo -e "${RED}✗ no pods running${NC}"
fi

# Check readiness
echo -n "Checking service readiness... "
if [ -n "$POD_NAME" ]; then
    READY_STATUS=$(kubectl exec -n ${NAMESPACE} ${POD_NAME} -- curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/ready || echo "000")
    
    if [ "$READY_STATUS" == "200" ]; then
        echo -e "${GREEN}✓ ready${NC}"
    elif [ "$READY_STATUS" == "503" ]; then
        echo -e "${YELLOW}⚠ not ready (check configuration)${NC}"
    else
        echo -e "${RED}✗ error (HTTP ${READY_STATUS})${NC}"
    fi
fi

# Check recent logs for errors
echo ""
echo "Recent logs (last 20 lines):"
echo "----------------------------"
kubectl logs -n ${NAMESPACE} -l app=${SERVICE_NAME} --tail=20

echo ""
echo "=================================="
echo "Validation Summary"
echo "=================================="

# Final status
if kubectl get deployment ${SERVICE_NAME} -n ${NAMESPACE} &> /dev/null && \
   [ "$REPLICAS" == "$DESIRED" ] && \
   [ "$HEALTH_STATUS" == "200" ]; then
    echo -e "${GREEN}✓ AI Code Review Service is running and healthy${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠ Service has issues - review output above${NC}"
    exit 1
fi
