# ADR-006: PostgreSQL for Data Persistence

## Status
**Accepted** - October 8, 2025

## Context

Fawkes platform components require a relational database for persistent data storage. Multiple components need databases: Backstage (service catalog), Mattermost (messages and boards), Jenkins (build metadata), SonarQube (code analysis), and custom services (DORA metrics, dojo progress). We need to choose a database that's reliable, performant, open source, and well-supported across our technology stack.

### Database Requirements Across Components

**Backstage**:
- Service catalog entities and relationships
- User preferences and settings
- Plugin data storage
- Search indexes
- Moderate write load, high read load

**Mattermost + Focalboard**:
- Messages, channels, users
- Project boards, cards, properties
- File metadata
- High write and read load
- Real-time updates

**DORA Metrics Service**:
- Build events, deployment events
- Historical metrics data
- Team aggregations
- Time-series queries
- Write-heavy, analytical reads

**Dojo Progress Tracking**:
- Learner progress, assessment scores
- Lab completion status
- Certification records
- Moderate write, frequent reads

**SonarQube**:
- Code analysis results
- Quality metrics history
- Security findings
- High write during scans, read for dashboards

**Jenkins** (optional, can use file system):
- Build metadata and history
- Job configurations
- Plugin data

### Requirements for Database

**Technical Requirements**:
- **ACID Compliance**: Data consistency and reliability
- **SQL Support**: Complex queries, joins, transactions
- **JSON Support**: Flexible schema for plugin data
- **Full-Text Search**: Search across catalog, messages, documentation
- **High Availability**: Replication, failover
- **Backup/Restore**: Point-in-time recovery
- **Performance**: Handle 1000+ concurrent connections
- **Scalability**: Vertical and horizontal scaling options

**Operational Requirements**:
- **Open Source**: Transparent, no licensing costs
- **Mature**: Production-proven, stable
- **Well-Documented**: Extensive documentation and community
- **Cloud-Native**: Works well in Kubernetes
- **Monitoring**: Prometheus metrics, logging integration
- **Security**: Encryption at rest and in transit, RBAC

**Integration Requirements**:
- Supported by Backstage, Mattermost, SonarQube, Jenkins
- Kubernetes Operator available
- Terraform provider for provisioning
- Helm charts for deployment
- Backup tools mature and reliable

### Forces at Play

**Technical Forces**:
- Multiple components need databases
- Could use single shared database or separate instances
- Need balance between operational simplicity and isolation
- Performance critical for developer experience

**Operational Forces**:
- Platform team capacity limited
- Need reliable backups and disaster recovery
- Monitoring and troubleshooting must be straightforward
- Upgrades should be low-risk

**Cost Forces**:
- Open source preferred (no licensing)
- Cloud-managed services convenient but expensive
- Self-hosted requires operational overhead
- Need cost-effective solution that scales

**Ecosystem Forces**:
- PostgreSQL has massive adoption in cloud-native space
- Most tools support PostgreSQL natively
- Large knowledge base and community
- Cloud providers offer managed PostgreSQL

## Decision

**We will use PostgreSQL as the standard relational database for Fawkes platform components.**

Specifically:
- **PostgreSQL 15+** (latest stable version)
- **CloudNativePG Operator** for Kubernetes-native management
- **Separate databases per component** (single cluster, multiple databases)
- **Automated backups** to S3/MinIO with point-in-time recovery
- **High Availability** configuration (primary + replica)
- **Connection pooling** via PgBouncer
- **Prometheus metrics** for monitoring
- **Cloud-managed option** available for production (AWS RDS, Azure Database, Google Cloud SQL)

### Rationale

1. **Industry Standard**: PostgreSQL is the most popular open source relational database, with massive adoption across cloud-native applications and platform tools

2. **Universal Compatibility**: All Fawkes components support PostgreSQL:
   - Backstage: Officially supported, recommended database
   - Mattermost: Full support, production-ready
   - Focalboard: Built-in support (uses Mattermost database)
   - SonarQube: Officially supported
   - Jenkins: Supported via plugins
   - Custom services: Excellent language support (Go, Python, TypeScript)

