# =============================================================================

# BROWN BELT LAB FILES - Observability & SRE (Modules 13-16)

# =============================================================================

# =============================================================================

# MODULE 13 - LAB 1: Complete Observability Stack

# Directory: labs/module-13/

# =============================================================================

---

# labs/module-13/prometheus-values.yaml

# Helm values for Prometheus stack

prometheus:
prometheusSpec:
retention: 15d
storageSpec:
volumeClaimTemplate:
spec:
accessModes: ["ReadWriteOnce"]
resources:
requests:
storage: 50Gi

    additionalScrapeConfigs:
    - job_name: 'fawkes-apps'
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2

grafana:
adminPassword: "fawkes-dojo"
datasources:
datasources.yaml:
apiVersion: 1
datasources: - name: Prometheus
type: prometheus
url: http://prometheus-operated:9090
isDefault: true - name: Loki
type: loki
url: http://loki:3100 - name: Tempo
type: tempo
url: http://tempo:3100

---

# labs/module-13/loki-stack.yaml

# Loki for log aggregation

apiVersion: v1
kind: ConfigMap
metadata:
name: loki-config
namespace: monitoring
data:
loki.yaml: |
auth_enabled: false

    server:
      http_listen_port: 3100

    ingester:
      lifecycler:
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
      chunk_idle_period: 15m
      chunk_retain_period: 30s

    schema_config:
      configs:
      - from: 2020-10-24
        store: boltdb-shipper
        object_store: filesystem
        schema: v11
        index:
          prefix: index_
          period: 24h

    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/index
        cache_location: /loki/cache
        shared_store: filesystem
      filesystem:
        directory: /loki/chunks

    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h

---

apiVersion: apps/v1
kind: StatefulSet
metadata:
name: loki
namespace: monitoring
spec:
serviceName: loki
replicas: 1
selector:
matchLabels:
app: loki
template:
metadata:
labels:
app: loki
spec:
containers: - name: loki
image: grafana/loki:2.9.0
ports: - containerPort: 3100
name: http
volumeMounts: - name: config
mountPath: /etc/loki - name: storage
mountPath: /loki
volumes: - name: config
configMap:
name: loki-config
volumeClaimTemplates:

- metadata:
  name: storage
  spec:
  accessModes: ["ReadWriteOnce"]
  resources:
  requests:
  storage: 10Gi

---

# labs/module-13/tempo-config.yaml

# Tempo for distributed tracing

apiVersion: v1
kind: ConfigMap
metadata:
name: tempo-config
namespace: monitoring
data:
tempo.yaml: |
server:
http_listen_port: 3100

    distributor:
      receivers:
        jaeger:
          protocols:
            thrift_http:
              endpoint: 0.0.0.0:14268
            grpc:
              endpoint: 0.0.0.0:14250
        otlp:
          protocols:
            http:
              endpoint: 0.0.0.0:4318
            grpc:
              endpoint: 0.0.0.0:4317

    ingester:
      trace_idle_period: 10s
      max_block_bytes: 1_000_000
      max_block_duration: 5m

    compactor:
      compaction:
        block_retention: 1h

    storage:
      trace:
        backend: local
        local:
          path: /var/tempo/traces
        wal:
          path: /var/tempo/wal

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: tempo
namespace: monitoring
spec:
replicas: 1
selector:
matchLabels:
app: tempo
template:
metadata:
labels:
app: tempo
spec:
containers: - name: tempo
image: grafana/tempo:2.2.0
ports: - containerPort: 3100
name: http - containerPort: 14268
name: jaeger-http - containerPort: 4318
name: otlp-http
volumeMounts: - name: config
mountPath: /etc/tempo - name: storage
mountPath: /var/tempo
volumes: - name: config
configMap:
name: tempo-config - name: storage
emptyDir: {}

---

# labs/module-13/instrumented-app.yaml

# Sample app with full instrumentation

