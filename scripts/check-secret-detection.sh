#!/usr/bin/env bash
# scripts/check-secret-detection.sh — the runnable half of the secret-detection
# agent skill (.agents/skills/security-testing/secret-detection/).
#
# The skill declares Outputs `secrets.json` (SKILL.md:33-36) and a "Secret Types
# Detected" table (SKILL.md:47-55). Until now nothing produced that JSON and
# nothing read it, so the skill was advisory only. This script implements the
# declared contract and is the first agent-skill validator wired to fail a PR
# (.github/workflows/agent-ci.yml).
#
# Design note — the skill's pattern table mixes two different kinds of entry:
#
#   1. Credential-SHAPED patterns (AKIA…, ghp_…, xox…, PEM private-key headers)
#      These are unambiguous. A match is a real finding. BLOCKING.
#
#   2. Bare KEYWORDS (token, password, bearer, jwt, api_key)
#      These are a catalogue of secret *types*, not detection regexes. Matched
#      literally they fire on ordinary prose and on schema examples — this very
#      repo has "token budget" in AGENTS.md and `"password": "string"` in  # pragma: allowlist secret
#      interface-definition/SKILL.md. A validator that cries wolf on day one gets
#      deleted, which is worse than not having one. So keyword hits are counted
#      and reported as an INVENTORY and never affect the exit code.
#
# Assignment-shaped credentials (e.g. `AWS_SECRET_ACCESS_KEY=<literal>`) sit
# between the two: the keyword alone is too weak, but a keyword bound to a
# literal value that is neither a placeholder nor a K8s reference is a genuine
# finding. Those are BLOCKING too.
#
# False-positive policy:
#   - `# pragma: allowlist secret` on the line suppresses a finding. This is the
#     convention documented in AGENTS.md:100 and already honoured by the
#     pre-commit gitleaks/detect-secrets hooks. This script implements it for the
#     patterns above.
#   - A placeholder value (changeme, example, <redacted>, ${VAR}, …) is not a
#     finding.
#   - K8s reference keys (secretKeyRef, secretName, external-secrets) name a
#     Secret, they do not contain one.
#
# This validator is complementary to, not a replacement for, gitleaks: gitleaks
# runs in .github/workflows/secret-scan.yml and as a pre-commit hook. This one
# asserts the agent skill's own declared contract, so the skill is executable
# rather than aspirational.
#
# Usage:
#   scripts/check-secret-detection.sh [--json PATH] [--quiet] [--no-json] [PATH...]
#
# Exit codes:
#   0  no credential-shaped findings  (inventory warnings may still print)
#   1  at least one credential-shaped finding
#   2  usage or internal error

set -euo pipefail
cd "$(dirname "$0")/.."

JSON_OUT=".agents/logs/secret-detection.json"
QUIET=0
WRITE_JSON=1
CHUNK_SIZE=200
declare -a TARGETS=()

# ---------------------------------------------------------------------------
# Blocking patterns. Each entry: <id>|<POSIX ERE>
# ERE (not PCRE) so grep -E is portable and no extra dependency is needed.
# Every regex here MUST be a single line: an ERE cannot span lines, and a
# multi-line group fails with "grep: Unmatched ( or \(", which silently
# disables the guard it was meant to provide.
# ---------------------------------------------------------------------------
SHAPED_PATTERNS=(
  'aws_access_key_id|(A3T[A-Z0-9]|AKIA|ASIA|ABIA|ACCA)[A-Z0-9]{16}'
  'github_token|gh[pousr]_[A-Za-z0-9]{36,}'
  'github_pat|github_pat_[A-Za-z0-9_]{40,}'
  'slack_token|xox[baprs]-[A-Za-z0-9-]{10,}'
  'private_key|-----BEGIN( [A-Z]+)* PRIVATE KEY-----'
  'stripe_key|(sk|rk)_(live|test)_[A-Za-z0-9]{16,}'
  'google_api_key|AIza[0-9A-Za-z_-]{35}'
  'npm_token|npm_[A-Za-z0-9]{36}'
  'json_web_token|eyJ[A-Za-z0-9_-]{8,}\.eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}'
  'sendgrid_key|SG\.[A-Za-z0-9_-]{16,}\.[A-Za-z0-9_-]{16,}'
  'gitlab_token|glpat-[A-Za-z0-9_-]{20,}'
)

