Feature: Event Tracking Infrastructure
  As a platform team member
  I want comprehensive event tracking across the platform
  So that I can understand user behavior and make data-driven decisions

  Background:
    Given the Plausible analytics platform is deployed
    And the event tracking library is initialized
    And Backstage is instrumented with event tracking

  @local
  Scenario: Event schema is defined and accessible
    When I import the event schema module
    Then the EventCategory enum should have at least 10 categories
    And the EventAction enum should have at least 20 actions
    And the PredefinedEvents object should have at least 60 events
    And each predefined event should have category, action, and label

  @local
  Scenario: Event tracking library is deployed and functional
    When I initialize the event tracker with valid configuration
    Then the tracker should be initialized successfully
    And the tracker status should show initialized as true
    And the Plausible script should be loaded
    And the script should have data-domain attribute

  @local
  Scenario: Tracking 60+ predefined events
    Given the event tracking library is initialized
    Then there should be at least 60 predefined events available:
      | Category        | Min Events |
      | navigation      | 5          |
      | scaffolding     | 10         |
      | documentation   | 6          |
      | cicd            | 12         |
      | feedback        | 8          |
      | feature_usage   | 6          |
      | error           | 5          |
      | performance     | 4          |
      | user            | 4          |
    And each event should have a unique identifier
    And each event should be properly categorized

  @local
  Scenario: Navigation events are tracked
    When a user views the homepage
    Then the "VIEW_HOMEPAGE" event should be tracked
    When a user views the service catalog
    Then the "VIEW_CATALOG" event should be tracked
    When a user searches the catalog with query "java service"
    Then the "SEARCH_CATALOG" event should be tracked with properties:
      | Property | Value        |
      | query    | java service |
    When a user views a service detail page
    Then the "VIEW_SERVICE" event should be tracked

  @local
  Scenario: Scaffolding events are tracked
    When a user starts the scaffolding workflow
    Then the "START_SCAFFOLDING" event should be tracked
    When a user selects the "Java" template
    Then the "SELECT_TEMPLATE" event should be tracked
    And the event should have property "template" equal to "java-service"
    When scaffolding completes successfully
    Then the "COMPLETE_SCAFFOLDING" event should be tracked
    When a user cancels scaffolding
    Then the "CANCEL_SCAFFOLDING" event should be tracked

  @local
  Scenario: Documentation events are tracked
    When a user views documentation page
    Then the "VIEW_DOCS" event should be tracked
    When a user searches documentation with "kubernetes"
    Then the "SEARCH_DOCS" event should be tracked
    And the query should be included in event properties
    When a user views TechDocs
    Then the "VIEW_TECHDOCS" event should be tracked
    When a user downloads documentation
    Then the "DOWNLOAD_DOCS" event should be tracked

  @local
  Scenario: CI/CD events are tracked
    When a user views a pipeline
    Then the "VIEW_PIPELINE" event should be tracked
    When a user triggers a build
    Then the "TRIGGER_BUILD" event should be tracked
    When a build completes successfully
    Then the "BUILD_COMPLETE" event should be tracked with duration
    When a build fails
    Then the "BUILD_FAILED" event should be tracked with error details
    When a user deploys an application
    Then the "DEPLOY_APPLICATION" event should be tracked with target environment

  @local
  Scenario: Deployment events are tracked
    When a deployment completes successfully
    Then the "DEPLOYMENT_COMPLETE" event should be tracked
    When a deployment fails
    Then the "DEPLOYMENT_FAILED" event should be tracked
    When ArgoCD performs a sync
    Then the "ARGOCD_SYNC" event should be tracked
    When ArgoCD performs a rollback
    Then the "ARGOCD_ROLLBACK" event should be tracked

  @local
  Scenario: Feedback events are tracked
    When a user opens the feedback widget
    Then the "OPEN_FEEDBACK_WIDGET" event should be tracked
    When a user submits feedback
    Then the "SUBMIT_FEEDBACK" event should be tracked
    When a user reports a bug
    Then the "REPORT_BUG" event should be tracked
    When a user requests a feature
    Then the "REQUEST_FEATURE" event should be tracked
    When a user logs a friction point
    Then the "FRICTION_LOG" event should be tracked

  @local
  Scenario: Feature usage events are tracked
    When a user interacts with Kubernetes plugin
    Then the "USE_KUBERNETES_PLUGIN" event should be tracked
    When a user interacts with ArgoCD plugin
    Then the "USE_ARGOCD_PLUGIN" event should be tracked
    When a user interacts with Grafana plugin
    Then the "USE_GRAFANA_PLUGIN" event should be tracked
    When a user exports data
    Then the "EXPORT_DATA" event should be tracked

  @local
  Scenario: Error events are tracked
    When a page load error occurs
    Then the "PAGE_ERROR" event should be tracked with error details
    When an API error occurs
    Then the "API_ERROR" event should be tracked with:
      | Property    | Example Value    |
      | endpoint    | /api/services    |
      | statusCode  | 500              |
      | errorCode   | INTERNAL_ERROR   |
    When a validation error occurs
    Then the "VALIDATION_ERROR" event should be tracked
    When an authentication error occurs
    Then the "AUTHENTICATION_ERROR" event should be tracked

  @local
  Scenario: Performance events are tracked
    When a page loads
    Then the "PAGE_LOAD" event should be tracked with duration
    When an API call completes
    Then the "API_RESPONSE" event should be tracked with response time
    When a slow operation is detected
    Then the "SLOW_OPERATION" event should be tracked
    When an operation times out
    Then the "TIMEOUT" event should be tracked

  @local
  Scenario: User events are tracked
    When a user logs in
    Then the "LOGIN" event should be tracked
    When a user logs out
    Then the "LOGOUT" event should be tracked
    When a user updates their profile
    Then the "UPDATE_PROFILE" event should be tracked
    When a user views their profile
    Then the "VIEW_PROFILE" event should be tracked

  @local
  Scenario: Event validation works correctly
    Given an event with valid structure
    When the event is validated
    Then validation should pass
    Given an event missing required category
    When the event is validated
    Then validation should fail with error message
    Given an event with non-serializable properties
    When the event is validated
    Then validation should fail

  @local
  Scenario: Events include proper context properties
    When any event is tracked
    Then the event should be validated before sending
    And the event should include timestamp
    And the event properties should be serializable
    And sensitive data should be sanitized
    When an event includes component context
    Then the event should have "component" property
    When an event includes user context
    Then the event should have "team" and "role" properties

  @local
  Scenario: Real-time streaming to Plausible works
    Given the event tracker is initialized
    When an event is tracked
    Then the event should be sent to Plausible immediately
    And the event should appear in Plausible dashboard within 30 seconds
    When multiple events are tracked in quick succession
    Then all events should be streamed in real-time
    And no events should be lost

  @local
  Scenario: Event middleware chain functions correctly
    Given a middleware chain with validation middleware
    When an invalid event is processed
    Then the event should be rejected
    Given a middleware chain with privacy middleware
    When an event with sensitive data is processed
    Then sensitive fields should be removed
    Given a middleware chain with enrichment middleware
    When an event is processed
    Then default properties should be added

  @local
  Scenario: Sampling middleware reduces event volume
    Given a sampling middleware with 10% sample rate
    When 100 events are tracked
    Then approximately 10 events should be sent to Plausible
    And the sample should be statistically random

  @local
  Scenario: Rate limiting prevents excessive events
    Given a rate limit of 100 events per minute
    When 150 events are tracked within one minute
    Then only 100 events should be sent
    And subsequent events should be rejected

  @local
  Scenario: Deduplication prevents duplicate events
    Given a deduplication window of 5 seconds
    When the same event is tracked twice within 5 seconds
    Then only the first event should be sent
    When the same event is tracked after 5 seconds
    Then both events should be sent

  @local
  Scenario: Privacy middleware protects sensitive data
    When an event with email field is tracked
    Then the email field should be removed
    When an event with password field is tracked
    Then the password field should be removed
    When an event with API key is tracked
    Then the API key should be removed
    When an event with long strings is tracked
    Then strings should be truncated to 500 characters

  @local
  Scenario: React hooks provide easy tracking interface
    Given a React component using useEventTracking hook
    When the component tracks an event
    Then the event should be sent successfully
    Given a component using usePageViewTracking hook
    When the component mounts
    Then a page view event should be tracked
    Given a component using useButtonClick hook
    When the button is clicked
    Then a click event should be tracked with button label

  @local
  Scenario: Form tracking hooks work end-to-end
    Given a form using useFormTracking hook
    When the form is displayed
    Then a "form.start" event should be tracked
    When the form is submitted successfully
    Then a "form.submit" event should be tracked
    When the form has validation errors
    Then a "form.error" event should be tracked with error details

  @local
  Scenario: Error tracking hooks capture exceptions
    Given a component using useErrorTracking hook
    When an error is thrown
    Then a PAGE_ERROR event should be tracked
    And the event should include error message and stack trace
    When an API call fails
    Then an API_ERROR event should be tracked
    And the event should include endpoint and status code

  @local
  Scenario: Event naming follows conventions
    When an event is formatted for tracking
    Then the name should follow pattern "{category}.{action}.{label}"
    And the name should use lowercase with underscores
    And the name should be unique within its category

  @local
  Scenario: Custom events can be tracked
    When a custom event "custom.action" is tracked
    Then the event should be sent to Plausible
    When a custom event with properties is tracked
    Then all properties should be included in the payload

  @local
  Scenario: Event properties are properly serialized
    When an event with string property is tracked
    Then the property should be sent as string
    When an event with number property is tracked
    Then the property should be sent as number
    When an event with boolean property is tracked
    Then the property should be sent as boolean
    When an event with undefined property is tracked
    Then the property should be omitted

  @local
  Scenario: Tracker handles offline scenarios gracefully
    Given the Plausible service is unavailable
    When events are tracked
    Then events should be queued
    When the Plausible service becomes available
    Then queued events should be sent

  @local
  Scenario: Debug mode provides detailed logging
    Given the tracker is initialized with debug mode enabled
    When an event is tracked
    Then debug logs should be written to console
    And the logs should include event details
    And the logs should include tracker state

  @local
  Scenario: Tracker can be enabled and disabled
    Given the tracker is initialized
    When tracking is disabled
    Then no events should be sent
    When tracking is re-enabled
    Then events should be sent normally

  @local
  Scenario: Tracker status can be queried
    When I query the tracker status
    Then I should receive initialization state
    And I should receive queue size
    And the status should reflect current state

  @local
  Scenario: Events are integrated with Plausible goals
    Given custom goals are configured in Plausible
    When tracked events match goal patterns
    Then goal conversions should be recorded
    And conversion rates should be calculated

  @local
  Scenario: Event tracking meets performance requirements
    When the tracker is initialized
    Then initialization should complete in under 100ms
    When an event is tracked
    Then the tracking call should complete in under 10ms
    And the tracking should not block the UI thread

  @local
  Scenario: Event tracking is GDPR compliant
    When events are tracked
    Then no cookies should be set
    And no personal identifiable information should be collected
    And all data should be anonymized
    And users should not require consent banners

  @local
  Scenario: Event tracking documentation is complete
    Given the event tracking README exists
    Then it should document all 60+ predefined events
    And it should include usage examples for each hook
    And it should explain middleware configuration
    And it should provide troubleshooting guidance
    And it should include integration instructions

  @local
  Scenario: AT-E3-007 acceptance test validation
    Given all event tracking infrastructure is deployed
    When I validate the complete system
    Then the event schema should be defined with 60+ events
    And the tracking library should be deployed and functional
    And all categories of events should be instrumented
    And event validation should work correctly
    And real-time streaming should be operational
    And middleware chain should function properly
    And React hooks should be available and tested
    And privacy controls should be in place
    And documentation should be complete
