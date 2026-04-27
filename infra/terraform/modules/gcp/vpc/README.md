# GCP VPC Module

Manages a Google Cloud VPC network with configurable subnets, Cloud NAT, Cloud Router, VPC Flow Logs, and firewall rules.

## Usage

```hcl
module "vpc" {
  source       = "../../modules/gcp/vpc"
  network_name = "fawkes-vpc"
  location     = "us-central1"
  project_id   = "my-gcp-project"

  subnets = [
    {
      name          = "gke-subnet"
      ip_cidr_range = "10.0.1.0/24"
      secondary_ip_ranges = [
        { range_name = "pods",     ip_cidr_range = "10.1.0.0/16" },
        { range_name = "services", ip_cidr_range = "10.2.0.0/16" }
      ]
    }
  ]

  enable_nat_gateway = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| google | >= 5.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| network_name | Name of the VPC network | `string` | n/a | yes |
| location | GCP region | `string` | n/a | yes |
| project_id | GCP project ID | `string` | n/a | yes |
| subnets | List of subnets to create | `list(object)` | n/a | yes |
| routing_mode | Network routing mode (REGIONAL or GLOBAL) | `string` | `"REGIONAL"` | no |
| enable_nat_gateway | Enable Cloud NAT | `bool` | `true` | no |
| router_asn | ASN for Cloud Router | `number` | `64514` | no |
| nat_ip_allocate_option | How external IPs are allocated for Cloud NAT | `string` | `"AUTO_ONLY"` | no |
| source_subnetwork_ip_ranges_to_nat | How NAT is configured per subnetwork | `string` | `"ALL_SUBNETWORKS_ALL_IP_RANGES"` | no |
| nat_min_ports_per_vm | Minimum ports allocated to a VM for NAT | `number` | `64` | no |
| nat_enable_endpoint_independent_mapping | Enable endpoint independent mapping | `bool` | `false` | no |
| nat_log_config_enable | Enable logging for Cloud NAT | `bool` | `true` | no |
| nat_log_config_filter | Log filter for Cloud NAT | `string` | `"ERRORS_ONLY"` | no |
| enable_flow_logs | Enable VPC Flow Logs | `bool` | `true` | no |
| flow_logs_aggregation_interval | Flow logs aggregation interval | `string` | `"INTERVAL_5_SEC"` | no |
| flow_logs_sampling | Flow logs sampling rate (0.0–1.0) | `number` | `0.5` | no |
| flow_logs_metadata | Metadata to include in flow logs | `string` | `"INCLUDE_ALL_METADATA"` | no |
| firewall_rules | List of custom firewall rules | `list(object)` | `[]` | no |
| create_default_firewall_rules | Create default firewall rules | `bool` | `true` | no |
| allow_ssh_from_iap | Allow SSH from Identity-Aware Proxy | `bool` | `true` | no |
| deny_all_egress | Deny all egress traffic | `bool` | `false` | no |
| tags | Labels for resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | The ID of the VPC network |
| network_name | The name of the VPC network |
| network_self_link | The self link of the VPC network |
| subnet_ids | Map of subnet names to their IDs |
| subnet_self_links | Map of subnet names to their self links |
| subnet_ip_cidr_ranges | Map of subnet names to their CIDR ranges |
| router_id | The ID of the Cloud Router |
| router_name | The name of the Cloud Router |
| nat_id | The ID of the Cloud NAT |
| nat_name | The name of the Cloud NAT |
| firewall_rule_ids | Map of firewall rule names to their IDs |

## Validation Rules

- Network name must be 2–64 characters, start with a lowercase letter, contain only lowercase letters, numbers, or hyphens
- Location must be a valid GCP region (e.g., `us-central1`, `europe-west1`)
- Project ID must be 6–30 characters
- At least one subnet must be specified; all subnet CIDR ranges must be valid
- All subnet names must start with a lowercase letter, contain only lowercase letters, numbers, or hyphens
- Routing mode must be `REGIONAL` or `GLOBAL`
- Router ASN must be in private ASN range (64512–65534 or 4200000000–4294967294)
- NAT IP allocate option must be `MANUAL_ONLY` or `AUTO_ONLY`
- NAT min ports per VM must be 64–65536
- NAT log filter must be `ERRORS_ONLY`, `TRANSLATIONS_ONLY`, or `ALL`
- Flow logs aggregation interval must be one of the valid values
- Flow logs sampling must be 0.0–1.0
- Flow logs metadata must be `EXCLUDE_ALL_METADATA`, `INCLUDE_ALL_METADATA`, or `CUSTOM_METADATA`
- Firewall rule direction must be `INGRESS` or `EGRESS`
- Firewall rule priority must be 0–65535
