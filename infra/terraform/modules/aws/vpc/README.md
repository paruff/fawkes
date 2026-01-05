# AWS VPC Module

This module creates a production-ready AWS VPC with public and private subnets across multiple availability zones.

## Features

- **Multi-AZ Deployment**: Creates public and private subnets across multiple availability zones for high availability
- **NAT Gateway**: Optional NAT Gateway for outbound connectivity from private subnets (with single or multi-AZ options)
- **VPC Endpoints**: Support for S3 (gateway) and ECR (interface) VPC endpoints to reduce data transfer costs
- **Flow Logs**: VPC Flow Logs to CloudWatch for network monitoring and troubleshooting
- **Security**: Least privilege security groups for VPC endpoints
- **Cost Optimization**: Automatic cost tagging and support for single NAT Gateway option

## Usage

```hcl
module "vpc" {
  source = "../../modules/aws/vpc"

  network_name         = "fawkes-dev-vpc"
  location             = "us-east-1"
  vpc_cidr             = "10.0.0.0/16"
  availability_zones   = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

  enable_nat_gateway    = true
  single_nat_gateway    = false  # Set to true for cost optimization
  enable_s3_endpoint    = true
  enable_ecr_endpoints  = true
  enable_flow_logs      = true

  tags = {
    Environment = "dev"
    Platform    = "fawkes"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| network_name | Name of the VPC | `string` | n/a | yes |
| location | AWS region for the VPC | `string` | n/a | yes |
| vpc_cidr | CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |
| availability_zones | List of availability zones for subnets | `list(string)` | n/a | yes |
| public_subnet_cidrs | CIDR blocks for public subnets | `list(string)` | n/a | yes |
| private_subnet_cidrs | CIDR blocks for private subnets | `list(string)` | n/a | yes |
| enable_nat_gateway | Enable NAT Gateway for outbound connectivity | `bool` | `true` | no |
| single_nat_gateway | Use a single NAT Gateway for cost optimization | `bool` | `false` | no |
| enable_dns_hostnames | Enable DNS hostnames in the VPC | `bool` | `true` | no |
| enable_dns_support | Enable DNS support in the VPC | `bool` | `true` | no |
| enable_s3_endpoint | Enable S3 VPC endpoint | `bool` | `true` | no |
| enable_ecr_endpoints | Enable ECR VPC endpoints | `bool` | `false` | no |
| enable_flow_logs | Enable VPC Flow Logs to CloudWatch | `bool` | `true` | no |
| flow_logs_traffic_type | Type of traffic to capture | `string` | `"ALL"` | no |
| flow_logs_retention_days | Days to retain Flow Logs | `number` | `7` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_cidr | The CIDR block of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_gateway_ids | List of NAT Gateway IDs |
| internet_gateway_id | The ID of the Internet Gateway |
| s3_endpoint_id | The ID of the S3 VPC endpoint |
| flow_log_id | The ID of the VPC Flow Log |

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          VPC (10.0.0.0/16)                       │
│                                                                   │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐       │
│  │   us-east-1a   │  │   us-east-1b   │  │   us-east-1c   │       │
│  │                │  │                │  │                │       │
│  │  ┌──────────┐  │  │  ┌──────────┐  │  │  ┌──────────┐  │       │
│  │  │  Public  │  │  │  │  Public  │  │  │  │  Public  │  │       │
│  │  │  Subnet  │  │  │  │  Subnet  │  │  │  │  Subnet  │  │       │
│  │  │ .1.0/24  │  │  │  │ .2.0/24  │  │  │  │ .3.0/24  │  │       │
│  │  └─────┬────┘  │  │  └─────┬────┘  │  │  └─────┬────┘  │       │
│  │        │       │  │        │       │  │        │       │       │
│  │    [NAT GW]   │  │    [NAT GW]   │  │    [NAT GW]   │       │
│  │        │       │  │        │       │  │        │       │       │
│  │  ┌─────┴────┐  │  │  ┌─────┴────┐  │  │  ┌─────┴────┐  │       │
│  │  │  Private │  │  │  │  Private │  │  │  │  Private │  │       │
│  │  │  Subnet  │  │  │  │  Subnet  │  │  │  │  Subnet  │  │       │
│  │  │ .11.0/24 │  │  │  │ .12.0/24 │  │  │  │ .13.0/24 │  │       │
│  │  └──────────┘  │  │  └──────────┘  │  │  └──────────┘  │       │
│  └───────────────┘  └───────────────┘  └───────────────┘       │
│                                                                   │
│  [Internet Gateway] ──────────────────────────────────────────  │
│  [S3 Endpoint] [ECR API Endpoint] [ECR DKR Endpoint]            │
└─────────────────────────────────────────────────────────────────┘
```

## Security Best Practices

1. **Private Subnets**: Deploy workloads in private subnets by default
2. **VPC Endpoints**: Use VPC endpoints to keep traffic within AWS network
3. **Flow Logs**: Enable VPC Flow Logs for security monitoring and compliance
4. **Security Groups**: Use least privilege security groups for VPC endpoints
5. **Public Access**: Block public access by default; use bastion hosts or VPN for access

## Cost Optimization

- **Single NAT Gateway**: Set `single_nat_gateway = true` to use one NAT Gateway instead of one per AZ (saves ~$32/month per AZ)
- **S3 Gateway Endpoint**: Free gateway endpoint for S3 access
- **Flow Logs Retention**: Adjust `flow_logs_retention_days` based on compliance requirements
- **Interface Endpoints**: Only enable ECR endpoints if needed (cost: ~$7.50/month per endpoint)

## Examples

See the [examples directory](../examples/) for complete usage examples:
- [vpc](../examples/vpc/) - Basic VPC configuration
- [complete](../examples/complete/) - Complete AWS infrastructure with VPC, EKS, RDS, and S3
