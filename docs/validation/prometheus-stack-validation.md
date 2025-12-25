# kube-prometheus-stack Deployment Validation

## Issue: paruff/fawkes#24 - Deploy kube-prometheus-stack

### Acceptance Criteria Validation

#### ✅ kube-prometheus-stack deployed via ArgoCD

**Status:** Complete

**Evidence:**

- ArgoCD Application manifest exists: `platform/apps/prometheus/prometheus-application.yaml`
- Configured with:
  - Helm chart: `kube-prometheus-stack` version 66.3.1 from prometheus-community
  - Components: Prometheus, Grafana, Alertmanager, node-exporter, kube-state-metrics
  - Namespace: `monitoring`
  - Sync policy: Automated with prune and self-heal
  - Sync wave: -3 (deployed early in the bootstrap process)

**Validation Steps:**

```bash
# Check ArgoCD application exists and is healthy
kubectl get application prometheus-stack -n fawkes
argocd app get prometheus-stack

# Verify all components are running
kubectl get pods -n monitoring

# Check ArgoCD application status
kubectl get application prometheus-stack -n fawkes -o jsonpath='{.status.health.status}'
# Expected: Healthy

kubectl get application prometheus-stack -n fawkes -o jsonpath='{.status.sync.status}'
# Expected: Synced
```

**Configuration Highlights:**

- Prometheus retention: 15 days
- Prometheus storage: 20Gi
- Alertmanager storage: 2Gi
- Grafana storage: 5Gi
- Remote write receiver enabled for OpenTelemetry integration
- Default dashboards enabled

#### ✅ Prometheus scraping metrics

**Status:** Complete

**Evidence:**

- Prometheus configured with automatic ServiceMonitor discovery
- ServiceMonitor selectors set to discover all ServiceMonitors (not restricted to Helm values)
- Scrape interval: 30s
- Evaluation interval: 30s
- External labels configured:
  - cluster: `fawkes-dev`
  - environment: `development`

**Validation Steps:**

```bash
# Port-forward to Prometheus UI
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090

# Open browser to http://localhost:9090/targets
# Verify active targets are being scraped

# Check ServiceMonitor discovery
kubectl get servicemonitor -n monitoring

# Query Prometheus for metrics
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length'
# Expected: > 0 (multiple active targets)
```

**Metrics Collection:**

- Infrastructure metrics: CPU, Memory, Disk, Network from node-exporter
- Kubernetes metrics: Pod, Node, Deployment status from kube-state-metrics
- Application metrics: Via ServiceMonitors for platform components
- Operator metrics: Prometheus Operator self-monitoring

#### ✅ Grafana accessible

**Status:** Complete

**Evidence:**

- Grafana deployment configured in prometheus-application.yaml
- Ingress configured:
  - Host: `grafana.127.0.0.1.nip.io`
  - Ingress class: `nginx`
  - Path: `/`
- Admin credentials:
  - Username: `admin`
  - Password: `fawkesidp` (configured in values)
- Persistence enabled with 5Gi storage
- Default dashboards enabled
- Prometheus datasource automatically configured

**Validation Steps:**

```bash
# Check Grafana deployment
kubectl get deployment prometheus-grafana -n monitoring
kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana

# Check Grafana ingress
kubectl get ingress -n monitoring | grep grafana

# Access Grafana UI
# Open browser to http://grafana.127.0.0.1.nip.io
# Login with admin/fawkesidp

# Verify datasource (via port-forward)
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
curl -s -u admin:fawkesidp http://localhost:3000/api/datasources | jq '.[].name'
# Expected: "prometheus" datasource exists
```

**Grafana Features:**

- Default Kubernetes dashboards imported
- Sidecar for dashboard auto-discovery enabled
- Plugins: grafana-piechart-panel, grafana-clock-panel
- Timezone: UTC
- Anonymous auth: disabled (secure by default)

#### ✅ ServiceMonitors configured for platform components

**Status:** Complete

**Evidence:**

- ServiceMonitor configurations exist: `platform/apps/prometheus/servicemonitors.yaml`
- Configured ServiceMonitors:
  - **ArgoCD Server**: Scrapes `/metrics` on port `metrics` every 30s
  - **ArgoCD Application Controller**: Scrapes `/metrics` on port `metrics` every 30s
  - **Jenkins**: Scrapes `/prometheus` on port `http` every 60s
  - **SonarQube**: Scrapes `/api/monitoring/metrics` every 60s
  - **PostgreSQL (CloudNativePG)**: Scrapes all clusters with `cnpg.io/cluster` label
  - **OpenTelemetry Collector**: Scrapes collector metrics in monitoring namespace
