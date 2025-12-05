# Golden Path Devfiles

This directory contains standardized Devfile templates for Eclipse Che Cloud
Development Environments (CDEs) in the Fawkes platform.

## Overview

Devfiles define the development environment configuration for Eclipse Che workspaces.
They specify containers, tools, commands, and resource requirements needed for
specific types of projects.

## Available Templates

| Template | Description | Resources | Use Case |
|----------|-------------|-----------|----------|
| `goldenpath-python.yaml` | Python development environment | 2 CPU, 4Gi Memory | Django, FastAPI, Flask, Data Science |
| `goldenpath-ai.yaml` | AI/ML development with GPU | 8 CPU, 16Gi Memory, GPU | TensorFlow, PyTorch, Jupyter |

## Using Devfiles

### From Backstage

1. Navigate to the Service Catalog
2. Click on a service with CDE support
3. Click "Launch CDE" button
4. Select a Devfile template
5. Wait for workspace to start

### From Che Dashboard

1. Access `https://che.fawkes.idp`
2. Click "Create Workspace"
3. Select template from "Custom Workspace"
4. Paste Devfile URL or content
5. Click "Create & Open"

### Direct URL

Launch a workspace directly with a Devfile URL:

```text
https://che.fawkes.idp/#https://github.com/paruff/fawkes/blob/main/platform/devfiles/goldenpath-python.yaml
```

## Devfile Structure

```yaml
schemaVersion: 2.2.2
metadata:
  name: my-devfile
  displayName: My Development Environment
  description: Description of the environment
  version: 1.0.0
  tags: [Python, FastAPI]

# Project templates
starterProjects:
  - name: template-name
    git:
      remotes:
        origin: https://github.com/org/repo

# Container definitions
components:
  - name: dev-container
    container:
      image: quay.io/devfile/universal-developer-image:latest
      memoryLimit: 4Gi
      cpuLimit: "2"
      endpoints:
        - name: app
          targetPort: 8000
          exposure: public

# Development commands
commands:
  - id: build
    exec:
      label: "Build"
      component: dev-container
      commandLine: make build
      group:
        kind: build
        isDefault: true
```

## Creating Custom Devfiles

### Step 1: Start from Template

Copy an existing Golden Path Devfile as a starting point:

```bash
cp goldenpath-python.yaml my-project-devfile.yaml
```

### Step 2: Customize Metadata

Update the metadata section with your project details:

```yaml
metadata:
  name: my-project
  displayName: My Project Development
  description: Custom environment for my project
  version: 1.0.0
  tags: [Python, Django, PostgreSQL]
```

### Step 3: Add Starter Projects

Define template repositories for new projects:

```yaml
starterProjects:
  - name: my-template
    description: My project template
    git:
      remotes:
        origin: https://github.com/myorg/my-template
```

### Step 4: Configure Components

Define containers with appropriate resources:

```yaml
components:
  - name: python
    container:
      image: python:3.11-slim
      memoryLimit: 4Gi
      cpuLimit: "2"
      env:
        - name: MY_VAR
          value: "my-value"
      endpoints:
        - name: app
          targetPort: 8000
```

### Step 5: Add Commands

Define common development tasks:

```yaml
commands:
  - id: install
    exec:
      label: "Install Dependencies"
      component: python
      commandLine: pip install -r requirements.txt
      workingDir: ${PROJECT_SOURCE}
      group:
        kind: build
        isDefault: true
```

### Step 6: Configure Events

Set up lifecycle hooks:

```yaml
events:
  postStart:
    - install
```

## Resource Guidelines

| Workload Type | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------------|-------------|-----------|----------------|--------------|
| Light (editing) | 500m | 2 | 1Gi | 4Gi |
| Medium (builds) | 1 | 4 | 2Gi | 8Gi |
| Heavy (AI/ML) | 2 | 8 | 8Gi | 16Gi |

## Vault Integration

To inject secrets into your workspace, add pod-overrides:

```yaml
attributes:
  pod-overrides:
    metadata:
      annotations:
        vault.hashicorp.com/agent-inject: "true"
        vault.hashicorp.com/role: "che-workspace"
        vault.hashicorp.com/agent-inject-secret-db: "secret/data/dev/database"
```

Secrets are available at `/vault/secrets/` in the container.

## GPU Support

For AI/ML workloads requiring GPU, add node selection:

```yaml
attributes:
  pod-overrides:
    spec:
      nodeSelector:
        gpu-enabled: "true"
      tolerations:
        - key: "nvidia.com/gpu"
          operator: "Exists"
          effect: "NoSchedule"
```

## References

- [Devfile Specification](https://devfile.io/docs/2.2.2/devfile-schema)
- [Eclipse Che Devfile Documentation](https://www.eclipse.org/che/docs/stable/end-user-guide/devfile-introduction/)
- [Universal Developer Image](https://github.com/devfile/developer-images)
- [ADR-021: Eclipse Che CDE Strategy](../../docs/adr/ADR-021%20eclipse-che-cde-strategy.md)
