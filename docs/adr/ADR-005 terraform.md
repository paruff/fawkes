# ADR-005: Terraform for Infrastructure as Code

## Status
**Accepted** - October 8, 2025

## Context

Fawkes requires an Infrastructure as Code (IaC) tool to provision and manage cloud infrastructure declaratively. IaC is fundamental to platform engineering, enabling repeatable, version-controlled, auditable infrastructure management across multiple clouds.

### The Need for Infrastructure as Code

**Current Challenges Without IaC**:
- **Manual Provisioning**: Error-prone, time-consuming, not documented
- **Configuration Drift**: Infrastructure diverges from documented state
- **No Version Control**: Can't track infrastructure changes over time
- **No Code Review**: Infrastructure changes not peer-reviewed
- **Environment Inconsistencies**: Dev, staging, prod configured differently
- **Disaster Recovery**: Rebuilding infrastructure from scratch is slow/impossible
- **No Self-Service**: Developers can't provision infrastructure without tickets
- **Tribal Knowledge**: Infrastructure setup exists only in operators' heads

**What Infrastructure as Code Provides**:
1. **Declarative Configuration**: Describe desired state, tool handles how to achieve it
2. **Version Control**: All infrastructure changes tracked in Git
3. **Code Review**: Infrastructure changes go through PR process
4. **Repeatability**: Provision identical infrastructure multiple times
5. **Environment Parity**: Dev/staging/prod from same code with different variables
6. **Disaster Recovery**: Rebuild entire infrastructure from code
7. **Documentation**: Code is documentation (always up-to-date)
8. **Automation**: Integrate with CI/CD for automated infrastructure changes

### Requirements for IaC Tool

**Core Requirements**:
- **Multi-Cloud**: Support AWS, Azure, GCP with consistent workflow
- **Declarative**: Describe desired state, not procedural steps
- **State Management**: Track current infrastructure state
- **Plan/Preview**: Show changes before applying
- **Modular**: Reusable modules for common patterns
- **Mature Ecosystem**: Providers for 100+ services
- **Large Community**: Extensive documentation, examples, support
- **Open Source**: Transparent, no vendor lock-in

**DORA Alignment**:
- **Infrastructure Changes**: Version-controlled, reviewable infrastructure
- **Deployment Frequency**: Automated infrastructure enables faster deployments
- **Lead Time**: Infrastructure provisioning no longer bottleneck
- **Change Failure Rate**: Preview changes before applying reduces errors

**Integration Requirements**:
- **GitHub**: Store modules and configurations
- **Jenkins**: Automate terraform apply in pipelines
- **Kubernetes**: Provision clusters, configure resources
- **Cloud Providers**: AWS, Azure, GCP
- **Backstage**: Show infrastructure status (future)

### Forces at Play

**Technical Forces**:
- Need multi-cloud support for flexibility
- State management critical for tracking resources
- Preview capability reduces risk of changes
- Modular approach enables code reuse

**Operational Forces**:
- Platform team can't manually provision everything
- Need disaster recovery capabilities
- Environment parity critical for testing
- Self-service infrastructure reduces tickets

**Developer Experience Forces**:
- Developers want infrastructure on-demand
- Need clear documentation of infrastructure
- Want confidence changes won't break production
- Prefer familiar tools and workflows

**Ecosystem Forces**:
- Terraform has dominant market share
- Extensive provider ecosystem
- Large community and knowledge base
- Enterprise adoption provides credibility

## Decision

**We will use Terraform as the primary Infrastructure as Code tool for Fawkes.**

Specifically:
- **Terraform OSS** (Open Source, latest stable version)
- **HCL** (HashiCorp Configuration Language)
- **Terraform Cloud** for state management (free tier, 5 users)
- **Modular approach** with reusable modules
- **Multi-environment** support (dev, staging, prod)
- **Version pinning** for providers and modules
- **Automated testing** with Terratest (critical modules)
- **Crossplane** for Kubernetes-native IaC (roadmap, Phase 2)

