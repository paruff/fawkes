# tests/bdd/features/trivy-integration.feature

@trivy @security @container-scanning
Feature: Trivy Container Security Scanning Integration
  As a platform engineer
  I want Trivy integrated into Jenkins pipelines and Harbor
  So that all container images are automatically scanned for vulnerabilities

  Background:
    Given Jenkins is deployed and accessible
    And Harbor is deployed with Trivy scanner enabled
    And the Golden Path pipeline is configured

  @jenkins @pipeline
  Scenario: Trivy integrated in Jenkins Golden Path pipeline
    Given a Jenkinsfile uses the Golden Path shared library
    And a Docker image has been built in the pipeline
    When the Container Security Scan stage executes
    Then Trivy scanner should be available in the pipeline pod
    And Trivy should scan the container image
    And the scan should check for HIGH and CRITICAL vulnerabilities
    And the scan report should be archived as a build artifact

  @jenkins @scan-report
  Scenario: Trivy scan generates reports in Jenkins
    Given a container image is scanned by Trivy in Jenkins
    When the scan completes
    Then a Trivy report in table format should be generated
    And a Trivy report in JSON format should be generated
    And the reports should be archived in Jenkins
    And the reports should be accessible from the build page

  @jenkins @quality-gate
  Scenario: Trivy scan enforces security quality gate
    Given a container image with CRITICAL vulnerabilities
    When Trivy scans the image with exit-code 1
    Then the pipeline should fail
    And the build status should be FAILURE
    And the console output should show vulnerability details
    And developers should be notified of the failure

  @harbor @automatic-scanning
  Scenario: Harbor automatically scans images on push
    Given Harbor is deployed with Trivy scanner enabled
    When a container image is pushed to Harbor
    Then Harbor should automatically trigger a Trivy scan
    And the scan should complete within 5 minutes
    And the scan results should be visible in Harbor UI
    And the scan results should show vulnerability counts by severity

  @harbor @trivy-pod
  Scenario: Trivy scanner pod is running in Harbor
    Given Harbor is deployed in namespace "fawkes"
    When I check for Trivy scanner pods
    Then a pod with label "component=trivy" should exist
    And the pod should be in Running state
    And the pod should be Ready
    And the pod should have Trivy vulnerability database

  @harbor @scan-results
  Scenario: Query Trivy scan results via Harbor API
    Given Harbor is deployed and accessible
    And a container image has been pushed and scanned
    When I query the Harbor API for scan results
    Then the API should return scan metadata
    And the response should include vulnerability counts
    And the response should include severity levels
    And the response should show scan completion status

  @pipeline @fail-on-vulnerabilities
  Scenario Outline: Pipeline fails on vulnerabilities based on severity
    Given a container image with "<severity>" vulnerabilities
    And the Trivy scan is configured with severity "<filter>"
    When the Container Security Scan stage executes
    Then the pipeline should "<result>"

    Examples:
      | severity  | filter          | result  |
      | CRITICAL  | HIGH,CRITICAL   | fail    |
      | HIGH      | HIGH,CRITICAL   | fail    |
      | MEDIUM    | HIGH,CRITICAL   | pass    |
      | LOW       | HIGH,CRITICAL   | pass    |

  @sbom @compliance
  Scenario: Trivy generates Software Bill of Materials (SBOM)
    Given a container image is being scanned
    When Trivy is configured to generate SBOM
    Then an SBOM in SPDX format should be generated
    And the SBOM should list all OS packages
    And the SBOM should list all application dependencies
    And the SBOM should be archived for compliance

  @monitoring @metrics
  Scenario: Trivy scan metrics are collected
    Given Trivy scans are running in Jenkins and Harbor
    When scans complete
    Then scan duration metrics should be recorded
    And vulnerability count metrics should be recorded
    And scan success/failure metrics should be recorded
    And metrics should be exportable to Prometheus

  @configuration @policies
  Scenario: Trivy scan policies are configurable
    Given the Golden Path pipeline
    When I configure custom Trivy settings
    Then I can set custom severity levels
    And I can set custom exit codes
    And I can enable or disable scan stages
    And I can configure scan timeouts

  @database @updates
  Scenario: Trivy vulnerability database is up to date
    Given Trivy is deployed in Jenkins and Harbor
    When I check the Trivy database version
    Then the database should be less than 24 hours old
    And the database should contain latest CVE data
    And the database should update automatically

  @integration @end-to-end
  Scenario: Complete Trivy workflow from code commit to deployment
    Given a developer commits code to the main branch
    When the Jenkins pipeline executes
    Then the code should be built and tested
    And a Docker image should be created
    And Trivy should scan the image in Jenkins
    And the image should be pushed to Harbor if scan passes
    And Harbor should run a second Trivy scan
    And scan results should be visible in both Jenkins and Harbor
    And deployment should only proceed if no CRITICAL vulnerabilities found

  @dashboard @visibility
  Scenario: Trivy scan results are visible in dashboards
    Given multiple container images have been scanned
    When I view the security dashboard
    Then I should see vulnerability trends over time
    And I should see top vulnerable images
    And I should see severity distribution
    And I should see scan success rates

  @offline @air-gapped
  Scenario: Trivy works in offline mode (future)
    Given Trivy database is pre-downloaded
    And the cluster is air-gapped
    When Trivy scans an image
    Then it should use the cached database
    And the scan should complete successfully
    And no external network calls should be made
