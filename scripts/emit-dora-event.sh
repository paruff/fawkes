#!/usr/bin/env bash
# scripts/emit-dora-event.sh — emits one structured JSON delivery event per
# call for uFawkesObs (Loki) and uFawkesDORA, mirroring uFawkesPipe's
# scripts/dora-log.sh line format (docs/UFAWKES_INTEGRATION.md).
#
# Events:
#   job-start      a pipeline/job began (records its start time for job-finish)
#   job-finish     it ended: status, duration_ms, and delivery metadata
#   deploy-marker  a change was delivered: delivery metadata plus `dora_event`,
#                  a uFawkesDORA deployment event (deployment-event.schema.json 1.0)
#
# Every event is one JSON line with dora-log.sh's fields (@timestamp, level,
# logger, message, pipeline, repo, step) plus: event, service, commit_sha,
# pipeline_url. Delivery metadata = `agent_tokens` (summed `Agent-Tokens:`
# commit trailers across the PR, see scripts/agent-usage.sh) and `pr`
# (number, first_commit_at, opened_at, merged_at, cycle_time_seconds, size).
#
# Output: always stdout (Alloy/Loki picks it up from job logs); appended to
# $DORA_EVENTS_FILE when set; POSTed as an OTLP log record to
# ${OTEL_EXPORTER_OTLP_ENDPOINT}/v1/logs when set (uFawkesObs routes OTLP
# logs to Loki). A failed POST is reported on stderr and never fails the
# pipeline — the stdout/file copies still exist.
#
# Usage:
#   scripts/emit-dora-event.sh <job-start|job-finish|deploy-marker> \
#     [--step NAME] [--status success|failure] [--at ISO-8601-UTC] \
#     [--started-at ISO-8601-UTC] [--environment NAME] [--pr NUMBER]
#
# CI context comes from GitHub Actions (GITHUB_*) or Woodpecker (CI_*)
# variables; PR data from the GitHub API via `gh` (GH_TOKEN). Missing
# context yields null fields, never an error.

set -euo pipefail
cd "$(dirname "$0")/.."

EVENT="${1:-}"
case "$EVENT" in
  job-start | job-finish | deploy-marker) shift ;;
  *)
    echo "usage: $0 <job-start|job-finish|deploy-marker> [options]" >&2
    exit 2
    ;;
esac

step="${CI_STEP_NAME:-${GITHUB_JOB:-unknown}}"
status="success"
at=""
started_at=""
environment="${DORA_ENVIRONMENT:-production}"
pr_number=""
while [ $# -gt 0 ]; do
  case "$1" in
    --step)
      step="$2"
      shift 2
      ;;
    --status)
      status="$2"
      shift 2
      ;;
    --at)
      at="$2"
      shift 2
      ;;
    --started-at)
      started_at="$2"
      shift 2
      ;;
    --environment)
      environment="$2"
      shift 2
      ;;
    --pr)
      pr_number="$2"
      shift 2
      ;;
    *)
      echo "unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

warn() { echo "emit-dora-event: $*" >&2; }
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
to_epoch() { date -u -d "$1" +%s 2> /dev/null || date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s; }

at="${at:-$(now_iso)}"
repo="${GITHUB_REPOSITORY:-${CI_REPO:-unknown}}"
pipeline="${GITHUB_RUN_NUMBER:-${CI_PIPELINE_NUMBER:-unknown}}"
service="${OTEL_SERVICE_NAME:-${repo##*/}}"
commit_sha="${GITHUB_SHA:-${CI_COMMIT_SHA:-$(git rev-parse HEAD 2> /dev/null || echo "")}}"
if [ -n "${GITHUB_RUN_ID:-}" ]; then
  pipeline_url="${GITHUB_SERVER_URL:-https://github.com}/${repo}/actions/runs/${GITHUB_RUN_ID}"
else
  pipeline_url="${CI_PIPELINE_URL:-}"
fi
state_file="${RUNNER_TEMP:-${TMPDIR:-/tmp}}/dora-${step//[^A-Za-z0-9_.-]/_}.start"

