# Choose Your Implementation Path

Fawkes is designed to meet teams where they are. Whether you are standing up a new
platform from scratch, migrating from a legacy setup, or incrementally improving an
existing delivery pipeline, there is an implementation path for you.

## Path A: Greenfield Platform

**Best for**: New projects, teams starting fresh, organisations standing up a new engineering platform.

You will build the full Fawkes stack from day one:

1. **Provision infrastructure** — Run `scripts/ignite.sh` to provision a Kubernetes cluster
   (AKS or EKS) using the Terraform modules in `infra/`.

2. **Bootstrap the platform** — ArgoCD, cert-manager, External Secrets Operator, and
   Kyverno are installed via the bootstrap Helm chart.

3. **Deploy platform components** — Backstage, Jenkins, Prometheus/Grafana, DevLake, and
   Vault are deployed as ArgoCD Applications from `platform/apps/`.

4. **Onboard your first service** — Use the Backstage golden-path template to scaffold
   and deploy your first microservice. Follow [Tutorial 1](../tutorials/1-deploy-first-service.md).

**Typical timeline**: 2–4 weeks to full platform, 1–2 weeks per service onboarded.

## Path B: Brownfield Migration

**Best for**: Existing organisations with legacy CI/CD (e.g., Jenkins on VMs, manual deployments),
wanting to adopt GitOps and improve DORA metrics without a big-bang rewrite.

Work incrementally:

1. **Containerise one service** — Pick a low-risk service and build a Docker image.
   Get it deploying to Kubernetes. Do not containerise everything at once.

2. **Add CI** — Connect the service to the Jenkins shared library or GitHub Actions.
   Add a linting and test stage. Establish a coverage baseline.

3. **Add GitOps** — Deploy the service via ArgoCD from a Helm chart. This replaces
   your existing manual deployment step.

4. **Add observability** — Add a Prometheus `/metrics` endpoint and a Grafana dashboard.
   Set an alert on the error rate.

5. **Repeat** — Onboard the next service using the same pattern.

**Typical timeline**: 1–2 sprints per service; full migration of 10 services in 3–6 months.

## Path C: Incremental Adoption

**Best for**: Teams that already have Kubernetes and CI/CD but want to add DORA measurement,
better observability, security gates, or a developer portal.

Pick the capability area you want to improve:

| Goal | Starting Point |
|------|---------------|
| Measure DORA metrics | [DevLake + Grafana setup](../how-to/observability/view-dora-metrics-devlake.md) |
| Developer portal | [Backstage onboarding](../tutorials/1-deploy-first-service.md) |
| Security gates | [Quality gates configuration](../how-to/security/quality-gates-configuration.md) |
| GitOps | [Onboard service to ArgoCD](../how-to/gitops/onboard-service-argocd.md) |
| Secrets management | [Rotate Vault secrets](../how-to/security/rotate-vault-secrets.md) |

## Next Steps

- [Quick Wins You Can Implement This Sprint](quick-wins.md)
- [Assess Your Current Capabilities](assessment.md)

## See Also

- [Getting Started](../getting-started.md)
- [Tutorials](../tutorials/index.md)
