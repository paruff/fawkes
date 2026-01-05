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

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| aws | >= 5.0.0 |
| tls | >= 4.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| cluster_name | Name of the EKS cluster | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| private_subnet_ids | List of private subnet IDs | `list(string)` | n/a | yes |
| public_subnet_ids | List of public subnet IDs | `list(string)` | `[]` | no |
| kubernetes_version | Kubernetes version | `string` | `"1.28"` | no |
| node_instance_types | Instance types for nodes | `list(string)` | `["t3.medium"]` | no |
| node_desired_size | Desired number of nodes | `number` | `3` | no |
| node_min_size | Minimum number of nodes | `number` | `1` | no |
| node_max_size | Maximum number of nodes | `number` | `10` | no |
| enable_ebs_csi_driver | Enable EBS CSI driver | `bool` | `true` | no |
| enable_cluster_autoscaler | Enable Cluster Autoscaler IAM role | `bool` | `true` | no |
| enable_aws_load_balancer_controller | Enable AWS LB Controller IAM role | `bool` | `true` | no |
| cluster_log_types | Control plane log types | `list(string)` | `["api", "audit", ...]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| cluster_id | EKS cluster ID |
| cluster_name | EKS cluster name |
| cluster_endpoint | EKS control plane endpoint |
| cluster_certificate_authority_data | Certificate data for cluster |
| oidc_provider_arn | ARN of OIDC provider |
| ebs_csi_driver_role_arn | IAM role ARN for EBS CSI driver |
| cluster_autoscaler_role_arn | IAM role ARN for Cluster Autoscaler |
| aws_load_balancer_controller_role_arn | IAM role ARN for AWS LB Controller |

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
