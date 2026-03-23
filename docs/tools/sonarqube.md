# SonarQube

[SonarQube](https://www.sonarqube.org/) is a static application security testing (SAST)
and code quality platform. It analyses source code for bugs, security vulnerabilities,
code smells, and test coverage gaps.

## How Fawkes Uses SonarQube

SonarQube is deployed in the platform namespace and integrated into the Jenkins CI pipeline.
Every pull request triggers a SonarQube scan. Builds fail if the analysis does not pass
the Quality Gate (by default: no new HIGH or CRITICAL issues, coverage ≥ 80% on new code).

```groovy
// Jenkinsfile (via shared library)
stage('SonarQube Analysis') {
    withSonarQubeEnv('fawkes-sonar') {
        sh 'mvn sonar:sonar'  // or: sonar-scanner for Python/JS
    }
}
stage('Quality Gate') {
    timeout(time: 5, unit: 'MINUTES') {
        waitForQualityGate abortPipeline: true
    }
}
```

## Key Metrics

| Metric | Description | Gate Threshold |
|--------|-------------|----------------|
| **Bugs** | Definite logic errors | 0 new bugs |
| **Vulnerabilities** | Security weaknesses | 0 HIGH/CRITICAL |
| **Code Smells** | Maintainability issues | Grade A on new code |
| **Coverage** | Unit test line coverage | ≥ 80% on new code |
| **Duplications** | Copy-pasted code | < 3% duplication |

## Supported Languages

SonarQube in Fawkes is configured for: Python, Java, JavaScript/TypeScript, Go, and
shell scripts (via community plugins).

## Accessing the UI

Navigate to the SonarQube URL in your environment. Log in with your SSO credentials.
The **Projects** view shows all analysed repositories. Click a project to see the issue
breakdown, code coverage map, and Quality Gate history.

## Excluding Files

Add a `sonar-project.properties` file to exclude generated code, vendor directories,
or migration scripts from analysis:

```properties
sonar.exclusions=**/migrations/**,**/vendor/**,**/*_generated.go
```

## See Also

- [Quality Gates Configuration](../how-to/security/quality-gates-configuration.md)
- [Shift Left on Security Pattern](../patterns/shift-left-on-security.md)
- [Change Failure Rate Reduction Pattern](../patterns/change-failure-rate-reduction.md)
