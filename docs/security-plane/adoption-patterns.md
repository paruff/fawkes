# Security Plane Adoption Patterns

## Overview

The Fawkes Security Plane supports three distinct adoption patterns, each suited to different organizational maturity levels and risk tolerances.

## Pattern 1: Advisory Mode 🟢

### When to Use
- **Initial adoption** - First time enabling security plane
- **Discovery phase** - Understanding current security posture
- **Low-risk applications** - Development or testing environments
- **New teams** - Teams unfamiliar with security tooling

### Configuration

```yaml
name: Security Checks

on: [push, pull_request]

jobs:
  security:
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: advisory
      fail-on-critical: false
      severity-threshold: MEDIUM
      enable-signing: false
      enable-sbom: true
```

### Behavior

| Check | Result | PR Impact |
|-------|--------|-----------|
| Secret found | ⚠️ Warning logged | ✅ PR allowed |
| CRITICAL vulnerability | ⚠️ Warning logged | ✅ PR allowed |
| Policy violation | ⚠️ Warning logged | ✅ PR allowed |
| SBOM generation | ✅ Generated | ✅ PR allowed |

### Benefits
- ✅ Non-disruptive - doesn't block development
- ✅ Visibility - see all issues
- ✅ Learning - understand security landscape
- ✅ Baseline - establish metrics

### Drawbacks
- ❌ No enforcement - issues can slip through
- ❌ Requires discipline - teams must act on findings
- ❌ Technical debt - can accumulate issues

### Timeline
**Duration**: 1-2 weeks

**Success Criteria**:
- All teams understand scan results
- Critical issues are cataloged
- Teams trained on remediation
- Ready to move to progressive mode

## Pattern 2: Progressive Enforcement 🟡

### When to Use
- **After advisory mode** - Baseline established
- **Gradual improvement** - Fixing critical issues first
- **Medium-risk applications** - Staging environments
- **Production-bound services** - Pre-production hardening

### Configuration

```yaml
name: Security Checks

on: [push, pull_request]

jobs:
  security:
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: strict
      fail-on-critical: true
      severity-threshold: CRITICAL
      enable-signing: false
      enable-sbom: true
```

### Behavior

| Check | Result | PR Impact |
|-------|--------|-----------|
| Secret found | ❌ PR blocked | ❌ Cannot merge |
| CRITICAL vulnerability | ❌ PR blocked | ❌ Cannot merge |
| HIGH vulnerability | ⚠️ Warning logged | ✅ PR allowed |
| Policy violation | ⚠️ Warning logged | ✅ PR allowed |
| SBOM generation | ✅ Generated | ✅ PR allowed |

### Benefits
- ✅ Balanced approach - security + velocity
- ✅ Clear priorities - focus on critical first
- ✅ Gradual hardening - improve over time
- ✅ Team buy-in - not overwhelming

### Drawbacks
- ⚠️ Some issues slip through - HIGH/MEDIUM not blocked
- ⚠️ Requires monitoring - track non-blocking issues
- ⚠️ Time investment - fixing critical takes time

### Timeline
**Duration**: 2-4 weeks after advisory

**Success Criteria**:
- Zero CRITICAL vulnerabilities
- No secrets in codebase
- SBOMs for all services
- Ready for strict mode

## Pattern 3: Strict Mode 🔴

### When to Use
- **Production services** - Customer-facing applications
- **Compliance requirements** - SOC2, PCI-DSS, HIPAA
- **High-risk applications** - Financial, healthcare, government
- **Mature security posture** - After progressive enforcement

### Configuration

