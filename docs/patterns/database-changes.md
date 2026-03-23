# Database Change Management Pattern

Database schema changes are one of the highest-risk activities in software delivery.
Without disciplined practices, schema migrations can cause downtime, data corruption,
or deployment rollback failures. This pattern describes how Fawkes manages database
changes safely and continuously.

## Core Principles

**All schema changes are code** — Migrations live in version control alongside
application code. Every change is reviewed, tested, and deployed through CI/CD.

**Forward-only migrations** — Write migrations to roll forward, not backward. If a
migration causes problems, write a new migration to fix it rather than rolling back
the schema.

**Backward-compatible changes** — Design migrations so the old application version
continues to work during a rolling deployment. This enables zero-downtime deployments.

## Backward-Compatibility Techniques

| Scenario | Safe Approach |
|----------|--------------|
| Add a column | Add as nullable with a default value |
| Rename a column | Add new column → backfill → update app → remove old |
| Drop a column | Stop reading it → deploy → remove column |
| Add a table | Always safe — old code ignores it |
| Change column type | Add new column → migrate data → swap references |

## Tools

**Flyway** (Java/Spring) — Versioned SQL migrations in `src/main/resources/db/migration/`.
Flyway tracks applied migrations in a `flyway_schema_history` table.

**Alembic** (Python/SQLAlchemy) — Auto-generates migration scripts from model changes.
Always review generated scripts before committing.

## CI Integration

```yaml
# Run migrations in CI before integration tests
- name: Run migrations
  run: |
    flyway -url=$DB_URL -user=$DB_USER -password=$DB_PASS migrate
```

Migrations are also applied as a Kubernetes init container before the application pod
starts, ensuring the schema is current before any traffic is served.

## See Also

- [Continuous Integration Pattern](continuous-integration.md)
- [Continuous Delivery Pattern](continuous-delivery.md)
- [Architecture Overview](../architecture.md)
