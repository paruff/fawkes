#!/usr/bin/env bash
# scripts/test-artifact-chain.sh — proves scripts/check-artifact-chain.sh
# blocks PRs that break the intent → spec → plan → code chain and passes
# compliant ones. Each scenario is a throwaway git repo with a `main` branch
# and a PR branch; nothing in this repository is touched.
#
# Report-only. Exit 0 = every scenario behaved as expected.

set -euo pipefail
cd "$(dirname "$0")/.."

# Git exports GIT_INDEX_FILE (and friends) to hooks. Run from a hook (the
# unit-tests pre-commit hook, or pre-push-validation's `pre-commit run
# --all-files`), they made every `git -C "$repo" ...` below act on the REAL
# repo: `git add -A` rewrote the real index and `git switch -qc pr` moved the
# real worktree onto a stray branch. Scenarios must see only their own repo.
unset GIT_INDEX_FILE GIT_DIR GIT_WORK_TREE GIT_PREFIX GIT_COMMON_DIR

CHECK="$PWD/scripts/check-artifact-chain.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

pass=0
fail=0

# new_repo <name>: repo with an initial commit on main, then a `pr` branch.
new_repo() {
  local repo="$work/$1"
  mkdir -p "$repo/scripts"
  cp "$CHECK" "$repo/scripts/"
  git -C "$repo" init -q -b main
  git -C "$repo" config user.email test@example.invalid
  git -C "$repo" config user.name test
  echo "# app" > "$repo/README.md"
  git -C "$repo" add -A
  git -C "$repo" commit -qm "chore: init"
  git -C "$repo" switch -qc pr
  echo "$repo"
}

# commit <repo> <path> <content>
commit() {
  mkdir -p "$(dirname "$1/$2")"
  printf '%s\n' "$3" > "$1/$2"
  git -C "$1" add -A
  git -C "$1" commit -qm "change $2"
}

# expect <pass|block> <label> <repo>
expect() {
  local want="$1" label="$2" repo="$3" out rc
  out="$(cd "$repo" && scripts/check-artifact-chain.sh main pr 2>&1)" && rc=0 || rc=$?
  if { [ "$want" = pass ] && [ "$rc" -eq 0 ]; } || { [ "$want" = block ] && [ "$rc" -eq 1 ]; }; then
    pass=$((pass + 1))
    echo "  ✅ ${want}: ${label}"
  else
    fail=$((fail + 1))
    echo "  ❌ expected ${want} (exit ${rc}): ${label}"
    echo "${out//$'\n'/$'\n'       }"
  fi
}

PLAN_OK=$'# Design: login\n\n## Implementation Sequence\n\n1. Add handler\n\n## Verification Strategy\n\n- AC-01: unit test'
PLAN_NO_VS=$'# Design: login\n\n## Implementation Sequence\n\n1. Add handler'
INTENT=$'# Intent — login\n\nUsers need to sign in.'
SPEC=$'# Specification: login\n\n## Acceptance Criteria\n\n- [ ] AC-01'

echo "== Rule 1: src/ changes need a plan.md with a Verification Strategy =="
r="$(new_repo skip-plan)"
commit "$r" src/app.ts "export const x = 1"
expect block "src/ change with no plan.md in the PR" "$r"

r="$(new_repo plan-without-section)"
commit "$r" docs/ai-sdlc/login/plan.md "$PLAN_NO_VS"
commit "$r" src/app.ts "export const x = 1"
expect block "plan.md lacks a Verification Strategy section" "$r"

r="$(new_repo plan-elsewhere)"
commit "$r" .agents/commands/plan.md "$PLAN_OK"
commit "$r" src/app.ts "export const x = 1"
expect block "plan.md outside docs/ai-sdlc/ does not count" "$r"

r="$(new_repo plan-on-main-only)"
git -C "$r" switch -q main
commit "$r" docs/ai-sdlc/login/intent.md "$INTENT"
commit "$r" docs/ai-sdlc/login/plan.md "$PLAN_OK"
git -C "$r" switch -q pr
git -C "$r" merge -q main
commit "$r" src/app.ts "export const x = 1"
expect block "plan.md already on main, not in this PR's diff" "$r"

r="$(new_repo compliant)"
commit "$r" docs/ai-sdlc/login/intent.md "$INTENT"
commit "$r" docs/ai-sdlc/login/spec.md "$SPEC"
commit "$r" docs/ai-sdlc/login/plan.md "$PLAN_OK"
commit "$r" src/app.ts "export const x = 1"
expect pass "intent → spec → plan (with Verification Strategy) → src/ in one PR" "$r"

r="$(new_repo lowercase-heading)"
commit "$r" docs/ai-sdlc/plan.md $'# Plan\n\n### verification strategy\n\n- run tests'
commit "$r" src/app.ts "export const x = 1"
expect pass "top-level docs/ai-sdlc/plan.md, heading level/case-insensitive" "$r"

r="$(new_repo large-plan)"
{
  printf '%s\n\n' "$PLAN_OK"
  for i in $(seq 1 20000); do echo "- step $i of a long plan"; done
} > "$work/big-plan.md"
commit "$r" docs/ai-sdlc/login/plan.md "$(cat "$work/big-plan.md")"
commit "$r" src/app.ts "export const x = 1"
expect pass "large plan.md (~500 KB, heading near the top) is not misread via SIGPIPE" "$r"

r="$(new_repo docs-only)"
commit "$r" docs/guide.md "hello"
expect pass "no src/ change and no artifacts" "$r"

echo "== Rule 2: spec.md needs an intent.md in branch history =="
r="$(new_repo spec-without-intent)"
commit "$r" docs/ai-sdlc/login/spec.md "$SPEC"
expect block "spec.md with no intent.md" "$r"

r="$(new_repo intent-other-feature)"
commit "$r" docs/ai-sdlc/billing/intent.md "$INTENT"
commit "$r" docs/ai-sdlc/login/spec.md "$SPEC"
expect block "intent.md exists only for a different feature" "$r"

r="$(new_repo intent-then-spec)"
commit "$r" docs/ai-sdlc/login/intent.md "$INTENT"
commit "$r" docs/ai-sdlc/login/spec.md "$SPEC"
expect pass "intent.md committed before spec.md" "$r"

r="$(new_repo intent-removed-later)"
commit "$r" docs/ai-sdlc/login/intent.md "$INTENT"
commit "$r" docs/ai-sdlc/login/spec.md "$SPEC"
git -C "$r" rm -q docs/ai-sdlc/login/intent.md
git -C "$r" commit -qm "remove intent"
expect pass "intent.md in history though later removed" "$r"

echo
if [ "$fail" -gt 0 ]; then
  echo "FAILED ${fail} scenario(s), passed ${pass}"
  exit 1
fi
echo "ALL ${pass} SCENARIOS BEHAVED AS EXPECTED"
