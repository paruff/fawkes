#!/bin/bash
# ============================================================================
# FILE: services/rag/build.sh
# PURPOSE: Build Docker image for RAG service
# USAGE: ./build.sh [TAG]
# ============================================================================

set -euo pipefail

# Configuration
IMAGE_NAME="rag-service"
TAG="${1:-latest}"
FULL_IMAGE="${IMAGE_NAME}:${TAG}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================================================"
echo "Building RAG Service Docker Image"
echo "================================================================================"
echo ""
echo "Image: ${FULL_IMAGE}"
echo ""

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Build image
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Building Docker image..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

docker build -t "${FULL_IMAGE}" .

echo ""
echo -e "${GREEN}✓${NC} Docker image built successfully: ${FULL_IMAGE}"
echo ""

# Show image details
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Image Details"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
docker images "${IMAGE_NAME}" | grep "${TAG}"
echo ""

# Optional: Test the image
echo -e "${YELLOW}ℹ${NC} To test the image locally:"
echo "  docker run -p 8000:8000 -e WEAVIATE_URL=http://host.docker.internal:8080 ${FULL_IMAGE}"
echo ""
echo -e "${YELLOW}ℹ${NC} To push to a registry:"
echo "  docker tag ${FULL_IMAGE} <registry>/${FULL_IMAGE}"
echo "  docker push <registry>/${FULL_IMAGE}"
echo ""

exit 0
