# Civo Network Module

Manages a Civo private network with optional firewall configuration and ingress rules.

## Usage

```hcl
module "network" {
  source       = "../../modules/civo/network"
  network_name = "fawkes-network"
  location     = "NYC1"
  cidr_block   = "10.0.0.0/16"

  create_firewall = true

  firewall_ingress_rules = [
    {
      label       = "allow-k8s-api"
      protocol    = "tcp"
      start_port  = 6443
      end_port    = 6443
      cidr_blocks = ["0.0.0.0/0"]
      action      = "allow"
    }
  ]
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.6.0 |
| civo | >= 1.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| network_name | Name of the network | `string` | n/a | yes |
| location | Civo region (NYC1, LON1, FRA1, PHX1) | `string` | n/a | yes |
| cidr_block | CIDR block for the network | `string` | `"10.0.0.0/16"` | no |
| create_firewall | Create a firewall for the network | `bool` | `true` | no |
| firewall_ingress_rules | List of firewall ingress rules | `list(object)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| network_id | The ID of the network |
| network_name | The name/label of the network |
| network_cidr | CIDR block of the network |
| default | Whether this is the default network |
| region | Region where the network is deployed |
| firewall_id | ID of the firewall |
| firewall_name | Name of the firewall |

## Validation Rules

- Network name must be 2–64 characters, start with alphanumeric, end with alphanumeric or underscore, contain only alphanumerics, periods, hyphens, or underscores
- Location must be one of: `NYC1`, `LON1`, `FRA1`, `PHX1`
- CIDR block must be a valid CIDR notation
- Firewall rule protocol must be `tcp`, `udp`, or `icmp`
- Firewall rule action must be `allow` or `deny`
