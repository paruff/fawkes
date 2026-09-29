#!/usr/bin/env bash
# scripts/test-dojo-feedback-intent.sh — proves scripts/dojo-feedback-intent.sh
# accepts well-formed dojo-feedback.md files, renders the `intent` issue and
# draft intent.md CI opens, opens nothing for "no gaps", and rejects
# malformed feedback with a specific reason. Fixtures live in a temp dir.
#
# Report-only. Exit 0 = every check passed.

# `cond && ok ... || bad ...` is safe here: ok() always returns 0.
# shellcheck disable=SC2015

set -euo pipefail
cd "$(dirname "$0")/.."

TOOL="$PWD/scripts/dojo-feedback-intent.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
pass=0
failures=()
ok() {
  pass=$((pass + 1))
  echo "  ✅ $1"
  return 0
}
bad() {
  failures+=("$1")
  echo "  ❌ $1"
  [ -z "${2:-}" ] || echo "${2//$'\n'/$'\n'       }"
}

valid() {
  cat << 'EOF'
---
lab: white-belt/module-03-delivery-events/lab-01
lab_ref: https://github.com/paruff/uFawkesDojo/pull/1
source_feature: docs/ai-sdlc/dora-events
source_commit: 0a5735d1234567890abcdef1234567890abcdef0
completed_at: 2026-09-27
learners: 2
proposed_feature: dora-events-hardening
---

# Dojo Feedback: dora-events

## Lab Results

| AC    | Rubric check | Passed | Failed | Notes |
| ----- | ------------ | ------ | ------ | ----- |
| AC-01 | shape        | 2      | 0      |       |

## Gaps

### GAP-01: Loki query undocumented

- **Type:** prompt
- **Evidence:** learner asked "which label do I select in Grafana?"
- **Affected:** `docs/UFAWKES_INTEGRATION.md`
- **Proposed change:** document the stream labels the collector assigns
- **Severity:** medium

### GAP-02: Token footer only for Claude Code

- **Type:** guardrail
- **Evidence:** OpenCode learner's commit had no Agent-Tokens footer; agent_tokens.commits_reporting was 0
- **Affected:** `scripts/agent-usage.sh`
- **Proposed change:** support OpenCode session storage
- **Severity:** high

## Proposed Intent

### Problem

GAP-01 and GAP-02 left learners unable to finish AC-05 unaided.

### Desired outcome

Both harnesses report token usage; the Loki query is documented and tested.

### Out of scope

- Grafana dashboard changes
EOF
}

echo "== Valid feedback with gaps =="
valid > "$work/dojo-feedback.md"
if out="$("$TOOL" "$work/dojo-feedback.md" --out-dir "$work/out" --opened-at 2026-09-27T12:00:00Z --sprint-days 7 2>&1)"; then
  ok "accepted"
else
  bad "rejected a valid file" "$out"
fi
title="$(cat "$work/out/issue-title.txt" 2> /dev/null || true)"
[ "$title" = "intent: dora-events-hardening (from Dojo lab white-belt/module-03-delivery-events/lab-01)" ] \
  && ok "issue title" || bad "issue title: ${title}"
[ "$(cat "$work/out/intent-path.txt" 2> /dev/null)" = "docs/ai-sdlc/dora-events-hardening/intent.md" ] \
  && ok "intent path from proposed_feature" || bad "intent path"
grep -qF "<!-- dojo-feedback: $work/dojo-feedback.md -->" "$work/out/issue.md" 2> /dev/null \
  && ok "issue carries an idempotency marker" || bad "marker missing"
grep -q "due 2026-10-04, one sprint = 7 days" "$work/out/issue.md" && ok "due date = opened + one sprint" || bad "due date"
for want in "- GAP-01: Loki query undocumented" "- GAP-02: Token footer only for Claude Code" \
  "GAP-01 and GAP-02 left learners" "Both harnesses report token usage" "- Grafana dashboard changes"; do
  grep -qF -- "$want" "$work/out/intent.md" && ok "draft intent contains: ${want}" || bad "draft intent missing: ${want}"
done
grep -qF '```markdown' "$work/out/issue.md" && grep -qF "# Intent — dora-events-hardening" "$work/out/issue.md" \
  && ok "issue embeds the draft intent" || bad "issue does not embed the draft"

echo "== No gaps → nothing to open =="
valid | awk '/^## Gaps$/{print; print ""; print "None."; print ""; skip=1; next} /^## Proposed Intent$/{skip=0} !skip' \
  | sed '/^### Problem$/,/^### Desired outcome$/{/^GAP-01/d;}' > "$work/none.md"
res="$("$TOOL" "$work/none.md" --out-dir "$work/none-out" 2>&1)" && [ "$res" = "no-gaps" ] \
  && ok "prints no-gaps, exits 0" || bad "no-gaps handling" "$res"

echo "== Malformed feedback is rejected with a reason =="
reject() { # reject <label> <expected-message> <sed-script>
  valid | sed "$3" > "$work/bad.md"
  if msg="$("$TOOL" "$work/bad.md" --out-dir "$work/bad-out" 2>&1)"; then
    bad "$1: accepted"
  elif grep -qF -- "$2" <<< "$msg"; then
    ok "$1"
  else
    bad "$1: wrong reason" "$msg"
  fi
}
reject "missing front matter key" "'source_commit' is missing" '/^source_commit:/d'
reject "non-slug proposed_feature" "must be a kebab-case slug" 's/^proposed_feature: .*/proposed_feature: Dora Events!/'
reject "unknown gap type" "GAP-01: Loki query undocumented: Type must be one of" 's/- \*\*Type:\*\* prompt/- **Type:** vibes/'
reject "gap without evidence" "GAP-02: Token footer only for Claude Code: Evidence is required" '/OpenCode learner/d'
reject "empty Gaps section" "must list '### GAP-NN: title'" '/^### GAP-/,/^- \*\*Severity/d'
reject "missing Proposed Intent" "missing heading matching: ^## Proposed Intent$" 's/^## Proposed Intent$/## Ideas/'
reject "empty Problem" "### Problem is empty" '/^GAP-01 and GAP-02 left/d'

echo
if [ "${#failures[@]}" -gt 0 ]; then
  echo "FAILED ${#failures[@]} check(s), passed ${pass}:"
  printf '  - %s\n' "${failures[@]}"
  exit 1
fi
echo "ALL ${pass} CHECKS PASSED"
