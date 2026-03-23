# Grafana

[Grafana](https://grafana.com/) is an open-source observability and data visualisation
platform. In Fawkes, Grafana serves as the unified dashboard layer for metrics, logs,
traces, and DORA performance indicators.

## How Fawkes Uses Grafana

Grafana is deployed as part of the `kube-prometheus-stack` Helm chart in the `monitoring`
namespace. It is accessible at the cluster ingress URL configured for your environment.

```bash
# Port-forward Grafana locally
kubectl port-forward svc/grafana 3000:80 -n monitoring
# Then open http://localhost:3000
```

## Data Sources

| Source | Type | Purpose |
|--------|------|---------|
| Prometheus | Metrics | Application and infrastructure metrics |
| Loki | Logs | Aggregated structured logs from all pods |
| Tempo | Traces | Distributed traces (OpenTelemetry) |
| DevLake | Metrics | DORA metrics (deployment frequency, lead time, CFR, MTTR) |

## Pre-Built Dashboards

Fawkes ships dashboards for common platform concerns:

- **DORA Metrics** — Deployment frequency, lead time, change failure rate, MTTR
- **Platform Overview** — Cluster resource utilisation, pod health, namespace summary
- **Service SLOs** — Error rate, latency P50/P95/P99 per service
- **ArgoCD** — Sync status, drift detection, rollout history
- **Jenkins** — Pipeline success rate, build duration trends

## Alerting

Alerts are defined as `PrometheusRule` custom resources in `platform/apps/`. When an
alert fires, Alertmanager routes it to the configured notification channel
(Mattermost, PagerDuty, or email).

## Adding a Dashboard

1. Create your dashboard in the Grafana UI.
2. Export as JSON (`Dashboard → Share → Export`).
3. Save the JSON to `platform/apps/grafana/dashboards/`.
4. ArgoCD will deploy it automatically on next sync.

## See Also

- [Unified Telemetry](../explanation/observability/unified-telemetry.md)
- [Monitoring and Observability Pattern](../patterns/monitoring-and-observability.md)
- [View DORA Metrics](../how-to/observability/view-dora-metrics-devlake.md)
