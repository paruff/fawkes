Feature: GCP Observability Integration
  As a platform operator
  I want to monitor GCP infrastructure with native GCP observability services
  So that I can ensure optimal performance, cost efficiency, and security

  Background:
    Given a GKE cluster is deployed on GCP
    And the cluster name is "fawkes-prod"
    And the GCP project ID is "fawkes-platform"
    And the GCP region is "us-central1"

  @gcp @cloudmonitoring
  Scenario: Cloud Monitoring is enabled for GKE cluster
    Given Cloud Monitoring is configured for the GKE cluster
    When I check the GKE cluster monitoring configuration
    Then Cloud Monitoring should be enabled
    And metrics should be exported to Cloud Monitoring

  @gcp @cloudmonitoring @dashboards
  Scenario: Cloud Monitoring dashboards are created
    Given the Cloud Monitoring dashboards Terraform is applied
    When I list Cloud Monitoring dashboards
    Then I should see the following dashboards:
      | Dashboard Name                     |
      | fawkes-prod-gke-overview          |
      | fawkes-prod-gke-node-performance  |
      | fawkes-prod-app-performance       |
      | fawkes-prod-cost-usage            |

  @gcp @cloudmonitoring @alerts
  Scenario: Critical Cloud Monitoring alert policies are configured
    Given the Cloud Monitoring alert policies Terraform is applied
    When I list alert policies for the cluster
    Then I should see the following alert policies:
      | Alert Policy Name                      | Severity |
      | fawkes-prod-control-plane-cpu-high     | warning  |
      | fawkes-prod-control-plane-memory-high  | warning  |
      | fawkes-prod-node-cpu-critical          | critical |
      | fawkes-prod-node-memory-critical       | critical |
      | fawkes-prod-pod-restart-high           | warning  |
      | fawkes-prod-api-server-error-rate-high | critical |
      | fawkes-prod-failed-pods-high           | critical |
      | fawkes-prod-node-disk-space-low        | warning  |

  @gcp @pubsub @alerting
  Scenario: Pub/Sub topics are created for alerting
    Given the Cloud Monitoring alert policies Terraform is applied
    When I list Pub/Sub topics
    Then I should see the following topics:
      | Topic Name                   |
      | fawkes-prod-critical-alerts  |
      | fawkes-prod-warning-alerts   |
      | fawkes-prod-cost-alerts      |

  @gcp @pubsub @mattermost
  Scenario: Pub/Sub topics are integrated with Mattermost
    Given Mattermost webhook URL is configured
    And the Cloud Monitoring alert policies Terraform is applied
    When I check Pub/Sub subscriptions
    Then the "fawkes-prod-mattermost-critical-sub" subscription should exist
    And the subscription should be a push subscription
    And the push endpoint should match the Mattermost webhook URL

  @gcp @pubsub @cost-collector
  Scenario: Pub/Sub topics are integrated with cost-collector
    Given the cost-collector service is deployed
    And the Cloud Monitoring alert policies Terraform is applied
    When I check Pub/Sub subscriptions
    Then the "fawkes-prod-cost-collector-sub" subscription should exist
    And the subscription should be a push subscription
    And the push endpoint should match the cost-collector endpoint

  @gcp @logging @deployment
  Scenario: Cloud Logging is configured for GKE cluster
    Given Cloud Logging is enabled for the GKE cluster
    When I check the logging configuration
    Then logs should be exported to Cloud Logging
    And the following log types should be collected:
      | Log Type       |
      | container      |
      | system         |
      | events         |
      | audit          |

  @gcp @logging @sinks
  Scenario: Log sinks are configured
    Given the log sinks Terraform is applied
    When I list log sinks
    Then I should see the following log sinks:
      | Sink Name                    | Destination Type |
      | fawkes-prod-gke-to-storage   | Cloud Storage    |
      | fawkes-prod-gke-to-bigquery  | BigQuery         |
      | fawkes-prod-app-to-storage   | Cloud Storage    |
      | fawkes-prod-errors-to-pubsub | Pub/Sub          |

  @gcp @logging @storage
  Scenario: Log storage bucket is configured with lifecycle
    Given the log sinks Terraform is applied
    When I check the log storage bucket configuration
    Then the bucket should have lifecycle rules configured:
      | Age (days) | Action           | Storage Class |
      | 90         | SetStorageClass  | NEARLINE      |
      | 365        | SetStorageClass  | COLDLINE      |
      | 730        | Delete           | N/A           |

  @gcp @logging @bigquery
  Scenario: Logs are exported to BigQuery
    Given the log sinks Terraform is applied
    When I check the BigQuery dataset
    Then the dataset "fawkes_prod_logs" should exist
    And the dataset should use partitioned tables
    And the default table expiration should be 90 days

  @gcp @logging @opensearch
  Scenario: Error logs are integrated with OpenSearch
    Given OpenSearch endpoint is configured
    And the log sinks Terraform is applied
    When I check the error logs Pub/Sub topic
    Then a subscription should exist for OpenSearch
    And the subscription should be a push subscription

  @gcp @logging @metrics
  Scenario: Log-based metrics are created
    Given the log sinks Terraform is applied
    When I list log-based metrics
    Then I should see the following metrics:
      | Metric Name                          |
      | fawkes_prod_failed_pods              |
      | fawkes_prod_api_server_errors        |
      | fawkes_prod_request_latency          |
      | fawkes_prod_http_status              |
      | fawkes_prod_db_query_duration        |
      | fawkes_prod_error_by_type            |

  @gcp @otel @deployment
  Scenario: OpenTelemetry Collector is deployed
    Given the OpenTelemetry Collector configuration is applied
    When I check the deployment status
    Then the deployment "otel-collector" should exist in namespace "gcp-observability"
    And the deployment should have 2 replicas
    And all replicas should be ready
    And the OpenTelemetry Collector service should be accessible

  @gcp @otel @integration
  Scenario: OpenTelemetry Collector integrates with multiple backends
    Given the OpenTelemetry Collector is running
    When I check the OpenTelemetry Collector configuration
    Then the following receivers should be configured:
      | Receiver              |
      | otlp                  |
      | prometheus            |
      | googlecloudmonitoring |
    And the following exporters should be configured:
      | Exporter              |
      | googlecloud           |
      | jaeger                |
      | prometheusremotewrite |

  @gcp @otel @traces
  Scenario: Traces are visible in Jaeger via OpenTelemetry Collector
    Given the OpenTelemetry Collector is running
    And Jaeger is configured as an exporter
    And an application sends OTLP traces to OpenTelemetry Collector
    When I query Jaeger for traces
    Then I should see traces from the application
    And traces should have GCP metadata enrichment
    And traces should include cluster_name label

  @gcp @cloudtrace
  Scenario: Traces are exported to Cloud Trace
    Given the OpenTelemetry Collector is running
    And Cloud Trace is configured as an exporter
    And an application sends OTLP traces to OpenTelemetry Collector
    When I query Cloud Trace for traces
    Then I should see traces from the application
    And traces should have GCP resource metadata
    And service map should show application relationships

  @gcp @costs @dashboard
  Scenario: GCP cost dashboard is available in Grafana
    Given the GCP cost dashboard is deployed to Grafana
    When I open Grafana
    And I navigate to dashboards
    Then I should see "GCP Cost Analysis" dashboard
    And the dashboard should have the following panels:
      | Panel Name                    |
      | Total Monthly Cost            |
      | Daily Cost Trend              |
      | Cost vs Budget                |
      | Projected Month-End Cost      |
      | Cost by Service (Top 10)      |
      | Cost by Resource (Top 10)     |
      | GKE Cluster Costs             |
      | Idle Resources Cost           |
      | Cost Anomalies Detected       |

  @gcp @costs @metrics
  Scenario: Cost metrics are collected and displayed
    Given the cost-collector service is running
    And Cloud Billing export to BigQuery is enabled
    When the cost-collector fetches billing data from BigQuery
    Then Prometheus should have the following metrics:
      | Metric Name                                   |
      | gcp_cost_usage_blended_cost                   |
      | gcp_cost_optimization_savings_potential       |
      | gcp_cost_optimization_idle_resource_cost      |
      | gcp_cost_cud_covered_cost                     |
      | gcp_cost_sustained_use_discount_savings       |
      | gcp_cost_anomaly                              |
    And the metrics should be labeled with service and resource_id

  @gcp @costs @integration
  Scenario: Cost data is integrated with Grafana
    Given the GCP cost dashboard is deployed
    And cost metrics are available in Prometheus
    When I view the "GCP Cost Analysis" dashboard
    Then I should see current month cost data
    And I should see cost breakdown by service
    And I should see cost breakdown by region
    And I should see cost optimization opportunities

  @gcp @costs @anomaly
  Scenario: Cost anomalies are detected
    Given the cost anomaly detection alert policy is configured
    And cost data is flowing from BigQuery
    When an unusual cost spike occurs
    Then a cost anomaly alert should be triggered
    And the alert should be sent to the cost alerts Pub/Sub topic
    And the cost-collector service should receive the alert

  @gcp @uptime @checks
  Scenario: Uptime checks are configured for critical endpoints
    Given the uptime checks Terraform is applied
    When I list uptime checks
    Then an uptime check should exist for the GKE API server
    And the check should monitor the /healthz endpoint
    And the check interval should be 60 seconds

  @gcp @uptime @alerts
  Scenario: Uptime check failures trigger alerts
    Given an uptime check is configured for the GKE API server
    And the uptime check alert policy is configured
    When the uptime check fails
    Then an alert should be triggered
    And the alert should be sent to the critical alerts Pub/Sub topic

  @gcp @integration @prometheus
  Scenario: OpenTelemetry Collector metrics are exported to Prometheus
    Given the OpenTelemetry Collector is running
    And Prometheus Remote Write is configured
    When OpenTelemetry Collector scrapes metrics from Kubernetes pods
    Then metrics should be forwarded to Prometheus
    And metrics should include cluster_name label
    And metrics should include GCP resource metadata

  @gcp @integration @jaeger
  Scenario: OpenTelemetry Collector traces are exported to Jaeger
    Given the OpenTelemetry Collector is running
    And Jaeger endpoint is configured
    When an application sends traces to OpenTelemetry Collector
    Then traces should be exported to Jaeger
    And traces should be enriched with GCP metadata
    And service map should show GCP service dependencies

  @gcp @documentation
  Scenario: GCP observability documentation is comprehensive
    Given the GCP observability README exists
    When I review the documentation
    Then it should include architecture diagrams
    And it should include deployment instructions
    And it should include Terraform examples
    And it should include troubleshooting guides
    And it should include security considerations
    And it should include cost estimates
    And it should include IAM configuration examples

  @gcp @terraform @validation
  Scenario: Terraform configurations are valid
    Given the Cloud Monitoring Terraform files exist
    And the Cloud Logging Terraform files exist
    When I run terraform validate
    Then there should be no validation errors
    And all required providers should be specified
    And provider versions should be >= 5.0.0

  @gcp @resource @limits
  Scenario: OpenTelemetry Collector pods have appropriate resource limits
    Given the OpenTelemetry Collector is deployed
    When I check pod resource specifications
    Then OpenTelemetry Collector should have:
      | Resource | Request | Limit |
      | CPU      | 200m    | 1000m |
      | Memory   | 512Mi   | 2Gi   |

  @gcp @security @workload-identity
  Scenario: Service accounts use Workload Identity
    Given the OpenTelemetry Collector is deployed
    When I check service account annotations
    Then OpenTelemetry Collector service account should have "iam.gke.io/gcp-service-account" annotation
    And the annotation should reference a GCP service account

  @gcp @health @probes
  Scenario: Health checks are configured for observability components
    Given the OpenTelemetry Collector is deployed
    When I check pod health probes
    Then OpenTelemetry Collector should have liveness probe on port 13133
    And OpenTelemetry Collector should have readiness probe on port 13133

  @gcp @cost @optimization
  Scenario: Cost optimization opportunities are identified
    Given the cost dashboard is displaying data
    When I view the "Cost Optimization" section
    Then I should see "Idle Resources Cost" metric
    And I should see "Committed Use Discount Coverage" percentage
    And I should see "Sustained Use Discount Savings" amount
    And I should see "Potential Monthly Savings" estimate

  @gcp @alerting @notification
  Scenario: Cloud Monitoring alerts trigger Pub/Sub notifications
    Given a Cloud Monitoring alert policy is in ALARM state
    And Pub/Sub notification channel is configured
    When the alert triggers
    Then a message should be published to the Pub/Sub topic
    And the message should include incident details
    And Mattermost should receive the notification

  @gcp @billing @export
  Scenario: Cloud Billing data is exported to BigQuery
    Given Cloud Billing export is enabled
    When billing data is generated
    Then data should be exported to the billing BigQuery dataset
    And data should include cost by service
    And data should include cost by SKU
    And data should include resource labels

  @gcp @monitoring @slo
  Scenario: Service Level Objectives are monitored
    Given SLOs are configured in Cloud Monitoring
    When I check SLO compliance
    Then availability SLO should be tracked
    And latency SLO should be tracked
    And error rate SLO should be tracked
    And SLO burn rate alerts should be configured
