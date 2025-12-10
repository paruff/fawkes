#!/bin/bash
# ============================================================================
# FILE: platform/apps/ingress-nginx/validate.sh
# PURPOSE: Validation script for NGINX Ingress Controller deployment
# ============================================================================

set -e

echo "================================================"
echo "NGINX Ingress Controller Validation Script"
echo "================================================"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Namespace
NAMESPACE="ingress-nginx"
TEST_NAMESPACE="ingress-test"

# Functions
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅${NC} $1 is installed"
        return 0
    else
        echo -e "${RED}❌${NC} $1 is not installed"
        return 1
    fi
}

check_namespace() {
    if kubectl get namespace $1 &> /dev/null; then
        echo -e "${GREEN}✅${NC} Namespace $1 exists"
        return 0
    else
        echo -e "${YELLOW}⚠️${NC} Namespace $1 does not exist"
        return 1
    fi
}

check_pods() {
    local namespace=$1
    local label=$2
    local expected_count=$3
    
    actual_count=$(kubectl get pods -n $namespace -l $label --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
    
    if [ $actual_count -ge $expected_count ]; then
        echo -e "${GREEN}✅${NC} Pods running in namespace $namespace (label: $label): $actual_count/$expected_count"
        return 0
    else
        echo -e "${YELLOW}⚠️${NC} Pods running in namespace $namespace (label: $label): $actual_count/$expected_count"
        return 1
    fi
}

check_service() {
    local namespace=$1
    local service=$2
    
    if kubectl get service -n $namespace $service &> /dev/null; then
        echo -e "${GREEN}✅${NC} Service $service exists in namespace $namespace"
        
        # Check if LoadBalancer has external IP
        lb_ip=$(kubectl get svc -n $namespace $service -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$lb_ip" ]; then
            echo -e "${GREEN}✅${NC} LoadBalancer IP: $lb_ip"
        else
            echo -e "${YELLOW}⚠️${NC} LoadBalancer IP not assigned yet (may be pending)"
        fi
        return 0
    else
        echo -e "${YELLOW}⚠️${NC} Service $service does not exist in namespace $namespace"
        return 1
    fi
}

check_ingress() {
    local namespace=$1
    local ingress=$2
    
    if kubectl get ingress -n $namespace $ingress &> /dev/null; then
        echo -e "${GREEN}✅${NC} Ingress $ingress exists in namespace $namespace"
        
        # Check ingress address
        address=$(kubectl get ingress -n $namespace $ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null)
        if [ -n "$address" ]; then
            echo -e "${GREEN}✅${NC} Ingress address: $address"
        else
            echo -e "${YELLOW}⚠️${NC} Ingress address not assigned yet"
        fi
        return 0
    else
        echo -e "${YELLOW}⚠️${NC} Ingress $ingress does not exist in namespace $namespace"
        return 1
    fi
}

# Main validation
echo "1. Checking prerequisites..."
check_command kubectl || exit 1
echo ""

echo "2. Checking namespaces..."
check_namespace $NAMESPACE
check_namespace $TEST_NAMESPACE
echo ""

echo "3. Checking ingress controller pods..."
check_pods $NAMESPACE "app.kubernetes.io/component=controller" 1
check_pods $NAMESPACE "app.kubernetes.io/component=default-backend" 1
echo ""

echo "4. Checking services..."
check_service $NAMESPACE "ingress-nginx-controller"
check_service $NAMESPACE "ingress-nginx-controller-metrics"
check_service $NAMESPACE "ingress-nginx-defaultbackend"
echo ""

echo "5. Checking test resources (if deployed)..."
if check_namespace $TEST_NAMESPACE 2>/dev/null; then
    check_pods $TEST_NAMESPACE "app=echo-server" 1
    check_service $TEST_NAMESPACE "echo-server"
    check_ingress $TEST_NAMESPACE "echo-server"
    check_ingress $TEST_NAMESPACE "echo-server-tls"
else
    echo -e "${YELLOW}⚠️${NC} Test namespace not found. Run: kubectl apply -f test-ingress.yaml"
fi
echo ""

echo "6. Testing metrics endpoint..."
if kubectl get svc -n $NAMESPACE ingress-nginx-controller-metrics &> /dev/null; then
    echo -e "${GREEN}✅${NC} Metrics service available at: ingress-nginx-controller-metrics.ingress-nginx.svc.cluster.local:10254/metrics"
fi
echo ""

echo "================================================"
echo "Validation Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "1. Deploy test ingress: kubectl apply -f test-ingress.yaml"
echo "2. Get LoadBalancer IP: kubectl get svc -n ingress-nginx ingress-nginx-controller"
echo "3. Test HTTP: curl http://test.127.0.0.1.nip.io"
echo "4. Test HTTPS: curl -k https://test-tls.127.0.0.1.nip.io"
echo ""
