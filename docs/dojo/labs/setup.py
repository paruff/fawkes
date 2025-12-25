# =============================================================================
# setup.py - Package installation configuration
# =============================================================================

from setuptools import setup, find_packages
from pathlib import Path

# Read README for long description
this_directory = Path(__file__).parent
long_description = (this_directory / "README.md").read_text()

setup(
    name="fawkes-cli",
    version="1.0.0",
    author="Fawkes Platform Team",
    author_email="platform-team@fawkes.io",
    description="Command-line tool for Fawkes Platform Engineering Dojo",
    long_description=long_description,
    long_description_content_type="text/markdown",
    url="https://github.com/fawkes-platform/fawkes-cli",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: System Administrators",
        "Topic :: Software Development :: Build Tools",
        "Topic :: System :: Systems Administration",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
        "Programming Language :: Python :: 3.11",
    ],
    python_requires=">=3.8",
    install_requires=[
        "click>=8.0.0",
        "pyyaml>=6.0",
        "requests>=2.28.0",
        "kubernetes>=24.0.0",
        "rich>=12.0.0",  # For beautiful terminal output
    ],
    extras_require={
        "dev": [
            "pytest>=7.0.0",
            "pytest-cov>=3.0.0",
            "black>=22.0.0",
            "flake8>=4.0.0",
            "mypy>=0.950",
        ],
    },
    entry_points={
        "console_scripts": [
            "fawkes=fawkes_cli.cli:main",
        ],
    },
    include_package_data=True,
    package_data={
        "fawkes_cli": [
            "labs/**/*.yaml",
            "labs/**/*.yml",
            "templates/**/*",
        ],
    },
    project_urls={
        "Documentation": "https://docs.fawkes.io",
        "Source": "https://github.com/fawkes-platform/fawkes-cli",
        "Bug Reports": "https://github.com/fawkes-platform/fawkes-cli/issues",
    },
)


# =============================================================================
# requirements.txt - Production dependencies
# =============================================================================

"""
click==8.1.7
pyyaml==6.0.1
requests==2.31.0
kubernetes==28.1.0
rich==13.7.0
"""


# =============================================================================
# requirements-dev.txt - Development dependencies
# =============================================================================

"""
-r requirements.txt

# Testing
pytest==7.4.3
pytest-cov==4.1.0
pytest-mock==3.12.0

# Code quality
black==23.12.1
flake8==6.1.0
mypy==1.7.1
isort==5.13.2

# Documentation
sphinx==7.2.6
sphinx-rtd-theme==2.0.0
"""


# =============================================================================
# pyproject.toml - Modern Python project configuration
# =============================================================================

"""
[build-system]
requires = ["setuptools>=65.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "fawkes-cli"
version = "1.0.0"
description = "Command-line tool for Fawkes Platform Engineering Dojo"
readme = "README.md"
requires-python = ">=3.8"
license = {text = "MIT"}
authors = [
    {name = "Fawkes Platform Team", email = "platform-team@fawkes.io"}
]
keywords = ["platform-engineering", "devops", "kubernetes", "gitops", "dojo"]

dependencies = [
    "click>=8.0.0",
    "pyyaml>=6.0",
    "requests>=2.28.0",
    "kubernetes>=24.0.0",
    "rich>=12.0.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=3.0.0",
    "black>=22.0.0",
    "flake8>=4.0.0",
]

[project.scripts]
fawkes = "fawkes_cli.cli:main"

[project.urls]
Homepage = "https://fawkes.io"
Documentation = "https://docs.fawkes.io"
Repository = "https://github.com/fawkes-platform/fawkes-cli"
Issues = "https://github.com/fawkes-platform/fawkes-cli/issues"

[tool.black]
line-length = 100
target-version = ['py38', 'py39', 'py310', 'py311']

[tool.isort]
profile = "black"
line_length = 100

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = "test_*.py"
python_functions = "test_*"
addopts = "-v --cov=fawkes_cli --cov-report=html --cov-report=term"

[tool.mypy]
python_version = "3.8"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
"""


# =============================================================================
# MANIFEST.in - Include non-Python files in package
# =============================================================================

"""
include README.md
include LICENSE
include requirements.txt
recursive-include src/fawkes_cli/labs *.yaml *.yml
recursive-include src/fawkes_cli/templates *
recursive-exclude * __pycache__
recursive-exclude * *.py[co]
"""


# =============================================================================
# .gitignore - Git ignore patterns
# =============================================================================

"""
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Virtual environments
venv/
ENV/
env/

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# Testing
.pytest_cache/
.coverage
htmlcov/
.tox/

# Fawkes specific
.fawkes/
*.log
"""


# =============================================================================
# README.md - Package README
# =============================================================================

"""
# Fawkes CLI

Command-line tool for the Fawkes Platform Engineering Dojo.

## Installation

### From PyPI (when published)

```bash
pip install fawkes-cli
```

### From Source

```bash
git clone https://github.com/fawkes-platform/fawkes-cli
cd fawkes-cli
pip install -e .
```

## Quick Start

```bash
# Setup infrastructure (one-time)
fawkes setup

# Start a lab
fawkes lab start --module 1

# Validate lab completion
fawkes lab validate --lab white-belt-lab1

# Clean up
fawkes lab stop --module 1
```

## Prerequisites

- Python 3.8+
- kubectl
- Access to a Kubernetes cluster

## Commands

### Lab Management

```bash
fawkes lab start --module N       # Start lab environment
fawkes lab validate --lab NAME    # Validate lab completion
fawkes lab stop --module N        # Clean up lab
fawkes lab list                   # List active labs
fawkes lab status --module N      # Check lab status
fawkes lab logs --module N        # View lab logs
```

### Assessments

```bash
fawkes assessment validate --belt LEVEL     # Validate assessment
fawkes assessment check-eligibility         # Check prerequisites
fawkes assessment schedule --belt LEVEL     # Schedule assessment
```

### Configuration

```bash
fawkes config set KEY VALUE       # Set config value
fawkes config get KEY             # Get config value
fawkes config list                # List all config
```

### Utilities

```bash
fawkes setup                      # Setup infrastructure
fawkes login                      # Authenticate
fawkes status                     # Check platform status
fawkes version                    # Show version
```

## Configuration

Config file location: `~/.fawkes/config.yaml`

Example configuration:

```yaml
cluster:
  context: my-cluster
  namespace_prefix: lab

labs:
  timeout: 3600
  auto_cleanup: true

user:
  email: your.email@company.com
  name: Your Name
```

## Development

```bash
# Clone repository
git clone https://github.com/fawkes-platform/fawkes-cli
cd fawkes-cli

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\\Scripts\\activate

# Install in development mode
pip install -e ".[dev]"

# Run tests
pytest

# Run linters
black src/
flake8 src/
mypy src/
```

## Documentation

- Full documentation: https://docs.fawkes.io
- Dojo modules: https://docs.fawkes.io/dojo
- Lab guides: https://docs.fawkes.io/dojo/labs

## Support

- Mattermost: #dojo-support
- Email: dojo-support@fawkes.io
- Issues: https://github.com/fawkes-platform/fawkes-cli/issues

## License

MIT License - see LICENSE file for details

## Contributing

Contributions welcome! Please see CONTRIBUTING.md for guidelines.
"""


# =============================================================================
# LICENSE - MIT License
# =============================================================================
