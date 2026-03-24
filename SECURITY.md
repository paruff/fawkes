# Security Policy

## Supported Versions

The following versions of Fawkes are currently supported with security updates:

| Version                   | Supported  |
| ------------------------- | ---------- |
| `main`                    | ✅ Yes     |
| Latest stable release tag | ✅ Yes     |
| Pre-release tags          | ❌ No      |
| Older release tags        | ❌ No      |

We only provide security fixes for the `main` branch and the latest stable tagged release. Pre-release builds and older release tags do not receive backported security fixes.

---

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Reporting security issues publicly before a fix is available puts the entire community at risk. Instead, use one of the following private channels:

### Option 1 — GitHub Private Security Advisory (Preferred)

Use GitHub's built-in private vulnerability reporting:

👉 [Open a private security advisory](https://github.com/paruff/fawkes/security/advisories/new)

This creates a private, encrypted channel between you and the maintainers. No one else can see the report until it is resolved and published.

### Option 2 — Email

Send a report to **security@fawkes-project.org** with the subject line:

```
[SECURITY] <brief description>
```

---

## What to Include in Your Report

To help us triage quickly, include as much of the following as possible:

- Description of the vulnerability and its potential impact
- Affected component(s) and version(s)
- Steps to reproduce or a proof-of-concept (PoC)
- Any suggested remediation or mitigation
- Whether you have already disclosed the issue elsewhere

---

## What to Expect

| Timeline        | Commitment                                              |
| --------------- | ------------------------------------------------------- |
| **72 hours**    | Acknowledgement that we have received your report       |
| **7 days**      | Initial assessment and severity triage                  |
| **30 days**     | Fix or mitigation released for critical/high issues     |
| **90 days**     | Fix or mitigation released for medium/low issues        |
| **Coordinated** | We will coordinate public disclosure timing with you    |

We follow coordinated vulnerability disclosure (CVD). We ask that you give us reasonable time to address the issue before public disclosure.

---

## Scope

### In Scope

The responsible disclosure policy covers vulnerabilities **in the Fawkes platform codebase** hosted in this repository, including:

- Python FastAPI services (`services/`)
- Infrastructure-as-Code modules (`infra/`)
- Helm charts and Kubernetes manifests (`charts/`, `platform/`)
- CI/CD pipeline definitions (`.github/workflows/`)
- Bash automation scripts (`scripts/`)
- Documentation that contains misleading security guidance (`docs/`)

### Out of Scope

The following are **not** covered by this policy:

- Vulnerabilities in **deployed instances** of Fawkes operated by third parties
- Vulnerabilities in **upstream dependencies** — report those directly to the upstream project
- Denial-of-service attacks against the maintainers' own infrastructure
- Social engineering attacks against maintainers or contributors
- Issues already known and tracked in the public issue tracker

---

## Safe Harbour

We will not pursue legal action against security researchers who:

- Report vulnerabilities through the private channels described above
- Act in good faith and do not exploit vulnerabilities beyond what is needed to demonstrate the issue
- Do not access, modify, or delete data belonging to others
- Do not perform attacks against our infrastructure or third parties

---

## Secrets and Credentials in Issues

If a public GitHub issue, pull request, discussion, or commit accidentally contains secrets, credentials, API keys, or tokens:

1. We will **remove or redact** the sensitive content immediately
2. We will **rotate** any exposed credentials as soon as possible
3. We will **audit** access logs to determine whether the credential was used maliciously

If you notice exposed credentials in the repository, please report them privately using the channels above — do not create a public issue referencing the secret value.

---

## Security Advisories

Published security advisories for Fawkes are available at:

👉 [https://github.com/paruff/fawkes/security/advisories](https://github.com/paruff/fawkes/security/advisories)

---

## Contact

- **Private advisory (preferred):** [https://github.com/paruff/fawkes/security/advisories/new](https://github.com/paruff/fawkes/security/advisories/new)
- **Email:** security@fawkes-project.org
- **General questions:** [GitHub Discussions](https://github.com/paruff/fawkes/discussions)

Thank you for helping keep Fawkes and its users safe.
