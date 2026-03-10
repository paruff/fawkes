# ⚠️ DEPRECATED MODULE

> **This module is deprecated and will be removed in a future release.**

## Status

**Deprecated** — do not use for new configurations.

## Canonical Replacement

Use `infra/terraform/modules/azure/resource-group` instead.

```hcl
# Before (deprecated)
module "rg" {
  source   = "./modules/azure-resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
  tags     = { environment = "dev" }
}

# After (canonical)
module "rg" {
  source   = "./modules/azure/resource-group"
  name     = "fawkes-rg"
  location = "eastus2"
  tags     = { environment = "dev" }
}
```

## Migration Guide

See [`REFACTORING.md`](../REFACTORING.md) for the full step-by-step migration guide.

## Deprecation Timeline

| Date | Action |
|------|--------|
| 2025-01-10 | Module marked as deprecated |
| 2025-07-31 | Module scheduled for removal |

## Why Deprecated?

This standalone module duplicates `infra/terraform/modules/azure/resource-group/`, which is
the canonical implementation aligned with the multi-cloud module hierarchy introduced in
Task 4.1.1. The canonical module extends the base module with validation rules and provider-specific
enhancements.

## Support

For questions or migration assistance:
- Review [`../azure/resource-group/README.md`](../azure/resource-group/README.md)
- Consult [`../REFACTORING.md`](../REFACTORING.md)
- Open an issue referencing **FAW-BUG-08**
