# Code Quality Pipeline - Quick Start Guide

## For Developers

### First Time Setup

```bash
# 1. Install pre-commit hooks (one-time setup)
make pre-commit-setup

# 2. Install Python development dependencies
pip install -r requirements-dev.txt
```

### Before Committing

```bash
# Run all linters locally
make lint

# Or run pre-commit hooks manually
pre-commit run --all-files
```

### Running Tests with Coverage

```bash
# Run tests with coverage report
pytest --cov=. --cov-report=term-missing --cov-report=html

# View HTML coverage report
open htmlcov/index.html  # macOS
xdg-open htmlcov/index.html  # Linux
```

### Fixing Common Issues

#### Black Formatting

```bash
# Check formatting
black --check .

# Auto-fix formatting
black .
```

#### Flake8 Linting

```bash
# Check style
flake8 . --max-line-length=120 --extend-ignore=E203,W503

# Most issues require manual fixes
```

#### MyPy Type Checking

```bash
# Check types
mypy --ignore-missing-imports .

# Add type hints to fix issues
```

## What Runs on PR

When you create a pull request, the following checks run automatically:

### 1. Python Quality (5-7 min)
- ✅ Black formatting check
- ✅ Flake8 linting
- ✅ MyPy type checking
- ✅ Pylint code analysis

### 2. Python Coverage (3-5 min)
- ✅ pytest with 60% minimum coverage
- ✅ Coverage report in PR comment
- ✅ HTML/XML reports in artifacts

### 3. TypeScript/JavaScript Quality (2-3 min)
- ✅ ESLint (if TS/JS files present)
- ✅ TypeScript compiler check
- ✅ Jest tests with coverage

### 4. Go Quality (2-3 min)
- ✅ golangci-lint (if Go files present)

### 5. Shell Quality (1-2 min)
- ✅ ShellCheck for all shell scripts

### 6. Security Integration (1 min)
- ✅ Validates security tools configured

### 7. Quality Summary (1 min)
- ✅ Aggregates results
- ✅ Posts comment on PR

## Reading Workflow Results

### Green Checks ✅
- All quality checks passed
- Safe to merge (pending other reviews)

### Yellow Warnings ⚠️
- Some non-critical issues found
- Review and consider fixing
- May still merge if approved

### Red Failures ❌
- Critical issues found
- Must be fixed before merge
- Check workflow logs for details

## Common Workflow Failures

### Coverage Too Low

**Error**: `FAIL Required test coverage of 60% not met`

**Fix**: Add tests for uncovered code

```bash
# See what's not covered
pytest --cov=. --cov-report=term-missing

# Focus on files with low coverage
```

### Black Formatting Issues

**Error**: `Black would reformat X files`

**Fix**: Run Black locally

```bash
black .
git add -u
git commit -m "Apply Black formatting"
git push
```

### Linting Errors

**Error**: Various linting errors from Flake8/Pylint

**Fix**: Address each error individually

```bash
# See all errors
flake8 . --max-line-length=120
pylint $(find . -name "*.py")

# Fix and re-run
```

## Skipping Checks (Emergency Only)

In rare cases, you may need to skip checks:

```bash
# Skip pre-commit hooks (not recommended)
git commit --no-verify

# Skip specific pre-commit hooks
SKIP=black,flake8 git commit
```

**Note**: Skipping local hooks doesn't skip CI checks!

## Getting Help

### Documentation
- [GitHub Actions Workflows](docs/how-to/development/github-actions-workflows.md)
- [Code Quality Standards](docs/how-to/development/code-quality-standards.md)
- [Pre-commit Hooks](docs/PRE-COMMIT.md)

### Support Channels
- GitHub Issues for bugs
- GitHub Discussions for questions
- Mattermost #platform-help for quick help

## Best Practices

### ✅ DO

- Run `make lint` before pushing
- Keep coverage above 60% (aim for 80%+)
- Write type hints for public functions
- Use descriptive commit messages
- Address linting issues immediately

### ❌ DON'T

- Don't skip pre-commit hooks regularly
- Don't ignore coverage drops
- Don't disable linting rules globally
- Don't commit commented-out code
- Don't commit secrets (even temporarily)

## Quick Reference

| Command | Purpose |
|---------|---------|
| `make pre-commit-setup` | Install pre-commit hooks |
| `make lint` | Run all linters |
| `pre-commit run --all-files` | Run pre-commit hooks |
| `pytest --cov=.` | Run tests with coverage |
| `black .` | Format Python code |
| `flake8 .` | Check Python style |
| `mypy .` | Check Python types |

## Workflow Status Badges

Check the repository README for live status badges:

- ![Code Quality](https://github.com/paruff/fawkes/actions/workflows/code-quality.yml/badge.svg)
- ![Pre-commit](https://github.com/paruff/fawkes/actions/workflows/pre-commit.yml/badge.svg)
- ![Security](https://github.com/paruff/fawkes/actions/workflows/security-and-terraform.yml/badge.svg)

---

**Questions?** Open a GitHub Discussion or ask in #platform-help on Mattermost.
