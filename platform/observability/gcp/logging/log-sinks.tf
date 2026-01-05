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

# Storage Bucket for Log Export
resource "google_storage_bucket" "logs" {
  name          = "${var.project_id}-${var.cluster_name}-logs"
  project       = var.project_id
  location      = var.region
  force_destroy = false

  uniform_bucket_level_access = true

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365
    }
    action {
      type          = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 730
    }
    action {
      type = "Delete"
    }
  }

  labels = merge(
    var.tags,
    {
      purpose = "logging"
      cluster = var.cluster_name
    }
  )
}

# BigQuery Dataset for Log Analysis
resource "google_bigquery_dataset" "logs" {
  dataset_id                 = replace("${var.cluster_name}_logs", "-", "_")
  project                    = var.project_id
  location                   = var.region
  default_table_expiration_ms = 7776000000 # 90 days

  labels = merge(
    var.tags,
    {
      purpose = "logging"
      cluster = var.cluster_name
    }
  )
}

# Log Sink - GKE Cluster Logs to Cloud Storage
resource "google_logging_project_sink" "gke_to_storage" {
  name    = "${var.cluster_name}-gke-to-storage"
  project = var.project_id

  destination = "storage.googleapis.com/${google_storage_bucket.logs.name}"

  filter = <<-EOT
    resource.type="k8s_cluster"
    resource.labels.cluster_name="${var.cluster_name}"
  EOT

  unique_writer_identity = true
}

# Grant sink service account write access to bucket
resource "google_storage_bucket_iam_member" "log_sink_writer" {
  bucket = google_storage_bucket.logs.name
  role   = "roles/storage.objectCreator"
  member = google_logging_project_sink.gke_to_storage.writer_identity
}

# Log Sink - GKE Cluster Logs to BigQuery
resource "google_logging_project_sink" "gke_to_bigquery" {
  name    = "${var.cluster_name}-gke-to-bigquery"
  project = var.project_id

  destination = "bigquery.googleapis.com/projects/${var.project_id}/datasets/${google_bigquery_dataset.logs.dataset_id}"

  filter = <<-EOT
    resource.type="k8s_cluster"
    resource.labels.cluster_name="${var.cluster_name}"
  EOT

  unique_writer_identity = true

  bigquery_options {
    use_partitioned_tables = true
  }
}

# Grant sink service account write access to BigQuery
resource "google_bigquery_dataset_iam_member" "log_sink_writer" {
  dataset_id = google_bigquery_dataset.logs.dataset_id
  role       = "roles/bigquery.dataEditor"
  member     = google_logging_project_sink.gke_to_bigquery.writer_identity
  project    = var.project_id
}

# Log Sink - Application Logs to Cloud Storage
resource "google_logging_project_sink" "app_to_storage" {
  name    = "${var.cluster_name}-app-to-storage"
  project = var.project_id

  destination = "storage.googleapis.com/${google_storage_bucket.logs.name}"

  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${var.cluster_name}"
    -resource.labels.namespace_name=("kube-system" OR "kube-public" OR "kube-node-lease")
  EOT

  unique_writer_identity = true
}

# Log Sink - Error Logs to Pub/Sub for Real-time Processing
resource "google_pubsub_topic" "error_logs" {
  name    = "${var.cluster_name}-error-logs"
  project = var.project_id

  labels = merge(
    var.tags,
    {
      purpose = "logging"
      severity = "error"
    }
  )

  message_retention_duration = "86400s" # 24 hours
}

resource "google_logging_project_sink" "errors_to_pubsub" {
  name    = "${var.cluster_name}-errors-to-pubsub"
  project = var.project_id

  destination = "pubsub.googleapis.com/projects/${var.project_id}/topics/${google_pubsub_topic.error_logs.name}"

  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${var.cluster_name}"
    severity>=ERROR
  EOT

  unique_writer_identity = true
}

# Grant sink service account publish access to Pub/Sub topic
resource "google_pubsub_topic_iam_member" "log_sink_publisher" {
  topic   = google_pubsub_topic.error_logs.name
  role    = "roles/pubsub.publisher"
  member  = google_logging_project_sink.errors_to_pubsub.writer_identity
  project = var.project_id
}

