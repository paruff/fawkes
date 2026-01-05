# AWS RDS Module

This module creates a production-ready Amazon RDS (Relational Database Service) instance with automated backups, encryption, and monitoring.

## Features

- **Multi-Engine Support**: PostgreSQL and MySQL
- **High Availability**: Multi-AZ deployment option
- **Automated Backups**: Configurable backup retention and windows
- **Encryption**: Encryption at rest with KMS
- **Performance**: Parameter groups for database tuning
- **Monitoring**: Enhanced monitoring and Performance Insights
- **CloudWatch Alarms**: CPU, connections, and storage monitoring
- **Security**: Least privilege security groups

## Usage

```hcl
module "rds" {
  source = "../../modules/aws/rds"

  identifier                = "fawkes-dev-db"
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  engine                    = "postgres"
  engine_version            = "15.4"
  instance_class            = "db.t3.micro"
  parameter_group_family    = "postgres15"

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_encrypted     = true

  database_name    = "fawkesdb"
  master_username  = "dbadmin"
  # master_password left null to auto-generate

  multi_az                = true
  backup_retention_period = 7

  performance_insights_enabled = true
  monitoring_interval          = 60

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
| random | >= 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| identifier | Name of the RDS instance | `string` | n/a | yes |
| vpc_id | ID of the VPC | `string` | n/a | yes |
| subnet_ids | List of subnet IDs | `list(string)` | n/a | yes |
| engine | Database engine (postgres or mysql) | `string` | n/a | yes |
| engine_version | Database engine version | `string` | n/a | yes |
| instance_class | Instance class | `string` | `"db.t3.micro"` | no |
| parameter_group_family | Parameter group family | `string` | n/a | yes |
| allocated_storage | Allocated storage in GB | `number` | `20` | no |
| max_allocated_storage | Max storage for autoscaling | `number` | `100` | no |
| storage_encrypted | Enable encryption | `bool` | `true` | no |
| database_name | Default database name | `string` | `null` | no |
| master_username | Master username | `string` | n/a | yes |
| master_password | Master password (auto-generated if null) | `string` | `null` | no |
| multi_az | Enable Multi-AZ | `bool` | `false` | no |
| backup_retention_period | Days to retain backups | `number` | `7` | no |
| performance_insights_enabled | Enable Performance Insights | `bool` | `false` | no |
| monitoring_interval | Enhanced monitoring interval | `number` | `0` | no |
| allowed_security_group_ids | Allowed security groups | `list(string)` | `[]` | no |
| allowed_cidr_blocks | Allowed CIDR blocks | `list(string)` | `[]` | no |
| tags | Tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| db_instance_id | RDS instance ID |
| db_instance_endpoint | Connection endpoint |
| db_instance_address | Database address |
| db_instance_port | Database port |
| db_master_username | Master username |
| db_master_password | Master password (sensitive) |
| db_security_group_id | Security group ID |

## Post-Deployment Steps

1. **Retrieve database password** (if auto-generated):
```bash
terraform output -raw db_master_password
```

2. **Connect to database**:
```bash
# PostgreSQL
psql -h <endpoint> -U <username> -d <database>

# MySQL
mysql -h <endpoint> -u <username> -p <database>
```

3. **Create application user**:
```sql
-- PostgreSQL
CREATE USER appuser WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE fawkesdb TO appuser;

-- MySQL
CREATE USER 'appuser'@'%' IDENTIFIED BY 'secure_password';
GRANT ALL PRIVILEGES ON fawkesdb.* TO 'appuser'@'%';
```

## Security Best Practices

1. **Private Subnets**: Deploy RDS in private subnets
2. **Encryption**: Enable `storage_encrypted = true`
3. **Security Groups**: Use `allowed_security_group_ids` to restrict access
4. **SSL/TLS**: Enforce SSL connections in parameter groups
5. **Deletion Protection**: Set `deletion_protection = true` for production
6. **Auto-generated Passwords**: Leave `master_password = null` for secure generation
7. **IAM Authentication**: Consider enabling IAM database authentication

## Parameter Group Examples

### PostgreSQL
```hcl
parameters = [
  {
    name  = "max_connections"
    value = "200"
  },
  {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/32768}"
  },
  {
    name  = "rds.force_ssl"
    value = "1"
  }
]
```

### MySQL
```hcl
parameters = [
  {
    name  = "max_connections"
    value = "200"
  },
  {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  },
  {
    name  = "require_secure_transport"
    value = "ON"
  }
]
```

## Cost Optimization

- **Instance Sizing**: Start with db.t3.micro for dev (~$13/month)
- **Multi-AZ**: Disable for dev environments (saves 2x cost)
- **Backup Retention**: Reduce to 1-3 days for dev
- **Storage Autoscaling**: Set `max_allocated_storage` to prevent over-provisioning
- **Performance Insights**: Disable for dev (free tier: 7 days retention)
- **Reserved Instances**: Purchase for production (up to 69% savings)

## Examples

See the [examples directory](../examples/) for complete usage examples:
- [rds](../examples/rds/) - RDS instance configuration
- [complete](../examples/complete/) - Complete AWS infrastructure with VPC, EKS, RDS, and S3
