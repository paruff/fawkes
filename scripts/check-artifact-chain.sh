#!/usr/bin/env bash
# scripts/check-artifact-chain.sh — enforces the committed AI-SDLC artifact
# chain for a PR: intent.md → spec.md → plan.md → code diff
# (docs/ai-sdlc/README.md). Run by .github/workflows/artifact-chain.yml.
#
# Rules:
#   1. A PR that changes anything under src/ must also add or modify a
#      docs/ai-sdlc/**/plan.md containing a "Verification Strategy" heading,
#      so the plan is reviewed in the same PR diff as the code.
#   2. Every docs/ai-sdlc/**/spec.md at the PR head must have a sibling
#      intent.md somewhere in the branch history.
#
# Report-only (no repository changes). Exit 0 = chain intact, 1 = violated.
#
# Usage: scripts/check-artifact-chain.sh <base-ref> [head-ref]

set -euo pipefail
cd "$(dirname "$0")/.."

BASE="${1:?usage: $0 <base-ref> [head-ref]}"
HEAD_REF="${2:-HEAD}"
ROOT="docs/ai-sdlc"
PLAN_GLOB=":(glob)${ROOT}/**/plan.md"
VERIFICATION_HEADING='^#{1,6}[[:space:]]+Verification Strategy([[:space:]]|$)'

errors=0
err() {
  errors=$((errors + 1))
  if [ -n "${GITHUB_ACTIONS:-}" ]; then
    echo "::error file=$1::$2"
  else
    echo "❌ $1: $2"
  fi
}

merge_base="$(git merge-base "$BASE" "$HEAD_REF")" || {
  echo "cannot find merge base of ${BASE} and ${HEAD_REF} (shallow clone? use fetch-depth: 0)" >&2
  exit 2
}

echo "== Rule 1: src/ changes ship with a plan.md that has a Verification Strategy =="
mapfile -t src_changes < <(git diff --name-only "$merge_base" "$HEAD_REF" -- src/)
if [ "${#src_changes[@]}" -eq 0 ]; then
  echo "  no src/ changes — rule not triggered"
else
  echo "  ${#src_changes[@]} src/ file(s) changed"
  mapfile -t plans < <(git diff --name-only --diff-filter=ACMR "$merge_base" "$HEAD_REF" -- "$PLAN_GLOB")
  valid=0
  for plan in "${plans[@]}"; do
    # No grep -q: exiting at the first match would SIGPIPE `git show` on a
    # large plan, and pipefail would turn that into a false "missing section".
    if git show "${HEAD_REF}:${plan}" | grep -iE "$VERIFICATION_HEADING" > /dev/null; then
      echo "  ✅ ${plan} includes a Verification Strategy section"
      valid=$((valid + 1))
    else
      err "$plan" "plan.md has no '## Verification Strategy' section — add how each acceptance criterion will be verified"
    fi
  done
  # A plan without the section was already reported above.
  if [ "${#plans[@]}" -eq 0 ]; then
    err "${src_changes[0]}" "PR changes src/ but its diff includes no ${ROOT}/<feature>/plan.md — commit the plan (with a '## Verification Strategy' section) in this PR"
  fi
fi

echo "== Rule 2: every spec.md has an intent.md in the branch history =="
mapfile -t specs < <(git ls-tree -r --name-only "$HEAD_REF" -- "$ROOT" | grep -E '(^|/)spec\.md$' || true)
if [ "${#specs[@]}" -eq 0 ]; then
  echo "  no spec.md under ${ROOT}/"
fi
for spec in "${specs[@]}"; do
  intent="$(dirname "$spec")/intent.md"
  if [ -n "$(git log -1 --format=%H "$HEAD_REF" -- "$intent")" ]; then
    echo "  ✅ ${spec} ← ${intent}"
  else
    err "$spec" "spec.md has no ${intent} in the branch history — commit the intent before (or with) the spec"
  fi
done

echo
if [ "$errors" -gt 0 ]; then
  echo "Artifact chain violated: ${errors} problem(s). See docs/ai-sdlc/README.md."
  exit 1
fi
echo "✅ Artifact chain intact"
