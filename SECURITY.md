# Security Policy — fawkes

## Supported versions

| Version | Supported |
|---|---|
| `main` branch | ✅ Active — patches applied here first |
| Tagged releases | ✅ Critical fixes backported where practical |
| Older releases | ❌ No active support |

We follow [Semantic Versioning](https://semver.org). The first stable release
is `v0.1.0`. Check [CHANGELOG.md](./CHANGELOG.md) for what each release
contains.

---

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report privately using one of these channels, in order of preference:

1. **GitHub private vulnerability reporting** (preferred):
   [Security → Report a vulnerability](https://github.com/paruff/fawkes/security/advisories/new)
   — this keeps the report confidential until a fix is published.

2. **Email**: Contact the maintainer via the email address on the
   [paruff GitHub profile](https://github.com/paruff). Use the subject line
   `[fawkes] Security report`.

Include in your report:

- Affected component (e.g. Kubernetes manifests, Helm charts, platform services,
  Terraform modules, CI/CD pipelines, secrets management)
- Steps to reproduce or a minimal proof of concept
- Your assessment of severity and impact
- Whether you have already disclosed this elsewhere

---

## Response timeline

| Stage | Target |
|---|---|
| Acknowledgement | Within 72 hours of receipt |
| Initial triage and severity assessment | Within 5 business days |
| Fix or mitigation published | Depends on severity (see below) |
| Public disclosure | After fix is available, coordinated with reporter |

**Severity guidelines:**

- **Critical** (CVSS ≥ 9.0): fix targeted within 7 days
- **High** (CVSS 7.0–8.9): fix targeted within 14 days
- **Medium / Low**: addressed in the next scheduled release

We will credit reporters in the release notes and CHANGELOG unless you
request anonymity.

---

## Scope

This policy covers the fawkes repository and its default configuration.
It does not cover:

- Third-party components (Kubernetes, Helm, Terraform, ArgoCD, Prometheus,
  Grafana, Loki, Tempo, OpenTelemetry, Istio, cert-manager, External Secrets
  Operator, and all upstream dependencies). Report upstream vulnerabilities
  to those projects. We will update pinned versions promptly when upstream
  patches are available.
- Deployments where users have modified the default configuration.
- The broader [uFawkes suite](https://github.com/paruff) — each repo has its
  own security policy.

---

## Security design notes

These are known constraints in this release. They are documented here rather
than treated as vulnerabilities:

**Multi-tenant Kubernetes platform.** fawkes implements isolation via
namespaces, NetworkPolicies, and RBAC. Review tenant isolation if your
threat model requires stronger guarantees.

**Secrets management.** Secrets are managed via External Secrets Operator
with external secret stores (AWS Secrets Manager, Vault, etc.). The default
configuration uses placeholder secrets — replace before production use.

**ArgoCD and GitOps.** ArgoCD manages cluster state from Git. Ensure Git
repository and ArgoCD access controls are properly configured. ArgoCD admin
access should be tightly controlled.

**Network policies.** Default deny NetworkPolicies are applied; egress
requires explicit allow-lists. Verify policies match your threat model.

**Image supply chain.** Container images are built via CI and pushed to
GHCR. Image signatures and SBOMs are generated; verify before deployment.

**Credential boundaries.** The `.env` / `.env.example` pattern defines
credential boundaries. Never commit populated `.env` files. Startup
validation in `make check-env` blocks deployment if defaults are detected.

**No TLS in default development configuration.** Inter-service mTLS is
enabled via Istio in production profiles only. Configure TLS before
exposing any service outside the cluster.

---

## Dependency management

Go module versions are pinned in `go.sum`. Helm chart dependencies are
pinned in `Chart.lock` files. Container image tags are pinned in CI and
Helm values. We review upstream release notes for security advisories and
update pinned versions as part of each release cycle. If a critical upstream
vulnerability is published between releases, we will cut a patch release.

To check for outdated dependencies:

```bash
go list -m -u all
helm dependency list charts/*
docker compose pull --dry-run
```

---

## AI-generated code policy

See [AI_STANCE.md](./AI_STANCE.md). AI-generated Kubernetes manifests,
Terraform modules, Helm templates, and CI/CD pipelines require human review
before merge — misconfigured infrastructure has real production impact.
