# Golden Path CI/CD Usage Guide

This guide explains how application teams can use the Fawkes Golden Path CI/CD pipeline to build, test, and deploy applications consistently.

## Overview

The Golden Path is a standardized CI/CD pipeline that:

- **Enforces Trunk-Based Development**: Only the main branch produces artifacts
- **Includes Mandatory Security Scanning**: SonarQube, Trivy, dependency checks
- **Supports BDD Testing**: Gherkin/Cucumber integration
- **Produces GitOps-Ready Artifacts**: Versioned container images for ArgoCD
- **Tracks DORA Metrics**: Automated metrics collection
- **Uses SCORE for Workload Definition**: Platform-agnostic application specifications (see [SCORE Integration](#score-workload-specification))

## Quick Start

### 1. Add a Jenkinsfile

Create a `Jenkinsfile` in your repository root:

```groovy
@Library('fawkes-pipeline-library') _

goldenPathPipeline {
    appName = 'my-service'
    language = 'java'  // java, python, node, go
}
```

### 2. Push to Main Branch

When you push to the `main` branch, the pipeline automatically:

1. Builds your application
2. Runs unit tests
3. Runs BDD/Gherkin tests
4. Performs security scanning
5. Builds a Docker image
6. Scans the container
7. Pushes to the registry
8. Updates GitOps manifests
9. Records DORA metrics

### 3. Open Pull Requests

PR builds run a lightweight pipeline with only tests (no artifacts).

## Pipeline Configuration

### Required Options

| Option | Description | Example |
|--------|-------------|---------|
| `appName` | Application name | `'my-service'` |
| `language` | Programming language | `'java'`, `'python'`, `'node'`, `'go'` |

### Optional Options

| Option | Default | Description |
|--------|---------|-------------|
| `dockerRegistry` | `harbor.fawkes.local` | Container registry URL |
| `dockerImage` | Auto-generated | Full Docker image path |
| `notifyChannel` | `ci-builds` | Mattermost channel for notifications |
| `testCommand` | Language-specific | Custom unit test command |
| `bddTestCommand` | Language-specific | Custom BDD test command |
| `buildCommand` | Language-specific | Custom build command |
| `sonarProject` | `appName` | SonarQube project key |
| `trivySeverity` | `HIGH,CRITICAL` | Trivy severity threshold |
| `runBddTests` | `true` | Enable/disable BDD testing |
| `runSecurityScan` | `true` | Enable/disable security scanning |
| `deployToArgoCD` | `true` | Update GitOps manifests |
| `timeoutMinutes` | `30` | Pipeline timeout |

## Language-Specific Configuration

### Java (Maven)

```groovy
goldenPathPipeline {
    appName = 'java-service'
    language = 'java'
    // Defaults:
    // buildCommand = 'mvn clean package -DskipTests'
    // testCommand = 'mvn test'
    // bddTestCommand = 'mvn verify -Pcucumber'
}
```

**Required Files:**
- `pom.xml` - Maven project file
- `Dockerfile` - Container build instructions
- `src/test/java/` - Unit tests
- `src/test/resources/features/` - Gherkin feature files (optional)

**Cucumber Integration:**

Add to `pom.xml`:

```xml
<profiles>
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
</profiles>
```

### Python

```groovy
goldenPathPipeline {
    appName = 'python-service'
    language = 'python'
    // Defaults:
    // buildCommand = 'pip install -r requirements.txt && pip install -e .'
    // testCommand = 'pytest tests/unit --junitxml=test-results.xml --cov=src --cov-report=xml'
    // bddTestCommand = 'behave --junit --junit-directory=bdd-results'
}
```

**Required Files:**
- `requirements.txt` - Dependencies
- `Dockerfile` - Container build instructions
- `tests/unit/` - Unit tests
- `features/` - Behave feature files (optional)

**Behave Integration:**

```
features/
├── environment.py
├── steps/
│   └── my_steps.py
└── my_feature.feature
```

### Node.js

```groovy
goldenPathPipeline {
    appName = 'node-service'
    language = 'node'
    // Defaults:
    // buildCommand = 'npm ci && npm run build'
    // testCommand = 'npm test -- --ci --reporters=jest-junit'
    // bddTestCommand = 'npm run test:bdd'
}
```

**Required Files:**
- `package.json` - Node.js project file
- `Dockerfile` - Container build instructions
- `__tests__/` or `tests/` - Unit tests
- `features/` - Cucumber.js feature files (optional)

**Cucumber.js Integration:**

Add to `package.json`:

```json
{
  "scripts": {
    "test:bdd": "cucumber-js"
  },
  "devDependencies": {
    "@cucumber/cucumber": "^9.0.0"
  }
}
```

### Go

```groovy
goldenPathPipeline {
    appName = 'go-service'
    language = 'go'
    // Defaults:
    // buildCommand = 'go build -v ./...'
    // testCommand = 'go test -v -coverprofile=coverage.out ./...'
    // bddTestCommand = 'go test -v ./features/...'
}
```

**Required Files:**
- `go.mod` - Go module file
- `Dockerfile` - Container build instructions
- `*_test.go` - Unit tests
- `features/` - Godog feature files (optional)

## Custom Commands

Override default commands when needed:

```groovy
goldenPathPipeline {
    appName = 'my-service'
    language = 'java'

    // Custom build with production profile
    buildCommand = 'mvn clean package -P production -DskipTests'

    // Run only specific tests
    testCommand = 'mvn test -Dtest=UnitTests'

    // Run only smoke BDD tests
    bddTestCommand = 'mvn verify -Dcucumber.filter.tags="@smoke"'
}
```

## BDD/Gherkin Testing

### Feature File Example

Create `src/test/resources/features/user_registration.feature`:

```gherkin
Feature: User Registration
  As a new user
  I want to register for an account
  So that I can access the application

  Background:
    Given the registration service is available

  @smoke
  Scenario: Successful registration
    Given I have valid user details
    When I submit the registration form
    Then my account is created
    And I receive a confirmation email

  @validation
  Scenario Outline: Invalid registration data
    Given I provide "<field>" with "<value>"
    When I submit the registration form
    Then I receive error "<error>"

    Examples:
      | field    | value | error               |
      | email    |       | Email is required   |
      | password | 123   | Password too short  |
```

### Step Definitions

#### Java (Cucumber)

```java
public class UserRegistrationSteps {
    @Given("the registration service is available")
    public void serviceIsAvailable() {
        // Verify service is running
    }

    @When("I submit the registration form")
    public void submitForm() {
        // Submit registration
    }

    @Then("my account is created")
    public void accountCreated() {
        // Verify account exists
    }
}
```

#### Python (Behave)

```python
from behave import given, when, then

@given('the registration service is available')
def service_available(context):
    # Verify service is running
    pass

@when('I submit the registration form')
def submit_form(context):
    # Submit registration
    pass

@then('my account is created')
def account_created(context):
    # Verify account exists
    pass
```

## Security Scanning

### SonarQube

Add `sonar-project.properties` to your repository:

```properties
sonar.projectKey=my-service
sonar.sources=src
sonar.tests=tests
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
```

### Trivy

Container scanning is automatic. Customize severity threshold:

```groovy
goldenPathPipeline {
    trivySeverity = 'CRITICAL'  // Only fail on critical
    trivyExitCode = '0'         // Don't fail build (warning only)
}
```

### Dependency Checks

Language-specific dependency scanning:
- **Java**: OWASP Dependency-Check Maven plugin
- **Python**: `safety` and `pip-audit`
- **Node.js**: `npm audit`
- **Go**: `govulncheck`

## Notifications

Build notifications are sent to Mattermost:

```groovy
goldenPathPipeline {
    notifyChannel = 'my-team-builds'
}
```

Notifications include:
- ✅/❌ Build status
- Build number and duration
- Commit SHA and branch
- Link to Jenkins build

## DORA Metrics

The pipeline automatically records:

- **Build Status**: Success/failure
- **Build Duration**: Time to complete
- **Commit Information**: SHA, branch, author
- **Deployment Events**: When artifacts are pushed

Access DORA dashboard at: `http://grafana.fawkes.local/d/dora`

## Pull Request Workflow

### PR Pipeline

PRs trigger a lightweight pipeline:

| Stage | Executed? |
|-------|-----------|
| Checkout | ✅ |
| Build | ❌ |
| Unit Test | ✅ |
| BDD Test | ✅ |
| Security Scan | ❌ |
| Docker Build | ❌ |
| Push Artifact | ❌ |

### Merge Requirements

Before merging:
1. All tests pass
2. Code review approved
3. PR status checks green

## Troubleshooting

### Common Issues

#### Build Timeout
Increase timeout in Jenkinsfile:
```groovy
timeoutMinutes = 60
```

#### SonarQube Fails
1. Check SonarQube project exists
2. Verify credentials in Jenkins
3. Check `sonar-project.properties`

#### Docker Push Fails
1. Verify registry credentials
2. Check network connectivity
3. Ensure image name is valid

#### BDD Tests Not Running
1. Ensure `runBddTests = true`
2. Check step definitions exist
3. Verify feature files are in correct location

### Debug Mode

View detailed logs in Jenkins console output:
1. Go to Jenkins build
2. Click "Console Output"
3. Search for stage name

### Getting Help

- **Documentation**: This guide and shared library README
- **Mattermost**: `#platform-support` channel
- **Office Hours**: Platform team availability

## Best Practices

1. **Keep Jenkinsfiles minimal** - Use default configurations
2. **Test locally first** - Run tests before pushing
3. **Use feature flags** - Deploy to main frequently
4. **Monitor builds** - Watch for increasing durations
5. **Update dependencies** - Keep libraries current
6. **Define workloads with SCORE** - Use `score.yaml` for portable application definitions

## SCORE Workload Specification

Fawkes Golden Path supports [SCORE](https://score.dev), an open-source, platform-agnostic workload specification. Instead of writing Kubernetes YAML directly, define your application's needs in a simple `score.yaml` file.

### Why SCORE?

✅ **Portability**: Define once, deploy anywhere (dev, staging, prod)
✅ **Simplicity**: Describe what you need, not how to configure K8s
✅ **Consistency**: Same format across all Golden Path applications
✅ **Developer-Friendly**: Focus on application logic, not infrastructure

### Quick Example

Create a `score.yaml` in your repository:

```yaml
apiVersion: score.dev/v1b1
metadata:
  name: my-service

containers:
  web:
    image: "harbor.fawkes.local/my-team/my-service:latest"
    resources:
      limits: {memory: "512Mi", cpu: "500m"}
      requests: {memory: "256Mi", cpu: "250m"}
    variables:
      LOG_LEVEL: "info"
      DATABASE_URL: "${resources.db.connection_string}"

service:
  ports:
    web: {port: 80, targetPort: 8080}

resources:
  db:
    type: postgres
    properties:
      database: "myapp"

route:
  host: "my-service.${ENVIRONMENT}.fawkes.idp"
  tls: {enabled: true}
```

The platform automatically translates this into:
- Kubernetes Deployment
- Service
- Ingress
- PostgreSQL database (via CloudNativePG)
- TLS certificate (via cert-manager)

### Repository Structure with SCORE

```
my-service/
├── score.yaml              # Workload definition (SCORE spec)
├── Jenkinsfile             # CI/CD pipeline
├── Dockerfile              # Container build
├── src/                    # Application code
└── tests/                  # Tests
```

### Supported Resources

| Resource Type | Description | Fawkes Implementation |
|--------------|-------------|----------------------|
| `postgres` | PostgreSQL database | CloudNativePG Cluster |
| `redis` | Redis cache | Redis Helm Chart |
| `secret` | Secrets from Vault | External Secrets Operator |
| `volume` | Persistent storage | PersistentVolumeClaim |

### Environment-Specific Deployment

The same `score.yaml` works across environments. Environment differences (replicas, resource limits, hostnames) are handled by the platform:

**Dev Environment:**
- 1 replica
- Smaller resource limits
- `my-service.dev.fawkes.idp`

**Prod Environment:**
- 3 replicas with autoscaling
- Higher resource limits
- `my-service.prod.fawkes.idp`

### Migration from K8s Manifests

If you have existing Kubernetes manifests, you can migrate gradually:

1. **Keep existing manifests** - They continue to work
2. **Create score.yaml** - Define the same workload in SCORE
3. **Validate** - Ensure generated manifests match your needs
4. **Switch** - Remove old manifests, use SCORE-generated ones

### Advanced Configuration

For Fawkes-specific features (autoscaling, observability, security policies), use the `extensions.fawkes` section:

```yaml
extensions:
  fawkes:
    team: my-team
    deployment:
      autoscaling:
        enabled: true
        minReplicas: 2
        maxReplicas: 10
    observability:
      metrics:
        enabled: true
        port: 9090
    security:
      runAsNonRoot: true
```

### Documentation & Examples

- **Full Template**: See `templates/golden-path-service/score.yaml`
- **Architecture Decision**: [ADR-030: SCORE Integration](adr/ADR-030%20SCORE%20Workload%20Specification%20Integration.md)
- **Transformer Details**: `charts/score-transformer/README.md`
- **Official SCORE Docs**: https://score.dev

## Next Steps

1. Add Jenkinsfile to your repository
2. Create `score.yaml` for workload definition (recommended)
3. Configure BDD tests (optional)
4. Push to main branch
5. Monitor build in Jenkins
6. Verify deployment in ArgoCD