apiVersion: apps/v1
kind: Deployment
metadata:
name: instrumented-app
namespace: lab-module-13
spec:
replicas: 2
selector:
matchLabels:
app: instrumented-app
template:
metadata:
labels:
app: instrumented-app
annotations:
prometheus.io/scrape: "true"
prometheus.io/port: "9090"
prometheus.io/path: "/metrics"
spec:
containers: - name: app
image: ghcr.io/fawkes/instrumented-app:v1.0.0
ports: - containerPort: 8080
name: http - containerPort: 9090
name: metrics
env: # Prometheus metrics - name: METRICS_ENABLED
value: "true" - name: METRICS_PORT
value: "9090"

        # Logging to Loki
        - name: LOG_FORMAT
          value: "json"
        - name: LOG_LEVEL
          value: "info"

        # Tracing to Tempo
        - name: OTEL_EXPORTER_OTLP_ENDPOINT
          value: "http://tempo.monitoring:4318"
        - name: OTEL_SERVICE_NAME
          value: "instrumented-app"
        - name: OTEL_TRACES_SAMPLER
          value: "always_on"

---

# =============================================================================

# MODULE 14 - LAB 2: DORA Metrics Dashboard

# Directory: labs/module-14/

# =============================================================================

---

# labs/module-14/dora-metrics-queries.yaml

apiVersion: v1
kind: ConfigMap
metadata:
name: dora-queries
namespace: lab-module-14
data:
deployment-frequency.promql: | # Deployments per day
sum(increase(deployments_total[1d]))

    # By team
    sum by (team) (increase(deployments_total[1d]))

    # Trend over 30 days
    sum_over_time(increase(deployments_total[1d])[30d:1d])

lead-time.promql: | # P95 lead time
histogram_quantile(0.95,
rate(lead_time_seconds_bucket[1d])
)

    # Average lead time
    rate(lead_time_seconds_sum[1d]) /
    rate(lead_time_seconds_count[1d])

mttr.promql: | # P95 MTTR
histogram_quantile(0.95,
rate(incident_resolution_seconds_bucket[7d])
)

    # Average incidents per week
    sum(increase(incidents_total[7d]))

change-failure-rate.promql: | # Change failure rate percentage
(
sum(increase(deployments_failed_total[7d]))
/
sum(increase(deployments_total[7d]))
) \* 100

---

# labs/module-14/grafana-dora-dashboard.json

apiVersion: v1
kind: ConfigMap
metadata:
name: dora-dashboard
namespace: monitoring
labels:
grafana_dashboard: "1"
data:
dora-dashboard.json: |
{
"dashboard": {
"title": "DORA Metrics - Comprehensive",
"tags": ["dora", "platform-engineering"],
"timezone": "browser",
"panels": [
{
"id": 1,
"title": "Deployment Frequency",
"type": "stat",
"gridPos": {"h": 8, "w": 6, "x": 0, "y": 0},
"targets": [{
"expr": "sum(increase(deployments_total[1d]))"
}],
"fieldConfig": {
"defaults": {
"unit": "short",
"thresholds": {
"steps": [
{"value": 0, "color": "red"},
{"value": 1, "color": "yellow"},
{"value": 5, "color": "green"}
]
}
}
}
},
{
"id": 2,
"title": "Lead Time (P95)",
"type": "gauge",
"gridPos": {"h": 8, "w": 6, "x": 6, "y": 0},
"targets": [{
"expr": "histogram_quantile(0.95, rate(lead_time_seconds_bucket[1d]))"
}],
"fieldConfig": {
"defaults": {
"unit": "s",
"max": 3600,
"thresholds": {
"steps": [
{"value": 0, "color": "green"},
{"value": 3600, "color": "yellow"},
{"value": 86400, "color": "red"}
]
}
}
}
},
{
"id": 3,
"title": "MTTR (P95)",
"type": "stat",
"gridPos": {"h": 8, "w": 6, "x": 12, "y": 0},
"targets": [{
"expr": "histogram_quantile(0.95, rate(incident_resolution_seconds_bucket[7d]))"
}],
"fieldConfig": {
"defaults": {
"unit": "s",
"thresholds": {
"steps": [
{"value": 0, "color": "green"},
{"value": 3600, "color": "yellow"},
{"value": 14400, "color": "red"}
]
}
}
}
},
{
"id": 4,
"title": "Change Failure Rate",
"type": "gauge",
"gridPos": {"h": 8, "w": 6, "x": 18, "y": 0},
"targets": [{
"expr": "(sum(increase(deployments_failed_total[7d])) / sum(increase(deployments_total[7d]))) \* 100"
}],
"fieldConfig": {
"defaults": {
"unit": "percent",
"max": 100,
"thresholds": {
"steps": [
{"value": 0, "color": "green"},
{"value": 15, "color": "yellow"},
{"value": 30, "color": "red"}
]
}
}
}
}
]
}
}

