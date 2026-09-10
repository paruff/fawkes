# Fawkes Scripts Directory

This directory contains automation scripts for the Fawkes platform, organized by purpose and responsibility.

## Directory Structure

```
scripts/
├── lib/                      # Shared library modules (modular ignite.sh)
│   ├── common.sh             # Error handling, logging, state management
│   ├── flags.sh              # Command-line flag parsing
│   ├── prereqs.sh            # Prerequisite checking
│   ├── terraform.sh          # Terraform operations
│   ├── validation.sh         # Cluster and workload validation
│   ├── cluster.sh            # Cluster provisioning orchestration
│   ├── argocd.sh             # ArgoCD deployment and management
│   ├── summary.sh            # Access summary generation
│   ├── error_handling.sh     # Error handling utilities
│   └── providers/            # Cloud provider implementations
│       ├── local.sh          # Local cluster (minikube, docker-desktop)
│       ├── aws.sh            # AWS EKS provisioning
│       ├── azure.sh          # Azure AKS provisioning
│       └── gcp.sh            # GCP GKE provisioning
├── homelab/                  # Homelab-specific scripts
│   ├── prepare-mac-mini-worker.sh
│   ├── start-wsl-k3s-worker.bat
│   ├── start-wsl-k3s-worker.ps1
│   ├── wake-win-wsl.sh
│   ├── prepare-wsl-connections.ps1
│   └── register-startup-task.ps1
├── validate-at-e*.sh         # Acceptance test validation scripts (per-issue)
├── validate-golden-path-*.sh # Golden path plane validation scripts
├── validate-epic-*.sh        # Epic-level validation orchestrators
├── ignite.sh                 # Main bootstrap orchestrator
├── bootstrap.sh              # Initial setup script
├── dev-up.sh / dev-down.sh   # Development environment lifecycle
├── tools.sh / tools-install.sh # Tool installation helpers
└── ...                       # Other utility scripts
```

## Script Categories

### 1. Bootstrap & Provisioning (Core)

| Script | Purpose |
|--------|---------|
| `ignite.sh` | Main orchestrator for Fawkes bootstrap (cluster + ArgoCD + apps) |
| `bootstrap.sh` | Initial repository/project setup |
| `dev-up.sh` / `dev-down.sh` | Start/stop local development environment |
| `buildinfra.sh` / `buildplatform.sh` | Infrastructure and platform build scripts |

**Key Features:**
- Modular architecture via `scripts/lib/`
- Provider abstraction: `local` (minikube), `aws` (EKS), `azure` (AKS), `gcp` (GKE)
- State management with `--resume` capability
- Dry-run mode for planning
- `--only-cluster` / `--only-apps` for targeted operations

### 2. Acceptance Test Validation (`validate-at-e*-*`)

Per-issue validation scripts that verify specific acceptance criteria (AC). Naming convention: `validate-at-e{EPIC}-{ISSUE}.sh`

| Pattern | Examples | Scope |
|---------|----------|-------|
| `e0-` | `validate-at-e0-001.sh`, `validate-at-e0-002.sh` | Epic 0: Foundation/Code Quality |
| `e1-` | `validate-at-e1-001.sh` through `validate-at-e1-012.sh` | Epic 1: Cluster & Infrastructure |
| `e2-` | `validate-at-e2-001.sh` through `validate-at-e2-010.sh` | Epic 2: Platform Services |
| `e3-` | `validate-at-e3-001.sh` through `validate-at-e3-012.sh` | Epic 3: Product & Discovery |

**Common Pattern:**
- Each script validates ONE issue's acceptance criteria
- Uses consistent test harness: `TOTAL_TESTS`, `PASSED_TESTS`, `FAILED_TESTS`
- Outputs JSON report to `reports/`
- Supports `--verbose`, `--namespace`, `--report` flags
- Exit code: 0 = all ACs pass, 1 = any AC fails

### 3. Golden Path Validation (`validate-golden-path-*.sh`)

Validates the **tracer-bullet** golden path across 4 planes (tracer-bullet is the reference application demonstrating Fawkes end-to-end):

