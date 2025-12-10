#!/bin/bash
# ============================================================================
# FILE: platform/apps/ingress-nginx/generate-test-cert.sh
# PURPOSE: Generate self-signed TLS certificate for testing ingress
# ============================================================================

set -e

echo "================================================"
echo "Generate Self-Signed TLS Certificate"
echo "================================================"
echo ""

# Configuration
NAMESPACE="ingress-test"
SECRET_NAME="echo-server-tls"
CERT_SUBJECT="/C=US/ST=Test-State/O=Test Org/CN=*.127.0.0.1.nip.io"
DAYS_VALID=365

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "This script will generate a self-signed TLS certificate for testing."
echo "The certificate will be valid for: *.127.0.0.1.nip.io"
echo "Validity period: ${DAYS_VALID} days"
echo ""

# Check if openssl is installed
if ! command -v openssl &> /dev/null; then
    echo -e "${YELLOW}Error: openssl is not installed${NC}"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${YELLOW}Error: kubectl is not installed${NC}"
    exit 1
fi

# Create temporary directory
TEMP_DIR=$(mktemp -d)
trap "rm -rf ${TEMP_DIR}" EXIT

echo "Generating certificate in temporary directory: ${TEMP_DIR}"
echo ""

# Generate private key and certificate
openssl req -x509 -nodes -days ${DAYS_VALID} \
    -newkey rsa:2048 \
    -keyout "${TEMP_DIR}/tls.key" \
    -out "${TEMP_DIR}/tls.crt" \
    -subj "${CERT_SUBJECT}" \
    -addext "subjectAltName=DNS:*.127.0.0.1.nip.io,DNS:test.127.0.0.1.nip.io,DNS:test-tls.127.0.0.1.nip.io"

echo -e "${GREEN}✅ Certificate generated successfully${NC}"
echo ""

# Create namespace if it doesn't exist
if ! kubectl get namespace "${NAMESPACE}" &> /dev/null; then
    echo "Creating namespace: ${NAMESPACE}"
    kubectl create namespace "${NAMESPACE}"
    echo -e "${GREEN}✅ Namespace created${NC}"
else
    echo -e "${GREEN}✅ Namespace ${NAMESPACE} already exists${NC}"
fi
echo ""

# Delete existing secret if it exists
if kubectl get secret "${SECRET_NAME}" -n "${NAMESPACE}" &> /dev/null; then
    echo "Deleting existing secret: ${SECRET_NAME}"
    kubectl delete secret "${SECRET_NAME}" -n "${NAMESPACE}"
fi

# Create TLS secret
echo "Creating TLS secret: ${SECRET_NAME}"
kubectl create secret tls "${SECRET_NAME}" \
    --cert="${TEMP_DIR}/tls.crt" \
    --key="${TEMP_DIR}/tls.key" \
    -n "${NAMESPACE}"

echo -e "${GREEN}✅ TLS secret created successfully${NC}"
echo ""

echo "================================================"
echo "Certificate Details"
echo "================================================"
openssl x509 -in "${TEMP_DIR}/tls.crt" -noout -text | grep -A 2 "Subject:"
openssl x509 -in "${TEMP_DIR}/tls.crt" -noout -text | grep -A 2 "Validity"
echo ""

echo "================================================"
echo "Deployment Complete!"
echo "================================================"
echo ""
echo "You can now deploy the test ingress:"
echo "  kubectl apply -f test-ingress.yaml"
echo ""
echo "And test HTTPS access:"
echo "  curl -k https://test-tls.127.0.0.1.nip.io"
echo ""
