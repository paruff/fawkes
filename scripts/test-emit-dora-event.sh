#!/usr/bin/env bash
# scripts/test-emit-dora-event.sh — proves scripts/emit-dora-event.sh emits
# events uFawkesObs can ingest, offline:
#   - job-start / job-finish / deploy-marker are single-line JSON with
#     uFawkesPipe dora-log.sh's fields (@timestamp, level, logger, message,
#     pipeline, repo, step) plus status/duration_ms on job-finish;
#   - agent token usage is summed from `Agent-Tokens:` trailers, and PR
#     cycle time is computed from first commit → merge;
#   - deploy-marker's `dora_event` validates against uFawkesObs's
#     deployment-event.schema.json (vendored verbatim in scripts/testdata/,
#     from paruff/uFawkesObs@1e63ef56 dora/events/);
#   - the OTLP/HTTP export POSTs a valid logs payload to /v1/logs, and an
#     unreachable endpoint warns without failing.
# GitHub API calls are served by a stub `gh` with fixture data.
#
# Needs python3 and jq only (set PYTHON to override the interpreter). No
# third-party modules: the schema is a flat draft-07 object, so it is
# validated with the stdlib. That keeps this test runnable on any machine
# with a stock python3 instead of only where `pip install jsonschema` ran.
# Report-only. Exit 0 = every check passed.

set -euo pipefail
cd "$(dirname "$0")/.."

PYTHON="${PYTHON:-python3}"
EMIT="$PWD/scripts/emit-dora-event.sh"
SCHEMA="$PWD/scripts/testdata/ufawkesobs-deployment-event.schema.json"
for tool in "$PYTHON" jq; do
  command -v "$tool" > /dev/null 2>&1 || {
    echo "FAIL: required tool not found: $tool" >&2
    exit 1
  }
done

work="$(mktemp -d)"
trap 'kill "${listener_pid:-}" 2>/dev/null || true; rm -rf "$work"' EXIT
pass=0
failures=()
check() { # check <label> <jq-filter-that-must-be-true> <json>
  if jq -e "$2" > /dev/null 2>&1 <<< "$3"; then
    pass=$((pass + 1))
    echo "  ✅ $1"
  else
    failures+=("$1")
    echo "  ❌ $1"
    echo "$3" | head -c 600
    echo
  fi
}

# ── Fixtures: a PR with two AI-assisted commits reporting token usage ─────
mkdir -p "$work/bin"
cat > "$work/pr.json" << 'EOF'
{"number": 42, "created_at": "2026-09-27T09:00:00Z", "merged_at": "2026-09-27T12:30:00Z",
 "additions": 120, "deletions": 8, "commits": 2}
EOF
cat > "$work/commits.json" << 'EOF'
[
  {"commit": {"author": {"date": "2026-09-27T08:15:00Z"},
   "message": "feat: a\n\nAgent-Tokens: input=100 output=2000 cache_read=50000 cache_write=3000 model=claude-opus-5-5 source=claude-code\nCo-Authored-By: Claude <noreply@anthropic.com>"}},
  {"commit": {"author": {"date": "2026-09-27T11:00:00Z"},
   "message": "fix: b\n\nAgent-Tokens: input=5 output=800 cache_read=10000 cache_write=0 model=claude-sonnet-5 source=claude-code"}},
  {"commit": {"author": {"date": "2026-09-27T11:30:00Z"}, "message": "docs: human-only change"}}
]
EOF
cat > "$work/bin/gh" << EOF
#!/usr/bin/env bash
# stub: serve fixture JSON for the two endpoints emit-dora-event.sh calls
case "\$*" in
  *pulls/42/commits*) cat "$work/commits.json" ;;
  *pulls/42*) cat "$work/pr.json" ;;
  *) echo "unexpected gh call: \$*" >&2; exit 1 ;;
esac
EOF
chmod +x "$work/bin/gh"
echo '{"pull_request": {"number": 42}}' > "$work/event.json"

export PATH="$work/bin:$PATH"
export GITHUB_REPOSITORY=acme/widget GITHUB_RUN_NUMBER=17 GITHUB_RUN_ID=9001 GITHUB_JOB=ci
export GITHUB_SERVER_URL=https://github.com GITHUB_EVENT_PATH="$work/event.json"
export GITHUB_SHA=0123456789abcdef0123456789abcdef01234567
export OTEL_SERVICE_NAME=widget RUNNER_TEMP="$work" DORA_EVENTS_FILE="$work/events.jsonl"
unset OTEL_EXPORTER_OTLP_ENDPOINT OTEL_EXPORTER_OTLP_HEADERS

