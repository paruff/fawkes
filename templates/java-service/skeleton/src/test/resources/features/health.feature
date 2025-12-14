Feature: Health Check
  As a platform operator
  I want to check the service health
  So that I can monitor service availability

  Scenario: Service health check returns OK
    When I request the health endpoint
    Then the response status should be 200
    And the response should contain status "UP"
    And the response should contain service name "${{ values.name }}"

  Scenario: Service info endpoint returns service details
    When I request the info endpoint
    Then the response status should be 200
    And the response should contain name "${{ values.name }}"
    And the response should contain version "0.1.0"