3. **Advanced Features**:
   - **JSONB**: Flexible schema for plugin data, semi-structured content
   - **Full-Text Search**: Built-in search without external tools
   - **CTEs and Window Functions**: Complex analytical queries
   - **LISTEN/NOTIFY**: Real-time event notifications
   - **Foreign Data Wrappers**: Access external data sources
   - **Extensions**: PostGIS, pg_stat_statements, timescaledb

4. **ACID Compliance**: 
   - Strong consistency guarantees
   - Transaction support
   - Data integrity and reliability
   - Critical for catalog, messaging, metrics

5. **Performance**:
   - Excellent query optimizer
   - Efficient indexing (B-tree, GiST, GIN, BRIN)
   - Parallel queries
   - Materialized views for aggregations
   - Connection pooling support

6. **High Availability**: 
   - Streaming replication (synchronous and asynchronous)
   - Automatic failover
   - Point-in-time recovery
   - WAL archiving for backups

7. **Cloud-Native**:
   - CloudNativePG operator for Kubernetes
   - Runs well in containers
   - Horizontal scaling via read replicas
   - Kubernetes-native backup solutions

8. **Mature and Stable**:
   - 35+ years of development
   - Production-proven at massive scale
   - Backward compatibility commitment
   - Predictable release cycle

9. **Excellent Tooling**:
   - pgAdmin (GUI administration)
   - psql (powerful CLI)
   - pg_dump/pg_restore (backup/restore)
   - Prometheus exporters (monitoring)
   - Migration tools (Flyway, Liquibase)

10. **Large Community**:
    - Extensive documentation
    - Active mailing lists and forums
    - Thousands of tutorials and examples
    - Commercial support available (EnterpriseDB, Crunchy Data)

11. **Open Source**:
    - PostgreSQL License (permissive, like MIT)
    - Community-driven development
    - No vendor lock-in
    - Free forever

12. **Security**:
    - SSL/TLS encryption
    - Row-level security
    - SCRAM authentication
    - Role-based access control
    - Audit logging

## Consequences

### Positive

✅ **Single Database Technology**: One database to learn, operate, monitor

✅ **Universal Support**: All platform components support PostgreSQL natively

✅ **Advanced Features**: JSONB, full-text search, CTEs meet all requirements

✅ **High Availability**: Built-in replication and failover

✅ **Performance**: Excellent for both transactional and analytical workloads

✅ **Cloud-Native**: Kubernetes operator provides native management

✅ **Backup & Recovery**: Mature tools, point-in-time recovery

✅ **Monitoring**: Prometheus exporters, excellent observability

✅ **Scalability**: Read replicas, connection pooling, sharding options

✅ **Large Community**: Easy to find help, examples, best practices

✅ **Open Source**: No licensing costs, transparent development

✅ **Operational Simplicity**: One database system reduces complexity

### Negative

⚠️ **Write Scalability**: Single primary for writes (read replicas for reads only)

⚠️ **Operational Overhead**: Requires backup, monitoring, upgrade management

⚠️ **Resource Usage**: ~200MB RAM minimum per database, can grow large

⚠️ **Vacuum Maintenance**: Requires periodic vacuum for performance

⚠️ **Index Bloat**: Indexes can bloat without maintenance

⚠️ **Learning Curve**: Advanced features require PostgreSQL expertise

⚠️ **Connection Limits**: Default 100 connections, requires pooling at scale

⚠️ **Replication Lag**: Async replication can have slight delays

### Neutral

◽ **Self-Hosted vs. Managed**: Can self-host or use cloud-managed services

◽ **Version Management**: Major upgrades require planning and testing

◽ **Storage Growth**: Need to monitor and manage storage capacity

### Mitigation Strategies

1. **Write Scalability**:
   - Use connection pooling (PgBouncer)
   - Optimize queries and indexes
   - Consider read replicas for reporting
   - Partition large tables if needed
   - Plan for vertical scaling

2. **Operational Overhead**:
   - Use CloudNativePG operator (automates backups, failover)
   - Implement automated monitoring and alerting
   - Document runbooks for common operations
   - Consider managed services for production (AWS RDS)
   - Regular automated backups

3. **Maintenance**:
   - Configure autovacuum appropriately
   - Monitor bloat with pg_stat_user_tables
   - Regular ANALYZE for query planning
   - Reindex periodically if needed
   - Schedule maintenance windows

