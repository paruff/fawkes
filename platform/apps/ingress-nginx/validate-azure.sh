#!/bin/bash
# ============================================================================
# FILE: platform/apps/ingress-nginx/validate-azure.sh
# PURPOSE: Validation script for Azure Load Balancer and Ingress deployment
# ============================================================================

set -e

echo "=========================================="
echo "Azure Load Balancer & Ingress Validation"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print success message
success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Function to print error message
error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to print warning message
warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

echo ""
echo "1. Checking ingress-nginx namespace..."
if kubectl get namespace ingress-nginx &> /dev/null; then
    success "ingress-nginx namespace exists"
else
    error "ingress-nginx namespace does not exist"
    exit 1
fi

echo ""
echo "2. Checking ingress-nginx controller deployment..."
if kubectl get deployment ingress-nginx-controller -n ingress-nginx &> /dev/null; then
    READY=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.replicas}')

    if [ "$READY" == "$DESIRED" ] && [ "$READY" != "" ]; then
        success "Deployment ingress-nginx-controller is ready ($READY/$DESIRED)"
    else
        error "Deployment ingress-nginx-controller is not ready ($READY/$DESIRED)"
        kubectl get pods -n ingress-nginx
        exit 1
    fi
else
    error "Deployment ingress-nginx-controller not found"
    exit 1
fi

echo ""
echo "3. Checking controller pods..."
PODS=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --no-headers | wc -l)
if [ "$PODS" -ge 2 ]; then
    success "Found $PODS controller pods (HA configuration)"
else
    warning "Found only $PODS controller pod(s). Expected at least 2 for HA"
fi

# Check if all pods are running
NOT_RUNNING=$(kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
if [ "$NOT_RUNNING" -eq 0 ]; then
    success "All controller pods are running"
else
    error "$NOT_RUNNING controller pod(s) are not running"
    kubectl get pods -n ingress-nginx -l app.kubernetes.io/component=controller
fi

echo ""
echo "4. Checking LoadBalancer service..."
if kubectl get svc ingress-nginx-controller -n ingress-nginx &> /dev/null; then
    SVC_TYPE=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.type}')

    if [ "$SVC_TYPE" == "LoadBalancer" ]; then
        success "Service type is LoadBalancer"
    else
        error "Service type is $SVC_TYPE, expected LoadBalancer"
    fi

    # Check for external IP
    echo "   Checking for external IP assignment..."
    EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

    if [ -n "$EXTERNAL_IP" ]; then
        success "External IP assigned: $EXTERNAL_IP"
    else
        warning "External IP not yet assigned (this may take a few minutes)"
    fi
else
    error "Service ingress-nginx-controller not found"
    exit 1
fi

echo ""
echo "5. Checking Azure Load Balancer annotations..."
HEALTH_PROBE=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.metadata.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path}')

if [ "$HEALTH_PROBE" == "/healthz" ]; then
    success "Azure Load Balancer health probe configured: $HEALTH_PROBE"
else
    warning "Azure Load Balancer health probe annotation not found or incorrect"
fi

echo ""
echo "6. Checking external traffic policy..."
TRAFFIC_POLICY=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.externalTrafficPolicy}')

if [ "$TRAFFIC_POLICY" == "Local" ]; then
    success "External traffic policy is Local (recommended for Azure)"
else
    warning "External traffic policy is $TRAFFIC_POLICY (recommended: Local)"
fi

echo ""
echo "7. Checking IngressClass..."
if kubectl get ingressclass nginx &> /dev/null; then
    success "IngressClass 'nginx' exists"

    IS_DEFAULT=$(kubectl get ingressclass nginx -o jsonpath='{.metadata.annotations.ingressclass\.kubernetes\.io/is-default-class}')
    if [ "$IS_DEFAULT" == "true" ]; then
        success "IngressClass 'nginx' is set as default"
    else
        warning "IngressClass 'nginx' is not set as default"
    fi
else
    error "IngressClass 'nginx' not found"
fi

echo ""
echo "8. Checking controller configuration..."
CONFIG_MAP=$(kubectl get configmap ingress-nginx-controller -n ingress-nginx -o jsonpath='{.data}' 2>/dev/null)

