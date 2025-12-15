# Security Quality Gates Configuration

## Overview

Fawkes platform enforces security quality gates at multiple stages in the CI/CD pipeline to prevent vulnerable code and images from being deployed. This document describes how quality gates are configured, their severity thresholds, and the override processes for legitimate exceptions.

## Quality Gate Types

### 1. SonarQube Quality Gates (SAST)

SonarQube performs Static Application Security Testing (SAST) on source code and enforces quality gates before code can proceed to the build stage.

#### Default Quality Gate Thresholds

| Metric | Operator | Threshold | Impact |
|--------|----------|-----------|--------|
| New Bugs | Is Greater Than | 0 | Pipeline fails |
| New Vulnerabilities | Is Greater Than | 0 | Pipeline fails |
| New Security Hotspots Reviewed | Is Less Than | 100% | Pipeline fails |
| New Code Coverage | Is Less Than | 80% | Pipeline fails |
| New Duplicated Lines (%) | Is Greater Than | 3% | Pipeline fails |
| New Maintainability Rating | Is Worse Than | A | Pipeline fails |

#### Configuration in Pipeline

The quality gate is automatically enforced in the Golden Path pipeline:

```groovy
@Library('fawkes-pipeline-library') _
goldenPathPipeline {
    appName = 'my-service'
    language = 'java'
    dockerImage = 'harbor.fawkes.local/fawkes/my-service'
    // SonarQube quality gate is automatically enforced
    // To skip security scanning entirely (not recommended):
    // runSecurityScan = false  // Requires approval!
}
```

#### Customizing SonarQube Quality Gates

To customize the quality gate for a specific project:

1. **Access SonarQube UI**:
   ```bash
   # Local development
   open http://sonarqube.127.0.0.1.nip.io
   
   # Production
   open https://sonarqube.fawkes.example.com
   ```

2. **Navigate to Quality Gates**:
   - Click **Quality Gates** in the top menu
   - Click **Create** to create a custom gate

3. **Define Conditions**:
   - Add conditions based on your requirements
   - Set thresholds for each metric
   - Save the quality gate

4. **Assign to Project**:
   - Go to your project
   - Click **Project Settings** → **Quality Gate**
   - Select your custom quality gate

#### Override Process for SonarQube

**When to Override**: Use overrides sparingly and only for:
- False positives confirmed by security team
- Known issues with documented mitigation
- Technical debt with approved remediation plan

**How to Override**:

1. **Inline Suppression** (Code-level):
   ```java
   // Java example
   @SuppressWarnings("java:S1234")  // Document reason!
   public void problematicMethod() {
       // Implementation
   }
   ```

   ```python
   # Python example
   def problematic_function():  # noqa: S102 - Reason documented in JIRA-123
       pass
   ```

2. **Project-level Exclusions** (sonar-project.properties):
   ```properties
   # Exclude third-party code
   sonar.exclusions=**/vendor/**,**/node_modules/**
   
   # Exclude generated code
   sonar.exclusions=**/generated/**
   ```

3. **Quality Gate Exception** (Requires approval):
   - Document the issue in a JIRA ticket
   - Get approval from Tech Lead and Security Team
   - Option: Disable entire security scanning stage:
     ```groovy
     goldenPathPipeline {
         appName = 'my-service'
         runSecurityScan = false  // Requires justification!
     }
     ```
   - Add detailed comment in Jenkinsfile explaining the exception
   - Schedule full security review for next sprint

**Note**: The `runSecurityScan = false` option disables the entire Security Scan stage, including SonarQube, Trivy, and secrets scanning. There is no way to disable only the SonarQube quality gate check. This is intentional - if you need to bypass quality gates, you must do so consciously for all security scanning.

**Exception Documentation Template**:
```groovy
// EXCEPTION: Security scanning disabled for hotfix deployment
// Reason: Critical production issue requires immediate fix
// Issue: JIRA-1234
// Approved by: tech-lead@example.com, security@example.com
// Remediation Plan: Full security scan scheduled for next sprint
// Expiration: 2024-12-31
goldenPathPipeline {
    appName = 'my-service'
    runSecurityScan = false  // Disables entire security scan stage
}
```

