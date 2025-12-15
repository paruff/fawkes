# tests/bdd/features/secrets-scanning.feature

@secrets-scanning @security @ci-cd @pipeline
Feature: Secrets Detection in CI/CD Pipelines
  As a security engineer
  I want automated secrets scanning in all CI/CD pipelines
  So that hardcoded secrets are detected and prevented from being deployed

  Background:
    Given I have a Jenkins pipeline configured with the Golden Path
    And Gitleaks is available as a container in the pipeline
    And the secrets scanning stage is enabled

  @pre-commit @local-protection
  Scenario: Pre-commit Hook Prevents Local Secret Commits
    Given a developer has pre-commit hooks installed
    And a file contains a hardcoded AWS access key
    When the developer attempts to commit the file
    Then the commit is blocked by Gitleaks pre-commit hook
    And the developer sees which file contains the secret
    And the developer sees the line number of the secret

  @pipeline @secrets-detected @failure
  Scenario: Pipeline Fails When Secrets Are Detected
    Given a repository contains a file with a hardcoded API key
    When the Jenkins pipeline runs the Secrets Scan stage
    Then the Gitleaks scan detects the secret
    And the Secrets Scan stage fails
    And the pipeline is aborted
    And a Gitleaks report is archived as a Jenkins artifact
    And the build description includes a link to the report

  @pipeline @no-secrets @success
  Scenario: Pipeline Passes When No Secrets Are Detected
    Given a repository contains no hardcoded secrets
    And all secrets are properly externalized
    When the Jenkins pipeline runs the Secrets Scan stage
    Then the Gitleaks scan completes successfully
    And no secrets are detected
    And the pipeline continues to the next stage

  @configuration @allowlist
  Scenario: False Positives Are Handled Via Allowlist
    Given a test file contains a fake API key for testing
    And the fake key is added to the .gitleaks.toml allowlist
    When the Jenkins pipeline runs the Secrets Scan stage
    Then the Gitleaks scan ignores the allowlisted value
    And the scan completes successfully

  @detection-coverage @api-keys
  Scenario Outline: Various Secret Types Are Detected
    Given a file contains a hardcoded <secret_type>
    When the Gitleaks scan runs
    Then the <secret_type> is detected
    And the scan reports the secret type and location

    Examples:
      | secret_type                  |
      | AWS Access Key               |
      | GitHub Personal Access Token |
      | Slack Webhook URL            |
      | Database Password            |
      | Private SSH Key              |
      | JWT Secret                   |
      | Azure Storage Connection String |

  @parallel-execution
  Scenario: Secrets Scan Runs in Parallel With Other Security Scans
    Given the Security Scan stage has multiple parallel checks
    When the pipeline executes the Security Scan stage
    Then the Secrets Scan runs in parallel with Container Scan
    And the Secrets Scan runs in parallel with SonarQube Analysis
    And the Secrets Scan runs in parallel with Dependency Check
    And all scans complete before proceeding to the next stage

  @reporting @audit-trail
  Scenario: Secrets Detection Creates Audit Trail
    Given a pipeline detects secrets in code
    When the Secrets Scan stage completes
    Then a gitleaks-report.json file is generated
    And the report is archived as a Jenkins artifact
    And the report includes the commit SHA
    And the report includes the file path and line number
    And the report includes the secret type detected

  @documentation @developer-guidance
  Scenario: Clear Guidance Is Provided When Secrets Are Detected
    Given a pipeline fails due to detected secrets
    When a developer views the build logs
    Then the logs explain why the pipeline failed
    And the logs list common types of detected secrets
    And the logs provide next steps for remediation
    And the logs reference the secrets management documentation

  @configuration @custom-rules
  Scenario: Custom Detection Rules Can Be Configured
    Given a .gitleaks.toml file exists in the repository
    And the file defines custom regex patterns for organization-specific secrets
    When the Gitleaks scan runs
    Then the custom rules are applied
    And organization-specific secret patterns are detected

  @integration @shared-library
  Scenario: Secrets Scanning Is Available Via Shared Library
    Given a project uses the securityScan shared library
    When the pipeline calls securityScan with default configuration
    Then the secrets scanning is automatically included
    And runs in parallel with other security checks

  @failure-mode @fail-fast
  Scenario: Pipeline Fails Fast on Critical Secret Detection
    Given a repository contains a production database password
    When the Secrets Scan stage executes
    Then the scan immediately fails upon detection
    And no subsequent stages are executed
    And the repository owner is notified of the security issue

  @environment-specific @allowlist-paths
  Scenario: Test Directories Are Excluded From Strict Scanning
    Given test fixture files contain fake secrets for testing
    And the test directories are listed in .gitleaks.toml paths allowlist
    When the Gitleaks scan runs
    Then secrets in test fixture paths are ignored
    And secrets in production code paths are still detected