```yaml
name: Security Checks

on: [push, pull_request]

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

### Behavior

| Check | Result | PR Impact |
|-------|--------|-----------|
| Secret found | ❌ PR blocked | ❌ Cannot merge |
| CRITICAL/HIGH/MEDIUM vuln | ❌ PR blocked | ❌ Cannot merge |
| Policy violation | ❌ PR blocked | ❌ Cannot merge |
| Unsigned image (prod) | ❌ PR blocked | ❌ Cannot merge |
| Missing SBOM | ❌ PR blocked | ❌ Cannot merge |

### Benefits
- ✅ Maximum security - all issues blocked
- ✅ Compliance ready - meets regulatory requirements
- ✅ Supply chain secured - signed images, SBOMs
- ✅ Audit trail - full visibility

### Drawbacks
- ⚠️ Slower velocity - more issues to fix
- ⚠️ Team friction - requires security mindset
- ⚠️ False positives - exemptions needed
- ⚠️ Maintenance overhead - policies need tuning

### Timeline
**Duration**: 4-8 weeks after progressive

**Success Criteria**:
- All services pass strict checks
- Images signed and verified
- Policies enforced and documented
- Zero unmitigated vulnerabilities

## Migration Path

### Week 1-2: Advisory Mode
```
Deploy → Scan → Learn → Catalog
```
- Enable security workflows
- Run scans on all repos
- Catalog all findings
- Train teams on tools

### Week 3-4: Fix Critical
```
Prioritize → Fix → Verify → Document
```
- Address CRITICAL vulnerabilities
- Fix secret leaks
- Update dependencies
- Document exemptions

### Week 5-6: Progressive Enforcement
```
Enable → Monitor → Fix → Iterate
```
- Turn on critical blocking
- Monitor non-blocking issues
- Gradual fixing of HIGH/MEDIUM
- Adjust thresholds

### Week 7-8: Strict Mode
```
Enforce → Sign → Verify → Maintain
```
- Full enforcement enabled
- Image signing required
- SBOM generation mandatory
- Continuous monitoring

## Customization Examples

### Start Strict for New Services

```yaml
# New service - no technical debt
with:
  enforcement-mode: strict
  fail-on-critical: true
  fail-on-violation: true
  severity-threshold: HIGH
```

### Advisory for Legacy Services

```yaml
# Legacy service - many issues
with:
  enforcement-mode: advisory
  fail-on-critical: false
  severity-threshold: CRITICAL
```

### Progressive for Refactoring

```yaml
# Service being modernized
with:
  enforcement-mode: strict
  fail-on-critical: true
  fail-on-violation: false  # Policies advisory
  severity-threshold: CRITICAL
```

### Production-Only Strict

```yaml
# Strict on main, advisory on branches
jobs:
  security:
    uses: paruff/fawkes/.github/workflows/security-plane-adoption.yml@main
    with:
      enforcement-mode: ${{ github.ref == 'refs/heads/main' && 'strict' || 'advisory' }}
      fail-on-critical: ${{ github.ref == 'refs/heads/main' }}
```

## Best Practices

### Do's ✅

1. **Start Advisory** - Always begin with advisory mode
2. **Communicate** - Tell teams about security plans
3. **Train First** - Educate before enforcing
4. **Set Timelines** - Clear deadlines for each phase
5. **Measure Progress** - Track metrics over time
6. **Celebrate Wins** - Recognize security improvements
7. **Document Exemptions** - Clear justifications
8. **Review Regularly** - Policies need updates

### Don'ts ❌

1. **Don't Start Strict** - Will overwhelm teams
2. **Don't Surprise Teams** - Communicate changes
3. **Don't Ignore Feedback** - Listen to developer pain
4. **Don't Set Unrealistic Timelines** - Allow time to fix
5. **Don't Block Without Help** - Provide remediation guidance
6. **Don't Forget Exemptions** - Some issues can't be fixed
7. **Don't Skip Training** - Teams need to understand tools
8. **Don't Set and Forget** - Policies evolve

## Metrics to Track

### Security Posture
- Number of secrets detected
- Vulnerability count by severity
- Policy violations by type
- % of images signed
- SBOM coverage

### Team Impact
- Mean time to remediation (MTTR)
- PR cycle time with security checks
- Number of exemptions requested
- Security training completion rate

### Adoption Progress
- % of repos in advisory mode
- % of repos in progressive mode
- % of repos in strict mode
- Time to move between modes

## Support & Resources

- 📖 [Onboarding Guide](.security-plane/onboarding/ONBOARDING.md)
- 🔧 [Troubleshooting](docs/security-plane/troubleshooting.md)
- 💬 Slack: #fawkes-security
- 🐛 Issues: https://github.com/paruff/fawkes/issues

---

*Choose the right pattern for your team's maturity level and risk tolerance.*
