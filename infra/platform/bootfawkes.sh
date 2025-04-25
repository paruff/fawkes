#!/usr/bin/env bash
set -euo pipefail

# bootfawkes.sh - Bootstrap Fawkes infra and platform

echo "Detecting operating system and running environment setup..."

case "$OSTYPE" in
  darwin*)
    echo "Detected macOS."
    ../workspace/space-setup-macos.sh
    ;;
  linux*)
    echo "Detected Linux."
    ../workspace/space-setup-linux.sh
    ;;
  msys*|cygwin*)
    echo "Detected Windows (Git Bash/MSYS/Cygwin)."
    pwsh -File ../workspace/bootstrap.ps1
    ;;
  *)
    echo "Unknown or unsupported OS: $OSTYPE"
    exit 1
    ;;
esac

echo "Checking for required tools: terraform, kubectl, helm, aws..."
for tool in terraform kubectl helm aws; do
  if ! command -v "$tool" &>/dev/null; then
    echo "Error: $tool is not installed or not in PATH."
    exit 1
  fi
done

echo "Provisioning infrastructure (VPC, Kubernetes cluster)..."
./buildinfra.sh

echo "Deploying platform components (Helm charts, namespaces, etc.)..."
./buildplatform.sh

echo "Fawkes infrastructure and platform bootstrapping complete."
