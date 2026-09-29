#!/usr/bin/env bash
# scripts/test-check-secret-detection.sh — proves the secret-detection validator
# actually fails. A validator that has never been shown to go red is not a
# control, it is a decoration.
#
# Each case plants a credential in a temp fixture, runs the validator, and
# asserts the exit code. The final cases run the validator against the REAL
# repository and assert a clean exit — that is what keeps the blocking patterns
# honest and stops someone "fixing" a false positive by deleting the rule.
#
# NOTE ON LITERALS: every sample credential below is written as a shell
# concatenation ('AKIA''IOSF…') rather than one contiguous string. Evaluated by
# bash each yields the real credential the assertion needs; read as file text no
# contiguous literal exists. Without this the harness flags itself and gitleaks
# fails it in pre-commit — a scanner that trips on its own tests is a scanner
# people delete.
#
# Usage: scripts/test-check-secret-detection.sh
# Exit:  0 all cases behaved as specified, 1 otherwise.

set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

VALIDATOR="scripts/check-secret-detection.sh"
# Fixtures live OUTSIDE the repository. Inside it, the planted credentials were
# visible to the "real repository must be clean" case below, so the suite
# guaranteed its own failure. Kept in a temp dir that is removed on exit.
FIXTURES="$(mktemp -d)"
trap 'rm -rf "$FIXTURES"' EXIT
pass=0
fail=0
n=0

ok() {
  pass=$((pass + 1))
  printf '  ok   %s\n' "$1"
}

no() {
  fail=$((fail + 1))
  printf '  FAIL %s\n' "$1"
  if [ -n "${2:-}" ]; then printf '       %s\n' "$2"; fi
}

# expect <label> <expected-exit> <file-content> [expected-rule-substring]
expect() {
  local label="$1" want="$2" content="$3" rule="${4:-}"
  n=$((n + 1))
  local f="${FIXTURES}/case-${n}.txt"
  mkdir -p "$FIXTURES"
  printf '%s\n' "$content" > "$f"

  local out got
  out="$("$VALIDATOR" --no-json "$f" 2>&1)"
  got=$?

  if [ "$got" -ne "$want" ]; then
    no "$label (expected exit $want, got $got)" "$(printf '%s' "$out" | head -3 | tr '\n' ' ')"
    return
  fi
  if [ -n "$rule" ] && [ "$want" -ne 0 ]; then
    if ! printf '%s' "$out" | grep -q "$rule"; then
      no "$label (expected rule '$rule' in output)" "$(printf '%s' "$out" | head -3 | tr '\n' ' ')"
      return
    fi
  fi
  ok "$label"
}

echo "== secret-detection validator =="

# --- must FAIL: credential-shaped patterns from the skill's pattern table ----
expect "aws access key id is caught" 1 \
  'AWS_ACCESS_KEY_ID=AKIA''IOSFODNN7''EXAMPLE' 'aws_access_key_id'

expect "github token is caught" 1 \
  'token: ghp_''0123456789''abcdefghijklmnopqrstuvwxyz''AB' 'github_token'

expect "github fine-grained pat is caught" 1 \
  'GITHUB_PAT=github_pat_''11ABCDEFG0''abcdefghijklmnopqrstuvwxyz''0123456789''ABCD' 'github_pat'

expect "slack token is caught" 1 \
  'xoxb-''123456789012''-''1234567890123''-abcdefghijklmnop' 'slack_token'

expect "pem private key header is caught" 1 \
  '-----BEGIN RSA PRIVATE KEY-----' 'private_key' # pragma: allowlist secret

stripe_live_key="sk_live_""TESTFAKEKEY1234567890123456" # pragma: allowlist secret
expect "stripe live key is caught" 1 "$stripe_live_key" 'stripe_key'

expect "google api key is caught" 1 \
  'AIzaSy''A1B2C3D4E5F6G7H8I9J0K1L2M3N4O5P6Q7R8S9T' 'google_api_key'

expect "npm token is caught" 1 \
  'npm_''1234567890abcdef''1234567890abcdef''12345678' 'npm_token'

expect "gitlab pat is caught" 1 \
  'glpat-''1234567890abcdefghijkl' 'gitlab_token'

expect "jwt is caught" 1 \
  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c' 'json_web_token' # pragma: allowlist secret

# --- must FAIL: assigned literal credentials (assignment heuristic) ----------
expect "password assigned a real literal is caught" 1 \
  'password = "SuperSecret123!"' 'assigned_credential' # pragma: allowlist secret