if [ -n "$CONFIG_MAP" ]; then
    success "Controller ConfigMap exists"

    # Check important settings
    SSL_REDIRECT=$(echo "$CONFIG_MAP" | grep -o '"ssl-redirect":"[^"]*"' | cut -d'"' -f4)
    if [ "$SSL_REDIRECT" == "true" ]; then
        success "   SSL redirect is enabled"
    else
        warning "   SSL redirect is disabled"
    fi

    HSTS=$(echo "$CONFIG_MAP" | grep -o '"hsts":"[^"]*"' | cut -d'"' -f4)
    if [ "$HSTS" == "true" ]; then
        success "   HSTS is enabled"
    else
        warning "   HSTS is disabled"
    fi
else
    warning "Controller ConfigMap not found or empty"
fi

echo ""
echo "9. Checking Prometheus metrics..."
METRICS_SVC=$(kubectl get svc ingress-nginx-controller-metrics -n ingress-nginx --no-headers 2>/dev/null | wc -l)

if [ "$METRICS_SVC" -gt 0 ]; then
    success "Metrics service exists"

    # Check if ServiceMonitor exists
    if kubectl get servicemonitor ingress-nginx-controller -n ingress-nginx &> /dev/null 2>&1; then
        success "ServiceMonitor exists for Prometheus"
    else
        warning "ServiceMonitor not found (requires Prometheus Operator)"
    fi
else
    warning "Metrics service not found"
fi

echo ""
echo "10. Checking HorizontalPodAutoscaler..."
if kubectl get hpa ingress-nginx-controller -n ingress-nginx &> /dev/null 2>&1; then
    success "HorizontalPodAutoscaler is configured"

    MIN_REPLICAS=$(kubectl get hpa ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.minReplicas}')
    MAX_REPLICAS=$(kubectl get hpa ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.maxReplicas}')

    success "   Autoscaling: min=$MIN_REPLICAS, max=$MAX_REPLICAS"
else
    warning "HorizontalPodAutoscaler not configured"
fi

echo ""
echo "11. Checking default backend..."
if kubectl get deployment ingress-nginx-defaultbackend -n ingress-nginx &> /dev/null 2>&1; then
    success "Default backend deployment exists"
else
    warning "Default backend deployment not found (optional)"
fi

echo ""
echo "12. Checking resource requests and limits..."
RESOURCES=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.containers[0].resources}')

if [ -n "$RESOURCES" ]; then
    success "Resource requests and limits are configured"

    CPU_REQUEST=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}')
    MEM_REQUEST=$(kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.containers[0].resources.requests.memory}')

    success "   CPU request: $CPU_REQUEST"
    success "   Memory request: $MEM_REQUEST"
else
    warning "Resource requests and limits not configured"
fi

echo ""
echo "13. Testing controller health endpoint..."
if [ -n "$EXTERNAL_IP" ]; then
    # Try to port-forward and check health
    echo "   Testing via port-forward..."
    kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8080:80 &> /dev/null &
    PF_PID=$!
    sleep 3

    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/healthz 2>/dev/null | grep -q "200\|404"; then
        success "Controller is responding to HTTP requests"
    else
        warning "Controller health check failed (this is normal if no ingress resources exist yet)"
    fi

    kill $PF_PID 2>/dev/null || true
fi

echo ""
echo "14. Checking Azure resources (if Azure CLI is available)..."
if command -v az &> /dev/null; then
    # Get node resource group
    NODE_RG=$(kubectl get nodes -o jsonpath='{.items[0].spec.providerID}' | cut -d'/' -f5)

    if [ -n "$NODE_RG" ]; then
        echo "   Node resource group: $NODE_RG"

        # Check for Load Balancer
        LB_COUNT=$(az network lb list --resource-group "$NODE_RG" --output table 2>/dev/null | grep -c "kubernetes" || true)

        if [ "$LB_COUNT" -gt 0 ]; then
            success "Azure Load Balancer found in resource group $NODE_RG"
        else
            warning "Azure Load Balancer not found (may not have permissions to query)"
        fi
    fi
else
    warning "Azure CLI not available, skipping Azure resource checks"
fi

echo ""
echo "=========================================="
echo "Validation Complete"
echo "=========================================="

# Summary
echo ""
echo "Summary:"
echo "--------"
kubectl get all -n ingress-nginx

echo ""
echo "To test the ingress controller, deploy the test ingress:"
echo "  kubectl apply -f test-ingress.yaml"
echo ""
echo "To get the external IP:"
echo "  kubectl get svc ingress-nginx-controller -n ingress-nginx"
echo ""
echo "To view logs:"
echo "  kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller --tail=50"
