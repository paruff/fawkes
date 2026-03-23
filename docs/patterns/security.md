# Shift Left on Security Pattern

"Shift left" means moving security testing earlier in the software delivery lifecycle —
from a gate at the end of the process to a continuous practice throughout development.
DORA research shows that teams that integrate security into their daily work achieve
twice as many security-related deployments as those that treat security as a separate
phase.

## What Shifting Left Means in Practice

| Traditional (right) | Shift Left |
|--------------------|------------|
| Security review before release | Security checks in every PR |
| Separate penetration testing team | Developers own security testing |
| Fix vulnerabilities reactively | Prevent vulnerabilities by design |
| Quarterly security scans | Continuous automated scanning |
| Security blocks releases | Security enables faster releases |

## Fawkes Security Gates

Every pull request in Fawkes runs:

1. **SAST (Static Analysis)** — SonarQube scans source code for security vulnerabilities
   without executing the code. Detects SQL injection, XSS, hardcoded secrets, insecure
   crypto usage.

2. **Dependency scanning** — Dependabot and `pip-audit`/`npm audit` flag packages with
   known CVEs. The `gh-advisory-database` tool is used before adding new dependencies.

3. **Container scanning** — Trivy scans built container images for OS and library
   vulnerabilities. HIGH and CRITICAL findings fail the build.

4. **Secret detection** — `detect-secrets` pre-commit hook prevents credentials from
   reaching Git history.

5. **DAST (Dynamic Analysis)** — OWASP ZAP scans deployed test environments for runtime
   vulnerabilities (run on every release candidate).

## Security as Code

Policy as code (via Kyverno) enforces security requirements at the infrastructure level:
- No containers run as root
- All containers have CPU/memory limits
- No `hostPath` volumes in production namespaces
- All images come from the approved registry

## Developer Responsibilities

Developers are responsible for:
- Reviewing Dependabot PRs within one sprint
- Addressing SonarQube security findings before merge
- Never committing secrets (use Vault + External Secrets Operator)

## See Also

- [Zero Trust Model](../explanation/security/zero-trust-model.md)
- [OWASP ZAP](../tools/owasp-zap.md)
- [SonarQube](../tools/sonarqube.md)
