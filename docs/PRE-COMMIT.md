# Pre-commit Hooks Setup Guide

This repository uses pre-commit hooks to ensure code quality, security, and compliance with GitOps, Terraform, Kubernetes, and IDP standards.

## Quick Start

### Install Pre-commit Hooks

```bash
make pre-commit-setup
```

This will:

1. Install the `pre-commit` package
2. Install all configured hooks
3. Set up Git hooks to run automatically on commit

### Manual Installation

If you prefer to install manually:

```bash
pip install pre-commit
pre-commit install
```

## What Gets Validated?

Our pre-commit hooks validate the following areas:

### 🔧 General Code Quality

- ✅ Trailing whitespace removal
- ✅ End-of-file fixing
- ✅ YAML/JSON syntax validation
- ✅ Large file detection
- ✅ Merge conflict detection
- ✅ Mixed line ending fixes
- ✅ Private key detection

### 📝 Documentation

- ✅ Markdown linting (`.markdownlint.json`)
- ✅ MkDocs build validation
- ✅ Documentation link checking

### 🏗️ Terraform (IaC)

- ✅ `terraform fmt` (auto-formatting)
- ✅ `terraform validate` (syntax validation)
- ✅ TFLint (static analysis)
- ✅ Terraform docs generation
- ✅ tfsec (security scanning)

### ☸️ Kubernetes Manifests

- ✅ kubeval (manifest validation)
- ✅ kustomize build validation
- ✅ Hardcoded secret detection
- ✅ Helm chart linting

### 🚀 GitOps

- ✅ ArgoCD application validation
- ✅ Kustomization file validation
- ✅ GitOps best practices

### 🎯 IDP Components

- ✅ Backstage catalog validation
- ✅ Helm values validation
- ✅ Platform component configuration

### 🔒 Security

- ✅ **Gitleaks** (comprehensive secret detection)
  - Detects 100+ types of secrets (API keys, passwords, tokens)
  - Configurable via `.gitleaks.toml`
  - Fast and accurate scanning
- ✅ **detect-secrets** (baseline-based detection)
  - Manages known false positives via `.secrets.baseline`
  - Complementary to Gitleaks
- ✅ **Private key detection** (SSH keys, certificates)
  - Prevents accidental commit of private keys
- ✅ **tfsec** (Terraform security scanning)
  - Infrastructure security best practices

**⚠️ Pipeline Integration**: Secrets scanning also runs in Jenkins CI/CD pipelines. If secrets are detected, the pipeline **fails immediately** to prevent deployment of vulnerable code.

**📖 Learn More**: See [Secrets Management Guide](how-to/security/secrets-management.md) for detailed information on handling secrets securely.

### 🐍 Python

- ✅ Black formatting
- ✅ Flake8 linting
- ✅ Type checking readiness

### 🐚 Shell Scripts

- ✅ ShellCheck validation

## Running Pre-commit Hooks

### Automatic (on commit)

Once installed, hooks run automatically when you commit:

```bash
git add .
git commit -m "Your commit message"
# Hooks run automatically
```

### Manual (all files)

Run hooks on all files in the repository:

```bash
pre-commit run --all-files
```

### Manual (specific files)

Run hooks on specific files:

```bash
pre-commit run --files infra/aws/main.tf
```

### Manual (specific hook)

Run a specific hook:

```bash
pre-commit run terraform_fmt --all-files
pre-commit run kubeval --all-files
```

### Skip Hooks (emergency only)

If you need to skip hooks temporarily (not recommended):

```bash
git commit --no-verify -m "Emergency fix"
```

## Tool Installation

Some hooks require external tools. Here's how to install them:

### Terraform Tools

```bash
# Terraform
brew install terraform  # macOS
# or download from https://terraform.io

# TFLint
brew install tflint  # macOS
# or download from https://github.com/terraform-linters/tflint

# terraform-docs
brew install terraform-docs  # macOS

# tfsec
brew install tfsec  # macOS
```

### Kubernetes Tools

```bash
# kubectl
brew install kubectl  # macOS

# kubeval
brew install kubeval  # macOS

# kustomize
brew install kustomize  # macOS

# helm
brew install helm  # macOS

# yq (YAML processor)
brew install yq  # macOS
```

### ArgoCD Tools

```bash
# ArgoCD CLI
brew install argocd  # macOS
# or download from https://argo-cd.readthedocs.io/
```

### MkDocs (Documentation)

```bash
pip install -r requirements.txt
```

### Notes

- ⚠️ Hooks that require unavailable tools will show warnings but won't fail
- ✅ GitHub Actions runs all hooks with all tools installed
- 💡 For the best experience, install all tools locally

## Configuration Files

| File                      | Purpose                                         |
| ------------------------- | ----------------------------------------------- |
| `.pre-commit-config.yaml` | Main pre-commit configuration                   |
| `.tflint.hcl`             | TFLint rules and plugin configuration           |
| `.terraform-docs.yml`     | Terraform documentation generation              |
| `.secrets.baseline`       | detect-secrets baseline (known false positives) |
| `.yamllint`               | YAML linting rules                              |
| `.markdownlint.json`      | Markdown linting rules                          |

## Updating Hooks

Pre-commit hooks are versioned. To update to the latest versions:

```bash
pre-commit autoupdate
```

This updates `.pre-commit-config.yaml` with the latest hook versions.

## Troubleshooting

### Hook fails with "command not found"

Install the required tool (see Tool Installation section).

### Hook fails on valid file

- Check if the file should be excluded in `.pre-commit-config.yaml`
- Add to baseline if it's a false positive (e.g., `.secrets.baseline`)

### Hooks are too slow

- Use `--hook-stage manual` for expensive hooks
- Run specific hooks instead of all: `pre-commit run hook-name`

### Reset hooks

```bash
pre-commit clean
pre-commit install --install-hooks
```

### Disable a specific hook

Edit `.pre-commit-config.yaml` and add `stages: [manual]` to the hook.

## GitHub Actions Integration

Pre-commit hooks run automatically in CI/CD via `.github/workflows/pre-commit.yml`:

- ✅ Runs on every pull request
- ✅ Runs on push to main/develop
- ✅ Comments on PR if validation fails
- ✅ All tools pre-installed in CI environment

## Best Practices

1. **Run hooks locally before pushing** - Catch issues early
2. **Install all tools** - Get the full validation experience
3. **Keep hooks updated** - Run `pre-commit autoupdate` monthly
4. **Don't skip hooks** - They exist for good reasons
5. **Fix root causes** - Don't just work around hook failures

## Contributing

When adding new hooks:

1. Add to `.pre-commit-config.yaml`
2. Test with `pre-commit run --all-files`
3. Update this README
4. Ensure CI job installs required tools

## Support

- 📖 [Pre-commit documentation](https://pre-commit.com/)
- 🐛 [Report issues](https://github.com/paruff/fawkes/issues)
- 💬 [Community discussions](https://github.com/paruff/fawkes/discussions)

---

**Remember**: Pre-commit hooks help maintain code quality and security. They're here to help, not hinder! 🚀
