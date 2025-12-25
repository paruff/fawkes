# Code Quality Standards

This document defines the comprehensive code quality standards for the Fawkes Internal Product Delivery Platform. All code contributions must adhere to these standards to maintain consistency, security, and maintainability.

## Overview

Fawkes enforces code quality through:

- **Automated Linting** - Pre-commit hooks and CI/CD checks
- **Security Scanning** - Secrets detection and vulnerability scanning
- **Style Enforcement** - Language-specific formatters and linters
- **Quality Gates** - CI/CD pipeline gates that block low-quality code

## Quick Start

```bash
# Install pre-commit hooks
make pre-commit-setup

# Run all linters
make lint

# Run linters on specific files
pre-commit run --files path/to/file
```

## Language-Specific Standards

### Bash

**Linter**: ShellCheck

**Standards**:
- Use `#!/usr/bin/env bash` shebang
- Use double quotes for variables: `"${var}"`
- Check exit codes with `|| exit 1`
- Use `[[ ]]` instead of `[ ]` for conditionals
- Add `set -euo pipefail` at script start for safety

**Configuration**: `.shellcheckrc` (uses defaults)

**Example**:
```bash
#!/usr/bin/env bash
set -euo pipefail

# Good
if [[ "${var}" == "value" ]]; then
    echo "Variable is set"
fi

# Bad
if [ $var == "value" ]; then  # Missing quotes, using [ ]
    echo "Variable is set"
fi
```

**Pre-commit hook**:
```yaml
- repo: https://github.com/shellcheck-py/shellcheck-py
  hooks:
    - id: shellcheck
      args: ['--severity=warning']
```

### Python

**Linters**: Black (formatter), Flake8 (linter)

**Standards**:
- **Line length**: 120 characters (extended from default 88)
- **Import order**: stdlib → third-party → local
- **Type hints**: Required for all public functions
- **Docstrings**: Google style for all public functions/classes
- **Naming**:
  - `snake_case` for functions and variables
  - `PascalCase` for classes
  - `UPPER_CASE` for constants

**Configuration**:
```python
# .pre-commit-config.yaml
- repo: https://github.com/psf/black
  hooks:
    - id: black
      args: []

- repo: https://github.com/pycqa/flake8
  hooks:
    - id: flake8
      args: ['--max-line-length=120', '--extend-ignore=E203,W503']
```

**Example**:
```python
"""Module for user management."""

from typing import Optional


def create_user(username: str, email: str, active: bool = True) -> dict:
    """Create a new user.

    Args:
        username: The username for the new user
        email: User's email address
        active: Whether the user is active (default: True)

    Returns:
        Dictionary containing user details

    Raises:
        ValueError: If username or email is invalid
    """
    if not username or not email:
        raise ValueError("Username and email are required")

    return {
        "username": username,
        "email": email,
        "active": active,
    }
```

**IDE Integration**:
```bash
# VS Code settings.json
{
    "python.linting.enabled": true,
    "python.linting.flake8Enabled": true,
    "python.linting.flake8Args": ["--max-line-length=120"],
    "python.formatting.provider": "black",
    "editor.formatOnSave": true
}
```

### Go

**Linter**: golangci-lint (recommended)

**Standards**:
- **Go version**: 1.21+
- **Package naming**: Short, lowercase, no underscores
- **Error handling**: Always check errors, don't ignore
- **Context**: Pass context.Context as first parameter
- **Comments**: Exported functions/types must have comments

**Configuration**: `.golangci.yml`
```yaml
linters:
  enable:
    - gofmt
    - golint
    - govet
    - errcheck
    - staticcheck
    - gosimple
    - ineffassign
    - unused

linters-settings:
  gofmt:
    simplify: true
```

**Example**:
```go
// Package user provides user management functionality.
package user

import (
    "context"
    "fmt"
)

// User represents a user in the system.
type User struct {
    ID       string
    Username string
    Email    string
}

// CreateUser creates a new user in the database.
func CreateUser(ctx context.Context, username, email string) (*User, error) {
    if username == "" || email == "" {
        return nil, fmt.Errorf("username and email are required")
    }

    user := &User{
        ID:       generateID(),
        Username: username,
        Email:    email,
    }

    return user, nil
}
```

