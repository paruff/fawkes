# ADR-014: SonarQube for Code Quality and Security Gates

## Status
**Accepted** - November 30, 2025

## Context

Fawkes platform requires a centralized code quality and security analysis solution integrated into the Golden Path CI/CD pipeline. Currently, code quality review and security vulnerability checks are inconsistent, often relying on manual review or isolated scanning tools that do not enforce pass/fail criteria. There is no central dashboard to track the Quality Debt or security status across all platform repositories.

### Requirements

**Functional Requirements**:
- Static Application Security Testing (SAST)
- Code quality metrics and technical debt tracking
- Security vulnerability detection
- Code coverage analysis
- Duplicate code detection
- Quality Gate enforcement in CI/CD pipelines
- Multi-language support (Java, Python, Node.js, Go)
- Branch-based analysis for PR reviews

**Non-Functional Requirements**:
- Fast feedback (< 5 minutes for analysis)
- Scalable to 50+ repositories
- SSO/OAuth integration for developer access
- Secure token-based CI/CD integration
- Persistent data storage with PostgreSQL
- High availability for production use

**Integration Requirements**:
- Jenkins pipeline integration via scanner token
- GitHub repository linking
- ArgoCD deployment management
- Prometheus metrics export
- Developer portal (Backstage) integration

### Forces at Play

**Technical Forces**:
- Need comprehensive language support
- Must integrate seamlessly with Jenkins pipelines
- Require fast, accurate analysis without blocking development

**Operational Forces**:
- Platform team capacity for maintenance
- Need for simple deployment and upgrades
- Backup and disaster recovery requirements

**Developer Experience Forces**:
- Clear, actionable feedback in CI/CD
- Easy access to detailed analysis reports
- Minimal friction in development workflow

## Decision

**We will deploy SonarQube as the centralized code quality and security analysis platform for Fawkes.**

Specifically:
- **SonarQube 10.7+ (Community Edition)** as the analysis engine
- **CloudNativePG PostgreSQL** for persistent data storage
- **Jenkins Shared Library** integration for scanner execution and Quality Gate enforcement
- **NGINX Ingress** for external access with SSO integration
- **Mandatory Quality Gate** enforcement on main branch commits
- **PR branch analysis** for early feedback

### Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     Developer Workflow                           │
│                                                                   │
│  Git Commit → Jenkins Pipeline → SonarQube Analysis → Quality Gate
└─────────────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                     SonarQube Platform                           │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │   Web UI     │  │   Compute    │  │   Search     │          │
│  │   (Java)     │  │   Engine     │  │   (ES)       │          │
│  └──────────────┘  └──────────────┘  └──────────────┘          │
│                           │                                      │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                    PostgreSQL                             │  │
│  │              (db-sonarqube-dev cluster)                   │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

### Quality Gate Strategy

**Default Quality Gate Conditions**:
| Metric | Operator | Threshold | Rationale |
|--------|----------|-----------|-----------|
| New Bugs | Is Greater Than | 0 | Prevent bug introduction |
| New Vulnerabilities | Is Greater Than | 0 | Security-first approach |
| New Security Hotspots Reviewed | Is Less Than | 100% | Ensure security review |
| New Code Coverage | Is Less Than | 80% | Maintain test coverage |
| New Duplicated Lines (%) | Is Greater Than | 3% | Limit code duplication |
| New Maintainability Rating | Is Worse Than | A | Quality standards |

**Quality Gate Enforcement**:
1. Main branch commits MUST pass Quality Gate before image push
2. PR builds report Quality Gate status but don't block (informational)
3. Pipeline fails immediately on Quality Gate failure with detailed logs
4. Direct link to SonarQube dashboard provided in build output

### Rationale

1. **Industry Standard**: SonarQube is the most widely adopted code quality platform with over 400K organizations using it

2. **Comprehensive Analysis**:
   - 27+ programming languages supported
   - 5000+ rules for bug, vulnerability, and code smell detection
   - Security hotspot identification
   - Coverage integration

3. **Quality Gate Enforcement**:
   - Automated pass/fail criteria
   - Configurable thresholds
   - Webhook integration for CI/CD

4. **Developer Experience**:
   - Clear, actionable feedback
   - IDE plugins (SonarLint) for local feedback
   - Detailed remediation guidance

5. **Open Source**:
   - Community Edition is free
   - Large community and ecosystem
   - Regular updates and security patches

6. **Cloud-Native Ready**:
   - Kubernetes-ready Helm chart
   - External PostgreSQL support
   - Prometheus metrics integration

## Consequences

### Positive

✅ **Centralized Quality Dashboard**: Single pane of glass for all code quality metrics

✅ **Consistent Standards**: Same quality rules enforced across all repositories

✅ **Security Shift-Left**: Vulnerabilities caught early in development

✅ **Developer Feedback**: Clear, actionable guidance on code improvements

✅ **Technical Debt Tracking**: Visibility into accumulated technical debt

✅ **Integration with CI/CD**: Automated enforcement in Golden Path pipeline

✅ **Multi-Language Support**: Java, Python, Node.js, Go, and more

### Negative

⚠️ **Resource Requirements**: SonarQube requires significant memory (2-4GB minimum)

⚠️ **Initial Configuration**: Requires setup of projects, quality profiles, and gates

