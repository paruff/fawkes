# Deferred apps

Apps moved out of `platform/apps/` so `platform-applications.yaml`'s directory
scan (`recurse: true`, `include: "*-application.yaml"`) doesn't pick them up
and deploy them locally. None of these are named in #1804 Phase 1's
acceptance criteria; keeping them out of the local bootstrap frees real
resources on a constrained dev cluster for the apps that are (Tekton,
Prometheus-stack, DevLake, Loki/Tempo/otel-collector, SonarQube, and
the cross-cutting infra those depend on: ingress-nginx, cert-manager,
sealed-secrets/external-secrets, vault, kyverno, postgresql).

`opensearch/` is here for a different reason: it's not out of Phase 1
scope, it's superseded. Loki (`platform/apps/loki/`) replaced it as the
platform's log store (see docs/adr/ADR-035), so it's deferred rather than
deleted outright, in case of rollback. Its ISM retention policy and index
templates configured a 30-day hot/warm/delete lifecycle that Loki's
`retention_period: 720h` now covers directly.

To bring one back into scope for a later phase: `git mv` it back into
`platform/apps/` (preserving its internal structure) and it'll be picked up
on the next sync - no other config change needed.

Contents: ai-code-review, analytics-dashboard, anomaly-detection,
design-system, devex-survey-automation, discovery-metrics,
eclipse-che, experimentation, feedback-service, focalboard, friction-bot,
harbor, hasura, openreplay, opensearch, penpot, plausible, samples
(sample-java-app, sample-nodejs-app, sample-python-app), smart-alerting,
unleash, vsm-service.
