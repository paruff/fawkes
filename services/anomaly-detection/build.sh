#!/bin/bash
# Build script for Anomaly Detection Service

set -euo pipefail

echo "🏗️  Building Anomaly Detection Service"

# Configuration
IMAGE_NAME="${IMAGE_NAME:-anomaly-detection}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-}"

FULL_IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
if [ -n "$REGISTRY" ]; then
  FULL_IMAGE="${REGISTRY}/${FULL_IMAGE}"
fi

echo "Image: $FULL_IMAGE"

# Build Docker image
echo "📦 Building Docker image..."
docker build -t "$FULL_IMAGE" .

echo "✅ Build complete: $FULL_IMAGE"

# Optional: Push to registry
if [ "$PUSH" = "true" ] && [ -n "$REGISTRY" ]; then
  echo "📤 Pushing to registry..."
  docker push "$FULL_IMAGE"
  echo "✅ Push complete"
fi

echo ""
echo "🎉 Anomaly Detection Service build successful!"
echo ""
echo "Next steps:"
echo "  1. Deploy to K8s: kubectl apply -f k8s/deployment.yaml"
echo "  2. Or use ArgoCD: kubectl apply -f ../platform/apps/anomaly-detection-application.yaml"
echo ""
