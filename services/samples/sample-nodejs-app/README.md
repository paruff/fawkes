# sample-nodejs-app

Sample Node.js Express application for testing

## Overview

This is a Node.js Express microservice following the Fawkes Golden Path. It includes:
- ✅ REST API with health, ready, and info endpoints
- ✅ Prometheus metrics
- ✅ Docker containerization
- ✅ Kubernetes manifests
- ✅ CI/CD pipeline via Jenkins
- ✅ Unit tests with Jest and BDD tests with Cucumber
- ✅ Security scanning with SonarQube and Trivy

## Prerequisites

- Node.js 20 LTS
- npm
- Docker
- kubectl (for deployment)

## Local Development

### Install

```bash
npm install
```

### Run

```bash
# Run in development mode with auto-reload
npm run dev

# Or run in production mode
npm start
```

The service will start on `http://localhost:3000`

### Test

```bash
# Run unit tests
npm test

# Run tests in watch mode
npm run test:watch

# Run BDD tests
npm run test:bdd

# Lint code
npm run lint
npm run lint:fix
```

## API Endpoints

- `GET /` - Root endpoint with service info
- `GET /health` - Health check endpoint
- `GET /ready` - Readiness check endpoint
- `GET /info` - Service information
- `GET /metrics` - Prometheus metrics

## Docker

### Build Image

```bash
docker build -t sample-nodejs-app:latest .
```

### Run Container

```bash
docker run -p 3000:3000 sample-nodejs-app:latest
```

## Deployment

This service is deployed via GitOps using ArgoCD.

### Deploy to Kubernetes

```bash
# Apply manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get deployment sample-nodejs-app
kubectl get pods -l app=sample-nodejs-app
```

### ArgoCD

```bash
# Sync with ArgoCD
argocd app sync sample-nodejs-app

# Check status
argocd app get sample-nodejs-app
```

## Monitoring

- **Metrics**: https://grafana.fawkes.idp/d/sample-nodejs-app
- **Logs**: https://opensearch.fawkes.idp
- **Traces**: https://grafana.fawkes.idp/explore?ds=tempo
- **Health**: https://sample-nodejs-app.fawkes.idp/health

## CI/CD Pipeline

The Jenkins pipeline runs on every commit to `main`:

1. **Build**: Install dependencies
2. **Test**: Run unit and BDD tests
3. **Scan**: SonarQube SAST and Trivy container scan
4. **Package**: Build Docker image
5. **Publish**: Push to Harbor registry
6. **Deploy**: Update GitOps repository

## Project Structure

```
.
├── src/
│   └── index.js            # Main application
├── tests/
│   ├── unit/
│   │   └── index.test.js   # Unit tests
│   └── bdd/
│       ├── features/
│       │   └── health.feature
│       └── step_definitions/
│           └── health_steps.js
├── k8s/
│   ├── deployment.yaml
│   ├── service.yaml
│   └── ingress.yaml
├── Dockerfile
├── Jenkinsfile
├── package.json
├── jest.config.js
└── catalog-info.yaml
```

## Support

- **Mattermost**: #platform-support
- **Documentation**: https://fawkes.idp/docs
- **Issues**: https://github.com/paruff/fawkes/issues
