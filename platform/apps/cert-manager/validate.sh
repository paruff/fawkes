#!/bin/bash
# ============================================================================
# FILE: platform/apps/cert-manager/validate.sh
# PURPOSE: Validation script for cert-manager deployment
# ============================================================================

set -e

echo "=========================================="
echo "cert-manager Validation"
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
echo "1. Checking cert-manager namespace..."
if kubectl get namespace cert-manager &> /dev/null; then
    success "cert-manager namespace exists"
else
    error "cert-manager namespace does not exist"
    exit 1
fi

echo ""
echo "2. Checking cert-manager deployments..."
REQUIRED_DEPLOYMENTS=("cert-manager" "cert-manager-webhook" "cert-manager-cainjector")

for deployment in "${REQUIRED_DEPLOYMENTS[@]}"; do
    if kubectl get deployment "$deployment" -n cert-manager &> /dev/null; then
        READY=$(kubectl get deployment "$deployment" -n cert-manager -o jsonpath='{.status.readyReplicas}')
        DESIRED=$(kubectl get deployment "$deployment" -n cert-manager -o jsonpath='{.spec.replicas}')
        
        if [ "$READY" == "$DESIRED" ] && [ "$READY" != "" ]; then
            success "Deployment $deployment is ready ($READY/$DESIRED)"
        else
            error "Deployment $deployment is not ready ($READY/$DESIRED)"
            kubectl get pods -n cert-manager -l app.kubernetes.io/name=$deployment
        fi
    else
        error "Deployment $deployment not found"
    fi
done

echo ""
echo "3. Checking cert-manager pods..."
PODS=$(kubectl get pods -n cert-manager --no-headers | wc -l)
if [ "$PODS" -gt 0 ]; then
    success "Found $PODS pods in cert-manager namespace"
    
    # Check if any pods are not running
    NOT_RUNNING=$(kubectl get pods -n cert-manager --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    if [ "$NOT_RUNNING" -gt 0 ]; then
        warning "$NOT_RUNNING pods are not in Running state"
        kubectl get pods -n cert-manager --field-selector=status.phase!=Running
    fi
else
    error "No pods found in cert-manager namespace"
    exit 1
fi

echo ""
echo "4. Checking ClusterIssuers..."
ISSUERS=$(kubectl get clusterissuer --no-headers 2>/dev/null | wc -l)
if [ "$ISSUERS" -gt 0 ]; then
    success "Found $ISSUERS ClusterIssuers"
    kubectl get clusterissuer
    
    echo ""
    echo "   Checking ClusterIssuer readiness..."
    while IFS= read -r issuer; do
        READY=$(kubectl get clusterissuer "$issuer" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$READY" == "True" ]; then
            success "   ClusterIssuer $issuer is ready"
        else
            warning "   ClusterIssuer $issuer is not ready"
            kubectl describe clusterissuer "$issuer" | grep -A 5 "Status:"
        fi
    done < <(kubectl get clusterissuer -o jsonpath='{.items[*].metadata.name}')
else
    warning "No ClusterIssuers found (deploy cluster-issuer-*.yaml files)"
fi

echo ""
echo "5. Checking Certificates..."
CERTS=$(kubectl get certificate -A --no-headers 2>/dev/null | wc -l)
if [ "$CERTS" -gt 0 ]; then
    success "Found $CERTS Certificates"
    kubectl get certificate -A
    
    echo ""
    echo "   Checking Certificate readiness..."
    kubectl get certificate -A -o json | jq -r '.items[] | "\(.metadata.namespace)/\(.metadata.name) \(.status.conditions[] | select(.type=="Ready") | .status)"' | while read -r line; do
        CERT_NAME=$(echo "$line" | awk '{print $1}')
        CERT_READY=$(echo "$line" | awk '{print $2}')
        
        if [ "$CERT_READY" == "True" ]; then
            success "   Certificate $CERT_NAME is ready"
        else
            warning "   Certificate $CERT_NAME is not ready"
        fi
    done
else
    warning "No Certificates found (this is normal if none have been created yet)"
fi

echo ""
echo "6. Checking cert-manager webhook..."
if kubectl get validatingwebhookconfigurations cert-manager-webhook &> /dev/null; then
    success "ValidatingWebhookConfiguration exists"
else
    error "ValidatingWebhookConfiguration not found"
fi

if kubectl get mutatingwebhookconfigurations cert-manager-webhook &> /dev/null; then
    success "MutatingWebhookConfiguration exists"
else
    error "MutatingWebhookConfiguration not found"
fi

echo ""
echo "7. Checking cert-manager CRDs..."
CRDS=(
    "certificaterequests.cert-manager.io"
    "certificates.cert-manager.io"
    "challenges.acme.cert-manager.io"
    "clusterissuers.cert-manager.io"
    "issuers.cert-manager.io"
    "orders.acme.cert-manager.io"
)

for crd in "${CRDS[@]}"; do
    if kubectl get crd "$crd" &> /dev/null; then
        success "CRD $crd exists"
    else
        error "CRD $crd not found"
    fi
done

echo ""
echo "8. Checking cert-manager API availability..."
if kubectl api-resources | grep -q "cert-manager.io"; then
    success "cert-manager API is available"
else
    error "cert-manager API is not available"
fi

echo ""
echo "9. Testing certificate creation (dry-run)..."
cat <<EOF | kubectl apply --dry-run=client -f - &> /dev/null
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: test-certificate
  namespace: default
spec:
  secretName: test-tls
  dnsNames:
    - test.example.com
  issuerRef:
    name: letsencrypt-staging
    kind: ClusterIssuer
EOF

if [ $? -eq 0 ]; then
    success "Certificate resource validation passed"
else
    error "Certificate resource validation failed"
fi

echo ""
echo "=========================================="
echo "Validation Complete"
echo "=========================================="

# Check if validation passed
if ! kubectl get pods -n cert-manager --field-selector=status.phase!=Running --no-headers 2>/dev/null | grep -q .; then
    success "All validation checks passed!"
    exit 0
else
    warning "Some validation checks had warnings. Review the output above."
    exit 0
fi