# Pub/Sub Subscription for OpenSearch Integration
resource "google_pubsub_subscription" "opensearch" {
  count   = var.opensearch_endpoint != "" ? 1 : 0
  name    = "${var.cluster_name}-opensearch-sub"
  topic   = google_pubsub_topic.error_logs.name
  project = var.project_id

  ack_deadline_seconds = 20

  push_config {
    push_endpoint = var.opensearch_endpoint

    attributes = {
      x-goog-version = "v1"
    }
  }

  labels = merge(
    var.tags,
    {
      service = "opensearch"
    }
  )
}

# Log-based Metric - Request Latency
resource "google_logging_metric" "request_latency" {
  name    = "${var.cluster_name}_request_latency"
  project = var.project_id

  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${var.cluster_name}"
    jsonPayload.latency_ms>0
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "ms"

    labels {
      key         = "service"
      value_type  = "STRING"
      description = "Service name"
    }

    labels {
      key         = "endpoint"
      value_type  = "STRING"
      description = "API endpoint"
    }
  }

  value_extractor = "EXTRACT(jsonPayload.latency_ms)"

  label_extractors = {
    "service"  = "EXTRACT(resource.labels.pod_name)"
    "endpoint" = "EXTRACT(jsonPayload.endpoint)"
  }

  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 2
      scale              = 0.01
    }
  }
}

# Log-based Metric - HTTP Status Codes
resource "google_logging_metric" "http_status" {
  name    = "${var.cluster_name}_http_status"
  project = var.project_id

  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${var.cluster_name}"
    jsonPayload.status_code>0
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "status_code"
      value_type  = "STRING"
      description = "HTTP status code"
    }

    labels {
      key         = "service"
      value_type  = "STRING"
      description = "Service name"
    }
  }

  label_extractors = {
    "status_code" = "EXTRACT(jsonPayload.status_code)"
    "service"     = "EXTRACT(resource.labels.pod_name)"
  }
}

# Log-based Metric - Database Query Duration
resource "google_logging_metric" "db_query_duration" {
  name    = "${var.cluster_name}_db_query_duration"
  project = var.project_id

  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${var.cluster_name}"
    jsonPayload.query_duration_ms>0
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
    unit        = "ms"

    labels {
      key         = "database"
      value_type  = "STRING"
      description = "Database name"
    }

    labels {
      key         = "operation"
      value_type  = "STRING"
      description = "Database operation"
    }
  }

  value_extractor = "EXTRACT(jsonPayload.query_duration_ms)"

  label_extractors = {
    "database"  = "EXTRACT(jsonPayload.database)"
    "operation" = "EXTRACT(jsonPayload.operation)"
  }

  bucket_options {
    exponential_buckets {
      num_finite_buckets = 64
      growth_factor      = 2
      scale              = 0.01
    }
  }
}

# Log-based Metric - Error Count by Type
resource "google_logging_metric" "error_by_type" {
  name    = "${var.cluster_name}_error_by_type"
  project = var.project_id

  filter = <<-EOT
    resource.type="k8s_pod"
    resource.labels.cluster_name="${var.cluster_name}"
    severity>=ERROR
  EOT

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"

    labels {
      key         = "error_type"
      value_type  = "STRING"
      description = "Error type"
    }

    labels {
      key         = "namespace"
      value_type  = "STRING"
      description = "Kubernetes namespace"
    }
  }

  label_extractors = {
    "error_type" = "EXTRACT(jsonPayload.error_type)"
    "namespace"  = "EXTRACT(resource.labels.namespace_name)"
  }
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

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "opensearch_endpoint" {
  description = "OpenSearch endpoint for log ingestion"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Outputs
output "logs_bucket_name" {
  description = "Name of the Cloud Storage bucket for logs"
  value       = google_storage_bucket.logs.name
}

output "logs_dataset_id" {
  description = "BigQuery dataset ID for logs"
  value       = google_bigquery_dataset.logs.dataset_id
}

output "error_logs_topic_name" {
  description = "Name of the Pub/Sub topic for error logs"
  value       = google_pubsub_topic.error_logs.name
}

output "gke_storage_sink_id" {
  description = "ID of the GKE to Storage log sink"
  value       = google_logging_project_sink.gke_to_storage.id
}

output "gke_bigquery_sink_id" {
  description = "ID of the GKE to BigQuery log sink"
  value       = google_logging_project_sink.gke_to_bigquery.id
}
