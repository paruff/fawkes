# ${{ values.name }}

${{ values.description }}

## Overview

This is a Spring Boot microservice following the Fawkes Golden Path. It includes:

- ✅ REST API with health and info endpoints
- ✅ Prometheus metrics via Spring Actuator
- ✅ Docker containerization
- ✅ Kubernetes manifests
- ✅ CI/CD pipeline via Jenkins
- ✅ Unit tests and BDD tests with Cucumber
- ✅ Security scanning with SonarQube and Trivy

## Prerequisites

- Java 21 LTS
- Maven 3.9+
- Docker
- kubectl (for deployment)

## Local Development

### Build

```bash
# Using Maven wrapper
./mvnw clean install

# Or with system Maven
mvn clean install
```

### Run

```bash
# Run locally
./mvnw spring-boot:run

# Or run the JAR
java -jar target/${{ values.name }}-0.1.0-SNAPSHOT.jar
```

The service will start on `http://localhost:8080`

### Test

```bash
# Run unit tests
./mvnw test

# Run BDD tests
./mvnw verify

# Run all tests with coverage
./mvnw clean verify
```

## API Endpoints

- `GET /api/health` - Health check endpoint
- `GET /api/info` - Service information
- `GET /actuator/health` - Spring Actuator health
- `GET /actuator/prometheus` - Prometheus metrics

## Docker

### Build Image

```bash
docker build -t ${{ values.name }}:latest .
```

### Run Container

```bash
docker run -p 8080:8080 ${{ values.name }}:latest
```

## Deployment

This service is deployed via GitOps using ArgoCD.

### Deploy to Kubernetes

```bash
# Apply manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get deployment ${{ values.name }}
kubectl get pods -l app=${{ values.name }}
```

### ArgoCD

```bash
# Sync with ArgoCD
argocd app sync ${{ values.name }}

# Check status
argocd app get ${{ values.name }}
```

## Monitoring

- **Metrics**: https://grafana.fawkes.idp/d/${{ values.name }}
- **Logs**: https://opensearch.fawkes.idp
- **Traces**: https://grafana.fawkes.idp/explore?ds=tempo
- **Health**: https://${{ values.name }}.fawkes.idp/actuator/health

## CI/CD Pipeline

The Jenkins pipeline runs on every commit to `main`:

1. **Build**: Compile and package the application
2. **Test**: Run unit and BDD tests
3. **Scan**: SonarQube SAST and Trivy container scan
4. **Package**: Build Docker image
5. **Publish**: Push to Harbor registry
6. **Deploy**: Update GitOps repository

## Project Structure

```
.
├── src/
│   ├── main/
│   │   ├── java/com/fawkes/app/
│   │   │   ├── Application.java
│   │   │   └── controller/
│   │   │       └── HealthController.java
│   │   └── resources/
│   │       └── application.properties
│   └── test/
│       ├── java/com/fawkes/app/
│       │   ├── controller/
│       │   │   └── HealthControllerTest.java
│       │   └── bdd/
│       │       ├── RunCucumberTest.java
│       │       └── HealthStepDefinitions.java
│       └── resources/
│           └── features/
│               └── health.feature
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── Dockerfile
├── Jenkinsfile
├── pom.xml
└── catalog-info.yaml
```

## Support

- **Mattermost**: #platform-support
- **Documentation**: https://fawkes.idp/docs
- **Issues**: https://github.com/paruff/fawkes/issues
