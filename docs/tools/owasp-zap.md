# OWASP ZAP

[OWASP ZAP](https://www.zaproxy.org/) (Zed Attack Proxy) is the world's most widely
used open-source web application security scanner, maintained by the Open Worldwide
Application Security Project (OWASP). It is a Dynamic Application Security Testing
(DAST) tool that tests running applications for vulnerabilities.

## How Fawkes Uses OWASP ZAP

ZAP runs as a Docker container in the CI pipeline against a freshly deployed test
environment after successful unit and integration tests. It scans the application's
HTTP endpoints for common vulnerabilities from the OWASP Top 10.

```yaml
# GitHub Actions workflow step (example)
- name: OWASP ZAP Baseline Scan
  uses: zaproxy/action-baseline@v0.11.0
  with:
    target: https://test-env.fawkes.internal
    rules_file_name: .zap/rules.tsv
    fail_action: true
```

## Scan Types

| Type | Coverage | Speed | When Used |
|------|----------|-------|-----------|
| **Baseline** | Passive scan only | Fast (1–2 min) | Every PR |
| **Full Scan** | Active attack simulation | Slow (10–30 min) | Nightly / release |
| **API Scan** | OpenAPI/Swagger endpoints | Medium | API services |

## Common Findings

ZAP detects vulnerabilities such as:
- Missing security headers (`Content-Security-Policy`, `X-Frame-Options`)
- Cross-Site Scripting (XSS) risks
- SQL injection opportunities
- Sensitive data in responses
- Outdated TLS configurations

## Reviewing Results

ZAP generates HTML reports stored as CI artifacts. Filter by **Risk Level**:

- **High / Critical** — Must fix before merge
- **Medium** — Fix in current sprint
- **Low / Informational** — Track in backlog

## False Positive Management

Create a `.zap/rules.tsv` file to suppress known false positives:

```tsv
10038	IGNORE	(Anti-CSRF Tokens)	Internal admin endpoint, CSRF not applicable
```

## See Also

- [Shift Left on Security Pattern](../patterns/shift-left-on-security.md)
- [Quality Gates Configuration](../how-to/security/quality-gates-configuration.md)
- [Zero Trust Model](../explanation/security/zero-trust-model.md)
