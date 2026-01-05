# VPC Example

This example demonstrates how to use the AWS VPC module to create a production-ready VPC.

## Usage

```bash
cd infra/terraform/modules/aws/examples/vpc
terraform init
terraform plan
terraform apply
```

## What This Creates

- VPC with CIDR 10.0.0.0/16
- 3 public subnets across 3 availability zones
- 3 private subnets across 3 availability zones
- Internet Gateway for public subnet internet access
- NAT Gateways for private subnet internet access
- S3 VPC endpoint for cost-free S3 access
- VPC Flow Logs to CloudWatch

## Cost Estimate

- VPC, subnets, IGW: **Free**
- NAT Gateways (3): **~$97/month** ($32.40/month each)
- VPC Flow Logs: **~$3/month** (based on 7-day retention)
- **Total: ~$100/month**

## Cost Optimization

To reduce costs for development:

```hcl
# Use single NAT Gateway
single_nat_gateway = true  # Reduces NAT cost to ~$32/month

# Or disable NAT Gateway completely for dev
enable_nat_gateway = false  # Free, but no internet from private subnets
```

## Cleanup

```bash
terraform destroy
```