| Script | Plane | Validates |
|--------|-------|-----------|
| `validate-golden-path-pipeline.sh` | Pipeline | Tekton PipelineRun built, scanned, pushed image to GHCR |
| `validate-golden-path-security.sh` | Security | Image signed (cosign), pod securityContext hardened, smart-alerting rejects unauth |
| `validate-golden-path-gitops.sh` | GitOps | ArgoCD sync succeeded, manifests match live cluster |
| `validate-golden-path-observability.sh` | Observability | Golden signals, traces, logs, dashboards present |
| `validate-golden-path-dora.sh` | DORA | Deployment frequency, lead time, change failure rate, MTTR |
| `validate-golden-path-devex.sh` | DevEx | CLI, scaffolding, local simulation work |
| `validate-golden-path-resources.sh` | Resources | Resource quotas, limits, requests configured |
| `validate-golden-path-progressive-delivery.sh` | Progressive | Canary/blue-green deployment patterns |

**Key Distinction:** These validate *live runtime state* (cluster, registry, GitOps repo), not just Git declarations.

### 4. Epic-Level Orchestration (`validate-epic-*.sh`)

Aggregate multiple AT validations for a complete epic.

| Script | Epics Covered | Issues |
|--------|---------------|--------|
| `validate-epic-3-final.sh` | Epic 3 Final | AT-E3-008, AT-E3-010, AT-E3-011, AT-E3-012 |

**Pattern:**
- Runs constituent `validate-at-e*-*.sh` scripts in sequence
- Collects results, generates consolidated JSON report
- Exit code reflects aggregate pass/fail

### 5. Feature-Focused / Specialized Validation

| Script | Purpose |
|--------|---------|
| `validate-security-plane.sh` | Platform security posture (RBAC, network policies, secrets) |
| `validate-research-structure.py` | Research documentation structure |
| `validate-issue-*.sh` | Ad-hoc issue validation |
| `verify-dora-metrics-service.sh` | DORA metrics service health |
| `check-ai-readiness.sh` | AI-assisted development readiness |
| `validate-jcasc.py` | Jenkins Configuration as Code |
| `seal-secrets.py` | SealedSecrets management |

### 6. Homelab Scripts (`homelab/`)

Scripts for managing the physical/virtual homelab cluster:
- Mac Mini worker node preparation
- WSL k3s worker node management (Windows + Linux scripts)
- Wake-on-LAN and startup automation

### 7. Utility & Maintenance

| Script | Purpose |
|--------|---------|
| `tools.sh` / `tools-install.sh` | Install required CLI tools (kubectl, terraform, etc.) |
| `weekly-metrics.sh` | DORA metrics collection (cron job) |
| `access-summary.sh` | Display service URLs and credentials |
| `dev-status.sh` | Check development environment status |
| `github-issues-generator.sh` / `create_issues_script.sh` | GitHub issue automation |
| `render-all-applications.sh` | Render all Helm/Kustomize manifests |

## Usage Patterns

### Running Individual AT Validations

```bash
# Validate a specific acceptance test
./scripts/validate-at-e1-001.sh --namespace fawkes --verbose

# Generate JSON report
./scripts/validate-at-e0-001.sh --report reports/at-e0-001.json

# Run with environment overrides
AZURE_RESOURCE_GROUP=my-rg ./scripts/validate-at-e1-001.sh
```

### Running Epic Validation

```bash
# Validate all Epic 3 final acceptance tests
./scripts/validate-epic-3-final.sh --namespace fawkes --verbose

# Skip report generation
./scripts/validate-epic-3-final.sh --no-report
```

### Running Golden Path Validations

```bash
# Pipeline plane (requires kubectl + gh CLI)
./scripts/validate-golden-path-pipeline.sh --namespace fawkes

# Security plane (requires cosign for signature check)
./scripts/validate-golden-path-security.sh --namespace fawkes

# All golden path planes (manual orchestration)
for script in scripts/validate-golden-path-*.sh; do
  "$script" --namespace fawkes
done
```

### Bootstrapping Fawkes

```bash
# Local development cluster
./scripts/ignite.sh local

# AWS EKS cluster
./scripts/ignite.sh --provider aws --region us-west-2 dev

# Azure AKS with custom name
./scripts/ignite.sh --provider azure --location eastus --cluster-name my-cluster dev

# Dry-run to preview
./scripts/ignite.sh --provider azure --dry-run dev

# Resume from failure
./scripts/ignite.sh --resume dev

# Show access summary only
./scripts/ignite.sh --access
```

## Conventions & Standards

### Test Harness (Shared Pattern)

