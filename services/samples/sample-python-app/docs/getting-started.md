# Getting Started

This guide will help you get started with the sample-python-app service.

## Installation

### Local Development

1. **Clone the repository**

```bash
git clone <repository-url>
cd sample-python-app
```

2. **Install dependencies**

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -r requirements-dev.txt
```

3. **Configure environment**

```bash
# Copy example environment file
cp .env.example .env

# Edit .env with your configuration
```

4. **Run the service**

```bash
# Development mode with auto-reload
uvicorn app.main:app --reload --port 8000
```

## Testing

### Run Unit Tests

```bash
pytest tests/
```

### Run with Coverage

```bash
pytest --cov=app tests/
```

### Linting

```bash
# Run flake8
flake8 app tests

# Run type checking
mypy app
```

## Deployment

This service is automatically deployed via GitOps using ArgoCD when changes are merged to the main branch.

### CI/CD Pipeline

1. **Build**: Code is built and unit tests are executed
2. **Security Scan**: SonarQube and Trivy scans are performed
3. **Package**: Docker image is built and pushed to Harbor
4. **Deploy**: ArgoCD syncs the changes to the target environment

## Next Steps

- [API Reference](api.md) - Learn about the available endpoints
- [Development](development.md) - Contribution guidelines