### Rationale

1. **Industry Standard**: Terraform is the most widely adopted IaC tool, with 40,000+ GitHub stars, used by 70%+ of organizations doing multi-cloud

2. **True Multi-Cloud**: Consistent workflow across clouds:
   - Same HCL syntax for AWS, Azure, GCP
   - Unified state management
   - Single tool to learn
   - Providers for 3,000+ services

3. **Mature and Battle-Tested**: 
   - 10+ years of development
   - Production-proven at enterprise scale
   - Extensive real-world validation
   - Known edge cases well-documented

4. **Declarative Language**: HCL describes desired state:
   - Easy to read and understand
   - Predictable behavior
   - Idempotent operations
   - Less error-prone than imperative scripts

5. **State Management**: 
   - Tracks actual infrastructure state
   - Enables drift detection
   - Supports team collaboration
   - Remote state backends (S3, Terraform Cloud)

6. **Plan Before Apply**: 
   - Preview changes before executing
   - Reduces fear of infrastructure changes
   - Catch mistakes before they happen
   - Show changes in PR reviews

7. **Massive Provider Ecosystem**: 
   - AWS: 1,000+ resources
   - Azure: 1,500+ resources
   - GCP: 800+ resources
   - Kubernetes: Full support
   - 3,000+ total providers

8. **Module Registry**: 
   - Public registry with 10,000+ modules
   - Reusable, community-validated code
   - Can publish private modules
   - Accelerates development

9. **Large Community**: 
   - Extensive documentation
   - Thousands of tutorials and examples
   - Active forums and Slack channels
   - Commercial support available (HashiCorp)

10. **Testing Support**: 
    - Terratest for integration testing
    - terraform validate for syntax
    - terraform fmt for formatting
    - tflint for best practices

11. **CI/CD Integration**: 
    - Easy to integrate with Jenkins
    - Automated plan on PR
    - Automated apply on merge
    - GitOps workflow support

12. **Crossplane Path**: 
    - Can transition to Crossplane later
    - Terraform modules can inform Crossplane compositions
    - Provides foundation for Kubernetes-native IaC

## Consequences

### Positive

✅ **Multi-Cloud Freedom**: Same tool and workflow across AWS, Azure, GCP

✅ **Version Controlled Infrastructure**: All changes in Git with full audit trail

✅ **Repeatable Provisioning**: Spin up identical environments reliably

✅ **Environment Parity**: Dev, staging, prod consistent, reducing bugs

✅ **Disaster Recovery**: Rebuild entire infrastructure from code in hours

✅ **Code Review**: Infrastructure changes peer-reviewed before applying

✅ **Preview Changes**: See exactly what will change before applying

✅ **Modular Code**: Reusable modules reduce duplication and errors

✅ **State Awareness**: Terraform knows current state, only changes what's needed

✅ **Extensive Ecosystem**: 3,000+ providers cover virtually any service

✅ **Developer Self-Service**: Developers can provision infrastructure via modules

✅ **Documentation as Code**: Infrastructure configuration is documentation

✅ **Large Community**: Easy to find help, examples, and best practices

### Negative

⚠️ **State Management Complexity**: State files require careful handling and locking

⚠️ **Learning Curve**: HCL syntax and concepts require learning

⚠️ **State Drift**: Manual changes create drift between code and reality

⚠️ **Refresh Delays**: terraform plan can be slow for large infrastructures

⚠️ **Provider Lag**: New cloud features may lag behind AWS/Azure/GCP releases

⚠️ **Breaking Changes**: Major Terraform/provider updates can break code

⚠️ **Resource Naming**: Changing resource names often requires destroy/recreate

⚠️ **Cost of Mistakes**: Accidental terraform destroy can be catastrophic

⚠️ **Complex Debugging**: Error messages sometimes cryptic

### Neutral

◽ **HCL vs. Other Languages**: Declarative DSL (HCL) vs. general-purpose languages (Python, TypeScript)

◽ **Terraform Cloud**: Free tier available, paid tiers for advanced features

