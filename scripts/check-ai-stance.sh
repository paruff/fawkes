#!/usr/bin/env bash
# scripts/check-ai-stance.sh — enforce that AI_STANCE.md is complete and current.
#
# This exists because "the audit passed" is only worth something if something
# runs it. It used to live in a scratch directory and be run by hand, which
# means it would have silently rotted. It is wired into pre-commit and
# preflight.
#
# Checks the four DORA AI Capability 1 clarity dimensions the stance skill
# documents, plus currency and the three-bucket policy shape.
#
# Exit 0 = stance is complete. Exit 1 = gaps, all listed.
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

STANCE="${1:-AI_STANCE.md}"

if [[ ! -f "$STANCE" ]]; then
  echo "FAIL: $STANCE not found." >&2
  echo "      Every uFawkes* repo needs one; see .agents/skills/ai-stance/." >&2
  exit 1
fi

gaps=0
gap() {
  echo "  GAP  $1" >&2
  gaps=$((gaps + 1))
}
ok() { echo "  ok   $1"; }

# ── Currency ────────────────────────────────────────────────────────────────
if grep -qE '^\**Last reviewed:\** *[0-9]{4}-[0-9]{2}-[0-9]{2}' "$STANCE"; then
  ok "Last reviewed date present"
else
  gap "no 'Last reviewed: YYYY-MM-DD'"
fi

next_due="$(sed -nE 's/^\**Next review due:\**[[:space:]]*([0-9]{4}-[0-9]{2}-[0-9]{2}).*/\1/p' "$STANCE" | head -1)"
if [[ -z "$next_due" ]]; then
  gap "no 'Next review due: YYYY-MM-DD'"
else
  if [[ "$next_due" < "$(date -u +%F)" ]]; then
    gap "review is OVERDUE (due $next_due, today $(date -u +%F)) — re-review and update the date"
  else
    ok "review due $next_due (not overdue)"
  fi
fi

ph="$(grep -c '\[PLACEHOLDER' "$STANCE" || true)"
if [[ "${ph:-0}" -gt 0 ]]; then
  gap "${ph} unfilled [PLACEHOLDER] string(s) remain"
else
  ok "no unfilled placeholders"
fi

# ── Three-bucket policy shape ───────────────────────────────────────────────
# A stance with no Prohibited list is not a stance. Three buckets, because
# "allowed" and "forbidden" without a middle produces either paralysis or
# a rubber stamp.
for bucket in "Prohibited" "Permitted with guardrails" "Allowed"; do
  if grep -qiE "^#+ .*${bucket}" "$STANCE"; then
    ok "bucket present: $bucket"
  else
    gap "missing '$bucket' bucket"
  fi
done

prohibited_count="$(sed -n '/^### Prohibited/,/^### Allowed/p' "$STANCE" \
  | grep -cE '^[[:space:]]*[-*] ' || true)"
if [[ "${prohibited_count:-0}" -ge 3 ]]; then
  ok "Prohibited has ${prohibited_count} concrete items"
else
  gap "Prohibited has only ${prohibited_count:-0} item(s); a sparse Prohibited list means the policy was not thought through"
fi

# ── Dimension 2/3: permitted tools need versions, not "latest" ──────────────
if grep -qiE 'latest (llm|model)|<model-id|TBD' "$STANCE"; then
  gap "a tool/model is listed as 'latest', '<model-id>' or TBD — pin an actual version"
else
  ok "no unpinned tool versions"
fi

# ── Dimension 1/4: applicability and feedback ───────────────────────────────
if grep -qiE 'applies to|applicability' "$STANCE"; then
  ok "role applicability stated"
else
  gap "does not state whether the stance applies to humans, agents, or both"
fi

if grep -qiE 'feedback|raise|concern' "$STANCE"; then
  ok "feedback mechanism named"
else
  gap "no feedback mechanism (how does someone raise a policy concern?)"
fi

# ── Enforcement honesty: claims must be checkable ───────────────────────────
# A stance that lists gates must not claim gates the repo does not run. This
# is the same failure the DORA vocabulary check guards against, one axis over.
# A stance that says "no workflow runs Semgrep" is being honest. Only a claim
# that SAST *is* enforced, with no negation, is a false gate.
sast_claim="$(grep -iE 'semgrep|codeql' "$STANCE" \
  | grep -viE '\b(no|none|not|never|advisory|optional|without)\b' || true)"
if [[ -n "$sast_claim" ]]; then
  sast_workflow=0
  for wf in .github/workflows/*; do
    [[ -e "$wf" ]] || continue
    case "$(basename "$wf")" in *sast* | *semgrep* | *codeql*) sast_workflow=1 ;; esac
  done
  if [[ "$sast_workflow" -eq 0 ]]; then
    gap "mentions Semgrep/CodeQL but no workflow runs them — either add the workflow or drop the claim"
  else
    ok "SAST claim backed by a workflow"
  fi
fi

if [[ "$gaps" -ne 0 ]]; then
  echo
  echo "AI stance audit FAILED with ${gaps} gap(s) in ${STANCE}." >&2
  echo "See .agents/skills/ai-stance/ for what each dimension means." >&2
  exit 1
fi

echo "AI stance audit PASSED — ${STANCE} is complete and current."