4. **Connection Pooling**:
   - Deploy PgBouncer for connection pooling
   - Configure appropriate pool sizes
   - Use transaction pooling for most apps
   - Monitor connection usage

5. **Monitoring**:
   - Deploy postgres_exporter for Prometheus
   - Create Grafana dashboards
   - Alert on key metrics (connections, replication lag, disk usage)
   - Log slow queries for optimization

6. **Backup & Recovery**:
   - Automated daily backups with retention
   - WAL archiving for point-in-time recovery
   - Regular restore testing
   - Document recovery procedures
   - Backup to S3/MinIO with encryption

## Alternatives Considered

### Alternative 1: MySQL/MariaDB

**Pros**:
- Very popular, large community
- Good performance for read-heavy workloads
- MariaDB fully open source
- Wide adoption
- Familiar to many developers

**Cons**:
- **Weaker JSON Support**: JSON type less powerful than PostgreSQL JSONB
- **Limited Full-Text Search**: Not as robust as PostgreSQL
- **Fewer Advanced Features**: Less support for CTEs, window functions
- **Fragmentation**: MySQL (Oracle) vs. MariaDB (community) split
- **Less Cloud-Native**: Kubernetes operators less mature

**Reason for Rejection**: PostgreSQL's superior JSON support, full-text search, and advanced SQL features better fit Fawkes needs. Backstage and Mattermost work better with PostgreSQL. MySQL excellent database but PostgreSQL better alignment with cloud-native ecosystem.

### Alternative 2: MongoDB

**Pros**:
- Document-oriented (flexible schema)
- Excellent for JSON data
- Horizontal scaling built-in
- High write throughput
- Popular for modern applications

**Cons**:
- **NoSQL**: Not all components support MongoDB
- **No ACID Across Collections**: Weak consistency by default
- **Limited Joins**: Embedding vs. referencing trade-offs
- **Operational Complexity**: Sharding complex to manage
- **Backstage Not Supported**: Backstage requires SQL database
- **License Concerns**: SSPL license controversial

**Reason for Rejection**: MongoDB excellent for document storage but incompatible with key components (Backstage, SonarQube). ACID properties critical for catalog and metrics. SQL relationships important for service dependencies. PostgreSQL JSONB provides flexible schema when needed while maintaining SQL strengths.

### Alternative 3: SQLite

**Pros**:
- Zero configuration
- No separate server process
- Very lightweight
- Fast for single-user scenarios
- Embedded database

**Cons**:
- **No Concurrency**: Limited concurrent writes
- **No Network Access**: File-based only
- **No Replication**: No built-in HA
- **Not Kubernetes-Native**: File-based doesn't fit pods well
- **Scalability Limits**: Not designed for multi-user systems

**Reason for Rejection**: SQLite excellent for local development and embedded use cases but not suitable for multi-user platform services. Need concurrent access, network access, and high availability. PostgreSQL designed for exactly these scenarios.

### Alternative 4: CockroachDB

**Pros**:
- PostgreSQL-compatible
- Distributed SQL (horizontal scaling)
- Built-in replication
- Multi-region support
- Strong consistency
- Cloud-native architecture

**Cons**:
- **Operational Complexity**: More complex than PostgreSQL
- **Resource Intensive**: Higher overhead than PostgreSQL
- **Less Mature**: Newer (2015 vs. PostgreSQL 1986)
- **Smaller Community**: Fewer examples and resources
- **Learning Curve**: Distributed systems concepts required
- **Overkill**: More than we need initially

**Reason for Rejection**: CockroachDB philosophically appealing (distributed, PostgreSQL-compatible) but operationally complex and resource-intensive for our scale. PostgreSQL sufficient for foreseeable future. CockroachDB excellent choice at massive scale but unnecessary complexity for Fawkes. May revisit if we need multi-region or massive horizontal scale.

### Alternative 5: TimescaleDB

**Pros**:
- PostgreSQL extension (full compatibility)
- Optimized for time-series data
- Excellent for metrics and logs
- Compression and retention policies
- Continuous aggregates

