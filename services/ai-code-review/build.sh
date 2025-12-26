#!/bin/bash
# =============================================================================
# Script: build.sh
# Purpose: Build script for AI Code Review Service
# Usage: ./build.sh
# Exit Codes: 0=success, 1=build failed, 2=missing prerequisites
# =============================================================================

set -euo pipefail

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

# Check prerequisites
if ! command -v docker &> /dev/null; then
  echo "ERROR: docker is required but not installed" >&2
  exit 2
fi

# Build the Docker image
if ! docker build -t "${FULL_IMAGE_NAME}" .; then
  echo "ERROR: Docker build failed" >&2
  exit 1
fi

echo "✅ Docker image built successfully: ${FULL_IMAGE_NAME}"

# Optionally push to registry
if [ "${PUSH_IMAGE:-false}" = "true" ]; then
  echo "Pushing image to registry..."
  if ! docker push "${FULL_IMAGE_NAME}"; then
    echo "ERROR: Failed to push image to registry" >&2
    exit 1
  fi
  echo "✅ Image pushed successfully"
fi

echo "Build complete!"
