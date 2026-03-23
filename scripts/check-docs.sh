#!/usr/bin/env bash
# check-docs.sh — Audit MkDocs documentation for broken nav entries and stub pages.
#
# Usage:
#   ./scripts/check-docs.sh           # audit only, exits 1 if issues found
#   ./scripts/check-docs.sh --strict  # same behaviour, kept for compatibility
#
# Exit codes:
#   0 — no issues found
#   1 — one or more issues found

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MKDOCS_YML="${REPO_ROOT}/mkdocs.yml"
DOCS_DIR="${REPO_ROOT}/docs"

echo "=== Fawkes Documentation Audit ==="
echo "Repository : ${REPO_ROOT}"
echo "MkDocs cfg : ${MKDOCS_YML}"
echo ""

# ── Dependency check ──────────────────────────────────────────────────────────
if ! command -v mkdocs &>/dev/null; then
  echo "ERROR: mkdocs is not installed. Run: pip install mkdocs mkdocs-material"
  exit 1
fi

ISSUES=0
BUILD_FAILED=0

# Temporary directory for the build output (unique per run to support parallel CI jobs)
BUILD_DIR=$(mktemp -d)
trap 'rm -rf "${BUILD_DIR}"' EXIT

# ── mkdocs build --strict ─────────────────────────────────────────────────────
echo "--- Running mkdocs build --strict ---"
BUILD_OUTPUT=$(mkdocs build --strict --site-dir "${BUILD_DIR}" 2>&1) || BUILD_FAILED=1

# Print any WARNING lines from the build
WARNINGS=$(echo "${BUILD_OUTPUT}" | grep "^WARNING" || true)
if [[ -n "${WARNINGS}" ]]; then
  echo ""
  echo "⚠  MkDocs build warnings:"
  echo "${WARNINGS}"
  ISSUES=$((ISSUES + $(echo "${WARNINGS}" | wc -l)))
fi

# ── Nav entry audit ───────────────────────────────────────────────────────────
echo ""
echo "--- Nav entry audit ---"
NAV_MISSING=$(echo "${BUILD_OUTPUT}" | grep "included in the 'nav' configuration, which is not found" || true)
if [[ -n "${NAV_MISSING}" ]]; then
  echo "❌  Missing nav files:"
  echo "${NAV_MISSING}"
  ISSUES=$((ISSUES + $(echo "${NAV_MISSING}" | wc -l)))
else
  echo "✅  All nav entries point to existing files"
fi

# ── Stub file audit (nav files with <200 words) ───────────────────────────────
echo ""
echo "--- Stub file audit (nav files with <200 words) ---"
STUB_COUNT=0
# Extract .md paths from the nav: section only (lines after 'nav:' up to the next top-level key)
while IFS= read -r filepath; do
  fullpath="${DOCS_DIR}/${filepath}"
  if [[ -f "${fullpath}" ]]; then
    words=$(wc -w <"${fullpath}")
    if [[ "${words}" -lt 200 ]]; then
      echo "⚠  Stub: ${filepath} (${words} words — minimum 200 required)"
      STUB_COUNT=$((STUB_COUNT + 1))
    fi
  fi
done < <(awk '
  /^nav:/ { in_nav = 1; next }
  in_nav {
    if ($0 ~ /^[a-z]/) { exit }
    print
  }
' "${MKDOCS_YML}" | grep -oE '[a-zA-Z0-9_/.-]+\.md' | sort -u)

if [[ "${STUB_COUNT}" -eq 0 ]]; then
  echo "✅  No stub pages found (all nav files have ≥200 words)"
else
  echo "⚠  ${STUB_COUNT} stub page(s) found"
  ISSUES=$((ISSUES + STUB_COUNT))
fi

# ── TODO / Coming Soon audit ──────────────────────────────────────────────────
# Flag pages that consist of little more than a heading plus a TODO/Coming Soon
# placeholder — i.e. files under 200 words that also contain a standalone
# placeholder line.  Rich documents that mention "TODO" in code blocks or
# "Coming soon" in status tables are intentionally NOT flagged.
echo ""
echo "--- TODO/Coming Soon audit ---"
TODO_COUNT=0
while IFS= read -r filepath; do
  fullpath="${DOCS_DIR}/${filepath}"
  if [[ -f "${fullpath}" ]]; then
    words=$(wc -w <"${fullpath}")
    # Only flag short files (stub-like) that contain a standalone placeholder line
    if [[ "${words}" -lt 200 ]] && grep -qiE '^\s*(TODO:?|Coming [Ss]oon\.?)\s*$' "${fullpath}" 2>/dev/null; then
      echo "⚠  Placeholder content: ${filepath} (${words} words)"
      TODO_COUNT=$((TODO_COUNT + 1))
    fi
  fi
done < <(awk '
  /^nav:/ { in_nav = 1; next }
  in_nav {
    if ($0 ~ /^[a-z]/) { exit }
    print
  }
' "${MKDOCS_YML}" | grep -oE '[a-zA-Z0-9_/.-]+\.md' | sort -u)

if [[ "${TODO_COUNT}" -eq 0 ]]; then
  echo "✅  No TODO/Coming Soon placeholders found"
else
  echo "⚠  ${TODO_COUNT} file(s) contain placeholder content"
  ISSUES=$((ISSUES + TODO_COUNT))
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "=== Summary ==="
if [[ "${BUILD_FAILED}" -eq 1 ]]; then
  echo "❌  mkdocs build --strict FAILED"
  ISSUES=$((ISSUES + 1))
else
  echo "✅  mkdocs build --strict passed (exit 0)"
fi

if [[ "${ISSUES}" -gt 0 ]]; then
  echo "❌  Total issues: ${ISSUES}"
  exit 1
else
  echo "✅  All checks passed — no documentation issues found"
  exit 0
fi
