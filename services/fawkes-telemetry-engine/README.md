# Fawkes Telemetry Engine

One of the two domain monoliths ([ADR-039](../../docs/adr/ADR-039-monolith-layout.md)).
It serves only `/health` and `/metrics` so far. Services such as `dora-metrics`
move in under `app/<name>/`, mounted at `/<service-name>`.

## Test

```bash
cd services/fawkes-telemetry-engine
pip install -r requirements-dev.txt
pytest tests/
```

The shared package `fawkes_common` is not installed. Tests find it through
`pythonpath` in `pyproject.toml`; point your editor at `services/common` too.

## Build and run

From the repository root:

```bash
docker build -f services/fawkes-telemetry-engine/Dockerfile -t fawkes-telemetry-engine:dev services/
docker run --rm -p 8000:8000 fawkes-telemetry-engine:dev
```
