Feature: Tracer Bullet Observability
  As a platform engineer
  I want to verify that the tracer-bullet service emits traces, metrics, and logs
  So that the observability pipeline is validated end-to-end

  Background:
    Given the tracer-bullet service is running

  @unit @observability
  Scenario: Health endpoint returns success
    When I GET "/health"
    Then the response status is 200
    And the response body contains "ok"

  @unit @observability
  Scenario: Prometheus metrics are exposed
    When I GET "/metrics"
    Then the response status is 200
    And the response body contains "http_requests_total"
    And the response body contains "http_request_duration_seconds"

  @unit @observability
  Scenario: Custom span is created via demo endpoint
    When I GET "/demo/span"
    Then the response status is 200
    And the response body contains "trace_id"
    And the trace_id is a valid 128-bit hex string

  @unit @observability
  Scenario: Structured logs include trace context
    When I GET "/health"
    Then the logs contain "trace_id="
    And the logs contain "span_id="

  @unit @observability
  Scenario: Info endpoint returns service metadata
    When I GET "/info"
    Then the response status is 200
    And the response body contains "tracer-bullet"
    And the response body contains "version"
