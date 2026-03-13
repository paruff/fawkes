# MCP K8s Server (Inspector)

A tiny FastAPI service that lists pods in a namespace. Intended for in-cluster, read-only inspection.

## Local run

```bash
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8080
```

## Build & Run (Docker)

```bash
docker build -t ghcr.io/paruff/mcp-k8s-server:dev .
docker run --rm -p 8080:8080 ghcr.io/paruff/mcp-k8s-server:dev
```

## Endpoints

- GET `/healthz` – health probe
- GET `/pods?namespace=fawkes` – list pods

## Publish (GHCR)

```bash
# Login (requires `write:packages` PAT or use GitHub Actions)
echo "$GH_PAT" | docker login ghcr.io -u paruff --password-stdin

# Tag and push
VERSION=v0.1.0
docker build -t ghcr.io/paruff/mcp-k8s-server:$VERSION .
docker push ghcr.io/paruff/mcp-k8s-server:$VERSION
```

## AI-Readiness Checklist

A module is "AI-ready" when agents can work on it reliably. Track any gaps as GitHub issues.
See [AGENTS.md §11](../../AGENTS.md) for full context.

- [ ] Type hints on all public functions
- [ ] Docstrings on all public classes and functions
- [ ] Tests exist and are green before AI adds to them
- [ ] Module is single-purpose (not a God class/file)
- [ ] Clear, contextual error messages (no bare `raise Exception`)
- [ ] Module is covered by BDD scenarios in `tests/bdd/`
