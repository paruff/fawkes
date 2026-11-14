# ADR-039: Layout of the Two Domain Monoliths and `services/common`

> **Status:** Proposed. It becomes Accepted when the maintainer merges it; steps 4 to 9 of paruff/fawkes#2299 wait for that.
> **Date:** 2026-11-14
> **Author:** AI-assisted, awaiting approval by @paruff
> **DORA Capability:** Cap 5 — Working in Small Batches

## Context

`AGENTS.md` §5 says services are two domain monoliths, `fawkes-telemetry-engine`
and `fawkes-devex-service`, with shared code in `services/common/`. The repo
has neither: `services/` holds 20 directories, 18 with a `requirements.txt`
([pin survey](../ai-sdlc/path-to-beta/pin-survey.md)). The
[path-to-Beta plan](../ai-sdlc/path-to-beta/plan.md) moves them in phases, and
its phase 1 can't write a line of `services/common/` until six questions have
one answer each. This ADR answers them.

Facts the answers rest on, read from `main` at `269b4e2e` on 2026-11-14:

- Every service is built with its own directory as the Docker build context
  (`COPY app/ ./app/`). `reusable-python-service-golden-path.yml` hard-codes
  `context: services/<service-name>`.
- `service-python-tests.yml` finds a directory by its `requirements.txt`, then
  runs `pip install -r requirements.txt`, `ruff check .` and `pytest tests/`
  from inside it.
- Service directory names have hyphens (`dora-metrics`, `space-metrics`) and
  can't be imported as written.
- Services that the plan puts in the same monolith register the same routes
  today: `discovery-metrics` and `experimentation` both serve
  `/api/v1/experiments/{experiment_id}`; `devex-survey-automation` and `nps`
  both serve `/survey/{token}` and `/api/v1/survey/{token}/submit`; `feedback`
  and `feedback-bot` both serve `POST /api/v1/feedback`. Fourteen services
  serve `GET /health` and six serve `GET /metrics`.
- No service has an `alembic/` directory. Four pin `alembic` in
  `requirements.txt` (`devex-survey-automation`, `insights`, `space-metrics`,
  `vsm`).
- The services pin six versions of `fastapi`, six of `uvicorn`, five of
  `httpx` and four of `sqlalchemy`. Every pin is exact (ADR-034).

## Decision

We will lay the monoliths out as below.

```text
services/
├── common/
│   ├── fawkes_common/          # the importable package: config.py, database.py, metrics.py, logging.py
│   ├── tests/
│   └── requirements.txt        # exact pins, only what fawkes_common imports
├── fawkes-telemetry-engine/
│   ├── app/
│   │   ├── main.py             # one FastAPI app: /health, /metrics, and one router per module
│   │   └── <module>/           # e.g. dora_metrics/, space_metrics/, each with its own migrations/
│   ├── tests/
│   ├── pyproject.toml          # [tool.pytest.ini_options] pythonpath = [".", "../common"]
│   ├── requirements.txt        # one set of exact pins for the whole monolith
│   └── Dockerfile
└── fawkes-devex-service/       # the same shape
```

1. **Importing `common`.** The package is `fawkes_common`, imported as
   `from fawkes_common.config import ...`. It is not installed. Tests find it
   through `pythonpath` in each monolith's `pyproject.toml`; images get it
   with a `COPY`. No wheel, no editable install, no private index.
2. **Docker build context.** The context is `services/`, and the Dockerfile
   stays in the monolith's directory:
   `docker build -f services/fawkes-telemetry-engine/Dockerfile services/`.
   The Dockerfile copies `common/fawkes_common` and its own `app/`.
3. **Module names.** A migrated service becomes `app/<name>/`, where `<name>`
   is its directory name with each hyphen replaced by an underscore
   (`dora-metrics` → `app/dora_metrics/`). Nothing else about the name changes.
4. **URL paths.** Every module's routes are mounted under `/<service-name>`,
   with the hyphen kept (`/dora-metrics/...`, `/nps/survey/{token}`). The
   monolith owns `/health`, `/ready` and `/metrics`. Old root-level paths do
   not keep working: the three collisions above make that impossible for six
   services, and one rule for all is easier to check than a per-service
   exception. The PR that migrates a service also changes its callers.
