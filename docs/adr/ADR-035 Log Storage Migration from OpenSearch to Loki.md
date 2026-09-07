# ADR-035: Log Storage Migration from OpenSearch to Loki

## Status

Accepted

Supersedes [ADR-011: Centralized Log Management](ADR-011%20Centralized%20Log%20Management.md).

## Context

ADR-011 chose OpenSearch (with Fluent Bit as the collector, later replaced by
the OpenTelemetry Collector - see `platform/apps/fluent-bit/README.md`) as
Fawkes' centralized log store, explicitly considering and rejecting Loki at
the time. That decision favored OpenSearch's full-text search DSL for
compliance auditing and security investigation use cases.

In practice, Fawkes' actual log volume and query patterns are the ones
ADR-011 itself listed as Loki's strengths: Kubernetes-native operational
logging, correlation against traces and metrics already flowing through
Grafana, and dev/small-team scale rather than billions of log entries or
SIEM-grade full-text search. Running a single-node OpenSearch cluster
(2Gi memory, 50Gi storage per ADR-011's own MVP sizing) to index full log
content, when the platform's own Tempo/Prometheus stack already establishes
Grafana as the single pane of glass, is disproportionate operational and
resource overhead for what's actually being asked of it.

## Decision

Replace OpenSearch with **Grafana Loki** (single-binary MVP deployment,
filesystem storage) as the log store, keeping the OpenTelemetry Collector as
the sole collection path (no Fluent Bit).

### What changed

- `platform/apps/loki/loki-application.yaml` (new): Loki chart
  (`grafana/helm-charts`, `loki` chart v7.3.0), `deploymentMode:
  SingleBinary`, `loki.storage.type: filesystem`, `auth_enabled: false`,
  `retention_period: 720h` (30 days, matching OpenSearch's ISM policy).
- `platform/apps/opentelemetry/otel-collector-application.yaml`: the logs
  pipeline's `opensearch` exporter is replaced with `otlphttp/loki`,
  pointed at Loki's native OTLP logs endpoint
  (`/otlp/v1/logs`). This is the path Grafana's own docs recommend over the
  community `lokiexporter` component: Loki's OTLP endpoint applies its own
  curated, low-cardinality mapping of resource attributes (`service.name`,
  `k8s.namespace.name`, `k8s.pod.name`, `k8s.container.name`, etc.) to
  index labels automatically, with everything else kept as unindexed
  structured metadata - no manual label configuration needed.
- `platform/apps/grafana/helm-release.yml`: the `OpenSearch` datasource is
  replaced with a `Loki` datasource (same `derivedFields` trace-ID
  extraction regexes, since the underlying log body format is unchanged).
  Tempo's `tracesToLogs`/`lokiSearch` `datasourceUid` now points at `loki`
  instead of `opensearch`.
- `platform/apps/opensearch/` moves to `platform/apps-deferred/opensearch/`
  (deferred, not deleted - see `platform/apps-deferred/README.md`) so a
  rollback is a `git mv` back, not a rebuild.

### What's intentionally out of scope for this ADR

- **Historical log data**: OpenSearch's existing indices are not migrated
  or backfilled into Loki. Logs are operational/short-retention data here
  (30-day policy on both sides); the cutover accepts a retention-window
  gap rather than building one-time backfill tooling for data that ages
  out in 30 days regardless.
- **Multi-tenancy / Loki auth**: `auth_enabled: false` matches OpenSearch's
  own MVP stance (`plugins.security.disabled: true`). Team-level log
  isolation, if needed later, is a separate decision (Loki's multi-tenancy
  model differs enough from OpenSearch's document-level security that it
  needs its own design, not a like-for-like port).

## Consequences

### Positive

1. **Lower resource footprint**: Loki's single binary (250m/512Mi request)
   is lighter than OpenSearch's single-node MVP (500m/2Gi), because Loki
   indexes only labels, not full log content.
2. **Unified query surface**: LogQL alongside PromQL and TraceQL in the
   same Grafana Explore view Fawkes already uses for metrics and traces -
   no separate OpenSearch Dashboards UI to learn or maintain.
3. **Simpler pipeline**: the OTLP-native exporter path removes the
   OpenSearch-specific index template / ISM policy ConfigMaps ADR-011
   required; Loki's schema and retention are chart values, not a
   post-deploy configuration job.
4. **No dual-formatter-style drift risk**: one log backend, one exporter,
   one datasource - removes a class of "which one is authoritative"
   confusion the platform has hit before with duplicate tooling.

### Negative

1. **Weaker full-text search**: Loki has no inverted index over log
   content; `|= "text"` line filters are a linear scan within a label
   selector's matched streams, not the fielded, scored full-text search
   OpenSearch DSL provided. Acceptable at current log volume; would need
   revisiting if Fawkes later needs SIEM-grade search or compliance
   full-text audit queries - exactly the case ADR-011 originally
   optimized for.
2. **Label discipline required**: Loki's performance model depends on
   keeping stream label cardinality low. The OTLP endpoint's default
   resource-attribute mapping handles this out of the box, but any future
   custom labels need the same discipline OpenSearch never required.
3. **Rollback has a retention-window cost**: because historical data isn't
   migrated, a rollback to OpenSearch after this cutover starts with an
   empty log history rather than picking up where OpenSearch left off.

## Alternatives Considered

See ADR-011's own "Alternative 1: Grafana Loki" section for the original
pros/cons analysis - this decision reverses that call for the reasons in
Context above, not because that analysis was wrong for the workload it
assumed.
