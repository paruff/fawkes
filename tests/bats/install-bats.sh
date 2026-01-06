#!/usr/bin/env bash
# =============================================================================
# File: tests/bats/install-bats.sh
# Purpose: Install BATS and its helper libraries for testing Bash scripts
# Usage: ./tests/bats/install-bats.sh [--prefix /path/to/install]
# =============================================================================

set -euo pipefail

# Default installation prefix
PREFIX="${HOME}/.local"
BATS_VERSION="v1.11.0"
BATS_SUPPORT_VERSION="v0.3.0"
BATS_ASSERT_VERSION="v2.1.0"
BATS_FILE_VERSION="v0.4.0"
BATS_MOCK_VERSION="master"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --prefix)
      PREFIX="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--prefix /path/to/install]"
      echo "Install BATS and helper libraries"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo "🔧 Installing BATS and helpers to ${PREFIX}"

# Create installation directory
mkdir -p "${PREFIX}"

# Temporary directory for cloning
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "${TEMP_DIR}"' EXIT

cd "${TEMP_DIR}"

# Install BATS core
echo "📦 Installing BATS core ${BATS_VERSION}..."
git clone --depth 1 --branch "${BATS_VERSION}" https://github.com/bats-core/bats-core.git
cd bats-core
./install.sh "${PREFIX}"
cd ..

# Install bats-support
echo "📦 Installing bats-support ${BATS_SUPPORT_VERSION}..."
git clone --depth 1 --branch "${BATS_SUPPORT_VERSION}" https://github.com/bats-core/bats-support.git
mkdir -p "${PREFIX}/lib/bats-support"
cp -r bats-support/load.bash bats-support/src "${PREFIX}/lib/bats-support/"

# Install bats-assert
echo "📦 Installing bats-assert ${BATS_ASSERT_VERSION}..."
git clone --depth 1 --branch "${BATS_ASSERT_VERSION}" https://github.com/bats-core/bats-assert.git
mkdir -p "${PREFIX}/lib/bats-assert"
cp -r bats-assert/load.bash bats-assert/src "${PREFIX}/lib/bats-assert/"

# Install bats-file
echo "📦 Installing bats-file ${BATS_FILE_VERSION}..."
git clone --depth 1 --branch "${BATS_FILE_VERSION}" https://github.com/bats-core/bats-file.git
mkdir -p "${PREFIX}/lib/bats-file"
cp -r bats-file/load.bash bats-file/src "${PREFIX}/lib/bats-file/"

# Install bats-mock
echo "📦 Installing bats-mock ${BATS_MOCK_VERSION}..."
git clone --depth 1 --branch "${BATS_MOCK_VERSION}" https://github.com/grayhemp/bats-mock.git
mkdir -p "${PREFIX}/lib/bats-mock"
cp -r bats-mock/load.bash bats-mock/src "${PREFIX}/lib/bats-mock/"

echo ""
echo "✅ BATS installation complete!"
echo ""
echo "Add to your PATH:"
echo "  export PATH=\"${PREFIX}/bin:\$PATH\""
echo ""
echo "Verify installation:"
echo "  bats --version"
echo ""
echo "Run tests:"
echo "  bats tests/bats/unit/"
