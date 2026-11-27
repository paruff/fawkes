# Version inventory (#2366)

Read on 2026-11-27 from `main` at `febe2c7b`. Nothing was upgraded.
The rule is [ADR-040](../../adr/ADR-040-version-currency.md).

Sources: each chart repository's `index.yaml` (highest non-prerelease), GitHub
releases, the Terraform registry, python.org, and endoflife.date for support
status. Dates are publication dates. "n/r" means not read. State is **current**,
**behind** (with its issue) or **exception** (with its reason).

## Helm charts

| Component | Set in | Pinned (date) | Latest stable (date) | Support / EOL | State |
|---|---|---|---|---|---|
| Argo CD chart | `scripts/dev-up.sh`; `infra/terraform/argocd/{variables.tf,README.md}`; `modules/argocd-helm/variables.tf` | 7.7.14 (2025-01-07), 7.7.12, unpinned | 10.20.0 (2026-11-25), app v3.6.3 | app 2.13 EOL 2025-08-13 | behind #2371 |
| Argo Rollouts | `platform/apps/argo-rollouts/` | 2.43.1 (2026-09-09) | 2.43.12 (2026-11-09) | n/r | behind #2388 |
| Backstage | `platform/apps/backstage/`; `scripts/dev-up.sh` | 1.10.0 (2024-10-10), 2.3.0; image `latest` | 2.11.0 (2026-11-17) | n/r | behind #2375 |
| cert-manager | `platform/apps/cert-manager/`; `platform/networking/cert-manager/` | v1.15.3 (2024-08-16), v1.16.2 | v1.21.3 (2026-10-23) | 1.21 supported | behind #2381 |
| Chaos Mesh | `platform/apps/chaos-mesh/` | 2.8.4 (2026-08-18) | 2.8.8 (2026-11-06) | n/r | behind #2388 |
| CloudNativePG | `platform/apps/postgresql/` | 0.22.1 (2024-10-17) | 0.29.2 (2026-11-17) | n/r | behind #2374 |
| DevLake | `platform/apps/devlake/` | 1.0.3-beta15 (2026-07-19), pre-release | v1.0.2 GA (2025-07-02); beta19 (2026-11-02) | n/r | behind #2391 |
| external-dns | `platform/networking/external-dns/` | 1.15.0 (2024-09-11) | 1.24.0 (2026-11-19) | n/r | behind #2391 |
| External Secrets | `platform/apps/external-secrets/` | 0.9.19 (2024-06-04) | 2.15.0 (2026-11-10) | n/r | behind #2373 |
| Grafana chart | `platform/apps/grafana/helm-release.yml` (appears not applied) | `latest` | 10.5.15 (2026-01-30), deprecated; community 14.6.1 (2026-11-26) | chart deprecated | behind #2382 |
| ingress-nginx | `platform/apps/ingress-nginx/` (2 files); `platform/networking/ingress-controller/` | 4.15.1 (2026-03-19), 4.11.3 | 4.15.1 (2026-03-19) | **upstream archived** | behind #2376 |
| kube-prometheus-stack | `platform/apps/prometheus/`; `scripts/dev-up.sh` | 89.2.2 (2026-09-04), 67.9.0 | 94.2.0 (2026-11-27) | n/r | behind #1735 |
| Kyverno | `platform/apps/kyverno/` | 3.3.3 (2026-11-11 in index) | 3.10.0 (2026-11-11) | app 1.13 not among current cycles | behind #2372 |
| Loki | `platform/apps/loki/` | 7.3.0 (2026-08-10) | 7.7.0 (2026-11-19); community 21.6.3 (2026-11-27) | n/r | behind #2383 |
| OpenTelemetry Collector | `platform/apps/opentelemetry/` | 0.172.1 (2026-09-05), image 0.114.0 (2024-11-19) | 0.183.2 (2026-11-24) | n/r | behind #2384 |
| sealed-secrets | `platform/apps/sealed-secrets/` | chart 2.19.3 (date n/r), image v0.28.0 (2025-01-16) | image v0.41.2 (2026-10-26); chart n/r (OCI) | n/r | behind #2388 |
| Secrets Store CSI driver | `platform/apps/vault-csi-driver/` | 1.4.4 (2024-06-18) | 1.6.2 (2026-11-19) | n/r | behind #2380 |
| SonarQube | `platform/apps/sonarqube-application.yaml`; `platform/apps/sonarqube/` | 2026.4.1 (2026-08-07); images 10.7.0, 7.9.1 | 2026.5.1008 (2026-11-25) | n/r | behind #2390 |
| Tempo | `platform/apps/tempo/` | 1.24.4 (2026-01-30) | 1.24.4 deprecated; community 3.2.1 (2026-10-21) | **chart deprecated** | behind #2383 |
| Vault chart | `platform/apps/vault/`; `scripts/dev-up.sh` | 0.28.1 (2024-07-12), 0.29.1 | 0.34.1 (2026-08-13) | server 1.17 EOL 2024-10-09 | behind #2380 |
| podinfo (sample) | `scripts/dev-up.sh` | 6.7.0 (2024-06-23) | 6.17.0 (2026-10-26) | n/r | exception: throwaway demo app for the local cluster |
| Weaviate | `extensions/ai/` | 16.8.8 (2024-04-08) | 17.9.0 (2026-11-23) | n/r | behind #2392 |
| DataHub | `extensions/data-platform/` | 0.4.26 (2024-09-18); image tag `head` | 1.1.12 (2026-11-25) | n/r | behind #2392 |

