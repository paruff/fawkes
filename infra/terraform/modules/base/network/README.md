# Base Network Module

This is a base module that defines common variables and validation patterns for virtual networks across all cloud providers (Azure VNet, AWS VPC, GCP VPC, Civo Network).

**Note**: This module is not intended to be instantiated directly. It serves as a reference for common variable definitions.

## Purpose

This module provides:
- Common variable definitions for virtual networks with validation rules
- Standardized naming conventions (snake_case)
- Reusable patterns for provider-specific implementations

## Usage

Provider-specific modules should reference these variable definitions. For actual deployments, use:

- `../azure/network` - For Azure Virtual Network
- `../aws/network` - For AWS VPC
- `../gcp/network` - For GCP VPC
- `../civo/network` - For Civo Network

## Variables

### Required Variables

- `network_name` - Name of the virtual network (2-64 chars)
- `location` - Cloud provider region/location
- `resource_group_name` - Resource group or organizational unit name
- `address_space` - CIDR blocks for network address space
- `subnet_name` - Name of the subnet
- `subnet_address_prefixes` - CIDR blocks for subnet address prefixes

### Optional Variables

- `enable_nat_gateway` - Enable NAT Gateway (default: true)
- `enable_dns_hostnames` - Enable DNS hostnames (default: true)
- `tags` - Tags/labels to apply (default: {})

## Validation Rules

All variables include validation rules to catch configuration errors early:

- Network name length and format
- Subnet name length (1-80 chars)
- Valid CIDR blocks for address_space
- Valid CIDR blocks for subnet_address_prefixes
- At least one address space required
- At least one subnet address prefix required

## Provider-Specific Extensions

Provider-specific modules should:
1. Reference these variable definitions where applicable
2. Use consistent naming from this base
3. Add provider-specific variables as needed
4. Add provider-specific validation
5. Define their own outputs based on provider resources
