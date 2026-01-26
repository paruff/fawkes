# Standards Documentation

This section contains coding standards, style guides, and best practices for contributing to the Fawkes platform.

## Coding Standards

- [Coding Standards](../../CODING_STANDARDS.md) - Comprehensive coding standards guide
- [Code Quality Standards](../how-to/development/code-quality-standards.md) - Quality requirements
- [Code Quality Quick Start](../how-to/development/code-quality-quickstart.md) - Quick setup guide

## Pre-commit Hooks

- [Pre-commit Hooks Setup](../PRE-COMMIT.md) - Configure pre-commit hooks for quality checks

## Documentation Standards

- [Standardization Summary](../STANDARDIZATION_SUMMARY.md) - Documentation standardization approach

## Quality Assurance

### Linting

Run all linters before committing:

```bash
make lint
```

Individual linters:

- **Bash**: shellcheck
- **Python**: flake8, black, isort
- **Go**: golangci-lint
- **YAML**: yamllint
- **Markdown**: markdownlint
- **Terraform**: terraform fmt, tflint

### Pre-commit Setup

```bash
# One-time setup
make pre-commit-setup

# Manual run
pre-commit run --all-files
```

### CI/CD Quality Gates

All pull requests must pass:

- ✅ Automated linting
- ✅ Security scanning
- ✅ Unit tests
- ✅ Pre-commit hooks
- ✅ Code review

## Style Guides

### Markdown

Follow [markdownlint rules](.markdownlint.json) for consistent documentation:

- Use ATX-style headings (`#`)
- Use fenced code blocks with language tags
- Limit line length (when reasonable)
- Use proper list formatting

### Python

- Follow [PEP 8](https://pep8.org/) style guide
- Use type hints
- Write docstrings in Google style
- Use `black` for formatting

### Go

- Follow [Effective Go](https://golang.org/doc/effective_go)
- Use `gofmt` and `golangci-lint`
- Write tests for all public functions

### Bash

- Follow [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- Use `shellcheck` for validation
- Quote all variables

## Related Documentation

- [Contributing Guide](../contributing.md) - How to contribute
- [Development Guide](../development.md) - Development setup
- [Code of Conduct](../CODE_OF_CONDUCT.md) - Community guidelines
