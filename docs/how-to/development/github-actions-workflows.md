# GitHub Actions Workflows

This document describes the GitHub Actions workflows used in the Fawkes platform for continuous integration and code quality enforcement.

## Overview

Fawkes uses multiple GitHub Actions workflows to ensure code quality, security, and platform reliability:

| Workflow | Purpose | Trigger | Badge |
|----------|---------|---------|-------|
| **Code Quality** | Linting, formatting, testing, coverage | PR, Push to main/develop | ![Code Quality](https://github.com/paruff/fawkes/actions/workflows/code-quality.yml/badge.svg) |
| **Pre-commit** | Pre-commit hook validation | PR, Push to main/develop | ![Pre-commit](https://github.com/paruff/fawkes/actions/workflows/pre-commit.yml/badge.svg) |
| **Security & Terraform** | Security scanning, Terraform validation | PR, Push to main | ![Security](https://github.com/paruff/fawkes/actions/workflows/security-and-terraform.yml/badge.svg) |
| **E2E Tests** | End-to-end platform testing | PR, Schedule | ![E2E Tests](https://github.com/paruff/fawkes/actions/workflows/idp-e2e-tests.yml/badge.svg) |
| **Accessibility** | WCAG compliance testing | PR, Push to main | ![Accessibility](https://github.com/paruff/fawkes/actions/workflows/accessibility-testing.yml/badge.svg) |

## Code Quality Workflow

**File**: `.github/workflows/code-quality.yml`

This workflow enforces comprehensive code quality standards across all languages used in Fawkes.

### Jobs

#### 1. Python Quality

Runs multiple linters and static analysis tools on Python code:

- **Black**: Code formatting check
- **Flake8**: Style guide enforcement (PEP 8)
- **MyPy**: Static type checking
- **Pylint**: Advanced code analysis

**Configuration**:
```yaml
- Max line length: 120 characters
- Ignore: E203, W503 (Black compatibility)
- Type hints: Required for public functions
```

**Local commands**:
```bash
# Run all Python linters
black --check .
flake8 . --max-line-length=120 --extend-ignore=E203,W503
mypy --ignore-missing-imports .
pylint $(find . -name "*.py")
```

#### 2. Python Test Coverage

Runs pytest with coverage reporting:

- **Coverage threshold**: 60% (will increase over time)
- **Report formats**: XML, HTML, Terminal
- **Coverage comment**: Automatically comments on PRs with coverage report

**Configuration**: `.coveragerc`, `tests/pytest.ini`

**Local commands**:
```bash
# Run tests with coverage
pytest --cov=. --cov-report=term-missing --cov-report=html

# View HTML report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

**Coverage artifacts**: Uploaded to GitHub Actions for review

#### 3. TypeScript/JavaScript Quality

Runs for the design-system components:

- **ESLint**: JavaScript/TypeScript linting
- **TypeScript Compiler**: Type checking
- **Jest**: Unit tests with coverage

**Conditions**: Only runs if TypeScript/JavaScript files are present

**Local commands**:
```bash
cd design-system
npm run lint
npx tsc --noEmit
npm test -- --coverage
```

#### 4. Go Quality

Runs golangci-lint for Go code:

- **Linters**: gofmt, govet, errcheck, staticcheck, and more
- **Configuration**: `.golangci.yml`
- **Timeout**: 5 minutes

**Conditions**: Only runs if Go files are present

**Local commands**:
```bash
golangci-lint run --timeout=5m
```

#### 5. Shell Quality

Runs ShellCheck on all shell scripts:

- **Severity**: Warning level
- **Standards**: POSIX compliance, best practices

**Local commands**:
```bash
shellcheck --severity=warning scripts/**/*.sh
```

#### 6. Security Integration Check

Verifies security tools are properly configured:

- Checks for security workflow existence
- Verifies Gitleaks configuration
- Validates pre-commit hooks setup

#### 7. Quality Summary

Aggregates results from all jobs and:

- Posts summary to GitHub Actions
- Comments on pull requests
- Provides links to fix issues

### Quality Gates

The workflow uses **continue-on-error: true** for most checks to provide comprehensive feedback without blocking PRs immediately. This allows developers to see all issues at once.

**Exception**: Security scanning failures should block deployment (handled in separate security workflow).

### Triggering the Workflow

**Automatically**:
- On pull request to `main` or `develop`
- On push to `main` or `develop`

**Manually**:
```bash
# Via GitHub UI: Actions → Code Quality → Run workflow
# Or via GitHub CLI:
gh workflow run code-quality.yml
```

## Pre-commit Workflow

**File**: `.github/workflows/pre-commit.yml`

Runs all pre-commit hooks defined in `.pre-commit-config.yaml`.

**Jobs**:
1. **Pre-commit**: Runs all hooks on all files
2. **GitOps Validation**: ArgoCD application validation
3. **IDP Validation**: Backstage catalog validation

**Local setup**:
```bash
make pre-commit-setup
pre-commit run --all-files
```

See [Pre-commit Documentation](../PRE-COMMIT.md) for details.

## Security & Terraform Workflow

**File**: `.github/workflows/security-and-terraform.yml`

Combines security scanning with Terraform validation.

**Security Checks**:
1. **Gitleaks**: Secret detection
2. **Trivy**: Vulnerability scanning (filesystem and containers)
3. **SARIF Upload**: Results to GitHub Security tab

**Terraform Checks**:
1. **terraform fmt**: Formatting check
2. **terraform validate**: Syntax validation
3. **TFLint**: Linting and best practices
4. **tfsec**: Security scanning

**Local commands**:
```bash
# Security
gitleaks detect --redact
trivy fs .

# Terraform
terraform fmt -recursive
terraform validate
tflint --recursive
tfsec .
```

## E2E Tests Workflow

**File**: `.github/workflows/idp-e2e-tests.yml`

Runs end-to-end tests for the entire platform.

**Scope**:
- ArgoCD deployment verification
- Backstage functionality
- Jenkins pipeline execution
- Observability stack validation

**Trigger**: PR, manual, scheduled (nightly)

## Accessibility Testing Workflow

**File**: `.github/workflows/accessibility-testing.yml`

Ensures WCAG 2.1 AA compliance.

**Tools**:
- **Axe-core**: Automated accessibility testing
- **Lighthouse CI**: Performance and accessibility audits
- **Pa11y**: Command-line accessibility testing

**Scope**: design-system components, Backstage UI

## Best Practices

### For Contributors

1. **Run locally first**: `make lint` before pushing
2. **Install pre-commit**: `make pre-commit-setup`
3. **Check coverage**: Aim for 80%+ on new code
4. **Review workflow output**: Address all issues

### For Maintainers

1. **Review failed checks**: Investigate root causes
2. **Update thresholds**: Gradually increase coverage requirements
3. **Monitor workflow performance**: Optimize slow jobs
4. **Update dependencies**: Keep actions up to date

## Workflow Monitoring

### View Workflow Status

**GitHub UI**: Repository → Actions tab

**GitHub CLI**:
```bash
# List workflow runs
gh run list --workflow=code-quality.yml

# View specific run
gh run view <run-id>

# Download artifacts
gh run download <run-id>
```

### Workflow Badges

Add badges to documentation:

```markdown
![Code Quality](https://github.com/paruff/fawkes/actions/workflows/code-quality.yml/badge.svg)
```

### Notifications

Configure workflow notifications:
- **Settings** → **Notifications** → **Actions**
- Choose: All workflows, failed workflows only, or none

## Troubleshooting

### Common Issues

#### Coverage Threshold Not Met

**Error**: `FAIL Required test coverage of 60% not met`

**Solution**:
```bash
# Run coverage locally
pytest --cov=. --cov-report=term-missing

# Identify untested code
# Add tests for files with low coverage
```

#### Linting Failures

**Error**: `Black would reformat files`

**Solution**:
```bash
# Auto-format
black .

# Commit changes
git add -u
git commit -m "Apply Black formatting"
```

#### Security Scan Failures

**Error**: `Gitleaks detected secrets`

**Solution**:
1. Remove secrets from code
2. Use environment variables instead
3. Rotate compromised credentials
4. Update `.gitleaks.toml` allowlist if false positive

#### Workflow Timeout

**Error**: Job exceeds 6 hour timeout

**Solution**:
1. Optimize slow steps
2. Add caching for dependencies
3. Split into multiple jobs
4. Increase timeout for specific jobs

## Maintenance

### Updating Workflows

1. Edit workflow file in `.github/workflows/`
2. Test locally with `act` (if possible):
   ```bash
   act -j python-quality
   ```
3. Create PR with changes
4. Monitor first run carefully

### Adding New Linters

1. Update workflow file
2. Add configuration file (if needed)
3. Update documentation
4. Test on sample PRs

### Updating Dependencies

**GitHub Actions**:
```bash
# Update to latest versions
# Edit workflow files to use @v6 instead of @v5, etc.
```

**Pre-commit hooks**:
```bash
pre-commit autoupdate
git commit -am "Update pre-commit hooks"
```

## Related Documentation

- [Code Quality Standards](development/code-quality-standards.md)
- [Pre-commit Hooks](../PRE-COMMIT.md)
- [Quality Gates Configuration](security/quality-gates-configuration.md)
- [Contributing Guide](../contributing.md)

## Support

- **GitHub Issues**: Report workflow problems
- **GitHub Discussions**: Ask questions
- **Mattermost**: #platform-help channel

---

**Maintained by**: Fawkes Platform Team  
**Last Updated**: December 2024  
**Related Issues**: #111 (Code Quality CI/CD Pipeline)
