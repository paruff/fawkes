#!/usr/bin/env bash
# scripts/check-agents.sh — the 4 execution-boundary agents must be valid
# AND dispatchable. Canonical source: .agents/agents/; harness mounts are
# symlinks into it. OpenCode's reviewer agents live in .opencode/agents/ and
# have no canonical counterpart (they are OpenCode-specific).

set -euo pipefail

cd "$(dirname "$0")/.."

CANONICAL=".agents/agents"
MOUNT=".opencode/agents"

EXPECTED=(planner builder verifier operator)

FAIL=0
ok() { printf '  OK   %s\n' "$1"; }
bad() {
  printf '  FAIL %s\n' "$1"
  FAIL=1
}

echo "== Agent dispatch check =="

for agent in "${EXPECTED[@]}"; do
  file="$CANONICAL/$agent.md"
  link="$MOUNT/$agent.md"

  if [[ ! -f "$file" ]]; then
    bad "$agent: canonical file missing ($file)"
    continue
  fi
  ok "$agent: canonical file present"

  # .opencode/agents are OpenCode-specific reviewer agents (no canonical counterpart)
  if [[ "$MOUNT" = ".opencode/agents" ]]; then
    ok "$agent: OpenCode-specific reviewer agent (no symlink required)"
    # Still validate frontmatter on the canonical file
  else
    # The harness mount must be a symlink into .agents/ so there is one source.
    if [[ ! -L "$link" ]]; then
      bad "$agent: $link is not a symlink (harness would load a separate copy)"
    elif [[ ! -e "$link" ]]; then
      bad "$agent: $link is DANGLING"
    elif [[ "$(realpath "$link")" != "$(realpath "$file")" ]]; then
      bad "$agent: $link points somewhere other than $file"
    else
      ok "$agent: mounted into $MOUNT"
    fi
  fi

  # Frontmatter must be delimited and parseable.
  if ! head -1 "$file" | grep -q '^---$'; then
    bad "$agent: no YAML frontmatter"
    continue
  fi
  fm_end="$(awk 'NR>1 && /^---$/{print NR; exit}' "$file")"
  if [[ -z "$fm_end" ]]; then
    bad "$agent: unterminated frontmatter"
    continue
  fi
  ok "$agent: frontmatter delimited (lines 2-$((fm_end - 1)))"

  fm="$(sed -n "2,$((fm_end - 1))p" "$file")"

  # name must match the filename, or dispatch by @name breaks.
  if ! grep -q "^name: $agent$" <<< "$fm"; then
    bad "$agent: name mismatch (frontmatter 'name' must be '$agent')"
  else
    ok "$agent: name matches filename"
  fi

  # description is required for discoverability.
  if ! grep -q "^description:" <<< "$fm"; then
    bad "$agent: missing description"
  else
    ok "$agent: has a description"
  fi

  # mode must be one of the valid modes; default is 'all'.
  if grep -q "^mode:" <<< "$fm"; then
    mode_val=$(grep "^mode:" <<< "$fm" | sed 's/^mode: *//')
    if [[ ! "$mode_val" =~ ^(primary|subagent|all)$ ]]; then
      bad "$agent: invalid mode '$mode_val' (must be primary|subagent|all)"
    else
      ok "$agent: mode=$mode_val (dispatchable)"
    fi
  else
    ok "$agent: mode=all (dispatchable)"
  fi

  # No unknown frontmatter keys.
  unknown_keys=$(grep -E '^[a-z]+:' <<< "$fm" | grep -vE "^(name|model|variant|description|mode|hidden|color|steps|options|permission|disable|temperature|top_p):" | cut -d: -f1 || true)
  if [[ -n "$unknown_keys" ]]; then
    bad "$agent: unknown frontmatter keys: $unknown_keys"
  else
    ok "$agent: no unknown frontmatter keys"
  fi

  # Every skill named on the "Skills loaded" line(s) must exist as a
  # SKILL.md under .agents/skills/ (top level or nested). A dangling name
  # means the harness loads nothing and the agent silently runs without it.
  # shellcheck disable=SC2016  # backticks are literal, matching markdown code spans
  skills=$(awk '/Skills loaded:/{f=1} f&&/Token cost:/{exit} f{print}' "$file" | grep -o '`[a-z0-9-]*`' | tr -d '`' || true)
  for skill in $skills; do
    if find .agents/skills -type f -path "*/${skill}/SKILL.md" 2> /dev/null | grep -q .; then
      ok "$agent: skill '$skill' exists"
    else
      bad "$agent: skill '$skill' not found under .agents/skills/"
    fi
  done
done

# -- retired-agent guard --
echo "-- retired-agent guard --"
shopt -s nullglob
for f in .agents/agents/*.md .opencode/agents/*.md; do
  [ -e "$f" ] || continue
  base=$(basename "$f" .md)
  if [[ ! " ${EXPECTED[*]} " =~ ${base} ]]; then
    bad "$f: retired stage/flow agent still present (must be one of: ${EXPECTED[*]})"
  fi
done
if [[ "$FAIL" -eq 0 ]]; then
  ok ".agents/agents: no retired stage/flow agents"
  ok ".opencode/agents: no retired stage/flow agents"
fi

echo "=========================="
if [[ "$FAIL" -eq 0 ]]; then
  echo "PASS: all 4 execution-boundary agents are valid and dispatchable."
  echo "NOTE: live invocation needs an opencode restart — agent config is not hot-reloaded."
else
  echo "FAIL: agent dispatch check found problems (see above)"
fi
exit $FAIL