⚠️ **Analysis Time**: Large projects may take several minutes to analyze

⚠️ **False Positives**: Some rules may flag non-issues requiring suppression

⚠️ **Learning Curve**: Developers need to understand SonarQube feedback

### Neutral

◽ **Community vs. Developer Edition**: Some features (branch analysis depth, security reports) require paid edition

◽ **Maintenance**: Requires periodic updates and database maintenance

◽ **Storage Growth**: Analysis history grows over time

### Mitigation Strategies

1. **Resource Management**:
   - Right-size Kubernetes resources
   - Configure housekeeping to clean old analysis data
   - Use separate PostgreSQL cluster for isolation

2. **Analysis Performance**:
   - Enable incremental analysis where supported
   - Configure appropriate exclusions
   - Run analysis in parallel with other pipeline stages

3. **False Positives**:
   - Create custom quality profiles
   - Use inline comments for legitimate suppressions
   - Regular review of flagged issues

4. **Developer Adoption**:
   - Provide SonarLint IDE plugin guidance
   - Document common issues and resolutions
   - Include SonarQube links in build notifications

## Alternatives Considered

### Alternative 1: Snyk

**Pros**:
- Strong security focus
- SaaS offering (less maintenance)
- Good dependency scanning

**Cons**:
- Limited code quality analysis
- No quality gate enforcement
- Primarily security-focused

**Reason for Rejection**: Snyk excellent for security but lacks comprehensive code quality analysis. SonarQube provides both security and quality in one platform.

### Alternative 2: CodeClimate

**Pros**:
- Clean UI
- Quality focus
- Good maintainability scores

**Cons**:
- Limited security features
- Fewer language support
- SaaS-only (no self-hosted)

**Reason for Rejection**: CodeClimate strong on quality but weak on security. Self-hosted option important for enterprise deployments.

### Alternative 3: Codacy

**Pros**:
- Multi-language support
- Security patterns
- SaaS and self-hosted options

**Cons**:
- Less mature than SonarQube
- Smaller community
- Limited enterprise features

**Reason for Rejection**: Codacy capable but SonarQube has larger community, more rules, and better Jenkins integration.

### Alternative 4: GitHub Advanced Security

**Pros**:
- Native GitHub integration
- Code scanning and secret scanning
- Dependency review

**Cons**:
- Expensive ($49/user/month)
- Limited to GitHub repositories
- Less comprehensive quality analysis

**Reason for Rejection**: GitHub Advanced Security powerful but expensive and limited to GitHub. SonarQube works with any Git provider.

## Related Decisions

- **ADR-004**: Jenkins for CI/CD (provides pipeline integration)
- **ADR-006**: PostgreSQL for Data Persistence (provides database backend)
- **ADR-009**: Secrets Management (SonarQube token storage)

## Implementation Notes

### Deployment Configuration

**SonarQube ArgoCD Application**:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sonarqube
  namespace: fawkes
spec:
  source:
    repoURL: https://charts.sonarsource.com
    chart: sonarqube
    targetRevision: "2025.1.0"
    helm:
      values: |
        jdbcOverwrite:
          enable: true
          jdbcUrl: "jdbc:postgresql://db-sonarqube-dev-rw.fawkes.svc:5432/sonarqube"
```

**Jenkins Credentials Configuration**:
```yaml
credentials:
  - id: sonarqube-token
    type: secretText
    secret: ${SONARQUBE_TOKEN}
    description: "SonarQube Scanner Token"
```

### Quality Gate Enforcement in Pipeline

```groovy
stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            def qg = waitForQualityGate()
            if (qg.status != 'OK') {
                error "Quality Gate failed: ${qg.status}"
            }
        }
    }
}
```

### Initial Setup Checklist

1. [ ] Deploy PostgreSQL cluster (db-sonarqube-dev)
2. [ ] Deploy SonarQube via ArgoCD
3. [ ] Configure admin password and SSO
4. [ ] Create scanner token for Jenkins
5. [ ] Add token to Jenkins credentials
6. [ ] Configure SonarQube server in Jenkins
7. [ ] Create default Quality Gate
8. [ ] Create language-specific quality profiles
9. [ ] Document developer onboarding

### Monitoring

**Prometheus Metrics**:
- `sonarqube_health_status`
- `sonarqube_compute_engine_tasks`
- `sonarqube_database_connections`

**Key Alerts**:
- SonarQube unhealthy
- Analysis queue growing
- Database connection issues

## Monitoring This Decision

We will revisit this ADR if:
- Analysis time consistently exceeds 5 minutes
- False positive rate becomes problematic
- Community Edition features are insufficient
- Alternative tools provide better value

**Next Review Date**: May 30, 2026 (6 months)

## References

- [SonarQube Documentation](https://docs.sonarqube.org/)
- [SonarQube Helm Chart](https://artifacthub.io/packages/helm/sonarqube/sonarqube)
- [Quality Gates Documentation](https://docs.sonarqube.org/latest/user-guide/quality-gates/)
- [Jenkins SonarQube Plugin](https://plugins.jenkins.io/sonar/)
- [Fawkes Jenkins Shared Library](../jenkins-shared-library/)

---

**Decision Made By**: Platform Architecture Team
**Approved By**: Project Lead
**Date**: November 30, 2025
**Author**: Fawkes Platform Team
**Last Updated**: November 30, 2025
