# Change Impact Map — Fawkes IDP

> DORA AI Cap 3: Agents cannot reason about cross-component impact without this map.
> Because Fawkes is a platform (infra → platform → services → docs), a change in one
> layer commonly breaks two or three others. Check this table before touching anything.
>
> Update this file whenever a cross-component dependency is discovered or changed.
> Maintained by `@docs-agent` — triggered when `services/`, `infra/`, or `platform/` change.

---

## Infrastructure Layer (infra/)

| If you change... | You must also check / update... |
|---|---|
| Terraform variable name | All `.tfvars` files that set it, CI workflows that pass it, `docs/reference/config/` |
| Terraform output name | Any `platform/` manifests that reference it via data source, CI workflows |
| EKS cluster name or version | ArgoCD `Application` server URLs, `platform/apps/`, kubeconfig references in `scripts/` |
| VPC or subnet IDs | All security groups, RDS, EKS node groups referencing them |
| IAM role ARNs | Service account annotations in `platform/`, IRSA bindings |
| AWS region variable | AMI lookups, availability zone references, S3 bucket regions |
| Vault configuration | `platform/apps/vault/`, ExternalSecrets references in `platform/`, `docs/how-to/security/` |
| New Terraform module | `docs/reference/config/`, `CHANGE_IMPACT_MAP.md` (this file) |

---

## Platform Layer (platform/, charts/)

| If you change... | You must also check / update... |
|---|---|
| Helm chart `values.yaml` key names | All environment override files (`values-dev.yaml`, `values-prod.yaml`), ArgoCD `Application` helm.values |
| ArgoCD `Application` `targetRevision` | Deployment runbook in `docs/runbooks/`, any CD pipeline references |
| Backstage catalog `component.yaml` | Backstage software catalog — refresh required; `docs/` for that component |
| Kubernetes namespace name | All `Application` destination namespaces, RBAC RoleBindings, NetworkPolicies |
| Image repository or tag format | CI workflow build/push steps, Helm `image.repository` values |
| Service port numbers | Ingress rules, NetworkPolicies, service-to-service gRPC/HTTP calls |
| Kyverno policy | Test it against existing workloads with `kyverno test` before merging |
| Jenkins shared library version | `Jenkinsfile` references in `jenkins-shared-library/`, `docs/tools/jenkins/` |

---

## Services Layer (services/)

| If you change... | You must also check / update... |
|---|---|
| Service API contract (gRPC/HTTP) | All callers in other services, API docs in `docs/reference/api/`, `docs/API_SURFACE.md` |
| Service port | Helm chart `values.yaml`, Kubernetes `Service` spec, Ingress rules |
| Environment variable names | Helm chart `env:` blocks, `platform/apps/{service}/`, `.env.example` if present |
| Database schema | Migration files, service models, `docs/DATA_MODEL.md`, related service tests |
| Authentication middleware | All services that rely on the same auth pattern, security agent review required |
| `go.mod` dependency | Check for version conflicts with other services; update `go.sum` |
| New service added | Add to Backstage catalog, add to ArgoCD, add to `docs/API_SURFACE.md`, add to CHANGE_IMPACT_MAP |

---

## Scripts Layer (scripts/)

| If you change... | You must also check / update... |
|---|---|
| `ignite.sh` flags or behaviour | `README.md` quickstart, `docs/tutorials/1-deploy-first-service/`, `docs/getting-started/` |
| `weekly-metrics.sh` output format | `docs/METRICS.md` interpretation guide |
| Any script used in CI | The workflow(s) that call it; re-test the full workflow |

---

## Docs Layer (docs/)

| If you change... | You must also check / update... |
|---|---|
| Navigation structure (`mkdocs.yml`) | All internal `[text](../relative-link)` links — run `mkdocs build --strict` |
| A how-to guide procedure | The corresponding tutorial if steps are shared |
| A runbook procedure | Test the runbook against a real (or simulated) incident scenario |
| Golden Path template | `docs/tutorials/5-create-golden-path-template/`, Backstage software template |
| DORA metrics definitions | `docs/playbooks/dora-metrics-implementation/`, the DevLake dashboard config |

---

## Cross-Cutting Changes (Touch Multiple Layers)

| Change | All layers affected |
|---|---|
| New cloud provider (e.g. GCP alongside AWS) | `infra/` new module + `platform/` new values + `docs/` new how-to + `scripts/ignite.sh` flag |
| New observability tool | `platform/apps/` + `services/` instrumentation + `docs/explanation/observability/` + `docs/how-to/observability/` |
| New authentication provider | `infra/` IAM + `platform/` OIDC config + `services/` middleware + `docs/how-to/security/` |
| Kubernetes version upgrade | `infra/` EKS version + `platform/` API version audit (`kubectl deprecations`) + all chart API versions + test suite |
| New DORA metric tracked | `services/` metrics collector + `platform/` DevLake config + `docs/METRICS.md` + `scripts/weekly-metrics.sh` |
