# Getting Started

This guide will help you get started with the ${{ values.name }} service.

## Installation

### Local Development

1. **Clone the repository**

```bash
git clone <repository-url>
cd ${{ values.name }}
```

2. **Build the project**

```bash
# Using Maven
mvn clean install

# Using Gradle
./gradlew build
```

3. **Configure environment**

```bash
# Copy example application properties
cp src/main/resources/application.properties.example src/main/resources/application.properties

# Edit application.properties with your configuration
```

4. **Run the service**

```bash
# Using Maven
mvn spring-boot:run

# Using Gradle
./gradlew bootRun

# Or run the JAR directly
java -jar target/${{ values.name }}-0.0.1-SNAPSHOT.jar
```

## Testing

### Run Unit Tests

```bash
# Using Maven
mvn test

# Using Gradle
./gradlew test
```

### Run with Coverage

```bash
# Using Maven with JaCoCo
mvn test jacoco:report

# Using Gradle with JaCoCo
./gradlew test jacocoTestReport
```

### Linting

```bash
# Run Checkstyle (Maven)
mvn checkstyle:check

# Run SpotBugs (Maven)
mvn spotbugs:check

# Run Checkstyle (Gradle)
./gradlew checkstyleMain checkstyleTest
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