| Jenkins, Mattermost, Bitnami PostgreSQL charts | `infra/local-dev/deploy-local.sh` (also Backstage, and Argo CD from `stable`) | unpinned | n/r | Jenkins replaced (ADR-036) | behind #2394 |

## Vendored manifests and components with no pin

| Component | Set in | Pinned (date) | Latest stable (date) | Support / EOL | State |
|---|---|---|---|---|---|
| Tekton Pipelines | `platform/apps/tekton/upstream/` | v1.15.1 (2026-08-27) | v1.18.0 (2026-10-29) | n/r | behind #2389 |
| Tekton Triggers | `platform/apps/tekton/upstream/` | v0.37.0 (2026-08-05) | v0.38.0 (2026-11-09) | n/r | behind #2389 |
| PostgreSQL | `platform/apps/postgresql/db-shared-dev-cluster.yaml`; Terraform examples | 17.11 (date n/r); examples 15 | 17.12 (2026-11-09); 19.0 newest GA | 17 EOL 2029-11-08 | behind #2374 |
| OpenBao | not deployed (ADR-037) | none | chart 0.30.8 (2026-11-19), v2.7.3 | n/r | exception: not installed yet, #2380 |
| Kubernetes, AKS | `infra/azure/variables.tf` | null (unpinned) | 1.37 (AKS 2026-10-25) | 1.34 ends 2026-11-30 | behind #2378 |
| Kubernetes, EKS | `infra/aws/{variables.tf,terraform.tfvars.example}` | 1.28 (2023-09-26) | 1.37 (2026-10-01) | **EOL 2024-11-26** | behind #2378 |
| Kubernetes, local | `scripts/dev-up.sh` uses the current cluster | none | 1.37.3 (2026-11-25); k3s v1.37.2 (2026-11-03) | n/r | behind #2378 |
| Kubernetes, GKE | `infra/terraform/modules/gcp/gke/` | null (unpinned) | 1.37.3 (2026-11-25) | n/r | behind #2378 |
| Database engines in Terraform | modules and examples | PostgreSQL 15 / 15.4, MySQL 8.0.21 | PostgreSQL 19.0, MySQL 9.7 LTS | **MySQL 8.0 EOL 2026-04-30** | behind #2374 |
| MySQL (DevLake) | `platform/apps/devlake/values.yaml` | 8.0 | 9.7 LTS (2026-04-21) | **EOL 2026-04-30** | behind #2391 |

## Container images

