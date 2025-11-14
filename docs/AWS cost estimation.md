# Fawkes AWS Cost Estimation

**Document Purpose**: Detailed AWS infrastructure cost analysis for Fawkes platform deployment
**Target Audience**: AWS Activate reviewers, financial planning, infrastructure architects
**Last Updated**: October 7, 2025
**AWS Region**: US-East-1 (Virginia) - Primary region for cost estimates

---

## Executive Summary

**Total Estimated Monthly Cost**: $1,847/month
**Annual Projection**: $22,164/year
**AWS Activate Credit Request**: $25,000 (covers 13 months of operation)

**Primary AWS Services**:
- Amazon EKS (Kubernetes orchestration)
- Amazon RDS (PostgreSQL databases)
- Amazon S3 (Artifact storage)
- Elastic Load Balancing (Application Load Balancers)
- Amazon CloudWatch (Monitoring and logging)
- AWS Secrets Manager (Secrets management)
- Amazon ECR (Container registry)

**Cost Optimization Strategy**: Implementing Reserved Instances, Spot instances, and auto-scaling can reduce costs by 40-60% after initial 6-month validation period.

---

## Infrastructure Architecture Overview

Fawkes requires three distinct environments to support:
1. **Development**: Active platform development and testing
2. **Staging**: Pre-production validation and integration testing
3. **Production**: Live platform serving community users and Dojo learners

Each environment runs a complete stack including:
- Kubernetes cluster (EKS)
- PostgreSQL database (RDS)
- Container registry (ECR)
- Load balancers (ALB)
- Monitoring and logging (CloudWatch)
- Storage (S3, EBS)

---

## Development Environment

**Purpose**: Platform engineering team development, feature testing, automated CI/CD testing

**Traffic Profile**: 5-10 concurrent users, intermittent usage (8 hours/day, 5 days/week)

### Compute - Amazon EKS

**EKS Control Plane**:
- Cost: $0.10/hour × 730 hours = **$73.00/month**
- Note: Control plane runs 24/7 regardless of node usage

**Worker Nodes** (3× t3.medium instances):
- Instance Type: t3.medium (2 vCPU, 4GB RAM)
- Quantity: 3 nodes (minimum for HA)
- On-Demand Cost: $0.0416/hour × 3 × 730 hours = **$91.10/month**
- Storage: 50GB EBS gp3 per node × 3 = $0.08/GB × 150GB = **$12.00/month**

**EKS Subtotal**: $176.10/month

### Database - Amazon RDS PostgreSQL

**Instance Configuration**:
- Instance Type: db.t3.medium (2 vCPU, 4GB RAM)
- Engine: PostgreSQL 15.x
- Single-AZ deployment (development only)
- Storage: 100GB gp3 SSD
- Cost Breakdown:
  - Instance: $0.068/hour × 730 hours = **$49.64/month**
  - Storage: 100GB × $0.115/GB = **$11.50/month**
  - Backup Storage: 100GB × $0.095/GB = **$9.50/month**

**RDS Subtotal**: $70.64/month

### Load Balancing

**Application Load Balancer** (1):
- ALB Hours: $0.0225/hour × 730 hours = **$16.43/month**
- LCU (Load Capacity Units): ~5 LCUs average = $0.008 × 5 × 730 = **$29.20/month**

**ALB Subtotal**: $45.63/month

### Storage - Amazon S3

**Container Images & Artifacts**:
- Standard Storage: 50GB × $0.023/GB = **$1.15/month**
- PUT/GET Requests: ~10,000 requests = **$0.05/month**

**Backup Storage**:
- Standard-IA: 20GB × $0.0125/GB = **$0.25/month**

**S3 Subtotal**: $1.45/month

### Container Registry - Amazon ECR

**Private Registry**:
- Storage: 30GB × $0.10/GB = **$3.00/month**
- Data Transfer: Negligible (within VPC)

**ECR Subtotal**: $3.00/month

### Monitoring - Amazon CloudWatch

**Logs**:
- Ingestion: 20GB × $0.50/GB = **$10.00/month**
- Storage: 20GB × $0.03/GB = **$0.60/month**

**Metrics**:
- Custom Metrics: 100 metrics × $0.30 = **$30.00/month**

**CloudWatch Subtotal**: $40.60/month

### Secrets Management - AWS Secrets Manager

**Secrets Storage**:
- 10 secrets × $0.40/secret = **$4.00/month**
- API Calls: 10,000 × $0.05/10,000 = **$0.50/month**

