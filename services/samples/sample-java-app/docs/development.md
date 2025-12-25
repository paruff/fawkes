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

### Java Style Guide

We follow standard Java conventions with these additions:

- Use Java 17+ features
- Follow Google Java Style Guide or similar
- Maximum line length: 120 characters
- Use meaningful variable and method names
- Write clear Javadoc comments for public APIs

### Code Formatting

We use the following tools:

- **Checkstyle**: Enforce code style
- **SpotBugs**: Find bugs through static analysis
- **SonarQube**: Code quality and security analysis

```bash
# Format code (Maven)
mvn spotless:apply

# Check code style (Maven)
mvn checkstyle:check

# Run SpotBugs (Maven)
mvn spotbugs:check

# Format code (Gradle)
./gradlew spotlessApply

# Check code style (Gradle)
./gradlew checkstyleMain
```

## Testing

### Writing Tests

- Use JUnit 5 for unit tests
- Use Mockito for mocking dependencies
- Place tests in `src/test/java/`
- Aim for >80% code coverage

### Test Structure

```java
@Test
void shouldReturnExpectedValue() {
    // Arrange
    var input = setupTestData();

    // Act
    var result = myService.process(input);

    // Assert
    assertEquals(expectedValue, result);
}
```

## Documentation

### Code Documentation

- Use Javadoc for all public classes and methods
- Include parameter descriptions and return values
- Document exceptions

Example:

```java
/**
 * Calculate the total price of items.
 *
 * @param items List of items to calculate total for
 * @return Total price as BigDecimal
 * @throws IllegalArgumentException if items list is empty
 */
public BigDecimal calculateTotal(List<Item> items) {
    // implementation
}
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

Use SLF4J with Logback or Log4j2:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

private static final Logger logger = LoggerFactory.getLogger(MyClass.class);

logger.info("Processing request for user: {}", userId);
```

### Metrics

Use Spring Boot Actuator and Micrometer:

- Expose metrics endpoint
- Track request count and duration
- Monitor error rates
- Custom business metrics

### Tracing

Use Spring Boot with OpenTelemetry:

```java
@Autowired
private Tracer tracer;

Span span = tracer.spanBuilder("operation_name").startSpan();
try (Scope scope = span.makeCurrent()) {
    // Your code here
} finally {
    span.end();
}
```

## Security

### Secrets Management

- Never commit secrets to Git
- Use Spring Cloud Vault for secret management
- Use environment variables or external configuration

### Dependencies

- Keep dependencies up to date
- Use Dependabot or Renovate
- Run OWASP Dependency Check
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
