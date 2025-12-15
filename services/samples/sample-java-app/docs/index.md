# sample-java-app

## Overview

Sample Java Spring Boot application for testing

## Quick Start

This service is part of the Fawkes platform and follows the golden path for Java microservices.

### Prerequisites

- Java 17+ and Maven or Gradle
- Docker
- Access to the Fawkes platform

### Running Locally

```bash
# Using Maven
mvn clean install
mvn spring-boot:run

# Using Gradle
./gradlew build
./gradlew bootRun
```

The service will be available at `http://localhost:8080`.

## Architecture

This service is built using:

- **Spring Boot**: Framework for production-ready Spring applications
- **Spring Framework**: Comprehensive programming and configuration model
- **OpenTelemetry**: Distributed tracing and observability

## Features

- RESTful API with OpenAPI documentation
- Health check endpoints (Spring Boot Actuator)
- Prometheus metrics
- Distributed tracing with OpenTelemetry
- Structured logging

## Documentation

- [Getting Started](getting-started.md) - Setup and installation guide
- [API Reference](api.md) - API endpoints and usage
- [Development](development.md) - Development guidelines

## Support

For issues and questions:

- Create an issue in the GitHub repository
- Contact the platform team via Backstage
- Check the [Fawkes documentation](https://backstage.fawkes.idp/docs)

## Owner

**Team**: ${{ values.owner }}
