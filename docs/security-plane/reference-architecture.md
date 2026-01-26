# Fawkes Security Plane - Reference Architecture

## Overview

The **Fawkes Security Plane** is a comprehensive, repository-agnostic security framework designed to provide automated security scanning, policy enforcement, SBOM generation, and image signing for the Fawkes Internal Developer Platform (IDP).

### Design Principles

1. **Works on Existing Repos** - Can be adopted after-the-fact, no need for repo creation
2. **Centralized Logic, Decentralized Adoption** - Reusable workflows, per-repo configuration
3. **Guardrails > Gates Initially** - Advisory mode by default, progressive enforcement
4. **DORA-Aligned** - Supports elite team performance metrics

### Key Features

- 🔍 **Security Scanning**: Secrets, vulnerabilities, dependencies
- 📦 **SBOM Generation**: Software Bill of Materials for supply chain security
- ✍️ **Image Signing**: Cosign-based cryptographic signatures
- 🛡️ **Policy Enforcement**: OPA/Rego policies for security compliance
- 📊 **Security Dashboards**: Badges, reports, and GitHub Security integration

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Fawkes Security Plane                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐   │
│  │   Scanning     │  │  Policy        │  │  Supply Chain  │   │
│  │   Engine       │  │  Enforcement   │  │  Security      │   │
│  │                │  │                │  │                │   │
│  │ • Gitleaks     │  │ • OPA/Conftest │  │ • SBOM (Syft)  │   │
│  │ • Trivy        │  │ • Rego Policies│  │ • Signing      │   │
│  │ • npm audit    │  │ • Kubernetes   │  │   (Cosign)     │   │
│  │ • safety       │  │ • Dockerfile   │  │ • Verification │   │
│  └────────────────┘  └────────────────┘  └────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │          Reusable GitHub Actions Workflows                │  │
│  │                                                            │  │
│  │  • reusable-security-scanning.yml                        │  │
│  │  • reusable-policy-enforcement.yml                       │  │
│  │  • reusable-sbom-generation.yml                          │  │
│  │  • reusable-image-signing.yml                            │  │
│  │  • security-plane-adoption.yml (orchestrator)            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    Policy Repository                       │  │
│  │                                                            │  │
│  │  .security-plane/policies/                                │  │
│  │  ├── kubernetes-security.rego                             │  │
│  │  ├── dockerfile-security.rego                             │  │
│  │  └── supply-chain-security.rego                           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Integration
                              │
┌─────────────────────────────▼─────────────────────────────┐
│                   Developer Repositories                    │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  .github/workflows/security.yml                     │   │
│  │  ↓                                                  │   │
│  │  Uses: paruff/fawkes/.github/workflows/            │   │
│  │        security-plane-adoption.yml@main            │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌────────────────────────────────────────────────────┐   │
│  │  .security-plane/                                   │   │
│  │  ├── policies/ (customized)                        │   │
│  │  └── exemptions.yaml                               │   │
│  └────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ Results & Artifacts
                              │
┌─────────────────────────────▼─────────────────────────────┐
│                   GitHub Security & Registry                │
│                                                             │
│  • SARIF uploads to GitHub Security tab                    │
│  • SBOMs as GitHub artifacts                               │
│  • Signed images in GitHub Container Registry              │
│  • Security badges in README                               │
│  • Issue creation for vulnerabilities                      │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Scanning Engine

**Purpose**: Detect security issues in code, dependencies, and containers

**Tools**:
- **Gitleaks**: Secret scanning (API keys, tokens, credentials)
- **Trivy**: Vulnerability scanning (CVEs, misconfigurations)
- **npm audit**: Node.js dependency vulnerabilities
- **safety**: Python dependency vulnerabilities

**Workflow**: `reusable-security-scanning.yml`

**Inputs**:
- `scan-type`: all, secrets, vulnerabilities, dependencies, container
- `severity-threshold`: UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL
- `fail-on-critical`: Block on critical vulnerabilities

**Outputs**:
- SARIF files uploaded to GitHub Security
- Summary in job output
- Artifacts for detailed reports

### 2. Policy Enforcement

**Purpose**: Enforce security best practices and compliance requirements