**Note**: The `runSecurityScan` flag disables the entire Security Scan stage, including SonarQube, Trivy, and secrets scanning. Use with extreme caution and only for approved emergency deployments.

### 2. Trivy Quality Gates (Container Scanning)

Trivy scans container images for vulnerabilities in OS packages and application dependencies, enforcing severity thresholds before images can be pushed to the registry.

#### Default Severity Thresholds

| Severity | Action | Rationale |
|----------|--------|-----------|
| CRITICAL | Pipeline fails | Immediate security risk |
| HIGH | Pipeline fails | Significant security risk |
| MEDIUM | Warning only | Monitor but allow |
| LOW | Warning only | Acceptable risk |

#### Configuration in Pipeline

Container scanning is automatically enabled in the Golden Path pipeline:

```groovy
@Library('fawkes-pipeline-library') _
goldenPathPipeline {
    appName = 'my-service'
    language = 'java'
    dockerImage = 'harbor.fawkes.local/fawkes/my-service'
    // Trivy scanning is automatically enabled
    trivySeverity = 'HIGH,CRITICAL'  // Default severity filter
    trivyExitCode = '1'              // Fail on vulnerabilities (default)
}
```

#### Customizing Trivy Severity Thresholds

**Option 1: Change Severity Filter** (Pipeline-level):

```groovy
goldenPathPipeline {
    appName = 'my-service'
    trivySeverity = 'CRITICAL'  // Only fail on CRITICAL
}
```

**Option 2: Disable Failure** (Emergency use only, requires approval):

```groovy
// URGENT: Relaxed container scanning for production hotfix
// Issue: INCIDENT-789
// Approved by: incident-commander@example.com, security@example.com
// Full scan required within 24 hours
goldenPathPipeline {
    appName = 'my-service'
    trivyExitCode = '0'  // Don't fail pipeline on vulnerabilities
}
```

#### Override Process for Trivy

