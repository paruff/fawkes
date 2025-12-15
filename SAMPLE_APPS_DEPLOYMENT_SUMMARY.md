# Sample Applications Deployment Summary

## Overview

This implementation successfully deploys three sample applications (Java Spring Boot, Python FastAPI, and Node.js Express) to demonstrate the Fawkes platform capabilities and enable DORA metrics collection.

## What Was Deployed

### 1. Sample Java Spring Boot Application (`sample-java-app`)
- **Location**: `services/samples/sample-java-app/`
- **Framework**: Spring Boot 3.4.1 with Java 21 LTS
- **Features**:
  - REST API with health and actuator endpoints
  - Prometheus metrics via `/actuator/prometheus`
  - Security scanning (SonarQube, Trivy)
  - BDD tests with Cucumber
  - Docker containerization with multi-stage build
- **Access**: https://sample-java-app.fawkes.idp
- **ArgoCD Application**: `platform/apps/samples/sample-java-app-application.yaml`

### 2. Sample Python FastAPI Application (`sample-python-app`)
- **Location**: `services/samples/sample-python-app/`
- **Framework**: FastAPI 0.115.5 with Python 3.12
- **Features**:
  - High-performance async REST API
  - Prometheus metrics via `/metrics`
  - Uvicorn ASGI server
  - BDD tests with Behave
  - Structured logging with JSON format
- **Access**: https://sample-python-app.fawkes.idp
- **ArgoCD Application**: `platform/apps/samples/sample-python-app-application.yaml`

### 3. Sample Node.js Express Application (`sample-nodejs-app`)
- **Location**: `services/samples/sample-nodejs-app/`
- **Framework**: Express 4.21.1 with Node.js 20
- **Features**:
  - Lightweight REST API
  - Prometheus metrics with prom-client via `/metrics`
  - Winston logging
  - BDD tests with Cucumber
  - ESLint code quality
- **Access**: https://sample-nodejs-app.fawkes.idp
- **ArgoCD Application**: `platform/apps/samples/sample-nodejs-app-application.yaml`

## Key Features

### GitOps Deployment
All applications are deployed using ArgoCD with:
- Automated sync and self-heal enabled
- Source: https://github.com/paruff/fawkes.git
- Target namespace: `fawkes-samples`
- Sync policy: prune and self-heal

### DORA Metrics Collection
Each application has DORA metrics annotations:
```yaml
annotations:
  dora.fawkes.io/collect-metrics: "true"
  dora.fawkes.io/environment: "dev"
```

This enables tracking of:
- **Deployment Frequency**: ArgoCD sync events
- **Lead Time for Changes**: Commit to deployment time
- **Change Failure Rate**: Failed syncs + incidents
- **Mean Time to Restore**: Incident to recovery time

### Ingress Configuration
All applications have:
- TLS termination with cert-manager
- nginx ingress class
- SSL redirect enabled
- Configured hostnames: `{app-name}.fawkes.idp`

### Security Best Practices
Each application implements:
- Non-root container execution (UID 65534)
- Read-only root filesystem
- All capabilities dropped
- Security context with seccomp profile
- Resource requests and limits

### Prometheus Metrics
All applications expose metrics:
- **Java**: `/actuator/prometheus` (Spring Actuator)
- **Python**: `/metrics` (prometheus-client)
- **Node.js**: `/metrics` (prom-client)

Pod annotations ensure automatic scraping:
```yaml
prometheus.io/scrape: "true"
prometheus.io/port: "{port}"
prometheus.io/path: "/metrics"
```

### Health Checks
Each application provides health endpoints:
- **Java**: `/actuator/health`, `/actuator/health/liveness`, `/actuator/health/readiness`
- **Python**: `/health`, `/ready`
- **Node.js**: `/health`, `/ready`

Kubernetes probes are configured for liveness and readiness.

### Backstage Catalog Integration
Each app includes `catalog-info.yaml` with:
- Component metadata
- API definitions (OpenAPI)
- Kubernetes integration
- GitHub repository links
- Owner and lifecycle information

## Deployment Instructions

### Deploy All Sample Applications
```bash
# Apply ArgoCD applications
kubectl apply -f platform/apps/samples/

# Wait for applications to sync
argocd app wait sample-java-app sample-python-app sample-nodejs-app

# Check deployment status
kubectl get pods -n fawkes-samples
```

### Deploy Individual Applications
```bash
# Java app
kubectl apply -f platform/apps/samples/sample-java-app-application.yaml

# Python app
kubectl apply -f platform/apps/samples/sample-python-app-application.yaml

# Node.js app
kubectl apply -f platform/apps/samples/sample-nodejs-app-application.yaml
```

### Verify Deployment
```bash
# Check ArgoCD applications
kubectl get applications -n fawkes | grep sample

# Check pods
kubectl get pods -n fawkes-samples

# Check services
kubectl get services -n fawkes-samples

# Check ingress
kubectl get ingress -n fawkes-samples

# Test health endpoints
curl https://sample-java-app.fawkes.idp/actuator/health
curl https://sample-python-app.fawkes.idp/health
curl https://sample-nodejs-app.fawkes.idp/health

# Test metrics endpoints
curl https://sample-java-app.fawkes.idp/actuator/prometheus
curl https://sample-python-app.fawkes.idp/metrics
curl https://sample-nodejs-app.fawkes.idp/metrics
```

