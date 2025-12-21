@rag @ai @acceptance @AT-E2-002
Feature: RAG Service for AI Context Retrieval
  As an AI assistant
  I want to retrieve relevant context from internal documentation
  So that I can provide accurate and contextual assistance

  Background:
    Given I have kubectl configured for the cluster
    And the fawkes namespace exists
    And Weaviate is deployed and running

  @deployment @pods
  Scenario: RAG service is deployed and running
    When I check the RAG service deployment in namespace "fawkes"
    Then the deployment "rag-service" should exist
    And the deployment should have 2 replicas
    And all RAG service pods should be in Ready state within 120 seconds

  @service @networking
  Scenario: RAG service is accessible via ClusterIP
    Given RAG service is deployed in namespace "fawkes"
    When I check the RAG service
    Then a service "rag-service" should exist in namespace "fawkes"
    And the service should be type "ClusterIP"
    And the service should expose port 80

  @ingress @accessibility
  Scenario: RAG service is accessible via ingress
    Given RAG service is deployed with ingress enabled
    When I check the ingress configuration in namespace "fawkes"
    Then an ingress should exist for "rag-service"
    And the ingress should have host "rag-service.127.0.0.1.nip.io"
    And the ingress should use ingressClassName "nginx"

  @health @api
  Scenario: RAG service health check is working
    Given RAG service is running in namespace "fawkes"
    When I query the health endpoint at "/api/v1/health"
    Then the response status should be 200
    And the response should contain status "UP" or "DEGRADED"
    And the response should indicate weaviate_connected status

  @context-retrieval @performance
  Scenario: Context retrieval works and is fast
    Given RAG service is running and healthy
    And internal documentation is indexed in Weaviate
    When I send a query "How do I deploy a new service?"
    Then the response should return within 500 milliseconds
    And the response should contain at least 1 result
    And the response should include retrieval_time_ms field

  @relevance @quality
  Scenario: Context retrieval returns relevant results
    Given RAG service is running and healthy
    And internal documentation is indexed in Weaviate
    When I send a query "What is the architecture of Fawkes?"
    Then the response should contain results
    And at least one result should have relevance_score greater than 0.7
    And each result should have content, source, and relevance_score fields

  @weaviate-integration
  Scenario: RAG service integrates with Weaviate
    Given RAG service is running in namespace "fawkes"
    And Weaviate is running in namespace "fawkes"
    When I check the RAG service configuration
    Then the ConfigMap "rag-service-config" should exist
    And it should contain weaviate_url pointing to Weaviate service
    And the RAG service should successfully connect to Weaviate

  @resources @stability
  Scenario: RAG service has resource limits
    Given RAG service is deployed in namespace "fawkes"
    When I check the resource specifications for RAG service deployment
    Then the deployment should have CPU requests of "500m"
    And the deployment should have memory requests of "1Gi"
    And the deployment should have CPU limits of "1"
    And the deployment should have memory limits of "1Gi"

  @security @serviceaccount
  Scenario: RAG service runs with proper security context
    Given RAG service is deployed in namespace "fawkes"
    When I check the security context for RAG service pods
    Then the pods should run as non-root user
    And the pods should have readOnlyRootFilesystem set to false
    And the pods should drop all capabilities
    And a serviceaccount "rag-service" should exist

  @documentation @openapi
  Scenario: RAG service API is documented
    Given RAG service is running in namespace "fawkes"
    When I access the OpenAPI documentation at "/docs"
    Then the documentation should be accessible
    And it should document the "/api/v1/query" endpoint
    And it should document the "/api/v1/health" endpoint
    And the query endpoint should accept query, top_k, and threshold parameters

  @metrics @observability
  Scenario: RAG service exposes Prometheus metrics
    Given RAG service is running in namespace "fawkes"
    When I query the metrics endpoint at "/metrics"
    Then the response status should be 200
    And the response should contain metric "rag_requests_total"
    And the response should contain metric "rag_query_duration_seconds"
    And the response should contain metric "rag_relevance_score"
