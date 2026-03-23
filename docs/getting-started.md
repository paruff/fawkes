# Getting Started with Fawkes

Welcome to the Fawkes Internal Developer Platform. Choose the path below that matches your goal — each path is designed to get you to a working outcome in the stated time without requiring you to read irrelevant sections.

---

## Which path is right for you?

| | **Path A — Evaluate Locally** | **Path B — Deploy to Cloud** | **Path C — Enterprise Multi-Cloud** |
|---|---|---|---|
| **Goal** | Explore the platform without cloud costs | Run a real platform on AWS EKS | Multi-cloud or enterprise-scale deployment |
| **Time** | ~20 minutes | 2–4 hours | 1–2 days |
| **Cloud account** | Not required | AWS account required | AWS + Azure or GCP |
| **Kubernetes** | k3d (local, auto-provisioned) | Amazon EKS (provisioned by Terraform) | Managed K8s per cloud |
| **Components** | 5 core components | Full core platform | Full platform + enterprise extensions |
| **Best for** | Evaluation, learning, demos | Teams adopting Fawkes | Platform teams operating at scale |

Jump to: [Path A](#path-a-evaluate-locally) · [Path B](#path-b-deploy-to-cloud-aws-eks) · [Path C](#path-c-enterprise-multi-cloud)

---

## Path A — Evaluate Locally

> **You should choose this if:** you want to explore Fawkes features, run the Dojo learning labs, or demo the platform to stakeholders — without spending on cloud infrastructure.

**Estimated time:** ~20 minutes from clone to running platform.

### Prerequisites

| Tool | Minimum version | Install guide |
|---|---|---|
| Docker | 24+ | <https://docs.docker.com/get-docker/> |
| k3d | 5+ | <https://k3d.io/#installation> |
| kubectl | 1.28+ | <https://kubernetes.io/docs/tasks/tools/> |
| Helm | 3.12+ | <https://helm.sh/docs/intro/install/> |
| make | any | Pre-installed on macOS/Linux |
| Git | any | Pre-installed on most systems |

**Resource requirements:** 4 CPU cores, 8 GB RAM, 20 GB free disk space.

### Tier 1 components deployed

Path A brings up the **five core components** needed to experience the platform:

| Component | Purpose |
|---|---|
| ArgoCD | GitOps controller — reconciles platform state |
| Backstage | Developer portal and Dojo learning hub |
| Prometheus + Grafana | Metrics collection and DORA dashboards |
| Vault (dev mode) | Secrets management (local, non-persistent) |
| Sample application | Demonstrates CI/CD and DORA metrics |

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/paruff/fawkes.git
cd fawkes

# 2. Bring up the local platform (creates k3d cluster + deploys all components)
make dev-up

# 3. Check service URLs and credentials
make dev-status

# 4. Tear down when done
make dev-down
```

> **Troubleshooting:** If any service does not reach `Running` status within 5 minutes, see [docs/tutorials/local-dev-setup.md](tutorials/local-dev-setup.md) for port-forward commands and diagnostics.

### Access the platform

After `make dev-up` completes, `make dev-status` prints the local URLs. Typical defaults:

| Service | URL | Default credentials |
|---|---|---|
| Backstage | <http://backstage.localhost> | GitHub OAuth (local dev app) |
| ArgoCD | <http://argocd.localhost> | `admin` / printed by `make dev-status` |
| Grafana | <http://grafana.localhost> | `admin` / `admin` |

### Next steps after Path A

- [Dojo White Belt](dojo/white-belt/README.md) — start your learning journey
- [Quick Start Tutorial](tutorials/quick-start.md) — guided walkthrough of all features
- When ready to deploy to the cloud, continue with [Path B](#path-b-deploy-to-cloud-aws-eks)

---

## Path B — Deploy to Cloud (AWS EKS)

> **You should choose this if:** your team has decided to adopt Fawkes and you want a production-capable platform on AWS. This is the standard single-account deployment used by most teams.

**Estimated time:** 2–4 hours for initial deployment; longer for DNS and certificate configuration.

### Prerequisites

| Tool | Minimum version | Install guide |
|---|---|---|
| AWS CLI | 2.x | <https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html> |
| Terraform | 1.6+ | <https://developer.hashicorp.com/terraform/install> |
| kubectl | 1.28+ | <https://kubernetes.io/docs/tasks/tools/> |
| Helm | 3.12+ | <https://helm.sh/docs/intro/install/> |
| Git | any | Pre-installed on most systems |

**AWS account requirements:**

- IAM permissions to create EKS, VPC, IAM roles, S3, and RDS resources
- Service quotas: at least 3 `m5.large` (or equivalent) EC2 instances available
- A registered domain name (for TLS certificates and Backstage OAuth callbacks)

**Resource requirements:** 3-node EKS cluster (`m5.large`), ~$150–300/month at standard AWS pricing. See [AWS Cost Estimation](<AWS cost estimation.md>) for a full breakdown.

### Tier 2 components deployed

In addition to the Tier 1 components, Path B deploys the full platform:

| Component | Purpose |
|---|---|
| Amazon EKS | Managed Kubernetes control plane |
| Amazon RDS (PostgreSQL) | Persistent storage for Backstage, SonarQube |
| Jenkins | CI/CD pipelines with golden path templates |
| SonarQube | Static application security testing (SAST) |
| OpenSearch | Log aggregation and search |
| DevLake | DORA metrics aggregation |
| External Secrets Operator | Syncs secrets from Vault/AWS Secrets Manager |
| Cert-manager + Let's Encrypt | Automated TLS certificates |
| Mattermost | Team collaboration and ChatOps |

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/paruff/fawkes.git
cd fawkes

# 2. Configure your environment
cp config/example.tfvars config/terraform.tfvars
# Edit terraform.tfvars with your AWS account ID, region, and domain

# 3. Configure GitHub OAuth for Backstage (required before first login)
# See: docs/how-to/security/github-oauth-quickstart.md

# 4. Provision infrastructure and deploy platform via ArgoCD
./scripts/ignite.sh --provider aws dev

# 5. Verify all components are healthy
make validate
```

> **Important:** Configure GitHub OAuth before running `ignite.sh`. The script will prompt if the secret is missing, but Backstage will not be accessible until OAuth is configured. See [GitHub OAuth Quick Start](how-to/security/github-oauth-quickstart.md).

### Verify deployment

```bash
# Check all pods are running
kubectl get pods -A

# Get service URLs
kubectl get ingress -n fawkes-platform

# Run acceptance tests
make test-bdd
```

### Next steps after Path B

- [Deployment Guide](deployment/index.md) — operational runbooks and day-2 operations
- [Golden Path Templates](golden-path-usage.md) — onboard your development teams
- [DORA Metrics Setup](observability/index.md) — configure team-level dashboards
- For multi-cloud or enterprise needs, see [Path C](#path-c-enterprise-multi-cloud)

---

## Path C — Enterprise Multi-Cloud

> **You should choose this if:** you are a platform team managing multiple cloud providers, business units, or need enterprise features such as SSO, RBAC, and dedicated compliance controls.

**Estimated time:** 1–2 days for initial deployment; longer for identity provider integration and compliance review.

### When to choose Path C

- You need to run Fawkes on both AWS and Azure (or GCP)
- You have an existing identity provider (Okta, Azure AD, LDAP) to integrate
- You need audit logs, fine-grained RBAC, or network isolation per business unit
- You are deploying to more than one AWS account (e.g. dev, staging, prod accounts)

### Guides by cloud provider

| Cloud | Guide |
|---|---|
| AWS (multi-account) | [AWS Deployment Guide](AWS_deployment_guide.md) |
| Azure AKS | [Azure Ingress Setup](azure-ingress-setup.md) · [Azure Ingress Quick Start](azure-ingress-quickstart.md) |
| Multi-cloud | [docs/deployment/](deployment/index.md) directory |

### Enterprise features

- **SSO integration** — Backstage and ArgoCD authenticate via your identity provider
- **Multi-tenancy** — isolated namespaces and network policies per team or business unit
- **Compliance controls** — OPA/Rego policies, audit logs, SBOM generation
- **High availability** — multi-zone EKS, RDS multi-AZ, Prometheus federation
- **Cost allocation** — per-namespace resource tagging and cost dashboards

> For enterprise deployment support, open a [GitHub Discussion](https://github.com/paruff/fawkes/discussions) or refer to the [deployment guides](deployment/index.md).

---

## Repository Structure

```
fawkes/
├── docs/                          # Documentation (Diátaxis framework)
│   ├── tutorials/                 # Learning-oriented guides
│   ├── how-to/                    # Task-oriented guides
│   ├── explanation/               # Understanding-oriented discussions
│   ├── reference/                 # API docs, config tables, glossary
│   ├── deployment/                # Cloud deployment guides (Path B and C)
│   └── dojo/                      # Belt-based learning modules
├── platform/                      # Platform components
│   ├── apps/                      # ArgoCD applications (Jenkins, Backstage, etc.)
│   ├── policies/                  # Kyverno policies (security, mutation, generation)
│   ├── devfiles/                  # Eclipse Che development environments
│   ├── networking/                # Ingress, cert-manager, external-dns
│   └── bootstrap/                 # Platform initialization scripts
├── infra/                         # Infrastructure as Code
│   ├── local-dev/                 # Local Kubernetes (kind, k3d)
│   ├── kubernetes/                # Kubernetes manifests
│   └── terraform/                 # Cloud infrastructure (AWS, Azure, GCP)
├── jenkins-shared-library/        # Golden Path pipeline library
├── services/                      # Platform-specific microservices (Python/FastAPI)
├── tests/                         # Test suites
│   ├── bdd/                       # BDD/Gherkin acceptance tests
│   ├── unit/                      # Unit tests
│   └── integration/               # Integration tests
└── mkdocs.yml                     # Documentation site configuration
```

---

## Need Help?

- [Troubleshooting guide](troubleshooting.md)
- [GitHub Issues](https://github.com/paruff/fawkes/issues)
- [Community Discussions](https://github.com/paruff/fawkes/discussions)

[Path A — Evaluate Locally :computer:](#path-a-evaluate-locally){ .md-button .md-button--primary }
[Path B — Cloud Deployment :cloud:](#path-b-deploy-to-cloud-aws-eks){ .md-button }
[Architecture Overview :books:](ARCHITECTURE.md){ .md-button }
