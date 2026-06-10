# AWS EKS Module

This module creates a production-ready Amazon EKS (Elastic Kubernetes Service) cluster with managed node groups and essential add-ons.

## Features

- **Managed Node Groups**: Fully managed worker nodes with auto-scaling
- **EKS Add-ons**: VPC CNI, CoreDNS, kube-proxy, and EBS CSI driver
- **IRSA**: IAM Roles for Service Accounts (IRSA) for secure pod-level IAM permissions
- **Cluster Autoscaler**: IAM role configured for Kubernetes Cluster Autoscaler
- **AWS Load Balancer Controller**: IAM role for AWS Load Balancer Controller
- **Logging**: Control plane logs exported to CloudWatch
- **Security**: Least privilege security groups and RBAC enabled by default
- **High Availability**: Multi-AZ deployment for control plane and nodes

## Usage

```hcl
module "eks" {
  source = "../../modules/aws/eks"

  cluster_name       = "fawkes-dev-eks"
  kubernetes_version = "1.28"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids

  node_instance_types = ["t3.medium"]
  node_desired_size   = 3
  node_min_size       = 1
  node_max_size       = 10

  endpoint_private_access = true
  endpoint_public_access  = true
  api_server_authorized_ip_ranges = ["0.0.0.0/0"]

  enable_ebs_csi_driver              = true
  enable_cluster_autoscaler          = true
  enable_aws_load_balancer_controller = true

  cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  tags = {
    Environment = "dev"
    Platform    = "fawkes"
    ManagedBy   = "terraform"
  }
}
```

## Requirements

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.6.0 |
| aws       | >= 5.0.0 |
| tls       | >= 4.0.0 |

## Inputs

| Name                                | Description                        | Type           | Default                 | Required |
| ----------------------------------- | ---------------------------------- | -------------- | ----------------------- | :------: |
| cluster_name                        | Name of the EKS cluster            | `string`       | n/a                     |   yes    |
| vpc_id                              | ID of the VPC                      | `string`       | n/a                     |   yes    |
| private_subnet_ids                  | List of private subnet IDs         | `list(string)` | n/a                     |   yes    |
| public_subnet_ids                   | List of public subnet IDs          | `list(string)` | `[]`                    |    no    |
| kubernetes_version                  | Kubernetes version                 | `string`       | `"1.28"`                |    no    |
| node_instance_types                 | Instance types for nodes           | `list(string)` | `["t3.medium"]`         |    no    |
| node_desired_size                   | Desired number of nodes            | `number`       | `3`                     |    no    |
| node_min_size                       | Minimum number of nodes            | `number`       | `1`                     |    no    |
| node_max_size                       | Maximum number of nodes            | `number`       | `10`                    |    no    |
| enable_ebs_csi_driver               | Enable EBS CSI driver              | `bool`         | `true`                  |    no    |
| enable_cluster_autoscaler           | Enable Cluster Autoscaler IAM role | `bool`         | `true`                  |    no    |
| enable_aws_load_balancer_controller | Enable AWS LB Controller IAM role  | `bool`         | `true`                  |    no    |
| cluster_log_types                   | Control plane log types            | `list(string)` | `["api", "audit", ...]` |    no    |
| tags                                | Tags to apply to resources         | `map(string)`  | `{}`                    |    no    |

## Outputs

| Name                                  | Description                         |
| ------------------------------------- | ----------------------------------- |
| cluster_id                            | EKS cluster ID                      |
| cluster_name                          | EKS cluster name                    |
| cluster_endpoint                      | EKS control plane endpoint          |
| cluster_certificate_authority_data    | Certificate data for cluster        |
| oidc_provider_arn                     | ARN of OIDC provider                |
| ebs_csi_driver_role_arn               | IAM role ARN for EBS CSI driver     |
| cluster_autoscaler_role_arn           | IAM role ARN for Cluster Autoscaler |
| aws_load_balancer_controller_role_arn | IAM role ARN for AWS LB Controller  |

## Post-Deployment Steps

After deploying the EKS cluster, you need to:

1. **Configure kubectl**:

```bash
aws eks update-kubeconfig --region <region> --name <cluster-name>
```