**Secrets Manager Subtotal**: $4.50/month

### Networking

**NAT Gateway** (1):
- Hours: $0.045/hour × 730 hours = **$32.85/month**
- Data Processing: 50GB × $0.045/GB = **$2.25/month**

**Data Transfer**:
- Outbound to Internet: 20GB × $0.09/GB = **$1.80/month**

**Networking Subtotal**: $36.90/month

### **Development Environment Total: $378.82/month**

---

## Staging Environment

**Purpose**: Pre-production validation, integration testing, performance testing, security scanning

**Traffic Profile**: 10-20 concurrent users, continuous deployment testing, 12 hours/day operation

### Compute - Amazon EKS

**EKS Control Plane**: **$73.00/month**

**Worker Nodes** (4× t3.large instances):
- Instance Type: t3.large (2 vCPU, 8GB RAM)
- Quantity: 4 nodes
- On-Demand Cost: $0.0832/hour × 4 × 730 hours = **$242.94/month**
- Storage: 100GB EBS gp3 per node × 4 = $0.08/GB × 400GB = **$32.00/month**

**EKS Subtotal**: $347.94/month

### Database - Amazon RDS PostgreSQL

**Instance Configuration**:
- Instance Type: db.t3.large (2 vCPU, 8GB RAM)
- Single-AZ (staging environment)
- Storage: 200GB gp3 SSD
- Cost Breakdown:
  - Instance: $0.136/hour × 730 hours = **$99.28/month**
  - Storage: 200GB × $0.115/GB = **$23.00/month**
  - Backup Storage: 200GB × $0.095/GB = **$19.00/month**

**RDS Subtotal**: $141.28/month

### Load Balancing

**Application Load Balancers** (2):
- ALB Hours: $0.0225/hour × 2 × 730 hours = **$32.85/month**
- LCU: ~8 LCUs average × 2 = $0.008 × 16 × 730 = **$93.44/month**

**ALB Subtotal**: $126.29/month

### Storage - Amazon S3

**Container Images & Artifacts**:
- Standard Storage: 100GB × $0.023/GB = **$2.30/month**
- PUT/GET Requests: ~50,000 requests = **$0.25/month**

**Backup Storage**:
- Standard-IA: 50GB × $0.0125/GB = **$0.63/month**

**S3 Subtotal**: $3.18/month

### Container Registry - Amazon ECR

**Private Registry**:
- Storage: 50GB × $0.10/GB = **$5.00/month**

**ECR Subtotal**: $5.00/month

### Monitoring - Amazon CloudWatch

**Logs**:
- Ingestion: 40GB × $0.50/GB = **$20.00/month**
- Storage: 40GB × $0.03/GB = **$1.20/month**

**Metrics**:
- Custom Metrics: 200 metrics × $0.30 = **$60.00/month**

**Alarms**: 20 alarms × $0.10 = **$2.00/month**

**CloudWatch Subtotal**: $83.20/month

### AWS X-Ray (Distributed Tracing)

**Traces Recorded**: 1 million traces × $5.00/million = **$5.00/month**
**Traces Retrieved**: 100K traces × $0.50/million = **$0.05/month**

**X-Ray Subtotal**: $5.05/month

### Secrets Management

**Secrets Storage**:
- 15 secrets × $0.40/secret = **$6.00/month**
- API Calls: 50,000 × $0.05/10,000 = **$2.50/month**

**Secrets Manager Subtotal**: $8.50/month

### Networking

**NAT Gateway** (1):
- Hours: $0.045/hour × 730 hours = **$32.85/month**
- Data Processing: 100GB × $0.045/GB = **$4.50/month**

**Data Transfer**:
- Outbound to Internet: 50GB × $0.09/GB = **$4.50/month**

**Networking Subtotal**: $41.85/month

### **Staging Environment Total: $762.29/month**

---

## Production Environment

**Purpose**: Live platform serving community users, Dojo learning environment for 200+ concurrent learners

**Traffic Profile**: 50-200 concurrent users, 24/7 availability, high-availability requirements

### Compute - Amazon EKS

**EKS Control Plane**: **$73.00/month**

**Worker Nodes** (6× t3.xlarge instances):
- Instance Type: t3.xlarge (4 vCPU, 16GB RAM)
- Quantity: 6 nodes (3 per AZ, 2 AZs for HA)
- On-Demand Cost: $0.1664/hour × 6 × 730 hours = **$728.83/month**
- Storage: 200GB EBS gp3 per node × 6 = $0.08/GB × 1,200GB = **$96.00/month**

