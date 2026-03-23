# JUnit

[JUnit](https://junit.org/) is the standard unit testing framework for Java. JUnit 5
(the Jupiter API) is the current generation, providing a modern annotation-based test
model with powerful extension support.

## How Fawkes Uses JUnit

The sample Java application under `services/samples/sample-java-app/` uses JUnit 5 for
unit and integration tests. Jenkins collects JUnit XML reports and publishes HTML test
results visible in the build summary.

```java
// Example JUnit 5 test
@Test
void shouldReturnHealthy() {
    var response = client.get("/health");
    assertEquals(200, response.statusCode());
    assertEquals("UP", response.body());
}
```

## Maven Integration

Tests run automatically with `mvn test`. The Surefire plugin executes JUnit tests and
produces XML reports in `target/surefire-reports/`.

```xml
<!-- pom.xml -->
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>
```

## Jenkins Test Reporting

Jenkins captures JUnit XML reports and displays:
- Pass/fail/skip counts per build
- Test duration trends
- Flaky test detection
- Failed test details with stack traces

```groovy
// Jenkinsfile
post {
    always {
        junit 'target/surefire-reports/**/*.xml'
    }
}
```

## Code Coverage

Fawkes uses JaCoCo alongside JUnit to measure code coverage. A minimum 80% line coverage
is enforced as a quality gate in the CI pipeline.

## See Also

- [Test Automation Pattern](../patterns/test-automation.md)
- [Code Quality Standards](../how-to/development/code-quality-standards.md)
- [Sample Java App](../tutorials/1-deploy-first-service.md)
