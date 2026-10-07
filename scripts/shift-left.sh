#!/usr/bin/env bash
# scripts/shift-left/shift-left.sh — run a uFawkesPipe shift-left tool at the
# rev this repo pins (uFawkes.dev docs/ai-sdlc/shift-left/spec.md).
#
# The hooks come from uFawkesPipe through .pre-commit-config.yaml; the tools
# that aren't hooks (doctor, agent-gate, shift-left-triage, require-tool) run
# from the same pinned clone, so one tag versions both. A consumer repo copies
# this one file to scripts/shift-left.sh; it is the only shift-left code it holds.
#
# Usage: shift-left.sh <tool> [args...]   e.g. doctor --quiet, agent-gate < hook.json
#   Runs scripts/shift-left/<tool>.sh with the arguments and stdin given.
#   In uFawkesPipe itself (or any repo with its own scripts/shift-left/<tool>.sh),
#   that local copy runs. Otherwise the uFawkesPipe repo and rev in
#   .pre-commit-config.yaml are looked up in pre-commit's cache, installing the
#   hook environments first if the clone isn't there yet.
set -euo pipefail

die() {
  echo "shift-left: $*" >&2
  exit 1
}
tool="${1:?usage: shift-left.sh <tool> [args...]}"
shift
root="$(git rev-parse --show-toplevel)" || die "not in a git repository"

if [[ -x "$root/scripts/shift-left/$tool.sh" ]]; then
  exec "$root/scripts/shift-left/$tool.sh" "$@"
fi

pinned="$(python3 -c '
import sys, yaml
for r in (yaml.safe_load(open(sys.argv[1])) or {}).get("repos") or []:
    url = str(r.get("repo", ""))
    if url.lower().rstrip("/").removesuffix(".git").endswith("paruff/ufawkespipe"):
        print(url, r.get("rev", ""))
        break
' "$root/.pre-commit-config.yaml")" || die "cannot read $root/.pre-commit-config.yaml"
[[ -n "$pinned" ]] || die "no paruff/uFawkesPipe repo in .pre-commit-config.yaml, so there is no pinned rev to run $tool from"
repo="${pinned% *}"
rev="${pinned##* }"

db="${PRE_COMMIT_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/pre-commit}/db.db"
lookup() {
  [[ -f "$db" ]] || return 0
  python3 -c '
import sqlite3, sys
row = sqlite3.connect(sys.argv[1]).execute("select path from repos where repo = ? and ref = ?", sys.argv[2:]).fetchone()
print(row[0] if row else "")
' "$db" "$repo" "$rev"
}
path="$(lookup)"
if [[ -z "$path" || ! -d "$path" ]]; then
  (cd "$root" && pre-commit install-hooks >&2) || die "pre-commit install-hooks failed"
  path="$(lookup)"
fi
[[ -x "$path/scripts/shift-left/$tool.sh" ]] || die "no tool $tool in $repo at $rev"
exec "$path/scripts/shift-left/$tool.sh" "$@"
