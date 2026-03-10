# API Surface

> **Purpose (AGENTS.md §3 Priority 3):** Authoritative reference for every public HTTP
> endpoint in the Fawkes platform. Agents **must** consult this document before creating
> a new endpoint to avoid duplicates.

All services run inside the `fawkes` Kubernetes namespace. In-cluster callers use the
`<service>.<namespace>.svc` DNS form shown in each section. All services expose FastAPI
auto-generated OpenAPI docs at `/docs` (Swagger UI) and `/redoc` unless otherwise noted.

## Table of Contents

- [VSM — Value Stream Mapping](#vsm--value-stream-mapping)
- [RAG — Retrieval Augmented Generation](#rag--retrieval-augmented-generation)
- [SPACE Metrics](#space-metrics)
- [AI Code Review](#ai-code-review)
- [Smart Alerting](#smart-alerting)
- [MCP K8s Server](#mcp-k8s-server)

---

## VSM — Value Stream Mapping

**Source:** `services/vsm/`
**Base URL (in-cluster):** `http://vsm-service.fawkes.svc`
**Container port:** 8000 | **Service port:** 80
**Backend:** PostgreSQL

Tracks work items through an 8-stage value stream (Backlog → Production) and
calculates flow metrics (WIP, cycle time, throughput, lead time).

### Health / Infrastructure

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/health` | Liveness — returns `status`, `service`, `version`, `database_connected` |
| `GET` | `/ready` | Readiness — returns `{"status":"READY"}` or HTTP 503 |
| `GET` | `/metrics` | Prometheus metrics (text/plain) |

### Business Endpoints

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `POST` | `/api/v1/work-items` | `WorkItemCreate` — `title`, `description`, `type`, `assignee` | `WorkItemResponse` (201) |
| `PUT` | `/api/v1/work-items/{id}/transition` | `StageTransitionCreate` — `to_stage`, `notes` | `StageTransitionResponse` |
| `GET` | `/api/v1/work-items/{id}/history` | path: `work_item_id` | `WorkItemHistory` — ordered list of stage transitions |
| `GET` | `/api/v1/metrics` | query: `days` (1–90, default 7) | `FlowMetricsResponse` — WIP, throughput, cycle time, lead time |
| `GET` | `/api/v1/stages` | — | `List[StageResponse]` — all defined stages |

**Focalboard integration (optional — enabled when `FOCALBOARD_URL` is set):**

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/v1/focalboard/webhook` | Receive Focalboard card-change events |
| `POST` | `/api/v1/focalboard/sync` | Trigger manual sync with Focalboard board |
| `GET` | `/api/v1/focalboard/stages/mapping` | Return VSM stage → Focalboard column mapping |

### Prometheus Metrics

| Metric | Type | Labels |
|--------|------|--------|
| `vsm_requests_total` | Counter | `method`, `endpoint`, `status` |
| `vsm_work_items_created_total` | Counter | `type` |
| `vsm_stage_transitions_total` | Counter | `from_stage`, `to_stage` |
| `vsm_cycle_time_hours` | Histogram | — |
| `vsm_work_in_progress` | Gauge | `stage` |
| `vsm_stage_cycle_time_seconds` | Histogram | `stage` |
| `vsm_throughput_per_day` | Counter | `date` |
| `vsm_lead_time_seconds` | Histogram | — |

---

## RAG — Retrieval Augmented Generation

**Source:** `services/rag/`
**Base URL (in-cluster):** `http://rag-service.fawkes.svc`
**Container port:** 8000 | **Service port:** 80
**Backend:** Weaviate vector database (`http://weaviate.fawkes.svc:80`)

Provides semantic context retrieval for AI assistants and code-generation tools by
indexing repository documents into a Weaviate vector store.

### Health / Infrastructure

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/api/v1/health` | Liveness — returns `status`, `service`, `version`, `weaviate_connected`, `weaviate_url` |
| `GET` | `/ready` | Readiness — returns `{"status":"READY"}` or HTTP 503 |
| `GET` | `/metrics` | Prometheus metrics (text/plain) |

### Business Endpoints

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `POST` | `/api/v1/query` | `QueryRequest` — `query` (str), `top_k` (1–20, default 5), `threshold` (0–1, default 0.7) | `QueryResponse` — `query`, `results[]`, `count`, `retrieval_time_ms` |
| `GET` | `/api/v1/stats` | — | `StatsResponse` — `total_documents`, `total_chunks`, `categories{}`, `last_indexed`, `index_freshness_hours`, `storage_usage_mb` |
| `GET` | `/dashboard` | — | HTML dashboard — indexing statistics and management UI |

**Query result shape (`ContextResult`):** `content`, `relevance_score`, `source`, `title`, `category`

### Prometheus Metrics

| Metric | Type | Labels |
|--------|------|--------|
| `rag_requests_total` | Counter | `method`, `endpoint`, `status` |
| `rag_query_duration_seconds` | Histogram | — |
| `rag_relevance_score` | Histogram | — |

---

## SPACE Metrics

**Source:** `services/space-metrics/`
**Base URL (in-cluster):** `http://space-metrics.fawkes.svc:8000`
**Container port:** 8000 | **Service port:** 8000
**Backend:** PostgreSQL

Collects and exposes Developer Experience metrics across the five SPACE dimensions:
Satisfaction, Performance, Activity, Communication, Efficiency.

### Health / Infrastructure

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness — returns `status`, `service`, `timestamp` |
| `GET` | `/metrics` | Prometheus metrics (text/plain) |

### Business Endpoints

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `GET` | `/api/v1/metrics/space` | query: `time_range` (`24h`\|`7d`\|`30d`\|`90d`, default `30d`) | `SpaceMetricsResponse` — all five dimensions + `health_score` |
| `GET` | `/api/v1/metrics/space/satisfaction` | query: `time_range` | `SatisfactionMetrics` |
| `GET` | `/api/v1/metrics/space/performance` | query: `time_range` | `PerformanceMetrics` |
| `GET` | `/api/v1/metrics/space/activity` | query: `time_range` | `ActivityMetrics` |
| `GET` | `/api/v1/metrics/space/communication` | query: `time_range` | `CommunicationMetrics` |
| `GET` | `/api/v1/metrics/space/efficiency` | query: `time_range` | `EfficiencyMetrics` |
| `GET` | `/api/v1/metrics/space/health` | — | `{ health_score, timestamp, status }` (`excellent`/`good`/`needs_improvement`) |
| `POST` | `/api/v1/friction/log` | `FrictionLogRequest` — friction incident details | `{ status, message, id }` |
| `POST` | `/api/v1/surveys/pulse/submit` | `PulseSurveyRequest` — `flow_state_days`, `valuable_work_percentage`, `cognitive_load` | `{ status, message }` |

### Prometheus Metrics

Metrics are computed and exposed via the custom `/metrics` endpoint (not `prometheus_client`
auto-generated). Labels and exact metric names are defined in `services/space-metrics/app/metrics.py`.

---

## AI Code Review

**Source:** `services/ai-code-review/`
**Base URL (in-cluster):** `http://ai-code-review.fawkes.svc:8000`
**Container port:** 8000 | **Service port:** 8000
**Dependencies:** RAG service, GitHub API, LLM API (OpenAI-compatible), SonarQube

Listens for GitHub pull-request webhook events, analyses changed files using an LLM
(context-augmented via the RAG service), and posts review comments directly on the PR.

### Health / Infrastructure

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness — returns `status`, `service`, `version`, `rag_connected`, `github_configured`, `llm_configured` |
| `GET` | `/ready` | Readiness — HTTP 503 if `GITHUB_TOKEN` or `LLM_API_KEY` not set |
| `GET` | `/metrics` | Prometheus metrics (text/plain) |

### Business Endpoints

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `POST` | `/webhook/github` | GitHub webhook payload (`pull_request` event); headers: `X-Hub-Signature-256`, `X-GitHub-Event` | HTTP 202 — review queued asynchronously |
| `GET` | `/stats` | — | Redirects caller to `/metrics` for detailed statistics |

**Review comment shape (`ReviewComment`):** `path`, `line`, `body`, `category`
(`security`/`performance`/`quality`/`best_practices`), `severity`
(`critical`/`high`/`medium`/`low`), `confidence` (0–1).

### Prometheus Metrics

| Metric | Type | Labels |
|--------|------|--------|
| `ai_review_webhooks_total` | Counter | `event_type`, `action` |
| `ai_review_reviews_total` | Counter | `repository`, `status` |
| `ai_review_duration_seconds` | Histogram | — |
| `ai_review_comments_total` | Counter | `repository`, `category`, `severity` |
| `ai_review_false_positive_rate` | Gauge | `repository` |

---

## Smart Alerting

**Source:** `services/smart-alerting/`
**Base URL (in-cluster):** `http://smart-alerting.fawkes.svc:8000`
**Container port:** 8000 | **Service port:** 8000
**Backend:** Redis (state store for alert groups and suppression rules)

Reduces alert noise through correlation, duplicate detection, suppression rules,
and intelligent routing to Mattermost, Slack, or PagerDuty.

### Health / Infrastructure

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Liveness — returns `status`, `service`, `version`, `redis_connected`, `rules_loaded` |
| `GET` | `/ready` | Readiness — HTTP 503 if Redis, suppression engine, or correlator not initialised |
| `GET` | `/metrics` | Prometheus metrics (text/plain) |

### Business Endpoints — Alert Ingestion

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `POST` | `/api/v1/alerts/prometheus` | `PrometheusAlertPayload` — `alerts[]`, `status`, `groupLabels`, `commonLabels` | `{ message, status: "processing" }` — async |
| `POST` | `/api/v1/alerts/grafana` | `List[Alert]` | `{ message, status: "processing" }` — async |
| `POST` | `/api/v1/alerts/datahub` | `List[Alert]` | `{ message, status: "processing" }` — async |
| `POST` | `/api/v1/alerts/generic` | `List[Alert]` | `{ message, status: "processing" }` — async |

### Business Endpoints — Alert Management

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `GET` | `/api/v1/alert-groups` | query: `limit` (default 50) | `List[AlertGroup]` |
| `GET` | `/api/v1/alert-groups/{group_id}` | — | `AlertGroup` |
| `GET` | `/api/v1/alerts/{alert_id}` | — | `Alert` |
| `PUT` | `/api/v1/alerts/{alert_id}/acknowledge` | — | `{ message, alert_id }` |
| `PUT` | `/api/v1/alerts/{alert_id}/resolve` | — | `{ message, alert_id }` |

### Business Endpoints — Suppression Rules

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `GET` | `/api/v1/rules` | — | `List[SuppressionRule]` |
| `POST` | `/api/v1/rules` | `SuppressionRule` — `name`, `type`, `enabled`, `alert_pattern`, ... | `SuppressionRule` (echo) |
| `GET` | `/api/v1/rules/{rule_id}` | — | `SuppressionRule` |
| `PUT` | `/api/v1/rules/{rule_id}` | `SuppressionRule` | `SuppressionRule` (echo) |
| `DELETE` | `/api/v1/rules/{rule_id}` | — | `{ message, rule_id }` |

### Business Endpoints — Statistics

| Method | Path | Response |
|--------|------|----------|
| `GET` | `/api/v1/stats` | `{ total_received, total_suppressed, total_grouped, total_routed, fatigue_reduction_percent }` |
| `GET` | `/api/v1/stats/reduction` | `{ fatigue_reduction_percent, target: 50.0, target_met }` |

**Rule types:** `maintenance_window`, `known_issue`, `flapping`, `cascade`, `time_based`

### Prometheus Metrics

| Metric | Type | Labels |
|--------|------|--------|
| `smart_alerting_received_total` | Counter | `source` |
| `smart_alerting_suppressed_total` | Counter | `reason` |
| `smart_alerting_grouped_total` | Counter | — |
| `smart_alerting_routed_total` | Counter | `channel` |
| `smart_alerting_fatigue_reduction` | Gauge | — |
| `smart_alerting_false_alert_rate` | Gauge | — |
| `smart_alerting_processing_duration_seconds` | Histogram | — |

---

## MCP K8s Server

**Source:** `services/mcp-k8s-server/`
**Base URL (in-cluster):** `http://mcp-k8s-server.fawkes.svc:8080`
**Container port:** 8080 | **Service port:** 8080

Lightweight in-cluster pod-inspection service. Uses the Kubernetes API (in-cluster
config) to list pods by namespace. No database or external dependencies.

> **Note:** This service does not expose a `/metrics` Prometheus endpoint.

### Health / Infrastructure

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/healthz` | Liveness — returns `{"status":"ok"}` |

### Business Endpoints

| Method | Path | Request | Response |
|--------|------|---------|----------|
| `GET` | `/pods` | query: `namespace` (default `fawkes`) | `[{ name, namespace, phase }]` — list of pod summaries |

---

## Cross-Service Dependencies

```
ai-code-review  →  rag-service  (POST /api/v1/query)
ai-code-review  →  GitHub API   (PR comments)
ai-code-review  →  LLM API      (code analysis)
ai-code-review  →  SonarQube    (static analysis results)
rag-service     →  Weaviate     (vector search)
smart-alerting  →  Backstage    (team ownership lookup)
smart-alerting  →  Mattermost / Slack / PagerDuty  (routing)
vsm-service     →  Focalboard   (optional board sync)
```
