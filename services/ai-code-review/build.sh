#!/bin/bash
# Build script for AI Code Review Service

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Configuration
IMAGE_NAME="${IMAGE_NAME:-ai-code-review}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
REGISTRY="${REGISTRY:-}"

# Add registry prefix if specified
if [ -n "$REGISTRY" ]; then
  FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
else
  FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"
fi

echo "Building AI Code Review Service Docker image..."
echo "Image: ${FULL_IMAGE_NAME}"

# Build the Docker image
docker build -t "${FULL_IMAGE_NAME}" .

echo "✅ Docker image built successfully: ${FULL_IMAGE_NAME}"

# Optionally push to registry
if [ "$PUSH_IMAGE" = "true" ]; then
  echo "Pushing image to registry..."
  docker push "${FULL_IMAGE_NAME}"
  echo "✅ Image pushed successfully"
fi

echo "Build complete!"
