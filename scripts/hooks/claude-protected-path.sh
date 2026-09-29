#!/usr/bin/env bash
# claude-protected-path.sh — Claude Code PreToolUse (Edit|Write) guard.
#
# Reads the hook JSON on stdin and denies edits to paths matched by
# scripts/hooks/protected-paths.json, the same rules the opencode plugin
# (.opencode/plugins/ai-sdlc-hooks.ts) enforces. Prints a deny decision on
# stdout; prints nothing to allow. Fails closed: unreadable input or config
# denies rather than allows.

set -euo pipefail

ROOT="${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel 2> /dev/null || pwd)}"

PAYLOAD="$(cat)"

ROOT="$ROOT" PAYLOAD="$PAYLOAD" python3 - << 'PY'
import json, os, re, sys


def deny(reason: str) -> None:
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    }}))


try:
    path = json.loads(os.environ["PAYLOAD"]).get("tool_input", {}).get("file_path", "") or ""
    with open(os.path.join(os.environ["ROOT"], "scripts/hooks/protected-paths.json")) as fh:
        cfg = json.load(fh)
except Exception as exc:  # fail closed, and say why
    deny(f"protected-path guard could not run: {exc}")
    sys.exit(0)

segments = [s for s in os.path.normpath(path).replace("\\", "/").split("/") if s]
basename = segments[-1] if segments else ""
if any(seg in segments for seg in cfg.get("protectedPathSegments", [".git"])):
    deny(f"Protected path: {path}")
elif any(re.search(p, basename) for p in cfg["protectedBasenamePatterns"]):
    deny(f"Protected path: {path}")
PY