echo "== Event shape (dora-log.sh fields) =="
start="$("$EMIT" job-start --step pipeline --at 2026-09-27T12:40:00Z)"
finish="$("$EMIT" job-finish --step pipeline --at 2026-09-27T12:47:30Z)"
deploy="$("$EMIT" deploy-marker --step pipeline --at 2026-09-27T12:48:00Z --environment production)"
for pair in "job-start:$start" "job-finish:$finish" "deploy-marker:$deploy"; do
  name="${pair%%:*}" json="${pair#*:}"
  check "${name}: one line of JSON" '(type == "object")' "$json"
  [ "$(printf '%s\n' "$json" | wc -l)" -eq 1 ] || failures+=("${name}: not a single line")
  check "${name}: dora-log.sh fields" \
    'has("@timestamp") and has("level") and has("logger") and has("message") and has("pipeline") and has("repo") and has("step")' "$json"
  check "${name}: event, service, commit, pipeline_url" \
    ".event == \"${name}\" and .service == \"widget\" and .repo == \"acme/widget\" and .pipeline == \"17\" and (.pipeline_url | endswith(\"/runs/9001\"))" "$json"
done
check "job-finish: status + duration_ms from job-start" '.status == "success" and .duration_ms == 450000' "$finish"
check "events file has all three lines" '. == 3' "$(wc -l < "$work/events.jsonl")"

echo "== Agent token usage and PR cycle time =="
check "tokens summed across trailers" \
  '.agent_tokens.input == 105 and .agent_tokens.output == 2800 and .agent_tokens.cache_read == 60000 and .agent_tokens.cache_write == 3000' "$finish"
check "reporting/total/AI-co-authored commit counts" \
  '.agent_tokens.commits_reporting == 2 and .agent_tokens.commits_total == 3 and .agent_tokens.ai_coauthored_commits == 1' "$finish"
check "models listed" '.agent_tokens.models == ["claude-opus-5-5", "claude-sonnet-5"]' "$finish"
check "PR cycle time = first commit → merge (4h15m)" \
  '.pr.number == 42 and .pr.first_commit_at == "2026-09-27T08:15:00Z" and .pr.merged_at == "2026-09-27T12:30:00Z" and .pr.cycle_time_seconds == 15300' "$deploy"
check "PR size" '.pr.lines_added == 120 and .pr.lines_deleted == 8 and .pr.commits == 2' "$deploy"

echo "== deploy-marker dora_event vs uFawkesObs deployment-event.schema.json =="
jq '.dora_event' <<< "$deploy" > "$work/dora_event.json"
if out="$(
  "$PYTHON" - "$SCHEMA" "$work/dora_event.json" 2>&1 << 'PY'
# Stdlib draft-07 subset validator. The vendored schema is a flat object using
# type, required[], properties{}, additionalProperties:false, enum, pattern and
# "format": date-time / uri. Anything outside that subset raises rather than
# silently passing, so this cannot drift into a laxer check than jsonschema
# gave us.
import datetime, json, re, sys, urllib.parse

schema, event = (json.load(open(p)) for p in sys.argv[1:3])
errors = []
# additionalProperties:false IS supported (see below); the schema-valued form
# is not, so only the object form is allowed through.
UNSUPPORTED = ("$ref", "anyOf", "oneOf", "allOf", "not", "patternProperties",
               "dependencies", "if", "then", "else")

def walk(node, sch, path):
    if isinstance(sch, dict):
        for key in UNSUPPORTED:
            if key in sch:
                errors.append(f"{path or '<root>'}: unsupported schema keyword {key!r} "
                              f"— extend this validator before trusting the result")
        ap = sch.get("additionalProperties")
        if ap is not None and ap is not False:
            errors.append(f"{path or '<root>'}: schema-valued additionalProperties "
                          f"is not supported by this validator")
    if not isinstance(sch, dict) or not isinstance(node, dict):
        return
    for key in sch.get("required", []):
        if key not in node:
            errors.append(f"{path}.{key}: required property is missing")
    props = sch.get("properties", {})
    if sch.get("additionalProperties") is False:
        for key in node:
            if key not in props:
                errors.append(f"{path}.{key}: additional property is not allowed")
    for key, sub in props.items():
        if key not in node:
            continue
        val = node[key]
        want = sub.get("type")
        types = {"string": str, "boolean": bool, "object": dict,
                 "array": list, "number": (int, float), "integer": int}
        if want in types and not isinstance(val, types[want]):
            errors.append(f"{path}.{key}: expected {want}, got {type(val).__name__}")
        fmt = sub.get("format")
        if fmt == "date-time" and isinstance(val, str):
            try:
                datetime.datetime.fromisoformat(val.replace("Z", "+00:00"))
            except ValueError:
                errors.append(f"{path}.{key}: {val!r} is not a valid date-time")
        elif fmt == "uri" and isinstance(val, str):
            parsed = urllib.parse.urlparse(val)
            if not parsed.scheme or not parsed.netloc:
                errors.append(f"{path}.{key}: {val!r} is not a valid absolute URI")
        elif fmt is not None and fmt not in ("date-time", "uri"):
            errors.append(f"{path}.{key}: unhandled format {fmt!r} "
                          f"— extend this validator before trusting the result")
        if "enum" in sub and val not in sub["enum"]:
            errors.append(f"{path}.{key}: {val!r} is not one of {sub['enum']!r}")
        if "pattern" in sub and isinstance(val, str):
            if not re.search(sub["pattern"], val):
                errors.append(f"{path}.{key}: {val!r} does not match {sub['pattern']!r}")
        walk(val, sub, f"{path}.{key}")