**When to Override**: Use overrides only for:
- False positives (vulnerability doesn't apply to your use case)
- Vulnerabilities with no available fix yet
- Accepted risk with documented mitigation

**How to Override**:

1. **Create `.trivyignore` file** in repository root:

   ```text
   # .trivyignore
   # 
   # Format: CVE-ID [exp:YYYY-MM-DD] [# comment]
   #
   
   # Example 1: False positive - application doesn't use vulnerable code path
   CVE-2023-12345  # PostgreSQL CVE, but we use prepared statements exclusively
   
   # Example 2: No fix available yet, mitigation in place
   CVE-2023-67890 exp:2024-12-31  # WAF rules block exploit, vendor fix expected Q1 2024
   
   # Example 3: Vendor confirmed not vulnerable
   CVE-2023-11111  # Alpine maintainers confirmed package version not affected
   ```

2. **Document in Security Log**:
   
   Create or update `SECURITY.md` in your repository:
   
   ```markdown
   # Security Exceptions
   
   ## Trivy Scan Overrides
   
   ### CVE-2023-12345 (PostgreSQL SQL Injection)
   - **Severity**: HIGH
   - **Affected Package**: postgresql@13.2
   - **Status**: False Positive
   - **Justification**: Application exclusively uses prepared statements and parameterized queries. Code review confirmed no dynamic SQL construction.
   - **Approved By**: security-team@example.com
   - **Review Date**: 2024-11-15
   - **Next Review**: 2024-12-15
   ```

3. **Temporary Override for Hotfixes**:

   For urgent deployments, you can temporarily lower the threshold:
   
   ```groovy
   // URGENT HOTFIX: Relaxed security scanning for production incident
   // Issue: INCIDENT-456
   // Approved by: incident-commander@example.com
   // Full scan required within 24 hours
   goldenPathPipeline {
       appName = 'my-service'
       trivySeverity = 'CRITICAL'  // Only block on CRITICAL
   }
   ```

**Override Approval Process**:

1. **Identify vulnerability** requiring override
2. **Document justification** in JIRA ticket
3. **Get approval** from:
   - Security Team (required)
   - Technical Lead (required)
   - Product Owner (for production)
4. **Create `.trivyignore` entry** with expiration date
5. **Schedule remediation** before expiration
6. **Monitor** for fix availability

### 3. Secrets Scanning (Gitleaks)

Gitleaks scans for hardcoded secrets, API keys, and credentials in the codebase.

#### Default Behavior

- **Action**: Pipeline fails immediately if secrets detected
- **Threshold**: Zero tolerance for secrets in code
- **Configuration**: Automatic, no configuration needed

#### Override Process for Secrets Scanning

**When to Override**: Very rare, only for:
- False positives (pattern matches but not actual secret)
- Test data with no sensitive value
- Public keys or non-sensitive tokens

**How to Override**:

1. **Create or update `.gitleaks.toml`**:

   ```toml
   # .gitleaks.toml
   
   [allowlist]
   description = "Allowlist for false positives"
   
   # Allow specific pattern
   regexes = [
       "EXAMPLE_NOT_REAL_KEY",  # Test fixtures
   ]
   
   # Allow specific file paths
   paths = [
       "tests/fixtures/test-data.json",
       "docs/examples/",
   ]
   
   # Allow specific commits (use sparingly!)
   commits = [
       "abc123def456",  # Migration commit with dummy data
   ]
   ```

2. **Document in Repository**:

   ```markdown
   # .gitleaks-exceptions.md
   
   ## Gitleaks Allowlist Exceptions
   
   ### tests/fixtures/test-data.json
   - **Pattern**: JWT token pattern
   - **Reason**: Test fixture with non-functional token
   - **Approved By**: security-team@example.com
   - **Date**: 2024-11-01
   ```

**IMPORTANT**: Never disable secrets scanning entirely. If you absolutely must bypass it temporarily for an emergency (not recommended):

```groovy
// EMERGENCY ONLY - Never use in normal circumstances
// Issue: INCIDENT-999
// Approved by: CTO, CISO, Incident Commander
// Temporary bypass for critical production fix
// Full security review required within 2 hours
goldenPathPipeline {
    appName = 'my-service'
    runSecurityScan = false  // Disables ALL security scans including secrets
}
```

**Note**: This disables the entire security scan stage. There is no way to disable only secrets scanning while keeping other security checks. This is by design to prevent accidental security lapses.

## Multi-Gate Enforcement Strategy

The Fawkes platform uses defense-in-depth with multiple quality gates:

```
┌─────────────────────────────────────────────────────────────┐
│                    CI/CD Pipeline Flow                       │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────┐
         │  1. Secrets Scan (Gitleaks)      │
         │     Threshold: Zero tolerance    │
         └─────────────────────────────────┘
                           │
                           ▼ PASS
         ┌─────────────────────────────────┐
         │  2. SonarQube SAST Analysis      │
         │     Threshold: Zero new vulns    │
         └─────────────────────────────────┘
                           │
                           ▼ PASS
         ┌─────────────────────────────────┐
         │  3. Build Docker Image           │
         └─────────────────────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────┐
         │  4. Trivy Container Scan         │
         │     Threshold: HIGH,CRITICAL     │
         └─────────────────────────────────┘
                           │
                           ▼ PASS
         ┌─────────────────────────────────┐
         │  5. Push to Harbor Registry      │
         └─────────────────────────────────┘
                           │
                           ▼
         ┌─────────────────────────────────┐
         │  6. Harbor Re-scan (Trivy)       │
         │     Double verification          │
         └─────────────────────────────────┘
                           │
                           ▼ PASS
         ┌─────────────────────────────────┐
         │  7. Deploy via ArgoCD            │
         └─────────────────────────────────┘
```

### Gate Failure Handling

**When a gate fails**:

1. **Pipeline stops immediately** at the failing stage
2. **Notification sent** to team via Mattermost
3. **Detailed report** available in Jenkins artifacts
4. **SonarQube/Harbor link** provided for analysis
5. **Metrics recorded** for DORA change failure rate

**Developer workflow**:

1. Review failure details in Jenkins build log
2. Access detailed report (SonarQube UI or Trivy JSON)
3. Fix the identified issues
4. Commit and push changes
5. Pipeline re-runs automatically

## Language-Specific Examples

### Java Example

```groovy
// Jenkinsfile
@Library('fawkes-pipeline-library') _
goldenPathPipeline {
    appName = 'user-service'
    language = 'java'
    dockerImage = 'harbor.fawkes.local/fawkes/user-service'
    sonarProject = 'user-service'
    
    // Quality gates (using defaults)
    // trivySeverity = 'HIGH,CRITICAL'  // default
    // trivyExitCode = '1'               // default
    // runSecurityScan = true            // default
}
```

**SonarQube configuration** (pom.xml):
```xml
<properties>
    <sonar.host.url>http://sonarqube.fawkes.svc:9000</sonar.host.url>
    <sonar.projectKey>user-service</sonar.projectKey>
    <sonar.coverage.jacoco.xmlReportPaths>target/site/jacoco/jacoco.xml</sonar.coverage.jacoco.xmlReportPaths>
</properties>
```

### Python Example

```groovy
// Jenkinsfile
@Library('fawkes-pipeline-library') _
goldenPathPipeline {
    appName = 'analytics-api'
    language = 'python'
    dockerImage = 'harbor.fawkes.local/fawkes/analytics-api'
    
    // Quality gates use defaults
    // trivySeverity = 'HIGH,CRITICAL'
}
```

**SonarQube configuration** (sonar-project.properties):
```properties
sonar.projectKey=analytics-api
sonar.sources=src
sonar.tests=tests
sonar.python.coverage.reportPaths=coverage.xml
sonar.python.version=3.11
```

### Node.js Example

```groovy
// Jenkinsfile
@Library('fawkes-pipeline-library') _
goldenPathPipeline {
    appName = 'web-frontend'
    language = 'node'
    dockerImage = 'harbor.fawkes.local/fawkes/web-frontend'
    
    // All quality gates enabled by default
}
```

**SonarQube configuration** (sonar-project.js):
```javascript
module.exports = {
  sonar: {
    projectKey: 'web-frontend',
    sources: 'src',
    tests: 'tests',
    javascript: {
      lcov: {
        reportPaths: 'coverage/lcov.info'
      }
    }
  }
};
```

### Go Example

```groovy
// Jenkinsfile
@Library('fawkes-pipeline-library') _
goldenPathPipeline {
    appName = 'event-processor'
    language = 'go'
    dockerImage = 'harbor.fawkes.local/fawkes/event-processor'
    
    // Quality gates enabled by default
}
```

**SonarQube configuration** (sonar-project.properties):
```properties
sonar.projectKey=event-processor
sonar.sources=.
sonar.tests=.
sonar.test.inclusions=**/*_test.go
sonar.go.coverage.reportPaths=coverage.out
```

## Common Failure Scenarios and Remediation

### Scenario 1: SonarQube Detects New Vulnerability

**Error Message**:
```
❌ QUALITY GATE FAILED: FAILED
The code changes did not meet the quality criteria.
Please review the SonarQube analysis for details:
http://sonarqube.fawkes.svc:9000/dashboard?id=my-service&branch=main

Common failure reasons:
- New bugs or vulnerabilities introduced
- Code coverage dropped below threshold
```

**Remediation**:
1. Click the SonarQube link in the build log
2. Review **New Code** tab for introduced issues
3. Fix the identified security vulnerability
4. Ensure tests cover the fix
5. Commit and push

### Scenario 2: Trivy Finds Critical CVE

**Error Message**:
```
Total: 3 (HIGH: 2, CRITICAL: 1)
┌───────────────┬────────────────┬──────────┬───────────────────┐
│   Library     │ Vulnerability  │ Severity │   Fixed Version   │
├───────────────┼────────────────┼──────────┼───────────────────┤
│ openssl       │ CVE-2023-12345 │ CRITICAL │ 3.0.10            │
│ libxml2       │ CVE-2023-67890 │ HIGH     │ 2.11.4            │
└───────────────┴────────────────┴──────────┴───────────────────┘
```

**Remediation**:

**Option A: Update Base Image**:
```dockerfile
# Before
FROM python:3.11-alpine

# After (updated base image with patches)
FROM python:3.11-alpine3.19
```

**Option B: Update Dependencies**:
```dockerfile
# Add explicit update in Dockerfile
RUN apk add --no-cache --upgrade openssl libxml2
```

**Option C: Override (if no fix available)**:
Create `.trivyignore`:
```text
CVE-2023-12345 exp:2024-12-31  # Vendor fix expected Q1 2024, WAF mitigation in place
```

### Scenario 3: Secrets Detected

**Error Message**:
```
❌ SECRETS DETECTED IN CODE
Gitleaks has detected potential secrets in your code.

Common secrets detected:
- API keys and tokens
- Passwords and credentials
```

**Remediation**:
1. **Remove the secret** from code
2. **Use environment variables** or Vault
3. **Rotate the secret** if it was committed
4. **Update** `.gitleaks.toml` if false positive

```bash
# Remove from history if committed
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch path/to/file" \
  --prune-empty --tag-name-filter cat -- --all
```

## Monitoring and Metrics

### DORA Metrics Impact

Quality gates affect DORA metrics:

- **Deployment Frequency**: Gates may slow initial deployment but improve over time
- **Lead Time for Changes**: Includes time to fix gate failures
- **Change Failure Rate**: Reduced by catching issues early
- **Time to Restore**: Faster recovery with higher quality code

### Quality Gate Metrics

Monitor quality gate performance in Grafana:

- **Gate Pass Rate**: Percentage of builds passing each gate
- **Average Fix Time**: Time to remediate gate failures
- **Override Rate**: Frequency of overrides (should be < 1%)
- **Top Failures**: Most common issues by type

**Grafana Dashboard**: Security → Quality Gates Overview

## Best Practices

### DO ✅

- **Fix issues immediately** when gates fail
- **Use inline suppressions** with clear comments
- **Document all overrides** with justification
- **Set expiration dates** on temporary exceptions
- **Review overrides regularly** (monthly recommended)
- **Monitor gate metrics** to identify patterns
- **Train team** on common issues and remediation

### DON'T ❌

- **Don't disable gates** without approval
- **Don't leave overrides indefinitely** 
- **Don't ignore MEDIUM/LOW** findings entirely
- **Don't commit secrets** even temporarily
- **Don't use same override** across multiple projects
- **Don't skip gate reviews** in retrospectives

## Getting Help

### Resources

- **SonarQube Documentation**: [Quality Gates](https://docs.sonarqube.org/latest/user-guide/quality-gates/)
- **Trivy Documentation**: [Vulnerability Scanning](https://aquasecurity.github.io/trivy/)
- **Gitleaks Documentation**: [Configuration](https://github.com/gitleaks/gitleaks)
- **Architecture**: [ADR-014 SonarQube Quality Gates](../../adr/ADR-014%20sonarqube%20quality%20gates.md)

### Support

For questions or assistance:

1. **Check docs**: [Security Documentation](../security/)
2. **Search examples**: Review other services in the monorepo
3. **Ask team**: #security-help channel in Mattermost
4. **Open ticket**: For policy exceptions or clarifications

### Approval Contacts

- **Security Team**: security-team@example.com
- **Technical Leads**: tech-leads@example.com
- **Platform Team**: platform-team@example.com

## Related Documentation

- [SonarQube Integration](../../../platform/apps/sonarqube/README.md)
- [Trivy Container Scanning](../../../platform/apps/trivy/README.md)
- [Secrets Management](./secrets-management.md)
- [Golden Path Pipeline Usage](../../golden-path-usage.md)
- [Jenkins Configuration as Code](../jenkins-casc-configuration.md)

---

**Maintained by**: Fawkes Platform Team  
**Last Updated**: December 2024  
**Related Issues**: #19 (SonarQube), #20 (Trivy), #21 (Secrets), #22 (Quality Gates)
