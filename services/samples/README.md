# Sample Applications

This directory contains three sample applications deployed on the Fawkes platform for testing and demonstration purposes.

## Applications

### 1. Sample Java Spring Boot App (`sample-java-app`)

A Java Spring Boot microservice demonstrating:
- REST API with health and info endpoints
- Prometheus metrics via Spring Actuator
- Docker containerization with security best practices
- Kubernetes deployment with proper resource limits
- GitOps deployment via ArgoCD

**Access**: https://sample-java-app.fawkes.idp
**Language**: Java 21 with Spring Boot 3.4.1
**Metrics**: `/actuator/prometheus`

### 2. Sample Python FastAPI App (`sample-python-app`)

A Python FastAPI application demonstrating:
- High-performance async REST API
- Prometheus metrics integration
- Structured logging
- Health and readiness endpoints
- Uvicorn ASGI server

**Access**: https://sample-python-app.fawkes.idp
**Language**: Python 3.12 with FastAPI 0.115.5
**Metrics**: `/metrics`

### 3. Sample Node.js Express App (`sample-nodejs-app`)

A Node.js Express service demonstrating:
- Lightweight REST API
- Prometheus metrics with prom-client
- Express middleware patterns
- Graceful shutdown handling
- Health check endpoints

**Access**: https://sample-nodejs-app.fawkes.idp
**Language**: Node.js 20 with Express 4.21.2
**Metrics**: `/metrics`

## Purpose

These sample applications are used for:

1. **Platform Testing**: Validate that the Fawkes platform can deploy and manage applications across different technology stacks
2. **DORA Metrics Collection**: Demonstrate automatic collection of deployment frequency, lead time, change failure rate, and MTTR
3. **Golden Path Validation**: Ensure the golden path templates work correctly
4. **Developer Onboarding**: Provide reference implementations for new teams
5. **Integration Testing**: Test platform capabilities like ingress, observability, and security

## Deployment

All sample applications are deployed via ArgoCD:

```bash
# Apply ArgoCD Applications
kubectl apply -f platform/apps/samples/

# Check deployment status
kubectl get applications -n fawkes

# View application logs
kubectl logs -n fawkes-samples -l app=sample-java-app
kubectl logs -n fawkes-samples -l app=sample-python-app
kubectl logs -n fawkes-samples -l app=sample-nodejs-app
```

## DORA Metrics

All sample applications have DORA metrics collection enabled through ArgoCD annotations:

```yaml
annotations:
  dora.fawkes.io/collect-metrics: "true"
  dora.fawkes.io/environment: "dev"
```

Metrics are collected by DevLake and can be viewed in:
- **DevLake Dashboard**: https://devlake.fawkes.idp
- **Grafana DORA Dashboard**: https://grafana.fawkes.idp/d/dora-metrics

## Monitoring

### Prometheus Metrics

All apps expose Prometheus metrics that are automatically scraped:

```bash
# Java app metrics
curl https://sample-java-app.fawkes.idp/actuator/prometheus

# Python app metrics
curl https://sample-python-app.fawkes.idp/metrics

# Node.js app metrics
curl https://sample-nodejs-app.fawkes.idp/metrics
```

### Health Checks

```bash
# Java app health
curl https://sample-java-app.fawkes.idp/actuator/health

# Python app health
curl https://sample-python-app.fawkes.idp/health

# Node.js app health
curl https://sample-nodejs-app.fawkes.idp/health
```

## Backstage Integration

All sample apps are registered in the Backstage service catalog with:
- Component metadata
- API definitions
- Kubernetes integration
- CI/CD pipeline status
- DORA metrics visibility

View in Backstage: https://backstage.fawkes.idp/catalog

## Architecture

Each sample application follows Fawkes best practices:

### Security
- Non-root container execution (UID 65534)
- Read-only root filesystem
- Dropped capabilities
- Security context with seccomp profile
- TLS termination at ingress

### Observability
- Prometheus metrics exposition
- Structured logging to stdout
- Health and readiness probes
- OpenTelemetry tracing support

### Scalability
- Horizontal pod autoscaling ready
- Resource requests and limits defined
- Pod disruption budgets
- Anti-affinity rules for HA

## Local Development

Each sample app can be run locally for development:

```bash
# Java app
cd services/samples/sample-java-app
./mvnw spring-boot:run

# Python app
cd services/samples/sample-python-app
pip install -r requirements.txt
python -m app.main

# Node.js app
cd services/samples/sample-nodejs-app
npm install
npm start
```

## Testing

Run tests for each application:

```bash
# Java app tests
cd services/samples/sample-java-app
./mvnw test
./mvnw verify  # BDD tests

# Python app tests
cd services/samples/sample-python-app
pytest
behave  # BDD tests

# Node.js app tests
cd services/samples/sample-nodejs-app
npm test
npm run test:bdd  # BDD tests
```

## CI/CD Pipeline

Each app includes a `Jenkinsfile` that defines the CI/CD pipeline:

1. **Build**: Compile and package the application
2. **Test**: Run unit and BDD tests with coverage
3. **Scan**: SonarQube SAST and Trivy container scan
4. **Package**: Build Docker image with security scanning
5. **Publish**: Push to Harbor registry
6. **Deploy**: Update GitOps repository for ArgoCD

The pipeline enforces quality gates:
- Zero new bugs/vulnerabilities (SonarQube)
- No HIGH/CRITICAL container vulnerabilities (Trivy)
- Test coverage ≥ 80%
- All tests passing

## Troubleshooting

### Application not accessible

```bash
# Check pod status
kubectl get pods -n fawkes-samples

# Check ingress
kubectl get ingress -n fawkes-samples

# View pod logs
kubectl logs -n fawkes-samples -l app=sample-java-app --tail=100
```

### ArgoCD sync issues

```bash
# Check ArgoCD application status
kubectl get application sample-java-app -n fawkes -o yaml

# Force sync
kubectl patch application sample-java-app -n fawkes \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

### Metrics not appearing

```bash
# Check ServiceMonitor
kubectl get servicemonitor -n fawkes-samples

# Test metrics endpoint
kubectl port-forward -n fawkes-samples svc/sample-java-app 8080:80
curl http://localhost:8080/actuator/prometheus
```

## Support

- **Documentation**: https://fawkes.idp/docs
- **Mattermost**: #platform-support
- **Issues**: https://github.com/paruff/fawkes/issues
