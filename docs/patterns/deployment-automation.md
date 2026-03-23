# Deployment Automation Pattern

Deployment automation is the practice of eliminating manual steps from the process
of moving code from a developer's commit to running in production. DORA research
shows that teams with fully automated deployments deploy 3× more frequently than
those requiring manual approval or intervention at deployment time.

## The Deployment Pipeline

A fully automated deployment pipeline in Fawkes looks like:

```
git push → GitHub → Jenkins CI
                        │
               Tests + Security scans pass
                        │
               Docker image built and pushed
                        │
               Git manifest updated (GitOps)
                        │
               ArgoCD detects change
                        │
               Rolling deployment to Kubernetes
                        │
               Smoke tests run
                        │
               Grafana monitors for anomalies
```

No human needs to press a button. The pipeline runs automatically on every commit
to `main` that passes CI.

## GitOps Deployment Model

Fawkes uses a **GitOps** model where the desired state of the cluster is always in
Git. ArgoCD continuously reconciles the live cluster with what Git declares. A
deployment is a git commit — not a `kubectl apply` command.

This means:
- **Auditable** — Every deployment is a git commit with an author and timestamp
- **Reproducible** — Any past state can be restored by checking out the commit
- **Rollback is instant** — `git revert` + `argocd app sync` restores the previous version

## Deployment Strategies

### Rolling Update (default)

Kubernetes replaces pods one at a time, ensuring minimum disruption. Use for
stateless services where any version can serve traffic.

### Blue/Green

Two identical environments run in parallel. Traffic switches atomically from blue
(current) to green (new). Instant rollback by switching traffic back.

### Canary

Route a small percentage (5–10%) of traffic to the new version. Monitor error rates
and latency. Promote progressively or rollback automatically.

Fawkes implements canary deployments using Argo Rollouts with Prometheus-based
automated promotion gates.

## DORA Deployment Frequency Metric

Deployment frequency is measured by DevLake from your ArgoCD deployment events. Each
successful sync of a production application counts as one deployment. Elite teams
deploy multiple times per day.

## See Also

- [Onboard Service to ArgoCD](../how-to/gitops/onboard-service-argocd.md)
- [GitOps Strategy](../explanation/architecture/gitops-strategy.md)
- [Continuous Integration Pattern](continuous-integration.md)