if schema.get("type") != "object":
    errors.append("<root>: expected an object schema")
walk(event, schema, "")

for e in errors:
    print(e)
sys.exit(1 if errors else 0)
PY
)"; then
  pass=$((pass + 1))
  echo "  ✅ dora_event is a valid uFawkesDORA deployment event"
else
  failures+=("dora_event schema validation")
  echo "  ❌ dora_event invalid:"
  echo "$out"
fi
check "dora_event carries cycle-time inputs and AI flag" \
  '.first_commit_at == "2026-09-27T08:15:00Z" and .pr_merged_at == "2026-09-27T12:30:00Z" and .ai_assisted == true' \
  "$(cat "$work/dora_event.json")"

echo "== OTLP/HTTP export to /v1/logs =="
port=$(((RANDOM % 20000) + 30000))
"$PYTHON" - "$port" "$work/otlp.json" << 'PY' &
import http.server, json, sys
port, out = int(sys.argv[1]), sys.argv[2]
class H(http.server.BaseHTTPRequestHandler):
    def do_POST(self):
        body = self.rfile.read(int(self.headers["Content-Length"]))
        with open(out, "w") as f:
            f.write(json.dumps({"path": self.path, "auth": self.headers.get("X-Test", ""),
                                "authorization": self.headers.get("Authorization", ""),
                                "payload": json.loads(body)}))
        self.send_response(200); self.end_headers(); self.wfile.write(b"{}")
    def log_message(self, *a): pass
http.server.HTTPServer(("127.0.0.1", port), H).handle_request()
PY
listener_pid=$!
sleep 1
# Values are percent-encoded per the OTel spec; the collector must see them decoded.
OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:${port}" \
  OTEL_EXPORTER_OTLP_HEADERS="X-Test=abc, Authorization=Basic%20dXNlcjpwYXNz%3D" \
  "$EMIT" deploy-marker --step pipeline --at 2026-09-27T12:48:00Z > /dev/null
wait "$listener_pid" || true
check "POSTed to /v1/logs with custom header" '.path == "/v1/logs" and .auth == "abc"' "$(cat "$work/otlp.json" 2> /dev/null || echo '{}')"
check "percent-encoded header value is decoded (Basic%20…%3D → 'Basic …=')" \
  '.authorization == "Basic dXNlcjpwYXNz="' "$(cat "$work/otlp.json" 2> /dev/null || echo '{}')"
check "OTLP resource service.name + body is the event line" \
  '.payload.resourceLogs[0].resource.attributes[0] == {key: "service.name", value: {stringValue: "widget"}}
   and (.payload.resourceLogs[0].scopeLogs[0].logRecords[0].body.stringValue | fromjson | .event) == "deploy-marker"
   and .payload.resourceLogs[0].scopeLogs[0].logRecords[0].timeUnixNano == "1790513280000000000"' \
  "$(cat "$work/otlp.json" 2> /dev/null || echo '{}')"

if err="$(OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:9" "$EMIT" job-start --step x 2>&1 > /dev/null)" \
  && grep -q "OTLP export .* failed" <<< "$err"; then
  pass=$((pass + 1))
  echo "  ✅ unreachable endpoint: warns on stderr, exits 0"
else
  failures+=("unreachable endpoint handling")
  echo "  ❌ unreachable endpoint: ${err}"
fi

echo
if [ "${#failures[@]}" -gt 0 ]; then
  echo "FAILED ${#failures[@]} check(s), passed ${pass}:"
  printf '  - %s\n' "${failures[@]}"
  exit 1
fi
echo "ALL ${pass} CHECKS PASSED"