**Cons**:
- **Not Needed for All Data**: Only beneficial for time-series
- **Additional Complexity**: Extension to install and manage
- **License**: Some features require license (Cloud only)

**Reason for Rejection**: TimescaleDB excellent for DORA metrics time-series data. However, not needed for Backstage, Mattermost, or other components. Can add TimescaleDB extension to DORA metrics database if needed, but standard PostgreSQL sufficient initially. Good option to consider for Phase 2 optimization.

### Alternative 6: Cloud-Managed Services Only (AWS RDS, Azure Database, Cloud SQL)

**Pros**:
- Fully managed (no operational overhead)
- Automated backups and failover
- Easy scaling
- Security managed
- High availability guaranteed
- Support included

**Cons**:
- **Cost**: Much more expensive than self-hosted ($100-500+/month per database)
- **Vendor Lock-In**: Specific to cloud provider
- **Less Control**: Can't customize everything
- **Not Self-Hosted**: Conflicts with open source platform values

**Reason for Rejection**: Managed services convenient but expensive and create vendor lock-in. Self-hosted PostgreSQL with CloudNativePG provides similar benefits at fraction of cost. However, we support managed services as option for production deployments. Fawkes flexible: can use self-hosted for cost-conscious deployments, managed for convenience.

### Alternative 7: Multiple Database Types (polyglot persistence)

**Pros**:
- Best tool for each job
- PostgreSQL for relational, MongoDB for documents, Redis for cache
- Optimized for specific use cases

**Cons**:
- **Operational Complexity**: Multiple databases to manage, monitor, backup
- **Increased Overhead**: More expertise required
- **Cost**: More resources needed
- **Not Necessary**: PostgreSQL JSONB handles semi-structured data well

**Reason for Rejection**: Polyglot persistence has merits but increases operational complexity significantly. PostgreSQL versatile enough to handle all current needs (relational + JSON + full-text search). Simpler to have single database technology. May add Redis for caching in Phase 2, but one primary database reduces complexity.

## Related Decisions

- **ADR-002**: Backstage (uses PostgreSQL for catalog)
- **ADR-007**: Mattermost (uses PostgreSQL for messages and boards)
- **Future ADR**: Backup and Disaster Recovery Strategy
- **Future ADR**: Database Performance Optimization

## Implementation Notes

### Deployment Architecture

**Kubernetes Deployment with CloudNativePG**:

```yaml
# PostgreSQL Cluster with HA
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: fawkes-postgres
  namespace: fawkes-data
spec:
  instances: 3  # 1 primary + 2 replicas
  
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
      effective_cache_size: "1GB"
      work_mem: "16MB"
      maintenance_work_mem: "128MB"
      
  bootstrap:
    initdb:
      database: backstage
      owner: backstage
      
  storage:
    size: 50Gi
    storageClass: gp3
    
  backup:
    barmanObjectStore:
      destinationPath: s3://fawkes-postgres-backups/
      s3Credentials:
        accessKeyId:
          name: backup-creds
          key: ACCESS_KEY_ID
        secretAccessKey:
          name: backup-creds
          key: SECRET_ACCESS_KEY
      wal:
        compression: gzip
      retentionPolicy: "30d"
      
  monitoring:
    enablePodMonitor: true
    
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "2"
```

### Database Organization

**Strategy**: Single PostgreSQL cluster, multiple databases

```
fawkes-postgres cluster
├── backstage_db (Backstage catalog)
├── mattermost_db (Mattermost + Focalboard)
├── sonarqube_db (SonarQube analysis)
├── dora_metrics_db (DORA metrics service)
├── dojo_progress_db (Learner progress)
└── jenkins_db (optional, Jenkins metadata)
```

**Rationale**:
- Logical isolation between components
- Easier to backup/restore individual databases
- Resource sharing (connection pooling benefits)
- Single cluster to manage (operational simplicity)

### Connection Pooling with PgBouncer

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pgbouncer
  namespace: fawkes-data
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: pgbouncer
        image: edoburu/pgbouncer:latest
        env:
        - name: DB_HOST
          value: fawkes-postgres-rw
        - name: DB_PORT
          value: "5432"
        - name: POOL_MODE
          value: transaction
        - name: MAX_CLIENT_CONN
          value: "1000"
        - name: DEFAULT_POOL_SIZE
          value: "25"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

