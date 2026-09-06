@golden-path @dora-deployment-frequency @dora-lead-time
Feature: Golden Path CI/CD Pipeline
  As a platform engineer
  I want to establish a standardized Golden Path pipeline
  So that application teams can consistently produce secure, tested container images

  Background:
    Given Jenkins is deployed via Kubernetes Ingress
    And the Fawkes shared library is configured
    And the DORA metrics service is available

  @smoke @security
  Scenario: Jenkins Access & Security
    Given Jenkins is deployed via Ingress
    And a Platform Engineer has valid credentials
    When an authenticated Platform Engineer accesses the Jenkins URL
    Then they are logged in via platform SSO/OAuth if available
    And all network traffic is secured with TLS
    And unauthorized access is denied

  @trunk-based @mandatory
  Scenario: Golden Path Enforcement on Main Branch
    Given a repository contains a Jenkinsfile calling the shared library
    And the repository has source code for a "java" application
    When a commit is pushed to the "main" branch
    Then the pipeline executes the mandatory sequence of stages
    And the stages include Checkout, Unit Test, BDD/Gherkin Test, Security Scan, Build Image, and Push Artifact
    And the pipeline completes successfully

  @bdd @testing
  Scenario: BDD Test Execution
    Given a repository includes Gherkin feature files
    And the repository has step definitions configured
    When the Golden Path pipeline runs the "BDD/Gherkin Test" stage
    Then the BDD tests are executed
    And the results are captured in Jenkins job results
    And a BDD test report is published
    And the pipeline fails if any BDD test fails

  @security @sonarqube
  Scenario: SonarQube Quality Gate
    Given the pipeline includes security scanning
    And SonarQube is configured
    When the Security Scan stage executes
    Then SonarQube analysis is performed
    And the pipeline waits for the quality gate
    And the pipeline fails if quality gate is not passed

  @security @trivy
  Scenario: Container Security Scan with Trivy
    Given a Docker image has been built
    When the Container Security Scan stage executes
    Then Trivy scans the image for vulnerabilities
    And vulnerabilities at HIGH or CRITICAL level cause failure
    And a scan report is archived

  @artifact @versioning
  Scenario: Artifact Generation & Versioning
    Given all tests and security scans pass
    When the Push Artifact stage executes
    Then a container image is built
    And the image is tagged with the Git SHA
    And the image is pushed to the internal registry
    And the image digest is recorded

  @gitops @argocd
  Scenario: GitOps Manifest Update
    Given the container image is pushed successfully
    When the Update GitOps stage executes
    Then the GitOps repository is updated with the new image tag
    And ArgoCD detects the manifest change
    And the deployment proceeds via GitOps

  @pr @fast-feedback @trunk-based-compliance
  Scenario: Trunk-Based Compliance - PR Validation Pipeline
    Given a developer creates a feature branch
    When a PR is opened against the "main" branch
    Then a lightweight non-artifact-producing pipeline runs
    And only unit tests and BDD tests are executed
    And no Docker image is built
    And no artifact is pushed
    And fast feedback is provided before merging
    And PR status is updated with results

  @dora @metrics
  Scenario: DORA Metrics Recording
    Given the pipeline has completed
    When metrics are recorded
    Then the build status is sent to DORA service
    And build duration is recorded
    And commit SHA is associated with the build
    And deployment frequency can be calculated

  @notification @mattermost
  Scenario: Build Notifications
    Given the pipeline completes
    When notifications are sent
    Then a message is posted to Mattermost
    And the message includes build status
    And the message includes a link to the build
    And the message includes commit information

  @language @java
  Scenario Outline: Language-Specific Build Commands
    Given a repository uses "<language>" as the primary language
    When the pipeline executes
    Then the build command "<build_command>" is used
    And the test command "<test_command>" is used
    And the BDD command "<bdd_command>" is used

    Examples:
      | language | build_command                           | test_command                                    | bdd_command                        |
      | java     | mvn clean package -DskipTests           | mvn test                                        | mvn verify -Pcucumber              |
      | python   | pip install -r requirements.txt         | pytest tests/unit --junitxml=test-results.xml   | behave --junit                     |
      | node     | npm ci && npm run build                 | npm test -- --ci                                | npm run test:bdd                   |
      | go       | go build -v ./...                       | go test -v ./...                                | go test -v ./features/...          |

  @failure @recovery
  Scenario: Pipeline Failure Handling
    Given a pipeline stage fails
    When the failure is detected
    Then the pipeline stops execution
    And a failure notification is sent
    And the failure is recorded in DORA metrics
    And console output is captured for debugging
    And the pipeline can be retried

  @configuration @override
  Scenario: Configuration Overrides
    Given a repository needs custom build commands
    When the Jenkinsfile specifies custom commands
    Then the custom build command is used
    And the custom test command is used
    And mandatory security stages still execute

  @pipeline-timeout
  Scenario: Pipeline Timeout
    Given a pipeline is configured with a timeout
    When the pipeline exceeds the timeout
    Then the pipeline is terminated
    And a timeout notification is sent
    And resources are cleaned up
