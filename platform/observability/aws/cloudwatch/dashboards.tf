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
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0.0"
    }
  }
}

# EKS Cluster Overview Dashboard
resource "aws_cloudwatch_dashboard" "eks_cluster_overview" {
  dashboard_name = "${var.cluster_name}-eks-overview"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "EKS Control Plane CPU Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/EKS", "cluster_control_plane_cpu_utilization", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          title  = "EKS Control Plane Memory Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/EKS", "cluster_control_plane_memory_utilization", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "log"
        properties = {
          title  = "EKS Control Plane Errors"
          region = var.aws_region
          query  = <<-EOT
            SOURCE '/aws/eks/${var.cluster_name}/cluster'
            | fields @timestamp, @message
            | filter @message like /error/i
            | sort @timestamp desc
            | limit 20
          EOT
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Node Count"
          region = var.aws_region
          metrics = [
            ["AWS/EKS", "cluster_node_count", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Pod Count"
          region = var.aws_region
          metrics = [
            ["AWS/EKS", "cluster_pod_count", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}

# EKS Node Group Dashboard
resource "aws_cloudwatch_dashboard" "eks_nodegroup" {
  dashboard_name = "${var.cluster_name}-eks-nodegroup"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "Node CPU Utilization"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "CPUUtilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Node Memory Utilization"
          region = var.aws_region
          metrics = [
            ["CWAgent", "mem_used_percent", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Node Disk Usage"
          region = var.aws_region
          metrics = [
            ["CWAgent", "disk_used_percent", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          yAxis = {
            left = {
              min = 0
              max = 100
            }
          }
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Node Network In/Out"
          region = var.aws_region
          metrics = [
            ["AWS/EC2", "NetworkIn", { stat = "Average", label = "Network In" }],
            ["...", "NetworkOut", { stat = "Average", label = "Network Out" }]
          ]
          period = 300
          stat   = "Average"
        }
      }
    ]
  })
}

# Application Performance Dashboard
resource "aws_cloudwatch_dashboard" "application_performance" {
  dashboard_name = "${var.cluster_name}-app-performance"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "Container Insights - CPU Utilization"
          region = var.aws_region
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", "ClusterName", var.cluster_name, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Container Insights - Memory Utilization"
          region = var.aws_region
          metrics = [
            ["ContainerInsights", "pod_memory_utilization", "ClusterName", var.cluster_name, { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Container Insights - Network RX/TX"
          region = var.aws_region
          metrics = [
            ["ContainerInsights", "pod_network_rx_bytes", "ClusterName", var.cluster_name, { stat = "Sum", label = "RX Bytes" }],
            ["...", "pod_network_tx_bytes", "...", "...", { stat = "Sum", label = "TX Bytes" }]
          ]
          period = 300
          stat   = "Sum"
        }
      },
      {
        type = "metric"
        properties = {
          title  = "Container Restarts"
          region = var.aws_region
          metrics = [
            ["ContainerInsights", "number_of_container_restarts", "ClusterName", var.cluster_name]
          ]
          period = 300
          stat   = "Sum"
        }
      }
    ]
  })
}

# Cost and Usage Dashboard
resource "aws_cloudwatch_dashboard" "cost_usage" {
  dashboard_name = "${var.cluster_name}-cost-usage"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          title  = "EKS Control Plane Cost (Estimated)"
          region = var.aws_region
          annotations = {
            horizontal = [
              {
                label = "Monthly Cost Target"
                value = 73
              }
            ]
          }
          metrics = [
            ["AWS/Usage", "ResourceCount", "Service", "EKS", "Type", "Resource", "Resource", "Cluster"]
          ]
          period = 86400
          stat   = "Average"
        }
      },
      {
        type = "log"
        properties = {
          title  = "Top 10 Most Expensive Resources"
          region = var.aws_region
          query  = <<-EOT
            fields @timestamp, line_item_resource_id, line_item_blended_cost
            | filter line_item_product_code = 'AmazonEKS' or line_item_product_code = 'AmazonEC2'
            | stats sum(line_item_blended_cost) as cost by line_item_resource_id
            | sort cost desc
            | limit 10
          EOT
        }
      }
    ]
  })
}

# Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