**Pre-commit hook** (add to `.pre-commit-config.yaml`):
```yaml
- repo: https://github.com/golangci/golangci-lint
  rev: v1.55.0
  hooks:
    - id: golangci-lint
```

### YAML

**Linter**: yamllint

**Standards**:
- **Indentation**: 2 spaces
- **Line length**: 120 characters (warning only)
- **Document start**: Not required (`---` optional)
- **Trailing spaces**: Not allowed
- **Empty lines**: Maximum 2 consecutive

**Configuration**: `.yamllint`
```yaml
extends: default

rules:
  line-length:
    max: 120
    level: warning
  document-start: disable
  comments-indentation: disable
  indentation:
    spaces: 2
    indent-sequences: consistent
```

**Example**:
```yaml
# Good
apiVersion: v1
kind: Service
metadata:
  name: my-service
  labels:
    app: my-app
    version: v1.0.0
spec:
  selector:
    app: my-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
```

### JSON

**Linter**: check-json (built-in to pre-commit-hooks)

**Standards**:
- **Indentation**: 2 spaces
- **Trailing commas**: Not allowed
- **Comments**: Not supported (use YAML if comments needed)
- **Keys**: Use camelCase or snake_case consistently

**Pre-commit hook**:
```yaml
- repo: https://github.com/pre-commit/pre-commit-hooks
  hooks:
    - id: check-json
```

**Example**:
```json
{
  "apiVersion": "v1",
  "kind": "ConfigMap",
  "metadata": {
    "name": "app-config",
    "namespace": "default"
  },
  "data": {
    "logLevel": "info",
    "maxConnections": "100"
  }
}
```

### Markdown

**Linter**: markdownlint-cli

**Standards**:
- **Line length**: Disabled (some docs need long lines)
- **Multiple H1s**: Allowed (for documentation)
- **Trailing spaces**: Not allowed
- **Lists**: Consistent markers (- or *)
- **Code blocks**: Language specifier required

**Configuration**: `.markdownlint.json`
```json
{
  "MD013": false,   // Disable line length
  "MD041": false,   // Disable first line heading
  "MD025": false,   // Allow multiple H1s
  "MD047": false,   // Disable single trailing newline
  "MD032": false,   // Disable blank lines around lists
  "MD034": false,   // Disable bare URLs
  "MD040": false    // Disable fenced code language
}
```

**Example**:
```markdown
# Component Architecture

## Overview

The component follows the microservices pattern with the following structure:

- API Gateway
- Service Layer
- Data Layer

### Code Example

```python
def hello_world():
    return "Hello, World!"
```
```

### Terraform

**Linters**: terraform fmt, terraform validate, TFLint, tfsec

**Standards**:
- **Terraform version**: 1.6+ syntax
- **Provider versions**: Always specify in `required_providers`
- **Variables**: All configurable values as variables
- **Outputs**: Important values exported
- **Naming**: snake_case for all resources
- **Comments**: Complex logic documented
- **Security**: tfsec security checks passing

**Configuration**: `.tflint.hcl`
```hcl
plugin "aws" {
  enabled = true
  version = "0.29.0"
}

plugin "azurerm" {
  enabled = true
  version = "0.25.1"
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}
```

**Example**:
```hcl
# Terraform >= 1.6
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

# Variable definition with description
variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

# Resource with proper naming
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Output important values
output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.main.id
}
```

**Pre-commit hooks**:
```yaml
- repo: https://github.com/antonbabenko/pre-commit-terraform
  hooks:
    - id: terraform_fmt
    - id: terraform_validate
    - id: terraform_tflint
    - id: terraform_docs
    - id: terraform_tfsec
```

## Security Standards

### Secrets Detection

**Tools**: Gitleaks, detect-secrets

**Standards**:
- **Zero tolerance** for committed secrets
- **Pre-commit**: Blocks commits with secrets
- **CI/CD**: Pipeline fails on secrets detection
- **Environment variables**: Use for all secrets
- **Vault integration**: For production secrets

**Configuration**: `.gitleaks.toml`
```toml
[allowlist]
description = "Allowlist for false positives"

# Test fixtures
paths = [
    "tests/fixtures/",
    "examples/",
]
```

