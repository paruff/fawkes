Feature: Mattermost Feedback Bot
  As a platform user
  I want to submit feedback through Mattermost
  So that I can easily provide input using natural language

  Background:
    Given the feedback bot is deployed in the fawkes namespace
    And the feedback service is running
    And Mattermost is configured with the /feedback slash command

  @local @feedback-bot
  Scenario: Bot responds to help command
    When I send the slash command "/feedback" with no text
    Then I should receive help documentation
    And the help should explain the usage format
    And the help should include examples

  @local @feedback-bot
  Scenario: Submit positive feedback with natural language
    When I send the slash command "/feedback The new UI is amazing! Love the dark mode."
    Then the bot should analyze the sentiment as "positive"
    And the bot should categorize it as "UI"
    And the bot should assign a rating of 5 stars
    And the feedback should be submitted to the feedback service
    And I should receive a success message with analysis

  @local @feedback-bot
  Scenario: Submit negative feedback about performance
    When I send the slash command "/feedback Builds are taking 20+ minutes, way too slow"
    Then the bot should analyze the sentiment as "negative"
    And the bot should categorize it as "Performance" or "CI/CD"
    And the bot should assign a rating of 1-2 stars
    And the feedback should be submitted to the feedback service
    And I should receive a success message with analysis

  @local @feedback-bot
  Scenario: Submit feedback with explicit rating
    When I send the slash command "/feedback Rate it 5 stars! Documentation is excellent."
    Then the bot should extract the rating as 5 stars
    And the bot should analyze the sentiment as "positive"
    And the bot should categorize it as "Documentation"
    And the feedback should be submitted to the feedback service

  @local @feedback-bot
  Scenario: Submit feature request
    When I send the slash command "/feedback Would be great to have CSV export for metrics"
    Then the bot should analyze the sentiment as "neutral" or "positive"
    And the bot should categorize it as "Feature Request"
    And the feedback should be submitted to the feedback service

  @local @feedback-bot
  Scenario: Submit bug report
    When I send the slash command "/feedback The deployment fails with error 500"
    Then the bot should analyze the sentiment as "negative"
    And the bot should categorize it as "Bug" or "CI/CD"
    And the feedback should be submitted to the feedback service

  @local @feedback-bot
  Scenario: Bot health check
    When I check the bot health endpoint
    Then the health status should be "healthy"
    And the service name should be "feedback-bot"

  @local @feedback-bot
  Scenario: Bot exports Prometheus metrics
    When I query the bot metrics endpoint
    Then I should see "feedback_bot_logs_total" metric
    And I should see "feedback_bot_slash_commands_total" metric
    And I should see "feedback_bot_request_duration_seconds" metric

  @local @feedback-bot @integration
  Scenario: End-to-end feedback submission flow
    Given a test user in Mattermost
    When the user submits feedback via "/feedback Great platform, very helpful!"
    Then the feedback should appear in the feedback database
    And the feedback should have sentiment "positive"
    And the feedback should have a category assigned
    And the feedback should have a rating assigned
    And the Prometheus metrics should be updated
    And the feedback should be visible in Backstage dashboard

  @local @feedback-bot
  Scenario: Auto-categorization works for multiple categories
    When I send feedback about "The Jenkins build is slow"
    Then it should be categorized as "CI/CD" or "Performance"
    When I send feedback about "Need better API documentation"
    Then it should be categorized as "Documentation" or "API"
    When I send feedback about "Security vulnerability in dependencies"
    Then it should be categorized as "Security"

  @local @feedback-bot
  Scenario: Sentiment analysis accuracy
    When I send very positive feedback "This is absolutely amazing! Best platform ever!"
    Then the sentiment should be "positive" with high confidence
    When I send very negative feedback "This is terrible and completely broken"
    Then the sentiment should be "negative" with high confidence
    When I send neutral feedback "The system works as expected"
    Then the sentiment should be "neutral"

  @local @feedback-bot @error-handling
  Scenario: Bot handles API errors gracefully
    Given the feedback service is unavailable
    When I send the slash command "/feedback Test feedback"
    Then I should receive an error message
    And the error message should be user-friendly
    And the bot should not crash

  @local @feedback-bot
  Scenario: Bot validates token if configured
    Given the bot token is configured
    When I send a slash command with invalid token
    Then I should receive an "Invalid token" message
    When I send a slash command with valid token
    Then the feedback should be processed normally

  @local @feedback-bot
  Scenario: Feedback includes source metadata
    When I submit feedback via Mattermost
    Then the feedback record should include "mattermost" as the source
    And it should include the user's Mattermost username
    And it should include a timestamp
