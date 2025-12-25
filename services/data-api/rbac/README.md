# Hasura RBAC Configuration

This directory contains Role-Based Access Control (RBAC) configurations for the Hasura GraphQL API.

## Overview

Hasura provides fine-grained access control at multiple levels:

- **Row-level security**: Filter rows based on user attributes
- **Column-level security**: Hide sensitive columns per role
- **Operation-level security**: Control insert/update/delete operations
- **Query depth limits**: Prevent complex queries from overwhelming the system
- **Rate limiting**: Throttle requests per role

## Roles

### Admin Role
- **Access**: Full access to all data and operations
- **Use case**: Platform administrators, DevOps team
- **Rate limit**: 10,000 requests/minute

### Developer Role
- **Access**: Read/write to most tables, filtered by team ownership
- **Use case**: Application developers, engineers
- **Rate limit**: 1,000 requests/minute

### Viewer Role
- **Access**: Read-only access to non-sensitive data
- **Use case**: Product managers, stakeholders, reporting tools
- **Rate limit**: 100 requests/minute

### Anonymous Role
- **Access**: Very limited read access to public data
- **Use case**: Public documentation, unauthenticated API access
- **Rate limit**: 10 requests/minute

## Session Variables

Hasura uses session variables for authorization:

- `X-Hasura-Role`: User's role (admin, developer, viewer, anonymous)
- `X-Hasura-User-Id`: Unique user identifier
- `X-Hasura-Team-Id`: User's team identifier
- `X-Hasura-Allowed-Teams`: JSON array of teams user can access

These are typically set by an authentication service (e.g., Backstage, OAuth).

## Permission Structure

```yaml
table: <table_name>
role: <role_name>
permission:
  columns: [col1, col2, ...]       # Which columns can be accessed
  filter: { ... }                   # Row-level filter (WHERE clause)
  check: { ... }                    # Insert/update validation
  allow_aggregations: true/false    # Allow count/sum/avg queries
  limit: N                          # Max rows returned
```

## Example Permissions

### VSM Work Items

#### Admin Role
```yaml
table: work_items
role: admin
select:
  columns: '*'  # All columns
  filter: {}    # No filter, see all rows
  allow_aggregations: true
```

#### Developer Role
```yaml
table: work_items
role: developer
select:
  columns:
    - id
    - title
    - type
    - status
    - current_stage_id
    - created_at
    - updated_at
    - team
  filter:
    _or:
      - team: { _eq: "X-Hasura-Team-Id" }
      - team: { _in: "X-Hasura-Allowed-Teams" }
  allow_aggregations: true

insert:
  columns:
    - title
    - type
    - status
    - team
  check:
    team: { _eq: "X-Hasura-Team-Id" }

update:
  columns:
    - title
    - status
    - current_stage_id
  filter:
    team: { _eq: "X-Hasura-Team-Id" }
```

#### Viewer Role
```yaml
table: work_items
role: viewer
select:
  columns:
    - id
    - title
    - type
    - status
    - current_stage_id
    - created_at
    - updated_at
  filter:
    _or:
      - team: { _eq: "X-Hasura-Team-Id" }
      - team: { _in: "X-Hasura-Allowed-Teams" }
  allow_aggregations: true
  limit: 100
```

### Backstage Catalog

#### Admin Role
```yaml
table: catalog_entities
role: admin
select:
  columns: '*'
  filter: {}
  allow_aggregations: true
```

#### Developer Role
```yaml
table: catalog_entities
role: developer
select:
  columns: '*'
  filter:
    _or:
      - spec: { owner: { _eq: "X-Hasura-Team-Id" } }
      - metadata: { visibility: { _eq: "public" } }
  allow_aggregations: true
```

#### Viewer Role
```yaml
table: catalog_entities
role: viewer
select:
  columns:
    - entity_id
    - entity_ref
    - kind
    - namespace
    - name
    - metadata
    - spec
  filter:
    metadata: { visibility: { _eq: "public" } }
  allow_aggregations: false
  limit: 100
```

### DORA Metrics

#### Admin Role
```yaml
table: deployments
role: admin
select:
  columns: '*'
  filter: {}
  allow_aggregations: true
```

#### Developer Role
```yaml
table: deployments
role: developer
select:
  columns:
    - id
    - name
    - environment
    - status
    - started_date
    - finished_date
    - result
  filter:
    _or:
      - team: { _eq: "X-Hasura-Team-Id" }
      - environment: { _in: ["dev", "staging"] }
  allow_aggregations: true
```

#### Viewer Role
```yaml
table: deployments
role: viewer
select:
  columns:
    - id
    - name
    - environment
    - status
    - started_date
    - finished_date
  filter:
    environment: { _in: ["dev", "staging", "production"] }
  allow_aggregations: true
  limit: 1000
```

## Column-Level Security

Sensitive columns can be hidden from certain roles:

