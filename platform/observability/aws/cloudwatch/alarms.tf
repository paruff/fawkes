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

# SNS Topics for Alarms
resource "aws_sns_topic" "critical_alerts" {
  name              = "${var.cluster_name}-critical-alerts"
  display_name      = "Critical Alerts for ${var.cluster_name}"
  kms_master_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-critical-alerts"
      Severity = "critical"
      Cost     = "monitoring"
    }
  )
}

resource "aws_sns_topic" "warning_alerts" {
  name              = "${var.cluster_name}-warning-alerts"
  display_name      = "Warning Alerts for ${var.cluster_name}"
  kms_master_key_id = var.kms_key_id

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-warning-alerts"
      Severity = "warning"
      Cost     = "monitoring"
    }
  )
}

# SNS Topic Subscription for Mattermost
resource "aws_sns_topic_subscription" "critical_to_mattermost" {
  count     = var.mattermost_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.critical_alerts.arn
  protocol  = "https"
  endpoint  = var.mattermost_webhook_url

  endpoint_auto_confirms = true
}

resource "aws_sns_topic_subscription" "warning_to_mattermost" {
  count     = var.mattermost_webhook_url != "" ? 1 : 0
  topic_arn = aws_sns_topic.warning_alerts.arn
  protocol  = "https"
  endpoint  = var.mattermost_webhook_url

  endpoint_auto_confirms = true
}

# EKS Control Plane CPU Alarm
resource "aws_cloudwatch_metric_alarm" "eks_control_plane_cpu_high" {
  alarm_name          = "${var.cluster_name}-control-plane-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "cluster_control_plane_cpu_utilization"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "EKS control plane CPU utilization is above 80%"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]
  ok_actions          = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-control-plane-cpu-high"
      Severity = "warning"
      Cost     = "monitoring"
    }
  )
}

# EKS Control Plane Memory Alarm
resource "aws_cloudwatch_metric_alarm" "eks_control_plane_memory_high" {
  alarm_name          = "${var.cluster_name}-control-plane-memory-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "cluster_control_plane_memory_utilization"
  namespace           = "AWS/EKS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "EKS control plane memory utilization is above 80%"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]
  ok_actions          = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-control-plane-memory-high"
      Severity = "warning"
      Cost     = "monitoring"
    }
  )
}

# Node CPU Critical Alarm
resource "aws_cloudwatch_metric_alarm" "node_cpu_critical" {
  alarm_name          = "${var.cluster_name}-node-cpu-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Node CPU utilization is critically high (>90%)"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-node-cpu-critical"
      Severity = "critical"
      Cost     = "monitoring"
    }
  )
}

# Node Memory Critical Alarm
resource "aws_cloudwatch_metric_alarm" "node_memory_critical" {
  alarm_name          = "${var.cluster_name}-node-memory-critical"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "3"
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "90"
  alarm_description   = "Node memory utilization is critically high (>90%)"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.critical_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-node-memory-critical"
      Severity = "critical"
      Cost     = "monitoring"
    }
  )
}

# Pod Restart Alarm
resource "aws_cloudwatch_metric_alarm" "pod_restart_high" {
  alarm_name          = "${var.cluster_name}-pod-restart-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "High number of pod restarts detected"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]
  ok_actions          = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-pod-restart-high"
      Severity = "warning"
      Cost     = "monitoring"
    }
  )
}

# API Server Error Rate Alarm
resource "aws_cloudwatch_log_metric_filter" "api_server_errors" {
  name           = "${var.cluster_name}-api-server-errors"
  log_group_name = "/aws/eks/${var.cluster_name}/cluster"
  pattern        = "[timestamp, request_id, ...] error"

  metric_transformation {
    name      = "ApiServerErrors"
    namespace = "EKS/${var.cluster_name}"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "api_server_error_rate_high" {
  alarm_name          = "${var.cluster_name}-api-server-error-rate-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApiServerErrors"
  namespace           = "EKS/${var.cluster_name}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "50"
  alarm_description   = "API server error rate is high"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.critical_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-api-server-error-rate-high"
      Severity = "critical"
      Cost     = "monitoring"
    }
  )
}

# Failed Pod Alarm
resource "aws_cloudwatch_log_metric_filter" "failed_pods" {
  name           = "${var.cluster_name}-failed-pods"
  log_group_name = "/aws/eks/${var.cluster_name}/cluster"
  pattern        = "[timestamp, request_id, ...] pod_status=\"Failed\""

  metric_transformation {
    name      = "FailedPods"
    namespace = "EKS/${var.cluster_name}"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_pods_high" {
  alarm_name          = "${var.cluster_name}-failed-pods-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FailedPods"
  namespace           = "EKS/${var.cluster_name}"
  period              = "300"
  statistic           = "Sum"
  threshold           = "5"
  alarm_description   = "High number of failed pods detected"
  alarm_actions       = [aws_sns_topic.critical_alerts.arn]
  ok_actions          = [aws_sns_topic.critical_alerts.arn]
  treat_missing_data  = "notBreaching"

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-failed-pods-high"
      Severity = "critical"
      Cost     = "monitoring"
    }
  )
}

# Disk Space Alarm
resource "aws_cloudwatch_metric_alarm" "node_disk_space_low" {
  alarm_name          = "${var.cluster_name}-node-disk-space-low"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "node_filesystem_utilization"
  namespace           = "ContainerInsights"
  period              = "300"
  statistic           = "Average"
  threshold           = "85"
  alarm_description   = "Node disk space utilization is above 85%"
  alarm_actions       = [aws_sns_topic.warning_alerts.arn]
  ok_actions          = [aws_sns_topic.warning_alerts.arn]

  dimensions = {
    ClusterName = var.cluster_name
  }

  tags = merge(
    var.tags,
    {
      Name     = "${var.cluster_name}-node-disk-space-low"
      Severity = "warning"
      Cost     = "monitoring"
    }
  )
}

# Variables
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "kms_key_id" {
  description = "KMS key ID for SNS topic encryption (optional)"
  type        = string
  default     = ""
}

variable "mattermost_webhook_url" {
  description = "Mattermost incoming webhook URL for alert notifications"
  type        = string
  default     = ""
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Outputs
output "critical_alerts_topic_arn" {
  description = "ARN of the critical alerts SNS topic"
  value       = aws_sns_topic.critical_alerts.arn
}

output "warning_alerts_topic_arn" {
  description = "ARN of the warning alerts SNS topic"
  value       = aws_sns_topic.warning_alerts.arn
}
