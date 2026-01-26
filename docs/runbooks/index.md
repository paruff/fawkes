# Runbooks

This section contains operational runbooks and procedures for managing the Fawkes platform.

## Overview

Runbooks provide step-by-step operational procedures for common platform tasks, incident response, and validation.

## Platform Operations

### Epic 1: Platform Foundation

- [Epic 1 Platform Operations](epic-1-platform-operations.md) - Core platform operational procedures
- [Epic 1 Architecture Diagrams](epic-1-architecture-diagrams.md) - Platform architecture reference

### Epic 3: Product Discovery

- [Epic 3 Product Discovery Operations](epic-3-product-discovery-operations.md) - Product discovery workflows
- [Epic 3 Architecture Diagrams](epic-3-architecture-diagrams.md) - Discovery architecture reference

## Validation & Acceptance Testing

### AT-E1-001: Azure AKS Cluster

- [AT-E1-001 Validation](at-e1-001-validation.md) - AKS cluster validation procedures
- [Azure AKS Setup](azure-aks-setup.md) - AKS cluster setup guide
- [Azure AKS Validation Checklist](azure-aks-validation-checklist.md) - Complete validation checklist

## Quick Reference

### Common Operations

```bash
# Check platform status
make k8s-status

# View component logs
make k8s-logs COMPONENT=backstage

# Check ArgoCD status
make argocd-status ENVIRONMENT=dev

# Validate resources
make validate-resources

# Deploy locally
make deploy-local COMPONENT=all
```

### Troubleshooting

See the [Troubleshooting Guide](../troubleshooting.md) for common issues and solutions.

## Related Documentation

- [Operations Documentation](../operations/) - Day 2 operations guides
- [How-To Guides](../how-to/index.md) - Step-by-step procedures
- [Troubleshooting](../troubleshooting.md) - Problem resolution
- [Validation](../validation/) - Validation procedures
- [Deployment](../deployment/index.md) - Deployment guides
