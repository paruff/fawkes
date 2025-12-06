---
title: Prometheus Helm Values Reference
description: Configuration reference for Prometheus monitoring in Fawkes platform
---

# Prometheus Helm Values Reference

## Overview

This document provides the configuration reference for the Prometheus monitoring system deployed in the Fawkes platform. Prometheus collects metrics from platform services and applications for observability and alerting.

**Helm Chart:** `prometheus/prometheus` (Prometheus Community chart)

**Chart Repository:** `https://prometheus-community.github.io/helm-charts`

**Values File Location:** `platform/apps/prometheus/values.yaml`

---

## Server Configuration

### `server.resources`

Resource allocation for the Prometheus server.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `server.resources.requests.cpu` | String | No | `100m` | CPU request (millicores). |
| `server.resources.requests.memory` | String | No | `256Mi` | Memory request. |
| `server.resources.limits.cpu` | String | No | `200m` | Maximum CPU allocation. |
| `server.resources.limits.memory` | String | No | `512Mi` | Maximum memory allocation. |

**Fawkes Defaults:**

```yaml
server:
  resources:
    requests:
      memory: 256Mi
      cpu: 100m
    limits:
      memory: 512Mi
      cpu: 200m
```

**Scaling Guidelines:**

| Environment | CPU Request | Memory Request | CPU Limit | Memory Limit |
|-------------|-------------|----------------|-----------|--------------|
| Development | `100m` | `256Mi` | `200m` | `512Mi` |
| Staging | `200m` | `512Mi` | `500m` | `1Gi` |
| Production | `500m` | `1Gi` | `2` | `4Gi` |

---

### `server.service`

Kubernetes Service configuration for the Prometheus server.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `server.service.type` | String | No | `ClusterIP` | Service type: `ClusterIP`, `NodePort`, `LoadBalancer`. |
| `server.service.port` | Integer | No | `80` | Service port. |
| `server.service.targetPort` | Integer | No | `9090` | Container port. |

**Fawkes Default:**

```yaml
server:
  service:
    type: ClusterIP
```

**Access Pattern:** Prometheus is accessed via Ingress, not directly exposed.

---

### `server.persistentVolume`

Persistent storage for metrics data.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `server.persistentVolume.enabled` | Boolean | No | `true` | Enable persistent storage. |
| `server.persistentVolume.size` | String | No | `8Gi` | Storage size. |
| `server.persistentVolume.storageClass` | String | No | `standard` | StorageClass name. |
| `server.persistentVolume.accessModes` | Array[String] | No | `["ReadWriteOnce"]` | Volume access modes. |

**Retention Recommendations:**

| Retention Period | Recommended Size | Use Case |
|------------------|------------------|----------|
| 7 days | `8Gi` | Development |
| 15 days | `20Gi` | Staging |
| 30 days | `50Gi` | Production |
| 90 days | `150Gi` | Long-term analysis |

**Example:**

```yaml
server:
  persistentVolume:
    enabled: true
    size: 50Gi
    storageClass: gp3
```

---

### `server.retention`

Metrics retention configuration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `server.retention` | String | No | `15d` | Time-based retention (e.g., `7d`, `30d`). |
| `server.retentionSize` | String | No | - | Size-based retention (e.g., `10GB`, `50GB`). Overrides time-based retention. |

**Example:**

```yaml
server:
  retention: "30d"
  retentionSize: "45GB"
```

---

## Alerting Configuration

### `alertmanager.enabled`

Enable or disable Alertmanager integration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `alertmanager.enabled` | Boolean | No | `true` | Deploy Alertmanager for alert routing. |

**Fawkes Default:** `true`

---

### `alertmanagerFiles`

Alert routing configuration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `alertmanagerFiles.alertmanager.yml` | Object | No | `{}` | Alertmanager configuration (receivers, routes). |

**Example:**

```yaml
alertmanagerFiles:
  alertmanager.yml:
    global:
      resolve_timeout: 5m
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'mattermost'
    receivers:
      - name: 'mattermost'
        webhook_configs:
          - url: 'https://mattermost.fawkes.example.com/hooks/alerts'
```

---

## Scrape Configurations

### `serverFiles.prometheus.yml`

Prometheus scrape configuration.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `serverFiles.prometheus.yml.scrape_configs` | Array[Object] | No | `[]` | List of scrape jobs. |

**Default Scrape Targets:**

