# Base Resource Group Module

This is a base module that defines common variables and outputs for resource groups across all cloud providers (Azure Resource Group, AWS Tags, GCP Projects, Civo Organization).

## Purpose

This module provides:
- Common variable definitions for resource grouping with validation rules
- Standardized naming conventions (snake_case)
- Reusable patterns for provider-specific implementations
- Consistent output structure

## Usage

This module is not intended to be used directly. Instead, use provider-specific modules that extend this base:

- `../azure/resource-group` - For Azure Resource Group
- `../aws/resource-group` - For AWS resource tagging
- `../gcp/resource-group` - For GCP Projects
- `../civo/resource-group` - For Civo Organization

## Variables

### Required Variables

- `name` - Name of the resource group (1-90 chars, alphanumerics, periods, underscores, hyphens, parenthesis)
- `location` - Cloud provider region/location

### Optional Variables

- `tags` - Tags/labels to apply (default: {})

## Outputs

- `id` - The resource group ID
- `name` - The resource group name
- `location` - The resource group location

## Validation Rules

All variables include validation rules to catch configuration errors early:

- Resource group name length (1-90 chars)
- Resource group name format (alphanumerics, periods, underscores, hyphens, parenthesis)

## Provider-Specific Extensions

Provider-specific modules should:
1. Define provider-specific variables
2. Use base module variables where possible
3. Map base variables to provider resources
4. Add provider-specific validation (e.g., Azure region validation)
5. Extend outputs with provider-specific information