```yaml
# Hide internal columns from non-admin roles
table: work_items
role: viewer
select:
  columns:
    - id
    - title
    - status
    # Note: internal_notes, cost_estimate are excluded
```

## Query Depth Limiting

Configure in Hasura environment:

```yaml
api_limits:
  depth_limit:
    global: 10
    per_role:
      admin: 20
      developer: 10
      viewer: 5
      anonymous: 3
```

Prevents deeply nested queries that could cause performance issues.

## Rate Limiting

Configured per role in Hasura deployment:

```yaml
rate_limit:
  global:
    max_req_per_min: 1000
    unique_params: IP

  per_role:
    admin:
      max_req_per_min: 10000
    developer:
      max_req_per_min: 1000
    viewer:
      max_req_per_min: 100
    anonymous:
      max_req_per_min: 10
```

## Node Limits

Limit total nodes (rows) returned across all queries in a single request:

```yaml
node_limit:
  global: 1000
  per_role:
    admin: 10000
    developer: 5000
    viewer: 1000
    anonymous: 100
```

## Applying Permissions

### Via Console

1. Navigate to http://hasura.local/console
2. Go to "Data" -> Select table
3. Click "Permissions" tab
4. Configure permissions for each role

### Via Metadata

1. Edit permission YAML files in this directory
2. Apply metadata:
   ```bash
   hasura metadata apply --endpoint http://hasura.local --admin-secret <secret>
   ```

### Via API

```bash
curl http://hasura.local/v1/metadata \
  -H "x-hasura-admin-secret: <secret>" \
  -H "Content-Type: application/json" \
  -d '{
    "type": "pg_create_select_permission",
    "args": {
      "table": "work_items",
      "source": "vsm",
      "role": "developer",
      "permission": {
        "columns": ["id", "title", "status"],
        "filter": {
          "team": {"_eq": "X-Hasura-Team-Id"}
        }
      }
    }
  }'
```

## Testing Permissions

### Test as Different Roles

```bash
# As admin
curl http://hasura.local/v1/graphql \
  -H "x-hasura-admin-secret: <secret>" \
  -H "x-hasura-role: admin" \
  -d '{"query": "{ workItems { id title } }"}'

# As developer
curl http://hasura.local/v1/graphql \
  -H "x-hasura-admin-secret: <secret>" \
  -H "x-hasura-role: developer" \
  -H "x-hasura-team-id: platform-team" \
  -d '{"query": "{ workItems { id title } }"}'

# As viewer
curl http://hasura.local/v1/graphql \
  -H "x-hasura-admin-secret: <secret>" \
  -H "x-hasura-role: viewer" \
  -H "x-hasura-team-id: platform-team" \
  -d '{"query": "{ workItems { id title } }"}'
```

### Verify Row-Level Security

```bash
# Should only return work items for the specified team
curl http://hasura.local/v1/graphql \
  -H "x-hasura-admin-secret: <secret>" \
  -H "x-hasura-role: developer" \
  -H "x-hasura-team-id: team-alpha" \
  -d '{"query": "{ workItems { id title team } }"}'
```

## Security Best Practices

1. **Principle of Least Privilege**: Give roles only the access they need
2. **Row-Level Security**: Always filter by ownership (team, user, org)
3. **Hide Sensitive Columns**: Don't expose internal IDs, secrets, PII unnecessarily
4. **Rate Limiting**: Prevent abuse with appropriate limits
5. **Audit Logs**: Enable query logging for sensitive operations
6. **Regular Reviews**: Review and update permissions as requirements change

## Common Patterns

### Team-Based Access
```yaml
filter:
  team: { _eq: "X-Hasura-Team-Id" }
```

### Multi-Team Access
```yaml
filter:
  team: { _in: "X-Hasura-Allowed-Teams" }
```

### Owner-Based Access
```yaml
filter:
  created_by: { _eq: "X-Hasura-User-Id" }
```

### Public + Owned
```yaml
filter:
  _or:
    - visibility: { _eq: "public" }
    - owner: { _eq: "X-Hasura-User-Id" }
```

### Environment-Based Access
```yaml
filter:
  _or:
    - environment: { _in: ["dev", "staging"] }
    - _and:
        - environment: { _eq: "production" }
        - team: { _eq: "X-Hasura-Team-Id" }
```

## Troubleshooting

### Permission Denied Errors

Check:
1. Correct role header is sent
2. Session variables are set correctly
3. Row-level filter allows access
4. Column is included in allowed columns

### Rate Limit Exceeded

Check:
1. Current rate limit for role
2. Consider upgrading role or requesting limit increase
3. Implement client-side caching

## References

- [Hasura Authorization](https://hasura.io/docs/latest/auth/authorization/)
- [Row Level Security](https://hasura.io/docs/latest/auth/authorization/permissions/)
- [API Limits](https://hasura.io/docs/latest/security/api-limits/)
- [Session Variables](https://hasura.io/docs/latest/auth/authorization/roles-variables/)