**Example (BAD)**:
```python
# ❌ NEVER do this
api_key = "sk-1234567890abcdef"  # pragma: allowlist secret
database_url = "postgresql://user:password@localhost/db"  # pragma: allowlist secret
```

**Example (GOOD)**:
```python
# ✅ Use environment variables
import os

api_key = os.environ.get("API_KEY")
database_url = os.environ.get("DATABASE_URL")

if not api_key or not database_url:
    raise ValueError("Required environment variables not set")
```

### Container Security

**Tool**: Trivy

**Standards**:
- **Severity threshold**: CRITICAL and HIGH fail pipeline
- **Base images**: Use official, updated images
- **Updates**: Regular security patching
- **Overrides**: Document in `.trivyignore` with expiration

**Example Dockerfile**:
```dockerfile
# Use specific version tag, not latest
FROM python:3.11-slim-bookworm

# Update packages for security
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Non-root user
RUN useradd -m -u 1000 appuser
USER appuser

WORKDIR /app
COPY --chown=appuser:appuser . .

CMD ["python", "app.py"]
```

### Code Quality (SAST)

**Tool**: SonarQube

**Standards**:
- **Code coverage**: Minimum 80% for new code
- **Bugs**: Zero new bugs
- **Vulnerabilities**: Zero new vulnerabilities
- **Security hotspots**: 100% reviewed
- **Code smells**: Address critical/major issues

## IDE Integration

### VS Code

**Extensions**:
```json
{
  "recommendations": [
    "ms-python.python",
    "ms-python.vscode-pylance",
    "ms-azuretools.vscode-docker",
    "redhat.vscode-yaml",
    "hashicorp.terraform",
    "golang.go",
    "timonwong.shellcheck",
    "davidanson.vscode-markdownlint"
  ]
}
```

**Settings** (`.vscode/settings.json`):
```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  },
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "[yaml]": {
    "editor.defaultFormatter": "redhat.vscode-yaml"
  },
  "[terraform]": {
    "editor.defaultFormatter": "hashicorp.terraform"
  }
}
```

### IntelliJ IDEA / PyCharm

**Plugins**:
- Python Plugin (PyCharm has built-in)
- Terraform and HCL
- Kubernetes
- Bash Support
- Markdown Support

**Settings**:
1. File → Settings → Tools → File Watchers → Add Black
2. File → Settings → Editor → Code Style → Python → Set line length to 120
3. File → Settings → Editor → Inspections → Enable all Python inspections

### Vim/Neovim

**Plugins** (via vim-plug):
```vim
Plug 'dense-analysis/ale'
Plug 'hashivim/vim-terraform'
Plug 'fatih/vim-go'
Plug 'ambv/black'
```

**Configuration**:
```vim
" ALE linters
let g:ale_linters = {
\   'python': ['flake8', 'black'],
\   'bash': ['shellcheck'],
\   'terraform': ['tflint'],
\   'go': ['golangci-lint'],
\}

" Auto-format on save
let g:ale_fixers = {
\   'python': ['black'],
\   'terraform': ['terraform'],
\}
let g:ale_fix_on_save = 1
```

## CI/CD Integration

### Pre-commit CI Workflow

**Location**: `.github/workflows/pre-commit.yml`

**Features**:
- Runs on all pull requests
- Runs on push to main/develop
- Caches dependencies for speed
- Comments on PR with failures
- Uploads artifacts for review

**Workflow**:
```yaml
name: Pre-commit Validation
on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop]

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: actions/setup-python@v6
        with:
          python-version: '3.11'
      - name: Install pre-commit
        run: pip install pre-commit
      - name: Run pre-commit
        run: pre-commit run --all-files
```

### Quality Gates

Quality gates enforce standards at multiple checkpoints:

```
Code Commit → Pre-commit Hooks → PR → CI Linting → Security Scan → Build → Deploy
     ↓              ↓              ↓         ↓              ↓          ↓       ↓
  Local Check   Local Check   GitHub   GitHub Actions   SonarQube  Harbor  ArgoCD
```

**Gate Levels**:
1. **Pre-commit** (Local): Immediate feedback on commit
2. **PR Check** (GitHub): Blocks merge on failure
3. **CI Linting** (GitHub Actions): Comprehensive checks
4. **Security Scan** (SonarQube/Trivy): Vulnerability detection
5. **Quality Gate** (SonarQube): Code quality metrics

