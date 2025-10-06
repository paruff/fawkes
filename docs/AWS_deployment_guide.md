# Deploying Fawkes on AWS: Production Guide

## Prerequisites
- AWS Account with appropriate permissions
- AWS CLI configured
- kubectl installed
- terraform >= 1.5.0

## Architecture Overview

[Include diagram showing]:
- VPC with public/private subnets across 3 AZs
- EKS cluster in private subnets
- RDS in private subnets
- ALB in public subnets
- NAT Gateways for outbound traffic
- S3 for artifact storage
- CloudWatch for observability

## Step-by-Step Deployment

### 1. Set Up AWS Infrastructure (30 minutes)
```bash
cd infra/terraform/aws
terraform init
terraform plan -var-file=production.tfvars
terraform apply