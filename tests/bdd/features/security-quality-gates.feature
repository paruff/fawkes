# tests/bdd/features/security-quality-gates.feature

@security @quality-gates @golden-path
Feature: Security Quality Gates Configuration and Enforcement
  As a platform engineer
  I want security quality gates configured and enforced in the CI/CD pipeline
  So that vulnerable code and images are prevented from reaching production

  Background:
    Given I have kubectl configured for the cluster
    And the Jenkins shared library is loaded
    And SonarQube is deployed and accessible
    And Trivy scanner is available

  @sonarqube @quality-gate @configuration
  Scenario: SonarQube Quality Gate is Configured with Default Thresholds
    Given SonarQube is running
    When I query the default Quality Gate configuration via API
    Then the Quality Gate must include the following conditions:
      | Metric                           | Operator         | Threshold |
      | New Bugs                         | Is Greater Than  | 0         |
      | New Vulnerabilities              | Is Greater Than  | 0         |
      | New Security Hotspots Reviewed   | Is Less Than     | 100%      |
      | New Code Coverage                | Is Less Than     | 80%       |
      | New Duplicated Lines (%)         | Is Greater Than  | 3%        |

  @sonarqube @quality-gate @enforcement @failure
  Scenario: Pipeline Fails When SonarQube Quality Gate Fails
    Given a Java service with the Golden Path pipeline
    And the service has a new critical security vulnerability in the code
    When the Jenkins pipeline executes the Security Scan stage
    And the SonarQube analysis completes
    And the Quality Gate status is checked
    Then the pipeline must fail at the Quality Gate stage
    And the build log must contain "Quality Gate failed"
    And the build log must include a link to the SonarQube dashboard
    And the failure reason must be clearly stated in the output

  @sonarqube @quality-gate @enforcement @success
  Scenario: Pipeline Succeeds When SonarQube Quality Gate Passes
    Given a Python service with the Golden Path pipeline
    And the service code meets all Quality Gate criteria
    When the Jenkins pipeline executes the Security Scan stage
    And the SonarQube analysis completes
    And the Quality Gate status is checked
    Then the pipeline must pass the Quality Gate stage
    And the build log must contain "Quality Gate passed successfully"
    And the pipeline must continue to the Build Docker Image stage

  @trivy @severity-threshold @configuration
  Scenario: Trivy Severity Thresholds are Configured in Pipeline
    Given a service using the Golden Path pipeline
    When I inspect the pipeline configuration
    Then the Trivy severity filter must be set to "HIGH,CRITICAL"
    And the Trivy exit code must be set to "1"
    And the runSecurityScan flag must be true by default

  @trivy @severity-threshold @enforcement @critical
  Scenario: Pipeline Fails on CRITICAL Vulnerabilities in Container Image
    Given a Node.js service with the Golden Path pipeline
    And the Docker image contains a CRITICAL vulnerability
    When the Jenkins pipeline executes the Container Security Scan stage
    Then the Trivy scan must detect the CRITICAL vulnerability
    And the pipeline must fail at the Container Security Scan stage
    And the Trivy report must be archived as a build artifact
    And the build log must show the vulnerability details

  @trivy @severity-threshold @enforcement @high
  Scenario: Pipeline Fails on HIGH Vulnerabilities in Container Image
    Given a Go service with the Golden Path pipeline
    And the Docker image contains 2 HIGH severity vulnerabilities
    When the Jenkins pipeline executes the Container Security Scan stage
    Then the Trivy scan must detect the HIGH vulnerabilities
    And the pipeline must fail at the Container Security Scan stage
    And the Trivy report must list all HIGH vulnerabilities

  @trivy @severity-threshold @enforcement @medium
  Scenario: Pipeline Continues on MEDIUM Vulnerabilities in Container Image
    Given a Python service with the Golden Path pipeline
    And the Docker image contains only MEDIUM severity vulnerabilities
    When the Jenkins pipeline executes the Container Security Scan stage
    Then the Trivy scan must detect the MEDIUM vulnerabilities
    And the scan must report the vulnerabilities in the log
    And the pipeline must continue to the Push Artifact stage
    And the vulnerabilities must be logged but not block deployment

  @sonarqube @override @documentation
  Scenario: SonarQube Quality Gate Override Process is Documented
    Given the quality gates configuration documentation exists
    When I read the SonarQube override section
    Then the documentation must explain when to use overrides
    And it must provide inline suppression examples for Java, Python, Node.js, and Go
    And it must document project-level exclusion configuration
    And it must require approval from Tech Lead and Security Team
    And it must include an exception documentation template

  @trivy @override @trivyignore
  Scenario: Trivy Override Process Using .trivyignore is Documented
    Given the quality gates configuration documentation exists
    When I read the Trivy override section
    Then the documentation must explain when to use .trivyignore
    And it must provide .trivyignore file format examples
    And it must show how to set expiration dates on exceptions
    And it must require documentation in SECURITY.md
    And it must define the approval process with Security Team

  @trivy @override @false-positive
  Scenario: Developer Can Override Trivy False Positive with .trivyignore
    Given a service repository with a Docker image
    And Trivy detects CVE-2023-12345 which is a false positive
    When the developer creates a .trivyignore file
    And adds "CVE-2023-12345 # False positive - using prepared statements only"
    And commits and pushes the changes
    Then the next pipeline run must ignore CVE-2023-12345
    And the pipeline must complete successfully
    And other vulnerabilities must still be detected and enforced

  @secrets-scan @gitleaks @enforcement
  Scenario: Pipeline Fails When Secrets are Detected in Code
    Given a repository with the Golden Path pipeline
    And a file contains a hardcoded AWS access key
    When the Jenkins pipeline executes the Secrets Scan stage
    Then Gitleaks must detect the secret
    And the pipeline must fail immediately at the Secrets Scan stage
    And the gitleaks-report.json must be archived
    And the build log must provide clear remediation guidance

  @secrets-scan @gitleaks @override
  Scenario: Developer Can Override Gitleaks False Positive with .gitleaks.toml
    Given a repository with test fixtures containing dummy credentials
    When the developer creates a .gitleaks.toml file
    And adds the test fixtures path to the allowlist
    And commits and pushes the changes
    Then the next pipeline run must ignore secrets in test fixtures
    And the pipeline must complete successfully
    And secrets in other files must still be detected

  @multi-gate @defense-in-depth
  Scenario: Multiple Quality Gates Provide Defense in Depth
    Given a service using the Golden Path pipeline
    When the pipeline executes
    Then the following gates must run in sequence:
      | Stage                      | Gate Type          |
      | Secrets Scan               | Gitleaks           |
      | SonarQube Analysis         | SAST               |
      | Quality Gate               | SonarQube          |
      | Container Security Scan    | Trivy              |
    And if any gate fails, subsequent stages must not execute
    And the failure must be reported to the team via Mattermost

  @documentation @override-approval
  Scenario: Quality Gate Override Requires Documented Approval
    Given the quality gates configuration documentation
    When a developer needs to override a quality gate
    Then the documentation must require:
      | Requirement                    | Details                                    |
      | JIRA ticket                    | Document issue and justification           |
      | Security Team approval         | Required for all overrides                 |
      | Technical Lead approval        | Required for all overrides                 |
      | Product Owner approval         | Required for production deployments        |
      | Expiration date                | Temporary overrides must have expiry       |
      | Remediation plan               | Must schedule fix before expiration        |

  @severity-threshold @customization
  Scenario: Developer Can Customize Trivy Severity Threshold Per Project
    Given a service Jenkinsfile using Golden Path pipeline
    When the developer sets trivySeverity to "CRITICAL"
    And the pipeline is executed
    Then only CRITICAL vulnerabilities must cause pipeline failure
    And HIGH vulnerabilities must be reported but not block deployment

  @quality-gate @metrics @dora
  Scenario: Quality Gate Failures are Tracked in DORA Metrics
    Given a service with the Golden Path pipeline
    When a pipeline run fails at the Quality Gate stage
    Then the failure must be recorded as a CI build failure
    And the failure type must be tagged as "quality-gate"
    And the metrics must be sent to DevLake for DORA tracking
    And the Change Failure Rate metric must be updated

  @language-specific @java
  Scenario: Java Service Has Complete Quality Gate Configuration Example
    Given the quality gates configuration documentation
    When I read the Java example section
    Then it must include a complete Jenkinsfile example
    And it must show SonarQube configuration in pom.xml
    And it must document JaCoCo coverage report paths
    And it must show default quality gate behavior

  @language-specific @python
  Scenario: Python Service Has Complete Quality Gate Configuration Example
    Given the quality gates configuration documentation
    When I read the Python example section
    Then it must include a complete Jenkinsfile example
    And it must show SonarQube configuration in sonar-project.properties
    And it must document coverage.xml report paths
    And it must show default quality gate behavior

  @language-specific @nodejs
  Scenario: Node.js Service Has Complete Quality Gate Configuration Example
    Given the quality gates configuration documentation
    When I read the Node.js example section
    Then it must include a complete Jenkinsfile example
    And it must show SonarQube configuration in sonar-project.js
    And it must document lcov.info coverage report paths
    And it must show default quality gate behavior

  @language-specific @go
  Scenario: Go Service Has Complete Quality Gate Configuration Example
    Given the quality gates configuration documentation
    When I read the Go example section
    Then it must include a complete Jenkinsfile example
    And it must show SonarQube configuration in sonar-project.properties
    And it must document coverage.out report paths
    And it must show default quality gate behavior

  @troubleshooting @common-failures
  Scenario: Documentation Provides Troubleshooting for Common Failures
    Given the quality gates configuration documentation
    When I read the troubleshooting section
    Then it must include remediation for SonarQube vulnerability detection
    And it must include remediation for Trivy critical CVE detection
    And it must include remediation for secrets detection
    And each scenario must provide step-by-step fix instructions

  @best-practices @guidelines
  Scenario: Documentation Provides Quality Gate Best Practices
    Given the quality gates configuration documentation
    When I read the best practices section
    Then it must list DO recommendations
    And it must list DON'T anti-patterns
    And it must explain the review process for overrides
    And it must recommend monthly review of exceptions
    And it must emphasize fixing issues immediately

  @access @support
  Scenario: Documentation Provides Support and Approval Contacts
    Given the quality gates configuration documentation
    When I read the getting help section
    Then it must list relevant documentation resources
    And it must provide Mattermost channels for support
    And it must list approval contacts for Security Team
    And it must list approval contacts for Technical Leads
    And it must list approval contacts for Platform Team
