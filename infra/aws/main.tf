terraform {
  required_version = ">= 1.5.7" # Required for EKS module v21
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Updated to support VPC module v6.5
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 3.0" # Matches current cluster compatibility
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = ">= 2.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "fawkes-eks-${random_string.suffix.result}"
  tags = merge(
    {
      Environment = var.environment
      Project     = "fawkes"
      Owner       = var.owner
    },
    var.extra_tags
  )
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for worker group management one"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr_one]
    description = "Allow SSH access from specific CIDR block"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
    description = "Allow all egress traffic to specific CIDR block"
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for worker group management two"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_ingress_cidr_two]
    description = "Allow SSH access from specific CIDR block"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.egress_cidr_block]
    description = "Allow all egress traffic to specific CIDR block"
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for all worker management"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_ingress_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.5"

  name                 = "fawkes-vpc"
  cidr                 = var.vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = var.private_subnets
  public_subnets       = var.public_subnets
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }

  tags = local.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 21.0" # Updated to support AWS provider 6.x

  name               = local.cluster_name
  kubernetes_version = var.eks_version
  subnet_ids         = module.vpc.private_subnets
  vpc_id             = module.vpc.vpc_id

  # Enable API and ConfigMap authentication for backward compatibility
  authentication_mode = "API_AND_CONFIG_MAP"

  eks_managed_node_groups = {
    worker_group_1 = {
      name                          = "worker-group-1"
      instance_types                = [var.worker_group_1_instance_type]
      desired_size                  = var.worker_group_1_capacity
      min_size                      = var.worker_group_1_min_size
      max_size                      = var.worker_group_1_max_size
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id]
    }
    worker_group_2 = {
      name                          = "worker-group-2"
      instance_types                = [var.worker_group_2_instance_type]
      desired_size                  = var.worker_group_2_capacity
      min_size                      = var.worker_group_2_min_size
      max_size                      = var.worker_group_2_max_size
      additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id]
    }
  }

  node_security_group_additional_rules = {
    all_worker_mgmt = {
      description = "Allow SSH from all_worker_mgmt"
      protocol    = "tcp"
      from_port   = 22
      to_port     = 22
      cidr_blocks = var.ssh_ingress_cidrs
    }
  }

  enabled_log_types                      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 7

  # Encryption config: Changed from list to object in EKS module v21
  encryption_config = var.kms_key_arn == null ? null : {
    provider_key_arn = var.kms_key_arn
    resources        = ["secrets"]
  }

  # Configure access entries (replaces aws-auth configmap in v21)
  # Note: Account-level access (map_accounts) is not supported with access entries.
  # Grant access using specific IAM principals (roles/users) instead.
  # Keys use ARN suffix to avoid state issues from list reordering
  access_entries = merge(
    # Convert map_roles to access entries
    {
      for idx, role in var.map_roles :
      "role_${replace(split("/", role.rolearn)[1], "/[^a-zA-Z0-9-]/", "_")}" => {
        principal_arn     = role.rolearn
        kubernetes_groups = role.groups
        type              = "STANDARD"
      }
    },
    # Convert map_users to access entries
    {
      for idx, user in var.map_users :
      "user_${replace(split("/", user.userarn)[1], "/[^a-zA-Z0-9-]/", "_")}" => {
        principal_arn     = user.userarn
        kubernetes_groups = user.groups
        type              = "STANDARD"
      }
    }
  )

  tags = local.tags
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}


output "vpc_id" {
  value = module.vpc.vpc_id
}