Feature: Jenkins Pipeline Creation
  As a platform engineer
  I want to automatically provision Jenkins pipelines for new projects
  So that developers can immediately start CI/CD workflows

  Background:
    Given the Fawkes platform is deployed
    And Jenkins is running and accessible
    And I have admin credentials for Jenkins

  @smoke @dora-deployment-frequency
  Scenario: Create a basic CI pipeline for a Spring Boot application
    Given a new Spring Boot project repository "sample-app"
    And the repository has a Jenkinsfile
    When I request a new workspace through Fawkes
    Then a Jenkins multibranch pipeline should be created
    And the pipeline should be named "sample-app-pipeline"
    And the pipeline should scan the repository for branches
    And the pipeline should trigger on the main branch
    And the initial build should complete successfully within 5 minutes

  @integration
  Scenario: Pipeline includes required stages for DORA metrics
    Given a Jenkins pipeline exists for project "sample-app"
    When I view the pipeline configuration
    Then the pipeline should include a "Build" stage
    And the pipeline should include a "Test" stage
    And the pipeline should include a "Security Scan" stage
    And the pipeline should include a "Deploy to Dev" stage
    And each stage should report metrics to the DORA dashboard

  @security
  Scenario: Pipeline uses secure credential management
    Given a Jenkins pipeline requires AWS credentials
    When the pipeline is configured through Fawkes
    Then credentials should be stored in Jenkins credential store
    And credentials should not be visible in pipeline logs
    And credentials should use IRSA for AWS access
    And the pipeline should fail if credentials are not available

  @failure-recovery @dora-mttr
  Scenario: Failed pipeline can be quickly diagnosed
    Given a Jenkins pipeline for "sample-app"
    When the pipeline fails at the "Test" stage
    Then the failure should be reported within 1 minute
    And the console output should be captured
    And the failure notification should include a link to logs
    And the pipeline should support immediate retry
    And the time to diagnose should be tracked for MTTR metrics