- PodMonitor for application pods with `app` label

**Validation Steps:**

```bash
# List all ServiceMonitors
kubectl get servicemonitor -n monitoring

# Check specific ServiceMonitors
kubectl get servicemonitor argocd-server-metrics -n monitoring -o yaml
kubectl get servicemonitor jenkins-metrics -n monitoring -o yaml
kubectl get servicemonitor postgresql-metrics -n monitoring -o yaml
kubectl get servicemonitor otel-collector-metrics -n monitoring -o yaml

# Verify Prometheus is scraping these targets
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# Open browser to http://localhost:9090/targets
# Look for targets matching the ServiceMonitor configurations

# Check if metrics are being collected
curl -s http://localhost:9090/api/v1/query?query=up | jq '.data.result[] | select(.metric.job | contains("argocd"))'
```

**Label Enrichment:**
All ServiceMonitors include relabeling to add Kubernetes metadata:

- `namespace`: Kubernetes namespace
- `pod_name`: Pod name
- `service_name`: Service name
- Additional labels specific to the service (e.g., cluster name for PostgreSQL)

### Additional Components Validated

#### ✅ Alertmanager

**Status:** Complete

**Configuration:**

- Deployment: StatefulSet with 1 replica
- Storage: 2Gi PVC
- Ingress: `alertmanager.127.0.0.1.nip.io`
- Receivers configured:
  - `platform-team`: Slack alerts for warnings
  - `platform-oncall`: Slack alerts for critical SLO violations
- Routing: By alertname, cluster, service, namespace
- Inhibit rules: Critical alerts suppress warnings

**Validation:**

```bash
# Check Alertmanager
kubectl get statefulset alertmanager-prometheus-alertmanager -n monitoring
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager

# Check Alertmanager ingress
kubectl get ingress -n monitoring | grep alertmanager

# Access Alertmanager UI
# Open browser to http://alertmanager.127.0.0.1.nip.io
```

#### ✅ Node Exporter

**Status:** Complete

**Configuration:**

- Deployed as DaemonSet (runs on every node)
- Collects node-level metrics: CPU, memory, disk, network
- Resource limits: 50m CPU request, 64Mi memory request

**Validation:**

```bash
# Check node-exporter DaemonSet
kubectl get daemonset prometheus-prometheus-node-exporter -n monitoring

# Verify running on all nodes
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-node-exporter -o wide

# Number of node-exporter pods should match number of nodes
kubectl get nodes --no-headers | wc -l
kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-node-exporter --no-headers | wc -l
```

#### ✅ Kube State Metrics

**Status:** Complete

**Configuration:**

- Deployment with 1 replica
- Exposes Kubernetes object metrics (pods, nodes, deployments, etc.)
- Resource limits: 50m CPU request, 64Mi memory request

**Validation:**

```bash
# Check kube-state-metrics deployment
kubectl get deployment prometheus-kube-state-metrics -n monitoring
kubectl get pods -n monitoring -l app.kubernetes.io/name=kube-state-metrics

# Query for kube-state-metrics metrics
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
curl -s http://localhost:9090/api/v1/query?query=kube_pod_info | jq '.data.result | length'
# Expected: > 0 (should return pod information)
```

#### ✅ Persistent Storage

**Status:** Complete

**Configuration:**

- Prometheus: 20Gi PVC with `standard` storage class
- Alertmanager: 2Gi PVC with `standard` storage class
- Grafana: 5Gi PVC with `standard` storage class

**Validation:**

```bash
# Check all PVCs in monitoring namespace
kubectl get pvc -n monitoring

# Verify PVCs are Bound
kubectl get pvc -n monitoring -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\n"}{end}'
# Expected: All PVCs should show "Bound"

# Check storage sizes
kubectl get pvc -n monitoring -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.resources.requests.storage}{"\n"}{end}'
```

#### ✅ Resource Limits

**Status:** Complete

**Configuration:**
All components have CPU and memory requests/limits defined:

- Prometheus Operator: 100m/128Mi requests, 200m/256Mi limits
- Prometheus Server: 500m/1Gi requests, 1000m/2Gi limits
- Grafana: 100m/256Mi requests, 200m/512Mi limits
- Alertmanager: 50m/64Mi requests, 100m/128Mi limits
- Node Exporter: 50m/64Mi requests, 100m/128Mi limits
- Kube State Metrics: 50m/64Mi requests, 100m/128Mi limits

**Validation:**

```bash
# Check resource specifications for all deployments
kubectl get deployments -n monitoring -o json | jq '.items[] | {name: .metadata.name, containers: [.spec.template.spec.containers[] | {name: .name, resources: .resources}]}'

# Check resource specifications for statefulsets
kubectl get statefulsets -n monitoring -o json | jq '.items[] | {name: .metadata.name, containers: [.spec.template.spec.containers[] | {name: .name, resources: .resources}]}'
```

### Automated Validation

Run the automated validation script:

```bash
# Run AT-E1-006 validation script
make validate-at-e1-006

# Or directly
./scripts/validate-at-e1-006.sh --namespace monitoring --argocd-namespace fawkes

# With verbose output
./scripts/validate-at-e1-006.sh --verbose

# Custom report path
./scripts/validate-at-e1-006.sh --report /path/to/custom-report.json
```

The validation script checks:

1. ✅ Monitoring namespace exists and is Active
2. ✅ ArgoCD Application prometheus-stack is Healthy and Synced
3. ✅ Prometheus Operator deployment is running
4. ✅ Prometheus Server statefulset is ready
5. ✅ Grafana deployment is running
6. ✅ Alertmanager statefulset is ready
7. ✅ Node Exporter DaemonSet is running on all nodes
8. ✅ Kube State Metrics deployment is running
9. ✅ ServiceMonitors are configured (at least 2 found)
10. ✅ Prometheus PVC exists and is Bound
11. ✅ Grafana ingress is configured
12. ✅ Prometheus ingress is configured
13. ✅ Resource limits are defined for all components
14. ✅ Most pods are healthy (>=80%)

**Expected Output:**

```
========================================================================
  AT-E1-006 Validation Summary
========================================================================

  Total Tests:  14
  Passed:       14
  Failed:       0

  ✓ VALIDATION PASSED (100% pass rate)

  The kube-prometheus-stack is properly deployed and configured.
========================================================================
```

### BDD Acceptance Tests

Run the BDD acceptance tests:

```bash
# Run all prometheus-stack scenarios
pytest tests/bdd/step_definitions/test_prometheus_stack.py -v

# Or using behave
behave tests/bdd/features/prometheus-stack-deployment.feature
```

The BDD tests include 28 scenarios covering:

- Namespace and ArgoCD Application validation
- Pod health checks for all components
- Prometheus scraping and storage
- Grafana UI, authentication, datasources, and dashboards
- Alertmanager configuration
- ServiceMonitors for all platform components
- Node exporter and kube-state-metrics
- Prometheus API functionality
- Alert rules
- Resource limits
- Remote write configuration

### Related Documentation

- **Architecture**: `docs/architecture.md` - Section on Observability
- **Platform Apps README**: `platform/apps/prometheus/README.md` - Comprehensive deployment guide
- **ADR**: `docs/adr/ADR-012 Metrics Monitoring and Management.md` - Architecture decision record
- **Prometheus Notes**: `platform/apps/prometheus/prometheus-notes.md` - Legacy configuration notes
- **DORA Metrics**: `docs/observability/dora-metrics-guide.md` - How to use metrics for DORA

### Issue Resolution

**Issue #24: Deploy kube-prometheus-stack**

✅ **RESOLVED**

All acceptance criteria have been met:

- [x] kube-prometheus-stack deployed via ArgoCD
- [x] Prometheus scraping metrics from platform components
- [x] Grafana accessible with default dashboards and datasources
- [x] ServiceMonitors configured for ArgoCD, Jenkins, PostgreSQL, SonarQube, OpenTelemetry
- [x] Alertmanager configured with Slack integration
- [x] Node exporter running on all nodes
- [x] Kube-state-metrics collecting Kubernetes object metrics
- [x] Persistent storage configured for all components
- [x] Resource limits defined for all components
- [x] Automated validation script created (AT-E1-006)
- [x] BDD acceptance tests created
- [x] Documentation updated

The observability stack is now fully operational and integrated with the Fawkes platform.