| Component | Set in | Pinned (date) | Latest stable (date) | Support / EOL | State |
|---|---|---|---|---|---|
| Python | Dockerfiles, Tekton tasks, data-quality extension | 3.13.14 (2026-06-10), 3.13.15 (2026-08-05), 3.13.18 (2026-10-25), 3.11 | 3.13.18; 3.15.2 newest GA (2026-10-25) | 3.13 EOL 2029-10-31 | behind #2379; 3.13 line held (no wheels, see `dependabot.yml`) |
| Node.js | Dockerfiles, templates, CI; Tekton | 24.19.0 (2026-08-03); 22.14.0 (2025-02-11) | 24.22.3 (2026-11-11); 26 newest | 24 EOL 2028-04-30 | behind #2379 |
| Eclipse Temurin | Java Dockerfiles | 21.0.11 (date n/r) | 21.0.13 (2026-11-18); 25 LTS newer | 21 EOL 2029-12-31 | behind #2379 |
| Maven | Dockerfiles; Tekton template | 3.9.16, 3.9.9 (dates n/r) | n/r | n/r | behind #2379 |
| nginx | `design-system/` | 1.28.3 (2026-03-24) | 1.30.8 (2026-11-23) | **1.28 EOL 2026-04-14** | behind #2379 |
| distroless Python | `.security-plane/templates/` | debian11 | debian13 base | **debian11 EOL 2026-08-31** | behind #2379 |
| Kaniko | Tekton pipelines | v1.23.2 (2024-07-10) | v1.24.0 (2025-05-23) | **repo archived** | behind #2385 |
| Trivy | Tekton pipelines; `security-and-terraform.yml` | 0.74.0 (2026-08-14), v0.73.0 | v0.76.2 (2026-11-05) | n/r | behind #2385 |
| alpine/git, bitnami/kubectl, sonar-scanner-cli, busybox | Tekton | v2.45.2, 1.31.2 (2024-10-23), 11.2, 1.36 | n/r (kubectl follows Kubernetes 1.37) | kubectl 1.31 past EOL | behind #2385 |
| ZAP | Tekton DAST task | 2.16.1 (2025-03-25) | v2.17.0 (2025-12-15) | n/r | behind #2385 |
| Fluent Bit | `platform/observability/civo/` | 2.2.0 (2023-11-09) | v5.2.1 (2026-11-25) | n/r | behind #2377 |
| OTel contrib, ADOT, X-Ray daemon | `platform/observability/{gcp,aws}/` | 0.92.0 (2024-01-10), v0.40.0 (2024-06-26), 3.3.10 (2024-01-02) | v0.166.0, v0.51.0, v3.7.2 (2026-10 to 11) | n/r | behind #2377 |
| echo-server | ingress test manifest | 0.9.2 (2024-02-03) | 0.9.2 | n/r | current |
| Devfile images (universal developer, TensorFlow), redis | `platform/devfiles/`; `services/smart-alerting/docker-compose.yaml` | `ubi8-latest`, 2.15.0, `7-alpine` | redis 8.12.0 (2026-11-22) | n/r | behind #2385 |
| Devcontainer image | `.devcontainer/devcontainer.json` | 2.2.0 by digest | n/r | n/r | exception: Fawkes' sibling image, released by us |
| Vault server and CSI provider images | `platform/apps/vault/` | 1.17.3 (2024-08-07), 1.4.3 (2024-07-03) | v2.2.2 (2026-11-12), v1.8.0 (2026-11-26) | **server 1.17 EOL** | behind #2380 |
| Grafana images | `platform/apps/prometheus/`, `platform/apps/devlake/` | 11.5.2 (2025-02-19), 10.2.2 (2023-11-21) | 13.3.2 (2026-11-24) | **11.5 EOL 2025-10-28** | behind #2382 |
| Weaviate server, transformers-inference | `extensions/ai/` | 1.24.1 (2024-03-01); model tag | v1.41.0 (2026-11-23); n/r | n/r | behind #2392 |
| DataHub images | `extensions/data-platform/` | `head` | v1.9.1 (2026-11-19) | n/r | behind #2392 |
| SonarQube plugins | both SonarQube values files | several, disagreeing | n/r | n/r | behind #2390 |
| fawkesproxy | `infra/aws/proxy-all.yaml` | untagged | n/a | n/a | behind #2393 |
| Fawkes' own and sample images | `services/*/k8s/`, golden-path template | several `latest` | n/a | n/a | behind #2393 |

## Terraform, CI and CLI tools

