#!/usr/bin/env bash
# scripts/test-claude-hooks.sh — the Claude Code PreToolUse hook in
# .claude/settings.json must deny protected paths (same rules as the opencode
# plugin: scripts/hooks/protected-paths.json) and allow everything else.

set -euo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
HOOK="$(jq -r '.hooks.PreToolUse[] | select(.matcher=="Edit|Write") | .hooks[0].command' .claude/settings.json)"

check() { # <expect: deny|allow> <file_path>
  local expect="$1" path="$2" out got
  out="$(printf '{"tool_input":{"file_path":"%s"}}' "$path" | CLAUDE_PROJECT_DIR="$PWD" bash -c "$HOOK" 2> /dev/null || true)"
  if grep -q '"permissionDecision": *"deny"' <<< "$out"; then got=deny; else got=allow; fi
  if [[ "$got" == "$expect" ]]; then
    printf '  ok   %-5s %s\n' "$expect" "$path"
    PASS=$((PASS + 1))
  else
    printf '  FAIL want %s got %s: %s\n' "$expect" "$got" "$path"
    FAIL=$((FAIL + 1))
  fi
}

echo "== Claude Code protected-path hook =="
check deny "$PWD/.env"
check deny ".env"
check deny "$PWD/.env.production"
check deny "$PWD/certs/server.pem"
check deny "$PWD/keys/id.key"
check deny "$PWD/credentials.json"
check deny "$PWD/.git/config"
check allow "$PWD/.env.example"
check allow "$PWD/scripts/foo.sh"
check allow "$PWD/README.md"

echo "== $PASS passed, $FAIL failed =="
[[ "$FAIL" -eq 0 ]]
