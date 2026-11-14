# Pin survey: Python dependencies in `services/`

Read at commit `269b4e2e` on 2026-11-14. This is read-only input to the
monolith-layout ADR (issue #2299 step 2). It is not a decision.

## Scope

- Service directories under `services/`: 20 (the file `services/location.yaml` is not a service).
- Directories with a `requirements.txt`: 18. These are the only files in the tables below.
- Directories with no `requirements.txt`: `data-api`, `samples`.
  `data-api` has no Python. `samples` has no file of its own; its one
  requirements file is nested (see below).
- `-r` and `-e` includes, option lines and unparsed lines skipped: none.
- Duplicate package lines inside one file: none.

Other dependency files that exist and are **not** in the tables:

- `requirements-dev.txt` in 16 directories: `ai-code-review`, `analytics-dashboard`, `anomaly-detection`, `devex-survey-automation`, `discovery-metrics`, `experimentation`, `feedback`, `feedback-bot`, `feedback-cli`, `friction-bot`, `friction-cli`, `insights`, `nps`, `smart-alerting`, `space-metrics`, `vsm`. Not present in `data-api`, `dora-metrics`, `mcp-k8s-server`, `samples`.
- `services/samples/sample-python-app/requirements.txt` and its
  `requirements-dev.txt`. Nested one level down, so excluded.
- `services/friction-cli/setup.py` and `services/feedback-cli/setup.py`, each
  with `install_requires` of `click`, `requests`, `rich`, `pydantic` and
  `pyyaml` as `>=` lower bounds. Excluded.
- No `pyproject.toml` or `Pipfile` was found.

## Grouping

Groups come from `plan.md` (decision D3 and the wave table under "Order"). The
plan does not state a monolith for `samples`. `data-api` and `mcp-k8s-server`
are "still open under D3 (#2301)".

| Group | Services |
|---|---|
| Telemetry engine | `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `anomaly-detection`, `smart-alerting`, `space-metrics`, `dora-metrics` |
| DevEx service | `friction-bot`, `feedback`, `feedback-bot`, `nps`, `devex-survey-automation`, `ai-code-review`, `vsm` |
| Stay command-line clients (D3) | `friction-cli`, `feedback-cli` |
| Open under D3 (#2301) | `data-api` (no `requirements.txt`), `mcp-k8s-server` |
| Not stated in plan.md | `samples` (no `requirements.txt`) |

## Table: telemetry engine

| package | insights | discovery-metrics | analytics-dashboard | experimentation | anomaly-detection | smart-alerting | space-metrics | dora-metrics |
|---|---|---|---|---|---|---|---|---|
| alembic | ==1.13.1 |  |  |  |  |  | ==1.13.3 |  |
| asyncpg |  |  |  |  |  |  | ==0.30.0 |  |
| croniter |  |  |  |  |  | ==2.0.1 |  |  |
| fastapi | ==0.115.5 | ==0.109.0 | ==0.104.1 | ==0.115.0 | ==0.115.5 | ==0.141.1 | ==0.115.0 | ==0.115.0 |
| greenlet |  |  |  |  |  |  | ==3.1.1 |  |
| httpx | ==0.25.2 |  | ==0.25.2 | ==0.27.2 | ==0.27.0 | ==0.28.1 | ==0.27.2 |  |
| numpy |  |  |  | ==2.1.3 | ==1.26.4 |  |  |  |
| opentelemetry-api | ==1.28.2 |  |  |  | ==1.28.2 |  |  |  |
| opentelemetry-instrumentation-fastapi | ==0.49b2 |  |  |  | ==0.49b2 |  |  |  |
| opentelemetry-sdk | ==1.28.2 |  |  |  | ==1.28.2 |  |  |  |
| pandas |  |  |  |  | ==2.2.3 |  |  |  |
| prometheus-client | ==0.21.0 | ==0.19.0 | ==0.19.0 | ==0.21.0 | ==0.21.0 | ==0.25.0 | ==0.21.0 |  |
| prophet |  |  |  |  | ==1.1.6 |  |  |  |
| psycopg2-binary | ==2.9.10 | ==2.9.9 | ==2.9.9 | ==2.9.10 |  |  |  |  |
| pydantic | ==2.13.4 | ==2.13.4 | ==2.13.4 | ==2.13.4 | ==2.13.4 | ==2.13.4 | ==2.13.4 |  |
| pydantic-settings |  |  | ==2.5.2 | ==2.6.0 |  | ==2.1.0 | ==2.5.2 |  |
| python-dateutil | ==2.8.2 | ==2.8.2 | ==2.8.2 | ==2.9.0 |  | ==2.8.2 | ==2.9.0 |  |
| pyyaml | ==6.0.1 |  |  |  |  | ==6.0.1 |  |  |
| redis |  |  |  |  |  | ==5.0.1 |  |  |
| scikit-learn |  |  |  |  | ==1.5.2 |  |  |  |
| scipy |  |  |  | ==1.14.1 |  |  |  |  |
| sqlalchemy | ==2.0.36 | ==2.0.25 | ==2.0.23 | ==2.0.36 |  |  | ==2.0.35 |  |
| uvicorn | ==0.32.1 [standard] | ==0.27.0 [standard] | ==0.24.0 [standard] | ==0.32.0 [standard] | ==0.32.1 [standard] | ==0.40.0 [standard] | ==0.32.0 [standard] | ==0.32.0 [standard] |

## Table: DevEx service

| package | friction-bot | feedback | feedback-bot | nps | devex-survey-automation | ai-code-review | vsm |
|---|---|---|---|---|---|---|---|
| alembic |  |  |  |  | ==1.14.0 |  | ==1.13.1 |
| asyncpg |  | ==0.30.0 |  | ==0.30.0 | ==0.30.0 |  |  |
| fastapi | ==0.128.0 | ==0.115.5 | ==0.109.0 | ==0.115.5 | ==0.115.5 | ==0.115.5 | ==0.115.5 |
| httpx |  | ==0.28.1 | ==0.26.0 | ==0.27.2 | ==0.27.2 | ==0.27.0 | ==0.25.2 |
| jinja2 |  |  |  |  | ==3.1.6 |  |  |
| opentelemetry-api |  |  |  |  |  | ==1.28.2 | ==1.28.2 |
| opentelemetry-instrumentation-fastapi |  |  |  |  |  | ==0.49b2 | ==0.49b2 |
| opentelemetry-sdk |  |  |  |  |  | ==1.28.2 | ==1.28.2 |
| prometheus-client | ==0.25.0 | ==0.21.0 | ==0.19.0 | ==0.21.0 | ==0.21.0 | ==0.21.0 | ==0.21.0 |
| psycopg2-binary |  |  |  |  |  |  | ==2.9.10 |
| pydantic | ==2.12.5 | ==2.13.4 [email] | ==2.13.4 | ==2.13.4 [email] | ==2.13.4 [email] | ==2.13.4 | ==2.13.4 |
| pydantic-settings |  |  |  |  | ==2.6.1 |  |  |
| python-dateutil |  |  |  |  | ==2.9.0 |  | ==2.8.2 |
| python-multipart | ==0.0.32 |  | ==0.0.31 |  |  |  |  |
| pyyaml | ==6.0.1 |  |  |  |  |  | ==6.0.1 |
| requests | ==2.34.2 |  |  |  |  |  |  |
| sqlalchemy |  |  |  |  | ==2.0.36 |  | ==2.0.36 |
| uvicorn | ==0.40.0 [standard] | ==0.32.1 [standard] | ==0.27.0 [standard] | ==0.32.1 [standard] | ==0.32.1 [standard] | ==0.32.1 [standard] | ==0.32.1 [standard] |
| vadersentiment |  | ==3.3.2 | ==3.3.2 |  |  |  |  |

## Table: command-line clients and open items

Services with a `requirements.txt` that are in neither monolith group:
`feedback-cli` and `friction-cli` (stay command-line clients), and
`mcp-k8s-server` (open under D3).

| package | feedback-cli | friction-cli | mcp-k8s-server |
|---|---|---|---|
| click | ==8.4.1 | ==8.4.1 |  |
| fastapi |  |  | ==0.115.0 |
| kubernetes |  |  | ==29.0.0 |
| pydantic | ==2.12.5 | ==2.12.5 |  |
| pyyaml | ==6.0.1 | ==6.0.1 |  |
| requests | ==2.34.2 | ==2.34.2 |  |
| rich | ==13.7.0 | ==13.7.0 |  |
| uvicorn |  |  | ==0.30.0 |

## Disagreements

Packages listed by two or more services with more than one distinct specifier,
across all 18 files. Extras and markers are part of the specifier here, so
`==2.13.4` and `==2.13.4 [email]` count as two. Lowest and highest compare the
version number only.

| package | services | distinct specifiers | lowest | highest | specifiers |
|---|---|---|---|---|---|
| fastapi | 16 | 6 | `==0.104.1` | `==0.141.1` | `==0.104.1`, `==0.109.0`, `==0.115.0`, `==0.115.5`, `==0.128.0`, `==0.141.1` |
| uvicorn | 16 | 6 | `==0.24.0 [standard]` | `==0.40.0 [standard]` | `==0.24.0 [standard]`, `==0.27.0 [standard]`, `==0.30.0`, `==0.32.0 [standard]`, `==0.32.1 [standard]`, `==0.40.0 [standard]` |
| httpx | 12 | 5 | `==0.25.2` | `==0.28.1` | `==0.25.2`, `==0.26.0`, `==0.27.0`, `==0.27.2`, `==0.28.1` |
| pydantic-settings | 5 | 4 | `==2.1.0` | `==2.6.1` | `==2.1.0`, `==2.5.2`, `==2.6.0`, `==2.6.1` |
| sqlalchemy | 7 | 4 | `==2.0.23` | `==2.0.36` | `==2.0.23`, `==2.0.25`, `==2.0.35`, `==2.0.36` |
| alembic | 4 | 3 | `==1.13.1` | `==1.14.0` | `==1.13.1`, `==1.13.3`, `==1.14.0` |
| prometheus-client | 14 | 3 | `==0.19.0` | `==0.25.0` | `==0.19.0`, `==0.21.0`, `==0.25.0` |
| pydantic | 16 | 3 | `==2.12.5` | `==2.13.4` | `==2.12.5`, `==2.13.4`, `==2.13.4 [email]` |
| numpy | 2 | 2 | `==1.26.4` | `==2.1.3` | `==1.26.4`, `==2.1.3` |
| psycopg2-binary | 5 | 2 | `==2.9.9` | `==2.9.10` | `==2.9.10`, `==2.9.9` |
| python-dateutil | 8 | 2 | `==2.8.2` | `==2.9.0` | `==2.8.2`, `==2.9.0` |
| python-multipart | 2 | 2 | `==0.0.31` | `==0.0.32` | `==0.0.31`, `==0.0.32` |

Headline counts: `fastapi` is listed by 16 services with 6 distinct specifiers; `uvicorn` is listed by 16 services with 6 distinct specifiers; `httpx` is listed by 12 services with 5 distinct specifiers; `sqlalchemy` is listed by 7 services with 4 distinct specifiers.
The plan (F9) claims six, six, five and four.
These match the plan's claim.

## Not pinned exactly

Every entry in every `requirements.txt` is an exact `==` pin. No `>=`, `~=`, range or unpinned entries were found.

## Shared by all and by most

Counted per group over the services that have a `requirements.txt`.

**Telemetry engine** (8 services with a `requirements.txt`: `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `anomaly-detection`, `smart-alerting`, `space-metrics`, `dora-metrics`).

