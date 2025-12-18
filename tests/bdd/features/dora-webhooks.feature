@dora @webhooks @local
Feature: DORA Metrics Webhooks Configuration
  As a Platform Engineer
  I want to configure webhooks from GitHub, Jenkins, and ArgoCD to DevLake
  So that DORA metrics are collected automatically from all sources

  Background:
    Given the DevLake DORA metrics service is deployed
    And the DevLake service is accessible at "http://devlake.fawkes-devlake.svc:8080"

  @github @webhook
  Scenario: GitHub webhook sends commit events to DevLake
    Given a GitHub webhook is configured for the repository "paruff/fawkes"
    And the webhook points to "http://devlake.fawkes.idp/api/plugins/webhook/1/commits"
    When a developer pushes a commit to the main branch
    Then the GitHub webhook should fire successfully
    And DevLake should receive the commit event
    And the commit should be stored in the DevLake database
    And the commit timestamp should be recorded for lead time calculation

  @jenkins @webhook
  Scenario: Jenkins sends build events to DevLake via shared library
    Given the Jenkins shared library "doraMetrics.groovy" is available
    And the Jenkins pipeline includes "doraMetrics.recordBuild()" calls
    When a Jenkins build completes successfully
    Then the doraMetrics.recordBuild() function should be called
    And a webhook request should be sent to "http://devlake.fawkes-devlake.svc:8080/api/plugins/webhook/1/cicd"
    And DevLake should receive the build event
    And the build metrics should be stored for rework rate calculation

  @jenkins @webhook @quality-gate
  Scenario: Jenkins sends quality gate results to DevLake
    Given a Jenkins pipeline with SonarQube quality gate
    And the pipeline includes "doraMetrics.recordQualityGate()" calls
    When the quality gate analysis completes
    Then the doraMetrics.recordQualityGate() function should be called
    And DevLake should receive the quality gate event
    And the quality metrics should be stored for quality tracking

  @argocd @webhook @deployment
  Scenario: ArgoCD sends deployment success events to DevLake
    Given ArgoCD notifications are configured with DevLake webhook
    And the webhook URL is "http://devlake.fawkes-devlake.svc:8080/api/plugins/webhook/1/deployments"
    When ArgoCD successfully syncs an application
    Then ArgoCD should send a deployment success notification
    And DevLake should receive the deployment event
    And the deployment should be stored with timestamp for deployment frequency
    And the commit-to-deployment time should be calculated for lead time

  @argocd @webhook @failure
  Scenario: ArgoCD sends deployment failure events to DevLake
    Given ArgoCD notifications are configured with DevLake webhook
    When an ArgoCD sync fails
    Then ArgoCD should send a deployment failure notification
    And DevLake should receive the failure event
    And the failure should be counted toward change failure rate

  @incident @webhook
  Scenario: Observability platform sends incident events to DevLake
    Given the incident webhook endpoint is available at "/api/plugins/webhook/1/incidents"
    When a production incident is created in the observability system
    Then the observability system should send an incident webhook
    And DevLake should receive the incident event
    And the incident should be stored with creation timestamp for MTTR

  @incident @webhook @resolution
  Scenario: Incident resolution events update MTTR
    Given an open incident exists in DevLake
    When the incident is resolved in the observability system
    Then a webhook should be sent with the resolution timestamp
    And DevLake should update the incident status to "resolved"
    And the MTTR should be calculated from creation to resolution time

  @webhook @network
  Scenario: Webhook endpoints are accessible from all sources
    Given Jenkins pods are running in the "fawkes" namespace
    And ArgoCD is running in the "argocd" namespace
    And DevLake is running in the "fawkes-devlake" namespace
    When network policies are applied
    Then Jenkins should be able to reach DevLake webhook endpoint
    And ArgoCD should be able to reach DevLake webhook endpoint
    And external GitHub webhooks should be able to reach DevLake via ingress

  @webhook @security
  Scenario: GitHub webhook validates HMAC signatures
    Given a GitHub webhook is configured with a secret
    When GitHub sends a webhook request with an invalid signature
    Then DevLake should reject the request with 401 Unauthorized
    When GitHub sends a webhook request with a valid signature
    Then DevLake should accept and process the request

  @webhook @configuration
  Scenario: Webhook configuration files are present
    Given the platform repository contains webhook configurations
    Then the "webhooks.yaml" configuration should exist
    And the "argocd-notifications.yaml" configuration should exist
    And the "github-webhook-setup.md" documentation should exist
    And the "jenkins-webhook-setup.md" documentation should exist

  @webhook @monitoring
  Scenario: Webhook metrics are exposed to Prometheus
    Given DevLake is configured to expose Prometheus metrics
    When webhooks are received from various sources
    Then Prometheus should scrape webhook metrics
    And metrics should include:
      | metric                          | type      |
      | devlake_webhook_requests_total  | counter   |
      | devlake_webhook_duration_seconds| histogram |
      | devlake_webhook_errors_total    | counter   |

  @webhook @validation
  Scenario Outline: All webhook endpoints return correct HTTP codes
    Given DevLake is running and accessible
    When a valid <event_type> webhook is sent to <endpoint>
    Then the response should have HTTP status code <expected_code>
    And the response should contain a success indicator

    Examples:
      | event_type  | endpoint                                 | expected_code |
      | commit      | /api/plugins/webhook/1/commits          | 200           |
      | build       | /api/plugins/webhook/1/cicd             | 200           |
      | deployment  | /api/plugins/webhook/1/deployments      | 200           |
      | incident    | /api/plugins/webhook/1/incidents        | 200           |

  @webhook @retry
  Scenario: Webhook failures are logged but don't fail pipelines
    Given a Jenkins pipeline is running
    And the DevLake service is temporarily unavailable
    When the pipeline tries to send a webhook event
    Then the webhook should fail gracefully
    And the pipeline should continue execution
    And a warning should be logged about the webhook failure

  @webhook @integration
  Scenario: End-to-end webhook flow for a complete deployment
    Given a developer commits code to the main branch
    When the commit is pushed to GitHub
    Then GitHub sends a commit webhook to DevLake
    And Jenkins pipeline is triggered for the commit
    And Jenkins sends build events to DevLake
    And Jenkins sends test results to DevLake
    And Jenkins sends quality gate results to DevLake
    And ArgoCD detects the new image and syncs
    And ArgoCD sends deployment success webhook to DevLake
    Then all events should be correlated by commit SHA
    And DORA metrics should be calculated:
      | metric                  | should_exist |
      | Deployment Frequency    | true         |
      | Lead Time for Changes   | true         |
      | Change Failure Rate     | true         |
      | Build Success Rate      | true         |
