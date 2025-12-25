# sample-python-app

Sample Python FastAPI application for testing

## Development

### Prerequisites

- Python 3.12+
- Docker
- kubectl

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run locally
uvicorn app.main:app --reload --port 8000

# Run tests
pytest tests/ -v

# Lint
black app/ tests/
flake8 app/ tests/
```

### API Documentation

Once running, visit:

- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Deployment

This service is deployed via GitOps using ArgoCD. Push to main branch to trigger deployment.

```bash
# Check deployment status
argocd app get sample-python-app

# Manual sync
argocd app sync sample-python-app
```

## Monitoring

- Metrics: https://grafana.fawkes.idp/d/sample-python-app
- Logs: https://opensearch.fawkes.idp
- Traces: https://grafana.fawkes.idp/explore?ds=tempo
