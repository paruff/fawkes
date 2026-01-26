Feature: Security Plane - Policy Enforcement
  As a security engineer
  I want to enforce security policies as code
  So that all deployments meet security standards

  Background:
    Given the Fawkes Security Plane is configured
    And OPA/Conftest is installed
    And security policies are loaded from ".security-plane/policies/"

  @security @policy @local
  Scenario: Enforce Kubernetes security policies
    Given a Kubernetes Deployment manifest
    And the deployment runs as root
    When policy enforcement is run
    Then the policy check should fail
    And the error message should indicate "must run as non-root user"

  @security @policy @local
  Scenario: Pass Kubernetes security policies
    Given a Kubernetes Deployment manifest
    And the deployment has non-root security context
    And the deployment has resource limits
    And the deployment has health probes
    When policy enforcement is run
    Then the policy check should pass
    And no violations should be reported

  @security @policy @local
  Scenario: Enforce Dockerfile best practices
    Given a Dockerfile using "USER root"
    When Dockerfile policy check is run
    Then the policy check should fail
    And the error message should indicate "must not use root user"

  @security @policy @local
  Scenario: Warn on Dockerfile improvements
    Given a Dockerfile using ":latest" tag
    When Dockerfile policy check is run
    Then a warning should be issued
    And the message should suggest "use specific version tags"

  @security @policy
  Scenario: Block critical vulnerabilities
    Given a container image with CRITICAL vulnerabilities
    And policy enforcement mode is "strict"
    When supply chain policy check is run
    Then the policy check should fail
    And the error message should list critical CVEs
    And deployment should be blocked

  @security @policy
  Scenario: Require SBOM presence
    Given a container image without an SBOM
    And SBOM requirement policy is enabled
    When supply chain policy check is run
    Then the policy check should fail
    And the error message should indicate "SBOM required"

  @security @policy
  Scenario: Require image signature
    Given a container image without a signature
    And image signing requirement policy is enabled
    And environment is "production"
    When supply chain policy check is run
    Then the policy check should fail
    And the error message should indicate "image must be signed"

  @security @policy @integration
  Scenario: Advisory mode allows violations
    Given policy enforcement mode is "advisory"
    And a Kubernetes manifest with policy violations
    When policy enforcement is run
    Then warnings should be logged
    But the workflow should not fail
    And violations should be reported in summary

  @security @policy @integration
  Scenario: Strict mode blocks violations
    Given policy enforcement mode is "strict"
    And a Kubernetes manifest with policy violations
    When policy enforcement is run
    Then the workflow should fail
    And violations should be listed
    And the PR should be blocked

  @security @policy
  Scenario: Custom policy rules
    Given a custom policy requiring specific labels
    And a Kubernetes manifest missing required labels
    When policy enforcement is run
    Then the custom policy should be evaluated
    And the check should fail on missing labels
    And the error should reference the custom policy
