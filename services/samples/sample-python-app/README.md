# ${{ values.name }}

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
uvicorn app.main:app --reload --port ${{ values.port }}

# Run tests
pytest tests/ -v

# Lint
black app/ tests/
flake8 app/ tests/
```

### API Documentation

Once running, visit:
- Swagger UI: http://localhost:${{ values.port }}/docs
- ReDoc: http://localhost:${{ values.port }}/redoc

## Deployment

This service is deployed via GitOps using ArgoCD. Push to main branch to trigger deployment.

```bash
# Check deployment status
argocd app get ${{ values.name }}

# Manual sync
argocd app sync ${{ values.name }}
```

## Monitoring

- Metrics: https://grafana.fawkes.idp/d/${{ values.name }}
- Logs: https://opensearch.fawkes.idp
- Traces: https://grafana.fawkes.idp/explore?ds=tempo
