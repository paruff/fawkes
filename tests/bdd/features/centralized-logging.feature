Feature: Centralized Log Management with OpenTelemetry
  As a platform engineer
  I want centralized, structured logging for all Kubernetes workloads using OpenTelemetry Collector and OTLP
  So that I can reliably correlate log events with traces and metrics, accelerating Mean Time to Resolution (MTTR)

  Background:
    Given I have a Kubernetes cluster with OpenTelemetry Collector deployed as a DaemonSet
    And I have OpenSearch configured as the log backend
    And the logging namespace exists

  @local @log-forwarding
  Scenario: Log Forwarding - Container logs are collected and forwarded
    Given an application pod generates a log message to stdout/stderr
    When the message is emitted
    Then the OpenTelemetry Collector Agent on that node must ingest the log
    And the log record must be forwarded via OTLP to the OpenSearch backend
    And the log should be searchable in OpenSearch within 30 seconds

  @local @kubernetes-enrichment
  Scenario: Kubernetes Context Enrichment - Logs contain mandatory resource attributes
    Given a raw application log is collected by the OpenTelemetry Collector
    When the k8sattributes processor runs
    Then the final log record stored in OpenSearch must contain "k8s.pod.name"
    And the log record must contain "k8s.namespace.name"
    And the log record must contain "k8s.container.name"
    And the log record should contain "k8s.deployment.name" if applicable

  @local @trace-correlation
  Scenario: Trace Correlation - Logs include trace context
    Given an application is instrumented to use the active trace context
    And the W3C traceparent header is set
    When an application log is generated during that traced operation
    Then the resulting log record stored in OpenSearch must include the "traceId"
    And the log record must include the "spanId" for immediate correlation

  @local @searchability
  Scenario: Access and Searchability - Logs are searchable within SLA
    Given an authorized Platform Engineer accesses the OpenSearch Dashboards interface
    And there are logs from a specific deployment
    When they search for logs from that k8s.deployment.name
    Then the logs should be returned within 3 seconds

  @local @failure-handling
  Scenario: Failure Handling - Agent handles backend unavailability
    Given the OpenTelemetry Collector Agent is configured with memory_limiter
    And the agent has batch processor with queue enabled
    When the OpenSearch backend becomes temporarily unavailable
    And applications continue to generate logs for 5 minutes
    Then the Collector Agent must buffer logs during the outage
    And upon recovery logs should be forwarded without data loss

  @local @structured-logging
  Scenario: Structured Logging - JSON logs are parsed correctly
    Given an application emits a structured JSON log with fields
      | field     | value                           |
      | level     | INFO                            |
      | message   | User login successful           |
      | traceId   | a1b2c3d4e5f6789012345678901234 |
      | spanId    | 1234567890abcdef                |
      | userId    | user-123                        |
    When the log is collected by the OpenTelemetry Collector
    Then the JSON fields should be extracted and indexed
    And the log should be searchable by traceId
    And the log should be searchable by userId

  @local @multi-tenancy
  Scenario: Multi-tenancy - Logs are isolated by namespace
    Given logs exist from namespace "team-alpha" and "team-beta"
    When a user with access only to "team-alpha" namespace queries logs
    Then they should only see logs from "team-alpha" namespace
    And logs from "team-beta" should not be visible

  @local @health-check
  Scenario: Health Check - OpenTelemetry Collector is healthy
    Given the OpenTelemetry Collector is deployed
    When I check the health endpoint at port 13133
    Then the health check should return status "healthy"
    And the zpages endpoint should be accessible at port 55679

  @local @log-volume
  Scenario: Log Volume Dashboard - Dashboard shows log statistics
    Given logs are being collected from multiple pods
    When I access the OpenSearch Dashboards
    Then I should see a dashboard showing log volume over time
    And I should be able to filter logs by namespace
    And I should be able to filter logs by severity level
