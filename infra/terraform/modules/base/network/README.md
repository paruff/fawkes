# Base Network Module

This is a base module that defines common variables and outputs for virtual networks across all cloud providers (Azure VNet, AWS VPC, GCP VPC, Civo Network).

## Purpose

This module provides:
- Common variable definitions for virtual networks with validation rules
- Standardized naming conventions (snake_case)
- Reusable patterns for provider-specific implementations
- Consistent output structure

## Usage

This module is not intended to be used directly. Instead, use provider-specific modules that extend this base:

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

## Outputs

- `network_id` - The virtual network ID
- `network_name` - The virtual network name
- `subnet_id` - The subnet ID
- `subnet_name` - The subnet name

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
1. Define provider-specific variables
2. Use base module variables where possible
3. Map base variables to provider resources
4. Add provider-specific validation
5. Extend outputs with provider-specific information
