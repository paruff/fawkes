Feature: Security Plane - SBOM Generation
  As a platform engineer
  I want to automatically generate SBOMs for all container images
  So that we have visibility into our software supply chain

  Background:
    Given the Fawkes Security Plane is configured
    And SBOM generation workflow is available

  @security @sbom @local
  Scenario: Generate SBOM for Python application
    Given a Python application with dependencies
    When the SBOM generation workflow is triggered
    Then an SBOM file in CycloneDX format should be created
    And the SBOM should contain all Python packages
    And the SBOM should be uploaded as a GitHub artifact
    And the artifact retention should be 90 days

  @security @sbom @local
  Scenario: Generate SBOM for Node.js application
    Given a Node.js application with npm packages
    When the SBOM generation workflow is triggered
    Then an SBOM file should be created
    And the SBOM should list all npm dependencies
    And the SBOM should include transitive dependencies

  @security @sbom
  Scenario: SBOM generation fails gracefully
    Given an application with no package manifest
    When the SBOM generation workflow is triggered
    Then the workflow should complete with a warning
    And an empty or minimal SBOM should be generated
    And the workflow should not fail

  @security @sbom
  Scenario: Multiple SBOM formats
    Given a container image
    When the SBOM is generated with format "cyclonedx-json"
    Then the output should be valid CycloneDX JSON
    When the SBOM is generated with format "spdx-json"
    Then the output should be valid SPDX JSON

  @security @sbom @integration
  Scenario: SBOM includes vulnerability metadata
    Given a Python application with known vulnerable packages
    When an SBOM is generated
    Then the SBOM should list all packages
    And packages with known vulnerabilities should be flagged
    And vulnerability details should be included
