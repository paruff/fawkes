# Fawkes Coding Standards

> Comprehensive code quality standards for the Fawkes Internal Product Delivery Platform

## Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Developer Setup](#developer-setup)
- [Language-Specific Standards](#language-specific-standards)
  - [Python](#python)
  - [Go](#go)
  - [Bash/Shell](#bashshell)
  - [YAML](#yaml)
  - [JSON](#json)
  - [Markdown](#markdown)
  - [Terraform](#terraform)
  - [TypeScript/JavaScript](#typescriptjavascript)
- [IDE Integration](#ide-integration)
- [Pre-commit Hooks](#pre-commit-hooks)
- [CI/CD Quality Gates](#cicd-quality-gates)
- [Security Standards](#security-standards)
- [Best Practices](#best-practices)
- [FAQ](#faq)

---

## Overview

Fawkes maintains high code quality standards through:

- ✅ **Automated Linting** - Pre-commit hooks and CI/CD checks
- ✅ **Security Scanning** - Secrets detection and vulnerability scanning
- ✅ **Style Enforcement** - Language-specific formatters and linters
- ✅ **Quality Gates** - CI/CD pipeline gates that block low-quality code
- ✅ **Test Coverage** - Minimum 60% test coverage requirement

### Why Code Quality Matters

- **Consistency**: All developers follow the same standards
- **Security**: Early detection of vulnerabilities and secrets
- **Maintainability**: Code is easier to read and modify
- **Productivity**: Automated tools catch issues before review
- **Reliability**: Fewer bugs make it to production

---

## Quick Start

Get started with code quality tools in 3 steps:

```bash
# 1. Install pre-commit hooks
make pre-commit-setup

# 2. Run all linters
make lint

# 3. Format on save (optional, recommended)
# See IDE Integration section below
```

Pre-commit hooks will automatically run on every `git commit` to validate your code.

---

## Developer Setup

### Prerequisites

Install these tools for the best development experience:

```bash
# Python tools
pip install black flake8 mypy pylint pytest pytest-cov

# Shell tools
brew install shellcheck shfmt  # macOS
apt-get install shellcheck     # Linux

# Go tools
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Node/TypeScript tools (if working with design-system)
npm install -g prettier eslint typescript

# Kubernetes/Infrastructure tools
brew install yamllint terraform tflint tfsec  # macOS
```

### Initial Setup

1. **Clone the repository**:

   ```bash
   git clone https://github.com/paruff/fawkes.git
   cd fawkes
   ```

2. **Install pre-commit hooks**:

   ```bash
   make pre-commit-setup
   ```

3. **Configure your IDE** (see [IDE Integration](#ide-integration))

4. **Verify setup**:

   ```bash
   make lint
   ```

### Daily Workflow

```bash
# 1. Create feature branch
git checkout -b feature/your-feature

# 2. Make changes
# ... edit files ...

# 3. Lint your changes (automatic on commit)
git add .
git commit -m "feat: your change description"
# Pre-commit hooks run automatically

# 4. Push your changes
git push origin feature/your-feature
```

---

## Language-Specific Standards

### Python

**Tools**: Black (formatter), Flake8 (linter), MyPy (type checker), Pylint (analyzer)

#### Standards

- **Line length**: 120 characters
- **Indentation**: 4 spaces
- **Type hints**: Required for all public functions
- **Docstrings**: Google style for all public functions/classes
- **Naming**:
  - `snake_case` for functions and variables
  - `PascalCase` for classes
  - `UPPER_CASE` for constants

#### Configuration Files

- **Black**: `pyproject.toml`
- **Flake8**: `pyproject.toml`
- **MyPy**: `pyproject.toml`

#### ✅ Good Examples

```python
"""User management module for Fawkes platform."""

from typing import Optional, List
import logging

logger = logging.getLogger(__name__)

# Constants
MAX_USERNAME_LENGTH: int = 50
DEFAULT_ROLE: str = "developer"


class User:
    """Represents a platform user.

    Attributes:
        username: The user's unique username.
        email: The user's email address.
        role: The user's role in the platform.
    """

    def __init__(self, username: str, email: str, role: str = DEFAULT_ROLE):
        self.username = username
        self.email = email
        self.role = role


def create_user(username: str, email: str, role: Optional[str] = None) -> User:
    """Create a new platform user.

    Args:
        username: The unique username for the user.
        email: The user's email address.
        role: Optional role assignment. Defaults to DEFAULT_ROLE.

    Returns:
        A newly created User instance.

    Raises:
        ValueError: If username or email is empty.
    """
    if not username or not email:
        raise ValueError("Username and email are required")

    user_role = role or DEFAULT_ROLE
    logger.info("Creating user: %s with role: %s", username, user_role)

    return User(username=username, email=email, role=user_role)


def get_active_users(min_age_days: int = 30) -> List[User]:
    """Get all active users from the last N days.

    Args:
        min_age_days: Minimum number of days since last activity.

    Returns:
        List of active User objects.
    """
    # Implementation here
    return []
```

#### ❌ Bad Examples

```python
# Bad: No docstrings, no type hints, poor naming
def CreateUser(u, e, r=None):
    if not u or not e:
        raise ValueError("required")
    return User(u, e, r or "developer")


# Bad: Line too long, no type hints
def get_all_platform_users_with_their_associated_metadata_and_permissions_from_database(database_connection):
    return database_connection.query("SELECT * FROM users")


# Bad: Inconsistent naming
class user_Manager:  # Should be UserManager
    def Get_Users(self):  # Should be get_users
        pass


# Bad: No error handling, bare except
def risky_operation():
    try:
        do_something()
    except:  # Never use bare except
        pass
```

#### Common Issues

| Issue                | Solution                              |
| -------------------- | ------------------------------------- |
| Line too long        | Break into multiple lines             |
| Missing type hints   | Add type annotations                  |
| No docstring         | Add Google-style docstring            |
| Inconsistent naming  | Use snake_case for functions/vars     |
| Bare except          | Catch specific exceptions             |
| Mutable defaults     | Use `None` and assign in function     |

---

### Go

**Tools**: golangci-lint (includes gofmt, govet, staticcheck, gosec)

#### Standards

- **Indentation**: Tabs (Go standard)
- **Line length**: No strict limit, but prefer 80-100 characters
- **Naming**:
  - `camelCase` for private functions/vars
  - `PascalCase` for exported functions/vars
  - Short, descriptive names
- **Comments**: Required for all exported functions, types, and packages
- **Error handling**: Always check errors, never ignore

#### Configuration File

- `.golangci.yml`

#### ✅ Good Examples

```go
package users

import (
    "context"
    "fmt"
    "time"
)

// User represents a platform user with authentication details.
type User struct {
    ID        string
    Username  string
    Email     string
    CreatedAt time.Time
}

// CreateUser creates a new user in the system.
// Returns an error if username or email is empty.
func CreateUser(ctx context.Context, username, email string) (*User, error) {
    if username == "" || email == "" {
        return nil, fmt.Errorf("username and email are required")
    }

    user := &User{
        ID:        generateID(),
        Username:  username,
        Email:     email,
        CreatedAt: time.Now(),
    }

    if err := validateUser(user); err != nil {
        return nil, fmt.Errorf("user validation failed: %w", err)
    }

    return user, nil
}

// GetActiveUsers retrieves all users active within the specified duration.
func GetActiveUsers(ctx context.Context, since time.Duration) ([]*User, error) {
    cutoff := time.Now().Add(-since)

    users, err := fetchUsersActiveSince(ctx, cutoff)
    if err != nil {
        return nil, fmt.Errorf("failed to fetch active users: %w", err)
    }

    return users, nil
}

func validateUser(u *User) error {
    if len(u.Username) < 3 {
        return fmt.Errorf("username too short")
    }
    return nil
}

func generateID() string {
    // Implementation
    return "user-123"
}

func fetchUsersActiveSince(ctx context.Context, since time.Time) ([]*User, error) {
    // Implementation
    return nil, nil
}
```

#### ❌ Bad Examples

```go
package users

// Bad: No package comment

// Bad: Unexported type with exported-style name
type user struct {  // Should be User if exported
    id string      // Inconsistent casing
    Username string
}

// Bad: No comment for exported function
func CreateUser(username, email string) *User {
    // Bad: No error handling, returns nil on failure
    if username == "" {
        return nil
    }

    // Bad: Ignoring errors
    user := &User{}
    _ = validateUser(user)  // Don't ignore errors!

    return user
}

// Bad: Generic error message, no context
func GetUser(id string) (*User, error) {
    u, err := fetchUser(id)
    if err != nil {
        return nil, err  // Should wrap error with context
    }
    return u, nil
}

// Bad: Too many return parameters, unclear
func ProcessUser(id string) (string, string, bool, error, int) {
    // Use a struct instead
    return "", "", false, nil, 0
}
```

#### Common Issues

| Issue                  | Solution                          |
| ---------------------- | --------------------------------- |
| Unused imports         | Run goimports                     |
| Unchecked errors       | Always check `err != nil`         |
| No comments on exports | Add comment starting with name    |
| Ignoring context       | Pass `context.Context` as first param |
| Generic errors         | Wrap errors with `fmt.Errorf`     |

---

### Bash/Shell

**Tools**: ShellCheck (linter), shfmt (formatter)

#### Standards

- **Shebang**: `#!/usr/bin/env bash`
- **Indentation**: 2 spaces
- **Case indentation**: Indent case statements
- **Safety**: Always use `set -euo pipefail` at start
- **Quoting**: Always quote variables: `"${var}"`
- **Conditionals**: Use `[[ ]]` instead of `[ ]`

#### Configuration

- shfmt args: `-i 2 -ci -bn -sr`

#### ✅ Good Examples

```bash
#!/usr/bin/env bash
set -euo pipefail

# Script: create-user.sh
# Description: Create a new platform user
# Usage: ./create-user.sh <username> <email>

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly LOG_FILE="${SCRIPT_DIR}/user-creation.log"

# Constants
readonly MAX_USERNAME_LENGTH=50
readonly DEFAULT_ROLE="developer"

# Functions
log_info() {
  local message="${1}"
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - ${message}" | tee -a "${LOG_FILE}"
}

log_error() {
  local message="${1}"
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - ${message}" >&2 | tee -a "${LOG_FILE}"
}

validate_username() {
  local username="${1}"

  if [[ -z "${username}" ]]; then
    log_error "Username cannot be empty"
    return 1
  fi

  if [[ ${#username} -gt ${MAX_USERNAME_LENGTH} ]]; then
    log_error "Username exceeds maximum length of ${MAX_USERNAME_LENGTH}"
    return 1
  fi

  return 0
}

create_user() {
  local username="${1}"
  local email="${2}"
  local role="${3:-${DEFAULT_ROLE}}"

  if ! validate_username "${username}"; then
    return 1
  fi

  log_info "Creating user: ${username}"

  # Create user (example)
  if kubectl create user "${username}" --email "${email}" --role "${role}"; then
    log_info "Successfully created user: ${username}"
    return 0
  else
    log_error "Failed to create user: ${username}"
    return 1
  fi
}

# Main
main() {
  if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <username> <email> [role]"
    exit 1
  fi

  local username="${1}"
  local email="${2}"
  local role="${3:-${DEFAULT_ROLE}}"

  if create_user "${username}" "${email}" "${role}"; then
    exit 0
  else
    exit 1
  fi
}

# Run main only if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
```

#### ❌ Bad Examples

```bash
#!/bin/bash
# Bad: Not using /usr/bin/env, no set -euo pipefail

# Bad: Not quoting variables, using [ ] instead of [[ ]]
if [ $username == "admin" ]; then
    echo "Admin user"
fi

# Bad: Not checking exit codes
kubectl create user $username
rm -rf /tmp/data

# Bad: Global variables without readonly
SCRIPT_DIR="$(pwd)"

# Bad: No error handling
function create_user() {
    # Could fail but no error handling
    kubectl create user $1 --email $2
}

# Bad: Using backticks instead of $()
files=`ls *.txt`

# Bad: Not local variables in functions
process_data() {
    result="some value"  # Should be local
}

# Bad: Complex one-liner
cat file.txt | grep "pattern" | awk '{print $1}' | sort | uniq | wc -l
# Better: Use intermediate variables for clarity
```

#### Error Handling

All Bash scripts MUST follow comprehensive error handling standards. See [Error Handling Standards](docs/standards/ERROR_HANDLING.md) for complete details.

**Core Requirements**:

1. **Strict Error Mode**: Start every script with `set -euo pipefail`
2. **Error Handling Library**: Source `/scripts/lib/error_handling.sh` for utilities
3. **Meaningful Error Messages**: Use `error_exit "message" exit_code`
4. **Prerequisites Check**: Use `require_command`, `require_var`, `require_file`
5. **Cleanup Functions**: Register cleanup with `register_cleanup_function`
6. **Rollback Functions**: Register rollback with `register_rollback_function`

**Standard Exit Codes**:
- `0` - Success
- `1` - General error  
- `2` - Missing prerequisite
- `3` - Validation failed
- `4` - Network error
- `5` - Timeout
- `6` - User cancelled
- `7` - Configuration error
- `8` - Permission error

**Example with Error Handling**:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source error handling library
source "${SCRIPT_DIR}/lib/error_handling.sh"

# Check prerequisites
require_command "kubectl" "kubectl is required but not installed"
require_var "NAMESPACE" "NAMESPACE environment variable must be set"

# Register cleanup
cleanup() {
  log_debug "Cleaning up temporary files..."
  rm -f /tmp/deploy-*.tmp
}
register_cleanup_function cleanup

# Register rollback on error
rollback() {
  log_warn "Rolling back deployment..."
  kubectl rollout undo deployment/myapp -n "$NAMESPACE" || true
}
register_rollback_function rollback

# Main logic with proper error handling
main() {
  show_section "Deploying Application"
  
  if ! kubectl apply -f app.yaml -n "$NAMESPACE"; then
    error_exit "Failed to deploy application" "$EXIT_GENERAL_ERROR"
  fi
  
  log_success "Application deployed successfully!"
}

main "$@"
```

#### Common Issues

| Issue              | Solution                        |
| ------------------ | ------------------------------- |
| Unquoted variables | Always use `"${var}"`           |
| No error handling  | Use `set -euo pipefail`         |
| Using `[ ]`        | Use `[[ ]]` for conditionals    |
| Global variables   | Use `readonly` or `local`       |
| No function docs   | Add comments above functions    |
| Backticks          | Use `$()` instead of backticks  |
| No cleanup         | Register cleanup functions      |
| Generic errors     | Use specific exit codes         |

---

### YAML

**Tools**: yamllint (linter), Prettier (formatter)

#### Standards

- **Indentation**: 2 spaces
- **Line length**: 120 characters (warning only)
- **Document start**: Optional (`---`)
- **Trailing spaces**: Not allowed
- **Empty lines**: Maximum 2 consecutive
- **Keys**: Use kebab-case for consistency

#### Configuration Files

- **Linter**: `.yamllint`
- **Formatter**: `.prettierrc`

#### ✅ Good Examples

```yaml
# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fawkes-backend
  namespace: fawkes
  labels:
    app: fawkes-backend
    version: v1.0.0
    managed-by: argocd
  annotations:
    description: "Fawkes backend service deployment"
spec:
  replicas: 3
  selector:
    matchLabels:
      app: fawkes-backend
  template:
    metadata:
      labels:
        app: fawkes-backend
        version: v1.0.0
    spec:
      containers:
        - name: backend
          image: fawkes/backend:v1.0.0
          ports:
            - containerPort: 8080
              name: http
              protocol: TCP
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url
          resources:
            requests:
              memory: "256Mi"
              cpu: "250m"
            limits:
              memory: "512Mi"
              cpu: "500m"
          livenessProbe:
            httpGet:
              path: /health
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
```

#### ❌ Bad Examples

```yaml
# Bad: Inconsistent indentation
apiVersion: apps/v1
kind: Deployment
metadata:
   name: fawkes-backend  # 3 spaces instead of 2
    namespace: fawkes    # 4 spaces
spec:
  replicas: 3
    selector:            # Wrong indentation
  matchLabels:           # Should be nested under selector

# Bad: Trailing whitespace
metadata:
  name: fawkes-backend  
  labels:
    app: backend       

# Bad: Missing required fields
apiVersion: apps/v1
kind: Deployment
# Missing metadata!
spec:
  replicas: 3

# Bad: Inconsistent naming conventions
metadata:
  name: Fawkes_Backend  # Use kebab-case, not PascalCase or snake_case
  labels:
    AppName: backend    # Should be lowercase
```

#### Common Issues

| Issue                  | Solution                       |
| ---------------------- | ------------------------------ |
| Inconsistent indent    | Use 2 spaces everywhere        |
| Trailing whitespace    | Enable editor trim on save     |
| Mixed naming styles    | Use kebab-case consistently    |
| Missing required fields| Validate with kubeval/kubeconform |
| Too long lines         | Break into multiple lines      |

---

### JSON

**Tools**: Prettier (formatter), check-json (validator)

#### Standards

- **Indentation**: 2 spaces
- **Trailing commas**: Not allowed (JSON spec)
- **Comments**: Not supported (use YAML if needed)
- **Keys**: Use camelCase or snake_case consistently
- **Quotes**: Always use double quotes

#### Configuration File

- `.prettierrc`

#### ✅ Good Examples

```json
{
  "name": "fawkes-backend",
  "version": "1.0.0",
  "description": "Fawkes Internal Product Delivery Platform",
  "repository": {
    "type": "git",
    "url": "https://github.com/paruff/fawkes.git"
  },
  "author": "Fawkes Team",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.0",
    "dotenv": "^16.0.0"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "eslint": "^8.0.0"
  },
  "scripts": {
    "start": "node server.js",
    "test": "jest",
    "lint": "eslint ."
  },
  "engines": {
    "node": ">=18.0.0"
  }
}
```

#### ❌ Bad Examples

```json
{
  "name": "fawkes-backend",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.0",
  },  // Bad: Trailing comma
  // Bad: Comments not allowed in JSON
  "devDependencies": {
    'jest': '^29.0.0'  // Bad: Single quotes
  }
}
```

#### Common Issues

| Issue            | Solution                          |
| ---------------- | --------------------------------- |
| Trailing commas  | Remove last comma in objects/arrays |
| Comments         | Use YAML if comments needed       |
| Single quotes    | Always use double quotes          |
| Invalid syntax   | Run through JSON validator        |

---

### Markdown

**Tools**: markdownlint-cli (linter), Prettier (formatter)

#### Standards

- **Line length**: Disabled (some docs need long lines)
- **Headings**: One H1 per document (title)
- **Lists**: Consistent markers (`-` or `*`)
- **Code blocks**: Always specify language
- **Links**: Use reference-style for repeated links
- **Trailing spaces**: Not allowed (except 2 for line breaks)

#### Configuration Files

- **Linter**: `.markdownlint.json`
- **Formatter**: `.prettierrc`

#### ✅ Good Examples

````markdown
# Fawkes Platform Guide

> Brief description of the guide

## Overview

This guide covers the essentials of the Fawkes platform.

## Prerequisites

Before starting, ensure you have:

- Kubernetes cluster (1.28+)
- kubectl CLI installed
- Basic understanding of containers

## Quick Start

Follow these steps:

1. **Clone repository**

   ```bash
   git clone https://github.com/paruff/fawkes.git
   cd fawkes
   ```

2. **Install dependencies**

   ```bash
   make pre-commit-setup
   ```

3. **Deploy platform**

   ```bash
   make deploy-local
   ```

## Code Examples

Here's a Python example:

```python
def hello_world():
    """Print hello world."""
    print("Hello, Fawkes!")
```

And a Bash example:

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Hello, Fawkes!"
```

## Tips

- ✅ Always use code blocks with language specification
- ✅ Keep lines under 120 characters when possible
- ✅ Use tables for structured data

## Resources

- [Official Documentation][docs]
- [GitHub Repository][repo]

[docs]: https://fawkes.dev/docs
[repo]: https://github.com/paruff/fawkes
````

#### ❌ Bad Examples

````markdown
# Bad Document

No description provided

## Section

Code without language:

```
kubectl get pods
```

Long line: This is a very long line that goes on and on and on and should probably be broken into multiple lines for better readability but isn't because someone didn't follow the style guide properly.

- List item 1
* List item 2    # Bad: Inconsistent list markers
- List item 3

## Another Section

[link](http://very-long-url-that-is-repeated-multiple-times.com/path/to/resource)
[another link](http://very-long-url-that-is-repeated-multiple-times.com/path/to/resource)
# Should use reference-style links instead
````

#### Common Issues

| Issue                 | Solution                                |
| --------------------- | --------------------------------------- |
| No language in code   | Add language: ` ```python `             |
| Inconsistent lists    | Use same marker throughout              |
| Multiple H1 headings  | Use only one H1 (title)                 |
| Broken links          | Test all links                          |
| Mixed line endings    | Use LF (Unix-style)                     |

---

### Terraform

**Tools**: terraform fmt (formatter), TFLint (linter), tfsec (security scanner)

#### Standards

- **Indentation**: 2 spaces
- **Naming**: Use snake_case for all identifiers
- **Variables**: Always include description and type
- **Outputs**: Document all outputs
- **Modules**: Version pinning required
- **State**: Remote state only (no local state)

#### Configuration Files

- `.tflint.hcl`
- `terraform.tfvars.example`

#### ✅ Good Examples

```hcl
# versions.tf
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate"
    container_name       = "state"
    key                  = "fawkes.tfstate"
  }
}

# variables.tf
variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
  default     = "fawkes-aks"
}

variable "node_count" {
  description = "Initial number of nodes in the default node pool"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 10
    error_message = "Node count must be between 1 and 10."
  }
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    managed_by = "terraform"
    project    = "fawkes"
  }
}

# main.tf
resource "azurerm_resource_group" "main" {
  name     = "fawkes-${var.environment}-rg"
  location = var.location
  tags     = var.tags
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "${var.cluster_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "${var.cluster_name}-${var.environment}"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags
}

# outputs.tf
output "cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_endpoint" {
  description = "The endpoint for the AKS cluster API server"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.main.name
}
```

#### ❌ Bad Examples

```hcl
# Bad: No version pinning
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      # No version specified!
    }
  }
}

# Bad: No description or type
variable "cluster_name" {}

# Bad: Hardcoded values
resource "azurerm_kubernetes_cluster" "main" {
  name                = "my-cluster"  # Should use variables
  location            = "eastus"      # Should use variables
  resource_group_name = "my-rg"       # Should reference resource

  default_node_pool {
    name       = "default"
    node_count = 3  # Should be variable
    vm_size    = "Standard_D2_v2"
  }
}

# Bad: No outputs defined

# Bad: Inconsistent naming
resource "azurerm_resource_group" "MyResourceGroup" {  # Use snake_case
  name = "Fawkes-RG"
}
```

#### Common Issues

| Issue                | Solution                               |
| -------------------- | -------------------------------------- |
| No version pinning   | Add required_providers with versions   |
| Hardcoded values     | Use variables                          |
| Missing descriptions | Add description to all variables       |
| No validation        | Add validation blocks to variables     |
| No outputs           | Document important values as outputs   |
| Security issues      | Run tfsec to find vulnerabilities      |

---

### TypeScript/JavaScript

**Tools**: ESLint (linter), Prettier (formatter), TypeScript compiler

#### Standards

- **Indentation**: 2 spaces
- **Semicolons**: Required
- **Quotes**: Double quotes
- **Type annotations**: Required for TypeScript
- **Arrow functions**: Prefer over function keyword
- **Async/await**: Prefer over raw promises

#### Configuration Files

- `.eslintrc.json`
- `.prettierrc`
- `tsconfig.json`

#### ✅ Good Examples

```typescript
// user.types.ts
export interface User {
  id: string;
  username: string;
  email: string;
  createdAt: Date;
}

export interface CreateUserRequest {
  username: string;
  email: string;
  role?: string;
}

export interface UserService {
  createUser(request: CreateUserRequest): Promise<User>;
  getUser(id: string): Promise<User | null>;
  listUsers(): Promise<User[]>;
}

// user.service.ts
import { User, CreateUserRequest, UserService } from "./user.types";

const DEFAULT_ROLE = "developer";

export class UserServiceImpl implements UserService {
  /**
   * Creates a new user in the system.
   * @param request - User creation request
   * @returns The created user
   * @throws Error if username or email is invalid
   */
  async createUser(request: CreateUserRequest): Promise<User> {
    const { username, email, role = DEFAULT_ROLE } = request;

    if (!username || !email) {
      throw new Error("Username and email are required");
    }

    if (!this.isValidEmail(email)) {
      throw new Error("Invalid email format");
    }

    const user: User = {
      id: this.generateId(),
      username,
      email,
      createdAt: new Date(),
    };

    await this.saveUser(user);
    return user;
  }

  /**
   * Retrieves a user by ID.
   * @param id - User ID
   * @returns The user or null if not found
   */
  async getUser(id: string): Promise<User | null> {
    if (!id) {
      throw new Error("User ID is required");
    }

    const user = await this.fetchUser(id);
    return user;
  }

  /**
   * Lists all users in the system.
   * @returns Array of users
   */
  async listUsers(): Promise<User[]> {
    const users = await this.fetchAllUsers();
    return users;
  }

  private isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  private generateId(): string {
    return `user-${Date.now()}`;
  }

  private async saveUser(user: User): Promise<void> {
    // Implementation
  }

  private async fetchUser(id: string): Promise<User | null> {
    // Implementation
    return null;
  }

  private async fetchAllUsers(): Promise<User[]> {
    // Implementation
    return [];
  }
}
```

#### ❌ Bad Examples

```typescript
// Bad: No type annotations
export class UserService {
  async createUser(request) {  // Missing types
    let { username, email } = request;

    if (!username || !email) {
      throw new Error("required");  // Vague error
    }

    // Bad: Using var instead of const/let
    var user = {
      id: generateId(),
      username: username,  // Redundant property shorthand
      email: email,
    };

    return user;
  }

  // Bad: Callback instead of async/await
  getUser(id, callback) {
    fetchUser(id, function(err, user) {
      if (err) callback(err);
      callback(null, user);
    });
  }

  // Bad: No error handling
  async deleteUser(id) {
    await db.users.delete(id);  // Could fail
  }
}

// Bad: Using any type
function processData(data: any): any {
  return data;
}

// Bad: Inconsistent naming
class user_service {  // Should be UserService
  CreateUser() {}     // Should be createUser
}
```

#### Common Issues

| Issue               | Solution                           |
| ------------------- | ---------------------------------- |
| Missing types       | Add TypeScript type annotations    |
| Using `any`         | Use specific types                 |
| Callbacks           | Use async/await                    |
| No error handling   | Add try/catch blocks               |
| Inconsistent naming | Use camelCase for vars/functions   |
| Missing semicolons  | Enable ESLint rule                 |

---

## IDE Integration

### VS Code

**Recommended Extensions**:

- [ESLint](https://marketplace.visualstudio.com/items?itemName=dbaeumer.vscode-eslint)
- [Prettier](https://marketplace.visualstudio.com/items?itemName=esbenp.prettier-vscode)
- [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python)
- [Go](https://marketplace.visualstudio.com/items?itemName=golang.go)
- [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
- [YAML](https://marketplace.visualstudio.com/items?itemName=redhat.vscode-yaml)

**Configuration** (`.vscode/settings.json`):

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  },
  "python.formatting.provider": "black",
  "python.linting.enabled": true,
  "python.linting.flake8Enabled": true,
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  },
  "[go]": {
    "editor.defaultFormatter": "golang.go"
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[yaml]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[markdown]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  }
}
```

### IntelliJ IDEA / PyCharm

1. **Enable Black formatter**:
   - Settings → Tools → Black → Enable Black
   - Check "Run on save"

2. **Enable ESLint**:
   - Settings → Languages & Frameworks → JavaScript → Code Quality Tools → ESLint
   - Select "Automatic ESLint configuration"

3. **Enable Prettier**:
   - Settings → Languages & Frameworks → JavaScript → Prettier
   - Check "On save"

### Vim / Neovim

Add to `.vimrc` or `init.vim`:

```vim
" ALE (Asynchronous Lint Engine)
let g:ale_linters = {
\   'python': ['flake8', 'pylint'],
\   'go': ['golangci-lint'],
\   'sh': ['shellcheck'],
\   'yaml': ['yamllint'],
\}

let g:ale_fixers = {
\   'python': ['black'],
\   'go': ['gofmt'],
\   'sh': ['shfmt'],
\   'yaml': ['prettier'],
\   'json': ['prettier'],
\   'markdown': ['prettier'],
\}

" Fix on save
let g:ale_fix_on_save = 1
```

---

## Pre-commit Hooks

Pre-commit hooks automatically run linters and formatters before each commit.

### Installation

```bash
# Install pre-commit hooks (one time)
make pre-commit-setup

# Or manually
pip install pre-commit
pre-commit install
```

### Usage

```bash
# Pre-commit runs automatically on git commit
git commit -m "feat: your changes"

# Run manually on all files
pre-commit run --all-files

# Run on specific files
pre-commit run --files path/to/file.py

# Skip pre-commit (not recommended)
git commit -m "fix: emergency" --no-verify
```

### Configuration

Pre-commit hooks are defined in `.pre-commit-config.yaml`:

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
        name: Format Python code with Black

  - repo: https://github.com/pycqa/flake8
    rev: 7.0.0
    hooks:
      - id: flake8
        name: Lint Python with Flake8

  # ... more hooks
```

### Updating Hooks

```bash
# Update all hooks to latest versions
pre-commit autoupdate

# Test after update
pre-commit run --all-files
```

---

## CI/CD Quality Gates

### GitHub Actions Workflows

The project uses GitHub Actions to enforce code quality in CI/CD:

1. **Pre-commit Workflow** (`.github/workflows/pre-commit.yml`)
   - Runs all pre-commit hooks
   - Validates on all PRs and pushes

2. **Code Quality Workflow** (`.github/workflows/code-quality.yml`)
   - Python linting (Black, Flake8, MyPy, Pylint)
   - Test coverage (60% minimum)
   - Go linting (golangci-lint)
   - Shell linting (ShellCheck)
   - TypeScript/JavaScript linting (ESLint)

3. **Security Workflow** (`.github/workflows/security-and-terraform.yml`)
   - Secrets scanning (Gitleaks)
   - Container scanning (Trivy)
   - Infrastructure scanning (tfsec)

### Quality Gates

All PRs must pass these checks:

- ✅ All pre-commit hooks pass
- ✅ All linters pass (zero errors)
- ✅ Test coverage ≥ 60%
- ✅ No secrets detected
- ✅ No HIGH/CRITICAL vulnerabilities
- ✅ All tests pass

### Local Testing

Test your changes locally before pushing:

```bash
# Run all linters
make lint

# Run tests with coverage
pytest --cov=. --cov-report=term-missing

# Run specific linter
flake8 .
```

---

## Security Standards

### Secrets Management

- ❌ **NEVER** commit secrets to Git
- ✅ Use environment variables
- ✅ Use Azure Key Vault or HashiCorp Vault
- ✅ Use External Secrets Operator in K8s

### Scanning

Pre-commit hooks automatically scan for:

- API keys
- Passwords
- Private keys
- AWS credentials
- Database connection strings

### Container Security

- Use official base images
- Scan images with Trivy
- No root containers (use `USER` directive)
- Minimal base images (Alpine, Distroless)

### Infrastructure Security

- Run `tfsec` on all Terraform code
- Enable Azure Security Center
- Use managed identities over service principals
- Follow principle of least privilege

---

## Best Practices

### General

1. **Write tests first** (TDD approach)
2. **Keep functions small** (single responsibility)
3. **Document public APIs** (comments/docstrings)
4. **Handle errors explicitly** (no silent failures)
5. **Use meaningful names** (no single letters except loops)
6. **Avoid premature optimization** (clear code first)
7. **Review your own code** (before requesting review)

### Git Commits

Use [Conventional Commits](https://www.conventionalcommits.org/):

```bash
# Format: <type>(<scope>): <description>

feat(backend): add user authentication
fix(ui): resolve navbar overflow issue
docs(api): update authentication guide
chore(deps): upgrade dependencies
test(users): add unit tests for user service
```

### Code Review

As a reviewer:

- ✅ Focus on logic, not style (automated)
- ✅ Check for security issues
- ✅ Verify tests are included
- ✅ Ensure documentation is updated

As an author:

- ✅ Keep PRs small (< 400 lines)
- ✅ Write clear PR descriptions
- ✅ Respond to all comments
- ✅ Run linters before requesting review

---

## FAQ

### General Questions

#### Q: Do I need to install all tools locally?

**A**: No. Pre-commit will install tools automatically in isolated environments. However, installing tools locally gives you real-time feedback in your IDE.

#### Q: Can I skip pre-commit hooks?

**A**: You can with `--no-verify`, but it's not recommended. CI will still enforce all checks, so you'll need to fix issues eventually.

#### Q: How do I fix "line too long" errors?

**A**: 
- Python: Break into multiple lines (120 char limit)
- Go: No strict limit, but prefer 80-100 characters
- Shell: Break commands with `\` continuation

#### Q: What if a linter gives a false positive?

**A**:
- Add inline comment to disable: `# noqa` (Python), `// nolint` (Go)
- Update config file to ignore specific rule
- Document why in code comments

### Python-Specific

#### Q: Why does Black format my code differently than I want?

**A**: Black is opinionated by design. This ensures consistency. If you disagree, discuss with the team about updating `.black` config.

#### Q: How do I add type hints to existing code?

**A**: Start with function signatures:

```python
def process_data(data: Dict[str, Any]) -> List[str]:
    ...
```

Run `mypy` to find issues incrementally.

#### Q: What's the difference between Flake8 and Pylint?

**A**:
- **Flake8**: Fast, checks PEP 8 style
- **Pylint**: Comprehensive, checks logic and patterns
- Use both for best coverage

### Go-Specific

#### Q: Why is golangci-lint slow?

**A**: It runs multiple linters. Use `--fast` flag for quick checks:

```bash
golangci-lint run --fast
```

#### Q: How do I ignore a specific linter error?

**A**: Add inline comment:

```go
//nolint:errcheck
_ = file.Close()
```

Or disable for entire file:

```go
//nolint
package main
```

### Shell-Specific

#### Q: Why does ShellCheck complain about my working script?

**A**: ShellCheck finds potential bugs. Review warnings carefully - they often prevent issues in edge cases.

#### Q: How do I quote variables correctly?

**A**: Always use `"${var}"`:

```bash
# Good
if [[ "${username}" == "admin" ]]; then

# Bad
if [ $username == "admin" ]; then
```

### Terraform-Specific

#### Q: How do I handle sensitive outputs?

**A**: Mark as sensitive:

```hcl
output "database_password" {
  value     = random_password.db.result
  sensitive = true
}
```

#### Q: Why does tfsec report issues on working code?

**A**: tfsec checks for security best practices. Fix HIGH/CRITICAL issues, consider others.

### CI/CD

#### Q: My PR failed linting but passes locally. Why?

**A**:
- Run `pre-commit run --all-files` locally
- Ensure you've pulled latest changes
- Check CI logs for specific failures

#### Q: Can I merge if coverage drops?

**A**: No. Add tests to maintain ≥ 60% coverage:

```bash
# Check coverage locally
pytest --cov=. --cov-report=term-missing
```

#### Q: How do I see detailed CI logs?

**A**:
1. Go to GitHub Actions tab
2. Click on failed workflow
3. Expand failed job
4. Review error messages

### Troubleshooting

#### Q: Pre-commit fails with "command not found"

**A**: Install missing tool:

```bash
# macOS
brew install shellcheck shfmt yamllint

# Linux
apt-get install shellcheck yamllint
```

#### Q: How do I reset pre-commit hooks?

**A**:

```bash
pre-commit uninstall
pre-commit clean
make pre-commit-setup
```

#### Q: My IDE isn't formatting on save

**A**:
1. Verify extensions are installed
2. Check settings.json configuration
3. Restart IDE
4. Run formatter manually to test: `black file.py`

---

## Additional Resources

### Documentation

- [Code Quality Standards Guide](docs/how-to/development/code-quality-standards.md) - Detailed reference
- [Format-on-Save Setup](docs/how-to/development/format-on-save-setup.md) - IDE configuration
- [GitHub Actions Workflows](docs/how-to/development/github-actions-workflows.md) - CI/CD details
- [Pre-commit Documentation](docs/PRE-COMMIT.md) - Pre-commit deep dive
- [Contributing Guide](docs/contributing.md) - How to contribute

### External Resources

- [Black Documentation](https://black.readthedocs.io/)
- [golangci-lint Linters](https://golangci-lint.run/usage/linters/)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Prettier Options](https://prettier.io/docs/en/options.html)
- [Conventional Commits](https://www.conventionalcommits.org/)

### Tools

- [pre-commit](https://pre-commit.com/) - Git hook framework
- [Black](https://github.com/psf/black) - Python formatter
- [golangci-lint](https://golangci-lint.run/) - Go linter
- [ShellCheck](https://www.shellcheck.net/) - Shell script analyzer
- [Prettier](https://prettier.io/) - Multi-language formatter

---

## Getting Help

### Internal

- **Slack**: #fawkes-dev
- **Office Hours**: Tuesday/Thursday 2-3pm PST
- **Email**: fawkes-dev@example.com

### Issues

Found a problem or have a suggestion?

1. Search [existing issues](https://github.com/paruff/fawkes/issues)
2. Create new issue with `[code-quality]` label
3. Provide example and expected behavior

---

## Conclusion

Following these coding standards ensures:

- ✅ Consistent, readable code across the platform
- ✅ Early detection of bugs and security issues
- ✅ Faster code reviews (automated style checks)
- ✅ Better collaboration between team members
- ✅ Higher quality, more maintainable codebase

**Remember**: These standards exist to help us build better software together. When in doubt, ask for help!

---

**Version**: 1.0.0  
**Last Updated**: December 26, 2024  
**Maintained By**: Fawkes Platform Team
