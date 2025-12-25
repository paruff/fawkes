---
title: Contributing to Fawkes
description: Guidelines for contributing to the Fawkes Internal Developer Platform
---

# Contributing to Fawkes

Thank you for your interest in contributing to Fawkes! This guide will help you get started with contributing to the project.

## Development Workflow

### 1. Trunk-Based Development

We follow trunk-based development practices:

```bash
# Clone the repository
git clone https://github.com/paruff/fawkes.git
cd fawkes

# Create a feature branch
git checkout -b feature/your-feature-name

# Make your changes
# Commit frequently with clear messages
git add .
git commit -m "feat: description of your change"

# Push your changes
git push origin feature/your-feature-name
```

### 2. Development Guidelines

| Guideline | Description |
|-----------|-------------|
| ![](assets/images/icons/git.png){ width="24" } **Branch Lifetime** | Merge within 24 hours |
| ![](assets/images/icons/test.png){ width="24" } **Testing** | Include tests with all changes |
| ![](assets/images/icons/docs.png){ width="24" } **Documentation** | Update relevant docs |
| ![](assets/images/icons/ci.png){ width="24" } **CI/CD** | Ensure all checks pass |

### 3. Code Quality Standards

All contributions must meet our code quality standards:

```bash
# One-time setup: Install pre-commit hooks
make pre-commit-setup

# Before committing: Run linters
make lint

# Pre-commit will automatically run on git commit
```

**All code must**:
- Pass automated linting (Bash, Python, Go, YAML, JSON, Markdown, Terraform)
- Pass security scanning (secrets detection, SAST, container scanning)
- Follow language-specific style guides
- Include appropriate tests

📖 **See**: [Code Quality Standards](how-to/development/code-quality-standards.md) for detailed requirements

## Adding New Content

### Documentation

```markdown
---
title: Your Page Title
description: Brief description of the page content
---

# Your Page Title

Content goes here following the standard format:
- Use H2 (##) for main sections
- Use tables for structured information
- Include related links
```

### Implementation Patterns

When adding new patterns:

1. Create pattern file in `docs/patterns/`
2. Add to navigation in `mkdocs.yml`
3. Link from relevant capabilities
4. Include example implementations

### Tool Integration

When adding new tools:

1. Create tool doc in `docs/tools/`
2. Add to navigation in `mkdocs.yml`
3. Link from relevant patterns
4. Include configuration examples

## Testing Changes

```bash
# Install dependencies
pip install -r requirements.txt

# Run local development server
mkdocs serve

# Build documentation
mkdocs build
```

## Submitting Changes

1. **Create Issue**
   - Describe the problem or enhancement
   - Reference related DORA capabilities

2. **Submit Pull Request**
   - Reference the issue
   - Include clear description
   - Update documentation
   - Add tests if applicable

3. **Review Process**
   - Peer review required
   - All checks must pass
   - Documentation updated

## Getting Help

- Create an issue on GitHub
- Join our community discussions
- Review existing documentation

[View Style Guide](style-guide.md){ .md-button }
[GitHub Repository](https://github.com/paruff/fawkes){ .md-button }
