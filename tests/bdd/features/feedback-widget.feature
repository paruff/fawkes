@feedback @backstage @api
Feature: Feedback Widget in Backstage
  As a platform user
  I want to submit feedback from within Backstage
  So that I can provide input on the platform experience

  Background:
    Given I have kubectl configured for the cluster
    And the feedback service is deployed in namespace "fawkes"

  @deployment @health
  Scenario: Feedback service is deployed and healthy
    When I check for the feedback-service deployment in namespace "fawkes"
    Then the deployment "feedback-service" should exist
    And the deployment should have at least 1 ready replica
    And the feedback service should be healthy

  @database
  Scenario: Feedback database is running
    When I check for the CloudNativePG cluster in namespace "fawkes"
    Then the cluster "db-feedback-dev" should exist
    And the database cluster should be ready

  @api @submit
  Scenario: Submit feedback successfully
    Given the feedback service is accessible
    When I submit feedback with rating 5 and category "UI/UX"
    Then the feedback should be accepted
    And the response should contain a feedback ID
    And the feedback status should be "open"

  @api @validation
  Scenario: Feedback submission validation
    Given the feedback service is accessible
    When I try to submit feedback with invalid rating 6
    Then the request should be rejected with validation error
    And the response should indicate rating must be between 1 and 5

  @api @admin @authorization
  Scenario: List feedback requires authorization
    Given the feedback service is accessible
    When I try to list feedback without authorization
    Then the request should be rejected with status 401

  @api @admin @list
  Scenario: Admin can list all feedback
    Given the feedback service is accessible
    And I have admin authorization
    When I list all feedback
    Then the request should be successful
    And the response should contain a list of feedback items

  @api @admin @status
  Scenario: Admin can update feedback status
    Given the feedback service is accessible
    And I have admin authorization
    And there is existing feedback with ID 1
    When I update feedback status to "resolved"
    Then the status update should be successful
    And the feedback status should be "resolved"

  @api @admin @stats
  Scenario: Admin can view feedback statistics
    Given the feedback service is accessible
    And I have admin authorization
    When I request feedback statistics
    Then the request should be successful
    And the response should contain total feedback count
    And the response should contain average rating
    And the response should contain feedback by category
    And the response should contain feedback by status

  @ingress @networking
  Scenario: Feedback service accessible via ingress
    When I check the ingress configuration in namespace "fawkes"
    Then an ingress should exist for "feedback-service"
    And the ingress should have host "feedback.127.0.0.1.nip.io"
    And the ingress should use ingressClassName "nginx"

  @backstage @proxy
  Scenario: Backstage proxy configured for feedback
    Given Backstage is deployed in namespace "fawkes"
    When I check the Backstage app-config
    Then the proxy should include endpoint "/feedback/api"
    And the proxy target should be "http://feedback-service.fawkes.svc:8000/"

  @metrics @observability
  Scenario: Feedback service exposes Prometheus metrics
    Given the feedback service is accessible
    When I request metrics from the feedback service
    Then the response should contain Prometheus metrics
    And metrics should include "feedback_submissions_total"
    And metrics should include "feedback_request_duration_seconds"

  @security @resources
  Scenario: Feedback service has resource limits
    When I check the feedback-service deployment in namespace "fawkes"
    Then the deployment should have CPU requests defined
    And the deployment should have memory requests defined
    And the deployment should have CPU limits defined
    And the deployment should have memory limits defined
    And the deployment should run as non-root user