## Common Issues and Solutions

### Pre-commit Hook Failures

**Issue**: Hook fails with "command not found"

**Solution**: Install the required tool
```bash
# Terraform tools
brew install terraform tflint terraform-docs tfsec

# Kubernetes tools
brew install kubectl kubeval kustomize helm

# Python tools
pip install black flake8 pre-commit

# Shell tools
brew install shellcheck
```

**Issue**: Hook times out or is very slow

**Solution**: Use specific hooks instead of all
```bash
# Run specific hook
pre-commit run terraform_fmt --all-files

# Skip slow hooks temporarily
SKIP=terraform_tflint,mkdocs-validate pre-commit run --all-files
```

### Linting Failures

**Issue**: Black and Flake8 conflict on line length

**Solution**: Both are configured for 120 chars, but ensure consistency:
```python
# .flake8
[flake8]
max-line-length = 120
extend-ignore = E203, W503
```

**Issue**: Terraform fmt changes files but validation fails

**Solution**: Run in order:
```bash
terraform fmt -recursive
terraform validate
```

**Issue**: ShellCheck reports issues in vendor scripts

**Solution**: Exclude vendor directories:
```bash
# .pre-commit-config.yaml
- id: shellcheck
  exclude: '^vendor/|^third-party/'
```

### Security Scanning Issues

**Issue**: Secrets detected in test fixtures

**Solution**: Add to allowlist:
```toml
# .gitleaks.toml
[allowlist]
paths = [
    "tests/fixtures/",
    "examples/test-data.json",
]
```

**Issue**: Trivy reports false positive CVE

**Solution**: Document and ignore:
```text
# .trivyignore
# PostgreSQL CVE - not applicable, using prepared statements
CVE-2023-12345 exp:2024-12-31
```

## Best Practices

### DO ✅

- **Run pre-commit before pushing**: `pre-commit run --all-files`
- **Install all linting tools locally**: Get immediate feedback
- **Configure IDE integration**: Auto-format on save
- **Address linting issues immediately**: Don't accumulate technical debt
- **Document overrides**: Explain why rules are disabled
- **Update tools regularly**: `pre-commit autoupdate`
- **Review linting in code reviews**: Quality is everyone's responsibility

### DON'T ❌

- **Don't skip hooks**: `--no-verify` should be rare emergency only
- **Don't commit commented-out code**: Remove it (Git history preserves it)
- **Don't disable rules globally**: Use specific exclusions
- **Don't ignore security warnings**: Address or document why safe
- **Don't commit secrets**: Even temporarily, even to feature branches
- **Don't mix formatting changes**: Separate formatting from logic changes

## Getting Help

### Resources

- **Pre-commit Documentation**: [docs/PRE-COMMIT.md](../../PRE-COMMIT.md)
- **Security Quality Gates**: [docs/how-to/security/quality-gates-configuration.md](../security/quality-gates-configuration.md)
- **Contributing Guide**: [docs/contributing.md](../../contributing.md)

### Support Channels

- **GitHub Issues**: [Report issues](https://github.com/paruff/fawkes/issues)
- **GitHub Discussions**: [Ask questions](https://github.com/paruff/fawkes/discussions)
- **Mattermost**: #platform-help channel

### Quick Commands Reference

```bash
# Setup
make pre-commit-setup          # Install pre-commit hooks
make setup-vscode              # Configure VS Code

# Linting
make lint                      # Run all linters
pre-commit run --all-files     # Run all pre-commit hooks
pre-commit run terraform_fmt   # Run specific hook

# Validation
make validate                  # Validate manifests
make terraform-validate        # Validate Terraform
make k8s-validate             # Validate Kubernetes

# Updates
pre-commit autoupdate         # Update hook versions
pre-commit clean              # Clean hook cache
```

## Continuous Improvement

Code quality standards evolve. We review and update:

- **Monthly**: Tool versions and configurations
- **Quarterly**: Standards based on team feedback
- **Per-release**: Major updates to linting tools

**Feedback**: Open an issue or PR to suggest improvements to these standards.

---

**Maintained by**: Fawkes Platform Team
**Last Updated**: December 2024
**Related Issues**: #109 (Code Quality Standards)
