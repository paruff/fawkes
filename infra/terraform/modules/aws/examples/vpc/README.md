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

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.0.0 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name                                                                                          | Description                | Type           | Default                                                                          | Required |
| --------------------------------------------------------------------------------------------- | -------------------------- | -------------- | -------------------------------------------------------------------------------- | :------: |
| <a name="input_availability_zones"></a> [availability_zones](#input_availability_zones)       | Availability zones         | `list(string)` | <pre>[<br/> "us-east-1a",<br/> "us-east-1b",<br/> "us-east-1c"<br/>]</pre>       |    no    |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region)                               | AWS region                 | `string`       | `"us-east-1"`                                                                    |    no    |
| <a name="input_enable_ecr_endpoints"></a> [enable_ecr_endpoints](#input_enable_ecr_endpoints) | Enable ECR VPC endpoints   | `bool`         | `false`                                                                          |    no    |
| <a name="input_enable_flow_logs"></a> [enable_flow_logs](#input_enable_flow_logs)             | Enable VPC flow logs       | `bool`         | `true`                                                                           |    no    |
| <a name="input_enable_nat_gateway"></a> [enable_nat_gateway](#input_enable_nat_gateway)       | Enable NAT Gateway         | `bool`         | `true`                                                                           |    no    |
| <a name="input_enable_s3_endpoint"></a> [enable_s3_endpoint](#input_enable_s3_endpoint)       | Enable S3 VPC endpoint     | `bool`         | `true`                                                                           |    no    |
| <a name="input_environment"></a> [environment](#input_environment)                            | Environment name           | `string`       | `"dev"`                                                                          |    no    |
| <a name="input_private_subnet_cidrs"></a> [private_subnet_cidrs](#input_private_subnet_cidrs) | Private subnet CIDR blocks | `list(string)` | <pre>[<br/> "10.0.11.0/24",<br/> "10.0.12.0/24",<br/> "10.0.13.0/24"<br/>]</pre> |    no    |
| <a name="input_project_name"></a> [project_name](#input_project_name)                         | Project name               | `string`       | `"fawkes"`                                                                       |    no    |
| <a name="input_public_subnet_cidrs"></a> [public_subnet_cidrs](#input_public_subnet_cidrs)    | Public subnet CIDR blocks  | `list(string)` | <pre>[<br/> "10.0.1.0/24",<br/> "10.0.2.0/24",<br/> "10.0.3.0/24"<br/>]</pre>    |    no    |
| <a name="input_single_nat_gateway"></a> [single_nat_gateway](#input_single_nat_gateway)       | Use single NAT Gateway     | `bool`         | `false`                                                                          |    no    |
| <a name="input_vpc_cidr"></a> [vpc_cidr](#input_vpc_cidr)                                     | VPC CIDR block             | `string`       | `"10.0.0.0/16"`                                                                  |    no    |

## Outputs

| Name                                                                                      | Description        |
| ----------------------------------------------------------------------------------------- | ------------------ |
| <a name="output_nat_gateway_ids"></a> [nat_gateway_ids](#output_nat_gateway_ids)          | NAT Gateway IDs    |
| <a name="output_private_subnet_ids"></a> [private_subnet_ids](#output_private_subnet_ids) | Private subnet IDs |
| <a name="output_public_subnet_ids"></a> [public_subnet_ids](#output_public_subnet_ids)    | Public subnet IDs  |
| <a name="output_vpc_cidr"></a> [vpc_cidr](#output_vpc_cidr)                               | VPC CIDR block     |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id)                                     | VPC ID             |

<!-- END_TF_DOCS -->

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | >= 5.0.0 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_availability_zones"></a> [availability_zones](#input_availability_zones) | Availability zones | `list(string)` | <pre>[<br/>  "us-east-1a",<br/>  "us-east-1b",<br/>  "us-east-1c"<br/>]</pre> | no |
| <a name="input_aws_region"></a> [aws_region](#input_aws_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_enable_ecr_endpoints"></a> [enable_ecr_endpoints](#input_enable_ecr_endpoints) | Enable ECR VPC endpoints | `bool` | `false` | no |
| <a name="input_enable_flow_logs"></a> [enable_flow_logs](#input_enable_flow_logs) | Enable VPC flow logs | `bool` | `true` | no |
| <a name="input_enable_nat_gateway"></a> [enable_nat_gateway](#input_enable_nat_gateway) | Enable NAT Gateway | `bool` | `true` | no |
| <a name="input_enable_s3_endpoint"></a> [enable_s3_endpoint](#input_enable_s3_endpoint) | Enable S3 VPC endpoint | `bool` | `true` | no |
| <a name="input_environment"></a> [environment](#input_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_private_subnet_cidrs"></a> [private_subnet_cidrs](#input_private_subnet_cidrs) | Private subnet CIDR blocks | `list(string)` | <pre>[<br/>  "10.0.11.0/24",<br/>  "10.0.12.0/24",<br/>  "10.0.13.0/24"<br/>]</pre> | no |
| <a name="input_project_name"></a> [project_name](#input_project_name) | Project name | `string` | `"fawkes"` | no |
| <a name="input_public_subnet_cidrs"></a> [public_subnet_cidrs](#input_public_subnet_cidrs) | Public subnet CIDR blocks | `list(string)` | <pre>[<br/>  "10.0.1.0/24",<br/>  "10.0.2.0/24",<br/>  "10.0.3.0/24"<br/>]</pre> | no |
| <a name="input_single_nat_gateway"></a> [single_nat_gateway](#input_single_nat_gateway) | Use single NAT Gateway | `bool` | `false` | no |
| <a name="input_vpc_cidr"></a> [vpc_cidr](#input_vpc_cidr) | VPC CIDR block | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_nat_gateway_ids"></a> [nat_gateway_ids](#output_nat_gateway_ids) | NAT Gateway IDs |
| <a name="output_private_subnet_ids"></a> [private_subnet_ids](#output_private_subnet_ids) | Private subnet IDs |
| <a name="output_public_subnet_ids"></a> [public_subnet_ids](#output_public_subnet_ids) | Public subnet IDs |
| <a name="output_vpc_cidr"></a> [vpc_cidr](#output_vpc_cidr) | VPC CIDR block |
| <a name="output_vpc_id"></a> [vpc_id](#output_vpc_id) | VPC ID |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