In every one of the 8: `fastapi`, `uvicorn`.

In at least two (service count):

- `alembic` (2): `insights`, `space-metrics`
- `fastapi` (8): `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `anomaly-detection`, `smart-alerting`, `space-metrics`, `dora-metrics`
- `httpx` (6): `insights`, `analytics-dashboard`, `experimentation`, `anomaly-detection`, `smart-alerting`, `space-metrics`
- `numpy` (2): `experimentation`, `anomaly-detection`
- `opentelemetry-api` (2): `insights`, `anomaly-detection`
- `opentelemetry-instrumentation-fastapi` (2): `insights`, `anomaly-detection`
- `opentelemetry-sdk` (2): `insights`, `anomaly-detection`
- `prometheus-client` (7): `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `anomaly-detection`, `smart-alerting`, `space-metrics`
- `psycopg2-binary` (4): `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`
- `pydantic` (7): `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `anomaly-detection`, `smart-alerting`, `space-metrics`
- `pydantic-settings` (4): `analytics-dashboard`, `experimentation`, `smart-alerting`, `space-metrics`
- `python-dateutil` (6): `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `smart-alerting`, `space-metrics`
- `pyyaml` (2): `insights`, `smart-alerting`
- `sqlalchemy` (5): `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `space-metrics`
- `uvicorn` (8): `insights`, `discovery-metrics`, `analytics-dashboard`, `experimentation`, `anomaly-detection`, `smart-alerting`, `space-metrics`, `dora-metrics`

**DevEx service** (7 services with a `requirements.txt`: `friction-bot`, `feedback`, `feedback-bot`, `nps`, `devex-survey-automation`, `ai-code-review`, `vsm`).

In every one of the 7: `fastapi`, `prometheus-client`, `pydantic`, `uvicorn`.

In at least two (service count):

- `alembic` (2): `devex-survey-automation`, `vsm`
- `asyncpg` (3): `feedback`, `nps`, `devex-survey-automation`
- `fastapi` (7): `friction-bot`, `feedback`, `feedback-bot`, `nps`, `devex-survey-automation`, `ai-code-review`, `vsm`
- `httpx` (6): `feedback`, `feedback-bot`, `nps`, `devex-survey-automation`, `ai-code-review`, `vsm`
- `opentelemetry-api` (2): `ai-code-review`, `vsm`
- `opentelemetry-instrumentation-fastapi` (2): `ai-code-review`, `vsm`
- `opentelemetry-sdk` (2): `ai-code-review`, `vsm`
- `prometheus-client` (7): `friction-bot`, `feedback`, `feedback-bot`, `nps`, `devex-survey-automation`, `ai-code-review`, `vsm`
- `pydantic` (7): `friction-bot`, `feedback`, `feedback-bot`, `nps`, `devex-survey-automation`, `ai-code-review`, `vsm`
- `python-dateutil` (2): `devex-survey-automation`, `vsm`
- `python-multipart` (2): `friction-bot`, `feedback-bot`
- `pyyaml` (2): `friction-bot`, `vsm`
- `sqlalchemy` (2): `devex-survey-automation`, `vsm`
- `uvicorn` (7): `friction-bot`, `feedback`, `feedback-bot`, `nps`, `devex-survey-automation`, `ai-code-review`, `vsm`
- `vadersentiment` (2): `feedback`, `feedback-bot`

## What this does not show

These were not checked:

- Transitive dependencies.
- What is installed in each image. Dockerfiles may install more, or pin base images differently.
- Whether any two pins are actually incompatible.

This survey does not recommend a version. That is the ADR's job.

## How this was produced

The script below reads each `services/*/requirements.txt` from the repo root
and builds the tables. The script itself is not committed. Names are
normalised per PEP 503 for grouping only.

```python
LINE = re.compile(r"^([A-Za-z0-9][A-Za-z0-9._-]*)\s*(\[[^\]]*\])?\s*([^;]*?)\s*(;.*)?$")
data = defaultdict(lambda: defaultdict(list))
skipped = []
dups = []
for d in dirs:
    p = f"services/{d}/requirements.txt"
    if not os.path.exists(p):
        continue
    for raw in open(p):
        l = re.sub(r"\s+#.*$", "", raw.strip())
        if not l or l.startswith("#"):
            continue
        if l.startswith("-"):
            skipped.append((d, l))
            continue
        m = LINE.match(l)
        if not m:
            skipped.append((d, "UNPARSED " + l))
            continue
        n = re.sub(r"[-_.]+", "-", m[1].lower())
        cell = (m[3].replace(" ", "") or "any") + (f" {m[2]}" if m[2] else "") + (f" {m[4].strip()}" if m[4] else "")
        data[n][d].append(cell)
cell = {n: {d: " + ".join(v) for d, v in s.items()} for n, s in data.items()}
for n, s in data.items():
    for d, v in s.items():
        if len(v) > 1:
            dups.append((d, n, v))
```