---

# =============================================================================

# MODULE 15 - LAB 3: SLIs, SLOs & Error Budgets

# Directory: labs/module-15/

# =============================================================================

---

# labs/module-15/slo-config.yaml

apiVersion: v1
kind: ConfigMap
metadata:
name: slo-definitions
namespace: lab-module-15
data:
slos.yaml: |
slos: - name: api-availability
description: API should be available 99.9% of the time
sli:
metric: http_requests_total
success_condition: status < 500
slo: 99.9
window: 30d
error_budget: 0.1

      - name: api-latency
        description: 95% of requests complete in <500ms
        sli:
          metric: http_request_duration_seconds
          percentile: 95
        slo: 0.5
        window: 30d

      - name: data-freshness
        description: Data is no older than 5 minutes
        sli:
          metric: data_age_seconds
        slo: 300
        window: 24h

---

# labs/module-15/slo-prometheus-rules.yaml

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
name: slo-rules
namespace: lab-module-15
spec:
groups:

- name: slo-availability
  interval: 30s
  rules:

  # SLI: Availability

  - record: sli:availability:ratio_rate5m
    expr: |
    (
    sum(rate(http_requests_total{status!~"5.."}[5m]))
    /
    sum(rate(http_requests_total[5m]))
    )

  # Error budget remaining (30 day window)

  - record: slo:availability:error_budget_remaining
    expr: |
    1 - (
    (1 - sli:availability:ratio_rate5m)
    /
    (1 - 0.999)
    )

  # Burn rate (how fast we're consuming error budget)

  - record: slo:availability:burn_rate
    expr: |
    (1 - sli:availability:ratio_rate5m)
    /
    (1 - 0.999)

- name: slo-latency
  interval: 30s
  rules:

  # SLI: Latency P95

  - record: sli:latency:p95
    expr: |
    histogram_quantile(0.95,
    rate(http_request_duration_seconds_bucket[5m])
    )

  # Latency SLO compliance

  - record: slo:latency:compliance
    expr: |
    (sli:latency:p95 <= 0.5)

---

# labs/module-15/slo-alerts.yaml

apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
name: slo-alerts
namespace: lab-module-15
spec:
groups:

- name: error-budget-alerts
  rules:

  # Fast burn (2% budget in 1 hour)

  - alert: ErrorBudgetFastBurn
    expr: |
    slo:availability:burn_rate > 14.4
    for: 2m
    labels:
    severity: critical
    annotations:
    summary: "Error budget burning too fast"
    description: "At current rate, error budget will be exhausted in {{ $value | humanizeDuration }}"

  # Slow burn (10% budget in 3 days)

  - alert: ErrorBudgetSlowBurn
    expr: |
    slo:availability:burn_rate > 6
    for: 1h
    labels:
    severity: warning
    annotations:
    summary: "Error budget burning steadily"
    description: "Error budget consumption rate is elevated"

  # Budget exhausted

  - alert: ErrorBudgetExhausted
    expr: |
    slo:availability:error_budget_remaining <= 0
    for: 5m
    labels:
    severity: critical
    annotations:
    summary: "Error budget exhausted"
    description: "No error budget remaining. Freeze deployments!"

---

# =============================================================================

# MODULE 16 - LAB 4: Incident Management

# Directory: labs/module-16/

# =============================================================================

---

# labs/module-16/incident-tracker.yaml

# Simple incident tracking via CRD

apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
name: incidents.fawkes.io
spec:
group: fawkes.io
versions:

- name: v1
  served: true
  storage: true
  schema:
  openAPIV3Schema:
  type: object
  properties:
  spec:
  type: object
  properties:
  severity:
  type: string
  enum: [P0, P1, P2, P3]
  summary:
  type: string
  affectedServices:
  type: array
  items:
  type: string
  startTime:
  type: string
  format: date-time
  status:
  type: object
  properties:
  state:
  type: string
  enum: [investigating, identified, mitigating, resolved]
  mitigationTime:
  type: string
  format: date-time
  resolutionTime:
  type: string
  format: date-time
  mttr:
  type: integer
  scope: Namespaced
  names:
  plural: incidents
  singular: incident
  kind: Incident

---

# labs/module-16/incident-example.yaml

apiVersion: fawkes.io/v1
kind: Incident
metadata:
name: incident-20251019-001
namespace: lab-module-16
spec:
severity: P1
summary: "High error rate on payment API"
affectedServices: - payment-api - checkout-service
startTime: "2025-10-19T10:30:00Z"
status:
state: resolved
mitigationTime: "2025-10-19T10:35:00Z"
resolutionTime: "2025-10-19T10:45:00Z"
mttr: 900 # 15 minutes in seconds

---

# labs/module-16/postmortem-template.yaml

apiVersion: v1
kind: ConfigMap
metadata:
name: postmortem-template
namespace: lab-module-16
data:
template.md: | # Incident Postmortem: [INCIDENT-ID]

    **Date**: [YYYY-MM-DD]
    **Duration**: [START] to [END] ([DURATION])
    **Severity**: [P0/P1/P2/P3]
    **Authors**: [Names]
    **Status**: Draft/Final

    ## Executive Summary
    [2-3 sentence summary of what happened and impact]

    ## Impact
    - **Users affected**: [number or percentage]
    - **Duration**: [X hours Y minutes]
    - **Services affected**: [list]
    - **Revenue impact**: [$amount or N/A]
    - **Customer complaints**: [number]

    ## Timeline (all times UTC)
    - **10:30** - Alert fired: High error rate detected
    - **10:32** - On-call acknowledged, incident channel created
    - **10:35** - Root cause identified: Database connection pool exhausted
    - **10:37** - Mitigation started: Increased connection pool size
    - **10:40** - Error rate returning to normal
    - **10:45** - Incident resolved, monitoring continues
    - **11:00** - Postmortem scheduled

    ## Root Cause
    [Detailed explanation of what caused the incident]

    ### Contributing Factors
    1. [Factor 1]
    2. [Factor 2]

    ## Resolution
    [What was done to fix the immediate problem]

    ## Detection
    - **How detected**: [Alert/User report/Monitoring]
    - **Time to detect**: [X minutes from start]
    - **Could we have detected sooner?**: [Yes/No, explain]

    ## Action Items
    | Action | Owner | Due Date | Priority |
    |--------|-------|----------|----------|
    | [Action 1] | @person | YYYY-MM-DD | P0 |
    | [Action 2] | @person | YYYY-MM-DD | P1 |

    ## Lessons Learned
    ### What went well
    - [Item 1]
    - [Item 2]

    ### What went wrong
    - [Item 1]
    - [Item 2]

    ### Where we got lucky
    - [Item 1]

    ## Prevention
    [How we'll prevent this from happening again]

---

# =============================================================================

# BLACK BELT LAB FILES - Platform Architecture (Modules 17-20)

# =============================================================================

# =============================================================================

# MODULE 17 - Implementation: Platform as a Product

# Directory: labs/module-17/

# =============================================================================

---

# labs/module-17/user-feedback-crd.yaml

apiVersion: apiextensions.k8s.io/v1
kind: CustomResourceDefinition
metadata:
name: feedbacks.fawkes.io
spec:
group: fawkes.io
versions:

- name: v1
  served: true
  storage: true
  schema:
  openAPIV3Schema:
  type: object
  properties:
  spec:
  type: object
  properties:
  user:
  type: string
  npsScore:
  type: integer
  minimum: 0
  maximum: 10
  feedback:
  type: string
  feature:
  type: string
  timestamp:
  type: string
  format: date-time
  scope: Cluster
  names:
  plural: feedbacks
  singular: feedback
  kind: Feedback

---

# labs/module-17/backstage-catalog-metrics.yaml

# Track catalog adoption metrics

apiVersion: v1
kind: ConfigMap
metadata:
name: catalog-metrics
namespace: lab-module-17
data:
queries.promql: | # Components registered
count(backstage_catalog_entities_total{kind="Component"})

    # APIs documented
    count(backstage_catalog_entities_total{kind="API"})

    # Active users (last 7 days)
    count(count_over_time(backstage_user_login[7d]))

    # Page views by type
    sum by (page_type) (rate(backstage_page_view_total[1h]))

---

# =============================================================================

# MODULE 18 - Implementation: Multi-Tenancy

# Directory: labs/module-18/

# =============================================================================

---

# labs/module-18/tenant-namespace-template.yaml

apiVersion: v1
kind: Namespace
metadata:
name: tenant-{{.TenantName}}
labels:
fawkes.io/tenant: "{{.TenantName}}"
fawkes.io/team: "{{.TeamName}}"

---

apiVersion: v1
kind: ResourceQuota
metadata:
name: tenant-quota
namespace: tenant-{{.TenantName}}
spec:
hard:
requests.cpu: "{{.CPUQuota}}"
requests.memory: "{{.MemoryQuota}}"
limits.cpu: "{{.CPULimit}}"
limits.memory: "{{.MemoryLimit}}"
persistentvolumeclaims: "{{.PVCQuota}}"
services.loadbalancers: "{{.LBQuota}}"

---

apiVersion: v1
kind: LimitRange
metadata:
name: tenant-limits
namespace: tenant-{{.TenantName}}
spec:
limits:

- max:
  cpu: "2"
  memory: "4Gi"
  min:
  cpu: "10m"
  memory: "10Mi"
  default:
  cpu: "500m"
  memory: "512Mi"
  defaultRequest:
  cpu: "100m"
  memory: "128Mi"
  type: Container

---

apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
name: tenant-admin
namespace: tenant-{{.TenantName}}
rules:

- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
name: tenant-admin-binding
namespace: tenant-{{.TenantName}}
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: Role
name: tenant-admin
subjects:

- kind: Group
  name: "tenant-{{.TenantName}}-admins"
  apiGroup: rbac.authorization.k8s.io

---

# labs/module-18/hierarchical-namespace.yaml

# Using HNC (Hierarchical Namespace Controller)

apiVersion: hnc.x-k8s.io/v1alpha2
kind: HierarchyConfiguration
metadata:
name: hierarchy
namespace: org-engineering
spec:
parent: org-root

---

apiVersion: hnc.x-k8s.io/v1alpha2
kind: SubnamespaceAnchor
metadata:
name: team-backend
namespace: org-engineering

---

apiVersion: hnc.x-k8s.io/v1alpha2
kind: SubnamespaceAnchor
metadata:
name: team-frontend
namespace: org-engineering

---

# =============================================================================

# MODULE 19 - Implementation: Zero Trust Security

# Directory: labs/module-19/

# =============================================================================

---

# labs/module-19/workload-identity-setup.yaml

# AWS IRSA (IAM Roles for Service Accounts) example

apiVersion: v1
kind: ServiceAccount
metadata:
name: payment-service
namespace: lab-module-19
annotations:
eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/payment-service

---

apiVersion: apps/v1
kind: Deployment
metadata:
name: payment-service
namespace: lab-module-19
spec:
replicas: 2
selector:
matchLabels:
app: payment-service
template:
metadata:
labels:
app: payment-service
spec:
serviceAccountName: payment-service
containers: - name: app
image: payment-service:v1.0.0 # No AWS credentials needed - IRSA provides them

---

# labs/module-19/policy-as-code-gatekeeper.yaml

apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
name: k8srequiredsignedimages
spec:
crd:
spec:
names:
kind: K8sRequiredSignedImages
targets: - target: admission.k8s.gatekeeper.sh
rego: |
package k8srequiredsignedimages

        violation[{"msg": msg}] {
          container := input.review.object.spec.containers[_]
          not is_signed(container.image)
          msg := sprintf("Image %v is not signed", [container.image])
        }

        is_signed(image) {
          # Check if image has valid signature
          # In real implementation, would verify with Cosign
          startswith(image, "registry.fawkes.io/")
        }

---

apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredSignedImages
metadata:
name: must-be-signed
spec:
match:
kinds: - apiGroups: ["apps"]
kinds: ["Deployment"]

---

# labs/module-19/external-secrets-vault.yaml

apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
name: vault-backend
namespace: lab-module-19
spec:
provider:
vault:
server: "https://vault.fawkes.io"
path: "secret"
version: "v2"
auth:
kubernetes:
mountPath: "kubernetes"
role: "payment-service"

---

apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
name: payment-secrets
namespace: lab-module-19
spec:
refreshInterval: 1h
secretStoreRef:
name: vault-backend
kind: SecretStore
target:
name: payment-secrets
creationPolicy: Owner
data:

- secretKey: stripe-api-key
  remoteRef:
  key: payment/stripe
  property: api_key
- secretKey: database-password
  remoteRef:
  key: payment/database
  property: password

---

# =============================================================================

# MODULE 20 - Implementation: Multi-Cloud

# Directory: labs/module-20/

# =============================================================================

---

# labs/module-20/crossplane-aws-composition.yaml

apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
name: xpostgresql-aws
labels:
provider: aws
spec:
compositeTypeRef:
apiVersion: database.fawkes.io/v1alpha1
kind: XPostgreSQL
resources:

- name: rdsinstance
  base:
  apiVersion: database.aws.crossplane.io/v1beta1
  kind: RDSInstance
  spec:
  forProvider:
  region: us-east-1
  dbInstanceClass: db.t3.micro
  engine: postgres
  engineVersion: "14"
  masterUsername: admin
  allocatedStorage: 20
  storageEncrypted: true
  publiclyAccessible: false

---

# labs/module-20/crossplane-gcp-composition.yaml

apiVersion: apiextensions.crossplane.io/v1
kind: Composition
metadata:
name: xpostgresql-gcp
labels:
provider: gcp
spec:
compositeTypeRef:
apiVersion: database.fawkes.io/v1alpha1
kind: XPostgreSQL
resources:

- name: cloudsqlinstance
  base:
  apiVersion: database.gcp.crossplane.io/v1beta1
  kind: CloudSQLInstance
  spec:
  forProvider:
  region: us-central1
  databaseVersion: POSTGRES_14
  settings:
  tier: db-f1-micro
  ipConfiguration:
  ipv4Enabled: false
  privateNetwork: projects/my-project/global/networks/default

---

# labs/module-20/cloud-agnostic-database.yaml

# Application uses cloud-agnostic API

apiVersion: database.fawkes.io/v1alpha1
kind: XPostgreSQL
metadata:
name: my-database
spec:
size: small
version: "14"
storageGB: 20
highAvailability: false

# Crossplane automatically provisions RDS on AWS or Cloud SQL on GCP

# based on which composition is selected

---

# =============================================================================

# LAB DEPLOYMENT AUTOMATION

# =============================================================================

---

# labs/deploy-all-labs.sh

apiVersion: v1
kind: ConfigMap
metadata:
name: lab-deployment-scripts
namespace: fawkes-system
data:
deploy-labs.sh: |
#!/bin/bash # Deploy all lab infrastructure
set -e

    echo "Deploying Fawkes Dojo Lab Infrastructure..."

    # Install prerequisite operators
    echo "Installing operators..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update

    # Create monitoring namespace
    kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

    # Install Prometheus stack
    echo "Installing Prometheus..."
    helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
      -n monitoring \
      -f labs/module-13/prometheus-values.yaml \
      --wait

    # Install ArgoCD
    echo "Installing ArgoCD..."
    kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

    # Install Flagger
    echo "Installing Flagger..."
    kubectl apply -f labs/green-belt-shared/flagger-install.yaml

    # Install Crossplane
    echo "Installing Crossplane..."
    helm upgrade --install crossplane \
      crossplane-stable/crossplane \
      -n crossplane-system \
      --create-namespace \
      --wait

    echo "Lab infrastructure deployed successfully!"
    echo "Run 'fawkes lab start --module N' to start a specific lab"
