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