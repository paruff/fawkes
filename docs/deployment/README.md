# Deployment Guides

This directory contains deployment guides for Fawkes platform components.

## Available Guides

- [Backstage with PostgreSQL Backend](./backstage-postgresql.md) - Deploy Backstage developer portal with HA PostgreSQL database

## Quick Start

All platform components are deployed using GitOps with ArgoCD. The general pattern is:

1. **Update secrets** - Replace placeholder values in `platform/apps/*/secrets.yaml`
2. **Apply bootstrap** - `kubectl apply -f platform/bootstrap/app-of-apps.yaml`
3. **Monitor deployment** - `argocd app list` and `kubectl get pods -n fawkes`
4. **Verify** - Run BDD tests with `behave tests/bdd/features/`

## Prerequisites

- Kubernetes cluster (1.28+)
- ArgoCD installed
- kubectl configured
- (Optional) argocd CLI for easier management

## Deployment Order

ArgoCD sync waves ensure proper ordering:

| Wave | Components | Purpose |
|------|------------|---------|
| -10  | Networking | Ingress controller, cert-manager |
| -5   | Operators | CloudNativePG, External Secrets |
| -4   | Databases | PostgreSQL clusters |
| 0    | Core Apps | Jenkins, SonarQube, Harbor |
| 5    | Portal | Backstage, Grafana |
| 10   | Additional | Mattermost, Focalboard, Eclipse Che |

## Security Note

**Never commit real secrets to Git!**

For production deployments:
- Use External Secrets Operator with Vault
- Use sealed secrets or SOPS
- Use cloud-native secret management (AWS Secrets Manager, Azure Key Vault, GCP Secret Manager)

See [docs/how-to/manage-secrets.md](../how-to/manage-secrets.md) for details.

## Support

For issues or questions:
- GitHub Issues: https://github.com/paruff/fawkes/issues
- Documentation: https://github.com/paruff/fawkes/tree/main/docs
