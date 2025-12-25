# SonarQube - Code Quality and Security Analysis

## Purpose

SonarQube provides continuous inspection of code quality and security. It performs static analysis to detect bugs, code smells, and security vulnerabilities, enforcing quality gates in the CI/CD pipeline.

## Key Features

- **Static Analysis (SAST)**: Security vulnerability detection
- **Code Quality**: Technical debt and code smell tracking
- **Quality Gates**: Automated pass/fail criteria
- **Multi-Language**: Java, Python, JavaScript, Go, and more
- **PR Decoration**: Inline comments on pull requests
- **Historical Tracking**: Quality metrics over time

## Quick Start

### Accessing SonarQube

Local development:

```bash
# Access UI
http://sonarqube.127.0.0.1.nip.io
```

Default credentials:

- Username: `admin`
- Password: `admin` (change on first login!)

## Integration with Jenkins

SonarQube is integrated into the Golden Path pipeline:

```groovy
stage('Code Quality') {
    steps {
        withSonarQubeEnv('SonarQube') {
            sh 'mvn sonar:sonar'
        }
    }
}

stage('Quality Gate') {
    steps {
        timeout(time: 5, unit: 'MINUTES') {
            waitForQualityGate abortPipeline: true
        }
    }
}
```

## Quality Gate

The default quality gate requires:

- **New Bugs**: 0
- **New Vulnerabilities**: 0
- **Security Hotspots Reviewed**: 100%
- **New Code Coverage**: ≥ 80%
- **Duplicated Lines**: ≤ 3%
- **Maintainability Rating**: A

## Analysis Configuration

### Maven Projects

```xml
<!-- pom.xml -->
<properties>
    <sonar.host.url>http://sonarqube.fawkes.svc:9000</sonar.host.url>
    <sonar.projectKey>my-service</sonar.projectKey>
</properties>
```

```bash
mvn clean verify sonar:sonar
```

### Python Projects

```bash
# Install scanner
pip install sonar-scanner

# Run analysis
sonar-scanner \
  -Dsonar.projectKey=my-service \
  -Dsonar.sources=. \
  -Dsonar.host.url=http://sonarqube.fawkes.svc:9000 \
  -Dsonar.login=${SONAR_TOKEN}
```

### JavaScript/TypeScript

```bash
# Using sonar-scanner
npm install -g sonar-scanner

sonar-scanner \
  -Dsonar.projectKey=my-service \
  -Dsonar.sources=src \
  -Dsonar.tests=tests \
  -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info
```

## Security Hotspots

Review and address security hotspots:

```bash
# View hotspots
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/hotspots/search?projectKey=my-service"
```

### Common Security Issues

- **SQL Injection**: Use prepared statements
- **XSS**: Sanitize user input
- **Hardcoded Secrets**: Use Vault/External Secrets
- **Insecure Crypto**: Use strong algorithms
- **Path Traversal**: Validate file paths

## Metrics and Reporting

### Key Metrics

| Metric          | Description            | Target     |
| --------------- | ---------------------- | ---------- |
| Bugs            | Potential bugs         | 0          |
| Vulnerabilities | Security issues        | 0          |
| Code Smells     | Maintainability issues | ≤ 100/kLOC |
| Coverage        | Unit test coverage     | ≥ 80%      |
| Duplications    | Duplicate code         | ≤ 3%       |

### Export Reports

```bash
# PDF report
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/project_analyses/create_report?project=my-service&format=pdf"
```

## Troubleshooting

### Analysis Timeout

Increase timeout in Jenkins:

```groovy
timeout(time: 30, unit: 'MINUTES') {
    withSonarQubeEnv('SonarQube') {
        sh 'mvn sonar:sonar'
    }
}
```

### Database Issues

```bash
# Check PostgreSQL connection
kubectl exec -n fawkes deployment/sonarqube -- \
  psql -h postgresql.fawkes.svc -U sonarqube -c "SELECT version();"
```

## Related Documentation

- [Quality Profiles Guide](quality-profiles.md) - Detailed setup for Java, Python, Node.js profiles
- [Deployment Guide](../../../docs/deployment/sonarqube-deployment.md) - Complete deployment instructions
- [Deployment Summary](../../../docs/deployment/sonarqube-deployment-summary.md) - Implementation summary for issue #19
- [ADR-014: SonarQube Quality Gates](../../../docs/adr/ADR-014 sonarqube quality gates.md) - Architecture decision
- [SonarQube Documentation](https://docs.sonarqube.org/)
- [Quality Gates](https://docs.sonarqube.org/latest/user-guide/quality-gates/)
