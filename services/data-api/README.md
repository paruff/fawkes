# Data API

Provides data access layer schemas and RBAC configuration for Fawkes platform services.

## Contents

- `schema/` — Database schema definitions
- `rbac/` — Role-based access control configuration

## AI-Readiness Checklist

A module is "AI-ready" when agents can work on it reliably. Track any gaps as GitHub issues.
See [AGENTS.md §11](../../AGENTS.md) for full context.

- [ ] Type hints on all public functions
- [ ] Docstrings on all public classes and functions
- [ ] Tests exist and are green before AI adds to them
- [ ] Module is single-purpose (not a God class/file)
- [ ] Clear, contextual error messages (no bare `raise Exception`)
- [ ] Module is covered by BDD scenarios in `tests/bdd/`