**Note**: Production will use Reserved Instances after validation period (40% savings = $291.53/month savings)

**EKS Subtotal**: $897.83/month

### Database - Amazon RDS PostgreSQL

**Instance Configuration**:
- Instance Type: db.m5.large (2 vCPU, 8GB RAM)
- Multi-AZ deployment (high availability)
- Storage: 500GB gp3 SSD
- Automated backups with 7-day retention
- Cost Breakdown:
  - Instance (Multi-AZ): $0.190/hour × 730 hours × 2 = **$277.40/month**
  - Storage: 500GB × $0.115/GB = **$57.50/month**
  - Backup Storage: 500GB × $0.095/GB = **$47.50/month**
  - PIOPS (Provisioned IOPS): 3000 IOPS × $0.10 = **$300.00/month** (optional, for high-traffic scenarios)

**RDS Subtotal (without PIOPS)**: $382.40/month
**RDS Subtotal (with PIOPS)**: $682.40/month

*Using base configuration (without PIOPS) for conservative estimate*

### Load Balancing

**Application Load Balancers** (3):
- ALB Hours: $0.0225/hour × 3 × 730 hours = **$49.28/month**
- LCU: ~20 LCUs average × 3 = $0.008 × 60 × 730 = **$350.40/month**

**ALB Subtotal**: $399.68/month

### Storage - Amazon S3

**Container Images & Artifacts**:
- Standard Storage: 300GB × $0.023/GB = **$6.90/month**
- PUT/GET Requests: ~200,000 requests = **$1.00/month**

**Backup Storage**:
- Standard-IA: 200GB × $0.0125/GB = **$2.50/month**

**Glacier Deep Archive** (long-term backups):
- 500GB × $0.00099/GB = **$0.50/month**

**S3 Subtotal**: $10.90/month

### Container Registry - Amazon ECR

**Private Registry**:
- Storage: 100GB × $0.10/GB = **$10.00/month**
- Data Transfer (within region): Included

**ECR Subtotal**: $10.00/month

### Monitoring - Amazon CloudWatch

**Logs**:
- Ingestion: 100GB × $0.50/GB = **$50.00/month**
- Storage: 100GB × $0.03/GB = **$3.00/month**

**Metrics**:
- Custom Metrics: 500 metrics × $0.30 = **$150.00/month**

**Alarms**: 50 alarms × $0.10 = **$5.00/month**

**CloudWatch Subtotal**: $208.00/month

### AWS X-Ray (Distributed Tracing)

**Traces Recorded**: 5 million traces × $5.00/million = **$25.00/month**
**Traces Retrieved**: 500K traces × $0.50/million = **$0.25/month**

**X-Ray Subtotal**: $25.25/month

### Secrets Management

**Secrets Storage**:
- 25 secrets × $0.40/secret = **$10.00/month**
- API Calls: 200,000 × $0.05/10,000 = **$10.00/month**

**Secrets Manager Subtotal**: $20.00/month

### Networking

**NAT Gateways** (2, one per AZ for HA):
- Hours: $0.045/hour × 2 × 730 hours = **$65.70/month**
- Data Processing: 300GB × $0.045/GB = **$13.50/month**

**Data Transfer**:
- Outbound to Internet: 200GB × $0.09/GB = **$18.00/month**

**VPC Endpoints** (for S3, ECR):
- 2 endpoints × $0.01/hour × 730 hours = **$14.60/month**

**Networking Subtotal**: $111.80/month

### AWS Certificate Manager

**SSL/TLS Certificates**: Free (public certificates)

### AWS WAF (Web Application Firewall)

**Web ACL**: $5.00/month
**Rules**: 5 rules × $1.00 = **$5.00/month**
**Requests**: 10 million × $0.60/million = **$6.00/month**

**WAF Subtotal**: $16.00/month

### **Production Environment Total: $2,083.86/month**

*(Conservative estimate without PIOPS, with potential to add $300/month for high-performance scenarios)*

---

## Cost Summary: All Environments

| Environment | Monthly Cost | Annual Cost | % of Total |
|-------------|-------------|-------------|------------|
| **Development** | $378.82 | $4,545.84 | 18% |
| **Staging** | $762.29 | $9,147.48 | 37% |
| **Production** | $2,083.86 | $25,006.32 | 100% |
| **TOTAL (3 Environments)** | **$3,224.97** | **$38,699.64** | - |