◽ **HashiCorp Business**: Company behind Terraform has commercial interests

### Mitigation Strategies

1. **State Management**:
   - Use remote state backend (Terraform Cloud or S3)
   - Enable state locking (DynamoDB for S3)
   - Never manually edit state files
   - Regular state backups
   - Document state management procedures

2. **Learning Curve**:
   - Provide Terraform training workshops
   - Create comprehensive module documentation
   - Use module examples extensively
   - Start simple, add complexity gradually
   - Leverage community resources

3. **State Drift**:
   - Educate team: never make manual changes
   - Run terraform plan regularly to detect drift
   - Use cloud provider guard rails (SCPs, policies)
   - Consider drift detection automation
   - Document procedure for importing manual changes

4. **Breaking Changes**:
   - Pin provider versions in code
   - Test updates in non-production first
   - Follow Terraform upgrade guides carefully
   - Subscribe to provider changelogs
   - Budget time for major upgrades

5. **Cost of Mistakes**:
   - Protect production with different credentials
   - Use terraform plan before every apply
   - Require PR approval for production changes
   - Enable deletion protection on critical resources
   - Regular backups and disaster recovery testing

6. **Resource Naming**:
   - Use computed names where possible
   - Document naming conventions
   - Use lifecycle blocks (create_before_destroy)
   - Plan for resource replacement scenarios

## Alternatives Considered

### Alternative 1: Pulumi

