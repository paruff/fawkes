# tests/bdd/features/opentelemetry-deployment.feature

@opentelemetry @observability @traces
Feature: OpenTelemetry Collector Deployment
  As a platform engineer
  I want to deploy OpenTelemetry Collector as a DaemonSet with receivers and exporters configured
  So that the platform can collect traces, metrics, and logs from applications

  Background:
    Given I have kubectl configured for the cluster
    And the monitoring namespace exists

  @namespace
  Scenario: OpenTelemetry deployed in monitoring namespace
    When I check for the monitoring namespace
    Then the namespace "monitoring" should exist
    And the namespace "monitoring" should be Active

  @argocd @application
  Scenario: OpenTelemetry ArgoCD Application exists
    Given ArgoCD is deployed in namespace "fawkes"
    When I check for ArgoCD Application "otel-collector"
    Then the Application should exist in namespace "fawkes"
    And the Application should be Healthy
    And the Application should be Synced

  @daemonset @deployment
  Scenario: OpenTelemetry Collector deployed as DaemonSet
    Given OpenTelemetry Collector is deployed
    When I check for DaemonSet "otel-collector-opentelemetry-collector" in namespace "monitoring"
    Then the DaemonSet should exist
    And the DaemonSet should be running on all schedulable nodes
    And all DaemonSet pods should be in Ready state within 300 seconds

  @receivers @otlp
  Scenario: OTLP receivers are configured and accessible
    Given OpenTelemetry Collector is running
    When I check the OTLP receiver ports
    Then port 4317 should be exposed for OTLP gRPC
    And port 4318 should be exposed for OTLP HTTP
    And the OTLP receivers should be accepting connections

  @receivers @prometheus
  Scenario: Prometheus receiver is configured
    Given OpenTelemetry Collector configuration is deployed
    When I check the collector configuration
    Then the Prometheus receiver should be configured
    And the receiver should scrape pods with prometheus.io/scrape=true annotation
    And the receiver should include Kubernetes metadata in scraped metrics

  @exporters @prometheus
  Scenario: Prometheus exporter is configured
    Given OpenTelemetry Collector is deployed
    When I check the collector configuration for exporters
    Then the prometheusremotewrite exporter should be configured
    And the exporter should target "prometheus-prometheus.monitoring.svc.cluster.local:9090"
    And metrics should be exportable to Prometheus

  @exporters @opensearch
  Scenario: OpenSearch exporter is configured for logs
    Given OpenTelemetry Collector is deployed
    When I check the collector configuration for exporters
    Then the opensearch exporter should be configured
    And the exporter should target "opensearch-cluster-master.logging.svc.cluster.local:9200"
    And logs should be exportable to OpenSearch

  @exporters @tempo
  Scenario: Tempo exporter is configured for traces
    Given OpenTelemetry Collector is deployed
    When I check the collector configuration for exporters
    Then the otlp/tempo exporter should be configured
    And the exporter should target "tempo.monitoring.svc.cluster.local:4317"
    And traces should be exportable to Tempo

  @pipelines @metrics
  Scenario: Metrics pipeline is configured
    Given OpenTelemetry Collector is deployed
    When I check the service pipelines configuration
    Then a metrics pipeline should exist
    And the pipeline should include receivers: otlp, prometheus, kubeletstats, hostmetrics
    And the pipeline should include processors: memory_limiter, k8sattributes, resourcedetection, transform, batch
    And the pipeline should export to prometheusremotewrite

  @pipelines @logs
  Scenario: Logs pipeline is configured
    Given OpenTelemetry Collector is deployed
    When I check the service pipelines configuration
    Then a logs pipeline should exist
    And the pipeline should include receivers: filelog, otlp
    And the pipeline should include processors: memory_limiter, attributes/logs, k8sattributes, resourcedetection, transform/logs, batch/logs
    And the pipeline should export to opensearch

  @pipelines @traces
  Scenario: Traces pipeline is configured
    Given OpenTelemetry Collector is deployed
    When I check the service pipelines configuration
    Then a traces pipeline should exist
    And the pipeline should include receiver: otlp
    And the pipeline should include processors: memory_limiter, probabilistic_sampler, k8sattributes, resourcedetection, attributes/traces, transform/traces, batch/traces
    And the pipeline should export to otlp/tempo

  @health @endpoints
  Scenario: Health check and diagnostic endpoints are accessible
    Given OpenTelemetry Collector is running
    When I check the health endpoint at port 13133
    Then the health check should return status "healthy"
    And the zpages diagnostic endpoint should be accessible at port 55679

  @kubernetes @enrichment
  Scenario: Kubernetes attributes processor is configured
    Given OpenTelemetry Collector is deployed
    When I check the k8sattributes processor configuration
    Then the processor should extract metadata: k8s.namespace.name, k8s.pod.name, k8s.container.name
    And the processor should extract labels: app, service_name, component, version
    And the processor should use serviceAccount for authentication

  @sample-traces @integration
  Scenario: Sample application generates traces
    Given a sample instrumented application is deployed
    When the application processes a request
    Then traces should be sent to the OTLP receiver at port 4317
    And the traces should include service.name attribute
    And the traces should include span with operation name
    And the traces should be exported to Tempo

  @sample-traces @correlation
  Scenario: Traces are enriched with Kubernetes metadata
    Given a sample instrumented application is deployed in namespace "default"
    When the application generates a trace
    Then the trace should be enriched with k8s.namespace.name="default"
    And the trace should include k8s.pod.name attribute
    And the trace should include k8s.deployment.name attribute if applicable
    And the enriched trace should be queryable in Tempo

  @monitoring @metrics
  Scenario: OpenTelemetry Collector exposes self-metrics
    Given OpenTelemetry Collector is running
    When I query the metrics endpoint at port 8888
    Then Prometheus metrics should be exposed
    And metrics should include otelcol_receiver_accepted_spans
    And metrics should include otelcol_receiver_refused_spans
    And metrics should include otelcol_exporter_sent_spans

  @resources
  Scenario: OpenTelemetry Collector has resource limits
    Given OpenTelemetry Collector DaemonSet is deployed
    When I check the resource specifications
    Then CPU requests should be defined as 200m
    And memory requests should be defined as 512Mi
    And CPU limits should be defined as 1000m
    And memory limits should be defined as 1Gi

  @security @context
  Scenario: OpenTelemetry Collector runs with security context
    Given OpenTelemetry Collector DaemonSet is deployed
    When I check the security context
    Then the pod should run as non-root user (10001)
    And allowPrivilegeEscalation should be false
    And all capabilities should be dropped

  @volumes @log-collection
  Scenario: Required volumes are mounted for log collection
    Given OpenTelemetry Collector DaemonSet is deployed
    When I check the volume mounts
    Then /var/log/containers should be mounted as read-only
    And /var/log/pods should be mounted as read-only
    And /var/lib/docker/containers should be mounted as read-only
    And /var/lib/otelcol/file_storage should be mounted as writable

  @tolerations
  Scenario: OpenTelemetry Collector tolerates master/control-plane nodes
    Given OpenTelemetry Collector DaemonSet is deployed
    When I check the pod tolerations
    Then the DaemonSet should tolerate node-role.kubernetes.io/master
    And the DaemonSet should tolerate node-role.kubernetes.io/control-plane
    And the DaemonSet should run on all nodes including control plane

  @servicemonitor
  Scenario: ServiceMonitor for OpenTelemetry Collector metrics
    Given OpenTelemetry Collector is deployed with metrics exposed
    When I check for PodMonitor "otel-collector-opentelemetry-collector"
    Then the PodMonitor should exist in namespace "monitoring"
    And the PodMonitor should scrape metrics endpoint on port 8888
    And Prometheus should be scraping OpenTelemetry Collector metrics
