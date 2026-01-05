# Base Resource Group Module

This is a base module that defines common variables and validation patterns for resource groups across all cloud providers (Azure Resource Group, AWS Tags, GCP Projects, Civo Organization).

**Note**: This module is not intended to be instantiated directly. It serves as a reference for common variable definitions.

## Purpose

This module provides:
- Common variable definitions for resource grouping with validation rules
- Standardized naming conventions (snake_case)
- Reusable patterns for provider-specific implementations

## Usage

Provider-specific modules should reference these variable definitions. For actual deployments, use:

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

## Validation Rules

All variables include validation rules to catch configuration errors early:

- Resource group name length (1-90 chars)
- Resource group name format (alphanumerics, periods, underscores, hyphens, parenthesis)

## Provider-Specific Extensions

Provider-specific modules should:
1. Reference these variable definitions where applicable
2. Use consistent naming from this base
3. Add provider-specific variables as needed
4. Add provider-specific validation (e.g., Azure region validation)
5. Define their own outputs based on provider resources
