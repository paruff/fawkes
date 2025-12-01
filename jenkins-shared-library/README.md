# Fawkes Jenkins Shared Library

This shared library provides a standardized "Golden Path" CI/CD pipeline for the Fawkes platform. It enforces trunk-based development principles with mandatory security and quality gates.

## Overview

The Golden Path pipeline ensures consistent, secure, and well-tested container images across all application repositories. It follows these principles:

- **Trunk-Based Development**: Artifacts are only produced from the main branch
- **Security First**: Mandatory security scanning at multiple levels
- **Quality Gates**: Automated testing and code quality enforcement
- **GitOps Ready**: Produces versioned artifacts for ArgoCD deployment

## Quick Start

### 1. Configure Jenkins

Add this shared library to your Jenkins instance via Configuration as Code:

```yaml
unclassified:
  globalLibraries:
    libraries:
      - name: "fawkes-pipeline-library"
        defaultVersion: "main"
        retriever:
          modernSCM:
            scm:
              git:
                remote: "https://github.com/paruff/fawkes"
                credentialsId: "github-token"
```

### 2. Create a Jenkinsfile

Add a minimal `Jenkinsfile` to your repository:

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'java'  // java, python, node, go
}
```

That's it! The pipeline automatically handles:
- Building your application
- Running unit tests
- Executing BDD/Gherkin tests
- Security scanning (SonarQube, Trivy, dependency checks)
- Building and pushing Docker images
- Updating GitOps manifests for ArgoCD

## Pipeline Stages

### For Main Branch (Artifact Production)

| Stage | Description |
|-------|-------------|
| Checkout | Clone repository |
| Build | Compile/build application |
| Unit Test | Run unit tests |
| BDD/Gherkin Test | Run behavior-driven tests |
| Security Scan | SonarQube analysis, dependency check |
| Quality Gate | Wait for SonarQube quality gate |
| Build Docker Image | Create container image |
| Container Security Scan | Trivy vulnerability scan |
| Push Artifact | Push to container registry |
| Update GitOps | Update manifests for ArgoCD |
| Record DORA Metrics | Send metrics to DORA service |

### For Pull Requests (Fast Feedback)

| Stage | Description |
|-------|-------------|
| Checkout | Clone repository |
| Unit Test | Run unit tests |
| BDD/Gherkin Test | Run BDD tests |
| Code Style Check | Lint and style checking |

## Available Pipelines

### goldenPathPipeline

Full CI/CD pipeline for main branch with artifact production.

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'java'
    dockerImage = 'harbor.fawkes.local/myorg/my-service'
    notifyChannel = 'team-builds'
    runBddTests = true
    runSecurityScan = true
}
```

### prValidationPipeline

Lightweight pipeline for PR validation.

```groovy
@Library('fawkes-pipeline-library') _

prValidationPipeline {
    appName = 'my-service'
    language = 'java'
}
```

## Configuration Options

### goldenPathPipeline Options

| Option | Default | Description |
|--------|---------|-------------|
| `appName` | Job name | Application name |
| `language` | `java` | Language: java, python, node, go |
| `dockerImage` | Auto-generated | Full Docker image path |
| `dockerRegistry` | `harbor.fawkes.local` | Container registry |
| `notifyChannel` | `ci-builds` | Mattermost channel |
| `testCommand` | Language-specific | Unit test command |
| `bddTestCommand` | Language-specific | BDD test command |
| `buildCommand` | Language-specific | Build command |
| `sonarProject` | `appName` | SonarQube project key |
| `trivySeverity` | `HIGH,CRITICAL` | Trivy severity filter |
| `trivyExitCode` | `1` | Exit code on vulnerabilities |
| `deployToArgoCD` | `true` | Update GitOps manifests |
| `argocdApp` | `{appName}-dev` | ArgoCD application name |
| `runBddTests` | `true` | Enable BDD testing |
| `runSecurityScan` | `true` | Enable security scanning |
| `timeoutMinutes` | `30` | Pipeline timeout |

### Language-Specific Defaults

#### Java
```groovy
buildCommand = 'mvn clean package -DskipTests'
testCommand = 'mvn test'
bddTestCommand = 'mvn verify -Pcucumber'
```

#### Python
```groovy
buildCommand = 'pip install -r requirements.txt && pip install -e .'
testCommand = 'pytest tests/unit --junitxml=test-results.xml --cov=src --cov-report=xml'
bddTestCommand = 'behave --junit --junit-directory=bdd-results'
```

#### Node.js
```groovy
buildCommand = 'npm ci && npm run build'
testCommand = 'npm test -- --ci --reporters=jest-junit'
bddTestCommand = 'npm run test:bdd'
```

