# Fawkes DevEx Service

One of the two domain monoliths ([ADR-039](../../docs/adr/ADR-039-monolith-layout.md)).
It serves only `/health` and `/metrics` so far. Services such as `friction-bot`
move in under `app/<name>/`, mounted at `/<service-name>`.

## Test

```bash
cd services/fawkes-devex-service
pip install -r requirements-dev.txt
pytest tests/
```

The shared package `fawkes_common` is not installed. Tests find it through
`pythonpath` in `pyproject.toml`; point your editor at `services/common` too.

## Build and run

From the repository root:

```bash
docker build -f services/fawkes-devex-service/Dockerfile -t fawkes-devex-service:dev services/
docker run --rm -p 8000:8000 fawkes-devex-service:dev
```
