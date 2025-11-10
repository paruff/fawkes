# Fawkes AWS Production Deployment Guide

**Document Purpose**: Complete step-by-step guide for deploying Fawkes on AWS in production
**Target Audience**: DevOps engineers, Platform engineers, System administrators
**Estimated Time**: 3-4 hours for full deployment
**Last Updated**: October 7, 2025

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Pre-Deployment Planning](#pre-deployment-planning)
4. [Phase 1: AWS Foundation Setup](#phase-1-aws-foundation-setup)
5. [Phase 2: EKS Cluster Deployment](#phase-2-eks-cluster-deployment)
6. [Phase 3: Database and Storage](#phase-3-database-and-storage)
7. [Phase 4: Platform Services](#phase-4-platform-services)
8. [Phase 5: Observability Stack](#phase-5-observability-stack)
9. [Phase 6: Security Hardening](#phase-6-security-hardening)
10. [Phase 7: Validation and Testing](#phase-7-validation-and-testing)
11. [Post-Deployment Operations](#post-deployment-operations)
12. [Troubleshooting](#troubleshooting)
13. [Cost Optimization](#cost-optimization)

---

## Prerequisites

### Required Tools

Install these tools on your local machine before beginning:

```bash
# AWS CLI (version 2.x)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version  # Should be 2.x

# kubectl (Kubernetes CLI)
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

# Terraform (1.5.0 or later)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform version

# Helm (Kubernetes package manager)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

# eksctl (EKS cluster management)
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version

# jq (JSON processor - for scripts)
sudo apt-get install jq -y  # Ubuntu/Debian
# or
sudo yum install jq -y      # RHEL/CentOS
```

### AWS Account Requirements

**IAM Permissions Needed**:
- EC2 (VPC, Security Groups, EBS)
- EKS (Cluster creation and management)
- RDS (PostgreSQL instances)
- S3 (Bucket creation and management)
- IAM (Role and policy creation)
- CloudWatch (Logs and metrics)
- Certificate Manager (SSL/TLS certificates)
- Secrets Manager (Secret storage)
- Application Load Balancer
- Route53 (DNS management - optional)

**Recommended**: Use an IAM user with `AdministratorAccess` for initial setup, then lock down to least-privilege after deployment.

**Service Limits Check**:
```bash
# Check EKS cluster limit (default: 100 per region)
aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-1194D53C \
  --region us-east-1

# Check EIP limit (need at least 3 for NAT gateways)
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-0263D0A3 \
  --region us-east-1
```

### Domain and SSL (Optional but Recommended)

**For production deployments**:
- Domain name (e.g., `fawkes.yourdomain.com`)
- Access to DNS management (Route53 or external DNS provider)
- SSL certificate via AWS Certificate Manager (we'll create this)

**Without domain**:
- Can use AWS-provided Load Balancer DNS names
- Self-signed certificates (development only)

### Budget and Cost Awareness

**Expected Monthly Costs**:
- **Development**: ~$379/month
- **Staging**: ~$762/month
- **Production**: ~$2,084/month

See [AWS Cost Estimation](./AWS_COST_ESTIMATION.md) for detailed breakdown.

**Set up billing alerts**:
```bash
aws budgets create-budget \
  --account-id YOUR_ACCOUNT_ID \
  --budget file://budget.json \
  --notifications-with-subscribers file://notifications.json
```

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         AWS Region (us-east-1)               │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │                   VPC (10.0.0.0/16)                    │ │
│  │                                                        │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │   Public     │  │   Public     │  │   Public    │ │ │
│  │  │  Subnet AZ1  │  │  Subnet AZ2  │  │ Subnet AZ3  │ │ │
│  │  │ 10.0.1.0/24  │  │ 10.0.2.0/24  │  │10.0.3.0/24  │ │ │
│  │  │              │  │              │  │             │ │ │
│  │  │  NAT GW      │  │  NAT GW      │  │  NAT GW     │ │ │
│  │  │  ALB         │  │  ALB         │  │             │ │ │
│  │  └──────────────┘  └──────────────┘  └─────────────┘ │ │
│  │         │                 │                 │         │ │
│  │  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐ │ │
│  │  │   Private    │  │   Private    │  │   Private   │ │ │
│  │  │  Subnet AZ1  │  │  Subnet AZ2  │  │ Subnet AZ3  │ │ │
│  │  │ 10.0.11.0/24 │  │ 10.0.12.0/24 │  │10.0.13.0/24 │ │ │
│  │  │              │  │              │  │             │ │ │
│  │  │ EKS Nodes    │  │ EKS Nodes    │  │ EKS Nodes   │ │ │
│  │  │ RDS Primary  │  │ RDS Standby  │  │             │ │ │
│  │  └──────────────┘  └──────────────┘  └─────────────┘ │ │
│  │                                                        │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  EKS Cluster (fawkes-production)                       │ │
│  │  - Backstage Portal                                    │ │
│  │  - Jenkins CI/CD                                       │ │
│  │  - ArgoCD (GitOps)                                     │ │
│  │  - Harbor (Registry)                                   │ │
│  │  - Prometheus + Grafana                                │ │
│  │  - Mattermost                                          │ │
│  │  - Focalboard                                          │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  RDS PostgreSQL (Multi-AZ)                             │ │
│  └────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐ │
│  │  S3 Buckets                                            │ │
│  │  - Artifacts (fawkes-artifacts-prod)                   │ │
│  │  - Backups (fawkes-backups-prod)                       │ │
│  │  - Logs (fawkes-logs-prod)                             │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Network Design

**VPC CIDR**: `10.0.0.0/16` (65,536 IPs)

**Subnets**:
- **Public Subnets** (3 AZs): `10.0.1.0/24`, `10.0.2.0/24`, `10.0.3.0/24`
  - Internet Gateway attached
  - NAT Gateways deployed here
  - Application Load Balancers

- **Private Subnets** (3 AZs): `10.0.11.0/24`, `10.0.12.0/24`, `10.0.13.0/24`
  - No direct internet access
  - EKS worker nodes
  - RDS instances
  - Egress via NAT Gateways

**Why 3 Availability Zones?**
- High availability and fault tolerance
- EKS best practice (distribute nodes across AZs)
- RDS Multi-AZ automatic failover

### Component Placement

| Component | Subnet Type | Availability Zones | Accessibility |
|-----------|-------------|-------------------|---------------|
| **Internet Gateway** | N/A | Region-level | Public |
| **NAT Gateways** | Public | 3 (one per AZ) | Public IPs |
| **Application Load Balancers** | Public | 3 | Internet-facing |
| **EKS Worker Nodes** | Private | 3 | Internal only |
| **RDS PostgreSQL** | Private | 2 (Multi-AZ) | Internal only |
| **S3 Buckets** | N/A | Region-level | VPC Endpoint |

---

## Pre-Deployment Planning

### Environment Configuration

Create a `production.tfvars` file with your specific configuration:

```hcl
# production.tfvars

# General Settings
environment         = "production"
project_name        = "fawkes"
aws_region          = "us-east-1"
availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]

# VPC Configuration
vpc_cidr            = "10.0.0.0/16"
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]

# EKS Cluster Configuration
cluster_name        = "fawkes-production"
cluster_version     = "1.28"
node_instance_type  = "t3.xlarge"
node_desired_size   = 6
node_min_size       = 3
node_max_size       = 12

# RDS Configuration
db_instance_class   = "db.m5.large"
db_engine_version   = "15.4"
db_name             = "fawkes"
db_username         = "fawkesadmin"
db_multi_az         = true
db_allocated_storage = 500
db_backup_retention = 7

# S3 Bucket Names (must be globally unique)
artifacts_bucket    = "fawkes-artifacts-prod-YOUR-UNIQUE-ID"
backups_bucket      = "fawkes-backups-prod-YOUR-UNIQUE-ID"
logs_bucket         = "fawkes-logs-prod-YOUR-UNIQUE-ID"

# Domain Configuration (optional)
domain_name         = "fawkes.yourdomain.com"
create_route53_zone = false  # Set to true if you want Terraform to manage DNS

# Tags
tags = {
  Environment = "production"
  Project     = "fawkes"
  ManagedBy   = "terraform"
  Owner       = "platform-team"
  CostCenter  = "engineering"
}
```

### Secrets Management

**Generate secure passwords BEFORE deployment**:

```bash
# Generate database password
DB_PASSWORD=$(openssl rand -base64 32)
echo "Database Password: $DB_PASSWORD"  # Save this securely!

# Generate ArgoCD admin password
ARGOCD_PASSWORD=$(openssl rand -base64 24)
echo "ArgoCD Password: $ARGOCD_PASSWORD"

# Generate Jenkins admin password
JENKINS_PASSWORD=$(openssl rand -base64 24)
echo "Jenkins Password: $JENKINS_PASSWORD"

# Store in AWS Secrets Manager (we'll do this in Phase 1)
```

**IMPORTANT**: Store all passwords in a secure password manager (1Password, LastPass, etc.) immediately.

### Pre-Flight Checklist

Before proceeding, verify:

- [ ] AWS CLI configured with correct credentials (`aws sts get-caller-identity`)
- [ ] All required tools installed and correct versions
- [ ] `production.tfvars` file created with your values
- [ ] All passwords generated and stored securely
- [ ] S3 bucket names are globally unique (add your org/random suffix)
- [ ] Budget alerts configured (optional but recommended)
- [ ] Team notified of deployment window (estimated 3-4 hours)

---

## Phase 1: AWS Foundation Setup

**Duration**: 30 minutes
**Goal**: Create VPC, subnets, security groups, and IAM roles

### Step 1.1: Initialize Terraform

```bash
# Clone the Fawkes repository
git clone https://github.com/paruff/fawkes.git
cd fawkes/infra/terraform/aws

# Initialize Terraform
terraform init

# Validate configuration
terraform validate

# Plan deployment (review what will be created)
terraform plan -var-file=production.tfvars -out=tfplan
```

**Review the plan carefully**. You should see:
- 1 VPC
- 6 subnets (3 public, 3 private)
- 1 Internet Gateway
- 3 NAT Gateways
- Route tables and associations
- Security groups
- IAM roles and policies

### Step 1.2: Deploy VPC and Networking

```bash
# Apply the foundation infrastructure
terraform apply tfplan

# This will take ~10 minutes (NAT Gateways are slow to provision)
```

**Expected output**:
```
Apply complete! Resources: 42 added, 0 changed, 0 destroyed.

Outputs:
vpc_id = "vpc-0a1b2c3d4e5f6g7h8"
public_subnet_ids = ["subnet-abc123", "subnet-def456", "subnet-ghi789"]
private_subnet_ids = ["subnet-xyz123", "subnet-uvw456", "subnet-rst789"]
nat_gateway_ids = ["nat-0a1b2c3d", "nat-4e5f6g7h", "nat-8i9j0k1l"]
```

### Step 1.3: Create S3 Buckets

```bash
# Create artifacts bucket
aws s3 mb s3://fawkes-artifacts-prod-YOUR-UNIQUE-ID --region us-east-1

# Enable versioning for artifacts
aws s3api put-bucket-versioning \
  --bucket fawkes-artifacts-prod-YOUR-UNIQUE-ID \
  --versioning-configuration Status=Enabled

# Create backups bucket
aws s3 mb s3://fawkes-backups-prod-YOUR-UNIQUE-ID --region us-east-1

# Enable versioning for backups
aws s3api put-bucket-versioning \
  --bucket fawkes-backups-prod-YOUR-UNIQUE-ID \
  --versioning-configuration Status=Enabled

# Create logs bucket
aws s3 mb s3://fawkes-logs-prod-YOUR-UNIQUE-ID --region us-east-1

# Configure lifecycle policy for logs (delete after 90 days)
cat > logs-lifecycle.json <<EOF
{
  "Rules": [
    {
      "Id": "DeleteOldLogs",
      "Status": "Enabled",
      "Prefix": "",
      "Expiration": {
        "Days": 90
      }
    }
  ]
}
EOF

aws s3api put-bucket-lifecycle-configuration \
  --bucket fawkes-logs-prod-YOUR-UNIQUE-ID \
  --lifecycle-configuration file://logs-lifecycle.json

# Enable encryption at rest for all buckets
for bucket in fawkes-artifacts-prod-YOUR-UNIQUE-ID fawkes-backups-prod-YOUR-UNIQUE-ID fawkes-logs-prod-YOUR-UNIQUE-ID; do
  aws s3api put-bucket-encryption \
    --bucket $bucket \
    --server-side-encryption-configuration '{
      "Rules": [
        {
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }
      ]
    }'
done
```

### Step 1.4: Store Secrets in AWS Secrets Manager

```bash
# Store database password
aws secretsmanager create-secret \
  --name fawkes/production/db-password \
  --description "Fawkes Production Database Password" \
  --secret-string "$DB_PASSWORD" \
  --region us-east-1

# Store ArgoCD admin password
aws secretsmanager create-secret \
  --name fawkes/production/argocd-password \
  --description "ArgoCD Admin Password" \
  --secret-string "$ARGOCD_PASSWORD" \
  --region us-east-1

# Store Jenkins admin password
aws secretsmanager create-secret \
  --name fawkes/production/jenkins-password \
  --description "Jenkins Admin Password" \
  --secret-string "$JENKINS_PASSWORD" \
  --region us-east-1

# Verify secrets were created
aws secretsmanager list-secrets --region us-east-1 | grep fawkes
```

### Step 1.5: Create SSL Certificate (if using custom domain)

```bash
# Request certificate from AWS Certificate Manager
aws acm request-certificate \
  --domain-name fawkes.yourdomain.com \
  --subject-alternative-names "*.fawkes.yourdomain.com" \
  --validation-method DNS \
  --region us-east-1

# Output will include CertificateArn - save this!
# Example: arn:aws:acm:us-east-1:123456789012:certificate/abc123...

# Follow the validation instructions (add DNS records)
# Certificate validation usually takes 5-30 minutes
```

**Validation**:
```bash
# Check VPC exists
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=fawkes-production-vpc"

# Check subnets exist
aws ec2 describe-subnets --filters "Name=vpc-id,Values=YOUR_VPC_ID"

# Check NAT gateways are available
aws ec2 describe-nat-gateways --filter "Name=state,Values=available"

# Verify S3 buckets
aws s3 ls | grep fawkes

# Verify secrets
aws secretsmanager list-secrets | grep fawkes
```

---

## Phase 2: EKS Cluster Deployment

**Duration**: 20-30 minutes
**Goal**: Deploy and configure EKS cluster with worker nodes

### Step 2.1: Create EKS Cluster

```bash
# Create cluster configuration file
cat > cluster-config.yaml <<EOF
apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: fawkes-production
  region: us-east-1
  version: "1.28"

vpc:
  id: "YOUR_VPC_ID"  # From Phase 1 output
  subnets:
    private:
      us-east-1a:
        id: "PRIVATE_SUBNET_1_ID"
      us-east-1b:
        id: "PRIVATE_SUBNET_2_ID"
      us-east-1c:
        id: "PRIVATE_SUBNET_3_ID"

managedNodeGroups:
  - name: fawkes-ng-general
    instanceType: t3.xlarge
    minSize: 3
    maxSize: 12
    desiredCapacity: 6
    privateNetworking: true
    volumeSize: 200
    volumeType: gp3
    labels:
      role: general
      environment: production
    tags:
      Name: fawkes-production-node
      Environment: production
      Project: fawkes
    iam:
      withAddonPolicies:
        imageBuilder: true
        autoScaler: true
        externalDNS: true
        certManager: true
        appMesh: false
        ebs: true
        fsx: false
        efs: true
        albIngress: true
        xRay: true
        cloudWatch: true

iam:
  withOIDC: true
  serviceAccounts:
    - metadata:
        name: aws-load-balancer-controller
        namespace: kube-system
      wellKnownPolicies:
        awsLoadBalancerController: true
    - metadata:
        name: ebs-csi-controller-sa
        namespace: kube-system
      wellKnownPolicies:
        ebsCSIController: true
    - metadata:
        name: external-secrets
        namespace: external-secrets-system
      attachPolicyARNs:
        - "arn:aws:iam::aws:policy/SecretsManagerReadWrite"

cloudWatch:
  clusterLogging:
    enableTypes:
      - "api"
      - "audit"
      - "authenticator"
      - "controllerManager"
      - "scheduler"

addons:
  - name: vpc-cni
    version: latest
  - name: coredns
    version: latest
  - name: kube-proxy
    version: latest
  - name: aws-ebs-csi-driver
    version: latest
    serviceAccountRoleARN: "AUTO_GENERATED"
EOF

# Create the EKS cluster
eksctl create cluster -f cluster-config.yaml

# This takes 15-20 minutes - good time for coffee!
```

**What's happening during creation**:
1. EKS control plane provisioning (managed by AWS)
2. Worker nodes launching across 3 AZs
3. IAM roles and policies creation
4. OIDC provider setup
5. Add-ons installation (VPC CNI, CoreDNS, kube-proxy, EBS CSI)

### Step 2.2: Configure kubectl Access

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --region us-east-1 \
  --name fawkes-production

# Verify connectivity
kubectl get nodes

# Should show 6 nodes in Ready state:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-11-123.ec2.internal   Ready    <none>   2m    v1.28.x
# ip-10-0-11-124.ec2.internal   Ready    <none>   2m    v1.28.x
# ...
```

### Step 2.3: Install AWS Load Balancer Controller

```bash
# Add Helm repository
helm repo add eks https://aws.github.io/eks-charts
helm repo update

# Get your cluster VPC ID
VPC_ID=$(aws eks describe-cluster \
  --name fawkes-production \
  --query "cluster.resourcesVpcConfig.vpcId" \
  --output text)

# Install AWS Load Balancer Controller
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=fawkes-production \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set region=us-east-1 \
  --set vpcId=$VPC_ID

# Verify installation
kubectl get deployment -n kube-system aws-load-balancer-controller

# Should show:
# NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
# aws-load-balancer-controller   2/2     2            2           1m
```

### Step 2.4: Install External Secrets Operator

```bash
# Add Helm repository
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Create namespace
kubectl create namespace external-secrets-system

# Install External Secrets Operator
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --set installCRDs=true

# Verify installation
kubectl get pods -n external-secrets-system

# Create SecretStore for AWS Secrets Manager
cat <<EOF | kubectl apply -f -
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: fawkes-system
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets
EOF
```

### Step 2.5: Configure Cluster Autoscaler

```bash
# Install Cluster Autoscaler
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Patch deployment with correct cluster name
kubectl -n kube-system \
  patch deployment cluster-autoscaler \
  -p '{"spec":{"template":{"metadata":{"annotations":{"cluster-autoscaler.kubernetes.io/safe-to-evict": "false"}}}}}'

kubectl -n kube-system \
  set image deployment/cluster-autoscaler \
  cluster-autoscaler=registry.k8s.io/autoscaling/cluster-autoscaler:v1.28.0

# Add cluster name
kubectl -n kube-system \
  patch deployment cluster-autoscaler \
  --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/command/-", "value": "--node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/fawkes-production"}]'

# Verify
kubectl get pods -n kube-system | grep cluster-autoscaler
```

**Validation**:
```bash
# Check cluster status
eksctl get cluster --name fawkes-production

# Check nodes
kubectl get nodes -o wide

# Check system pods
kubectl get pods -n kube-system

# Verify service accounts
kubectl get sa -n kube-system aws-load-balancer-controller
kubectl get sa -n external-secrets-system external-secrets
```

---

## Phase 3: Database and Storage

**Duration**: 20 minutes
**Goal**: Deploy RDS PostgreSQL and configure storage classes

### Step 3.1: Create RDS PostgreSQL Instance

```bash
# Get private subnet IDs
PRIVATE_SUBNET_1=$(terraform output -raw private_subnet_ids | jq -r '.[0]')
PRIVATE_SUBNET_2=$(terraform output -raw private_subnet_ids | jq -r '.[1]')

# Create DB subnet group
aws rds create-db-subnet-group \
  --db-subnet-group-name fawkes-production-db-subnet \
  --db-subnet-group-description "Fawkes Production DB Subnet Group" \
  --subnet-ids $PRIVATE_SUBNET_1 $PRIVATE_SUBNET_2 \
  --tags Key=Environment,Value=production Key=Project,Value=fawkes

# Create security group for RDS
RDS_SG_ID=$(aws ec2 create-security-group \
  --group-name fawkes-production-rds-sg \
  --description "Fawkes Production RDS Security Group" \
  --vpc-id $VPC_ID \
  --output text)

# Allow PostgreSQL access from EKS nodes
EKS_NODE_SG=$(aws eks describe-cluster \
  --name fawkes-production \
  --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $EKS_NODE_SG

# Create RDS instance
aws rds create-db-instance \
  --db-instance-identifier fawkes-production-db \
  --db-instance-class db.m5.large \
  --engine postgres \
  --engine-version 15.4 \
  --master-username fawkesadmin \
  --master-user-password "$DB_PASSWORD" \
  --allocated-storage 500 \
  --storage-type gp3 \
  --storage-encrypted \
  --db-subnet-group-name fawkes-production-db-subnet \
  --vpc-security-group-ids $RDS_SG_ID \
  --backup-retention-period 7 \
  --preferred-backup-window "03:00-04:00" \
  --preferred-maintenance-window "sun:04:00-sun:05:00" \
  --multi-az \
  --auto-minor-version-upgrade \
  --publicly-accessible false \
  --tags Key=Name,Value=fawkes-production-db Key=Environment,Value=production

# This takes 10-15 minutes - continue with next steps while it provisions
```

### Step 3.2: Configure Kubernetes Storage Classes

```bash
# Create storage class for general purpose SSD (gp3)
cat <<EOF | kubectl apply -f -
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-retain
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
EOF

# Verify storage classes
kubectl get storageclass
```

### Step 3.3: Wait for RDS Instance and Get Endpoint

```bash
# Wait for RDS instance to be available
echo "Waiting for RDS instance to be available (this takes ~15 minutes)..."
aws rds wait db-instance-available \
  --db-instance-identifier fawkes-production-db

# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier fawkes-production-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

echo "RDS Endpoint: $RDS_ENDPOINT"

# Store RDS endpoint in Secrets Manager for easy access
aws secretsmanager create-secret \
  --name fawkes/production/db-endpoint \
  --description "Fawkes Production Database Endpoint" \
  --secret-string "$RDS_ENDPOINT" \
  --region us-east-1

# Create Kubernetes secret for database connection
kubectl create namespace fawkes-system

kubectl create secret generic postgres-credentials \
  --from-literal=host=$RDS_ENDPOINT \
  --from-literal=port=5432 \
  --from-literal=database=postgres \
  --from-literal=username=fawkesadmin \
  --from-literal=password=$DB_PASSWORD \
  -n fawkes-system
```

### Step 3.4: Initialize Database Schema

```bash
# Connect to RDS and create databases for each platform component
cat > init-databases.sql <<EOF
-- Create databases for platform components
CREATE DATABASE backstage;
CREATE DATABASE jenkins;
CREATE DATABASE argocd;
CREATE DATABASE harbor;
CREATE DATABASE mattermost;
CREATE DATABASE focalboard;

-- Create extensions
\c backstage
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c jenkins
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c argocd
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c harbor
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c mattermost
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

\c focalboard
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
EOF

# Run via temporary pod
kubectl run postgres-client --rm -i --tty \
  --image postgres:15 \
  --restart=Never \
  -n fawkes-system \
  --env="PGPASSWORD=$DB_PASSWORD" \
  -- psql -h $RDS_ENDPOINT -U fawkesadmin -d postgres -f /dev/stdin < init-databases.sql

# Verify databases were created
kubectl run postgres-client --rm -i --tty \
  --image postgres:15 \
  --restart=Never \
  -n fawkes-system \
  --env="PGPASSWORD=$DB_PASSWORD" \
  -- psql -h $RDS_ENDPOINT -U fawkesadmin -d postgres -c "\l"
```

**Validation**:
```bash
# Verify RDS instance is running
aws rds describe-db-instances \
  --db-instance-identifier fawkes-production-db \
  --query 'DBInstances[0].DBInstanceStatus' \
  --output text
# Should output: available

# Test database connectivity
kubectl run postgres-test --rm -i --tty \
  --image postgres:15 \
  --restart=Never \
  -n fawkes-system \
  --env="PGPASSWORD=$DB_PASSWORD" \
  -- psql -h $RDS_ENDPOINT -U fawkesadmin -d postgres -c "SELECT version();"

# Verify storage classes
kubectl get storageclass
```

---

## Phase 4: Platform Services

**Duration**: 45-60 minutes
**Goal**: Deploy core Fawkes platform components

### Step 4.1: Create Namespaces

```bash
# Create namespaces for platform components
kubectl create namespace backstage
kubectl create namespace jenkins
kubectl create namespace argocd
kubectl create namespace harbor
kubectl create namespace monitoring
kubectl create namespace mattermost
kubectl create namespace focalboard

# Label namespaces for better organization
kubectl label namespace backstage app.kubernetes.io/part-of=fawkes
kubectl label namespace jenkins app.kubernetes.io/part-of=fawkes
kubectl label namespace argocd app.kubernetes.io/part-of=fawkes
kubectl label namespace harbor app.kubernetes.io/part-of=fawkes
kubectl label namespace monitoring app.kubernetes.io/part-of=fawkes
kubectl label namespace mattermost app.kubernetes.io/part-of=fawkes
kubectl label namespace focalboard app.kubernetes.io/part-of=fawkes
```

### Step 4.2: Deploy ArgoCD (GitOps Engine)

```bash
# Add ArgoCD Helm repository
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Create values file for ArgoCD
cat > argocd-values.yaml <<EOF
global:
  domain: argocd.fawkes.yourdomain.com

server:
  service:
    type: ClusterIP
  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/certificate-arn: YOUR_ACM_CERT_ARN
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: '443'
    hosts:
      - argocd.fawkes.yourdomain.com

configs:
  secret:
    argocdServerAdminPassword: '$ARGOCD_PASSWORD_BCRYPT'
  cm:
    url: https://argocd.fawkes.yourdomain.com
    dex.config: |
      connectors:
        - type: github
          id: github
          name: GitHub
          config:
            clientID: YOUR_GITHUB_OAUTH_CLIENT_ID
            clientSecret: YOUR_GITHUB_OAUTH_CLIENT_SECRET
            orgs:
              - name: your-github-org

redis:
  enabled: true

repoServer:
  replicas: 2

applicationSet:
  enabled: true
EOF

# Hash the ArgoCD password for storage
ARGOCD_PASSWORD_BCRYPT=$(htpasswd -nbBC 10 "" "$ARGOCD_PASSWORD" | tr -d ':\n' | sed 's/$2y/$2a/')

# Replace in values file
sed -i "s|\$ARGOCD_PASSWORD_BCRYPT|$ARGOCD_PASSWORD_BCRYPT|g" argocd-values.yaml

# Install ArgoCD
helm install argocd argo/argo-cd \
  --namespace argocd \
  --values argocd-values.yaml \
  --version 5.51.0

# Wait for ArgoCD to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/argocd-server -n argocd

# Get ArgoCD admin password (if you didn't set it)
ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD Admin Password: $ARGOCD_ADMIN_PASSWORD"

# Get ArgoCD URL
kubectl get ingress -n argocd
```

### Step 4.3: Deploy Harbor (Container Registry)

```bash
# Add Harbor Helm repository
helm repo add harbor https://helm.goharbor.io
helm repo update

# Create values file for Harbor
cat > harbor-values.yaml <<EOF
expose:
  type: ingress
  tls:
    enabled: true
    certSource: secret
    secret:
      secretName: harbor-tls
  ingress:
    className: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/certificate-arn: YOUR_ACM_CERT_ARN
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: '443'
    hosts:
      core: harbor.fawkes.yourdomain.com

externalURL: https://harbor.fawkes.yourdomain.com

persistence:
  enabled: true
  persistentVolumeClaim:
    registry:
      storageClass: gp3
      size: 200Gi
    chartmuseum:
      storageClass: gp3
      size: 5Gi
    jobservice:
      jobLog:
        storageClass: gp3
        size: 1Gi
    database:
      storageClass: gp3
      size: 1Gi
    redis:
      storageClass: gp3
      size: 1Gi
    trivy:
      storageClass: gp3
      size: 5Gi

database:
  type: external
  external:
    host: $RDS_ENDPOINT
    port: 5432
    username: fawkesadmin
    password: $DB_PASSWORD
    coreDatabase: harbor
    notaryServerDatabase: notary_server
    notarySignerDatabase: notary_signer

harborAdminPassword: $(openssl rand -base64 16)

trivy:
  enabled: true

notary:
  enabled: false

metrics:
  enabled: true
EOF

# Install Harbor
helm install harbor harbor/harbor \
  --namespace harbor \
  --values harbor-values.yaml \
  --version 1.13.0

# Wait for Harbor to be ready (takes 5-10 minutes)
kubectl wait --for=condition=available --timeout=600s \
  deployment/harbor-core -n harbor
```

### Step 4.4: Deploy Jenkins (CI/CD)

```bash
# Add Jenkins Helm repository
helm repo add jenkins https://charts.jenkins.io
helm repo update

# Create values file for Jenkins
cat > jenkins-values.yaml <<EOF
controller:
  adminPassword: $JENKINS_PASSWORD

  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/certificate-arn: YOUR_ACM_CERT_ARN
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: '443'
    hostName: jenkins.fawkes.yourdomain.com

  resources:
    requests:
      cpu: "1000m"
      memory: "2Gi"
    limits:
      cpu: "2000m"
      memory: "4Gi"

  JCasC:
    configScripts:
      aws-credentials: |
        credentials:
          system:
            domainCredentials:
              - credentials:
                - aws:
                    accessKey: "${AWS_ACCESS_KEY_ID}"
                    description: "AWS Credentials"
                    id: "aws-credentials"
                    iamRoleArn: ""
                    scope: GLOBAL
                    secretKey: "${AWS_SECRET_ACCESS_KEY}"
      kubernetes-cloud: |
        jenkins:
          clouds:
            - kubernetes:
                name: "kubernetes"
                serverUrl: "https://kubernetes.default"
                namespace: "jenkins"
                jenkinsUrl: "http://jenkins:8080"
                jenkinsTunnel: "jenkins-agent:50000"
                containerCapStr: "10"
                templates:
                  - name: "jenkins-agent"
                    namespace: "jenkins"
                    label: "jenkins-agent"
                    containers:
                      - name: "jnlp"
                        image: "jenkins/inbound-agent:latest"
                        alwaysPullImage: true
                        workingDir: "/home/jenkins/agent"
                        ttyEnabled: true

  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - configuration-as-code:latest
    - aws-credentials:latest
    - pipeline-aws:latest
    - docker-workflow:latest
    - blueocean:latest

persistence:
  enabled: true
  storageClass: gp3-retain
  size: 100Gi

agent:
  enabled: true
  resources:
    requests:
      cpu: "500m"
      memory: "1Gi"
    limits:
      cpu: "1000m"
      memory: "2Gi"
EOF

# Install Jenkins
helm install jenkins jenkins/jenkins \
  --namespace jenkins \
  --values jenkins-values.yaml \
  --version 4.6.0

# Wait for Jenkins to be ready
kubectl wait --for=condition=available --timeout=600s \
  deployment/jenkins -n jenkins

# Get Jenkins admin password (if you didn't set it)
JENKINS_ADMIN_PASSWORD=$(kubectl exec --namespace jenkins -it svc/jenkins \
  -c jenkins -- /bin/cat /run/secrets/additional/chart-admin-password)
echo "Jenkins Admin Password: $JENKINS_ADMIN_PASSWORD"
```

### Step 4.5: Deploy Backstage (Developer Portal)

```bash
# Create Backstage configuration
cat > backstage-values.yaml <<EOF
image:
  registry: ghcr.io
  repository: backstage/backstage
  tag: latest

backstage:
  image:
    pullPolicy: Always

  extraEnvVars:
    - name: POSTGRES_HOST
      value: $RDS_ENDPOINT
    - name: POSTGRES_PORT
      value: "5432"
    - name: POSTGRES_USER
      value: fawkesadmin
    - name: POSTGRES_PASSWORD
      value: $DB_PASSWORD

  appConfig:
    app:
      title: Fawkes Platform
      baseUrl: https://backstage.fawkes.yourdomain.com

    backend:
      baseUrl: https://backstage.fawkes.yourdomain.com
      listen:
        port: 7007
      csp:
        connect-src: ["'self'", 'http:', 'https:']
      cors:
        origin: https://backstage.fawkes.yourdomain.com
        methods: [GET, POST, PUT, DELETE]
        credentials: true
      database:
        client: pg
        connection:
          host: \${POSTGRES_HOST}
          port: \${POSTGRES_PORT}
          user: \${POSTGRES_USER}
          password: \${POSTGRES_PASSWORD}
          database: backstage

    catalog:
      rules:
        - allow: [Component, System, API, Group, User, Resource, Location]
      locations:
        - type: url
          target: https://github.com/paruff/fawkes/blob/master/catalog-info.yaml

    auth:
      providers:
        github:
          development:
            clientId: \${GITHUB_CLIENT_ID}
            clientSecret: \${GITHUB_CLIENT_SECRET}

ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: YOUR_ACM_CERT_ARN
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  host: backstage.fawkes.yourdomain.com

postgresql:
  enabled: false  # Using external RDS

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi
EOF

# Install Backstage
helm install backstage backstage/backstage \
  --namespace backstage \
  --values backstage-values.yaml

# Wait for Backstage to be ready
kubectl wait --for=condition=available --timeout=600s \
  deployment/backstage -n backstage
```

### Step 4.6: Deploy Mattermost (Team Collaboration)

```bash
# Add Mattermost Helm repository
helm repo add mattermost https://helm.mattermost.com
helm repo update

# Create values file
cat > mattermost-values.yaml <<EOF
ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: YOUR_ACM_CERT_ARN
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
  hosts:
    - mattermost.fawkes.yourdomain.com

mysql:
  enabled: false

externalDB:
  enabled: true
  externalDriverType: "postgres"
  externalConnectionString: "postgres://fawkesadmin:$DB_PASSWORD@$RDS_ENDPOINT:5432/mattermost?sslmode=require"

persistence:
  data:
    enabled: true
    size: 50Gi
    storageClass: gp3
  plugins:
    enabled: true
    size: 5Gi
    storageClass: gp3

resources:
  requests:
    cpu: 500m
    memory: 1Gi
  limits:
    cpu: 1000m
    memory: 2Gi
EOF

# Install Mattermost
helm install mattermost mattermost/mattermost-team-edition \
  --namespace mattermost \
  --values mattermost-values.yaml

# Wait for Mattermost to be ready
kubectl wait --for=condition=available --timeout=600s \
  deployment/mattermost -n mattermost
```

### Step 4.7: Deploy Focalboard (Project Tracking)

```bash
# Create Focalboard deployment
cat > focalboard-deployment.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: focalboard-config
  namespace: focalboard
data:
  config.json: |
    {
      "serverRoot": "https://focalboard.fawkes.yourdomain.com",
      "port": 8000,
      "dbtype": "postgres",
      "dbconfig": "postgres://fawkesadmin:$DB_PASSWORD@$RDS_ENDPOINT:5432/focalboard?sslmode=require",
      "useSSL": false,
      "webpath": "./pack",
      "filespath": "./files",
      "telemetry": true,
      "session_expire_time": 2592000,
      "session_refresh_time": 18000,
      "localOnly": false,
      "enableLocalMode": true,
      "localModeSocketLocation": "/var/tmp/focalboard_local.socket"
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: focalboard
  namespace: focalboard
spec:
  replicas: 2
  selector:
    matchLabels:
      app: focalboard
  template:
    metadata:
      labels:
        app: focalboard
    spec:
      containers:
      - name: focalboard
        image: mattermost/focalboard:latest
        ports:
        - containerPort: 8000
        volumeMounts:
        - name: config
          mountPath: /opt/focalboard/config.json
          subPath: config.json
        - name: data
          mountPath: /opt/focalboard/files
        resources:
          requests:
            cpu: 250m
            memory: 512Mi
          limits:
            cpu: 500m
            memory: 1Gi
      volumes:
      - name: config
        configMap:
          name: focalboard-config
      - name: data
        persistentVolumeClaim:
          claimName: focalboard-data
---
apiVersion: v1
kind: Service
metadata:
  name: focalboard
  namespace: focalboard
spec:
  selector:
    app: focalboard
  ports:
  - port: 8000
    targetPort: 8000
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: focalboard-data
  namespace: focalboard
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 20Gi
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: focalboard
  namespace: focalboard
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: YOUR_ACM_CERT_ARN
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  ingressClassName: alb
  rules:
  - host: focalboard.fawkes.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: focalboard
            port:
              number: 8000
EOF

# Apply Focalboard manifests
kubectl apply -f focalboard-deployment.yaml

# Wait for Focalboard to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/focalboard -n focalboard
```

**Validation**:
```bash
# Check all platform services are running
kubectl get pods -n argocd
kubectl get pods -n harbor
kubectl get pods -n jenkins
kubectl get pods -n backstage
kubectl get pods -n mattermost
kubectl get pods -n focalboard

# Get all ingress URLs
kubectl get ingress --all-namespaces

# Test connectivity to each service
curl -k https://argocd.fawkes.yourdomain.com
curl -k https://harbor.fawkes.yourdomain.com
curl -k https://jenkins.fawkes.yourdomain.com
curl -k https://backstage.fawkes.yourdomain.com
curl -k https://mattermost.fawkes.yourdomain.com
curl -k https://focalboard.fawkes.yourdomain.com
```

---

## Phase 5: Observability Stack

**Duration**: 30 minutes
**Goal**: Deploy Prometheus, Grafana, and logging infrastructure

### Step 5.1: Deploy Prometheus Stack

```bash
# Add Prometheus Helm repository
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create values file
cat > prometheus-values.yaml <<EOF
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 100Gi
    resources:
      requests:
        cpu: 500m
        memory: 2Gi
      limits:
        cpu: 1000m
        memory: 4Gi

grafana:
  enabled: true
  adminPassword: $(openssl rand -base64 16)

  ingress:
    enabled: true
    ingressClassName: alb
    annotations:
      alb.ingress.kubernetes.io/scheme: internet-facing
      alb.ingress.kubernetes.io/target-type: ip
      alb.ingress.kubernetes.io/certificate-arn: YOUR_ACM_CERT_ARN
      alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
      alb.ingress.kubernetes.io/ssl-redirect: '443'
    hosts:
      - grafana.fawkes.yourdomain.com

  persistence:
    enabled: true
    storageClassName: gp3
    size: 10Gi

  datasources:
    datasources.yaml:
      apiVersion: 1
      datasources:
      - name: Prometheus
        type: prometheus
        url: http://prometheus-operated:9090
        isDefault: true

  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp3
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

kubeStateMetrics:
  enabled: true

nodeExporter:
  enabled: true
EOF

# Install Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values prometheus-values.yaml \
  --version 51.0.0

# Wait for Prometheus to be ready
kubectl wait --for=condition=available --timeout=600s \
  deployment/prometheus-grafana -n monitoring
```

### Step 5.2: Deploy DORA Metrics Exporter

```bash
# Create DORA metrics collection service
cat > dora-metrics-exporter.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: dora-exporter-config
  namespace: monitoring
data:
  config.yaml: |
    argocd:
      url: https://argocd.fawkes.yourdomain.com
      token: \${ARGOCD_TOKEN}
    jenkins:
      url: https://jenkins.fawkes.yourdomain.com
      username: admin
      token: \${JENKINS_TOKEN}
    prometheus:
      port: 9090
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dora-metrics-exporter
  namespace: monitoring
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dora-metrics-exporter
  template:
    metadata:
      labels:
        app: dora-metrics-exporter
    spec:
      containers:
      - name: exporter
        image: fawkes/dora-metrics-exporter:latest  # TODO: Build this image
        ports:
        - containerPort: 9090
        envFrom:
        - secretRef:
            name: dora-exporter-secrets
        volumeMounts:
        - name: config
          mountPath: /app/config.yaml
          subPath: config.yaml
      volumes:
      - name: config
        configMap:
          name: dora-exporter-config
---
apiVersion: v1
kind: Service
metadata:
  name: dora-metrics-exporter
  namespace: monitoring
  labels:
    app: dora-metrics-exporter
spec:
  ports:
  - port: 9090
    targetPort: 9090
    name: metrics
  selector:
    app: dora-metrics-exporter
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: dora-metrics
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: dora-metrics-exporter
  endpoints:
  - port: metrics
    interval: 60s
EOF

# Apply DORA metrics exporter
kubectl apply -f dora-metrics-exporter.yaml
```

### Step 5.3: Import DORA Metrics Dashboards

```bash
# Create DORA metrics dashboard
cat > dora-dashboard.json <<'EOF'
{
  "dashboard": {
    "title": "DORA Metrics - Fawkes Platform",
    "tags": ["dora", "platform"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Deployment Frequency",
        "targets": [
          {
            "expr": "sum(rate(deployments_total[7d]))",
            "legendFormat": "Deployments per day"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Lead Time for Changes",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(lead_time_seconds_bucket[7d]))",
            "legendFormat": "p95 Lead Time"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Mean Time to Restore (MTTR)",
        "targets": [
          {
            "expr": "avg(mttr_seconds) / 60",
            "legendFormat": "MTTR (minutes)"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Change Failure Rate",
        "targets": [
          {
            "expr": "(sum(failed_deployments_total) / sum(deployments_total)) * 100",
            "legendFormat": "Failure Rate (%)"
          }
        ],
        "type": "gauge"
      }
    ]
  }
}
EOF

# Import dashboard to Grafana
GRAFANA_POD=$(kubectl get pod -n monitoring -l "app.kubernetes.io/name=grafana" -o jsonpath="{.items[0].metadata.name}")

kubectl exec -n monitoring $GRAFANA_POD -- \
  curl -X POST http://localhost:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @/tmp/dora-dashboard.json

# Upload the dashboard file first
kubectl cp dora-dashboard.json monitoring/$GRAFANA_POD:/tmp/
```

**Validation**:
```bash
# Check Prometheus is scraping targets
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &
curl http://localhost:9090/api/v1/targets

# Access Grafana
kubectl get ingress -n monitoring

# Get Grafana admin password
kubectl get secret -n monitoring prometheus-grafana \
  -o jsonpath="{.data.admin-password}" | base64 --decode; echo
```

---

## Phase 6: Security Hardening

**Duration**: 20 minutes
**Goal**: Implement security best practices

### Step 6.1: Deploy Trivy Operator (Vulnerability Scanning)

```bash
# Add Aqua Security Helm repository
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

# Install Trivy Operator
helm install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --set="trivy.ignoreUnfixed=true"

# Wait for Trivy to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/trivy-operator -n trivy-system
```

### Step 6.2: Deploy Kyverno (Policy Enforcement)

```bash
# Add Kyverno Helm repository
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Install Kyverno
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace

# Wait for Kyverno to be ready
kubectl wait --for=condition=available --timeout=300s \
  deployment/kyverno -n kyverno

# Apply baseline policies
kubectl apply -f https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-privileged-containers/disallow-privileged-containers.yaml
kubectl apply -f https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-host-namespaces/disallow-host-namespaces.yaml
kubectl apply -f https://raw.githubusercontent.com/kyverno/policies/main/pod-security/baseline/disallow-host-path/disallow-host-path.yaml

# Create custom policy for required labels
cat <<EOF | kubectl apply -f -
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-labels
spec:
  validationFailureAction: audit
  background: true
  rules:
  - name: check-for-labels
    match:
      any:
      - resources:
          kinds:
          - Pod
          - Deployment
          - Service
    validate:
      message: "Labels 'app.kubernetes.io/name' and 'app.kubernetes.io/part-of' are required."
      pattern:
        metadata:
          labels:
            app.kubernetes.io/name: "?*"
            app.kubernetes.io/part-of: "fawkes"
EOF
```

### Step 6.3: Configure Network Policies

```bash
# Create network policies for each namespace
cat <<EOF | kubectl apply -f -
# Allow Backstage to communicate with all services
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backstage-egress
  namespace: backstage
spec:
  podSelector:
    matchLabels:
      app: backstage
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 8080
  - to:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 5432  # PostgreSQL
---
# ArgoCD network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: argocd-network-policy
  namespace: argocd
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/part-of: argocd
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 443
  egress:
  - to:
    - namespaceSelector: {}
  - to:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 22  # Git SSH
---
# Jenkins network policy
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: jenkins-network-policy
  namespace: jenkins
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: jenkins
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 8080
    - protocol: TCP
      port: 50000  # JNLP agent port
  egress:
  - to:
    - namespaceSelector: {}
---
# Monitoring namespace - allow all (needs to scrape metrics)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-egress
  namespace: monitoring
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector: {}
EOF
```

### Step 6.4: Enable Pod Security Standards

```bash
# Apply Pod Security Standards to namespaces
kubectl label namespace backstage pod-security.kubernetes.io/enforce=baseline
kubectl label namespace jenkins pod-security.kubernetes.io/enforce=baseline
kubectl label namespace argocd pod-security.kubernetes.io/enforce=baseline
kubectl label namespace harbor pod-security.kubernetes.io/enforce=baseline
kubectl label namespace mattermost pod-security.kubernetes.io/enforce=baseline
kubectl label namespace focalboard pod-security.kubernetes.io/enforce=baseline
kubectl label namespace monitoring pod-security.kubernetes.io/enforce=baseline

# Audit mode for system namespaces
kubectl label namespace kube-system pod-security.kubernetes.io/audit=restricted
kubectl label namespace kube-system pod-security.kubernetes.io/warn=restricted
```

### Step 6.5: Configure RBAC

```bash
# Create read-only role for developers
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fawkes-developer
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["pods/log"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fawkes-operator
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods/exec", "pods/portforward"]
  verbs: ["create"]
---
# Bind roles to groups (configure based on your IdP)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fawkes-developers
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fawkes-developer
subjects:
- kind: Group
  name: fawkes-developers
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fawkes-operators
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fawkes-operator
subjects:
- kind: Group
  name: fawkes-operators
  apiGroup: rbac.authorization.k8s.io
EOF
```

**Validation**:
```bash
# Check Trivy is scanning
kubectl get vulnerabilityreports -A

# Check Kyverno policies
kubectl get clusterpolicy

# Verify network policies
kubectl get networkpolicies -A

# Test RBAC (as a developer user)
kubectl auth can-i delete pods --as=system:serviceaccount:default:developer
# Should return "no"
```

---

## Phase 7: Validation and Testing

**Duration**: 30 minutes
**Goal**: Verify all components are working correctly

### Step 7.1: Component Health Checks

```bash
# Create health check script
cat > health-check.sh <<'EOF'
#!/bin/bash

echo "========================================="
echo "Fawkes Platform Health Check"
echo "========================================="
echo ""

# Check cluster health
echo "1. EKS Cluster Status:"
aws eks describe-cluster --name fawkes-production --query 'cluster.status' --output text
echo ""

# Check node health
echo "2. Node Status:"
kubectl get nodes -o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[3].type,VERSION:.status.nodeInfo.kubeletVersion
echo ""

# Check RDS status
echo "3. RDS Database Status:"
aws rds describe-db-instances --db-instance-identifier fawkes-production-db --query 'DBInstances[0].DBInstanceStatus' --output text
echo ""

# Check all pods
echo "4. Pod Status by Namespace:"
for ns in argocd harbor jenkins backstage mattermost focalboard monitoring; do
  echo "  Namespace: $ns"
  kubectl get pods -n $ns -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount
  echo ""
done

# Check ingresses
echo "5. Ingress Endpoints:"
kubectl get ingress -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTS:.spec.rules[0].host,ADDRESS:.status.loadBalancer.ingress[0].hostname
echo ""

# Check PVC status
echo "6. Persistent Volume Claims:"
kubectl get pvc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage
echo ""

# Check certificates (if using cert-manager)
echo "7. SSL Certificates:"
aws acm list-certificates --region us-east-1 --query 'CertificateSummaryList[?contains(DomainName, `fawkes`)]' --output table
echo ""

echo "========================================="
echo "Health Check Complete"
echo "========================================="
EOF

chmod +x health-check.sh
./health-check.sh
```

### Step 7.2: Connectivity Tests

```bash
# Test external connectivity to all services
cat > connectivity-test.sh <<'EOF'
#!/bin/bash

SERVICES=(
  "https://argocd.fawkes.yourdomain.com"
  "https://harbor.fawkes.yourdomain.com"
  "https://jenkins.fawkes.yourdomain.com"
  "https://backstage.fawkes.yourdomain.com"
  "https://mattermost.fawkes.yourdomain.com"
  "https://focalboard.fawkes.yourdomain.com"
  "https://grafana.fawkes.yourdomain.com"
)

echo "Testing connectivity to all services..."
echo ""

for service in "${SERVICES[@]}"; do
  status_code=$(curl -k -s -o /dev/null -w "%{http_code}" "$service")
  if [ "$status_code" -eq 200 ] || [ "$status_code" -eq 302 ] || [ "$status_code" -eq 401 ]; then
    echo "✓ $service - OK (HTTP $status_code)"
  else
    echo "✗ $service - FAILED (HTTP $status_code)"
  fi
done

echo ""
echo "Connectivity test complete"
EOF

chmod +x connectivity-test.sh
./connectivity-test.sh
```

### Step 7.3: Deploy Test Application

```bash
# Create a test application to verify the full pipeline
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Namespace
metadata:
  name: fawkes-test
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-fawkes
  namespace: fawkes-test
spec:
  replicas: 2
  selector:
    matchLabels:
      app: hello-fawkes
  template:
    metadata:
      labels:
        app: hello-fawkes
        app.kubernetes.io/name: hello-fawkes
        app.kubernetes.io/part-of: fawkes
    spec:
      containers:
      - name: hello
        image: nginxdemos/hello:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
---
apiVersion: v1
kind: Service
metadata:
  name: hello-fawkes
  namespace: fawkes-test
spec:
  selector:
    app: hello-fawkes
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: hello-fawkes
  namespace: fawkes-test
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
spec:
  ingressClassName: alb
  rules:
  - host: hello.fawkes.yourdomain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: hello-fawkes
            port:
              number: 80
EOF

# Wait for deployment
kubectl wait --for=condition=available --timeout=300s \
  deployment/hello-fawkes -n fawkes-test

# Get the ingress URL
kubectl get ingress hello-fawkes -n fawkes-test

# Test the application
sleep 60  # Wait for ALB to register targets
curl http://hello.fawkes.yourdomain.com
```

### Step 7.4: Verify DORA Metrics Collection

```bash
# Check if Prometheus is collecting metrics
kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090 &
PF_PID=$!

sleep 5

# Query deployment metrics
curl -s 'http://localhost:9090/api/v1/query?query=deployments_total' | jq

# Query lead time metrics
curl -s 'http://localhost:9090/api/v1/query?query=lead_time_seconds_count' | jq

# Query MTTR metrics
curl -s 'http://localhost:9090/api/v1/query?query=mttr_seconds' | jq

# Stop port-forward
kill $PF_PID
```

### Step 7.5: Security Scan

```bash
# Run Trivy scan on all namespaces
kubectl get vulnerabilityreports -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,CRITICAL:.report.summary.criticalCount,HIGH:.report.summary.highCount

# Check Kyverno policy reports
kubectl get policyreport -A

# Test network policies
kubectl run test-pod --image=busybox --rm -it --restart=Never -- /bin/sh
# Inside the pod, try to access services
# wget -O- http://jenkins.jenkins.svc.cluster.local:8080
# Should succeed or fail based on network policies
```

**Validation Checklist**:

- [ ] All nodes are in Ready state
- [ ] All pods are Running (no CrashLoopBackOff)
- [ ] RDS database is available
- [ ] All ingresses have ALB addresses
- [ ] All services respond to HTTP requests (200, 302, or 401)
- [ ] Test application deployed successfully
- [ ] Prometheus collecting metrics
- [ ] No critical vulnerabilities in running containers
- [ ] Network policies enforced
- [ ] RBAC working correctly

---

## Post-Deployment Operations

### DNS Configuration

If you're using Route53 or external DNS:

```bash
# Get all ALB DNS names
kubectl get ingress -A -o jsonpath='{range .items[*]}{.spec.rules[0].host}{"\t"}{.status.loadBalancer.ingress[0].hostname}{"\n"}{end}'

# Create Route53 records (if using Route53)
# For each service, create a CNAME record pointing to the ALB DNS name

# Example for ArgoCD:
aws route53 change-resource-record-sets \
  --hosted-zone-id YOUR_HOSTED_ZONE_ID \
  --change-batch '{
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "argocd.fawkes.yourdomain.com",
          "Type": "CNAME",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "k8s-argocd-abc123-1234567890.us-east-1.elb.amazonaws.com"
            }
          ]
        }
      }
    ]
  }'

# Repeat for all services
```

### Configure Backups

```bash
# Install Velero for cluster backups
helm repo add vmware-tanzu https://vmware-tanzu.github.io/helm-charts
helm repo update

# Create S3 bucket for backups (if not already created)
aws s3 mb s3://fawkes-velero-backups-prod-YOUR-UNIQUE-ID --region us-east-1

# Create IAM policy for Velero
cat > velero-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeVolumes",
        "ec2:DescribeSnapshots",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:CreateSnapshot",
        "ec2:DeleteSnapshot"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:AbortMultipartUpload",
        "s3:ListMultipartUploadParts"
      ],
      "Resource": [
        "arn:aws:s3:::fawkes-velero-backups-prod-YOUR-UNIQUE-ID/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::fawkes-velero-backups-prod-YOUR-UNIQUE-ID"
      ]
    }
  ]
}
EOF

aws iam create-policy \
  --policy-name FawkesVeleroPolicy \
  --policy-document file://velero-policy.json

# Install Velero
helm install velero vmware-tanzu/velero \
  --namespace velero \
  --create-namespace \
  --set-file credentials.secretContents.cloud=<(echo "[default]
aws_access_key_id=$AWS_ACCESS_KEY_ID
aws_secret_access_key=$AWS_SECRET_ACCESS_KEY") \
  --set configuration.provider=aws \
  --set configuration.backupStorageLocation.bucket=fawkes-velero-backups-prod-YOUR-UNIQUE-ID \
  --set configuration.backupStorageLocation.config.region=us-east-1 \
  --set configuration.volumeSnapshotLocation.config.region=us-east-1 \
  --set initContainers[0].name=velero-plugin-for-aws \
  --set initContainers[0].image=velero/velero-plugin-for-aws:v1.8.0 \
  --set initContainers[0].volumeMounts[0].mountPath=/target \
  --set initContainers[0].volumeMounts[0].name=plugins

# Create daily backup schedule
velero schedule create daily-backup \
  --schedule="0 2 * * *" \
  --ttl 720h0m0s

# Test backup
velero backup create test-backup --wait
velero backup describe test-backup
```

### Configure Monitoring and Alerting

```bash
# Create AlertManager configuration
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: alertmanager-config
  namespace: monitoring
data:
  alertmanager.yml: |
    global:
      resolve_timeout: 5m

    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'fawkes-team'

    receivers:
    - name: 'fawkes-team'
      email_configs:
      - to: 'alerts@yourdomain.com'
        from: 'fawkes-alerts@yourdomain.com'
        smarthost: 'smtp.gmail.com:587'
        auth_username: 'fawkes-alerts@yourdomain.com'
        auth_password: 'YOUR_SMTP_PASSWORD'
        headers:
          Subject: '{{ template "email.default.subject" . }}'
      slack_configs:
      - api_url: 'YOUR_SLACK_WEBHOOK_URL'
        channel: '#fawkes-alerts'
        title: '{{ template "slack.default.title" . }}'
        text: '{{ template "slack.default.text" . }}'
EOF

# Restart AlertManager to pick up new config
kubectl rollout restart statefulset/alertmanager-prometheus-kube-prometheus-alertmanager -n monitoring
```

### Set Up Cost Monitoring

```bash
# Tag all resources for cost allocation
CLUSTER_NAME="fawkes-production"

# Tag EKS cluster
aws eks tag-resource \
  --resource-arn $(aws eks describe-cluster --name $CLUSTER_NAME --query 'cluster.arn' --output text) \
  --tags Environment=production,Project=fawkes,CostCenter=engineering

# Tag RDS instance
aws rds add-tags-to-resource \
  --resource-name $(aws rds describe-db-instances --db-instance-identifier fawkes-production-db --query 'DBInstances[0].DBInstanceArn' --output text) \
  --tags Key=Environment,Value=production Key=Project,Value=fawkes Key=CostCenter,Value=engineering

# Tag S3 buckets
for bucket in fawkes-artifacts-prod-YOUR-UNIQUE-ID fawkes-backups-prod-YOUR-UNIQUE-ID fawkes-logs-prod-YOUR-UNIQUE-ID; do
  aws s3api put-bucket-tagging \
    --bucket $bucket \
    --tagging 'TagSet=[{Key=Environment,Value=production},{Key=Project,Value=fawkes},{Key=CostCenter,Value=engineering}]'
done

# Set up AWS Cost Explorer filters
echo "Configure Cost Explorer to filter by tags: Project=fawkes"
```

### Documentation

```bash
# Create deployment documentation
cat > DEPLOYMENT_RECORD.md <<EOF
# Fawkes Production Deployment Record

**Deployment Date**: $(date)
**Deployed By**: $(whoami)
**AWS Region**: us-east-1

## Infrastructure Details

### EKS Cluster
- **Name**: fawkes-production
- **Version**: 1.28
- **Nodes**: 6 x t3.xlarge
- **VPC ID**: $VPC_ID

### RDS Database
- **Identifier**: fawkes-production-db
- **Instance Class**: db.m5.large
- **Engine**: PostgreSQL 15.4
- **Multi-AZ**: Yes
- **Endpoint**: $RDS_ENDPOINT

### S3 Buckets
- Artifacts: fawkes-artifacts-prod-YOUR-UNIQUE-ID
- Backups: fawkes-backups-prod-YOUR-UNIQUE-ID
- Logs: fawkes-logs-prod-YOUR-UNIQUE-ID

### Service Endpoints
$(kubectl get ingress -A -o custom-columns=SERVICE:.metadata.name,URL:.spec.rules[0].host --no-headers)

## Access Credentials

**Stored in AWS Secrets Manager**:
- fawkes/production/db-password
- fawkes/production/argocd-password
- fawkes/production/jenkins-password
- fawkes/production/db-endpoint

## Component Versions

**Platform Services**:
- ArgoCD: 5.51.0
- Harbor: 1.13.0
- Jenkins: 4.6.0
- Backstage: latest
- Mattermost: latest
- Focalboard: latest

**Observability**:
- Prometheus Stack: 51.0.0
- Grafana: (included in Prometheus stack)

**Security**:
- Trivy Operator: latest
- Kyverno: latest

## Next Steps

1. Configure DNS records for all services
2. Set up monitoring alerts
3. Configure backup retention policies
4. Onboard first users
5. Deploy first application

## Maintenance Windows

- **Preferred Maintenance**: Sundays 04:00-05:00 UTC
- **Backup Windows**: Daily 03:00-04:00 UTC

## Support Contacts

- Platform Team: platform-team@yourdomain.com
- AWS Support: [Your AWS Support Plan]
- On-Call: [PagerDuty/On-Call System]

EOF

cat DEPLOYMENT_RECORD.md
```

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Pods stuck in Pending state

**Symptoms**:
```bash
kubectl get pods -A | grep Pending
```

**Diagnosis**:
```bash
# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Common causes:
# 1. Insufficient resources
kubectl describe nodes | grep -A 5 "Allocated resources"

# 2. PVC not bound
kubectl get pvc -A | grep Pending

# 3. Node selector/affinity issues
kubectl get pod <pod-name> -n <namespace> -o yaml | grep -A 10 nodeSelector
```

**Solutions**:
```bash
# Scale up nodes if resource constrained
eksctl scale nodegroup --cluster=fawkes-production --nodes=9 --name=fawkes-ng-general

# Check storage class
kubectl get storageclass

# Fix PVC issues
kubectl describe pvc <pvc-name> -n <namespace>
```

#### Issue: Cannot access services via ingress

**Symptoms**:
```bash
curl https://argocd.fawkes.yourdomain.com
# Returns timeout or connection refused
```

**Diagnosis**:
```bash
# Check ingress status
kubectl get ingress -A
kubectl describe ingress <ingress-name> -n <namespace>

# Check ALB controller logs
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller

# Check target groups in AWS console
aws elbv2 describe-target-groups --region us-east-1

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

**Solutions**:
```bash
# Restart ALB controller
kubectl rollout restart deployment/aws-load-balancer-controller -n kube-system

# Check certificate ARN is correct
kubectl get ingress <ingress-name> -n <namespace> -o yaml | grep certificate-arn

# Verify DNS resolution
nslookup argocd.fawkes.yourdomain.com
```

#### Issue: Database connection failures

**Symptoms**:
```bash
# Pods crashlooping with database errors
kubectl logs <pod-name> -n <namespace> | grep -i "database\|postgres"
```

**Diagnosis**:
```bash
# Check RDS status
aws rds describe-db-instances --db-instance-identifier fawkes-production-db

# Test connectivity from cluster
kubectl run postgres-test --rm -i --tty \
  --image postgres:15 \
  --restart=Never \
  --env="PGPASSWORD=$DB_PASSWORD" \
  -- psql -h $RDS_ENDPOINT -U fawkesadmin -d postgres -c "SELECT 1"

# Check security group rules
aws ec2 describe-security-groups --group-ids <rds-sg-id>
```

**Solutions**:
```bash
# Verify security group allows traffic from EKS nodes
EKS_NODE_SG=$(aws eks describe-cluster --name fawkes-production --query "cluster.resourcesVpcConfig.clusterSecurityGroupId" --output text)

aws ec2 authorize-security-group-ingress \
  --group-id $RDS_SG_ID \
  --protocol tcp \
  --port 5432 \
  --source-group $EKS_NODE_SG

# Check secrets are correct
kubectl get secret postgres-credentials -n fawkes-system -o yaml
```

#### Issue: High AWS costs

**Diagnosis**:
```bash
# Check current month's costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=SERVICE

# Identify expensive resources
kubectl top nodes
kubectl top pods -A
```

**Solutions**:
```bash
# Right-size nodes
eksctl scale nodegroup --cluster=fawkes-production --nodes=3 --name=fawkes-ng-general

# Delete unused EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available --query 'Volumes[*].[VolumeId,Size,CreateTime]' --output table

# Configure auto-scaling
# (Already configured in Step 2.5)

# Use Spot instances for dev/staging
# Edit nodegroup configuration to use Spot

# Set up AWS Budgets alerts
aws budgets create-budget \
  --account-id $(aws sts get-caller-identity --query Account --output text) \
  --budget file://budget-alert.json
```

#### Issue: Certificate validation pending

**Symptoms**:
```bash
aws acm describe-certificate --certificate-arn <cert-arn> | grep Status
# Returns: PENDING_VALIDATION
```

**Solutions**:
```bash
# Get validation records
aws acm describe-certificate --certificate-arn <cert-arn> --query 'Certificate.DomainValidationOptions[0].ResourceRecord'

# Add DNS record for validation
# In Route53 or your DNS provider, create a CNAME record with the values returned above

# Wait for validation (can take 5-30 minutes)
aws acm wait certificate-validated --certificate-arn <cert-arn>
```

---

## Cost Optimization

### Immediate Optimizations (Week 1)

```bash
# 1. Right-size EKS nodes based on actual usage
kubectl top nodes
kubectl top pods -A --sort-by=memory

# If utilization < 50%, scale down
eksctl scale nodegroup --cluster=fawkes-production --nodes=4 --name=fawkes-ng-general

# 2. Delete unused EBS volumes
aws ec2 describe-volumes --filters Name=status,Values=available \
  --query 'Volumes[*].[VolumeId,Size,CreateTime]' --output table

# Delete them
aws ec2 delete-volume --volume-id vol-xxxxxxxxx

# 3. Configure S3 lifecycle policies
aws s3api put-bucket-lifecycle-configuration \
  --bucket fawkes-logs-prod-YOUR-UNIQUE-ID \
  --lifecycle-configuration file://s3-lifecycle.json

# s3-lifecycle.json content:
cat > s3-lifecycle.json <<EOF
{
  "Rules": [
    {
      "Id": "ArchiveOldLogs",
      "Status": "Enabled",
      "Transitions": [
        {
          "Days": 30,
          "StorageClass": "STANDARD_IA"
        },
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ],
      "Expiration": {
        "Days": 365
      }
    }
  ]
}
EOF
```

### Long-term Optimizations (Month 2-3)

```bash
# 1. Purchase Reserved Instances (40% savings)
# After validating instance types and sizes, purchase 1-year RIs
aws ec2 describe-reserved-instances-offerings \
  --instance-type t3.xlarge \
  --offering-class standard \
  --product-description Linux/UNIX

# 2. Use Savings Plans for RDS
aws rds purchase-reserved-db-instances-offering \
  --reserved-db-instances-offering-id <offering-id> \
  --reserved-db-instance-id fawkes-production-db-reserved

# 3. Implement cluster autoscaling policies
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-autoscaler-priority-expander
  namespace: kube-system
data:
  priorities: |-
    10:
      - .*-spot-.*
    50:
      - .*-on-demand-.*
EOF

# 4. Use Spot instances for non-critical workloads
# Create a mixed instance nodegroup
eksctl create nodegroup \
  --cluster=fawkes-production \
  --name=fawkes-ng-spot \
  --node-type=t3.xlarge \
  --nodes=3 \
  --nodes-min=1 \
  --nodes-max=10 \
  --spot

# 5. Enable AWS Compute Optimizer
aws compute-optimizer update-enrollment-status \
  --status Active \
  --include-member-accounts
```

### Monitoring Costs

```bash
# Create cost monitoring dashboard
cat > cost-monitoring.sh <<'EOF'
#!/bin/bash

echo "===== Fawkes AWS Cost Report ====="
echo "Report Date: $(date)"
echo ""

# Current month costs
echo "Current Month Costs:"
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=SERVICE \
  --filter file://<(echo '{
    "Tags": {
      "Key": "Project",
      "Values": ["fawkes"]
    }
  }') \
  --output table

echo ""
echo "Top 10 Most Expensive Resources:"
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics UnblendedCost \
  --group-by Type=DIMENSION,Key=RESOURCE_ID \
  --filter file://<(echo '{
    "Tags": {
      "Key": "Project",
      "Values": ["fawkes"]
    }
  }') \
  --query 'ResultsByTime[0].Groups | sort_by(@, &Metrics.UnblendedCost.Amount) | reverse(@) | [0:10]' \
  --output table

echo ""
echo "Projected Month-End Cost:"
aws ce get-cost-forecast \
  --time-period Start=$(date +%Y-%m-%d),End=$(date -d "$(date +%Y-%m-01) +1 month -1 day" +%Y-%m-%d) \
  --metric UNBLENDED_COST \
  --granularity MONTHLY \
  --output table

echo ""
echo "====================================="
EOF

chmod +x cost-monitoring.sh
./cost-monitoring.sh
```

---

## Appendix A: Complete Deployment Checklist

### Pre-Deployment

- [ ] AWS account with appropriate permissions
- [ ] All required tools installed (AWS CLI, kubectl, terraform, helm, eksctl)
- [ ] Domain name registered (optional but recommended)
- [ ] Budget alerts configured
- [ ] Team notified of deployment window
- [ ] Passwords generated and stored securely
- [ ] S3 bucket names chosen (globally unique)

### Phase 1: Foundation (30 min)

- [ ] Terraform initialized
- [ ] VPC and networking deployed
- [ ] NAT Gateways provisioned
- [ ] S3 buckets created with encryption
- [ ] Secrets stored in AWS Secrets Manager
- [ ] SSL certificate requested (if using custom domain)
- [ ] Validation: VPC, subnets, NAT gateways, S3 buckets exist

### Phase 2: EKS Cluster (30 min)

- [ ] EKS cluster created
- [ ] Worker nodes launched across 3 AZs
- [ ] kubectl configured
- [ ] AWS Load Balancer Controller installed
- [ ] External Secrets Operator installed
- [ ] Cluster Autoscaler configured
- [ ] Validation: All nodes Ready, system pods running

### Phase 3: Database & Storage (20 min)

- [ ] RDS PostgreSQL instance created (Multi-AZ)
- [ ] Security groups configured
- [ ] Database connectivity verified
- [ ] Databases initialized for each component
- [ ] Storage classes configured
- [ ] Validation: RDS available, connectivity tested

### Phase 4: Platform Services (60 min)

- [ ] Namespaces created
- [ ] ArgoCD deployed and accessible
- [ ] Harbor deployed and accessible
- [ ] Jenkins deployed and accessible
- [ ] Backstage deployed and accessible
- [ ] Mattermost deployed and accessible
- [ ] Focalboard deployed and accessible
- [ ] Validation: All services responding, ingresses have ALB addresses

### Phase 5: Observability (30 min)

- [ ] Prometheus stack deployed
- [ ] Grafana accessible with dashboards
- [ ] DORA metrics exporter deployed
- [ ] Alerting configured
- [ ] Validation: Prometheus scraping, Grafana dashboards visible

### Phase 6: Security (20 min)

- [ ] Trivy Operator deployed
- [ ] Kyverno policies deployed
- [ ] Network policies configured
- [ ] Pod Security Standards applied
- [ ] RBAC roles created
- [ ] Validation: Vulnerability scans running, policies enforced

### Phase 7: Validation (30 min)

- [ ] Health check script run successfully
- [ ] Connectivity tests pass
- [ ] Test application deployed
- [ ] DORA metrics collecting
- [ ] Security scan completed
- [ ] Validation: All green checks

### Post-Deployment

- [ ] DNS records configured
- [ ] Backups configured (Velero)
- [ ] Monitoring and alerting verified
- [ ] Cost tracking enabled
- [ ] Documentation completed
- [ ] Team access granted
- [ ] First application deployed
- [ ] Runbook created

---

## Appendix B: Useful Commands Reference

### Cluster Management

```bash
# Get cluster info
kubectl cluster-info
eksctl get cluster --name fawkes-production

# Get all resources
kubectl get all -A

# Scale nodegroup
eksctl scale nodegroup --cluster=fawkes-production --nodes=6 --name=fawkes-ng-general

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name fawkes-production

# Drain node for maintenance
kubectl drain <node-name> --ignore-daemonsets --delete-emptydir-data

# Uncordon node after maintenance
kubectl uncordon <node-name>
```

### Debugging

```bash
# View pod logs
kubectl logs <pod-name> -n <namespace>
kubectl logs <pod-name> -n <namespace> --previous  # Previous container

# Follow logs
kubectl logs -f <pod-name> -n <namespace>

# Exec into pod
kubectl exec -it <pod-name> -n <namespace> -- /bin/bash

# Port forward
kubectl port-forward -n <namespace> svc/<service-name> 8080:80

# Describe resources
kubectl describe pod <pod-name> -n <namespace>
kubectl describe node <node-name>

# Get events
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# Check resource usage
kubectl top nodes
kubectl top pods -A
```

### Backup and Restore

```bash
# Create backup
velero backup create <backup-name> --include-namespaces <namespace>

# List backups
velero backup get

# Restore from backup
velero restore create --from-backup <backup-name>

# Backup specific resource
velero backup create <backup-name> --include-resources deployments,services

# Schedule regular backups
velero schedule create daily --schedule="0 2 * * *" --ttl 720h
```

### Certificate Management

```bash
# List certificates
aws acm list-certificates --region us-east-1

# Describe certificate
aws acm describe-certificate --certificate-arn <arn>

# Request new certificate
aws acm request-certificate \
  --domain-name fawkes.yourdomain.com \
  --validation-method DNS \
  --region us-east-1

# Delete certificate
aws acm delete-certificate --certificate-arn <arn>
```

### Database Operations

```bash
# Connect to RDS
kubectl run postgres-client --rm -i --tty \
  --image postgres:15 \
  --restart=Never \
  --env="PGPASSWORD=$DB_PASSWORD" \
  -- psql -h $RDS_ENDPOINT -U fawkesadmin -d postgres

# Create database dump
kubectl run postgres-backup --rm -i --tty \
  --image postgres:15 \
  --restart=Never \
  --env="PGPASSWORD=$DB_PASSWORD" \
  -- pg_dump -h $RDS_ENDPOINT -U fawkesadmin -d backstage > backstage-backup.sql

# Restore database
kubectl run postgres-restore --rm -i --tty \
  --image postgres:15 \
  --restart=Never \
  --env="PGPASSWORD=$DB_PASSWORD" \
  -- psql -h $RDS_ENDPOINT -U fawkesadmin -d backstage < backstage-backup.sql
```

### Secrets Management

```bash
# Create secret from AWS Secrets Manager
kubectl create secret generic my-secret \
  --from-literal=password=$(aws secretsmanager get-secret-value \
    --secret-id fawkes/production/db-password \
    --query SecretString \
    --output text)

# View secret (base64 decoded)
kubectl get secret <secret-name> -n <namespace> -o jsonpath='{.data.password}' | base64 -d

# Update secret
kubectl create secret generic <secret-name> \
  --from-literal=key=value \
  --dry-run=client -o yaml | kubectl apply -f -
```

---

## Appendix C: Disaster Recovery Procedures

### RDS Failure

**Detection**:
```bash
aws rds describe-db-instances \
  --db-instance-identifier fawkes-production-db \
  --query 'DBInstances[0].DBInstanceStatus'
```

**Recovery** (Multi-AZ automatic failover):
```bash
# Force failover to standby
aws rds reboot-db-instance \
  --db-instance-identifier fawkes-production-db \
  --force-failover

# Wait for availability
aws rds wait db-instance-available \
  --db-instance-identifier fawkes-production-db

# Verify new endpoint (should be same)
aws rds describe-db-instances \
  --db-instance-identifier fawkes-production-db \
  --query 'DBInstances[0].Endpoint.Address'
```

**Recovery** (Complete failure - restore from snapshot):
```bash
# List recent snapshots
aws rds describe-db-snapshots \
  --db-instance-identifier fawkes-production-db \
  --query 'DBSnapshots[*].[DBSnapshotIdentifier,SnapshotCreateTime]' \
  --output table

# Restore from snapshot
aws rds restore-db-instance-from-db-snapshot \
  --db-instance-identifier fawkes-production-db-restored \
  --db-snapshot-identifier <snapshot-id> \
  --db-subnet-group-name fawkes-production-db-subnet \
  --multi-az

# Update connection strings in Kubernetes secrets
NEW_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier fawkes-production-db-restored \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

kubectl create secret generic postgres-credentials \
  --from-literal=host=$NEW_ENDPOINT \
  --from-literal=port=5432 \
  --from-literal=database=postgres \
  --from-literal=username=fawkesadmin \
  --from-literal=password=$DB_PASSWORD \
  -n fawkes-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Restart all pods using database
kubectl rollout restart deployment -n backstage
kubectl rollout restart deployment -n jenkins
kubectl rollout restart deployment -n argocd
kubectl rollout restart deployment -n harbor
kubectl rollout restart deployment -n mattermost
kubectl rollout restart deployment -n focalboard
```

### EKS Cluster Failure

**Detection**:
```bash
kubectl get nodes
# No response or all nodes NotReady
```

**Recovery**:
```bash
# Check cluster status
aws eks describe-cluster --name fawkes-production --query 'cluster.status'

# If cluster API is down, recreate from Terraform
cd infra/terraform/aws
terraform plan -var-file=production.tfvars
terraform apply

# Restore from Velero backup
velero restore create --from-backup daily-backup-20251007
```

### Complete Region Failure

**Prerequisites**:
- Multi-region setup (not covered in this guide)
- Cross-region RDS replication
- S3 cross-region replication

**Recovery**:
```bash
# Promote RDS read replica in secondary region
aws rds promote-read-replica \
  --db-instance-identifier fawkes-production-db-replica \
  --region us-west-2

# Deploy EKS cluster in secondary region
cd infra/terraform/aws
terraform apply -var-file=dr-production.tfvars -var="aws_region=us-west-2"

# Update DNS to point to new region
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone-id> \
  --change-batch file://failover-dns.json
```

---

## Appendix D: Maintenance Procedures

### Monthly Maintenance Tasks

```bash
# 1. Update EKS cluster version
eksctl upgrade cluster --name fawkes-production --version 1.29 --approve

# 2. Update nodegroups
eksctl upgrade nodegroup --cluster=fawkes-production --name=fawkes-ng-general

# 3. Update Helm charts
helm repo update
helm list -A

# Update each chart
helm upgrade argocd argo/argo-cd -n argocd --version <new-version>
helm upgrade harbor harbor/harbor -n harbor --version <new-version>
# ... etc

# 4. Update add-ons
eksctl utils update-addon --cluster fawkes-production --name vpc-cni --version <new-version>
eksctl utils update-addon --cluster fawkes-production --name coredns --version <new-version>
eksctl utils update-addon --cluster fawkes-production --name kube-proxy --version <new-version>
eksctl utils update-addon --cluster fawkes-production --name aws-ebs-csi-driver --version <new-version>

# 5. Clean up old resources
# Delete old EBS snapshots
aws ec2 describe-snapshots --owner-ids self \
  --query 'Snapshots[?StartTime<=`2024-07-01`].[SnapshotId,StartTime,Description]' \
  --output table

# Delete them
aws ec2 delete-snapshot --snapshot-id snap-xxxxxxxxx

# 6. Review and clean up unused PVCs
kubectl get pvc -A | grep Released
kubectl delete pvc <pvc-name> -n <namespace>

# 7. Rotate secrets
# Generate new password
NEW_DB_PASSWORD=$(openssl rand -base64 32)

# Update in RDS
aws rds modify-db-instance \
  --db-instance-identifier fawkes-production-db \
  --master-user-password $NEW_DB_PASSWORD \
  --apply-immediately

# Update in Secrets Manager
aws secretsmanager update-secret \
  --secret-id fawkes/production/db-password \
  --secret-string $NEW_DB_PASSWORD

# Update in Kubernetes
kubectl create secret generic postgres-credentials \
  --from-literal=password=$NEW_DB_PASSWORD \
  --dry-run=client -o yaml | kubectl apply -f -

# 8. Review security scan results
kubectl get vulnerabilityreports -A | grep CRITICAL

# 9. Review and update network policies
kubectl get networkpolicies -A

# 10. Cost optimization review
./cost-monitoring.sh
```

### Quarterly Maintenance Tasks

```bash
# 1. Major version upgrades (EKS, RDS)
# Follow AWS documentation for major version upgrades

# 2. Review and update IAM policies
aws iam get-policy-version \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/FawkesPolicy \
  --version-id v1

# 3. Security audit
aws securityhub get-findings --region us-east-1

# 4. Compliance check
aws config describe-compliance-by-config-rule

# 5. Performance review
# Review Grafana dashboards for trends
# Analyze DORA metrics improvements

# 6. Disaster recovery test
# Perform complete failover test in DR environment

# 7. Documentation review
# Update runbooks, procedures, contact information
```

---

## Appendix E: Additional Resources

### Official Documentation

- [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/)
- [Amazon RDS User Guide](https://docs.aws.amazon.com/rds/latest/userguide/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [Backstage Documentation](https://backstage.io/docs/overview/what-is-backstage)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Harbor Documentation](https://goharbor.io/docs/)

### Best Practices Guides

- [EKS Best Practices Guide](https://aws.github.io/aws-eks-best-practices/)
- [Kubernetes Production Best Practices](https://kubernetes.io/docs/setup/best-practices/)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

### Training and Certification

- [AWS Certified Solutions Architect](https://aws.amazon.com/certification/certified-solutions-architect-associate/)
- [Certified Kubernetes Administrator (CKA)](https://www.cncf.io/certification/cka/)
- [Platform Engineering University](https://platformengineering.university/)

### Community and Support

- [Fawkes GitHub Discussions](https://github.com/paruff/fawkes/discussions)
- [Fawkes Mattermost](https://mattermost.fawkes.yourdomain.com) (after deployment)
- [AWS Support](https://console.aws.amazon.com/support/)
- [CNCF Slack](https://slack.cncf.io/)

---

## Conclusion

Congratulations! You've successfully deployed the Fawkes platform on AWS in production.

**What you've accomplished**:
- ✅ Deployed a complete Internal Delivery Platform on AWS
- ✅ Set up high-availability infrastructure across 3 availability zones
- ✅ Implemented security best practices (encryption, network policies, RBAC)
- ✅ Configured comprehensive observability and monitoring
- ✅ Established automated backups and disaster recovery procedures
- ✅ Created maintainable, documented infrastructure

**Next steps**:
1. **Onboard your first team**: Create their first project using Backstage
2. **Deploy first application**: Use the golden path templates
3. **Configure CI/CD**: Set up Jenkins pipelines for automated builds
4. **Launch Dojo**: Begin training engineers on the platform
5. **Iterate and improve**: Collect feedback and enhance the platform

**Remember**:
- Monitor costs daily for the first week
- Review security scans weekly
- Perform monthly maintenance tasks
- Test disaster recovery procedures quarterly
- Keep documentation up to date

**Need help?**
- Check troubleshooting section first
- Search GitHub Issues: https://github.com/paruff/fawkes/issues
- Join the community on Mattermost
- Review AWS documentation
- Contact platform team: platform-team@yourdomain.com

**Thank you for choosing Fawkes!** 🚀

---

**Document Version**: 1.0
**Last Updated**: October 7, 2025
**Maintained By**: Fawkes Platform Team
**Feedback**: Please submit issues or improvements to the GitHub repository

---

**Estimated Total Time**: 3-4 hours
**Estimated Monthly Cost**: $2,084 (production environment)
**AWS Services Used**: 10+ (EKS, RDS, S3, ALB, CloudWatch, Secrets Manager, ACM, IAM, VPC, ECR)