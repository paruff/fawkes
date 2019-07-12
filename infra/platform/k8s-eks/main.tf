terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.11"
  region  = var.region
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_availability_zones" "available" {}

locals {
  cluster_name = "k8s-${random_string.suffix.result}"

  # the commented out worker group list below shows an example of how to define
  # multiple worker groups of differing configurations
  # worker_groups = [
  #   {
  #     asg_desired_capacity = 2
  #     asg_max_size = 10
  #     asg_min_size = 2
  #     instance_type = "m4.xlarge"
  #     name = "worker_group_a"
  #     additional_userdata = "echo foo bar"
  #     subnets = "${join(",", module.vpc.private_subnets)}"
  #   },
  #   {
  #     asg_desired_capacity = 1
  #     asg_max_size = 5
  #     asg_min_size = 1
  #     instance_type = "m4.2xlarge"
  #     name = "worker_group_b"
  #     additional_userdata = "echo foo bar"
  #     subnets = "${join(",", module.vpc.private_subnets)}"
  #   },
  # ]


  # the commented out worker group tags below shows an example of how to define
  # custom tags for the worker groups ASG
  # worker_group_tags = {
  #   worker_group_a = [
  #     {
  #       key                 = "k8s.io/cluster-autoscaler/node-template/taint/nvidia.com/gpu"
  #       value               = "gpu:NoSchedule"
  #       propagate_at_launch = true
  #     },
  #   ],
  #   worker_group_b = [
  #     {
  #       key                 = "k8s.io/cluster-autoscaler/node-template/taint/nvidia.com/gpu"
  #       value               = "gpu:NoSchedule"
  #       propagate_at_launch = true
  #     },
  #   ],
  # }

  worker_groups = [
    {
      # This will launch an autoscaling group with only On-Demand instances
      instance_type        = "r4.large"
      additional_userdata  = "echo foo bar"
      subnets              = "${join(",", module.vpc.private_subnets)}"
      asg_desired_capacity = "2"
    },
  ]
  worker_groups_launch_template = [
    {
      # This will launch an autoscaling group with only Spot Fleet instances
      instance_type                            = "r5.large"
      additional_userdata                      = "echo foo bar"
      subnets                                  = "${join(",", module.vpc.private_subnets)}"
      additional_security_group_ids            = "${aws_security_group.worker_group_mgmt_one.id},${aws_security_group.worker_group_mgmt_two.id}"
      override_instance_type                   = "r5a.large"
      asg_desired_capacity                     = "2"
      spot_instance_pools                      = 10
      on_demand_percentage_above_base_capacity = "0"
    },
  ]
  tags = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
    Workspace   = "${terraform.workspace}"
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
}

resource "aws_security_group" "worker_group_mgmt_one" {
  name_prefix = "worker_group_mgmt_one"
  description = "SG to be applied to all *nix machines"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
    ]
  }
}

resource "aws_security_group" "worker_group_mgmt_two" {
  name_prefix = "worker_group_mgmt_two"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "192.168.0.0/16",
    ]
  }
}

resource "aws_security_group" "all_worker_mgmt" {
  name_prefix = "all_worker_management"
  vpc_id      = "${module.vpc.vpc_id}"

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"

    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }
}
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name           = "test-vpc-spot"
  cidr           = "10.0.0.0/16"
  azs            = data.aws_availability_zones.available.names
  public_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]

  tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
  }
}

module "eks" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = local.cluster_name
  subnets      = module.vpc.public_subnets
  vpc_id       = module.vpc.vpc_id

  worker_groups_launch_template_mixed = [
    {
      name                    = "spot-1"
      override_instance_types = ["m5.large", "m5a.large", "m5d.large", "m5ad.large"]
      spot_instance_pools     = 4
      asg_max_size            = 5
      asg_desired_capacity    = 5
      kubelet_extra_args      = "--node-labels=kubernetes.io/lifecycle=spot"
      public_ip               = true
    },
  ]
}
