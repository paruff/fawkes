#!/usr/bin/env bash
#
# scripts/check-harness-parity.sh — verify every harness is wired to the one
# canonical .agents/ tree and stays in sync: no shadowing, no broken symlinks,
# no drifted MCP server sets, no reserved-name collisions. This is the
# automated version of the `doctor`/`oc-health` collision this repo found and
# fixed by hand — see docs/ai-sdlc/spec.md R5.
#
# Wiring contract: .agents/ is canonical. Everything a harness dispatches to
# is a symlink into it:
#   .opencode/{skills,commands}  -> ../.agents/{skills,commands}
#   .claude/{skills,commands}    -> ../.agents/{skills,commands}
#   .cursor/rules/AGENTS.md      -> ../../AGENTS.md
#   .github/copilot-instructions.md, CLAUDE.md, GEMINI.md, .cursorrules
#                                 -> AGENTS.md
# .opencode/agents is deliberately NOT a symlink: those three reviewer agents
# are OpenCode-specific and have no canonical counterpart.
#
# Exit 0 = clean. Exit 1 = drift found (fails CI and pre-commit).

set -euo pipefail
cd "$(dirname "$0")/.."

FAIL=0
say_ok() { printf '  OK   %s\n' "$1"; }
say_fail() {
  printf '  FAIL %s\n' "$1"
  FAIL=1
}

echo "== Harness parity check =="

# 0. Every symlink in the repo must resolve. A dangling harness symlink is
#    silent: the harness loads nothing, no error surfaces, and the agent
#    simply appears to have no skills or commands. `find -xtype l` reports
#    broken links specifically, which `test -e` alone does not.
echo "-- symlink resolution --"
broken_count=0
link_count=0
while IFS= read -r link; do
  link_count=$((link_count + 1))
  if [ -e "$link" ]; then
    say_ok "$(printf '%-40s -> %s' "$link" "$(readlink "$link")")"
  else
    say_fail "$(printf '%-40s -> %s  (DANGLING)' "$link" "$(readlink "$link")")"
    broken_count=$((broken_count + 1))
  fi
done < <(find . -maxdepth 3 -type l \
  -not -path './.git/*' \
  -not -path './opencode/*' \
  -not -path '*/node_modules/*' \
  | sed 's|^\./||' | sort)
if [ "$broken_count" -eq 0 ]; then
  say_ok "all $link_count symlink(s) resolve"
else
  say_fail "$broken_count of $link_count symlink(s) are dangling"
fi

# 1. .claude/{skills,commands} and .opencode/{skills,commands} must be
#    symlinks into the canonical .agents/ tree, not real directories. A real
#    directory here would silently shadow the canonical source instead of
#    sharing it — exactly the class of bug this check exists to catch
#    automatically. They must point at .agents/ DIRECTLY, not at each other:
#    .claude -> .opencode -> .agents is a chain that can break in the middle.
echo "-- canonical fan-out --"
for harness in .claude .opencode; do
  for pair in commands skills; do
    link="$harness/$pair"
    target=".agents/$pair"
    if [ -L "$link" ] && [ "$(realpath "$link" 2> /dev/null)" = "$(realpath "$target" 2> /dev/null)" ]; then
      say_ok "$link -> $target (symlink intact)"
    else
      say_fail "$link is not a symlink to $target (shadowing or indirection risk)"
    fi
  done
done

# 1b. The AGENTS.md aliases must be symlinks to the one source. A harness that
#     loads a stale copy of the policy is worse than one that loads none.
for alias in CLAUDE.md GEMINI.md .cursorrules .cursor/rules/AGENTS.md .github/copilot-instructions.md; do
  if [ ! -e "$alias" ]; then
    say_fail "$alias is missing (harness loads no policy)"
  elif [ -L "$alias" ] && [ "$(realpath "$alias" 2> /dev/null)" = "$(realpath AGENTS.md 2> /dev/null)" ]; then
    say_ok "$alias -> AGENTS.md"
  else
    say_fail "$alias is not a symlink to AGENTS.md"
  fi
done

# 2. MCP server sets must match between .opencode/opencode.json and .mcp.json —
#    the two harnesses should offer the same servers, even though each
#    keeps its own file (the two schemas aren't identical, see spec.md).
if [ -f .opencode/opencode.json ] && [ -f .mcp.json ]; then
  oc_servers=$(jq -r '.mcp // {} | keys | sort | join(",")' .opencode/opencode.json)
  cc_servers=$(jq -r '.mcpServers // {} | keys | sort | join(",")' .mcp.json)
  if [ "$oc_servers" = "$cc_servers" ]; then
    say_ok "MCP server sets match: $oc_servers"
  else
    say_fail "MCP server sets differ — opencode.json: [$oc_servers] vs .mcp.json: [$cc_servers]"
  fi
  # 2b. Same names is not enough: each server must launch the same pinned
  #     package (stdio) or hit the same URL (remote) in both files, and no
  #     stdio package may float on @latest.
  cc_specs=$(jq -r '.mcpServers | to_entries[] | "\(.key)=\(if .value.url then .value.url else (.value.args | join(" ")) end)"' .mcp.json | sort)
  oc_specs=$(jq -r '.mcp | to_entries[] | "\(.key)=\(if .value.url then .value.url else (.value.command[1:] | join(" ")) end)"' .opencode/opencode.json | sort)
  if [ "$cc_specs" = "$oc_specs" ]; then
    say_ok "MCP server launch specs match between harnesses"
  else
    say_fail "MCP server launch specs differ between .mcp.json and .opencode/opencode.json:"
    diff <(echo "$cc_specs") <(echo "$oc_specs") | sed 's/^/         /' || true
  fi
  if grep -q '@latest' .mcp.json .opencode/opencode.json; then
    say_fail "MCP config uses @latest — pin an exact version"
  else
    say_ok "no @latest in MCP config"
  fi
else
  say_fail "opencode.json or .mcp.json missing"
fi

# 3. No command/skill name may collide with a harness's own reserved
#    names. NOT EXHAUSTIVE — extend this list whenever a new collision is
#    found, the way `doctor` was found (and renamed to `oc-health`) this
#    session.
RESERVED_NAMES="doctor review help clear compact init model mcp plugin context hooks permissions config cost export login logout memory pr-comments resume status agents bug vim terminal-setup"
collision_found=0
for f in .agents/commands/*.md; do
  [ -e "$f" ] || continue
  name=$(basename "$f" .md)
  for reserved in $RESERVED_NAMES; do
    if [ "$name" = "$reserved" ]; then
      say_fail "command '$name' collides with a reserved/built-in name ($reserved)"
      collision_found=1
    fi
  done
done
for f in .agents/skills/*/SKILL.md; do
  [ -e "$f" ] || continue
  skill_dir=$(dirname "$f")
  name=$(basename "$skill_dir")
  for reserved in $RESERVED_NAMES; do
    if [ "$name" = "$reserved" ]; then
      say_fail "skill '$name' collides with a reserved/built-in name ($reserved)"
      collision_found=1
    fi
  done
done
if [ "$collision_found" -eq 0 ]; then
  say_ok "no command/skill names collide with the known reserved-name list"
fi

echo "=========================="
if [ "$FAIL" -eq 0 ]; then
  echo "PASS: no drift detected"
else
  echo "FAIL: drift detected — see above"
fi
exit $FAIL