**Tools**:
- **Conftest**: OPA/Rego policy evaluation
- **OPA**: Open Policy Agent for policy-as-code

**Workflow**: `reusable-policy-enforcement.yml`

**Policy Types**:
1. **Kubernetes Security** (`kubernetes-security.rego`)
   - Non-root containers
   - Resource limits
   - Security contexts
   - Network policies

2. **Dockerfile Security** (`dockerfile-security.rego`)
   - No root user
   - Specific base image versions
   - Health checks
   - Minimal layers

3. **Supply Chain Security** (`supply-chain-security.rego`)
   - Block critical vulnerabilities
   - Require SBOM
   - Require image signatures
   - Approved registries

**Inputs**:
- `policy-path`: Path to policy files
- `target-path`: Files to validate
- `fail-on-violation`: Block on violations

### 3. SBOM Generation

**Purpose**: Create Software Bill of Materials for supply chain transparency

**Tools**:
- **Syft**: SBOM generation (CycloneDX, SPDX formats)

**Workflow**: `reusable-sbom-generation.yml`

**Inputs**:
- `image-name`: Container image name
- `image-tag`: Image tag
- `sbom-format`: cyclonedx-json, spdx-json, syft-json

**Outputs**:
- SBOM file as GitHub artifact
- Package count summary
- Retention: 90 days

### 4. Image Signing

**Purpose**: Cryptographically sign container images for authenticity

**Tools**:
- **Cosign**: Keyless image signing with Sigstore

**Workflow**: `reusable-image-signing.yml`

**Features**:
- Keyless signing with OIDC
- SBOM attestation
- Signature verification
- Registry integration

**Inputs**:
- `image-name`: Image to sign
- `registry`: Container registry (ghcr.io)
- `sign-sbom`: Also sign SBOM attestation

### 5. Orchestration Workflow

**Purpose**: Coordinate all security plane components

**Workflow**: `security-plane-adoption.yml`

**Jobs**:
1. `security-scan`: Run all security scans
2. `policy-enforcement`: Validate against policies
3. `generate-sbom`: Create SBOM (if image specified)
4. `sign-image`: Sign image (on push to main)
5. `security-summary`: Generate status badge

**Trigger Events**:
- `push`: On commits to main/develop
- `pull_request`: On PRs
- `workflow_dispatch`: Manual trigger with options

## Adoption Patterns

### Pattern 1: Advisory Mode (Getting Started)

**Use Case**: Understanding current security posture without blocking

**Configuration**:
```yaml
# .github/workflows/security.yml
jobs:
  security:
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: advisory
      fail-on-critical: false
```

**Behavior**:
- ✅ Scans run on every PR and push
- ✅ Results visible in GitHub Security
- ❌ No blocking - PRs can merge
- ✅ Team learns about issues

**Timeline**: 1-2 weeks

### Pattern 2: Progressive Enforcement

**Use Case**: Gradual rollout with critical-only blocking

**Configuration**:
```yaml
jobs:
  security:
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: strict
      fail-on-critical: true
      severity-threshold: CRITICAL
```

**Behavior**:
- ✅ Scans run on every PR and push
- ❌ CRITICAL vulnerabilities block
- ⚠️ HIGH/MEDIUM are warnings
- ✅ Gradual improvement

**Timeline**: 2-4 weeks after advisory

### Pattern 3: Strict Mode (Production)

**Use Case**: Full enforcement for production-ready repos

**Configuration**:
```yaml
jobs:
  security:
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: strict
      fail-on-critical: true
      fail-on-violation: true
      severity-threshold: MEDIUM
      enable-signing: true
      enable-sbom: true
```

**Behavior**:
- ❌ Any policy violation blocks
- ❌ MEDIUM+ vulnerabilities block
- ✅ Images must be signed
- ✅ SBOMs required
- ✅ Production-grade security

**Timeline**: 4-8 weeks after progressive

## Integration with Fawkes IDP

### Golden Path Templates

Service templates automatically include security plane:

```
templates/
├── java-service/
│   ├── .github/workflows/security.yml
│   └── .security-plane/
├── nodejs-service/
│   ├── .github/workflows/security.yml
│   └── .security-plane/
└── python-service/
    ├── .github/workflows/security.yml
    └── .security-plane/
```