### Phased Rollout (Recommended)

**Phase 1: Months 1-3** (Development Only)
- Monthly: $378.82
- Quarterly Total: **$1,136.46**

**Phase 2: Months 4-6** (Development + Staging)
- Monthly: $378.82 + $762.29 = $1,141.11
- Quarterly Total: **$3,423.33**

**Phase 3: Months 7-12** (All Three Environments)
- Monthly: $3,224.97
- Semi-Annual Total: **$19,349.82**

**12-Month Phased Total**: **$23,909.61**

---

## AWS Activate Credit Request Justification

### Requested Amount: $25,000

**Allocation Strategy**:

**Phase 1 (Months 1-3)**: $1,200 credits
- Build production-grade reference implementation
- Complete Terraform modules for AWS
- Deploy and validate all platform services
- Document deployment patterns

**Phase 2 (Months 4-6)**: $3,500 credits
- Launch staging environment for testing
- Begin Dojo learning platform development
- Support initial community adopters (10-20 users)
- Implement automated testing infrastructure

**Phase 3 (Months 7-12)**: $20,300 credits
- Launch production environment for community
- Scale Dojo platform to 200+ concurrent learners
- Provide demo environments for enterprise prospects
- Support growing open-source community

**Reserve/Buffer**: $0 (exact 12-month coverage)

---

## Cost Optimization Strategy

### Immediate Optimizations (Months 1-6)

**Development Environment**:
- Use Spot Instances for worker nodes: **30% savings** = $27.33/month
- Schedule shutdown during non-business hours (nights/weekends): **60% uptime** = $54.66/month saved
- **Combined Savings**: $82/month or $492 over 6 months

**Staging Environment**:
- Use Spot Instances where possible: **25% savings** = $60.74/month
- Schedule shutdown outside testing windows: **40% savings** = $140.79/month
- **Combined Savings**: $201.53/month or $1,209 over 6 months

**Total Phase 1-2 Savings**: $1,701 over 6 months

### Long-Term Optimizations (Months 7-12)

**Reserved Instances** (1-year commitment after validation):
- EKS Worker Nodes: **40% savings** = $291.53/month
- RDS Instances: **35% savings** = $133.84/month
- **Combined Savings**: $425.37/month or $2,552 over 6 months

**Auto-Scaling Policies**:
- Scale down during low-traffic periods (nights): **15% compute savings** = $109.32/month
- Right-size instances based on utilization: **10% additional savings** = $72.88/month
- **Combined Savings**: $182.20/month or $1,093 over 6 months

**Storage Optimization**:
- Lifecycle policies for S3 (move to IA after 30 days): **20% savings** = $2.18/month
- EBS snapshot management (delete old snapshots): **10% savings** = $9.60/month
- **Combined Savings**: $11.78/month or $71 over 6 months

**Total Phase 3 Savings**: $3,716 over 6 months

### Projected 12-Month Cost with Optimizations

- **Months 1-6 (with immediate optimizations)**: $1,136.46 + ($3,423.33 - $1,209) = **$3,350.79**
- **Months 7-12 (with all optimizations)**: ($19,349.82 - $3,716) = **$15,633.82**
- **Total Optimized 12-Month Cost**: **$18,984.61**

**Savings vs. Baseline**: $23,909.61 - $18,984.61 = **$4,925 (21% reduction)**

---

## Monitoring and Cost Control

### AWS Cost Management Tools

**AWS Budgets**:
- Set monthly budget alerts at 80%, 100%, 120% thresholds
- Email notifications to team and AWS billing contact
- Automatic notifications for anomaly detection

**Cost Allocation Tags**:
```
Environment: [dev|staging|prod]
Project: fawkes
Component: [eks|rds|s3|alb|cloudwatch]
Owner: platform-team
CostCenter: engineering
```

**AWS Cost Explorer**:
- Weekly cost reviews
- Identify cost anomalies
- Track savings from optimizations

**Third-Party Tools** (optional):
- CloudHealth or CloudCheckr for advanced cost optimization
- Infracost for Terraform cost estimation in CI/CD

### Cost Anomaly Detection

**Automated Alerts for**:
- Unexpected traffic spikes (LCU increases)
- Storage growth exceeding 20% month-over-month
- Compute utilization above 85% (scale up) or below 30% (scale down)
- Data transfer costs exceeding $100/month

