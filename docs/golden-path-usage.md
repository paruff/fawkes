# Golden Path CI/CD Usage Guide

This guide explains how application teams can use the Fawkes Golden Path CI/CD pipeline to build, test, and deploy applications consistently.

## Overview

The Golden Path is a standardized CI/CD pipeline that:

- **Enforces Trunk-Based Development**: Only the main branch produces artifacts
- **Includes Mandatory Security Scanning**: SonarQube, Trivy, dependency checks
- **Supports BDD Testing**: Gherkin/Cucumber integration
- **Produces GitOps-Ready Artifacts**: Versioned container images for ArgoCD
- **Tracks DORA Metrics**: Automated metrics collection

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

## Next Steps

1. Add Jenkinsfile to your repository
2. Configure BDD tests (optional)
3. Push to main branch
4. Monitor build in Jenkins
5. Verify deployment in ArgoCD
