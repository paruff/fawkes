# Shift Left on Security Pattern

Shifting security left means integrating security practices early and continuously
throughout the development lifecycle rather than applying them as a final gate before
release. This approach reduces the cost of fixing vulnerabilities (a bug found in code
review costs 10× less to fix than one found in production) and enables teams to
maintain high deployment velocity without compromising security posture.

## Security Throughout the Lifecycle

### In the IDE

Developers catch security issues before they even commit:
- IDE plugins (SonarLint) provide real-time SAST feedback
- Pre-commit hooks (`detect-secrets`, `gitleaks`) block credential commits
- Dependency vulnerability warnings surface in the editor

### In Every Pull Request

Every PR automatically runs:

```
SAST (SonarQube) → Dependency scan (Dependabot/pip-audit)
                 → Secret detection (detect-secrets)
                 → Container scan (Trivy)
                 → IaC scan (tflint, checkov)
```

All HIGH/CRITICAL findings block merge. Developers see the finding inline in the PR.

### In Staging

OWASP ZAP runs a full active scan against the deployed staging environment before
any release candidate is promoted to production. This catches runtime vulnerabilities
that static analysis cannot detect.

### In Production

Runtime security:
- **Kyverno** enforces pod security standards (no root containers, read-only filesystem)
- **Network policies** restrict lateral movement between namespaces
- **Falco** (optional) detects anomalous runtime behaviour

## Developer Security Training

The dojo learning path includes a security module covering OWASP Top 10, secure
coding practices for Python/Java/Go, and how to interpret security tool findings.
Teams that invest in developer security education see 50% fewer new vulnerabilities
per sprint.

## Security Debt Tracking

SonarQube assigns a "security hotspot" category to findings requiring human review.
Track open security hotspots in the team's backlog with the same urgency as bug tickets.

## See Also

- [Zero Trust Model](../explanation/security/zero-trust-model.md)
- [Security Pattern](security.md)
- [OWASP ZAP](../tools/owasp-zap.md)