| Component | Set in | Pinned (date) | Latest stable (date) | Support / EOL | State |
|---|---|---|---|---|---|
| Terraform CLI | workflows | 1.15.8 (2026-07-08) | 1.17.2 (2026-11-11) | n/r | behind #2385 |
| aws provider | `infra/aws`, modules, observability, networking | locks 5.100.0 to 6.73.0 | 6.74.0 (2026-11-23) | n/r | behind #2387 |
| azurerm provider | `infra/azure`, modules | locks 5.0.1 (2026-07-30), 5.14.0 | 5.15.0 (2026-11-24) | n/r | behind #2387 |
| google provider | modules, observability | locks 7.14.1 to 7.42.0 | 8.12.0 (2026-11-17) | n/r | behind #2387 |
| helm, kubernetes providers | `infra/terraform` | helm 2.17.0 (2024-12-20), kubernetes 3.2.1 | 3.3.0 (2026-09-02), 3.5.0 (2026-11-05) | n/r | behind #2387 |
| cloudinit, http, local, null, random, time, tls providers | lock files | patch or minor behind at most | local 2.9.1, random 3.9.1, time 0.14.2, tls 4.4.2 | n/r | behind #2387 |
| EKS and VPC modules | `infra/aws/main.tf` | `~> 21.0`, `~> 6.5` | 21.30.2, 6.9.0 | n/r | behind #2387 (ranges, not exact) |
| TFLint | workflows | v0.64.0 (2026-07-17) | v0.66.0 (2026-11-08) | n/r | behind #2385 |
| tfsec | pre-commit workflow | v1.28.14 (2025-05-02) | v1.28.14 | superseded by Trivy | behind #2385 |
| golangci-lint | pre-commit; `code-quality.yml` | v2.15.0, v2.12.2 | v2.15.0 (2026-10-16) | n/r | behind #2385 |
| conftest, yq, Helm CLI | workflows | 0.69.0, v4.53.3, unpinned or n/r | v0.71.1, v4.54.3, v4.3.2 | n/r | behind #2385 |
| Argo CD CLI | `pre-commit.yml` | v3.5.0 (2026-08-04) | v3.6.3 (2026-11-24) | 3.5 supported | behind #2371 |
| Prometheus Operator CRDs | `idp-e2e-tests.yml` | v0.93.1 (2026-08-10) | v0.95.2 (2026-11-12) | n/r | behind #1735 |
| uFawkesPipe (reusable workflows, hooks) | `.github/workflows/`, `.pre-commit-config.yaml`; `AGENTS.md` | v1.16.0-beta.1 pre-release; `AGENTS.md` says v1.2.0 | v2.0.1 (2026-11-20) | n/r | behind #2397 |
| gitleaks | pre-commit, workflows, `.gitops-templates/` | v8.30.1, v8.18.1 (2023-11-17) | v8.30.1 (2026-03-21) | n/r | behind #2385 |
| kubeconform | pre-commit workflow | v0.8.0 (2026-06-04) | v0.8.0 | n/r | current |
| kustomize, shfmt | workflows | v5.8.1 (2026-02-09), v3.8.0 (2024-02-11) | v5.8.3 (2026-10-08), v3.14.1 (2026-09-06) | n/r | behind #2385 |
| ruff, pre-commit (CI installs) | workflows | unpinned `pip install` | n/r | n/r | behind #2385 |
| Go toolchain | `go.mod`, workflows | 1.26 | 1.27.4 (2026-11-10) | 1.26 supported | behind #2385 |
| Pre-commit hooks | `.pre-commit-config.yaml` | per hook | n/r | n/r | exception: Dependabot `pre-commit` updates them monthly |
| GitHub Actions | `.github/` | by SHA | n/r | n/r | exception: Dependabot updates them weekly |

## Libraries and parts outside the stack

| Component | Set in | State |
|---|---|---|
| Python libraries | 51 `requirements*.txt` | exception: ADR-034 pins them; versions differ per service until #2299/#2300 merge the services |
| npm libraries (incl. design-system) | `package.json` files | exception: tracked in #1715; no automation, see #2386 |
| Go libraries | `go.mod`, `tests/terratest/go.mod` | exception: pinned by `go.sum`; no automation, see #2386 |
| Backstage plugins | `platform/apps/backstage/plugins` | behind #2375 (versions n/r) |
| OpenSearch, OpenSearch Dashboards | `platform/apps-deferred/` | exception: deferred, not installed; #1737 |
| Harbor 1.15.2 (latest 1.19.4), Eclipse Che 7.89.0, OpenReplay 1.14.0, other `apps-deferred` | `platform/apps-deferred/` | exception: deferred, not installed |

## Not verified

- "n/r" cells are real gaps: several support statuses and some dates and
  application versions were not read. The upgrade issue should fill them.

- Security advisories were counted by publication date, not checked against
  affected version ranges. Grafana and HashiCorp do not publish GitHub advisories.
- Nothing here was checked against a running cluster. A pinned value is what Git
  says, not what is installed.
- Whether a manifest is applied by a bootstrap was checked only where noted.
