# Copyright (c) 2025  Philip Ruff
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0.0"
    }
  }
}

# Pub/Sub Topics for Alerts
resource "google_pubsub_topic" "critical_alerts" {
  name    = "${var.cluster_name}-critical-alerts"
  project = var.project_id

  labels = merge(
    var.tags,
    {
      severity = "critical"
      cost     = "monitoring"
    }
  )

  message_retention_duration = "86400s" # 24 hours
}

resource "google_pubsub_topic" "warning_alerts" {
  name    = "${var.cluster_name}-warning-alerts"
  project = var.project_id

  labels = merge(
    var.tags,
    {
      severity = "warning"
      cost     = "monitoring"
    }
  )

  message_retention_duration = "86400s" # 24 hours
}

resource "google_pubsub_topic" "cost_alerts" {
  name    = "${var.cluster_name}-cost-alerts"
  project = var.project_id

  labels = merge(
    var.tags,
    {
      severity = "info"
      cost     = "monitoring"
      type     = "billing"
    }
  )

  message_retention_duration = "86400s" # 24 hours
}

# Pub/Sub Subscription for cost-collector service
resource "google_pubsub_subscription" "cost_collector" {
  name    = "${var.cluster_name}-cost-collector-sub"
  topic   = google_pubsub_topic.cost_alerts.name
  project = var.project_id

  ack_deadline_seconds = 20

  push_config {
    push_endpoint = var.cost_collector_endpoint

    attributes = {
      x-goog-version = "v1"
    }
  }

  labels = merge(
    var.tags,
    {
      service = "cost-collector"
    }
  )
}

# Pub/Sub Subscription for Mattermost (Critical Alerts)
resource "google_pubsub_subscription" "mattermost_critical" {
  count   = var.mattermost_webhook_url != "" ? 1 : 0
  name    = "${var.cluster_name}-mattermost-critical-sub"
  topic   = google_pubsub_topic.critical_alerts.name
  project = var.project_id

  ack_deadline_seconds = 20

  push_config {
    push_endpoint = var.mattermost_webhook_url

    attributes = {
      x-goog-version = "v1"
    }
  }

  labels = merge(
    var.tags,
    {
      service = "mattermost"
    }
  )
}

# Pub/Sub Subscription for Mattermost (Warning Alerts)
resource "google_pubsub_subscription" "mattermost_warning" {
  count   = var.mattermost_webhook_url != "" ? 1 : 0
  name    = "${var.cluster_name}-mattermost-warning-sub"
  topic   = google_pubsub_topic.warning_alerts.name
  project = var.project_id

  ack_deadline_seconds = 20

  push_config {
    push_endpoint = var.mattermost_webhook_url

    attributes = {
      x-goog-version = "v1"
    }
  }

  labels = merge(
    var.tags,
    {
      service = "mattermost"
    }
  )
}

# Notification Channel for Pub/Sub
resource "google_monitoring_notification_channel" "critical_pubsub" {
  display_name = "${var.cluster_name} Critical Alerts Pub/Sub"
  type         = "pubsub"
  project      = var.project_id

  labels = {
    topic = google_pubsub_topic.critical_alerts.id
  }

  user_labels = merge(
    var.tags,
    {
      severity = "critical"
    }
  )
}

resource "google_monitoring_notification_channel" "warning_pubsub" {
  display_name = "${var.cluster_name} Warning Alerts Pub/Sub"
  type         = "pubsub"
  project      = var.project_id

  labels = {
    topic = google_pubsub_topic.warning_alerts.id
  }

  user_labels = merge(
    var.tags,
    {
      severity = "warning"
    }
  )
}

resource "google_monitoring_notification_channel" "cost_pubsub" {
  display_name = "${var.cluster_name} Cost Alerts Pub/Sub"
  type         = "pubsub"
  project      = var.project_id

  labels = {
    topic = google_pubsub_topic.cost_alerts.id
  }

  user_labels = merge(
    var.tags,
    {
      type = "billing"
    }
  )
}

# GKE Control Plane CPU Alert
resource "google_monitoring_alert_policy" "control_plane_cpu_high" {
  display_name = "${var.cluster_name}-control-plane-cpu-high"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "GKE Control Plane CPU Utilization > 80%"

    condition_threshold {
      filter          = "metric.type=\"container.googleapis.com/container/cpu/utilization\" resource.type=\"k8s_cluster\" resource.label.cluster_name=\"${var.cluster_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.warning_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "warning"
    }
  )
}

# GKE Control Plane Memory Alert
resource "google_monitoring_alert_policy" "control_plane_memory_high" {
  display_name = "${var.cluster_name}-control-plane-memory-high"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "GKE Control Plane Memory Utilization > 80%"

    condition_threshold {
      filter          = "metric.type=\"container.googleapis.com/container/memory/utilization\" resource.type=\"k8s_cluster\" resource.label.cluster_name=\"${var.cluster_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.8

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.warning_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "warning"
    }
  )
}

# Node CPU Critical Alert
resource "google_monitoring_alert_policy" "node_cpu_critical" {
  display_name = "${var.cluster_name}-node-cpu-critical"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Node CPU Utilization > 90%"

    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
      duration        = "900s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.critical_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "critical"
    }
  )
}

# Node Memory Critical Alert
resource "google_monitoring_alert_policy" "node_memory_critical" {
  display_name = "${var.cluster_name}-node-memory-critical"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Node Memory Utilization > 90%"

    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/node/memory/allocatable_utilization\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
      duration        = "900s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.9

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.critical_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "critical"
    }
  )
}

