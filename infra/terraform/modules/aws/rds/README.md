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

| Name      | Version  |
| --------- | -------- |
| terraform | >= 1.6.0 |
| aws       | >= 5.0.0 |
| random    | >= 3.0.0 |

## Inputs

| Name                         | Description                              | Type           | Default         | Required |
| ---------------------------- | ---------------------------------------- | -------------- | --------------- | :------: |
| identifier                   | Name of the RDS instance                 | `string`       | n/a             |   yes    |
| vpc_id                       | ID of the VPC                            | `string`       | n/a             |   yes    |
| subnet_ids                   | List of subnet IDs                       | `list(string)` | n/a             |   yes    |
| engine                       | Database engine (postgres or mysql)      | `string`       | n/a             |   yes    |
| engine_version               | Database engine version                  | `string`       | n/a             |   yes    |
| instance_class               | Instance class                           | `string`       | `"db.t3.micro"` |    no    |
| parameter_group_family       | Parameter group family                   | `string`       | n/a             |   yes    |
| allocated_storage            | Allocated storage in GB                  | `number`       | `20`            |    no    |
| max_allocated_storage        | Max storage for autoscaling              | `number`       | `100`           |    no    |
| storage_encrypted            | Enable encryption                        | `bool`         | `true`          |    no    |
| database_name                | Default database name                    | `string`       | `null`          |    no    |
| master_username              | Master username                          | `string`       | n/a             |   yes    |
| master_password              | Master password (auto-generated if null) | `string`       | `null`          |    no    |
| multi_az                     | Enable Multi-AZ                          | `bool`         | `false`         |    no    |
| backup_retention_period      | Days to retain backups                   | `number`       | `7`             |    no    |
| performance_insights_enabled | Enable Performance Insights              | `bool`         | `false`         |    no    |
| monitoring_interval          | Enhanced monitoring interval             | `number`       | `0`             |    no    |
| allowed_security_group_ids   | Allowed security groups                  | `list(string)` | `[]`            |    no    |
| allowed_cidr_blocks          | Allowed CIDR blocks                      | `list(string)` | `[]`            |    no    |
| tags                         | Tags to apply to resources               | `map(string)`  | `{}`            |    no    |

## Outputs

| Name                 | Description                 |
| -------------------- | --------------------------- |
| db_instance_id       | RDS instance ID             |
| db_instance_endpoint | Connection endpoint         |
| db_instance_address  | Database address            |
| db_instance_port     | Database port               |
| db_master_username   | Master username             |
| db_master_password   | Master password (sensitive) |
| db_security_group_id | Security group ID           |

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
CREATE USER appuser WITH PASSWORD 'secure_password'; -- pragma: allowlist secret
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

<!-- BEGIN_TF_DOCS -->

## Requirements

| Name                                                                     | Version  |
| ------------------------------------------------------------------------ | -------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws)                   | >= 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement_random)          | >= 3.0.0 |

## Providers

| Name                                                      | Version |
| --------------------------------------------------------- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws)          | 6.27.0  |
| <a name="provider_random"></a> [random](#provider_random) | 3.7.2   |

## Resources

| Name                                                                                                                                                    | Type     |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- |
| [aws_cloudwatch_metric_alarm.cpu_utilization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)      | resource |
| [aws_cloudwatch_metric_alarm.database_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.free_storage_space](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm)   | resource |
| [aws_db_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance)                                         | resource |
| [aws_db_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group)                           | resource |
| [aws_db_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group)                                 | resource |
| [aws_iam_role.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role)                                     | resource |
| [aws_iam_role_policy_attachment.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)                                    | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password)                                       | resource |

## Inputs

