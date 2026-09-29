#!/usr/bin/env bash
# pre-commit-secret-scan.sh — commit-time secret gate, shared by both harnesses.
#
# Claude Code (.claude/settings.json) and OpenCode (.opencode/plugins/) both call
# THIS file rather than reimplementing the check, so there is one implementation
# and one place to fix it. It is also directly runnable:
#
#   scripts/hooks/pre-commit-secret-scan.sh
#
# Scans only the STAGED files, not the whole tree. A whole-tree scan takes ~25s
# and would report secrets that are not part of this commit; the question at
# commit time is narrower — "is a secret going into this commit?"
#
# Exit codes:
#   0  clean, commit may proceed
#   1  credential-shaped finding in a staged file — BLOCK
#   2  the validator could not run (missing, crashed, bad state) — BLOCK
#
# Fails closed on 2 as well as 1. A secret gate that can be walked through by
# making the validator error is not a gate. `--no-verify` still bypasses it, and
# that bypass is visible in the reflog; gitleaks in pre-commit and the
# secret-scan CI workflow are independent backstops regardless.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2> /dev/null || pwd)"
VALIDATOR="${REPO_ROOT}/scripts/check-secret-detection.sh"

if [ ! -x "$VALIDATOR" ]; then
  echo "secret-scan: validator missing or not executable: ${VALIDATOR}" >&2
  echo "secret-scan: refusing to allow a commit through an unrunnable secret gate." >&2
  exit 2
fi

cd "$REPO_ROOT"

# Staged, added/copied/modified/renamed files only. Deletions cannot leak a
# secret and would make the validator error on a missing path.
staged="$(git diff --cached --name-only --diff-filter=ACM 2> /dev/null || true)"

if [ -z "$staged" ]; then
  # Nothing staged (e.g. `git commit -a` with no changes, or a hook probe).
  # Not an error: there is nothing to scan and nothing to block.
  exit 0
fi

set +e
# NOT --quiet: the whole point of blocking is showing the developer which line
# failed. A gate that says "BLOCKED" and nothing else just gets bypassed.
# shellcheck disable=SC2086
output="$("$VALIDATOR" --no-json $staged 2>&1)"
rc=$?
set -e

case "$rc" in
  0)
    exit 0
    ;;
  1)
    echo "secret-scan: BLOCKED — credential-shaped finding in a staged file." >&2
    echo "$output" >&2
    echo >&2
    echo "Remove the secret, or suppress a false positive with a trailing" >&2
    echo "'# pragma: allowlist secret' on the offending line." >&2
    exit 1
    ;;
  *)
    echo "secret-scan: BLOCKED — validator exited ${rc} (could not complete)." >&2
    echo "$output" >&2
    echo "secret-scan: fix the validator before committing; not falling open." >&2
    exit 2
    ;;
esac
