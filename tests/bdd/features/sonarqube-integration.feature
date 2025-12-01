# tests/bdd/features/sonarqube-integration.feature

@sonarqube @code-quality @security
Feature: SonarQube Integration and Quality Gate Enforcement
  As a platform engineer
  I want to deploy and integrate SonarQube with the CI/CD pipeline
  So that code quality and security are automatically enforced

  Background:
    Given I have kubectl configured for the cluster
    And the PostgreSQL Operator is installed and running

  @service-deployment @persistence
  Scenario: Service Deployment & Persistence
    Given a dedicated PostgreSQL instance has been provisioned
    When the SonarQube Helm chart is deployed
    Then the service must start successfully
    And it must connect to the PostgreSQL backend
    And it must remain accessible via Ingress

  @jenkins-integration @golden-path
  Scenario: Jenkins Integration (Golden Path)
    Given the Jenkins Shared Library has been updated
    When a Golden Path pipeline executes the Security Scan stage
    Then the pipeline must successfully execute the SonarQube Scanner CLI against the source code
    And the results must be uploaded to SonarQube
    And the Quality Gate status must be obtained

  @quality-gate @success
  Scenario: Quality Gate Enforcement (Success)
    Given a new code commit meets the defined Quality Gate criteria
    When the Jenkins pipeline checks the status
    Then the pipeline must proceed successfully to the Build Image stage

  @quality-gate @failure
  Scenario: Quality Gate Enforcement (Failure)
    Given a new code commit introduces a critical security vulnerability
    When the Jenkins pipeline checks the status
    Then the pipeline must fail immediately
    And the SonarQube Quality Gate failure reason must be output in the build logs

  @developer-feedback @access
  Scenario: Developer Feedback & Access
    Given a pipeline run completes
    When a developer views the Jenkins build results
    Then a direct link to the corresponding SonarQube analysis report must be available
    And the developer can access the SonarQube UI using platform SSO/OAuth