### Backup Configuration

**Automated Backups**:
- Full backup: Daily at 2 AM UTC
- WAL archiving: Continuous
- Retention: 30 days
- Destination: S3/MinIO bucket
- Encryption: At rest (S3 SSE)

**Backup Verification**:
```bash
# Weekly automated restore test
kubectl cnpg backup fawkes-postgres-$(date +%Y%m%d)

# Restore to test cluster
kubectl cnpg restore fawkes-postgres-test \
  --backup fawkes-postgres-20251008 \
  --cluster fawkes-postgres
```

### Monitoring & Alerting

**Prometheus Metrics** (via postgres_exporter):
- `pg_up` - Database reachable
- `pg_stat_database_*` - Database statistics
- `pg_stat_replication_*` - Replication lag
- `pg_locks_*` - Lock contention
- `pg_stat_user_tables_*` - Table statistics

**Key Alerts**:
```yaml
groups:
- name: postgres
  rules:
  - alert: PostgreSQLDown
    expr: pg_up == 0
    for: 1m
    annotations:
      summary: "PostgreSQL is down"
      
  - alert: PostgreSQLReplicationLag
    expr: pg_replication_lag > 30
    for: 5m
    annotations:
      summary: "Replication lag {{ $value }}s"
      
  - alert: PostgreSQLConnectionsHigh
    expr: pg_stat_database_numbackends > 180
    for: 5m
    annotations:
      summary: "High connection count: {{ $value }}"
      
  - alert: PostgreSQLDiskUsageHigh
    expr: pg_database_size_bytes / pg_settings_max_wal_size > 0.8
    for: 5m
    annotations:
      summary: "Database disk usage high"
```

**Grafana Dashboard**:
- Connection count and usage
- Query performance (slow queries)
- Replication lag
- Database size growth
- Cache hit ratio
- Transaction rate
- Lock contention

### Maintenance Tasks

**Automated** (via CronJobs):
```yaml
# Daily vacuum analyze
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-vacuum
spec:
  schedule: "0 3 * * *"  # 3 AM daily
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: vacuum
            image: postgres:15
            command:
            - /bin/sh
            - -c
            - |
              psql -h fawkes-postgres-rw -U postgres -c "VACUUM ANALYZE"
```

**Manual** (quarterly):
- Reindex large tables
- Analyze table bloat
- Review and optimize slow queries
- Update statistics manually if needed

### Security Configuration

**Authentication**:
```yaml
# PostgreSQL pg_hba.conf
host    all             all             10.0.0.0/8            scram-sha-256
host    replication     all             10.0.0.0/8            scram-sha-256
hostssl all             all             0.0.0.0/0             scram-sha-256
```

**Encryption**:
- TLS/SSL for connections (enforced)
- Encryption at rest (storage level)
- Backup encryption (S3 SSE)

**Access Control**:
```sql
-- Create role per application
CREATE ROLE backstage WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE backstage_db TO backstage;
GRANT ALL PRIVILEGES ON DATABASE backstage_db TO backstage;

-- Read-only role for monitoring
CREATE ROLE monitoring WITH LOGIN PASSWORD 'secure_password';
GRANT CONNECT ON DATABASE backstage_db TO monitoring;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO monitoring;
```

### Performance Tuning

**Connection Settings**:
```
max_connections = 200
shared_buffers = 256MB          # 25% of RAM
effective_cache_size = 1GB      # 50-75% of RAM
work_mem = 16MB                 # RAM / max_connections / 2
maintenance_work_mem = 128MB    # RAM / 16
```

**Query Optimization**:
```
# Enable query logging for slow queries
log_min_duration_statement = 1000  # Log queries > 1s
log_statement = 'all'              # Log all statements (dev only)

# Query planning
random_page_cost = 1.1            # SSD storage
effective_io_concurrency = 200    # SSD capability
```

**Autovacuum**:
```
autovacuum = on
autovacuum_max_workers = 3
autovacuum_naptime = 1min
autovacuum_vacuum_cost_delay = 20ms
```

### Migration Strategy

**Schema Migrations**:
- Use Flyway or Liquibase for versioned migrations
- Store migrations in Git
- Apply migrations in CI/CD pipeline
- Never modify schema manually