| Name                                                                                                                                             | Description                                                           | Type                                                                     | Default                 | Required |
| ------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- | ------------------------------------------------------------------------ | ----------------------- | :------: |
| <a name="input_engine"></a> [engine](#input_engine)                                                                                              | Database engine type                                                  | `string`                                                                 | n/a                     |   yes    |
| <a name="input_engine_version"></a> [engine_version](#input_engine_version)                                                                      | Database engine version                                               | `string`                                                                 | n/a                     |   yes    |
| <a name="input_identifier"></a> [identifier](#input_identifier)                                                                                  | The name of the RDS instance                                          | `string`                                                                 | n/a                     |   yes    |
| <a name="input_master_username"></a> [master_username](#input_master_username)                                                                   | Master username for the database                                      | `string`                                                                 | n/a                     |   yes    |
| <a name="input_parameter_group_family"></a> [parameter_group_family](#input_parameter_group_family)                                              | Database parameter group family                                       | `string`                                                                 | n/a                     |   yes    |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids)                                                                                  | List of subnet IDs for the DB subnet group                            | `list(string)`                                                           | n/a                     |   yes    |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id)                                                                                              | ID of the VPC where RDS will be created                               | `string`                                                                 | n/a                     |   yes    |
| <a name="input_alarm_actions"></a> [alarm_actions](#input_alarm_actions)                                                                         | List of ARNs to notify when alarm triggers                            | `list(string)`                                                           | `[]`                    |    no    |
| <a name="input_allocated_storage"></a> [allocated_storage](#input_allocated_storage)                                                             | The allocated storage in gigabytes                                    | `number`                                                                 | `20`                    |    no    |
| <a name="input_allowed_cidr_blocks"></a> [allowed_cidr_blocks](#input_allowed_cidr_blocks)                                                       | List of CIDR blocks allowed to access the database                    | `list(string)`                                                           | `[]`                    |    no    |
| <a name="input_allowed_security_group_ids"></a> [allowed_security_group_ids](#input_allowed_security_group_ids)                                  | List of security group IDs allowed to access the database             | `list(string)`                                                           | `[]`                    |    no    |
| <a name="input_auto_minor_version_upgrade"></a> [auto_minor_version_upgrade](#input_auto_minor_version_upgrade)                                  | Enable automatic minor version upgrades                               | `bool`                                                                   | `true`                  |    no    |
| <a name="input_backup_retention_period"></a> [backup_retention_period](#input_backup_retention_period)                                           | Days to retain backups                                                | `number`                                                                 | `7`                     |    no    |
| <a name="input_backup_window"></a> [backup_window](#input_backup_window)                                                                         | Preferred backup window (UTC)                                         | `string`                                                                 | `"03:00-04:00"`         |    no    |
| <a name="input_cpu_utilization_threshold"></a> [cpu_utilization_threshold](#input_cpu_utilization_threshold)                                     | CPU utilization threshold for CloudWatch alarm                        | `number`                                                                 | `80`                    |    no    |
| <a name="input_create_cloudwatch_alarms"></a> [create_cloudwatch_alarms](#input_create_cloudwatch_alarms)                                        | Create CloudWatch alarms for monitoring                               | `bool`                                                                   | `true`                  |    no    |
| <a name="input_database_connections_threshold"></a> [database_connections_threshold](#input_database_connections_threshold)                      | Database connections threshold for CloudWatch alarm                   | `number`                                                                 | `100`                   |    no    |
| <a name="input_database_name"></a> [database_name](#input_database_name)                                                                         | Name of the default database to create                                | `string`                                                                 | `null`                  |    no    |
| <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection)                                                       | Enable deletion protection                                            | `bool`                                                                   | `true`                  |    no    |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled_cloudwatch_logs_exports](#input_enabled_cloudwatch_logs_exports)                   | List of log types to export to CloudWatch                             | `list(string)`                                                           | `[]`                    |    no    |
| <a name="input_free_storage_space_threshold"></a> [free_storage_space_threshold](#input_free_storage_space_threshold)                            | Free storage space threshold in bytes for CloudWatch alarm            | `number`                                                                 | `5000000000`            |    no    |
| <a name="input_instance_class"></a> [instance_class](#input_instance_class)                                                                      | The instance class to use                                             | `string`                                                                 | `"db.t3.micro"`         |    no    |
| <a name="input_iops"></a> [iops](#input_iops)                                                                                                    | Amount of provisioned IOPS (only for io1/io2 storage types)           | `number`                                                                 | `null`                  |    no    |
| <a name="input_kms_key_id"></a> [kms_key_id](#input_kms_key_id)                                                                                  | ARN of KMS key for storage encryption (uses default if not specified) | `string`                                                                 | `null`                  |    no    |
| <a name="input_maintenance_window"></a> [maintenance_window](#input_maintenance_window)                                                          | Preferred maintenance window                                          | `string`                                                                 | `"sun:04:00-sun:05:00"` |    no    |
| <a name="input_master_password"></a> [master_password](#input_master_password)                                                                   | Master password (leave null to auto-generate)                         | `string`                                                                 | `null`                  |    no    |
| <a name="input_max_allocated_storage"></a> [max_allocated_storage](#input_max_allocated_storage)                                                 | Maximum storage threshold for autoscaling (0 to disable)              | `number`                                                                 | `100`                   |    no    |
| <a name="input_monitoring_interval"></a> [monitoring_interval](#input_monitoring_interval)                                                       | Interval for enhanced monitoring (0 to disable, 1, 5, 10, 15, 30, 60) | `number`                                                                 | `0`                     |    no    |
| <a name="input_multi_az"></a> [multi_az](#input_multi_az)                                                                                        | Enable Multi-AZ deployment for high availability                      | `bool`                                                                   | `false`                 |    no    |
| <a name="input_parameters"></a> [parameters](#input_parameters)                                                                                  | List of database parameters to apply                                  | <pre>list(object({<br/> name = string<br/> value = string<br/> }))</pre> | `[]`                    |    no    |
| <a name="input_performance_insights_enabled"></a> [performance_insights_enabled](#input_performance_insights_enabled)                            | Enable Performance Insights                                           | `bool`                                                                   | `false`                 |    no    |
| <a name="input_performance_insights_kms_key_id"></a> [performance_insights_kms_key_id](#input_performance_insights_kms_key_id)                   | KMS key ID for Performance Insights encryption                        | `string`                                                                 | `null`                  |    no    |
| <a name="input_performance_insights_retention_period"></a> [performance_insights_retention_period](#input_performance_insights_retention_period) | Days to retain Performance Insights data                              | `number`                                                                 | `7`                     |    no    |
| <a name="input_port"></a> [port](#input_port)                                                                                                    | Port for database connections                                         | `number`                                                                 | `null`                  |    no    |
| <a name="input_publicly_accessible"></a> [publicly_accessible](#input_publicly_accessible)                                                       | Make the database publicly accessible                                 | `bool`                                                                   | `false`                 |    no    |
| <a name="input_skip_final_snapshot"></a> [skip_final_snapshot](#input_skip_final_snapshot)                                                       | Skip final snapshot when destroying                                   | `bool`                                                                   | `false`                 |    no    |
| <a name="input_storage_encrypted"></a> [storage_encrypted](#input_storage_encrypted)                                                             | Enable storage encryption                                             | `bool`                                                                   | `true`                  |    no    |
| <a name="input_storage_type"></a> [storage_type](#input_storage_type)                                                                            | Storage type for RDS instance                                         | `string`                                                                 | `"gp3"`                 |    no    |
| <a name="input_tags"></a> [tags](#input_tags)                                                                                                    | Tags to apply to RDS resources                                        | `map(string)`                                                            | `{}`                    |    no    |

## Outputs

| Name                                                                                                  | Description                                 |
| ----------------------------------------------------------------------------------------------------- | ------------------------------------------- |
| <a name="output_db_instance_address"></a> [db_instance_address](#output_db_instance_address)          | The address of the RDS instance             |
| <a name="output_db_instance_arn"></a> [db_instance_arn](#output_db_instance_arn)                      | The ARN of the RDS instance                 |
| <a name="output_db_instance_endpoint"></a> [db_instance_endpoint](#output_db_instance_endpoint)       | The connection endpoint                     |
| <a name="output_db_instance_id"></a> [db_instance_id](#output_db_instance_id)                         | The RDS instance ID                         |
| <a name="output_db_instance_name"></a> [db_instance_name](#output_db_instance_name)                   | The database name                           |
| <a name="output_db_instance_port"></a> [db_instance_port](#output_db_instance_port)                   | The database port                           |
| <a name="output_db_master_password"></a> [db_master_password](#output_db_master_password)             | The master password for the database        |
| <a name="output_db_master_username"></a> [db_master_username](#output_db_master_username)             | The master username for the database        |
| <a name="output_db_monitoring_role_arn"></a> [db_monitoring_role_arn](#output_db_monitoring_role_arn) | The ARN of the enhanced monitoring IAM role |
| <a name="output_db_parameter_group_id"></a> [db_parameter_group_id](#output_db_parameter_group_id)    | The db parameter group id                   |
| <a name="output_db_security_group_id"></a> [db_security_group_id](#output_db_security_group_id)       | The security group ID of the RDS instance   |
| <a name="output_db_subnet_group_id"></a> [db_subnet_group_id](#output_db_subnet_group_id)             | The db subnet group name                    |

<!-- END_TF_DOCS -->

<!-- prettier-ignore-start -->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement_terraform) | >= 1.6.0 |
| <a name="requirement_aws"></a> [aws](#requirement_aws) | >= 5.0.0 |
| <a name="requirement_random"></a> [random](#requirement_random) | >= 3.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider_aws) | 6.27.0 |
| <a name="provider_random"></a> [random](#provider_random) | 3.7.2 |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudwatch_metric_alarm.cpu_utilization](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.database_connections](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.free_storage_space](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_db_instance.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_instance) | resource |
| [aws_db_parameter_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_parameter_group) | resource |
| [aws_db_subnet_group.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_role.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.rds](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [random_password.master](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_engine"></a> [engine](#input_engine) | Database engine type | `string` | n/a | yes |
| <a name="input_engine_version"></a> [engine_version](#input_engine_version) | Database engine version | `string` | n/a | yes |
| <a name="input_identifier"></a> [identifier](#input_identifier) | The name of the RDS instance | `string` | n/a | yes |
| <a name="input_master_username"></a> [master_username](#input_master_username) | Master username for the database | `string` | n/a | yes |
| <a name="input_parameter_group_family"></a> [parameter_group_family](#input_parameter_group_family) | Database parameter group family | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet_ids](#input_subnet_ids) | List of subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc_id](#input_vpc_id) | ID of the VPC where RDS will be created | `string` | n/a | yes |
| <a name="input_alarm_actions"></a> [alarm_actions](#input_alarm_actions) | List of ARNs to notify when alarm triggers | `list(string)` | `[]` | no |
| <a name="input_allocated_storage"></a> [allocated_storage](#input_allocated_storage) | The allocated storage in gigabytes | `number` | `20` | no |
| <a name="input_allowed_cidr_blocks"></a> [allowed_cidr_blocks](#input_allowed_cidr_blocks) | List of CIDR blocks allowed to access the database | `list(string)` | `[]` | no |
| <a name="input_allowed_security_group_ids"></a> [allowed_security_group_ids](#input_allowed_security_group_ids) | List of security group IDs allowed to access the database | `list(string)` | `[]` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto_minor_version_upgrade](#input_auto_minor_version_upgrade) | Enable automatic minor version upgrades | `bool` | `true` | no |
| <a name="input_backup_retention_period"></a> [backup_retention_period](#input_backup_retention_period) | Days to retain backups | `number` | `7` | no |
| <a name="input_backup_window"></a> [backup_window](#input_backup_window) | Preferred backup window (UTC) | `string` | `"03:00-04:00"` | no |
| <a name="input_cpu_utilization_threshold"></a> [cpu_utilization_threshold](#input_cpu_utilization_threshold) | CPU utilization threshold for CloudWatch alarm | `number` | `80` | no |
| <a name="input_create_cloudwatch_alarms"></a> [create_cloudwatch_alarms](#input_create_cloudwatch_alarms) | Create CloudWatch alarms for monitoring | `bool` | `true` | no |
| <a name="input_database_connections_threshold"></a> [database_connections_threshold](#input_database_connections_threshold) | Database connections threshold for CloudWatch alarm | `number` | `100` | no |
| <a name="input_database_name"></a> [database_name](#input_database_name) | Name of the default database to create | `string` | `null` | no |
| <a name="input_deletion_protection"></a> [deletion_protection](#input_deletion_protection) | Enable deletion protection | `bool` | `true` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled_cloudwatch_logs_exports](#input_enabled_cloudwatch_logs_exports) | List of log types to export to CloudWatch | `list(string)` | `[]` | no |
| <a name="input_free_storage_space_threshold"></a> [free_storage_space_threshold](#input_free_storage_space_threshold) | Free storage space threshold in bytes for CloudWatch alarm | `number` | `5000000000` | no |
| <a name="input_instance_class"></a> [instance_class](#input_instance_class) | The instance class to use | `string` | `"db.t3.micro"` | no |
| <a name="input_iops"></a> [iops](#input_iops) | Amount of provisioned IOPS (only for io1/io2 storage types) | `number` | `null` | no |
| <a name="input_kms_key_id"></a> [kms_key_id](#input_kms_key_id) | ARN of KMS key for storage encryption (uses default if not specified) | `string` | `null` | no |
| <a name="input_maintenance_window"></a> [maintenance_window](#input_maintenance_window) | Preferred maintenance window | `string` | `"sun:04:00-sun:05:00"` | no |
| <a name="input_master_password"></a> [master_password](#input_master_password) | Master password (leave null to auto-generate) | `string` | `null` | no |
| <a name="input_max_allocated_storage"></a> [max_allocated_storage](#input_max_allocated_storage) | Maximum storage threshold for autoscaling (0 to disable) | `number` | `100` | no |
| <a name="input_monitoring_interval"></a> [monitoring_interval](#input_monitoring_interval) | Interval for enhanced monitoring (0 to disable, 1, 5, 10, 15, 30, 60) | `number` | `0` | no |
| <a name="input_multi_az"></a> [multi_az](#input_multi_az) | Enable Multi-AZ deployment for high availability | `bool` | `false` | no |
| <a name="input_parameters"></a> [parameters](#input_parameters) | List of database parameters to apply | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_performance_insights_enabled"></a> [performance_insights_enabled](#input_performance_insights_enabled) | Enable Performance Insights | `bool` | `false` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance_insights_kms_key_id](#input_performance_insights_kms_key_id) | KMS key ID for Performance Insights encryption | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance_insights_retention_period](#input_performance_insights_retention_period) | Days to retain Performance Insights data | `number` | `7` | no |
| <a name="input_port"></a> [port](#input_port) | Port for database connections | `number` | `null` | no |
| <a name="input_publicly_accessible"></a> [publicly_accessible](#input_publicly_accessible) | Make the database publicly accessible | `bool` | `false` | no |
| <a name="input_skip_final_snapshot"></a> [skip_final_snapshot](#input_skip_final_snapshot) | Skip final snapshot when destroying | `bool` | `false` | no |
| <a name="input_storage_encrypted"></a> [storage_encrypted](#input_storage_encrypted) | Enable storage encryption | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage_type](#input_storage_type) | Storage type for RDS instance | `string` | `"gp3"` | no |
| <a name="input_tags"></a> [tags](#input_tags) | Tags to apply to RDS resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_db_instance_address"></a> [db_instance_address](#output_db_instance_address) | The address of the RDS instance |
| <a name="output_db_instance_arn"></a> [db_instance_arn](#output_db_instance_arn) | The ARN of the RDS instance |
| <a name="output_db_instance_endpoint"></a> [db_instance_endpoint](#output_db_instance_endpoint) | The connection endpoint |
| <a name="output_db_instance_id"></a> [db_instance_id](#output_db_instance_id) | The RDS instance ID |
| <a name="output_db_instance_name"></a> [db_instance_name](#output_db_instance_name) | The database name |
| <a name="output_db_instance_port"></a> [db_instance_port](#output_db_instance_port) | The database port |
| <a name="output_db_master_password"></a> [db_master_password](#output_db_master_password) | The master password for the database |
| <a name="output_db_master_username"></a> [db_master_username](#output_db_master_username) | The master username for the database |
| <a name="output_db_monitoring_role_arn"></a> [db_monitoring_role_arn](#output_db_monitoring_role_arn) | The ARN of the enhanced monitoring IAM role |
| <a name="output_db_parameter_group_id"></a> [db_parameter_group_id](#output_db_parameter_group_id) | The db parameter group id |
| <a name="output_db_security_group_id"></a> [db_security_group_id](#output_db_security_group_id) | The security group ID of the RDS instance |
| <a name="output_db_subnet_group_id"></a> [db_subnet_group_id](#output_db_subnet_group_id) | The db subnet group name |
<!-- END_TF_DOCS -->
<!-- prettier-ignore-end -->
