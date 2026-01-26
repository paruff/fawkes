# Security Documentation

This section covers security features, policies, and best practices for the Fawkes platform.

## Security Plane

The Fawkes Security Plane provides comprehensive security capabilities including SBOM generation, image signing, and policy enforcement.

- [Security Plane Reference Architecture](../security-plane/reference-architecture.md) - Complete security architecture
- [Security Plane Quick Start](../security-plane/quick-start.md) - Get started with security features
- [Security Plane Implementation Summary](../security-plane/IMPLEMENTATION_SUMMARY.md) - Technical implementation details
- [Adoption Patterns](../security-plane/adoption-patterns.md) - How to adopt security practices

## Security Features

### Policy Enforcement

- [Policy as Code Tiers](../explanation/governance/policy-as-code-tiers.md) - Understanding policy enforcement
- [Kyverno Policy List](../reference/policies/kyverno-policy-list.md) - Available Kubernetes policies
- [Troubleshoot Kyverno Violations](../how-to/policy/troubleshoot-kyverno-violation.md) - Debug policy issues

### Zero Trust Security

- [Zero Trust Model](../explanation/security/zero-trust-model.md) - Understanding zero trust architecture
- [Shift Left on Security Pattern](../patterns/security.md) - Early security testing

### Secrets Management

- [Consume Vault Secrets Tutorial](../tutorials/3-consume-vault-secret.md) - Using secrets in applications
- [Rotate Vault Secrets](../how-to/security/rotate-vault-secrets.md) - Secret rotation procedures

### Security Scanning

- [Quality Gates Configuration](../how-to/security/quality-gates-configuration.md) - Configure security gates
- [Trivy Scan Analysis](TRIVY_SCAN_ANALYSIS.md) - Container vulnerability scanning
- [GitHub Actions Security Improvements](../github-actions-security-improvements.md) - Secure CI/CD pipelines

## Implementation References

- [AT-E1-006 Validation Coverage](../AT-E1-006-VALIDATION-COVERAGE.md) - Security validation testing

## Related Documentation

- [Security Best Practices](../security.md) - General security guidelines
- [How-To Guides](../how-to/index.md) - Step-by-step security guides
- [Reference Documentation](../reference/index.md) - Security API and configuration
- [Patterns](../patterns/index.md) - Security patterns and practices