### Monthly Cost Review Process

**Week 1**: Review previous month's spend vs. budget
**Week 2**: Analyze cost trends and usage patterns
**Week 3**: Implement optimization recommendations
**Week 4**: Validate optimizations and adjust budgets

---

## Additional AWS Services (Optional/Future)

Services we may adopt as platform matures:

| Service | Use Case | Estimated Monthly Cost |
|---------|----------|------------------------|
| **AWS Config** | Compliance tracking | $20-$50 |
| **AWS GuardDuty** | Threat detection | $30-$100 |
| **AWS Security Hub** | Security posture | $10-$30 |
| **AWS Systems Manager** | Parameter store (alternative to Secrets Manager) | $5-$15 |
| **Amazon OpenSearch** | Log analytics (alternative to self-hosted) | $200-$500 |
| **AWS Backup** | Centralized backup management | $50-$150 |
| **Amazon CloudFront** | CDN for static assets | $20-$100 |
| **AWS Lambda** | Serverless automation | $10-$50 |

**Total Optional Services**: $345-$995/month

*These services are not included in base cost estimate but represent future expansion opportunities.*

---

## ROI Analysis

### Value Delivered by AWS Credits

**Direct Benefits**:
- **Platform Development**: 12 months of uninterrupted development
- **Community Support**: 200+ learners trained on Dojo platform
- **Enterprise Demos**: 20+ prospect demonstrations
- **Open Source Contributions**: Reference implementation for AWS deployments

**Indirect Benefits**:
- **AWS Advocacy**: Every Dojo graduate learns AWS-native platform engineering
- **Ecosystem Growth**: Fawkes users become AWS customers
- **Documentation**: Comprehensive AWS deployment guides benefit broader community
- **Best Practices**: Showcase modern AWS architecture patterns

### Expected Outcomes (12-Month Horizon)

**Community Metrics**:
- 500+ GitHub stars
- 50+ active contributors
- 200+ Dojo learners certified
- 20+ organizations adopting Fawkes on AWS

**Business Metrics**:
- 10 enterprise pilot programs
- $10K MRR from managed service beta
- 5 partnerships with training organizations
- 100+ job placements for Dojo graduates

**AWS-Specific Outcomes**:
- 30+ organizations migrated to AWS using Fawkes
- $500K+ annual AWS spend driven by Fawkes users
- 200+ engineers trained on AWS services
- Contribution to AWS EKS/RDS/CloudWatch ecosystems

---

## Conclusion

**Total AWS Investment Required**: $23,910 over 12 months (phased)
**AWS Activate Credit Request**: $25,000
**Optimized Cost (with savings)**: $18,985 (21% under budget)

**Why This Investment Makes Sense**:

1. **AWS-Native Platform**: Fawkes is purpose-built for AWS, showcasing EKS, RDS, S3, and CloudWatch
2. **Community Impact**: Training 200+ platform engineers who will use AWS in their organizations
3. **Open Source Value**: Reference implementation benefits entire AWS community
4. **Long-Term AWS Commitment**: Every Fawkes user is a potential AWS customer
5. **Cost-Effective**: Phased approach validates value before full-scale deployment

**Next Steps**:
1. Secure AWS Activate credits ($25,000)
2. Deploy Phase 1 (Development environment)
3. Build reference implementation and documentation
4. Launch Dojo platform (Phase 2-3)
5. Support community growth and enterprise adoption

---

## Appendix: AWS Pricing Assumptions

**Pricing effective as of**: October 2025
**Region**: US-East-1 (N. Virginia)
**Currency**: USD
**Pricing Model**: On-Demand (with Reserved Instance projections)

**Sources**:
- [AWS Pricing Calculator](https://calculator.aws)
- [Amazon EKS Pricing](https://aws.amazon.com/eks/pricing/)
- [Amazon RDS Pricing](https://aws.amazon.com/rds/postgresql/pricing/)
- [Amazon S3 Pricing](https://aws.amazon.com/s3/pricing/)
- [Elastic Load Balancing Pricing](https://aws.amazon.com/elasticloadbalancing/pricing/)

**Disclaimer**: Actual costs may vary based on usage patterns, data transfer, and AWS pricing changes. This estimate provides a conservative baseline for planning purposes.

---

**Document Owner**: Fawkes Platform Team
**Review Cadence**: Monthly during AWS Activate period
**Last Review**: October 7, 2025
**Next Review**: November 7, 2025