**Example Flyway Migration**:
```sql
-- V1__create_users_table.sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) NOT NULL UNIQUE,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
```

### Disaster Recovery

**Recovery Time Objective (RTO)**: 4 hours
**Recovery Point Objective (RPO)**: 1 hour (WAL archiving)

**Recovery Procedure**:
1. Create new PostgreSQL cluster
2. Restore from latest backup
3. Apply WAL files for point-in-time recovery
4. Verify data integrity
5. Update application connection strings
6. Resume operations

**Automated DR Testing**:
- Monthly restore test to separate cluster
- Verify data integrity checks pass
- Document any issues and resolution

### Managed Service Alternative

**For Production Deployments**:

**AWS RDS PostgreSQL**:
- Multi-AZ for high availability
- Automated backups with point-in-time recovery
- Read replicas for scaling
- Enhanced monitoring
- Estimated cost: $200-400/month (db.t3.large)

**Azure Database for PostgreSQL**:
- Flexible Server with HA
- Automated backups and patching
- Read replicas
- Advanced Threat Protection
- Estimated cost: $180-350/month (similar specs)

**Google Cloud SQL for PostgreSQL**:
- High availability configuration
- Automated backups
- Read replicas
- Cloud SQL Proxy for secure connections
- Estimated cost: $190-370/month (similar specs)

**Decision**: Support both self-hosted and managed options. Documentation for both approaches. Recommend self-hosted for dev/staging, managed for production (optional).

## Monitoring This Decision

We will revisit this ADR if:
- PostgreSQL performance becomes bottleneck that can't be resolved
- Write scalability becomes critical requirement
- Operational burden exceeds team capacity
- Cloud-managed services become cost-competitive with self-hosted
- Alternative database provides significantly better features
- Components add requirements PostgreSQL can't meet

**Next Review Date**: April 8, 2026 (6 months)

## References

- [PostgreSQL Official Documentation](https://www.postgresql.org/docs/)
- [CloudNativePG Documentation](https://cloudnative-pg.io/documentation/)
- [PostgreSQL High Availability](https://www.postgresql.org/docs/current/high-availability.html)
- [PgBouncer Documentation](https://www.pgbouncer.org/)
- [Postgres Exporter](https://github.com/prometheus-community/postgres_exporter)
- [PostgreSQL Performance Tuning](https://wiki.postgresql.org/wiki/Performance_Optimization)

## Notes

### Why PostgreSQL Over MySQL?

**PostgreSQL advantages**:
- Better JSON support (JSONB with indexing)
- Full-text search built-in
- More advanced SQL features (CTEs, window functions)
- Better for complex queries
- Stronger in cloud-native ecosystem

**MySQL advantages**:
- Slightly simpler for basic use cases
- Some argue faster for simple reads
- More familiar to some developers

**For Fawkes**: PostgreSQL's advanced features (especially JSONB and full-text search) align better with platform needs. Both excellent databases, but PostgreSQL slight edge for our use cases.

### Single Cluster vs. Multiple Clusters

**Single Cluster Approach** (chosen):
- Operational simplicity (one cluster to manage)
- Resource efficiency (shared resources)
- Easier monitoring and backup
- Lower infrastructure costs

**Multiple Clusters Approach**:
- Complete isolation between components
- Independent scaling
- Failure isolation
- Higher operational overhead

**Decision**: Single cluster with multiple databases provides good balance. Can split into multiple clusters later if needed.

### When to Consider Alternative Databases

**Consider MySQL/MariaDB**:
- Team has strong MySQL expertise
- Simple transactional workloads only
- No need for advanced PostgreSQL features

**Consider MongoDB**:
- Truly schemaless data needed
- Horizontal write scaling critical
- All components support NoSQL (not our case)

**Consider CockroachDB**:
- Multi-region requirements
- Massive horizontal scaling needed
- Can absorb operational complexity

**For most teams**: PostgreSQL is the pragmatic, proven choice.

---

**Decision Made By**: Platform Architecture Team  
**Approved By**: Project Lead  
**Date**: October 8, 2025  
**Author**: [Platform Architect Name]  
**Last Updated**: October 8, 2025