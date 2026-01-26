Feature: Security Plane - Vulnerability Scanning
  As a security engineer
  I want to automatically scan for security vulnerabilities
  So that we can identify and fix security issues early

  Background:
    Given the Fawkes Security Plane is configured
    And Trivy vulnerability scanner is available
    And Gitleaks secret scanner is available

  @security @scanning @local
  Scenario: Scan for secrets in codebase
    Given a Git repository
    When Gitleaks secret scanning is run
    Then no hardcoded secrets should be found
    And the scan should check for API keys
    And the scan should check for passwords
    And the scan should check for private keys

  @security @scanning @local
  Scenario: Detect hardcoded secrets
    Given a file with a hardcoded API key
    When Gitleaks secret scanning is run
    Then the scan should fail
    And the secret should be reported
    And the file location should be provided
    And remediation guidance should be given

  @security @scanning @local
  Scenario: Scan filesystem for vulnerabilities
    Given a Python application with requirements.txt
    When Trivy filesystem scan is run
    Then all dependencies should be scanned
    And vulnerabilities should be reported by severity
    And CVE identifiers should be listed

  @security @scanning
  Scenario: Scan container image for vulnerabilities
    Given a container image "python:3.9"
    When Trivy container scan is run
    Then the base image should be scanned
    And OS packages should be scanned
    And application dependencies should be scanned
    And results should be uploaded to GitHub Security

  @security @scanning
  Scenario: Fail on critical vulnerabilities
    Given a container image with CRITICAL vulnerabilities
    And fail-on-critical is enabled
    When vulnerability scanning is run
    Then the scan should fail
    And critical vulnerabilities should be listed
    And the PR should be blocked

  @security @scanning
  Scenario: Advisory mode on critical vulnerabilities
    Given a container image with CRITICAL vulnerabilities
    And enforcement mode is "advisory"
    When vulnerability scanning is run
    Then the scan should complete
    But warnings should be reported
    And the PR should not be blocked

  @security @scanning @integration
  Scenario: Scan Python dependencies
    Given a requirements.txt with vulnerable packages
    When dependency scanning is run
    Then pip packages should be scanned
    And vulnerable packages should be identified
    And fixed versions should be suggested

  @security @scanning @integration
  Scenario: Scan Node.js dependencies
    Given a package.json with vulnerable packages
    When npm audit is run
    Then npm packages should be scanned
    And vulnerabilities should be reported
    And npm audit fix suggestions should be provided

  @security @scanning
  Scenario: Upload SARIF results to GitHub
    Given a vulnerability scan has completed
    When SARIF upload is enabled
    Then results should be formatted as SARIF
    And SARIF should be uploaded to GitHub Security tab
    And vulnerabilities should appear in security alerts

  @security @scanning
  Scenario: Multiple scan types in one workflow
    Given scan-type is "all"
    When the security scanning workflow is run
    Then secret scanning should execute
    And vulnerability scanning should execute
    And dependency scanning should execute
    And all results should be aggregated

  @security @scanning
  Scenario: Severity threshold filtering
    Given severity threshold is "HIGH"
    And a scan finds LOW, MEDIUM, HIGH, and CRITICAL issues
    When the scan results are filtered
    Then only HIGH and CRITICAL issues should be reported
    And LOW and MEDIUM issues should be suppressed
