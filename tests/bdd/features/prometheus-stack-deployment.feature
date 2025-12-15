# tests/bdd/features/prometheus-stack-deployment.feature

@prometheus @observability @monitoring
Feature: kube-prometheus-stack Deployment
  As a platform engineer
  I want to deploy kube-prometheus-stack via ArgoCD with Grafana
  So that the platform has comprehensive metrics monitoring and alerting

  Background:
    Given I have kubectl configured for the cluster
    And the ingress-nginx controller is deployed and running

  @namespace
  Scenario: Prometheus deployed in monitoring namespace
    When I check for the monitoring namespace
    Then the namespace "monitoring" should exist
    And the namespace "monitoring" should be Active

  @argocd @application
  Scenario: Prometheus ArgoCD Application exists
    Given ArgoCD is deployed in namespace "fawkes"
    When I check for ArgoCD Application "prometheus-stack"
    Then the Application should exist in namespace "fawkes"
    And the Application should be Healthy
    And the Application should be Synced

  @pods @health
  Scenario: Prometheus Operator pods are running
    Given kube-prometheus-stack is deployed in namespace "monitoring"
    When I check the Prometheus pods
    Then the following pods should be running in namespace "monitoring":
      | component                      |
      | prometheus-operator           |
      | prometheus-prometheus         |
      | alertmanager-prometheus-alertmanager |
      | prometheus-grafana            |
      | prometheus-kube-state-metrics |
    And all Prometheus pods should be in Ready state within 300 seconds

  @prometheus @scraping
  Scenario: Prometheus is scraping metrics
    Given Prometheus is deployed and running
    When I query Prometheus for active targets
    Then Prometheus should have active scrape targets
    And the targets should include:
      | target_type              |
      | prometheus               |
      | node-exporter           |
      | kube-state-metrics      |
      | prometheus-operator     |

  @prometheus @storage
  Scenario: Prometheus persistent storage is configured
    Given Prometheus is deployed in namespace "monitoring"
    When I check the PersistentVolumeClaims in namespace "monitoring"
    Then a PVC for Prometheus should exist
    And the PVC should be Bound
    And the PVC size should be at least 20Gi

  @grafana @ui @accessibility
  Scenario: Grafana UI accessible via ingress
    Given Grafana is deployed with ingress enabled
    When I check the ingress configuration in namespace "monitoring"
    Then an ingress should exist for "prometheus-grafana"
    And the ingress should have host "grafana.127.0.0.1.nip.io"
    And the ingress should use ingressClassName "nginx"
    And the Grafana UI should be accessible at "http://grafana.127.0.0.1.nip.io"

  @grafana @authentication
  Scenario: Grafana admin login
    Given Grafana UI is accessible
    When I attempt to login with admin credentials
    Then I should successfully authenticate
    And I should see the Grafana dashboard

  @grafana @datasource
  Scenario: Prometheus datasource configured in Grafana
    Given Grafana is deployed and accessible
    When I check the Grafana datasources
    Then a Prometheus datasource should be configured
    And the datasource should be set as default
    And the datasource should be healthy

  @grafana @dashboards
  Scenario: Default Kubernetes dashboards are imported
    Given Grafana is deployed with default dashboards enabled
    When I query Grafana API for dashboards
    Then the following dashboards should exist:
      | dashboard_name                           |
      | Kubernetes / Compute Resources / Cluster |
      | Kubernetes / Compute Resources / Namespace (Pods) |
      | Node Exporter / Nodes                    |

  @alertmanager @ui
  Scenario: Alertmanager UI accessible via ingress
    Given Alertmanager is deployed with ingress enabled
    When I check the ingress configuration in namespace "monitoring"
    Then an ingress should exist for "alertmanager"
    And the ingress should have host "alertmanager.127.0.0.1.nip.io"
    And the Alertmanager UI should be accessible at "http://alertmanager.127.0.0.1.nip.io"

  @alertmanager @config
  Scenario: Alertmanager configuration is valid
    Given Alertmanager is deployed in namespace "monitoring"
    When I check the Alertmanager configuration
    Then the configuration should include route definitions
    And the configuration should include receiver definitions
    And Alertmanager should be ready to accept alerts

  @servicemonitor @argocd
  Scenario: ServiceMonitor for ArgoCD metrics
    Given ServiceMonitors are configured in namespace "monitoring"
    When I check for ServiceMonitor "argocd-server-metrics"
    Then the ServiceMonitor should exist
    And the ServiceMonitor should target namespace "fawkes"
    And Prometheus should be scraping ArgoCD metrics

  @servicemonitor @jenkins
  Scenario: ServiceMonitor for Jenkins metrics
    Given ServiceMonitors are configured in namespace "monitoring"
    When I check for ServiceMonitor "jenkins-metrics"
    Then the ServiceMonitor should exist
    And the ServiceMonitor should target namespace "fawkes"
    And Prometheus should be scraping Jenkins metrics

  @servicemonitor @postgresql
  Scenario: ServiceMonitor for PostgreSQL metrics
    Given ServiceMonitors are configured in namespace "monitoring"
    When I check for ServiceMonitor "postgresql-metrics"
    Then the ServiceMonitor should exist
    And Prometheus should be scraping PostgreSQL metrics from CloudNativePG clusters

  @servicemonitor @opentelemetry
  Scenario: ServiceMonitor for OpenTelemetry Collector
    Given ServiceMonitors are configured in namespace "monitoring"
    When I check for ServiceMonitor "otel-collector-metrics"
    Then the ServiceMonitor should exist
    And the ServiceMonitor should target namespace "monitoring"
    And Prometheus should be scraping OpenTelemetry Collector metrics

  @node-exporter
  Scenario: Node Exporter DaemonSet is running
    Given kube-prometheus-stack is deployed
    When I check for node-exporter pods
    Then node-exporter pods should be running on all nodes
    And each node should have exactly one node-exporter pod

  @kube-state-metrics
  Scenario: Kube State Metrics is collecting data
    Given kube-prometheus-stack is deployed
    When I query Prometheus for kube_state_metrics
    Then metrics should be available for:
      | metric_type        |
      | kube_pod_info     |
      | kube_node_info    |
      | kube_deployment_status_replicas |

  @prometheus @api
  Scenario: Prometheus API is functional
    Given Prometheus is deployed and accessible
    When I query the Prometheus API endpoint "/api/v1/query"
    Then I should receive a valid JSON response
    And the response should confirm Prometheus is operational

  @prometheus @rules
  Scenario: Alert rules are loaded
    Given Prometheus is deployed in namespace "monitoring"
    When I query Prometheus for loaded alert rules
    Then alert rules should be loaded
    And the rules should include Kubernetes cluster alerts
    And the rules should include node alerts

  @monitoring @platform
  Scenario: Platform components are being monitored
    Given kube-prometheus-stack is deployed and scraping metrics
    When I query Prometheus for metrics from platform components
    Then metrics should be available for:
      | component     |
      | argocd        |
      | jenkins       |
      | postgresql    |
      | backstage     |

  @resources
  Scenario: Prometheus components have resource limits
    Given kube-prometheus-stack is deployed in namespace "monitoring"
    When I check the resource specifications for Prometheus deployments
    Then all deployments should have CPU requests defined
    And all deployments should have memory requests defined
    And all deployments should have CPU limits defined
    And all deployments should have memory limits defined

  @persistence @alertmanager
  Scenario: Alertmanager persistent storage is configured
    Given Alertmanager is deployed in namespace "monitoring"
    When I check the PersistentVolumeClaims in namespace "monitoring"
    Then a PVC for Alertmanager should exist
    And the PVC should be Bound

  @remote-write
  Scenario: Prometheus supports remote write for OpenTelemetry
    Given Prometheus is deployed with remote write receiver enabled
    When I check the Prometheus configuration
    Then the remote write receiver should be enabled
    And OpenTelemetry Collector should be able to push metrics to Prometheus