2. **Install Cluster Autoscaler** (if enabled):

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml
kubectl -n kube-system annotate serviceaccount cluster-autoscaler eks.amazonaws.com/role-arn=<cluster_autoscaler_role_arn>
```

3. **Install AWS Load Balancer Controller** (if enabled):

```bash
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=<cluster-name> \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    EKS Control Plane                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                  │
│  │  API      │  │  etcd    │  │  Scheduler│                  │
│  │  Server   │  │          │  │           │                  │
│  └──────────┘  └──────────┘  └──────────┘                  │
│         │              │             │                        │
└─────────┼──────────────┼─────────────┼────────────────────┘
          │              │             │
   ┌──────┴──────────────┴─────────────┴──────┐
   │           VPC Private Subnets              │
   │  ┌──────────────────────────────────────┐ │
   │  │       Managed Node Group              │ │
   │  │  ┌────────┐  ┌────────┐  ┌────────┐  │ │
   │  │  │ Worker │  │ Worker │  │ Worker │  │ │
   │  │  │ Node 1 │  │ Node 2 │  │ Node 3 │  │ │
   │  │  └────────┘  └────────┘  └────────┘  │ │
   │  └──────────────────────────────────────┘ │
   │                                            │
   │  [EBS CSI Driver] [Cluster Autoscaler]    │
   │  [AWS Load Balancer Controller]           │
   └────────────────────────────────────────────┘