# Keyword half of a KEY=VALUE / "key": "value" credential. The value must look
# like a literal credential: 12+ chars, credential charset, no interpolation.
ASSIGN_KEYWORDS='(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret|access[_-]?key|auth[_-]?token|token|password|passwd|pwd)'
# 'grep -oE' rather than 'sed s///' for the value: on a non-match sed prints its
# input UNCHANGED, so a failed extraction used to hand back the whole line and
# every non-matching line was reported as a credential.
ASSIGN_VALUE='[A-Za-z0-9_./+=&-]{12,}'
ASSIGN_RE="(${ASSIGN_KEYWORDS})[\"']?[[:space:]]*[:=][[:space:]]*[\"']?${ASSIGN_VALUE}"

# Lowercased form, for value extraction. Done by hand rather than with `sed /I`
# or `grep -P`, which are GNU extensions that break on macOS.
LC_KEYWORDS='(api[_-]?key|apikey|secret[_-]?key|client[_-]?secret|access[_-]?key|auth[_-]?token|token|password|passwd|pwd)'

# A value matching any of these is a placeholder or a reference, not a secret.
PLACEHOLDER_RE='^(invalid|none|null|nil|true|false|undefined|empty|default|omit|unused|n/a)$'
PLACEHOLDER_SUBSTR='(changeme|change_me|change-me|example|placeholder|dummy|sample|fake|redacted|redact|\*\*\*+|x{4,}|\.\.\.|replace_me|replace-me|insert[_-]?here|your[_-]?|not[_-]?a[_-]?secret|no[_-]?secret|secretkeyref|secretnameref|secretgenerator|ext(ernal)?[-_ ]?secrets?|<[^>]*>|\$\{[A-Za-z_][A-Za-z0-9_]*\}|\$[A-Z_][A-Z0-9_]*|\{\{[^}]*\}\})'

# K8s/GitOps keys that REFERENCE a Secret rather than hold one.
REFERENCE_RE='(secretKeyRef|secretName|secretGenerator|secretRef|secrets:|existingSecret|envFrom)'

# Files expected to contain credential-shaped noise. Single line only.
EXCLUDE_RE='(^\.secrets\.baseline$|^scripts/testdata/secret-detection/|\.lock\.json$|(^|/)(node_modules|\.git|dist|build|coverage)/|\.min\.(js|css)$|(^|/)package-lock\.json$|(^|/)yarn\.lock$|(^|/)pnpm-lock\.yaml$|(^|/)poetry\.lock$|(^|/)Cargo\.lock$|(^|/)go\.sum$)'

# ---------------------------------------------------------------------------
# Arg parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --json)
      JSON_OUT="${2:?--json needs a path}"
      shift 2
      ;;
    --no-json)
      WRITE_JSON=0
      shift
      ;;
    --quiet)
      QUIET=1
      shift
      ;;
    -h | --help)
      sed -n '2,46p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    --)
      shift
      while [ $# -gt 0 ]; do
        TARGETS+=("$1")
        shift
      done
      ;;
    -*)
      echo "unknown option: $1" >&2
      exit 2
      ;;
    *)
      TARGETS+=("$1")
      shift
      ;;
  esac
done

# ---------------------------------------------------------------------------
# Build the file list
# ---------------------------------------------------------------------------
declare -a FILES=()
if [ "${#TARGETS[@]}" -eq 0 ]; then
  while IFS= read -r f; do FILES+=("$f"); done < <(git ls-files)