# Pod Restart Alert
resource "google_monitoring_alert_policy" "pod_restart_high" {
  display_name = "${var.cluster_name}-pod-restart-high"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "High Pod Restart Rate"

    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\" resource.label.cluster_name=\"${var.cluster_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_RATE"
        cross_series_reducer = "REDUCE_SUM"
        group_by_fields      = ["resource.cluster_name"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.warning_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "warning"
    }
  )
}

# Failed Pods Alert (using log-based metric)
resource "google_logging_metric" "failed_pods" {
  name    = "${var.cluster_name}_failed_pods"
  project = var.project_id

  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${var.cluster_name}"
    jsonPayload.message=~"Failed"
    severity="ERROR"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "pod_name"
      value_type  = "STRING"
      description = "Pod name"
    }
  }

  label_extractors = {
    "pod_name" = "EXTRACT(resource.labels.pod_name)"
  }
}

resource "google_monitoring_alert_policy" "failed_pods_high" {
  display_name = "${var.cluster_name}-failed-pods-high"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "High Number of Failed Pods"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.failed_pods.name}\" resource.type=\"k8s_pod\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 5

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_SUM"
        cross_series_reducer = "REDUCE_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.critical_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "critical"
    }
  )
}

# Disk Space Alert
resource "google_monitoring_alert_policy" "node_disk_space_low" {
  display_name = "${var.cluster_name}-node-disk-space-low"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Node Disk Space Utilization > 85%"

    condition_threshold {
      filter          = "metric.type=\"kubernetes.io/node/ephemeral_storage/allocatable_utilization\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.85

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.warning_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "warning"
    }
  )
}

# API Server Error Rate Alert (using log-based metric)
resource "google_logging_metric" "api_server_errors" {
  name    = "${var.cluster_name}_api_server_errors"
  project = var.project_id

  filter = <<-EOT
    resource.type="k8s_cluster"
    resource.labels.cluster_name="${var.cluster_name}"
    log_name="projects/${var.project_id}/logs/events"
    jsonPayload.message=~"error|Error|ERROR"
    jsonPayload.source.component="apiserver"
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "api_server_error_rate_high" {
  display_name = "${var.cluster_name}-api-server-error-rate-high"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "API Server Error Rate High"

    condition_threshold {
      filter          = "metric.type=\"logging.googleapis.com/user/${google_logging_metric.api_server_errors.name}\" resource.type=\"k8s_cluster\""
      duration        = "300s"
      comparison      = "COMPARISON_GT"
      threshold_value = 50

      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.critical_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "critical"
    }
  )
}

# Uptime Check for Critical Endpoints
resource "google_monitoring_uptime_check_config" "api_server" {
  count        = var.api_server_endpoint != "" ? 1 : 0
  display_name = "${var.cluster_name}-api-server-uptime"
  project      = var.project_id
  timeout      = "10s"
  period       = "60s"

  http_check {
    path         = "/healthz"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.api_server_endpoint
    }
  }
}

resource "google_monitoring_alert_policy" "api_server_uptime" {
  count        = var.api_server_endpoint != "" ? 1 : 0
  display_name = "${var.cluster_name}-api-server-down"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "API Server Uptime Check Failed"

    condition_threshold {
      filter          = "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\" metric.label.check_id=\"${google_monitoring_uptime_check_config.api_server[0].uptime_check_id}\""
      duration        = "300s"
      comparison      = "COMPARISON_LT"
      threshold_value = 1

      aggregations {
        alignment_period     = "300s"
        cross_series_reducer = "REDUCE_COUNT_FALSE"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        group_by_fields      = ["resource.label.host"]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.critical_pubsub.id]

  alert_strategy {
    auto_close = "1800s"
  }

  user_labels = merge(
    var.tags,
    {
      severity = "critical"
    }
  )
}

# Cost Anomaly Detection Alert
resource "google_monitoring_alert_policy" "cost_anomaly" {
  display_name = "${var.cluster_name}-cost-anomaly"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "GCP Cost Anomaly Detected"

    condition_threshold {
      filter          = "metric.type=\"billing.googleapis.com/project/cost\" resource.type=\"billing_account\""
      duration        = "3600s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.cost_anomaly_threshold

      aggregations {
        alignment_period   = "3600s"
        per_series_aligner = "ALIGN_DELTA"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.cost_pubsub.id]

  alert_strategy {
    auto_close = "86400s"
  }

  user_labels = merge(
    var.tags,
    {
      type = "billing"
    }
  )
}

# Variables
variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
}

variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "mattermost_webhook_url" {
  description = "Mattermost incoming webhook URL for alert notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "cost_collector_endpoint" {
  description = "Endpoint URL for cost-collector service"
  type        = string
  default     = ""
}

variable "api_server_endpoint" {
  description = "GKE API server endpoint for uptime checks"
  type        = string
  default     = ""
}

variable "cost_anomaly_threshold" {
  description = "Cost anomaly threshold in USD"
  type        = number
  default     = 100
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Outputs
output "critical_alerts_topic_name" {
  description = "Name of the critical alerts Pub/Sub topic"
  value       = google_pubsub_topic.critical_alerts.name
}

output "warning_alerts_topic_name" {
  description = "Name of the warning alerts Pub/Sub topic"
  value       = google_pubsub_topic.warning_alerts.name
}

output "cost_alerts_topic_name" {
  description = "Name of the cost alerts Pub/Sub topic"
  value       = google_pubsub_topic.cost_alerts.name
}

output "critical_notification_channel_id" {
  description = "ID of the critical alerts notification channel"
  value       = google_monitoring_notification_channel.critical_pubsub.id
}

output "warning_notification_channel_id" {
  description = "ID of the warning alerts notification channel"
  value       = google_monitoring_notification_channel.warning_pubsub.id
}

output "cost_notification_channel_id" {
  description = "ID of the cost alerts notification channel"
  value       = google_monitoring_notification_channel.cost_pubsub.id
}