#### Go
```groovy
buildCommand = 'go build -v ./...'
testCommand = 'go test -v -coverprofile=coverage.out ./...'
bddTestCommand = 'go test -v ./features/...'
```

## Custom Commands

Override default commands when needed:

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'java'
    
    // Custom commands
    buildCommand = 'mvn clean package -P production -DskipTests'
    testCommand = 'mvn test -Dtest=UnitTests'
    bddTestCommand = 'mvn verify -Dcucumber.filter.tags="@smoke"'
}
```

## BDD/Gherkin Test Integration

### Cucumber (Java)

Add Cucumber dependencies and create feature files in `src/test/resources/features/`:

```gherkin
Feature: User Registration
  Scenario: Successful registration
    Given a new user with valid details
    When they submit the registration form
    Then they should receive a confirmation email
```

Configure Maven profile:
```xml
<profile>
    <id>cucumber</id>
    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-failsafe-plugin</artifactId>
                <configuration>
                    <includes>
                        <include>**/CucumberRunner.java</include>
                    </includes>
                </configuration>
            </plugin>
        </plugins>
    </build>
</profile>
```

### Behave (Python)

Create feature files in `features/`:

```gherkin
Feature: API Endpoints
  Scenario: Health check returns 200
    Given the API is running
    When I request the health endpoint
    Then I should receive status 200
```

### Jest + Cucumber (Node.js)

Add `@cucumber/cucumber` and create step definitions:

```javascript
// features/step_definitions/api.steps.js
const { Given, When, Then } = require('@cucumber/cucumber');

Given('the API is running', function() {
    // setup
});
```

## Security Scanning

### SonarQube

The Golden Path pipeline includes mandatory SonarQube Quality Gate enforcement. When the Quality Gate fails, the pipeline stops and provides a direct link to the SonarQube dashboard.

#### Jenkins Configuration

1. Install the SonarQube Scanner plugin
2. Configure SonarQube server in Jenkins (Manage Jenkins > Configure System > SonarQube servers):
   - Name: `SonarQube`
   - Server URL: `http://sonarqube.fawkes.svc:9000`
   - Server authentication token: (create in SonarQube and add as Jenkins credential)

3. Add `sonar-project.properties` to your repository:

```properties
sonar.projectKey=my-service
sonar.projectName=My Service
sonar.sources=src
sonar.tests=tests
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

#### Quality Gate Behavior

**Main Branch**: Quality Gate is **mandatory**. Pipeline fails if gate fails.
**PR Branches**: Quality Gate status is reported but does not block.

When Quality Gate fails, developers see:
- ❌ Failure reason in console output
- 📊 Direct link to SonarQube analysis report
- List of common failure causes

#### Quality Gate Thresholds

| Metric | Threshold |
|--------|-----------|
| New Bugs | 0 |
| New Vulnerabilities | 0 |
| New Security Hotspots Reviewed | 100% |
| New Code Coverage | ≥80% |
| New Duplicated Lines | ≤3% |
| Maintainability Rating | A |

#### Custom Configuration

```groovy
goldenPathPipeline {
    appName = 'my-service'
    sonarProject = 'custom-project-key'  // Override default (appName)
    runSecurityScan = true               // Enable SonarQube (default)
}
```

### Trivy

Container images are automatically scanned with Trivy. Configure severity:

```groovy
goldenPathPipeline {
    trivySeverity = 'CRITICAL'  // Only fail on critical
    trivyExitCode = '0'         // Don't fail build
}
```

### OWASP Dependency Check

Automatically runs for Java projects. For other languages:
- Python: `safety` and `pip-audit`
- Node.js: `npm audit`
- Go: `govulncheck`

## DORA Metrics

The pipeline automatically records metrics to the DORA metrics service:

- Build status (success/failure)
- Build duration
- Commit information
- Branch information

Configure the metrics endpoint:
```groovy
environment {
    DORA_METRICS_URL = 'http://dora-metrics.fawkes.svc:8080'
}
```

## Notifications

Build notifications are sent to Mattermost:

```groovy
goldenPathPipeline {
    notifyChannel = 'team-builds'
}
```

Notification includes:
- Build status (✅ success / ❌ failure)
- Build number and duration
- Commit SHA and branch
- Link to build

## Troubleshooting

### Common Issues

1. **Build timeout**: Increase `timeoutMinutes`
2. **SonarQube fails**: Check credentials and project configuration
3. **Docker push fails**: Verify registry credentials
4. **ArgoCD not syncing**: Check GitOps repository permissions

### Debug Mode

Enable verbose logging:

```groovy
goldenPathPipeline {
    // Add to pipeline
    options {
        timestamps()
    }
}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Submit a pull request

## License

MIT License - see LICENSE file for details.
