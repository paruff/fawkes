# GCP Cloud SQL Module

Manages a Google Cloud SQL instance (PostgreSQL or MySQL) with configurable availability, backup, networking, read replicas, and monitoring.

## Usage

```hcl
module "cloudsql" {
  source           = "../../modules/gcp/cloudsql"
  instance_name    = "fawkes-postgres"
  location         = "us-central1"
  project_id       = "my-gcp-project"
  database_version = "POSTGRES_15"

  tier              = "db-n1-standard-2"
  availability_type = "REGIONAL"

  private_network = module.vpc.network_id

  databases = ["fawkes", "backstage"]
  users = [
    { name = "fawkes", password = null }
  ]

  tags = {
    environment = "dev"
    platform    = "fawkes"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| google | >= 5.0.0 |
| random | >= 3.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| instance_name | Name of the Cloud SQL instance | `string` | n/a | yes |
| location | GCP region | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| database_version | Database version (POSTGRES_XX or MYSQL_XX) | `string` | n/a | yes |
| use_random_suffix | Add random suffix to instance name | `bool` | `true` | no |
| tier | Machine tier | `string` | `"db-f1-micro"` | no |
| availability_type | Availability type (REGIONAL or ZONAL) | `string` | `"REGIONAL"` | no |
| disk_type | Disk type (PD_SSD or PD_HDD) | `string` | `"PD_SSD"` | no |
| disk_size | Disk size in GB | `number` | `10` | no |
| disk_autoresize | Enable automatic disk size increase | `bool` | `true` | no |
| disk_autoresize_limit | Maximum disk size for autoresize (0 = unlimited) | `number` | `0` | no |
| deletion_protection | Enable deletion protection | `bool` | `true` | no |
| backup_enabled | Enable automated backups | `bool` | `true` | no |
| backup_start_time | Start time for daily backups (HH:MM) | `string` | `"03:00"` | no |
| point_in_time_recovery_enabled | Enable point-in-time recovery | `bool` | `true` | no |
| transaction_log_retention_days | Transaction log retention days | `number` | `7` | no |
| retained_backups | Number of backups to retain | `number` | `7` | no |
| ipv4_enabled | Enable public IP | `bool` | `false` | no |
| private_network | VPC network ID for private IP | `string` | `null` | no |
| require_ssl | Require SSL for connections | `bool` | `true` | no |
| authorized_networks | Authorized networks for public IP access | `list(object)` | `[]` | no |
| maintenance_window_day | Day of week for maintenance (1–7) | `number` | `7` | no |
| maintenance_window_hour | Hour of day for maintenance (0–23) | `number` | `3` | no |
| maintenance_window_update_track | Update track (canary or stable) | `string` | `"stable"` | no |
| query_insights_enabled | Enable Query Insights | `bool` | `true` | no |
| databases | List of databases to create | `list(string)` | `[]` | no |
| users | List of database users to create | `list(object)` | `[]` | no |
| read_replicas | List of read replicas | `list(object)` | `[]` | no |
| tags | Labels to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| instance_name | The name of the Cloud SQL instance |
| instance_connection_name | The connection name |
| instance_self_link | The self link of the instance |
| instance_service_account_email | Service account email |
| private_ip_address | The private IP address |
| public_ip_address | The public IP address |
| database_names | List of created database names |
| user_names | List of created user names |
| replica_connection_names | Map of replica names to connection names |
| generated_user_passwords | Map of user names to generated passwords (sensitive) |

## Validation Rules

- Instance name must be 1–84 characters, start with lowercase letter, contain only lowercase letters, numbers, or hyphens
- Database version must match format `POSTGRES_XX` or `MYSQL_XX`
- Availability type must be `REGIONAL` or `ZONAL`
- Disk type must be `PD_SSD` or `PD_HDD`
- Disk size must be 10–65536 GB
- Disk autoresize limit must be 0 or at least 10 GB
- Backup start time must be in `HH:MM` format
- Transaction log retention must be 1–35 days
- Retained backups must be 1–365
- Maintenance window day must be 1–7 (1 = Monday)
- Maintenance window hour must be 0–23
- Maintenance window update track must be `canary` or `stable`
- Query plans per minute must be 0–20
- Query string length must be 256–4500
