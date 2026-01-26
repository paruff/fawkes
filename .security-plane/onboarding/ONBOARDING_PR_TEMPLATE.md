---
name: Security Plane Onboarding PR
about: Template for onboarding a repository to the Fawkes Security Plane
title: '[SECURITY] Onboard to Fawkes Security Plane'
labels: security, enhancement
---

## 🔒 Security Plane Onboarding

This PR onboards the repository to the **Fawkes Security Plane**, enabling automated security scanning, SBOM generation, image signing, and policy enforcement.

## What's Included

### ✅ Security Workflows
- [x] Reusable security scanning workflow
- [x] SBOM generation with Syft
- [x] Image signing with Cosign
- [x] Policy enforcement with OPA/Conftest

### 📋 Policy Files
- [x] Kubernetes security policies
- [x] Dockerfile best practices
- [x] Supply chain security policies

### 📚 Documentation
- [x] Onboarding guide
- [x] Security baseline templates
- [x] Remediation guidance

## Adoption Mode

This PR configures the security plane in **{{ ADOPTION_MODE }}** mode:

- [ ] **Advisory** - Scans run but don't block (recommended for initial adoption)
- [ ] **Progressive** - Block only critical vulnerabilities
- [ ] **Strict** - Full enforcement with blocking

## Changes Made

- Added `.security-plane/` directory with policies and templates
- Added `.github/workflows/security.yml` workflow
- Updated `.gitignore` to exclude security scan artifacts
- Added security badges to README

## Testing Performed

- [ ] Local policy testing with Conftest
- [ ] Workflow validation in test branch
- [ ] Security scan completed successfully
- [ ] No blocking issues found (or documented exemptions)

## Security Scan Results

### Summary
- **Secrets**: No hardcoded secrets found ✅
- **Vulnerabilities**: X critical, Y high, Z medium
- **Policy Violations**: X blocking, Y warnings
- **SBOM**: Generated successfully ✅

### Critical Issues to Address
<!-- List any critical vulnerabilities or policy violations that need attention -->

1. Issue 1
2. Issue 2

## Configuration

```yaml
# Security workflow configuration
enforcement-mode: {{ ENFORCEMENT_MODE }}
fail-on-critical: {{ FAIL_ON_CRITICAL }}
severity-threshold: {{ SEVERITY_THRESHOLD }}
```

## Rollout Plan

### Phase 1: Advisory Mode (Week 1-2)
- Run scans in advisory mode
- Identify and catalog existing issues
- No blocking enforcement

### Phase 2: Fix Critical Issues (Week 3-4)
- Address all CRITICAL vulnerabilities
- Fix blocking policy violations
- Update dependencies

### Phase 3: Progressive Enforcement (Week 5-6)
- Enable blocking for CRITICAL vulnerabilities
- Monitor for new issues
- Train team on security practices

### Phase 4: Strict Mode (Week 7+)
- Full enforcement enabled
- All policies blocking
- Continuous monitoring

## Team Action Items

- [ ] Review onboarding documentation: `.security-plane/onboarding/ONBOARDING.md`
- [ ] Set up local security scanning tools
- [ ] Review and acknowledge security policies
- [ ] Assign security champion for the team
- [ ] Schedule security training session

## Breaking Changes

⚠️ **None** - Security plane runs in advisory mode by default and won't block existing workflows.

## Exemptions Requested

<!-- List any security findings that need exemptions with justification -->

None at this time.

## Documentation

- Onboarding guide: `.security-plane/onboarding/ONBOARDING.md`
- Security policies: `.security-plane/policies/`
- Secure templates: `.security-plane/templates/`

## Checklist

- [ ] Security workflows added and tested
- [ ] Policies reviewed and customized for repo needs
- [ ] Documentation reviewed
- [ ] Team notified and trained
- [ ] Security champion assigned
- [ ] Initial security scan completed
- [ ] Critical issues addressed or exempted
- [ ] README updated with security badges

## Next Steps

After merging:
1. Monitor security scan results in GitHub Actions
2. Review GitHub Security tab for detailed findings
3. Address critical and high-severity issues
4. Schedule regular security reviews
5. Progress toward stricter enforcement modes

## Questions?

- 📖 Full documentation: `docs/security-plane/`
- 💬 Slack: #fawkes-security
- 🐛 Issues: https://github.com/paruff/fawkes/issues
- 📧 Email: security-team@example.com

---

/cc @security-team @platform-team
