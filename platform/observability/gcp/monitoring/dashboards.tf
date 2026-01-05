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

# GKE Cluster Overview Dashboard
resource "google_monitoring_dashboard" "gke_cluster_overview" {
  dashboard_json = jsonencode({
    displayName = "${var.cluster_name}-gke-overview"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "GKE Control Plane CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"container.googleapis.com/container/cpu/utilization\" resource.type=\"k8s_cluster\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "CPU Utilization"
              }]
              yAxis = {
                label = "Utilization %"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "GKE Control Plane Memory Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"container.googleapis.com/container/memory/utilization\" resource.type=\"k8s_cluster\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "Memory Utilization"
              }]
              yAxis = {
                label = "Utilization %"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 4
          height = 4
          widget = {
            title = "Node Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/node/count\" resource.type=\"k8s_cluster\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "Nodes"
              }]
              yAxis = {
                label = "Count"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 4
          height = 4
          widget = {
            title = "Pod Count"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/pod/count\" resource.type=\"k8s_cluster\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "Pods"
              }]
              yAxis = {
                label = "Count"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 4
          height = 4
          widget = {
            title = "Container Restarts"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/container/restart_count\" resource.type=\"k8s_container\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.cluster_name"]
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "Restarts/sec"
              }]
              yAxis = {
                label = "Restarts per second"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# GKE Node Performance Dashboard
resource "google_monitoring_dashboard" "gke_node_performance" {
  dashboard_json = jsonencode({
    displayName = "${var.cluster_name}-gke-node-performance"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Node CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "$${resource.labels.node_name}"
              }]
              yAxis = {
                label = "CPU Utilization %"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Node Memory Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/node/memory/allocatable_utilization\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "$${resource.labels.node_name}"
              }]
              yAxis = {
                label = "Memory Utilization %"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Node Disk Usage"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/node/ephemeral_storage/allocatable_utilization\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod  = "300s"
                      perSeriesAligner = "ALIGN_MEAN"
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "$${resource.labels.node_name}"
              }]
              yAxis = {
                label = "Disk Utilization %"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Node Network Traffic"
            xyChart = {
              dataSets = [
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"kubernetes.io/node/network/received_bytes_count\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
                      aggregation = {
                        alignmentPeriod  = "300s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                  plotType        = "LINE"
                  targetAxis      = "Y1"
                  legendTemplate  = "RX: $${resource.labels.node_name}"
                },
                {
                  timeSeriesQuery = {
                    timeSeriesFilter = {
                      filter = "metric.type=\"kubernetes.io/node/network/sent_bytes_count\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
                      aggregation = {
                        alignmentPeriod  = "300s"
                        perSeriesAligner = "ALIGN_RATE"
                      }
                    }
                  }
                  plotType        = "LINE"
                  targetAxis      = "Y1"
                  legendTemplate  = "TX: $${resource.labels.node_name}"
                }
              ]
              yAxis = {
                label = "Bytes/sec"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# Application Performance Dashboard
resource "google_monitoring_dashboard" "application_performance" {
  dashboard_json = jsonencode({
    displayName = "${var.cluster_name}-app-performance"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 6
          height = 4
          widget = {
            title = "Pod CPU Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/pod/cpu/utilization\" resource.type=\"k8s_pod\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.namespace_name"]
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "$${resource.labels.namespace_name}"
              }]
              yAxis = {
                label = "CPU Utilization"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Pod Memory Utilization"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/pod/memory/utilization\" resource.type=\"k8s_pod\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_MEAN"
                      crossSeriesReducer = "REDUCE_MEAN"
                      groupByFields      = ["resource.namespace_name"]
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "$${resource.labels.namespace_name}"
              }]
              yAxis = {
                label = "Memory Utilization"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Pod Network RX Bytes"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/pod/network/received_bytes_count\" resource.type=\"k8s_pod\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.namespace_name"]
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "$${resource.labels.namespace_name}"
              }]
              yAxis = {
                label = "Bytes/sec"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Pod Network TX Bytes"
            xyChart = {
              dataSets = [{
                timeSeriesQuery = {
                  timeSeriesFilter = {
                    filter = "metric.type=\"kubernetes.io/pod/network/sent_bytes_count\" resource.type=\"k8s_pod\" resource.label.cluster_name=\"${var.cluster_name}\""
                    aggregation = {
                      alignmentPeriod    = "300s"
                      perSeriesAligner   = "ALIGN_RATE"
                      crossSeriesReducer = "REDUCE_SUM"
                      groupByFields      = ["resource.namespace_name"]
                    }
                  }
                }
                plotType        = "LINE"
                targetAxis      = "Y1"
                legendTemplate  = "$${resource.labels.namespace_name}"
              }]
              yAxis = {
                label = "Bytes/sec"
                scale = "LINEAR"
              }
              chartOptions = {
                mode = "COLOR"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
}

# Cost and Usage Dashboard
resource "google_monitoring_dashboard" "cost_usage" {
  dashboard_json = jsonencode({
    displayName = "${var.cluster_name}-cost-usage"
    mosaicLayout = {
      columns = 12
      tiles = [
        {
          width  = 12
          height = 2
          widget = {
            title = "Cost Overview"
            text = {
              content = "This dashboard displays GKE cluster cost and resource usage. Cost data is derived from BigQuery billing exports."
              format  = "MARKDOWN"
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "GKE Cluster Resource Count"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"kubernetes.io/pod/count\" resource.type=\"k8s_cluster\" resource.label.cluster_name=\"${var.cluster_name}\""
                  aggregation = {
                    alignmentPeriod    = "300s"
                    perSeriesAligner   = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_SUM"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        },
        {
          width  = 6
          height = 4
          widget = {
            title = "Average Node Utilization"
            scorecard = {
              timeSeriesQuery = {
                timeSeriesFilter = {
                  filter = "metric.type=\"kubernetes.io/node/cpu/allocatable_utilization\" resource.type=\"k8s_node\" resource.label.cluster_name=\"${var.cluster_name}\""
                  aggregation = {
                    alignmentPeriod    = "300s"
                    perSeriesAligner   = "ALIGN_MEAN"
                    crossSeriesReducer = "REDUCE_MEAN"
                  }
                }
              }
              sparkChartView = {
                sparkChartType = "SPARK_LINE"
              }
            }
          }
        }
      ]
    }
  })

  project = var.project_id
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

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Outputs
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
