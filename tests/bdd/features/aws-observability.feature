Feature: AWS Observability Integration
  As a platform operator
  I want to monitor AWS infrastructure with native AWS observability services
  So that I can ensure optimal performance, cost efficiency, and security

  Background:
    Given an EKS cluster is deployed on AWS
    And the cluster name is "fawkes-prod"
    And the AWS region is "us-east-1"

  @aws @cloudwatch
  Scenario: CloudWatch logging is enabled for EKS control plane
    Given CloudWatch logging is configured for the EKS cluster
    When I check the EKS cluster logging configuration
    Then the following log types should be enabled:
      | Log Type            |
      | api                 |
      | audit               |
      | authenticator       |
      | controllerManager   |
      | scheduler           |
    And the log group "/aws/eks/fawkes-prod/cluster" should exist
    And the log retention should be set to 30 days

  @aws @cloudwatch @dashboards
  Scenario: CloudWatch dashboards are created
    Given the CloudWatch dashboards Terraform is applied
    When I list CloudWatch dashboards
    Then I should see the following dashboards:
      | Dashboard Name               |
      | fawkes-prod-eks-overview     |
      | fawkes-prod-eks-nodegroup    |
      | fawkes-prod-app-performance  |
      | fawkes-prod-cost-usage       |

  @aws @cloudwatch @alarms
  Scenario: Critical CloudWatch alarms are configured
    Given the CloudWatch alarms Terraform is applied
    When I list CloudWatch alarms for the cluster
    Then I should see the following alarms:
      | Alarm Name                              | Severity |
      | fawkes-prod-control-plane-cpu-high      | warning  |
      | fawkes-prod-control-plane-memory-high   | warning  |
      | fawkes-prod-node-cpu-critical           | critical |
      | fawkes-prod-node-memory-critical        | critical |
      | fawkes-prod-pod-restart-high            | warning  |
      | fawkes-prod-api-server-error-rate-high  | critical |
      | fawkes-prod-failed-pods-high            | critical |
      | fawkes-prod-node-disk-space-low         | warning  |

  @aws @sns @alerting
  Scenario: SNS topics are created for alerting
    Given the CloudWatch alarms Terraform is applied
    When I list SNS topics
    Then I should see the following topics:
      | Topic Name                    |
      | fawkes-prod-critical-alerts   |
      | fawkes-prod-warning-alerts    |
    And the topics should have encryption enabled

  @aws @sns @mattermost
  Scenario: SNS topics are integrated with Mattermost
    Given Mattermost webhook URL is configured
    And the CloudWatch alarms Terraform is applied
    When I check SNS topic subscriptions
    Then the "fawkes-prod-critical-alerts" topic should have a subscription
    And the subscription protocol should be "https"
    And the subscription endpoint should match the Mattermost webhook URL

  @aws @xray @deployment
  Scenario: X-Ray daemon is deployed as DaemonSet
    Given the X-Ray daemon YAML is applied
    When I check the DaemonSet status
    Then the DaemonSet "xray-daemon" should exist in namespace "aws-observability"
    And all nodes should have an X-Ray daemon pod running
    And the X-Ray daemon service should be accessible on port 2000

  @aws @xray @tracing
  Scenario: X-Ray tracing is operational
    Given the X-Ray daemon is running
    And an application is sending traces
    When I check X-Ray service map
    Then I should see trace data in X-Ray
    And the service map should show application relationships

  @aws @adot @deployment
  Scenario: ADOT collector is deployed
    Given the ADOT configuration is applied
    When I check the ADOT deployment status
    Then the deployment "adot-collector" should exist in namespace "aws-observability"
    And the deployment should have 2 replicas
    And all replicas should be ready
    And the ADOT collector service should be accessible

  @aws @adot @integration
  Scenario: ADOT collector integrates with multiple backends
    Given the ADOT collector is running
    When I check the ADOT configuration
    Then the following receivers should be configured:
      | Receiver   |
      | otlp       |
      | prometheus |
      | awsxray    |
    And the following exporters should be configured:
      | Exporter              |
      | awsxray               |
      | awscloudwatch         |
      | prometheusremotewrite |
      | jaeger                |

  @aws @adot @traces
  Scenario: Traces are visible in Jaeger via ADOT
    Given the ADOT collector is running
    And Jaeger is configured as an exporter
    And an application sends OTLP traces to ADOT
    When I query Jaeger for traces
    Then I should see traces from the application
    And traces should have AWS metadata enrichment

  @aws @costs @dashboard
  Scenario: AWS cost dashboard is available in Grafana
    Given the AWS cost dashboard is deployed to Grafana
    When I open Grafana
    And I navigate to dashboards
    Then I should see "AWS Cost Analysis" dashboard
    And the dashboard should have the following panels:
      | Panel Name                    |
      | Total Monthly Cost            |
      | Daily Cost Trend              |
      | Cost vs Budget                |
      | Projected Month-End Cost      |
      | Cost by Service (Top 10)      |
      | Cost by Resource (Top 10)     |
      | EKS Cluster Cost Breakdown    |

  @aws @costs @metrics
  Scenario: Cost metrics are collected and displayed
    Given the cost-collector service is running
    And Cost and Usage Reports are enabled
    When the cost-collector fetches CUR data
    Then Prometheus should have the following metrics:
      | Metric Name                       |
      | aws_cost_usage_blended_cost       |
      | aws_cost_optimization_savings_potential |
    And the metrics should be labeled with service and resource_id

  @aws @costs @integration
  Scenario: Cost data is integrated with Grafana
    Given the AWS cost dashboard is deployed
    And cost metrics are available in Prometheus
    When I view the "AWS Cost Analysis" dashboard
    Then I should see current month cost data
    And I should see cost breakdown by service
    And I should see cost optimization opportunities

  @aws @logs @queries
  Scenario: CloudWatch Logs Insights queries are available
    Given the log-insights-queries.json file exists
    When I parse the queries file
    Then I should see at least 20 pre-built queries
    And queries should be tagged by category
    And the following query categories should exist:
      | Category    |
      | eks         |
      | errors      |
      | performance |
      | security    |
      | cost        |

  @aws @logs @insights
  Scenario: CloudWatch Logs Insights queries can be executed
    Given EKS logs are flowing to CloudWatch
    And the "EKS API Server Errors" query is loaded
    When I execute the query against the EKS log group
    Then the query should return results
    And results should include timestamp and message fields
    And results should be sorted by timestamp descending

  @aws @security @audit
  Scenario: Security-related queries detect suspicious activities
    Given audit logs are enabled for the EKS cluster
    And the "Audit Log - Suspicious Activities" query is loaded
    When I execute the security query
    Then I should see activities filtered by security keywords
    And results should include user, verb, and resource fields
    And high-risk operations should be highlighted

  @aws @performance @latency
  Scenario: High latency API requests are identified
    Given API server logs are available in CloudWatch
    And the "High Latency API Requests" query is loaded
    When I execute the latency query
    Then I should see requests with latency over 1000ms
    And results should include average and max latency
    And results should be aggregated by time bin

  @aws @integration @prometheus
  Scenario: ADOT metrics are exported to Prometheus
    Given the ADOT collector is running
    And Prometheus Remote Write is configured
    When ADOT scrapes metrics from Kubernetes pods
    Then metrics should be forwarded to Prometheus
    And metrics should include cluster_name label
    And metrics should include AWS resource metadata

  @aws @integration @jaeger
  Scenario: ADOT traces are exported to Jaeger
    Given the ADOT collector is running
    And Jaeger endpoint is configured
    When an application sends traces to ADOT
    Then traces should be exported to Jaeger
    And traces should be enriched with AWS metadata
    And service map should show AWS service dependencies

  @aws @documentation
  Scenario: AWS observability documentation is comprehensive
    Given the AWS observability README exists
    When I review the documentation
    Then it should include architecture diagrams
    And it should include deployment instructions
    And it should include troubleshooting guides
    And it should include security considerations
    And it should include cost estimates
    And it should include example queries

  @aws @terraform @validation
  Scenario: Terraform configurations are valid
    Given the CloudWatch Terraform files exist
    When I run terraform validate
    Then there should be no validation errors
    And all required providers should be specified
    And provider versions should be >= 5.0.0

  @aws @resource @limits
  Scenario: ADOT and X-Ray pods have appropriate resource limits
    Given the ADOT collector is deployed
    And the X-Ray daemon is deployed
    When I check pod resource specifications
    Then ADOT collector should have:
      | Resource | Request | Limit |
      | CPU      | 200m    | 1000m |
      | Memory   | 512Mi   | 2Gi   |
    And X-Ray daemon should have:
      | Resource | Request | Limit |
      | CPU      | 100m    | 500m  |
      | Memory   | 128Mi   | 512Mi |

  @aws @security @irsa
  Scenario: Service accounts use IAM Roles for Service Accounts (IRSA)
    Given the X-Ray daemon is deployed
    And the ADOT collector is deployed
    When I check service account annotations
    Then X-Ray service account should have "eks.amazonaws.com/role-arn" annotation
    And ADOT service account should have "eks.amazonaws.com/role-arn" annotation
    And role ARNs should follow the naming convention

  @aws @health @probes
  Scenario: Health checks are configured for observability components
    Given the ADOT collector is deployed
    And the X-Ray daemon is deployed
    When I check pod health probes
    Then ADOT should have liveness probe on port 13133
    And ADOT should have readiness probe on port 13133
    And X-Ray should have liveness probe on port 2000
    And X-Ray should have readiness probe on port 2000

  @aws @cost @optimization
  Scenario: Cost optimization opportunities are identified
    Given the cost dashboard is displaying data
    When I view the "Cost Optimization Opportunities" section
    Then I should see "Idle Resources Cost" metric
    And I should see "Reserved Instance Coverage" percentage
    And I should see "Savings Plan Coverage" percentage
    And I should see "Potential Monthly Savings" estimate

  @aws @alerting @notification
  Scenario: CloudWatch alarms trigger Mattermost notifications
    Given a CloudWatch alarm is in ALARM state
    And SNS topic is integrated with Mattermost
    When the alarm triggers
    Then a notification should be sent to SNS topic
    And the notification should be forwarded to Mattermost
    And the Mattermost message should include:
      | Field           |
      | Alarm name      |
      | Current state   |
      | Metric details  |
      | Timestamp       |
      | Console link    |
