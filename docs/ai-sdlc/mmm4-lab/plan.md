# Plan: mmm4 lab, wave 1

**Traces to:** fawkes#1804 (Alpha). The lab is a rehearsal; Alpha is verified live on AKS.

## Decisions (maintainer, 2026-11-27)

- Wave 1 only: Argo CD, ingress-nginx, cert-manager, Argo Rollouts, Tekton,
  Prometheus and Grafana, `python-fawkes-path` and its analysis template.
- A lab ApplicationSet under `platform/lab/`.
- A `lab` branch in `python-fawkes-path-gitops`.

## Not in wave 1

Loki, Tempo, the OpenTelemetry collector, dashboards (wave 2). PostgreSQL and
Backstage (placeholder secrets, #1797; no External Secrets). `space-metrics` and
`dora-metrics` (private images). Chaos Mesh. Azure storage classes.

## Verification Strategy

| Criterion | How |
|---|---|
| The lab installs wave 1 and nothing else, from the real templates | `pytest tests/unit/test_lab_cluster.py` |
| A lab promotion cannot change `main` or count as production | same test; pipeline run with `gitops-branch=lab` |
| Argo CD syncs every wave 1 Application on mmm4 | `kubectl --context mmm4 get applications -n argocd` |
| The sample app runs on ARM | its Rollout is Healthy and `/health` answers |