All validation scripts follow this pattern:

```bash
# Counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()

# Recording function
record_test() {
  local test_name="$1" status="$2" message="$3"
  TOTAL_TESTS=$((TOTAL_TESTS + 1))
  if [ "$status" = "PASS" ]; then
    PASSED_TESTS=$((PASSED_TESTS + 1))
    log_success "$test_name: $message"
  else
    FAILED_TESTS=$((FAILED_TESTS + 1))
    log_error "$test_name: $message"
  fi
  TEST_RESULTS+=("$(jq -n --arg n "$test_name" --arg s "$status" --arg m "$message" '{name:$n,status:$s,message:$m}')")
}
```

### Output Format

- **Console**: Color-coded progress with section headers
- **Reports**: JSON in `reports/` with timestamp, summary, and per-test results
- **Exit Codes**: 0 = success, 1 = failure

### Library Reuse

Scripts should source shared libraries where applicable:

```bash
source "$(dirname "${BASH_SOURCE[0]}")/lib/common.sh"
source "$(dirname "${BASH_SOURCE[0]}")/lib/flags.sh"
```

## Adding New Validation Scripts

1. **For new AT (Acceptance Test):**
   - Name: `validate-at-e{EPIC}-{ISSUE}.sh`
   - Follow the test harness pattern
   - Add to appropriate epic orchestrator if needed

2. **For new Golden Path plane:**
   - Name: `validate-golden-path-{PLANE}.sh`
   - Validate live runtime state, not Git declarations
   - Output standardized JSON report

3. **For new Epic orchestrator:**
   - Name: `validate-epic-{NAME}.sh`
   - Call constituent AT scripts
   - Generate consolidated report

## Relationship: AT Scripts vs Epic Scripts vs Golden Path

```
┌─────────────────────────────────────────────────────────────┐
│                    EPIC ORCHESTRATORS                       │
│  (validate-epic-*.sh - runs multiple AT scripts)           │
└──────────────────────┬──────────────────────────────────────┘
                       │ runs
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌───────────────┐ ┌───────────────┐ ┌───────────────┐
│  AT-E3-008    │ │  AT-E3-010    │ │  AT-E3-011    │
│  (discovery)  │ │  (usability)  │ │  (analytics)  │
└───────┬───────┘ └───────┬───────┘ └───────┬───────┘
        │                 │                 │
        └─────────────────┼─────────────────┘
                          ▼
        ┌─────────────────────────────────┐
        │      GOLDEN PATH VALIDATIONS    │
        │  (validate-golden-path-*.sh)    │
        │  Validates live runtime across  │
        │  4 planes: Pipeline, Security,  │
        │  GitOps, Observability          │
        └─────────────────────────────────┘
```

**Key Distinction:**
- **AT scripts** (`validate-at-e*`) = Verify *specific issue acceptance criteria* (contractual)
- **Golden Path scripts** = Verify *end-to-end runtime behavior* of tracer-bullet (evidence)
- **Epic scripts** = Aggregate AT results for milestone reporting

## Reports

All validation scripts generate JSON reports in `reports/` directory:

```
reports/
├── at-e0-001-validation-20251226-120000.json
├── at-e1-001-validation-20251226-120000.json
├── epic-3-final-validation-20251226-120000.json
├── golden-path-pipeline-validation-20251226-120000.json
├── golden-path-security-validation-20251226-120000.json
└── ...
```

Report schema includes:
- `test_suite` / `test_name`
- `timestamp` (ISO 8601)
- `summary`: total, passed, failed, pass_rate
- `results`: array of `{name, status, message}`
- Context-specific fields (cluster, namespace, image_repo, etc.)

## CI/CD Integration

Scripts are designed for CI/CD integration:

```yaml
# Example GitHub Actions step
- name: Validate Epic 3
  run: |
    ./scripts/validate-epic-3-final.sh --namespace fawkes
    # Reports automatically uploaded as artifacts
```

## Maintenance Notes

- **Cleanup**: `ignite.sh cleanup` removes ArgoCD/Fawkes namespaces and cluster-scoped resources
- **State**: `.ignite-state.json` tracks bootstrap progress for `--resume`
- **Dependencies**: Most scripts require `kubectl`, `jq`, `gh`, `cosign` (for security)
- **Environment**: Use `NAMESPACE` env var (default: `fawkes`) for target namespace
