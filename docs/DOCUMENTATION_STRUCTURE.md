# Documentation Structure Guide

This document explains the organization of the Fawkes platform documentation.

## Overview

The Fawkes documentation follows the [Diátaxis framework](https://diataxis.fr/), organizing content by user needs into four main categories:

1. **Tutorials** - Learning-oriented, step-by-step guides
2. **How-To Guides** - Task-oriented, problem-solving guides
3. **Explanation** - Understanding-oriented, conceptual guides
4. **Reference** - Information-oriented, technical specifications

## Directory Structure

```
docs/
├── index.md                    # Documentation homepage
├── getting-started.md          # Quick start guide
├── architecture.md             # Platform architecture overview
├── configuration.md            # Platform configuration
├── troubleshooting.md          # Common issues and solutions
├── contributing.md             # Contributing guidelines
├── development.md              # Development setup
│
├── tutorials/                  # Step-by-step learning guides
├── how-to/                     # Task-specific guides
├── explanation/                # Conceptual documentation
├── patterns/                   # Design and architecture patterns
├── reference/                  # API docs, glossary, config
├── playbooks/                  # Implementation playbooks
│
├── deployment/                 # Deployment guides and configs
├── observability/              # Monitoring, metrics, DORA
├── security-plane/             # Security features and policies
├── testing/                    # Testing strategies
├── validation/                 # Validation procedures
├── runbooks/                   # Operational procedures
│
├── adr/                        # Architecture Decision Records
├── ai/                         # AI and ML documentation
├── data-platform/              # Data platform docs
├── design/                     # Design system
├── research/                   # User research
├── standards/                  # Coding standards
├── vsm/                        # Value Stream Mapping
├── tools/                      # Platform tools docs
│
└── implementation-summaries/   # Historical implementation records
```

## Index Files

Each major directory contains an `index.md` file that:

- Provides an overview of the section
- Lists key documents in the section
- Links to related documentation
- Helps users navigate the content

## Navigation Paths

### For Application Developers

Users who want to build and deploy applications:

1. Start: [Getting Started](getting-started.md)
2. Learn: [Tutorials](tutorials/index.md)
3. Tasks: [How-To Guides](how-to/index.md)
4. Reference: [Reference Docs](reference/index.md)
5. Help: [Troubleshooting](troubleshooting.md)

### For Platform Engineers

Maintainers building and operating the platform:

1. Understand: [Architecture](architecture.md)
2. Contribute: [Contributing Guide](contributing.md)
3. Develop: [Development Guide](development.md)
4. Standards: [Coding Standards](../CODING_STANDARDS.md)
5. Decisions: [ADRs](adr/index.md)
6. Operate: [Runbooks](runbooks/index.md)

## Documentation Types

### Tutorials (Learning-Oriented)

**Purpose**: Help users learn by doing
**Location**: `docs/tutorials/`
**Characteristics**:
- Step-by-step instructions
- Reproducible examples
- Focus on teaching, not explaining
- Example: "Deploy Your First Service"

### How-To Guides (Task-Oriented)

**Purpose**: Solve specific problems
**Location**: `docs/how-to/`
**Characteristics**:
- Goal-oriented
- Assume some knowledge
- Focus on results, not understanding
- Example: "Rotate Vault Secrets"

### Explanation (Understanding-Oriented)

**Purpose**: Explain concepts and decisions
**Location**: `docs/explanation/`, `docs/patterns/`, `docs/adr/`
**Characteristics**:
- Conceptual discussion
- Background and context
- Multiple perspectives
- Example: "GitOps Strategy"

### Reference (Information-Oriented)

**Purpose**: Provide technical information
**Location**: `docs/reference/`, `docs/tools/`
**Characteristics**:
- Accurate and complete
- Neutral description
- Technical specifications
- Example: "Glossary", "API Documentation"

## Operational Documentation

### Deployment

Guides for deploying the platform and services:
- Infrastructure provisioning
- Platform installation
- Service deployment
- Configuration management

### Observability

Monitoring, metrics, and DORA implementation:
- Metrics collection
- Dashboard creation
- Alerting setup
- DORA metrics tracking

### Security

Security features, policies, and procedures:
- Security scanning
- Policy enforcement
- Secrets management
- Vulnerability management

### Testing

Testing strategies and implementations:
- Unit testing
- Integration testing
- E2E testing
- Acceptance testing

## Maintenance

### Adding New Documentation

1. Determine the documentation type (tutorial, how-to, explanation, reference)
2. Place in appropriate directory
3. Follow existing format and style
4. Add to `mkdocs.yml` navigation if needed
5. Update relevant index.md files
6. Add cross-links to related docs

### Updating Navigation

The `mkdocs.yml` file defines the site navigation. When adding new sections:

1. Add to appropriate nav section
2. Update related index.md files
3. Test with `mkdocs build`
4. Verify all links work

### Running Quality Checks

```bash
# Lint markdown files
make lint

# Build documentation site
mkdocs build

# Serve locally for preview
mkdocs serve
# Opens at http://localhost:8000
```

## Style Guidelines

### Markdown

- Use ATX-style headings (`#`)
- Use fenced code blocks with language tags
- Keep lines reasonable length (no strict limit)
- Use proper list formatting
- Include alt text for images

### Cross-Linking

- Link to related documentation liberally
- Use relative paths for internal links
- Include context in link text
- Example: `[Deploy Your First Service](tutorials/1-deploy-first-service.md)`

### Voice and Tone

- Use active voice
- Write in present tense
- Use "you" for users, "we" for platform team
- Be concise and clear
- Focus on user needs

## Related Documentation

- [CODING_STANDARDS.md](../CODING_STANDARDS.md) - Code quality standards
- [Contributing Guide](contributing.md) - How to contribute
- [README.md](../README.md) - Project overview
- [CHANGELOG.md](../CHANGELOG.md) - Version history

## Resources

- [Diátaxis Framework](https://diataxis.fr/) - Documentation system framework
- [MkDocs](https://www.mkdocs.org/) - Documentation site generator
- [Material for MkDocs](https://squidfunk.github.io/mkdocs-material/) - Theme documentation
- [Keep a Changelog](https://keepachangelog.com/) - Changelog format