| Job | Target | Metrics |
|-----|--------|---------|
| `prometheus` | Prometheus itself | Self-monitoring metrics. |
| `kubernetes-apiservers` | Kubernetes API server | Control plane metrics. |
| `kubernetes-nodes` | Kubelet on each node | Node metrics (CPU, memory, disk). |
| `kubernetes-pods` | Pods with `prometheus.io/scrape=true` annotation | Application metrics. |
| `kubernetes-service-endpoints` | Service endpoints | Service-level metrics. |

**Example Custom Scrape Job:**

```yaml
serverFiles:
  prometheus.yml:
    scrape_configs:
      - job_name: 'jenkins'
        static_configs:
          - targets: ['jenkins.jenkins.svc.cluster.local:8080']
        metrics_path: '/prometheus'
        scrape_interval: 30s
```

---

## Service Discovery

### `kubeStateMetrics.enabled`

Enable Kube State Metrics for Kubernetes resource metrics.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `kubeStateMetrics.enabled` | Boolean | No | `true` | Deploy kube-state-metrics. |

**Metrics Collected:**

- Deployment status (replicas, available replicas)
- Pod status (phase, restarts, resource usage)
- Node status (allocatable resources, conditions)
- PersistentVolumeClaim status (phase, capacity)

---

### `nodeExporter.enabled`

Enable Node Exporter for node-level metrics.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `nodeExporter.enabled` | Boolean | No | `true` | Deploy node-exporter DaemonSet. |

**Metrics Collected:**

- CPU usage and load average
- Memory usage (total, available, buffers, caches)
- Disk I/O and space
- Network traffic and errors

---

## Ingress Configuration

### `server.ingress`

Ingress configuration for accessing Prometheus UI.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `server.ingress.enabled` | Boolean | No | `false` | Enable Ingress resource creation. |
| `server.ingress.annotations` | Object | No | `{}` | Ingress annotations (e.g., `cert-manager.io/cluster-issuer`). |
| `server.ingress.hosts` | Array[String] | No | `[]` | Hostnames for Ingress rules. |
| `server.ingress.tls` | Array[Object] | No | `[]` | TLS configuration. |

**Example:**

```yaml
server:
  ingress:
    enabled: true
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-prod
      nginx.ingress.kubernetes.io/auth-type: basic
      nginx.ingress.kubernetes.io/auth-secret: prometheus-basic-auth
    hosts:
      - prometheus.fawkes.example.com
    tls:
      - secretName: prometheus-tls
        hosts:
          - prometheus.fawkes.example.com
```

---

## Federation Configuration

### `server.global`

Global Prometheus configuration for federation.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `server.global.scrape_interval` | String | No | `15s` | Default scrape interval. |
| `server.global.scrape_timeout` | String | No | `10s` | Default scrape timeout. |
| `server.global.evaluation_interval` | String | No | `15s` | Rule evaluation interval. |
| `server.global.external_labels` | Object | No | `{}` | Labels added to all metrics (e.g., `cluster`, `environment`). |

**Example:**

```yaml
server:
  global:
    scrape_interval: 15s
    evaluation_interval: 15s
    external_labels:
      cluster: 'fawkes-prod'
      environment: 'production'
```

---

## Security Configuration

### `server.podSecurityPolicy`

Pod Security Policy for Prometheus server.

| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| `server.podSecurityPolicy.enabled` | Boolean | No | `false` | Enable PodSecurityPolicy (deprecated in K8s 1.25+). |

**Note:** Use Kyverno policies instead for modern Kubernetes versions.

---

## Complete Example

```yaml
server:
  resources:
    requests:
      memory: 1Gi
      cpu: 500m
    limits:
      memory: 4Gi
      cpu: 2
  service:
    type: ClusterIP
  persistentVolume:
    enabled: true
    size: 50Gi
    storageClass: gp3
  retention: "30d"
  global:
    scrape_interval: 15s
    external_labels:
      cluster: 'fawkes-prod'
  ingress:
    enabled: true
    hosts:
      - prometheus.fawkes.example.com
    tls:
      - secretName: prometheus-tls
        hosts:
          - prometheus.fawkes.example.com

alertmanager:
  enabled: true

kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true
```

---

## See Also

- [Prometheus Official Documentation](https://prometheus.io/docs/)
- [Prometheus Helm Chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)
- [View DORA Metrics](../../how-to/observability/view-dora-metrics-devlake.md)
- [Unified Telemetry Explanation](../../explanation/observability/unified-telemetry.md)