# ── PR + agent-token metadata ─────────────────────────────────────────────
delivery_json() {
  local number="$pr_number" pr commits tokens first_commit merged end cycle
  if [ -z "$number" ] && [ -n "${GITHUB_EVENT_PATH:-}" ] && [ -f "$GITHUB_EVENT_PATH" ]; then
    number="$(jq -r '.pull_request.number // empty' "$GITHUB_EVENT_PATH")"
  fi
  if [ -z "$number" ] && command -v gh > /dev/null && [ -n "$commit_sha" ] && [ "$repo" != unknown ]; then
    # push to main: the PR this commit came from
    number="$(gh api "repos/${repo}/commits/${commit_sha}/pulls" --jq '[.[] | select(.merged_at != null)][0].number // empty' 2> /dev/null)" \
      || warn "could not look up the PR for ${commit_sha}"
  fi
  if [ -z "$number" ] || ! command -v gh > /dev/null; then
    [ -z "$number" ] || warn "gh not available; PR metadata omitted"
    jq -n '{agent_tokens: null, pr: null}'
    return
  fi
  if ! pr="$(gh api "repos/${repo}/pulls/${number}" 2> /dev/null)" \
    || ! commits="$(gh api --paginate "repos/${repo}/pulls/${number}/commits" 2> /dev/null | jq -s 'add')"; then
    warn "GitHub API lookup for PR #${number} failed; PR metadata omitted"
    jq -n '{agent_tokens: null, pr: null}'
    return
  fi

  # Sum `Agent-Tokens: input=N output=N cache_read=N cache_write=N model=M` trailers.
  tokens="$(jq '
    [ .[] | .commit.message | split("\n")[] | select(test("^Agent-Tokens:"))
      | [ scan("([a-z_]+)=([^ ]+)") | {(.[0]): .[1]} ] | add ] as $t
    | [ .[] | .commit.message | [ split("\n")[]
        | test("^Co-Authored-By: .*(noreply@anthropic\\.com|copilot|cursor|opencode)"; "i") ] | any ] as $ai
    | {
        input:       ($t | map(.input // "0" | tonumber) | add // 0),
        output:      ($t | map(.output // "0" | tonumber) | add // 0),
        cache_read:  ($t | map(.cache_read // "0" | tonumber) | add // 0),
        cache_write: ($t | map(.cache_write // "0" | tonumber) | add // 0),
        models:      ($t | map(.model // empty) | map(split("+")[]) | unique),
        commits_reporting: ($t | length),
        commits_total: length,
        ai_coauthored_commits: ($ai | map(select(.)) | length)
      }' <<< "$commits")"

  first_commit="$(jq -r '[.[].commit.author.date] | sort | first // empty' <<< "$commits")"
  merged="$(jq -r '.merged_at // empty' <<< "$pr")"
  end="${merged:-$at}"
  cycle=null
  [ -n "$first_commit" ] && cycle=$(($(to_epoch "$end") - $(to_epoch "$first_commit")))

  jq -n --argjson tokens "$tokens" --argjson pr "$pr" --arg first "$first_commit" \
    --argjson cycle "$cycle" --arg measured_to "$end" '{
      agent_tokens: $tokens,
      pr: {
        number: $pr.number,
        first_commit_at: (if $first == "" then null else $first end),
        opened_at: $pr.created_at,
        merged_at: $pr.merged_at,
        cycle_time_seconds: $cycle,
        cycle_time_measured_to: $measured_to,
        lines_added: $pr.additions,
        lines_deleted: $pr.deletions,
        commits: $pr.commits
      }
    }'
}

# ── Build the event ───────────────────────────────────────────────────────
base="$(jq -n --arg ts "$at" --arg event "$EVENT" --arg step "$step" --arg pipeline "$pipeline" \
  --arg repo "$repo" --arg service "$service" --arg sha "$commit_sha" --arg url "$pipeline_url" '{
    "@timestamp": $ts, level: "info", logger: "dora", pipeline: $pipeline, repo: $repo,
    step: $step, event: $event, service: $service,
    commit_sha: (if $sha == "" then null else $sha end),
    pipeline_url: (if $url == "" then null else $url end)
  }')"

case "$EVENT" in
  job-start)
    echo "$at" > "$state_file"
    line="$(jq -c --arg m "Starting ${step}" '. + {message: $m}' <<< "$base")"
    ;;
  job-finish)
    started_at="${started_at:-$(cat "$state_file" 2> /dev/null || true)}"
    duration=null
    [ -n "$started_at" ] && duration=$((($(to_epoch "$at") - $(to_epoch "$started_at")) * 1000))
    level=info
    [ "$status" = success ] || level=error
    line="$(jq -c --arg m "Completed ${step}" --arg status "$status" --arg level "$level" \
      --argjson duration "$duration" --argjson delivery "$(delivery_json)" \
      '. + {message: $m, level: $level, status: $status, duration_ms: $duration} + $delivery' <<< "$base")"
    ;;
  deploy-marker)
    delivery="$(delivery_json)"
    deploy_status="$status"
    [ "$status" = failure ] && deploy_status=failed
    line="$(jq -c --arg m "Delivered ${commit_sha:0:12} to ${environment}" --arg env "$environment" \
      --arg status "$deploy_status" --argjson delivery "$delivery" '
      . + {message: $m, status: $status, environment: $env} + $delivery
      | .dora_event = ({
          schema_version: "1.0", event_type: "deployment", repo: .repo, service: .service,
          environment: $env, commit_sha: .commit_sha, deployed_at: .["@timestamp"],
          status: $status, pipeline_url: .pipeline_url,
          ai_assisted: (((.agent_tokens.output // 0) > 0) or ((.agent_tokens.ai_coauthored_commits // 0) > 0)),
          first_commit_at: .pr.first_commit_at, pr_merged_at: .pr.merged_at
        } | with_entries(select(.value != null)))' <<< "$base")"
    ;;
esac

# ── Emit ──────────────────────────────────────────────────────────────────
echo "$line"
[ -n "${DORA_EVENTS_FILE:-}" ] && echo "$line" >> "$DORA_EVENTS_FILE"

if [ -n "${OTEL_EXPORTER_OTLP_ENDPOINT:-}" ]; then
  otlp="$(jq -c --arg svc "$service" --arg event "$EVENT" --arg ns "$(($(to_epoch "$at") * 1000000000))" \
    --arg body "$line" '{resourceLogs: [{
      resource: {attributes: [{key: "service.name", value: {stringValue: $svc}}]},
      scopeLogs: [{scope: {name: "ufawkes.dora"}, logRecords: [{
        timeUnixNano: $ns, severityText: ($body | fromjson | .level | ascii_upcase),
        body: {stringValue: $body},
        attributes: [{key: "event", value: {stringValue: $event}}]
      }]}]
    }]}' <<< "{}")"
  headers=(-H "Content-Type: application/json")
  # OTEL_EXPORTER_OTLP_HEADERS is comma-separated key=value pairs whose keys
  # and values are percent-encoded (OTel spec), e.g. Authorization=Basic%20xyz.
  urldecode() {
    local v="${1//\\/\\\\}"
    printf '%b' "${v//%/\\x}"
  }
  trim() {
    local v="${1#"${1%%[![:space:]]*}"}"
    printf '%s' "${v%"${v##*[![:space:]]}"}"
  }
  IFS=',' read -ra extra <<< "${OTEL_EXPORTER_OTLP_HEADERS:-}"
  for h in "${extra[@]}"; do
    [[ "$h" == *=* ]] || continue
    headers+=(-H "$(urldecode "$(trim "${h%%=*}")"): $(urldecode "$(trim "${h#*=}")")")
  done
  if ! curl -fsS --max-time 10 "${headers[@]}" -d "$otlp" "${OTEL_EXPORTER_OTLP_ENDPOINT%/}/v1/logs" > /dev/null; then
    warn "OTLP export to ${OTEL_EXPORTER_OTLP_ENDPOINT%/}/v1/logs failed; event kept on stdout${DORA_EVENTS_FILE:+ and in $DORA_EVENTS_FILE}"
  fi
fi
