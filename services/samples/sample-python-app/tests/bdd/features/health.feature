Feature: Health Check
  As a platform operator
  I want to check the service health
  So that I can monitor service availability

  Scenario: Service health check returns UP
    When I request the health endpoint
    Then the response status should be 200
    And the response should contain status "UP"
    And the response should contain service "sample-python-app"

  Scenario: Service readiness check returns READY
    When I request the ready endpoint
    Then the response status should be 200
    And the response should contain status "READY"

  Scenario: Service info endpoint returns details
    When I request the info endpoint
    Then the response status should be 200
    And the response should contain name "sample-python-app"
    And the response should contain version "0.1.0"