### Backstage Integration

Security metrics visible in Backstage:

```yaml
# catalog-info.yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: my-service
  annotations:
    github.com/project-slug: org/repo
    security-plane/enabled: 'true'
    security-plane/mode: 'strict'
```

### Jenkins Integration

Jenkins pipelines can call security workflows:

```groovy
// Jenkinsfile
stage('Security Scan') {
    steps {
        sh 'gh workflow run security-plane-adoption.yml'
    }
}
```

### ArgoCD Integration

Security policies enforced before deployment:

```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  syncPolicy:
    automated:
      prune: true
    syncOptions:
      - Validate=true  # Validates against policies
```

## Metrics & Monitoring

### DORA Metrics

Security plane supports DORA metrics:

- **Deployment Frequency**: No security blocking delays
- **Lead Time**: Fast security feedback in PRs
- **Change Failure Rate**: Reduced by catching issues pre-deployment
- **Mean Time to Recovery**: Faster incident response with SBOMs

### Security Metrics

Track over time:
- Number of vulnerabilities (by severity)
- Policy violations (by type)
- MTTR for security issues
- % of repos with security plane enabled
- % of images signed
- SBOM coverage

### Dashboards

**GitHub Security Tab**:
- Vulnerability alerts
- Secret scanning alerts
- SARIF results

**Grafana Dashboard** (planned):
- Security posture overview
- Vulnerability trends
- Policy compliance rates
- SBOM coverage

## Extensibility

### Adding New Policies

1. Create new `.rego` file in `.security-plane/policies/`
2. Define deny/warn rules
3. Test locally with `conftest test`
4. Commit and policies are automatically enforced

Example:
```rego
# .security-plane/policies/custom.rego
package main

deny[msg] {
    input.kind == "Deployment"
    # Your custom logic
    msg := "Your custom policy message"
}
```

### Adding New Languages

Update scanning workflows to include new language tools:

```yaml
# reusable-security-scanning.yml
- name: Check Rust dependencies
  run: cargo audit
```

### Adding New Scanners

Extend workflows with additional tools:

```yaml
jobs:
  custom-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run custom scanner
        run: custom-tool scan
```

## Best Practices

### For Platform Teams

1. **Start with Advisory Mode**: Don't block teams immediately
2. **Provide Training**: Help teams understand security findings
3. **Regular Updates**: Keep policies and tools up-to-date
4. **Measure Impact**: Track metrics before/after adoption
5. **Gather Feedback**: Iterate based on developer experience

### For Development Teams

1. **Run Scans Locally**: Use `conftest` before committing
2. **Fix Critical First**: Prioritize by severity
3. **Update Dependencies**: Keep packages current
4. **Use Templates**: Leverage secure baseline templates
5. **Request Exemptions**: When fixes aren't possible

### For Security Teams

1. **Tune Policies**: Balance security with productivity
2. **Document Rationale**: Explain why policies exist
3. **Provide Remediation**: Give clear fix guidance
4. **Monitor Trends**: Track security posture over time
5. **Celebrate Wins**: Recognize teams improving security

## Troubleshooting

### Common Issues

**Issue**: Too many false positives
**Solution**: Add exemptions in `.security-plane/exemptions.yaml`

**Issue**: Scans taking too long
**Solution**: Use `.trivyignore`, cache scan databases

**Issue**: Policy blocking valid code
**Solution**: Customize policy or request exemption

**Issue**: SBOM generation fails
**Solution**: Ensure package manifests exist, try different format

## References

- [OPA Documentation](https://www.openpolicyagent.org/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/)
- [Syft Documentation](https://github.com/anchore/syft)
- [Gitleaks Documentation](https://github.com/gitleaks/gitleaks)
- [SLSA Framework](https://slsa.dev/)
- [NIST SSDF](https://csrc.nist.gov/Projects/ssdf)

## Support

- 📖 Documentation: `docs/security-plane/`
- 💬 Slack: #fawkes-security
- 🐛 Issues: https://github.com/paruff/fawkes/issues
- 📧 Email: security-team@example.com

---

*Last Updated: 2024-01-26*  
*Version: 1.0.0*