else
  for t in "${TARGETS[@]}"; do
    if [ -d "$t" ]; then
      # Strip the './' that 'find .' prepends. EXCLUDE_RE is anchored with '^'
      # for precision, and './scripts/testdata/...' does not match
      # '^scripts/testdata/...' — so without this every anchored exclusion was
      # silently dead whenever the scan was pointed at a directory.
      while IFS= read -r f; do FILES+=("${f#./}"); done < <(find "$t" -type f | sort)
    elif [ -f "$t" ]; then
      FILES+=("${t#./}")
    fi
  done
fi

# Filter the path list in one grep rather than one grep per file: the per-file
# form meant 367 spawns before the scan even started.
declare -a scannable=()
if [ "${#FILES[@]}" -gt 0 ]; then
  while IFS= read -r f; do
    [ -n "$f" ] || continue
    [ -f "$f" ] || continue
    [ -r "$f" ] || continue
    scannable+=("$f")
  done < <(printf '%s\n' "${FILES[@]}" | grep -vE -e "$EXCLUDE_RE" || true)
fi

scanned_count="${#scannable[@]}"
if [ "$scanned_count" -eq 0 ]; then
  echo "check-secret-detection: nothing to scan" >&2
  exit 2
fi

# ---------------------------------------------------------------------------
# Scan
#
# Performance: the tree is scanned in a handful of processes, not two per file.
# A naive per-file loop meant ~674 spawns for 337 files and took 30s, nearly all
# of it process overhead — only one line in this repo matches any pattern. Files
# are chunked so a large tree cannot blow past ARG_MAX.
# ---------------------------------------------------------------------------
declare -a FINDINGS=()
declare -A INVENTORY=()

# Only the REGEX half of each entry may go in here. Joining the whole
# 'id|regex' entry makes the pattern table match its own identifiers
# ('aws_access_key_id' matches the id text of its own rule).
SHAPED_ONLY_RE=''
sep=''
for entry in "${SHAPED_PATTERNS[@]}"; do
  SHAPED_ONLY_RE="${SHAPED_ONLY_RE}${sep}${entry#*|}"
  sep='|'
done

# Shaped patterns are case-SENSITIVE on purpose: an AWS key id is uppercase by
# definition, and loosening it only adds false positives. The assignment form is
# case-INSENSITIVE because real assignments are conventionally uppercase env vars
# (PASSWORD=, TOKEN=) and would otherwise never be seen by a case-sensitive
# sweep. So they are two passes, not one.

# Classify one already-matched line. Echoes nothing and returns 1 to skip.
classify() {
  local body="$1" hid='' entry hval
  case "$body" in
    *'pragma: allowlist secret'*) return 1 ;;
  esac

  for entry in "${SHAPED_PATTERNS[@]}"; do
    if printf '%s' "$body" | LC_ALL=C grep -qE -e "${entry#*|}"; then
      hid="${entry%%|*}"
      break
    fi
  done

  if [ -z "$hid" ]; then
    # No shaped pattern fired, so this is the assignment form. Its keyword alone
    # is too weak, so the value has to earn the finding.
    if printf '%s' "$body" | LC_ALL=C grep -qiE -e "$PLACEHOLDER_SUBSTR"; then return 1; fi
    if printf '%s' "$body" | LC_ALL=C grep -qiE -e "$REFERENCE_RE"; then return 1; fi
    hval="$(printf '%s' "$body" | tr '[:upper:]' '[:lower:]' \
      | grep -oE "${LC_KEYWORDS}[\"']?[[:space:]]*[:=][[:space:]]*[\"']?${ASSIGN_VALUE}" \
      | head -1 \
      | sed -E "s/^${LC_KEYWORDS}[\"']?[[:space:]]*[:=][[:space:]]*[\"']?//")"
    [ -n "$hval" ] || return 1
    if printf '%s' "$hval" | LC_ALL=C grep -qiE -e "$PLACEHOLDER_RE"; then return 1; fi
    hid=assigned_credential
  fi

  printf '%s' "$hid"
}

