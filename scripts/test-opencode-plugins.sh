#!/usr/bin/env bash
# scripts/test-opencode-plugins.sh — contract and behaviour tests for the
# OpenCode V2 plugins in .opencode/plugins/. The plugins are JavaScript, so the
# suite uses node's built-in test runner: offline, no install, no network.
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

if ! command -v node > /dev/null 2>&1; then
  echo "FAIL: node is required to test the OpenCode plugins" >&2
  exit 1
fi

node --test tests/plugins/opencode-plugins.test.mjs