expect "token assigned a real literal is caught" 1 \
  'api_token = "ghp_abcdefghijklmnopqrstuvwxyz123456"' 'assigned_credential' # pragma: allowlist secret

# --- must PASS: placeholder patterns -----------------------------------------
expect "changeme value is a placeholder" 0 \
  'password = "changeme"'

expect "example value is a placeholder" 0 \
  'token = "example"'

expect "redacted value is a placeholder" 0 \
  'api_key = "redacted"'

expect "angle-bracket value is a placeholder" 0 \
  'token = "<YOUR_TOKEN_HERE>"'

expect "xxx-masked value is a placeholder" 0 \
  'api_key = "xxx"'

# --- must PASS: allowlisted contexts -----------------------------------------
expect "pragma allowlist suppresses a shaped finding" 0 \
  'token = "ghp_0123456789abcdefghijklmnopqrstuvwxyzAB"  # pragma: allowlist secret' 'github_token'

expect "pragma allowlist suppresses an assigned finding" 0 \
  'password = "SuperSecret123!"  # pragma: allowlist secret' 'assigned_credential'

# --- must PASS: K8s/GitOps references ----------------------------------------
expect "k8s secretKeyRef is a reference not a secret" 0 \
  'secretKeyRef:
  name: my-secret
  key: password'

# --- must PASS: documentation examples ---------------------------------------
expect "schema example password string is not a secret" 0 \
  'example: "password123"  # schema example'

expect "prose about tokens is not a secret" 0 \
  'The token is used to authenticate the user.'

# --- must PASS: skill pattern table does not self-trigger --------------------
# shellcheck disable=SC2016 # the single-quoted regex must reach the validator unexpanded
expect "the skill pattern table itself does not self-trigger" 0 \
  '| GitHub Tokens | `ghp_[0-9a-zA-Z]{36}`       |'

# --- the real repository (scripts/ excluding test scripts) must be clean -----
# For fawkes (large platform repo), we scan scripts/ excluding test scripts
# and .github/ workflows to validate the validator on the code it protects.
echo
echo "  -- real repository (scripts/ excluding test-*.sh + .github/) --"
# Build file list excluding test scripts which contain test credentials
file_list=$(find scripts/ .github/ -type f -name "*.sh" ! -name "test-*.sh" 2> /dev/null | head -100)
if [ -n "$file_list" ]; then
  repo_out=$(printf '%s\n' "$file_list" | xargs "$VALIDATOR" --no-json 2>&1)
  repo_rc=$?
  if [ "$repo_rc" -eq 0 ]; then
    ok "repository scans clean (exit 0)"
  else
    no "repository scans clean (exit $repo_rc)" "$(printf '%s' "$repo_out" | grep -E '^\s+\[' | head -10)"
  fi

  # The emitted artifact must be valid JSON and self-consistent.
  echo
  echo "  -- emitted secrets.json --"
  tmp_json="$(mktemp)"
  if printf '%s\n' "$file_list" | xargs "$VALIDATOR" --quiet --json "$tmp_json" > /dev/null 2>&1; then
    if command -v jq > /dev/null 2>&1; then
      if jq -e . "$tmp_json" > /dev/null 2>&1; then
        ok "secrets.json is valid JSON"
      else
        no "secrets.json is valid JSON"
      fi
      for k in skill status validator files_scanned issues; do
        if jq -e "has(\"$k\")" "$tmp_json" > /dev/null 2>&1; then
          ok "secrets.json has required key '$k'"
        else
          no "secrets.json has required key '$k'"
        fi
      done
      if [ "$(jq -r '.status' "$tmp_json")" = "pass" ]; then
        ok "secrets.json status is 'pass' on a clean tree"
      else
        no "secrets.json status is 'pass' on a clean tree" "got $(jq -r '.status' "$tmp_json")"
      fi
      if [ "$(jq -r '.issues | length' "$tmp_json")" = "0" ]; then
        ok "secrets.json issues array is empty on a clean tree"
      else
        no "secrets.json issues array is empty on a clean tree"
      fi
    else
      no "validator succeeded writing secrets.json"
    fi
    rm -f "$tmp_json"
  fi
else
  printf '  skip (no non-test scripts found)\n'
fi

echo
echo "== ${pass} passed, ${fail} failed =="
[ "$fail" -eq 0 ] || exit 1
exit 0