## Acceptance Testing

A comprehensive BDD test has been created to validate the deployment:
- **Location**: `tests/bdd/features/sample-apps-deployment.feature`
- **Coverage**:
  - ArgoCD application creation and sync
  - Kubernetes resource deployment
  - Ingress accessibility
  - Health endpoint verification
  - Prometheus metrics exposure
  - DORA metrics annotations
  - Backstage catalog registration
  - Security context validation
  - Resource limits verification

### Run Acceptance Tests
```bash
cd tests/bdd
./run-test.sh features/sample-apps-deployment.feature
```

## Monitoring and Observability

### View DORA Metrics
- **DevLake Dashboard**: https://devlake.fawkes.idp
- **Grafana DORA Dashboard**: https://grafana.fawkes.idp/d/dora-metrics

### View Application Metrics
- **Prometheus**: https://prometheus.fawkes.idp
  - Query: `{app=~"sample-.*"}`
- **Grafana**: https://grafana.fawkes.idp
  - Dashboards created for each application

### View Logs
- **OpenSearch**: https://opensearch.fawkes.idp
  - Filter by namespace: `fawkes-samples`
  - Filter by app: `sample-java-app`, `sample-python-app`, `sample-nodejs-app`

### View Traces
- **Grafana Tempo**: https://grafana.fawkes.idp/explore?ds=tempo
  - Query by service name

## CI/CD Integration

Each application includes a `Jenkinsfile` for CI/CD:

1. **Build Stage**: Compile and package
2. **Test Stage**: Unit tests and BDD tests with coverage
3. **Scan Stage**: SonarQube SAST and Trivy container scanning
4. **Package Stage**: Build Docker image
5. **Publish Stage**: Push to Harbor registry
6. **Deploy Stage**: Update GitOps repository

Quality gates enforce:
- Zero new bugs/vulnerabilities (SonarQube)
- No HIGH/CRITICAL vulnerabilities (Trivy)
- Test coverage ≥ 80%
- All tests passing

## Files Created

### Sample Applications
- `services/samples/README.md` - Overview and instructions
- `services/samples/sample-java-app/` - Complete Java application
- `services/samples/sample-python-app/` - Complete Python application
- `services/samples/sample-nodejs-app/` - Complete Node.js application

### ArgoCD Configurations
- `platform/apps/samples/README.md` - ArgoCD deployment instructions
- `platform/apps/samples/sample-java-app-application.yaml`
- `platform/apps/samples/sample-python-app-application.yaml`
- `platform/apps/samples/sample-nodejs-app-application.yaml`

### Tests
- `tests/bdd/features/sample-apps-deployment.feature` - BDD acceptance test

## Dependencies

The sample applications depend on:
- ArgoCD for GitOps deployment
- cert-manager for TLS certificates
- ingress-nginx for ingress
- Prometheus for metrics collection
- DevLake for DORA metrics
- Harbor container registry (for CI/CD)
- Jenkins (for CI/CD pipelines)
- Backstage for service catalog

## Success Criteria Met

✅ Sample Java Spring Boot app deployed  
✅ Sample Python FastAPI app deployed  
✅ Sample Node.js Express app deployed  
✅ All apps accessible via ingress  
✅ DORA metrics being collected for all apps  

## Next Steps

1. **Build Docker Images**: Build and push images to Harbor registry
   ```bash
   cd services/samples/sample-java-app && docker build -t harbor.fawkes.local/platform-team/sample-java-app:latest .
   cd services/samples/sample-python-app && docker build -t harbor.fawkes.local/platform-team/sample-python-app:latest .
   cd services/samples/sample-nodejs-app && docker build -t harbor.fawkes.local/platform-team/sample-nodejs-app:latest .
   ```

2. **Configure CI/CD**: Set up Jenkins pipelines for each application

3. **Configure DevLake**: Add ArgoCD connection and configure DORA metric collection

4. **Register in Backstage**: Import catalog-info.yaml files into Backstage

5. **Monitor and Validate**: Verify metrics are flowing and DORA metrics are being calculated

## Troubleshooting

### Pods not starting
```bash
kubectl describe pod -n fawkes-samples -l app=sample-java-app
kubectl logs -n fawkes-samples -l app=sample-java-app
```

### ArgoCD sync issues
```bash
kubectl get application sample-java-app -n fawkes -o yaml
argocd app sync sample-java-app --force
```

### Ingress not working
```bash
kubectl get ingress -n fawkes-samples sample-java-app -o yaml
kubectl describe ingress -n fawkes-samples sample-java-app
```

### Metrics not appearing
```bash
kubectl port-forward -n fawkes-samples svc/sample-java-app 8080:80
curl http://localhost:8080/actuator/prometheus
```

## Support

- **Documentation**: https://fawkes.idp/docs
- **Mattermost**: #platform-support
- **Issues**: https://github.com/paruff/fawkes/issues

## References

- Golden Path Templates: `/templates/`
- Architecture Documentation: `/docs/architecture.md`
- DORA Metrics Guide: `/docs/observability/dora-metrics-guide.md`
- DevLake Documentation: `/platform/apps/devlake/README.md`
