# Security Plane - Onboarding Guide

## 🔒 Welcome to the Fawkes Security Plane

This guide will help you onboard your repository to the Fawkes Security Plane, which provides:
- 🔍 Automated security scanning (secrets, vulnerabilities, dependencies)
- 📦 SBOM (Software Bill of Materials) generation
- ✍️ Container image signing with Cosign
- 🛡️ Policy enforcement with OPA/Rego
- 📊 Security badges and dashboards

## Quick Start (5 minutes)

### Step 1: Copy Security Plane Files

```bash
# From your repository root
cp -r /path/to/fawkes/.security-plane .
```

### Step 2: Add Security Workflow

Create `.github/workflows/security.yml`:

```yaml
name: Security Checks

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main, develop]

permissions:
  contents: read
  security-events: write
  packages: write
  id-token: write

jobs:
  security:
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: advisory  # or 'strict' for blocking
      image-name: ${{ github.repository }}
      enable-signing: true
      enable-sbom: true
```

### Step 3: Configure Policies (Optional)

Edit `.security-plane/policies/*.rego` to customize enforcement rules for your needs.

### Step 4: Test Locally

```bash
# Install Conftest for local policy testing
brew install conftest  # macOS
# or
curl -L https://github.com/open-policy-agent/conftest/releases/download/v0.49.1/conftest_0.49.1_Linux_x86_64.tar.gz | tar xz
sudo mv conftest /usr/local/bin/

# Test Kubernetes manifests
conftest test k8s/*.yaml -p .security-plane/policies/

# Test Dockerfile
conftest test Dockerfile -p .security-plane/policies/
```

## Adoption Modes

### 🟢 Advisory Mode (Recommended for Start)
- Scans run but don't block PRs/deployments
- Great for understanding current security posture
- Provides visibility without disrupting workflow

```yaml
enforcement-mode: advisory
fail-on-critical: false
```

### 🟡 Progressive Mode
- Block only CRITICAL vulnerabilities
- Warn on HIGH and MEDIUM
- Gradual enforcement increase

```yaml
enforcement-mode: strict
severity-threshold: CRITICAL
fail-on-critical: true
```

### 🔴 Strict Mode (Production)
- Block all policy violations
- Enforce image signing
- Require SBOMs
- No vulnerabilities above threshold

```yaml
enforcement-mode: strict
fail-on-critical: true
fail-on-violation: true
```

## What Gets Scanned

### Secrets
- Gitleaks scans for hardcoded credentials
- Patterns: API keys, tokens, passwords, private keys

### Vulnerabilities
- Trivy scans container images and filesystems
- Checks against CVE databases
- Reports severity: UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL

### Dependencies
- npm audit for Node.js
- safety for Python
- Trivy for Go, Java, Rust, etc.

### Policy Compliance
- Kubernetes security best practices
- Dockerfile hardening
- Supply chain security (SBOM, signatures)

## Customizing for Your Repo

### 1. Update `.security-plane/policies/kubernetes-security.rego`

```rego
# Add your own policies
deny[msg] {
    input.kind == "Deployment"
    # Your custom logic
    msg := "Your custom error message"
}
```

### 2. Configure Exemptions

Create `.security-plane/exemptions.yaml`:

```yaml
vulnerabilities:
  # Exempt specific CVEs with justification
  - cve: CVE-2023-12345
    reason: "False positive - not exploitable in our use case"
    expires: "2024-12-31"

policies:
  # Exempt specific files from policy checks
  - path: "test/**"
    policy: "require-resource-limits"
    reason: "Test resources don't need limits"
```

### 3. Add Custom Security Workflow Steps

Edit `.github/workflows/security.yml` to add repo-specific checks:

```yaml
jobs:
  custom-security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run custom security tool
        run: ./scripts/custom-security-check.sh
```

## Security Badges

Add to your README.md:

```markdown
![Security Scan](https://github.com/your-org/your-repo/workflows/Security%20Checks/badge.svg)
![Vulnerabilities](https://img.shields.io/github/issues/your-org/your-repo/vulnerability)
```

## Remediation Workflow

When security issues are found:

1. **Review the scan results** in GitHub Actions logs
2. **Check GitHub Security tab** for detailed vulnerability info
3. **Prioritize fixes** based on severity and exploitability
4. **Update dependencies** or patch code
5. **Re-run scans** to verify fixes
6. **Document exemptions** if issues can't be fixed immediately

### Example Remediation

For a vulnerable npm package:

```bash
# Check for updates
npm outdated

# Update specific package
npm update package-name

# Or update all
npm update

# Audit
npm audit fix

# Re-run security workflow
git commit -am "fix: update vulnerable dependencies"
git push
```

## Troubleshooting

### Scans Taking Too Long
- Reduce scan scope with `.trivyignore`
- Cache Trivy database between runs

### Too Many False Positives
- Add exemptions in `.security-plane/exemptions.yaml`
- Adjust severity threshold
- Customize policies

### Policy Failures
- Review policy in `.security-plane/policies/`
- Run `conftest test` locally
- Add policy exemptions if needed

### SBOM Generation Fails
- Ensure package manifest files exist (package.json, requirements.txt, etc.)
- Check Syft supports your language
- Try different SBOM format (cyclonedx vs spdx)

## Next Steps

1. ✅ Run first security scan
2. 📊 Review results in GitHub Security tab
3. 🔧 Fix critical and high-severity issues
4. 📈 Monitor security metrics over time
5. 🚀 Move to progressive or strict enforcement
6. 📚 Train team on security best practices

## Support

- 📖 Documentation: `docs/security-plane/`
- 💬 Slack: #fawkes-security
- 🐛 Issues: https://github.com/paruff/fawkes/issues
- 📧 Email: security-team@example.com

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [OPA/Rego Policy Language](https://www.openpolicyagent.org/docs/latest/policy-language/)
