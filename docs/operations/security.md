# Security Operations

This page is the operational entry point for all security-related processes in Fawkes.

---

## Responsible Disclosure Policy

Fawkes has a responsible disclosure (coordinated vulnerability disclosure) policy for security
researchers and users who discover vulnerabilities in the platform.

👉 **See [SECURITY.md](https://github.com/paruff/fawkes/blob/main/SECURITY.md) at the repository root for the full policy**, including:

- Supported versions
- How to privately report a vulnerability (GitHub Security Advisory or email)
- Response SLA (acknowledgement within 72 hours, fixes within 30–90 days)
- Scope (what is and is not covered)
- Safe-harbour commitments
- What happens when secrets are accidentally exposed in public issues

---

## Reporting a Vulnerability (Quick Reference)

| Channel | Link / Address |
| ------- | -------------- |
| GitHub Private Advisory (preferred) | [Open an advisory](https://github.com/paruff/fawkes/security/advisories/new) |
| Email | security@fawkes-project.org |

**Do not** file a public GitHub issue for security vulnerabilities. Use the private channels above.

---

## Published Advisories

Resolved security advisories are published at:

👉 [https://github.com/paruff/fawkes/security/advisories](https://github.com/paruff/fawkes/security/advisories)

---

## Security Controls

For a description of the platform's security model, controls, and recommendations, see the
[Security overview](../security.md).

For operational how-to guides, see:

- [Rotate Vault Secrets](../how-to/security/rotate-vault-secrets.md)
- [Quality Gates Configuration](../how-to/security/quality-gates-configuration.md)

---

## Secrets Handling

If sensitive information (credentials, API keys, tokens) is accidentally committed to the
repository or posted in a public issue:

1. Contact **security@fawkes-project.org** immediately.
2. The maintainers will **remove or redact** the content.
3. Affected credentials will be **rotated** as soon as possible.
4. Access logs will be **audited** to assess potential misuse.

See [Secrets Management Guide](../how-to/security/secrets-management.md) for preventive controls.
