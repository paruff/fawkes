# Plan: psycopg2-binary 2.9.10 for Python 3.13

**Traces to:** #2328 (this PR) — dependency pin repair that restores the
service Test matrix; not a feature, so no separate intent/spec pair.

## Context

`services/analytics-dashboard` and `services/discovery-metrics` pin
`psycopg2-binary==2.9.9`. That release ships no cp313 wheels, so on the CI
runner (Python 3.13) pip compiles it from source and fails on
`_PyInterpreterState_Get` (removed in CPython 3.13). Every PR touching
`services/**` runs the service Test matrix, so the two jobs fail even when
the PR changes nothing in those services. `services/insights`,
`services/vsm` and `services/experimentation` already pin 2.9.10 and install
cleanly in the same runs.

## Changes

1. Bump `psycopg2-binary` 2.9.9 → 2.9.10 in
   `services/analytics-dashboard/requirements.txt` and
   `services/discovery-metrics/requirements.txt`.

No code changes: 2.9.10 is the same driver with cp313 wheels.

## Verification Strategy

| Criterion | Evidence | How |
| ------------------------------ | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| 2.9.9 fails on Python 3.13 | `uv pip install psycopg2-binary==2.9.9` in a real 3.13 venv → build failure | Reproduced locally before the bump (and twice in CI: #2278 on Nov 2, #2320) |
| 2.9.10 installs from a wheel | 11 cp313 wheels on PyPI; install succeeds in a 3.13 venv | `uv pip install psycopg2-binary==2.9.10` in the same venv |
| Both requirements files resolve | No dependency conflicts introduced | `uv pip compile <file> --python-version 3.13` for both services |
| CI matrix goes green | `Test (analytics-dashboard)` and `Test (discovery-metrics)` pass | Re-trigger #2320 / #2308 / #2278 after this merges |

## Follow-up

`extensions/data-platform/services/data-quality/requirements.txt` still pins
2.9.9 and is not installed by any workflow today; bump it when that pipeline
is wired up.
