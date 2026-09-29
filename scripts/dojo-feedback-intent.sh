#!/usr/bin/env bash
# scripts/dojo-feedback-intent.sh — validates a dojo-feedback.md (format:
# .agents/skills/dojo-feedback/SKILL.md) and renders what CI opens when it
# is merged: an `intent` issue and a ready-to-commit draft intent.md, so a
# Dojo lab's findings restart the AI-SDLC cycle (docs/ai-sdlc/dojo-handoff.md).
#
# Writes into --out-dir (default: a temp dir, printed):
#   issue-title.txt  issue.md  intent.md  intent-path.txt  marker.txt
# and prints "no-gaps" instead when the feedback records no gaps (nothing to
# open). Report-only apart from --out-dir. Exit 0 = valid, 1 = invalid.
#
# Usage: scripts/dojo-feedback-intent.sh <dojo-feedback.md> [--out-dir DIR]
#          [--sprint-days N] [--opened-at ISO-8601-UTC]

set -euo pipefail

FILE="${1:?usage: $0 <dojo-feedback.md> [--out-dir DIR] [--sprint-days N] [--opened-at ISO]}"
shift
out=""
sprint_days="${DOJO_SPRINT_DAYS:-7}"
opened_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
while [ $# -gt 0 ]; do
  case "$1" in
    --out-dir)
      out="$2"
      shift 2
      ;;
    --sprint-days)
      sprint_days="$2"
      shift 2
      ;;
    --opened-at)
      opened_at="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done
[ -f "$FILE" ] || {
  echo "no such file: $FILE" >&2
  exit 1
}
out="${out:-$(mktemp -d)}"
mkdir -p "$out"

errors=()
err() { errors+=("$1"); }

# ── Front matter ─────────────────────────────────────────────────────────
[ "$(head -1 "$FILE")" = "---" ] || err "missing YAML front matter (first line must be ---)"
front="$(awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f' "$FILE")"
field() { sed -n "s/^$1:[[:space:]]*//p" <<< "$front" | sed 's/[[:space:]]*#.*$//; s/^"//; s/"$//' | head -1; }
for key in lab lab_ref source_feature source_commit completed_at learners proposed_feature; do
  [ -n "$(field "$key")" ] || err "front matter: '${key}' is missing or empty"
done
lab="$(field lab)"
source_feature="$(field source_feature)"
source_commit="$(field source_commit)"
proposed="$(field proposed_feature)"
[[ -z "$proposed" || "$proposed" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || err "proposed_feature '${proposed}' must be a kebab-case slug"
[[ -z "$source_feature" || "$source_feature" =~ ^docs/ai-sdlc/ ]] || err "source_feature must be a docs/ai-sdlc/<feature> path"

# ── Sections ─────────────────────────────────────────────────────────────
body="$(awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{f=0; done=1; next} !f && done' "$FILE")"
section() { # section <heading-regex>: text under a heading, up to the next heading of level <= its own
  awk -v h="$1" '
    $0 ~ "^#+ " {
      level = length($0) - length(substr($0, index($0, " ")))
      if (on && level <= lvl) exit
      if ($0 ~ h) { on = 1; lvl = level; next }
    }
    on' <<< "$body"
}
for h in '^# Dojo Feedback:' '^## Lab Results$' '^## Gaps$' '^## Proposed Intent$' '^### Problem$' '^### Desired outcome$' '^### Out of scope$'; do
  grep -qE "$h" <<< "$body" || err "missing heading matching: ${h}"
done

gaps="$(section '^## Gaps$')"
no_gaps=false
if grep -qE '^None\.?[[:space:]]*$' <<< "$gaps" && ! grep -qE '^### GAP-' <<< "$gaps"; then
  no_gaps=true
else
  gap_count="$(grep -cE '^### GAP-[0-9]+: .+' <<< "$gaps" || true)"
  [ "$gap_count" -gt 0 ] || err "## Gaps must list '### GAP-NN: title' entries (or the single line 'None.')"
  # every gap needs a known type and non-empty evidence
  while IFS= read -r gap; do
    block="$(awk -v g="$gap" '$0 == g {on=1; next} on && /^### /{exit} on' <<< "$gaps")"
    type="$(sed -n 's/^- \*\*Type:\*\*[[:space:]]*//p' <<< "$block" | head -1)"
    [[ "$type" =~ ^(guardrail|prompt|spec|plan|lab)$ ]] || err "${gap#\#\#\# }: Type must be one of guardrail|prompt|spec|plan|lab (got '${type}')"
    [ -n "$(sed -n 's/^- \*\*Evidence:\*\*[[:space:]]*//p' <<< "$block")" ] || err "${gap#\#\#\# }: Evidence is required"
  done < <(grep -E '^### GAP-[0-9]+: ' <<< "$gaps")
fi

problem="$(section '^### Problem$' | sed '/./,$!d')"
outcome="$(section '^### Desired outcome$' | sed '/./,$!d')"
out_of_scope="$(section '^### Out of scope$' | sed '/./,$!d')"
if ! $no_gaps; then
  [ -n "$problem" ] || err "### Problem is empty"
  [ -n "$outcome" ] || err "### Desired outcome is empty"
fi

if [ "${#errors[@]}" -gt 0 ]; then
  echo "❌ ${FILE} is not a valid dojo-feedback.md:" >&2
  printf '  - %s\n' "${errors[@]}" >&2
  exit 1
fi
if $no_gaps; then
  echo "no-gaps"
  exit 0
fi

# ── Render issue + draft intent ──────────────────────────────────────────
due="$(date -u -d "${opened_at} + ${sprint_days} days" +%Y-%m-%d 2> /dev/null \
  || date -u -j -v+"${sprint_days}"d -f '%Y-%m-%dT%H:%M:%SZ' "$opened_at" +%Y-%m-%d)"
intent_path="docs/ai-sdlc/${proposed}/intent.md"
gap_titles="$(grep -E '^### GAP-[0-9]+: ' <<< "$gaps" | sed 's/^### /- /')"
marker="<!-- dojo-feedback: ${FILE} -->"

cat > "$out/intent.md" << EOF
# Intent — ${proposed}

Status: DRAFT — from Dojo feedback on \`${lab}\` (\`${FILE}\`); built from
\`${source_feature}\` @ \`${source_commit:0:12}\`. Due: ${due}.

## Problem

${problem}

## Gaps this cycle addresses

${gap_titles}

Details and evidence: \`${FILE}\`.

## Desired outcome

${outcome}

## Out of scope

${out_of_scope:-- (none stated)}
EOF

echo "intent: ${proposed} (from Dojo lab ${lab})" > "$out/issue-title.txt"
echo "$intent_path" > "$out/intent-path.txt"
echo "$marker" > "$out/marker.txt"
cat > "$out/issue.md" << EOF
${marker}
The Dojo lab \`${lab}\` (built from \`${source_feature}\` @ \`${source_commit:0:12}\`)
surfaced gaps that restart the AI-SDLC cycle — see \`${FILE}\`.

**Gaps**

${gap_titles}

**Next step (due ${due}, one sprint = ${sprint_days} days):** commit the draft below as
\`${intent_path}\` in a PR whose description says \`Closes #<this issue>\`, then
continue with the \`spec\` stage. Edit the draft freely — humans decide the intent.

<details><summary>Draft <code>${intent_path}</code></summary>

\`\`\`\`markdown
$(cat "$out/intent.md")
\`\`\`\`

</details>

_Opened by \`dojo-feedback-intent.yml\` (\`docs/ai-sdlc/dojo-handoff.md\`)._
EOF

echo "$out"