5. **Pins.** Each monolith has one `requirements.txt`. For a package its
   member services pin today, it starts at the highest version any member
   pins. `services/common/requirements.txt` may only name a package at the
   version both monoliths pin, and a test in `services/common/tests/` fails
   when it doesn't.
6. **Migrations.** Each module that owns tables has `app/<name>/migrations/`
   (its own Alembic environment) and its own version table,
   `alembic_version_<name>`. One database per monolith, as the plan says. A
   module's history starts with a baseline revision written when it is
   migrated, since no service has revisions today.

## Rationale

- **No packaging step means nothing new to break.** `service-python-tests.yml`
  already runs `pytest tests/` from the service directory, so a `pythonpath`
  entry makes `fawkes_common` importable with no workflow change, which
  phase 1 is not allowed to make (#2299, "Do not").
- **A prefix per module is the only rule that survives the collisions.**
  Keeping root paths would need a decision for each of the three pairs, and a
  seventh service would need another.
- **One pin set per monolith is what "one process" means.** Two modules can't
  import two versions of `sqlalchemy`. Starting from the highest pin in use
  moves nothing forward that some service doesn't already run.
- **A version table per module keeps migrations independent.** Modules arrive
  one PR at a time (phase 4); a shared history would make each arrival rewrite
  the others' revision chain.

## Consequences

**Positive:**

- Steps 4 to 9 of #2299 have a fixed target, and each new directory is tested
  by CI as soon as it has a `requirements.txt`.
- A route collision between modules can't happen, and a test over
  `app.routes` can assert that every non-monolith route starts with a module
  prefix.

**Negative:**

- The build context changes from the service directory to `services/`.
  `reusable-python-service-golden-path.yml` passes
  `context: services/<service-name>`, so building a monolith through it needs
  a new input. That is a workflow edit, which needs approval (`AGENTS.md` §6),
  and it belongs to phase 5, not phase 1. Until then the monoliths build with
  a plain `docker build`.
- Every caller of a migrated service changes its URL. The plan found four
  service-to-service calls (F4), plus the two command-line clients and the
  bots. Each is changed in the PR that migrates the service it calls.
- "Highest pin in use" can combine versions that no single service has run
  together. The monolith's own tests are the check; where they fail, the
  migrating PR lowers the pin and says why.
- `pythonpath` makes the import work in tests but an editor needs the same
  hint. Each monolith's README says so.

**Agent instructions:**

- Import shared code as `from fawkes_common.<module> import ...`. Never copy
  a helper into a monolith.
- Add to `services/common/` only what already exists in two or more services
  (#2299). No auth helper until a service needs one; that is `goal` work.
- A new module is `app/<directory_name_with_underscores>/`, mounted at
  `/<directory-name>`.
- Don't add a package to `services/common/requirements.txt` at a version that
  differs from either monolith's pin.

## Alternatives Considered

| Option | Why not |
|---|---|
| Install `common` as a package (`pip install ../common`, or `-e`) | Needs a `pyproject.toml` build, and a `-e ../common` line in `requirements.txt` breaks `pip install -r` inside the image, where `..` isn't the repo |
| Build context stays the monolith's directory, with `common` copied in by a script before the build | A generated copy drifts from its source, and the image no longer builds from a clean checkout with one command |
| Keep each service's root-level paths | Three pairs of services in the same monolith already register the same route |
| One Alembic history per monolith | Modules migrate one PR at a time; each would have to rebase the shared chain |
| Lowest pin in use, not highest | Moves most services backwards, onto versions with known fixes missing |

## Related

- Supersedes: none. Follows ADR-034 (exact pins).
- Plan: [`docs/ai-sdlc/path-to-beta/plan.md`](../ai-sdlc/path-to-beta/plan.md), phase 1; decisions D2 and D3.
- Input: [`pin-survey.md`](../ai-sdlc/path-to-beta/pin-survey.md) (paruff/fawkes#2317).
- Issues: paruff/fawkes#2299, paruff/fawkes#2116.