**Pros**:
- Use real programming languages (Python, TypeScript, Go, C#)
- Familiar to developers (no new language to learn)
- Strong typing and IDE support
- Good testing story (use language's test framework)
- Modern architecture
- Growing quickly

**Cons**:
- **Smaller Community**: Much smaller than Terraform
- **Fewer Providers**: 100+ providers vs. Terraform's 3,000+
- **Less Mature**: Newer (2018 vs. Terraform 2014)
- **SaaS State Backend**: Free tier limited, paid for self-hosted
- **Steeper Troubleshooting**: Stack traces vs. Terraform's clear errors
- **Less Enterprise Adoption**: Fewer large-scale production examples

**Reason for Rejection**: Pulumi philosophically appealing (real languages), but Terraform's maturity, ecosystem, and community provide more value. Pulumi excellent for organizations with strong programming culture, but Terraform's declarative approach and larger ecosystem better fit for Fawkes' needs. May revisit in 2-3 years as Pulumi matures.

### Alternative 2: AWS CloudFormation

**Pros**:
- Native AWS integration
- No state management needed
- AWS-supported and maintained
- Free (no additional cost)
- Stack rollback on failure
- AWS console integration

**Cons**:
- **AWS Only**: Cannot manage Azure, GCP, or other providers
- **Verbose YAML/JSON**: Much more verbose than Terraform HCL
- **Limited Features**: Fewer advanced features than Terraform
- **Slow Updates**: New AWS features delayed in CloudFormation
- **Poor Error Messages**: Debugging difficult
- **No Multi-Cloud**: Complete rewrite needed for other clouds

**Reason for Rejection**: CloudFormation fine for AWS-only, but Fawkes multi-cloud from start. Vendor lock-in to AWS unacceptable. Terraform provides consistent multi-cloud experience. May use CloudFormation for AWS-specific features but not as primary IaC tool.

### Alternative 3: Azure Resource Manager (ARM) Templates

**Pros**:
- Native Azure integration
- Free (included with Azure)
- Azure portal integration
- What-if preview capability

**Cons**:
- **Azure Only**: Cannot manage AWS, GCP
- **JSON Verbose**: Very verbose JSON syntax
- **Complex Syntax**: Difficult to write and maintain
- **Poor Error Messages**: Debugging challenging
- **Limited Community**: Smaller than Terraform

**Reason for Rejection**: Same issues as CloudFormation—Azure lock-in, verbose syntax, single-cloud only. Terraform multi-cloud approach much better.

### Alternative 4: Ansible

**Pros**:
- General-purpose automation (not just infrastructure)
- Agentless (SSH-based)
- YAML syntax (familiar)
- Large community
- Can manage configuration in addition to infrastructure

**Cons**:
- **Imperative, Not Declarative**: Procedural scripts vs. desired state
- **No Built-In State**: Doesn't track infrastructure state
- **Idempotency Issues**: Not guaranteed idempotent
- **Not Designed for IaC**: Configuration management tool, not IaC tool
- **No Plan Preview**: Can't preview changes before applying
- **Slower**: SSH-based approach slower than API calls

**Reason for Rejection**: Ansible excellent for configuration management, but not purpose-built for infrastructure provisioning. Terraform's declarative approach and state management much better for IaC. May use Ansible for post-provisioning configuration alongside Terraform.

### Alternative 5: Crossplane

**Pros**:
- Kubernetes-native (CRDs)
- Declarative, Kubernetes-style
- GitOps integration native
- Composable infrastructure
- Cloud-agnostic abstractions
- CNCF project (good governance)

**Cons**:
- **Less Mature**: Newer than Terraform (2018)
- **Smaller Ecosystem**: Fewer providers than Terraform
- **Steeper Learning Curve**: Kubernetes CRDs more complex than HCL
- **Debugging Harder**: Kubernetes abstraction makes troubleshooting difficult
- **Smaller Community**: Fewer examples and tutorials
- **Requires Kubernetes**: Can't use without Kubernetes cluster

**Reason for Rejection**: Crossplane philosophically aligned (Kubernetes-native, cloud-agnostic), but less mature and harder to use. Terraform provides better starting point. **However**, Crossplane is our Phase 2 goal—we'll use Terraform initially, transition to Crossplane as it matures and team gains Kubernetes expertise. Terraform experience will inform Crossplane composition design.

### Alternative 6: OpenTofu

**Pros**:
- Terraform fork (fully compatible)
- Open source (Linux Foundation)
- Community-driven
- No vendor control concerns
- Free forever

**Cons**:
- **Very New**: Fork created August 2023
- **Uncertain Future**: Will it maintain compatibility?
- **Smaller Team**: Fewer contributors than Terraform
- **Provider Ecosystem**: May diverge from Terraform providers
- **Less Proven**: No significant production usage yet

**Reason for Rejection**: OpenTofu created in response to Terraform license change (BSL). While philosophically appealing (truly open source), too new and unproven. Terraform OSS (pre-license change) still available and sufficient for Fawkes. Will monitor OpenTofu and may switch if it proves mature and sustainable.

### Alternative 7: Terraform CDK (Cloud Development Kit)

**Pros**:
- Use programming languages (TypeScript, Python, Java, C#, Go)
- Generates Terraform JSON
- Familiar to developers
- HashiCorp-maintained

**Cons**:
- **Additional Layer**: Complexity of language + Terraform
- **Less Mature**: Newer than core Terraform
- **Smaller Community**: Fewer examples than HCL
- **Debugging Harder**: Two layers to debug (code + generated JSON)
- **Provider Support**: Not all providers well-supported

**Reason for Rejection**: Terraform CDK interesting but adds complexity. HCL's declarative nature and large ecosystem of HCL modules provide more value. If we wanted programming languages, would choose Pulumi directly. Terraform CDK feels like compromise without clear benefits.

## Related Decisions

- **ADR-001**: Kubernetes (Terraform provisions Kubernetes clusters)
- **Future ADR**: Crossplane for Kubernetes-Native IaC (Phase 2 migration path)
- **Future ADR**: Terraform Module Structure and Standards
- **Future ADR**: State Management and Locking Strategy

## Implementation Notes

### Repository Structure

**Monorepo Approach** (recommended):

```
fawkes-infrastructure/
├── modules/
│   ├── eks-cluster/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── vpc/
│   ├── rds/
│   ├── elasticache/
│   └── s3-bucket/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── terraform.tfvars
│   │   └── backend.tf
│   ├── staging/
│   └── prod/
├── global/
│   ├── iam/
│   ├── route53/
│   └── s3-backend/
├── scripts/
│   ├── plan.sh
│   ├── apply.sh
│   └── destroy.sh
├── .github/
│   └── workflows/
│       ├── terraform-plan.yml
│       └── terraform-apply.yml
└── README.md
```

### Module Example (EKS Cluster)

```hcl
# modules/eks-cluster/main.tf

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.20"
    }
  }
}

resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = aws_iam_role.cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = var.kms_key_arn
    }
    resources = ["secrets"]
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = merge(
    var.tags,
    {
      "Name" = var.cluster_name
      "ManagedBy" = "Terraform"
    }
  )
}

resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-nodegroup"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.desired_size
    max_size     = var.max_size
    min_size     = var.min_size
  }

  instance_types = var.instance_types

  labels = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }

  tags = var.tags
}
```

### Environment Configuration

```hcl
# environments/dev/main.tf

terraform {
  backend "s3" {
    bucket         = "fawkes-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "fawkes"
      ManagedBy   = "Terraform"
    }
  }
}

module "vpc" {
  source = "../../modules/vpc"
  
  vpc_name            = "fawkes-dev-vpc"
  cidr_block          = "10.0.0.0/16"
  availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets     = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  
  enable_nat_gateway = true
  single_nat_gateway = true  # Cost optimization for dev
  
  tags = local.tags
}

module "eks" {
  source = "../../modules/eks-cluster"
  
  cluster_name        = "fawkes-dev"
  kubernetes_version  = "1.28"
  subnet_ids          = module.vpc.private_subnet_ids
  
  desired_size = 3
  min_size     = 2
  max_size     = 5
  
  instance_types = ["t3.large"]
  
  tags = local.tags
}

locals {
  tags = {
    Environment = "dev"
    Project     = "fawkes"
    ManagedBy   = "Terraform"
  }
}
```

### CI/CD Integration (GitHub Actions)

```yaml
# .github/workflows/terraform-plan.yml

name: Terraform Plan

on:
  pull_request:
    paths:
      - 'environments/**'
      - 'modules/**'

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.6.0
          
      - name: Terraform Init
        working-directory: environments/dev
        run: terraform init
        
      - name: Terraform Format Check
        run: terraform fmt -check -recursive
        
      - name: Terraform Validate
        working-directory: environments/dev
        run: terraform validate
        
      - name: Terraform Plan
        working-directory: environments/dev
        run: terraform plan -no-color
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        
      - name: Comment PR
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: 'Terraform plan completed. Review the output above.'
            })
```

### Testing with Terratest

```go
// test/eks_test.go

package test

import (
    "testing"
    "github.com/gruntwork-io/terratest/modules/terraform"
    "github.com/stretchr/testify/assert"
)

func TestEKSCluster(t *testing.T) {
    terraformOptions := &terraform.Options{
        TerraformDir: "../modules/eks-cluster",
        
        Vars: map[string]interface{}{
            "cluster_name": "test-cluster",
            "kubernetes_version": "1.28",
            "subnet_ids": []string{"subnet-123", "subnet-456"},
        },
    }
    
    defer terraform.Destroy(t, terraformOptions)
    
    terraform.InitAndApply(t, terraformOptions)
    
    clusterName := terraform.Output(t, terraformOptions, "cluster_name")
    assert.Equal(t, "test-cluster", clusterName)
    
    clusterVersion := terraform.Output(t, terraformOptions, "kubernetes_version")
    assert.Equal(t, "1.28", clusterVersion)
}
```

### State Management

**Terraform Cloud** (recommended for MVP):

```hcl
terraform {
  cloud {
    organization = "fawkes-platform"
    
    workspaces {
      name = "fawkes-dev"
    }
  }
}
```

**S3 Backend** (alternative):

```hcl
terraform {
  backend "s3" {
    bucket         = "fawkes-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
    
    # Enable versioning for state file history
    versioning = true
  }
}
```

### Best Practices

1. **Always Use Remote State**: Never store state locally for team projects
2. **Enable State Locking**: Prevent concurrent modifications
3. **Pin Provider Versions**: Avoid surprise breaking changes
4. **Use Modules**: DRY principle, reusability
5. **Separate Environments**: Different state files for dev/staging/prod
6. **Code Review**: All changes via PR
7. **Plan Before Apply**: Always review plan output
8. **Tag Everything**: Consistent tagging for cost tracking and ownership
9. **Use Variables**: Never hardcode values
10. **Document Modules**: README with examples

### Migration to Crossplane (Phase 2)

**Path Forward**:
1. **Phase 1** (Months 1-6): Use Terraform exclusively
2. **Phase 2** (Months 7-12): Evaluate Crossplane maturity
3. **Phase 3** (Year 2): Gradual migration:
   - Start with new resources in Crossplane
   - Keep existing resources in Terraform
   - Create Crossplane compositions based on Terraform modules
   - Migrate non-critical resources first
4. **Phase 4** (Year 2-3): Complete migration to Crossplane

**Why Crossplane Eventually**:
- Kubernetes-native (consistent with platform)
- GitOps integration seamless
- Better abstraction for self-service
- Cloud-agnostic compositions
- Unified control plane

**Why Terraform First**:
- Mature and proven today
- Larger ecosystem and community
- Easier learning curve
- Better debugging and documentation
- Lower risk for MVP

## Monitoring This Decision

We will revisit this ADR if:
- Terraform license changes make OSS version unusable
- Crossplane reaches maturity level where migration makes sense
- Pulumi ecosystem and community significantly grow
- Team expertise shifts toward different tool
- OpenTofu becomes mature and clearly sustainable
- Multi-cloud requirements change significantly

**Next Review Date**: April 8, 2026 (6 months)
**Crossplane Evaluation**: October 2026 (12 months)

## References

- [Terraform Official Documentation](https://www.terraform.io/docs/)
- [Terraform Registry](https://registry.terraform.io/)
- [Terraform Best Practices](https://www.terraform-best-practices.com/)
- [Terratest Documentation](https://terratest.gruntwork.io/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Crossplane Documentation](https://crossplane.io/docs/)

## Notes

### Terraform vs. Pulumi: The Debate

**Use Terraform when**:
- Want largest ecosystem and community
- Prefer declarative DSL over programming
- Need maximum provider coverage
- Want battle-tested maturity

**Use Pulumi when**:
- Strong programming culture in organization
- Want to use existing language (Python, TypeScript, Go)
- Need complex logic in infrastructure code
- Prefer general-purpose language testing

**For Fawkes**: Terraform's maturity, ecosystem, and community provide more value. Pulumi excellent choice for many organizations, but Terraform better fits Fawkes' needs as open source platform.

### Terraform License Change Context

In August 2023, HashiCorp changed Terraform license from MPL to BSL (Business Source License). This prevents:
- Using Terraform in commercial competing products
- Hosting Terraform as paid service

For Fawkes:
- **Not Affected**: Using Terraform for our platform is permitted
- **No Commercial Product**: We're not selling Terraform itself
- **OpenTofu Available**: Fork exists if needed

This decision may be revisited if BSL becomes more restrictive or OpenTofu proves more sustainable.

### State Management is Critical

**State file contains**:
- All provisioned resource IDs
- Resource attributes and metadata
- Dependencies between resources
- Terraform version used

**If state file is lost**:
- Terraform can't manage existing resources
- Must import all resources manually (tedious)
- Or destroy and recreate everything (disruptive)

**Protection strategies**:
- Remote state backend (S3, Terraform Cloud)
- State file versioning enabled
- Regular backups
- Never edit state manually
- State locking to prevent corruption

---

**Decision Made By**: Platform Architecture Team  
**Approved By**: Project Lead  
**Date**: October 8, 2025  
**Author**: [Platform Architect Name]  
**Last Updated**: October 8, 2025