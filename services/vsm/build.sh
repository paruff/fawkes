#!/bin/bash
# Build script for VSM service Docker image

set -e

echo "Building VSM service Docker image..."
docker build -t vsm-service:latest .

echo "✅ VSM service image built successfully"
echo "To test locally: docker run -p 8000:8000 vsm-service:latest"
