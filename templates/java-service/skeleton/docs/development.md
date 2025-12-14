# Development Guide

## Development Workflow

### Branching Strategy

- `main`: Production-ready code
- `develop`: Integration branch for features
- `feature/*`: Feature branches
- `bugfix/*`: Bug fix branches

### Making Changes

1. Create a feature branch from `develop`
2. Make your changes
3. Write tests for your changes
4. Ensure all tests pass
5. Create a pull request

## Code Style

### Python Style Guide

We follow [PEP 8](https://pep8.org/) with the following additions:

- Line length: 100 characters
- Use type hints for all function signatures
- Use docstrings for all public functions and classes

### Code Formatting

We use the following tools:

- **Black**: Code formatting
- **isort**: Import sorting
- **flake8**: Linting
- **mypy**: Type checking

```bash
# Format code
black app tests

# Sort imports
isort app tests

# Lint
flake8 app tests

# Type check
mypy app
```

## Testing

### Writing Tests

- Place unit tests in `tests/unit/`
- Place integration tests in `tests/integration/`
- Use pytest fixtures for common setup
- Aim for >80% code coverage

### Test Structure

```python
def test_function_name():
    # Arrange
    setup_test_data()
    
    # Act
    result = function_under_test()
    
    # Assert
    assert result == expected_value
```

## Documentation

### Code Documentation

- All public functions must have docstrings
- Use Google-style docstrings
- Include parameter types and return types

Example:

```python
def calculate_total(items: list[Item]) -> float:
    """Calculate the total price of items.
    
    Args:
        items: List of items to calculate total for
        
    Returns:
        Total price as a float
        
    Raises:
        ValueError: If items list is empty
    """
    pass
```

### Documentation Site

Update the documentation in the `docs/` directory:

- `index.md`: Overview and introduction
- `getting-started.md`: Installation and setup
- `api.md`: API reference
- `development.md`: This file

Build and preview documentation locally:

```bash
# Install mkdocs
pip install mkdocs mkdocs-material

# Serve documentation locally
mkdocs serve

# Build documentation
mkdocs build
```

## Observability

### Logging

Use structured logging with the standard library:

```python
import logging

logger = logging.getLogger(__name__)

logger.info("Processing request", extra={
    "user_id": user_id,
    "request_id": request_id
})
```

### Metrics

Expose Prometheus metrics for:

- Request count and duration
- Error rates
- Business metrics

### Tracing

Use OpenTelemetry for distributed tracing:

```python
from opentelemetry import trace

tracer = trace.get_tracer(__name__)

with tracer.start_as_current_span("operation_name"):
    # Your code here
    pass
```

## Security

### Secrets Management

- Never commit secrets to Git
- Use environment variables for configuration
- Use Vault for sensitive data

### Dependencies

- Keep dependencies up to date
- Run security scans with `safety check`
- Review dependency licenses

## CI/CD Pipeline

The CI/CD pipeline includes:

1. **Lint**: Code quality checks
2. **Test**: Unit and integration tests
3. **Security Scan**: SonarQube and Trivy
4. **Build**: Docker image build
5. **Deploy**: GitOps deployment via ArgoCD

## Getting Help

- Check the [Fawkes documentation](https://backstage.fawkes.idp/docs)
- Ask in the team Slack channel
- Create an issue in the repository
- Contact the platform team