scan_chunk() {
  local files=("$@")
  local hit rest hfile hline hbody hid

  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    hfile="${hit%%:*}"
    rest="${hit#*:}"
    hline="${rest%%:*}"
    hbody="${rest#*:*}"
    hid="$(classify "$hbody" || true)"
    [ -n "$hid" ] || continue
    FINDINGS+=("${hid}|${hfile}|${hline}|$(printf '%s' "$hbody" | sed 's/^[[:space:]]*//' | cut -c1-120)")
  done < <(
    {
      LC_ALL=C grep -nHE -e "$SHAPED_ONLY_RE" "${files[@]}" 2> /dev/null || true
      LC_ALL=C grep -nHEi -e "$ASSIGN_RE" "${files[@]}" 2> /dev/null || true
    } | LC_ALL=C sort -u
  )

  # Non-blocking keyword inventory, all six counters in one awk pass.
  local k1 k2 k3 k4 k5 k6
  while read -r k1 k2 k3 k4 k5 k6; do
    [ -n "${k1:-}${k2:-}${k3:-}${k4:-}${k5:-}${k6:-}" ] || continue
    if [ "${k1:-0}" -gt 0 ]; then INVENTORY[token]=$((${INVENTORY[token]:-0} + k1)); fi
    if [ "${k2:-0}" -gt 0 ]; then INVENTORY[password]=$((${INVENTORY[password]:-0} + k2)); fi
    if [ "${k3:-0}" -gt 0 ]; then INVENTORY[secret]=$((${INVENTORY[secret]:-0} + k3)); fi
    if [ "${k4:-0}" -gt 0 ]; then INVENTORY[api_key]=$((${INVENTORY[api_key]:-0} + k4)); fi
    if [ "${k5:-0}" -gt 0 ]; then INVENTORY[bearer]=$((${INVENTORY[bearer]:-0} + k5)); fi
    if [ "${k6:-0}" -gt 0 ]; then INVENTORY[jwt]=$((${INVENTORY[jwt]:-0} + k6)); fi
  done < <(LC_ALL=C awk '
    { lt = tolower($0)
      if (lt !~ /token|password|secret|api_key|bearer|jwt/) next
      print (lt ~ /token/)+0, (lt ~ /password/)+0, (lt ~ /secret/)+0, (lt ~ /api_key/)+0, (lt ~ /bearer/)+0, (lt ~ /jwt/)+0
    }
  ' "${files[@]}" 2> /dev/null || true)
}

# Chunked so a large tree cannot exceed ARG_MAX in a single execve.
declare -a CHUNK=()
for f in "${scannable[@]}"; do
  CHUNK+=("$f")
  if [ "${#CHUNK[@]}" -ge "$CHUNK_SIZE" ]; then
    scan_chunk "${CHUNK[@]}"
    CHUNK=()
  fi
done
if [ "${#CHUNK[@]}" -gt 0 ]; then scan_chunk "${CHUNK[@]}"; fi

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------
finding_count="${#FINDINGS[@]}"
if [ "$finding_count" -gt 0 ]; then status=fail; else status=pass; fi

if [ "$QUIET" -eq 0 ]; then
  echo "== secret-detection: agent skill validator =="
  echo "  skill:   .agents/skills/security-testing/secret-detection/SKILL.md"
  echo "  files:   ${scanned_count} scanned"
  if [ "$finding_count" -gt 0 ]; then
    echo "  status:  FAIL — ${finding_count} finding(s)"
    echo
    for item in "${FINDINGS[@]}"; do
      id="${item%%|*}"
      rest="${item#*|}"
      file="${rest%%|*}"
      rest2="${rest#*|}"
      lineno="${rest2%%|*}"
      snippet="${rest2#*|}"
      echo "  [${id}] ${file}:${lineno}"
      echo "      ${snippet}"
      if [ -n "${GITHUB_ACTIONS:-}" ]; then
        echo "::error file=${file},line=${lineno}::secret-detection: ${id}"
      fi
    done
    echo
    echo "  Fix the finding, or suppress a false positive with a trailing"
    echo "  '# pragma: allowlist secret' on the offending line (AGENTS.md:100)."
  else
    echo "  status:  PASS — no credential-shaped findings"
  fi

  if [ "${#INVENTORY[@]}" -gt 0 ]; then
    echo
    echo "  inventory (non-blocking keyword occurrences, not findings):"
    for kw in token password secret api_key bearer jwt; do
      if [ -n "${INVENTORY["$kw"]:-}" ]; then
        printf '    %-10s %s\n' "$kw" "${INVENTORY[$kw]}"
      fi
    done
    echo "    ^ these are secret *type* keywords, not detections. They do not"
    echo "      affect the exit code by design; see the script's design note."
  fi
fi

# ---------------------------------------------------------------------------
# Emit the skill's declared output artifact: secrets.json
# Matches the schema the skill documents (SKILL.md:67-76).
# ---------------------------------------------------------------------------
if [ "$WRITE_JSON" -eq 1 ]; then
  mkdir -p "$(dirname "$JSON_OUT")"
  {
    printf '{\n'
    printf '  "skill": "secret-detection",\n'
    printf '  "status": "%s",\n' "$status"
    printf '  "validator": "scripts/check-secret-detection.sh",\n'
    printf '  "files_scanned": %s,\n' "$scanned_count"
    printf '  "gitleaks": { "status": "not_run_by_this_validator", "runner": ".github/workflows/secret-scan.yml" },\n'
    printf '  "container_secrets": { "status": "not_run_by_this_validator", "reason": "source-tree scan only; image layers are out of scope for this script" },\n'
    printf '  "artifacts_verified": { "status": "not_run_by_this_validator", "reason": "integrity.json is produced by secret-detection/integrity, not here" },\n'
    printf '  "inventory": {'
    first=1
    for kw in token password secret api_key bearer jwt; do
      if [ -n "${INVENTORY["$kw"]:-}" ]; then
        [ $first -eq 1 ] || printf ','
        first=0
        printf ' "%s": %s' "$kw" "${INVENTORY[$kw]}"
      fi
    done
    printf ' },\n'
    printf '  "issues": ['
    if [ "$finding_count" -eq 0 ]; then
      printf ']\n'
    else
      printf '\n'
      for idx in "${!FINDINGS[@]}"; do
        item="${FINDINGS[$idx]}"
        id="${item%%|*}"
        rest="${item#*|}"
        file="${rest%%|*}"
        rest2="${rest#*|}"
        lineno="${rest2%%|*}"
        snippet="${rest2#*|}"
        esc_snippet="${snippet//\\/\\\\}"
        esc_snippet="${esc_snippet//\"/\\\"}"
        esc_file="${file//\\/\\\\}"
        esc_file="${esc_file//\"/\\\"}"
        comma=,
        if [ "$idx" -eq $((finding_count - 1)) ]; then comma=; fi
        printf '    { "rule": "%s", "file": "%s", "line": %s, "snippet": "%s" }%s\n' \
          "$id" "$esc_file" "$lineno" "$esc_snippet" "$comma"
      done
      printf '  ]\n'
    fi
    printf '}\n'
  } > "$JSON_OUT"

  # A broken validator must never report itself as a pass. If the JSON we just
  # wrote does not parse, fail loudly rather than emitting a lie.
  if command -v jq > /dev/null 2>&1; then
    if ! jq -e . "$JSON_OUT" > /dev/null 2>&1; then
      echo "ERROR: emitted $JSON_OUT is not valid JSON — validator is broken" >&2
      exit 2
    fi
  fi
  if [ "$QUIET" -eq 0 ]; then echo "  wrote:   ${JSON_OUT}"; fi
fi

[ "$finding_count" -eq 0 ] || exit 1
exit 0
