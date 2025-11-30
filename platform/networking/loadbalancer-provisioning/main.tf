terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

variable "region" {
  description = "AWS region for the Elastic IP"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_id" {
  description = "VPC ID where the load balancer will be deployed"
  type        = string
}

variable "extra_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

provider "aws" {
  region = var.region
}

locals {
  tags = merge(
    {
      Environment = var.environment
      Project     = "fawkes"
      Component   = "ingress-lb"
      ManagedBy   = "terraform"
    },
    var.extra_tags
  )
}

# Allocate Elastic IP for the Ingress Controller Load Balancer
# This provides a static IP address for DNS configuration
resource "aws_eip" "ingress_lb" {
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "fawkes-ingress-lb-eip-${var.environment}"
  })
}
