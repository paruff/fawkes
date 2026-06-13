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

output "cluster_overview_dashboard_id" {
  description = "ID of the GKE cluster overview dashboard"
  value       = google_monitoring_dashboard.gke_cluster_overview.id
}

output "node_performance_dashboard_id" {
  description = "ID of the GKE node performance dashboard"
  value       = google_monitoring_dashboard.gke_node_performance.id
}

output "application_performance_dashboard_id" {
  description = "ID of the application performance dashboard"
  value       = google_monitoring_dashboard.application_performance.id
}

output "cost_usage_dashboard_id" {
  description = "ID of the cost and usage dashboard"
  value       = google_monitoring_dashboard.cost_usage.id
}