```

## Security Best Practices

1. **Private API Access**: Enable `endpoint_private_access` for internal access
2. **Authorized IPs**: Restrict `api_server_authorized_ip_ranges` to known IPs
3. **RBAC**: Enable Kubernetes RBAC (enabled by default)
4. **IRSA**: Use IAM Roles for Service Accounts for pod-level permissions
5. **Node Security**: Deploy nodes in private subnets
6. **Audit Logging**: Enable audit logs for compliance

## Cost Optimization

- **EKS Control Plane**: $0.10/hour (~$73/month)
- **Worker Nodes**: Use t3.medium for dev (~$30/month per node)
- **Spot Instances**: Set `node_capacity_type = "SPOT"` for non-prod (60-90% savings)
- **Cluster Autoscaler**: Automatically scale down unused nodes
- **Right-sizing**: Monitor resource usage and adjust instance types

## Examples

See the [examples directory](../examples/) for complete usage examples:

- [eks](../examples/eks/) - EKS cluster configuration
- [complete](../examples/complete/) - Complete AWS infrastructure with VPC, EKS, RDS, and S3

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.0.0 |
| <a name="requirement_tls"></a> [tls](#requirement_tls)                   | >= 4.0.0 |

## Providers

| Name                                             | Version |
| ------------------------------------------------ | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 6.27.0  |
| <a name="provider_tls"></a> [tls](#provider_tls) | 4.1.0   |

## Resources

| Name                                                                                                                                                                                        | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_cloudwatch_log_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group)                                                        | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon)                                                                              | resource |
| [aws_eks_addon.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon)                                                                       | resource |
| [aws_eks_addon.kube_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon)                                                                           | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon)                                                                              | resource |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster)                                                                             | resource |
| [aws_eks_node_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group)                                                                       | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider)                                          | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                           | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                                | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                     | resource |
| [aws_iam_role.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                         | resource |
| [aws_iam_role.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                                                             | resource |
| [aws_iam_role_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                                             | resource |
| [aws_iam_role_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy)                                                       | resource |
| [aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)                  | resource |
| [aws_iam_role_policy_attachment.cluster_amazon_eks_vpc_resource_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)         | resource |
| [aws_iam_role_policy_attachment.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)                                     | resource |
| [aws_iam_role_policy_attachment.node_group_amazon_ec2_container_registry_read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_amazon_eks_cni_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)                   | resource |
| [aws_iam_role_policy_attachment.node_group_amazon_eks_worker_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment)           | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                                                    | resource |
| [aws_security_group_rule.cluster_ingress_workstation_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule)                                | resource |

## Inputs

| Name                                                                                                                                       | Description                                                        | Type                                                                                         | Default                                                                                                       | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------ | -------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------- | :------: |
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name)                                                                      | Name of the EKS cluster                                            | `string`                                                                                     | n/a                                                                                                           |   yes    |
| <a name="input_private_subnet_ids"></a> [private_subnet_ids](#input_private_subnet_ids)                                                    | List of private subnet IDs for EKS nodes                           | `list(string)`                                                                               | n/a                                                                                                           |   yes    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                                                        | ID of the VPC where EKS cluster will be created                    | `string`                                                                                     | n/a                                                                                                           |   yes    |
| <a name="input_api_server_authorized_ip_ranges"></a> [api_server_authorized_ip_ranges](#input_api_server_authorized_ip_ranges)             | Authorized IP ranges for API server access (empty list allows all) | `list(string)`                                                                               | <pre>[<br/> "0.0.0.0/0"<br/>]</pre>                                                                           |    no    |
| <a name="input_cluster_log_retention_days"></a> [cluster_log_retention_days](#input_cluster_log_retention_days)                            | Number of days to retain cluster logs in CloudWatch                | `number`                                                                                     | `7`                                                                                                           |    no    |
| <a name="input_cluster_log_types"></a> [cluster_log_types](#input_cluster_log_types)                                                       | List of control plane logging types to enable                      | `list(string)`                                                                               | <pre>[<br/> "api",<br/> "audit",<br/> "authenticator",<br/> "controllerManager",<br/> "scheduler"<br/>]</pre> |    no    |
| <a name="input_coredns_addon_version"></a> [coredns_addon_version](#input_coredns_addon_version)                                           | Version of the CoreDNS addon                                       | `string`                                                                                     | `null`                                                                                                        |    no    |
| <a name="input_ebs_csi_driver_addon_version"></a> [ebs_csi_driver_addon_version](#input_ebs_csi_driver_addon_version)                      | Version of the EBS CSI driver addon                                | `string`                                                                                     | `null`                                                                                                        |    no    |
| <a name="input_enable_aws_load_balancer_controller"></a> [enable_aws_load_balancer_controller](#input_enable_aws_load_balancer_controller) | Enable IAM role for AWS Load Balancer Controller                   | `bool`                                                                                       | `true`                                                                                                        |    no    |
| <a name="input_enable_cluster_autoscaler"></a> [enable_cluster_autoscaler](#input_enable_cluster_autoscaler)                               | Enable IAM role for Cluster Autoscaler                             | `bool`                                                                                       | `true`                                                                                                        |    no    |
| <a name="input_enable_ebs_csi_driver"></a> [enable_ebs_csi_driver](#input_enable_ebs_csi_driver)                                           | Enable EBS CSI driver addon                                        | `bool`                                                                                       | `true`                                                                                                        |    no    |
| <a name="input_endpoint_private_access"></a> [endpoint_private_access](#input_endpoint_private_access)                                     | Enable private API server endpoint                                 | `bool`                                                                                       | `true`                                                                                                        |    no    |
| <a name="input_endpoint_public_access"></a> [endpoint_public_access](#input_endpoint_public_access)                                        | Enable public API server endpoint                                  | `bool`                                                                                       | `true`                                                                                                        |    no    |
| <a name="input_kube_proxy_addon_version"></a> [kube_proxy_addon_version](#input_kube_proxy_addon_version)                                  | Version of the kube-proxy addon                                    | `string`                                                                                     | `null`                                                                                                        |    no    |
| <a name="input_kubernetes_version"></a> [kubernetes_version](#input_kubernetes_version)                                                    | Kubernetes version to use for the EKS cluster                      | `string`                                                                                     | `"1.28"`                                                                                                      |    no    |
| <a name="input_node_capacity_type"></a> [node_capacity_type](#input_node_capacity_type)                                                    | Type of capacity for nodes (ON_DEMAND or SPOT)                     | `string`                                                                                     | `"ON_DEMAND"`                                                                                                 |    no    |
| <a name="input_node_desired_size"></a> [node_desired_size](#input_node_desired_size)                                                       | Desired number of worker nodes                                     | `number`                                                                                     | `3`                                                                                                           |    no    |
| <a name="input_node_disk_size"></a> [node_disk_size](#input_node_disk_size)                                                                | Disk size in GB for worker nodes                                   | `number`                                                                                     | `20`                                                                                                          |    no    |
| <a name="input_node_instance_types"></a> [node_instance_types](#input_node_instance_types)                                                 | List of instance types for the node group                          | `list(string)`                                                                               | <pre>[<br/> "t3.medium"<br/>]</pre>                                                                           |    no    |
| <a name="input_node_labels"></a> [node_labels](#input_node_labels)                                                                         | Key-value map of Kubernetes labels for nodes                       | `map(string)`                                                                                | `{}`                                                                                                          |    no    |
| <a name="input_node_max_size"></a> [node_max_size](#input_node_max_size)                                                                   | Maximum number of worker nodes                                     | `number`                                                                                     | `10`                                                                                                          |    no    |
| <a name="input_node_max_unavailable"></a> [node_max_unavailable](#input_node_max_unavailable)                                              | Maximum number of nodes unavailable during updates                 | `number`                                                                                     | `1`                                                                                                           |    no    |
| <a name="input_node_min_size"></a> [node_min_size](#input_node_min_size)                                                                   | Minimum number of worker nodes                                     | `number`                                                                                     | `1`                                                                                                           |    no    |
| <a name="input_node_taints"></a> [node_taints](#input_node_taints)                                                                         | List of Kubernetes taints to apply to nodes                        | <pre>list(object({<br/> key = string<br/> value = string<br/> effect = string<br/> }))</pre> | `[]`                                                                                                          |    no    |
| <a name="input_public_subnet_ids"></a> [public_subnet_ids](#input_public_subnet_ids)                                                       | List of public subnet IDs for EKS control plane ENIs               | `list(string)`                                                                               | `[]`                                                                                                          |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                              | Tags to apply to EKS resources                                     | `map(string)`                                                                                | `{}`                                                                                                          |    no    |
| <a name="input_vpc_cni_addon_version"></a> [vpc_cni_addon_version](#input_vpc_cni_addon_version)                                           | Version of the VPC CNI addon                                       | `string`                                                                                     | `null`                                                                                                        |    no    |

## Outputs

| Name                                                                                                                                               | Description                                                              |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------ |
| <a name="output_aws_load_balancer_controller_role_arn"></a> [aws_load_balancer_controller_role_arn](#output_aws_load_balancer_controller_role_arn) | ARN of IAM role for AWS Load Balancer Controller                         |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch_log_group_name](#output_cloudwatch_log_group_name)                                     | Name of the CloudWatch Log Group for cluster logs                        |
| <a name="output_cluster_arn"></a> [cluster_arn](#output_cluster_arn)                                                                               | The ARN of the EKS cluster                                               |
| <a name="output_cluster_autoscaler_role_arn"></a> [cluster_autoscaler_role_arn](#output_cluster_autoscaler_role_arn)                               | ARN of IAM role for Cluster Autoscaler                                   |
| <a name="output_cluster_certificate_authority_data"></a> [cluster_certificate_authority_data](#output_cluster_certificate_authority_data)          | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster_endpoint](#output_cluster_endpoint)                                                                | Endpoint for EKS control plane                                           |
| <a name="output_cluster_iam_role_arn"></a> [cluster_iam_role_arn](#output_cluster_iam_role_arn)                                                    | IAM role ARN of the EKS cluster                                          |
| <a name="output_cluster_id"></a> [cluster_id](#output_cluster_id)                                                                                  | The ID of the EKS cluster                                                |
| <a name="output_cluster_name"></a> [cluster_name](#output_cluster_name)                                                                            | The name of the EKS cluster                                              |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster_oidc_issuer_url](#output_cluster_oidc_issuer_url)                                           | The URL on the EKS cluster OIDC Issuer                                   |
| <a name="output_cluster_security_group_id"></a> [cluster_security_group_id](#output_cluster_security_group_id)                                     | Security group ID attached to the EKS cluster                            |
| <a name="output_cluster_version"></a> [cluster_version](#output_cluster_version)                                                                   | The Kubernetes version for the cluster                                   |
| <a name="output_ebs_csi_driver_role_arn"></a> [ebs_csi_driver_role_arn](#output_ebs_csi_driver_role_arn)                                           | ARN of IAM role for EBS CSI driver                                       |
| <a name="output_node_group_arn"></a> [node_group_arn](#output_node_group_arn)                                                                      | Amazon Resource Name (ARN) of the EKS Node Group                         |
| <a name="output_node_group_id"></a> [node_group_id](#output_node_group_id)                                                                         | EKS node group ID                                                        |
| <a name="output_node_group_role_arn"></a> [node_group_role_arn](#output_node_group_role_arn)                                                       | IAM role ARN for the node group                                          |
| <a name="output_node_group_status"></a> [node_group_status](#output_node_group_status)                                                             | Status of the EKS node group                                             |
| <a name="output_oidc_provider_arn"></a> [oidc_provider_arn](#output_oidc_provider_arn)                                                             | ARN of the OIDC Provider for EKS                                         |

<!-- END_TF_DOCS -->

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | >= 5.0.0 |
| <a name="requirement_tls"></a> [tls](#requirement_tls) | >= 4.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 6.27.0 |
| <a name="provider_tls"></a> [tls](#provider_tls) | 4.1.0 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_log_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.aws_load_balancer_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.cluster_autoscaler](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.cluster_amazon_eks_cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_amazon_eks_vpc_resource_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.ebs_csi_driver](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_amazon_ec2_container_registry_read_only](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_amazon_eks_cni_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_group_amazon_eks_worker_node_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cluster_ingress_workstation_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster_name](#input_cluster_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_private_subnet_ids"></a> [private_subnet_ids](#input_private_subnet_ids) | List of private subnet IDs for EKS nodes | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | ID of the VPC where EKS cluster will be created | `string` | n/a | yes |
| <a name="input_api_server_authorized_ip_ranges"></a> [api_server_authorized_ip_ranges](#input_api_server_authorized_ip_ranges) | Authorized IP ranges for API server access (empty list allows all) | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_cluster_log_retention_days"></a> [cluster_log_retention_days](#input_cluster_log_retention_days) | Number of days to retain cluster logs in CloudWatch | `number` | `7` | no |
| <a name="input_cluster_log_types"></a> [cluster_log_types](#input_cluster_log_types) | List of control plane logging types to enable | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_coredns_addon_version"></a> [coredns_addon_version](#input_coredns_addon_version) | Version of the CoreDNS addon | `string` | `null` | no |
| <a name="input_ebs_csi_driver_addon_version"></a> [ebs_csi_driver_addon_version](#input_ebs_csi_driver_addon_version) | Version of the EBS CSI driver addon | `string` | `null` | no |
| <a name="input_enable_aws_load_balancer_controller"></a> [enable_aws_load_balancer_controller](#input_enable_aws_load_balancer_controller) | Enable IAM role for AWS Load Balancer Controller | `bool` | `true` | no |
| <a name="input_enable_cluster_autoscaler"></a> [enable_cluster_autoscaler](#input_enable_cluster_autoscaler) | Enable IAM role for Cluster Autoscaler | `bool` | `true` | no |
| <a name="input_enable_ebs_csi_driver"></a> [enable_ebs_csi_driver](#input_enable_ebs_csi_driver) | Enable EBS CSI driver addon | `bool` | `true` | no |
| <a name="input_endpoint_private_access"></a> [endpoint_private_access](#input_endpoint_private_access) | Enable private API server endpoint | `bool` | `true` | no |
| <a name="input_endpoint_public_access"></a> [endpoint_public_access](#input_endpoint_public_access) | Enable public API server endpoint | `bool` | `true` | no |
| <a name="input_kube_proxy_addon_version"></a> [kube_proxy_addon_version](#input_kube_proxy_addon_version) | Version of the kube-proxy addon | `string` | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes_version](#input_kubernetes_version) | Kubernetes version to use for the EKS cluster | `string` | `"1.28"` | no |
| <a name="input_node_capacity_type"></a> [node_capacity_type](#input_node_capacity_type) | Type of capacity for nodes (ON_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| <a name="input_node_desired_size"></a> [node_desired_size](#input_node_desired_size) | Desired number of worker nodes | `number` | `3` | no |
| <a name="input_node_disk_size"></a> [node_disk_size](#input_node_disk_size) | Disk size in GB for worker nodes | `number` | `20` | no |
| <a name="input_node_instance_types"></a> [node_instance_types](#input_node_instance_types) | List of instance types for the node group | `list(string)` | <pre>[<br/>  "t3.medium"<br/>]</pre> | no |
| <a name="input_node_labels"></a> [node_labels](#input_node_labels) | Key-value map of Kubernetes labels for nodes | `map(string)` | `{}` | no |
| <a name="input_node_max_size"></a> [node_max_size](#input_node_max_size) | Maximum number of worker nodes | `number` | `10` | no |
| <a name="input_node_max_unavailable"></a> [node_max_unavailable](#input_node_max_unavailable) | Maximum number of nodes unavailable during updates | `number` | `1` | no |
| <a name="input_node_min_size"></a> [node_min_size](#input_node_min_size) | Minimum number of worker nodes | `number` | `1` | no |
| <a name="input_node_taints"></a> [node_taints](#input_node_taints) | List of Kubernetes taints to apply to nodes | <pre>list(object({<br/>    key    = string<br/>    value  = string<br/>    effect = string<br/>  }))</pre> | `[]` | no |
| <a name="input_public_subnet_ids"></a> [public_subnet_ids](#input_public_subnet_ids) | List of public subnet IDs for EKS control plane ENIs | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Tags to apply to EKS resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cni_addon_version"></a> [vpc_cni_addon_version](#input_vpc_cni_addon_version) | Version of the VPC CNI addon | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_aws_load_balancer_controller_role_arn"></a> [aws_load_balancer_controller_role_arn](#output_aws_load_balancer_controller_role_arn) | ARN of IAM role for AWS Load Balancer Controller |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch_log_group_name](#output_cloudwatch_log_group_name) | Name of the CloudWatch Log Group for cluster logs |
| <a name="output_cluster_arn"></a> [cluster_arn](#output_cluster_arn) | The ARN of the EKS cluster |
| <a name="output_cluster_autoscaler_role_arn"></a> [cluster_autoscaler_role_arn](#output_cluster_autoscaler_role_arn) | ARN of IAM role for Cluster Autoscaler |
| <a name="output_cluster_certificate_authority_data"></a> [cluster_certificate_authority_data](#output_cluster_certificate_authority_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster_endpoint](#output_cluster_endpoint) | Endpoint for EKS control plane |
| <a name="output_cluster_iam_role_arn"></a> [cluster_iam_role_arn](#output_cluster_iam_role_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_id"></a> [cluster_id](#output_cluster_id) | The ID of the EKS cluster |
| <a name="output_cluster_name"></a> [cluster_name](#output_cluster_name) | The name of the EKS cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster_oidc_issuer_url](#output_cluster_oidc_issuer_url) | The URL on the EKS cluster OIDC Issuer |
| <a name="output_cluster_security_group_id"></a> [cluster_security_group_id](#output_cluster_security_group_id) | Security group ID attached to the EKS cluster |
| <a name="output_cluster_version"></a> [cluster_version](#output_cluster_version) | The Kubernetes version for the cluster |
| <a name="output_ebs_csi_driver_role_arn"></a> [ebs_csi_driver_role_arn](#output_ebs_csi_driver_role_arn) | ARN of IAM role for EBS CSI driver |
| <a name="output_node_group_arn"></a> [node_group_arn](#output_node_group_arn) | Amazon Resource Name (ARN) of the EKS Node Group |
| <a name="output_node_group_id"></a> [node_group_id](#output_node_group_id) | EKS node group ID |
| <a name="output_node_group_role_arn"></a> [node_group_role_arn](#output_node_group_role_arn) | IAM role ARN for the node group |
| <a name="output_node_group_status"></a> [node_group_status](#output_node_group_status) | Status of the EKS node group |
| <a name="output_oidc_provider_arn"></a> [oidc_provider_arn](#output_oidc_provider_arn) | ARN of the OIDC Provider for EKS |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
