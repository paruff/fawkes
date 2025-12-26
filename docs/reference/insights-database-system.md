---
title: Insights Database and Tracking System
description: Structured system for capturing, organizing, and tracking insights with tagging, categorization, and searchability
---

# Insights Database and Tracking System

## Overview

The Insights Database and Tracking System is a structured platform for capturing, organizing, and tracking organizational learnings, best practices, and knowledge. It provides a comprehensive solution for knowledge management with features like tagging, hierarchical categorization, and advanced search capabilities.

**Service Name**: `insights`
**Database**: PostgreSQL 15+
**API Framework**: FastAPI
**API Documentation**: `/docs` (Swagger), `/redoc` (ReDoc)

---

## Key Features

### 1. Structured Insights Storage

- Capture insights with rich metadata (title, description, content, source)
- Track authorship and timestamps
- Manage insight lifecycle (draft, published, archived)
- Priority levels (low, medium, high, critical)

### 2. Tagging System

- Flexible tagging for cross-categorization
- Tag usage tracking for popularity metrics
- Color-coded tags for visual organization
- Automatic usage count maintenance

### 3. Hierarchical Categories

- Parent-child category relationships
- Unlimited nesting depth
- Visual indicators (colors and icons)
- Category-level insight counts

### 4. Advanced Search

- Full-text search across title, description, and content
- Multi-filter support (category, tags, priority, status, author)
- Tag-based filtering with AND logic
- Pagination support

### 5. Statistics and Aggregation

- Insights by status, priority, and category
- Tag usage statistics
- Recent insights tracking
- Real-time aggregations

### 6. RESTful API

- Comprehensive REST endpoints
- OpenAPI documentation
- Pydantic schema validation
- CORS support

### 7. Observability

- Prometheus metrics
- Health check endpoint
- Request duration tracking
- API request counters

---

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Insights Service                          │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐  │
│  │              FastAPI Application                        │  │
│  │                                                          │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐ │  │
│  │  │ Insights │  │   Tags   │  │Categories│  │ Stats  │ │  │
│  │  │   API    │  │   API    │  │   API    │  │  API   │ │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └────────┘ │  │
│  └────────────────────────────────────────────────────────┘  │
│                          │                                    │
│  ┌────────────────────────────────────────────────────────┐  │
│  │           SQLAlchemy ORM Layer                          │  │
│  │  (Models, Relationships, Query Building)               │  │
│  └────────────────────────────────────────────────────────┘  │
│                          │                                    │
└──────────────────────────┼────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│              PostgreSQL Database (insights)                    │
│                                                               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────────┐  │
│  │ insights │  │   tags   │  │categories│  │insight_tags│  │
│  └──────────┘  └──────────┘  └──────────┘  └────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           │
┌──────────────────────────▼────────────────────────────────────┐
│                 Data API (GraphQL)                             │
│         Unified access to insights via GraphQL                │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow

```
1. Capture Insight
   User → API → Validate → Create Record → Update Tag Counts → Return

2. Search Insights
   User → API → Apply Filters → Full-Text Search → Paginate → Return

3. Aggregation
   Request → API → Query Statistics → Calculate Metrics → Return

4. Dashboard View
   Dashboard → GraphQL API → Query Insights → Transform → Display
```

---

## Database Schema

### Entity-Relationship Diagram

```
┌─────────────────────┐
│    categories       │
│─────────────────────│
│ id (PK)            │◄───┐
│ name (unique)       │    │
│ slug (unique)       │    │
│ description         │    │
│ parent_id (FK)      │────┘ (self-referential)
│ color               │
│ icon                │
│ created_at          │
│ updated_at          │
└─────────────────────┘
          │
          │ (1:N)
          │
┌─────────▼───────────────┐
│      insights           │
│─────────────────────────│
│ id (PK)                │
│ title                   │
│ description             │
│ content                 │
│ source                  │
│ author                  │
│ category_id (FK)        │
│ priority                │
│ status                  │
│ created_at              │
│ updated_at              │
│ published_at            │
└─────────────────────────┘
          │
          │ (N:M)
          │
          ├──────────────────┐
          │                  │
┌─────────▼───────────┐      │
│   insight_tags      │      │
│─────────────────────│      │
│ insight_id (FK,PK)  │      │
│ tag_id (FK,PK)      │      │
└─────────────────────┘      │
          │                  │
          │ (N:1)            │
          │                  │
┌─────────▼───────────┐      │
│       tags          │◄─────┘
│─────────────────────│
│ id (PK)            │
│ name (unique)       │
│ slug (unique)       │
│ description         │
│ color               │
│ created_at          │
│ usage_count         │
└─────────────────────┘
```

### Table Definitions

#### insights

Main table for storing insights.

| Column       | Type         | Description                                     |
| ------------ | ------------ | ----------------------------------------------- |
| id           | INTEGER      | Primary key                                     |
| title        | VARCHAR(500) | Insight title (indexed)                         |
| description  | TEXT         | Short description or summary                    |
| content      | TEXT         | Extended content or details                     |
| source       | VARCHAR(255) | Source of the insight                           |
| author       | VARCHAR(255) | Insight author (indexed)                        |
| category_id  | INTEGER      | Foreign key to categories (indexed)             |
| priority     | VARCHAR(20)  | Priority: low, medium, high, critical (indexed) |
| status       | VARCHAR(20)  | Status: draft, published, archived (indexed)    |
| created_at   | TIMESTAMP    | Creation timestamp (indexed)                    |
| updated_at   | TIMESTAMP    | Last update timestamp                           |
| published_at | TIMESTAMP    | Publication timestamp                           |

**Indexes**:

- `idx_insights_status_priority` (status, priority)
- `idx_insights_category_status` (category_id, status)
- `idx_insights_author_status` (author, status)

#### categories

Hierarchical categories for organizing insights.

| Column      | Type         | Description                              |
| ----------- | ------------ | ---------------------------------------- |
| id          | INTEGER      | Primary key                              |
| name        | VARCHAR(100) | Category name (unique, indexed)          |
| slug        | VARCHAR(100) | URL-friendly slug (unique, indexed)      |
| description | TEXT         | Category description                     |
| parent_id   | INTEGER      | Parent category ID (self-referential FK) |
| color       | VARCHAR(7)   | Hex color code for UI                    |
| icon        | VARCHAR(50)  | Icon name for UI                         |
| created_at  | TIMESTAMP    | Creation timestamp                       |
| updated_at  | TIMESTAMP    | Last update timestamp                    |

#### tags

Flexible tags for cross-categorization.

| Column      | Type        | Description                         |
| ----------- | ----------- | ----------------------------------- |
| id          | INTEGER     | Primary key                         |
| name        | VARCHAR(50) | Tag name (unique, indexed)          |
| slug        | VARCHAR(50) | URL-friendly slug (unique, indexed) |
| description | TEXT        | Tag description                     |
| color       | VARCHAR(7)  | Hex color code for UI               |
| created_at  | TIMESTAMP   | Creation timestamp                  |
| usage_count | INTEGER     | Number of insights using this tag   |

#### insight_tags

Many-to-many association between insights and tags.

| Column     | Type    | Description                  |
| ---------- | ------- | ---------------------------- |
| insight_id | INTEGER | Foreign key to insights (PK) |
| tag_id     | INTEGER | Foreign key to tags (PK)     |

**Indexes**:

- `idx_insight_tags_insight_id` (insight_id)
- `idx_insight_tags_tag_id` (tag_id)

---

## API Reference

### Insights Endpoints

#### Create Insight

```http
POST /insights
Content-Type: application/json

{
  "title": "Performance optimization in PostgreSQL",
  "description": "Database indexing improved query performance",
  "content": "Detailed explanation...",
  "source": "Production incident #1234",
  "author": "engineering-team",
  "category_id": 1,
  "priority": "high",
  "status": "published",
  "tag_ids": [1, 2, 3]
}
```

**Response**: `201 Created`

```json
{
  "id": 1,
  "title": "Performance optimization in PostgreSQL",
  "description": "Database indexing improved query performance",
  "content": "Detailed explanation...",
  "source": "Production incident #1234",
  "author": "engineering-team",
  "category_id": 1,
  "priority": "high",
  "status": "published",
  "created_at": "2025-12-23T18:00:00Z",
  "updated_at": "2025-12-23T18:00:00Z",
  "published_at": "2025-12-23T18:00:00Z",
  "tags": [...],
  "category": {...}
}
```

#### List Insights

```http
GET /insights?page=1&page_size=20&status=published&priority=high
```

**Response**: `200 OK`

```json
{
  "total": 42,
  "page": 1,
  "page_size": 20,
  "insights": [...]
}
```

#### Search Insights

```http
POST /insights/search
Content-Type: application/json

{
  "query": "performance",
  "category_id": 1,
  "tag_ids": [1, 5],
  "status": "published",
  "priority": "high",
  "author": "engineering",
  "page": 1,
  "page_size": 20
}
```

#### Get Insight

```http
GET /insights/{insight_id}
```

#### Update Insight

```http
PUT /insights/{insight_id}
Content-Type: application/json

{
  "title": "Updated title",
  "priority": "critical",
  "tag_ids": [1, 2, 3, 4]
}
```

#### Delete Insight

```http
DELETE /insights/{insight_id}
```

**Response**: `204 No Content`

### Tags Endpoints

#### Create Tag

```http
POST /tags
Content-Type: application/json

{
  "name": "Best Practice",
  "slug": "best-practice",
  "description": "Recommended best practice",
  "color": "#3B82F6"
}
```

#### List Tags

```http
GET /tags?skip=0&limit=100
```

#### Get Tag

```http
GET /tags/{tag_id}
```

#### Update Tag

```http
PUT /tags/{tag_id}
```

#### Delete Tag

```http
DELETE /tags/{tag_id}
```

### Categories Endpoints

#### Create Category

```http
POST /categories
Content-Type: application/json

{
  "name": "Technical",
  "slug": "technical",
  "description": "Technical insights and learnings",
  "parent_id": null,
  "color": "#3B82F6",
  "icon": "code"
}
```

#### List Categories

```http
GET /categories?skip=0&limit=100
```

#### Get Category

```http
GET /categories/{category_id}
```

#### Update Category

```http
PUT /categories/{category_id}
```

#### Delete Category

```http
DELETE /categories/{category_id}
```

**Note**: Cannot delete a category with insights. Remove insights first.

### Statistics Endpoint

#### Get Statistics

```http
GET /statistics
```

**Response**: `200 OK`

```json
{
  "total_insights": 156,
  "insights_by_status": {
    "draft": 23,
    "published": 128,
    "archived": 5
  },
  "insights_by_priority": {
    "low": 45,
    "medium": 67,
    "high": 38,
    "critical": 6
  },
  "insights_by_category": {
    "Technical": 56,
    "Process": 42,
    "People": 28,
    "Product": 30
  },
  "total_tags": 24,
  "total_categories": 8,
  "recent_insights": [...]
}
```

### Health & Metrics

#### Health Check

```http
GET /health
```

**Response**: `200 OK`

```json
{
  "status": "healthy",
  "service": "insights",
  "version": "1.0.0",
  "database_connected": true
}
```

#### Prometheus Metrics

```http
GET /metrics
```

**Metrics Exposed**:

- `insights_created_total`: Total insights created
- `insights_updated_total`: Total insights updated
- `insights_deleted_total`: Total insights deleted
- `api_requests_total`: Total API requests by method and endpoint
- `request_duration_seconds`: Request duration histogram

---

## Aggregation Process

The insights system provides multiple aggregation mechanisms:

### 1. Real-Time Statistics

The `/statistics` endpoint provides pre-calculated aggregations:

```python
# Insights by status
SELECT status, COUNT(*) FROM insights GROUP BY status;

# Insights by priority
SELECT priority, COUNT(*) FROM insights GROUP BY priority;

# Insights by category
SELECT c.name, COUNT(i.id)
FROM categories c
LEFT JOIN insights i ON c.id = i.category_id
GROUP BY c.name;
```

### 2. Tag Usage Tracking

Tag usage is automatically maintained:

- **On insight creation**: Increment `usage_count` for each associated tag
- **On insight update**: Update counts for added/removed tags
- **On insight deletion**: Decrement `usage_count` for each associated tag

### 3. Category Insight Counts

Category endpoint includes insight counts:

```python
# Get category with insight count
category = db.query(Category).filter(Category.id == category_id).first()
insight_count = db.query(Insight).filter(Insight.category_id == category.id).count()
```

### 4. Time-Based Aggregation

Filter insights by date ranges for trend analysis:

```sql
-- Insights created in last 30 days
SELECT DATE(created_at), COUNT(*)
FROM insights
WHERE created_at >= NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at);

-- Insights by status over time
SELECT DATE(created_at), status, COUNT(*)
FROM insights
GROUP BY DATE(created_at), status
ORDER BY DATE(created_at);
```

### 5. Author Contribution Metrics

Track insights by author:

```sql
-- Top contributors
SELECT author, COUNT(*) as insight_count
FROM insights
WHERE status = 'published'
GROUP BY author
ORDER BY insight_count DESC
LIMIT 10;
```

---

## Dashboard Integration

### GraphQL Integration

Access insights via the unified GraphQL API:

```graphql
# Query insights with filters
query {
  insights(
    where: { status: { _eq: "published" }, priority: { _eq: "high" }, category: { name: { _eq: "Technical" } } }
    order_by: { created_at: desc }
    limit: 20
  ) {
    id
    title
    description
    priority
    status
    created_at
    author
    category {
      name
      color
      icon
    }
    tags {
      name
      color
    }
  }
}

# Query statistics
query {
  insights_aggregate {
    aggregate {
      count
    }
  }
  insights_aggregate_by_status: insights_aggregate {
    nodes {
      status
    }
    aggregate {
      count
    }
  }
}

# Search insights by text
query {
  insights(
    where: {
      _or: [
        { title: { _ilike: "%performance%" } }
        { description: { _ilike: "%performance%" } }
        { content: { _ilike: "%performance%" } }
      ]
    }
  ) {
    id
    title
    description
  }
}
```

### Dashboard View Components

#### 1. Insights Overview Dashboard

**Components**:

- Total insights count
- Insights by status (pie chart)
- Insights by priority (bar chart)
- Insights by category (horizontal bar chart)
- Recent insights list
- Top tags (tag cloud)

**Data Source**: `/statistics` endpoint

#### 2. Insights List View

**Components**:

- Filterable table/grid
- Search bar
- Category filter dropdown
- Tag filter multi-select
- Priority filter
- Status filter
- Author filter
- Pagination controls

**Data Source**: `/insights` or `/insights/search` endpoints

#### 3. Insight Detail View

**Components**:

- Full insight content
- Metadata (author, dates, source)
- Category badge
- Tag badges
- Priority indicator
- Status badge
- Related insights (same category/tags)

**Data Source**: `/insights/{insight_id}` endpoint

#### 4. Category Tree View

**Components**:

- Hierarchical category display
- Insight count per category
- Color-coded categories
- Expandable/collapsible tree
- Click to filter insights

**Data Source**: `/categories` endpoint

#### 5. Tag Cloud View

**Components**:

- Size-based tag visualization (by usage_count)
- Color-coded tags
- Click to filter insights
- Tag usage statistics

**Data Source**: `/tags` endpoint

### Dashboard Refresh Strategy

**Real-Time Data**:

- Health status: Poll `/health` every 30s
- Statistics: Poll `/statistics` every 60s

**On-Demand Data**:

- Insights list: Fetch on page load and filter changes
- Search results: Fetch on search submission
- Detail view: Fetch on insight selection

**Metrics**:

- Prometheus metrics: Scrape `/metrics` every 15s
- Display in monitoring dashboard (Grafana)

---

## Insight Template

### Standard Insight Template

```json
{
  "title": "[Brief, descriptive title]",
  "description": "[One-sentence summary]",
  "content": "[Detailed content with sections]",
  "source": "[Where this insight came from]",
  "author": "[Author or team name]",
  "category_id": [Category ID],
  "priority": "[low|medium|high|critical]",
  "status": "[draft|published|archived]",
  "tag_ids": [List of relevant tag IDs]
}
```

### Content Structure Template

```markdown
## Context

[What was the situation or problem?]

## Insight

[What did we learn or discover?]

## Impact

[What was the result or benefit?]

## Action Items

- [Specific actions taken or recommended]

## References

- [Links to related documentation, incidents, PRs, etc.]

## Related

- [Links to related insights]
```

### Example Insight

```json
{
  "title": "Composite Indexes Improved Query Performance by 10x",
  "description": "Adding composite indexes on frequently queried columns reduced average query time from 500ms to 50ms",
  "content": "## Context\nWe were experiencing slow query times (500ms average) on the insights table during peak usage hours, affecting dashboard load times and user experience.\n\n## Insight\nAfter analyzing query patterns with EXPLAIN ANALYZE, we discovered that most queries filtered by both status and priority fields simultaneously, but we only had single-column indexes.\n\n## Impact\n- Query time reduced from 500ms to 50ms (10x improvement)\n- Dashboard load time improved from 3s to 0.8s\n- Database CPU utilization decreased by 30%\n- Improved user experience during peak hours\n\n## Action Items\n- ✅ Added composite index on (status, priority)\n- ✅ Added composite index on (category_id, status)\n- ✅ Updated query patterns to leverage indexes\n- ✅ Documented index strategy in database documentation\n- 🔄 Planning to analyze other tables for similar optimizations\n\n## References\n- Production incident: #1234\n- PR with index changes: #5678\n- Database performance dashboard: [link]\n\n## Related\n- Database Query Optimization Best Practices (Insight #45)\n- PostgreSQL Index Strategy (Insight #67)",
  "source": "Production incident #1234",
  "author": "engineering-team",
  "category_id": 1,
  "priority": "high",
  "status": "published",
  "tag_ids": [1, 5, 6]
}
```

---

## Usage Patterns

### 1. Incident Learning

Capture insights from production incidents:

```python
# After resolving an incident
insight = {
    "title": "Redis connection pool exhaustion during traffic spike",
    "description": "Insufficient connection pool size caused service degradation",
    "content": "Detailed incident timeline and resolution...",
    "source": "Incident #INC-2024-001",
    "author": "sre-team",
    "category_id": get_category_id("Technical"),
    "priority": "critical",
    "status": "published",
    "tag_ids": [
        get_tag_id("Incident"),
        get_tag_id("Lesson Learned"),
        get_tag_id("Performance")
    ]
}
```

### 2. Best Practice Documentation

Document team best practices:

```python
insight = {
    "title": "Code Review Checklist for Security",
    "description": "Standard security checks for all code reviews",
    "content": "Checklist items and explanations...",
    "source": "Security team guidelines",
    "author": "security-team",
    "category_id": get_category_id("Security"),
    "priority": "high",
    "status": "published",
    "tag_ids": [
        get_tag_id("Best Practice"),
        get_tag_id("Documentation")
    ]
}
```

### 3. Process Improvements

Track process improvements and retrospective outcomes:

```python
insight = {
    "title": "Reduced deployment time with parallel testing",
    "description": "Running tests in parallel reduced CI time by 40%",
    "content": "Implementation details and results...",
    "source": "Sprint retrospective Q4 2024",
    "author": "platform-team",
    "category_id": get_category_id("Process"),
    "priority": "medium",
    "status": "published",
    "tag_ids": [
        get_tag_id("Improvement"),
        get_tag_id("Quick Win"),
        get_tag_id("Deployment")
    ]
}
```

### 4. Knowledge Sharing

Share discoveries and learnings:

```python
insight = {
    "title": "Using PostgreSQL EXPLAIN ANALYZE for query optimization",
    "description": "Guide to using EXPLAIN ANALYZE to identify slow queries",
    "content": "Tutorial and examples...",
    "source": "Team knowledge sharing session",
    "author": "john-doe",
    "category_id": get_category_id("Technical"),
    "priority": "medium",
    "status": "published",
    "tag_ids": [
        get_tag_id("Documentation"),
        get_tag_id("Best Practice")
    ]
}
```

---

## Integration Examples

### Python Client

```python
import httpx

class InsightsClient:
    def __init__(self, base_url: str = "http://localhost:8000"):
        self.base_url = base_url
        self.client = httpx.Client()

    def create_insight(self, insight_data: dict):
        response = self.client.post(
            f"{self.base_url}/insights",
            json=insight_data
        )
        response.raise_for_status()
        return response.json()

    def search_insights(self, query: str, filters: dict = None):
        search_request = {"query": query, **(filters or {})}
        response = self.client.post(
            f"{self.base_url}/insights/search",
            json=search_request
        )
        response.raise_for_status()
        return response.json()

    def get_statistics(self):
        response = self.client.get(f"{self.base_url}/statistics")
        response.raise_for_status()
        return response.json()

# Usage
client = InsightsClient()

# Create insight
insight = client.create_insight({
    "title": "My Learning",
    "description": "What I learned",
    "author": "me",
    "category_id": 1,
    "priority": "medium",
    "status": "published",
    "tag_ids": [1, 2]
})

# Search insights
results = client.search_insights(
    "performance",
    filters={"status": "published", "priority": "high"}
)

# Get statistics
stats = client.get_statistics()
```

### JavaScript/TypeScript Client

```typescript
class InsightsClient {
  constructor(private baseUrl: string = "http://localhost:8000") {}

  async createInsight(insightData: any): Promise<any> {
    const response = await fetch(`${this.baseUrl}/insights`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(insightData),
    });
    if (!response.ok) throw new Error("Failed to create insight");
    return response.json();
  }

  async searchInsights(query: string, filters: any = {}): Promise<any> {
    const response = await fetch(`${this.baseUrl}/insights/search`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ query, ...filters }),
    });
    if (!response.ok) throw new Error("Search failed");
    return response.json();
  }

  async getStatistics(): Promise<any> {
    const response = await fetch(`${this.baseUrl}/statistics`);
    if (!response.ok) throw new Error("Failed to get statistics");
    return response.json();
  }
}

// Usage
const client = new InsightsClient();

// Create insight
const insight = await client.createInsight({
  title: "My Learning",
  description: "What I learned",
  author: "me",
  category_id: 1,
  priority: "medium",
  status: "published",
  tag_ids: [1, 2],
});

// Search insights
const results = await client.searchInsights("performance", {
  status: "published",
  priority: "high",
});

// Get statistics
const stats = await client.getStatistics();
```

---

## Performance Considerations

### Query Optimization

1. **Composite Indexes**: Used for common multi-column queries

   - `(status, priority)` for filtering
   - `(category_id, status)` for category-based queries
   - `(author, status)` for author-based queries

2. **Connection Pooling**: 10 connections by default

   - Adjust `pool_size` in `database.py` for higher load

3. **Pagination**: All list endpoints support pagination

   - Maximum page size: 100 items
   - Default page size: 20 items

4. **Tag Usage Count**: Maintained incrementally
   - No expensive COUNT queries on read
   - Updated on insight create/update/delete

### Scaling Strategies

1. **Read Replicas**: Use PostgreSQL read replicas for search-heavy workloads

2. **Caching**: Add Redis caching for:

   - Statistics endpoint (TTL: 60s)
   - Popular searches (TTL: 300s)
   - Tag and category lists (TTL: 600s)

3. **Full-Text Search**: Consider PostgreSQL full-text search or Elasticsearch for large datasets

4. **Async Processing**: Offload heavy aggregations to background jobs

---

## Security

### API Security

- **Authentication**: Add JWT or OAuth2 authentication (currently not implemented)
- **Authorization**: Implement role-based access control
- **Rate Limiting**: Add rate limiting to prevent abuse
- **CORS**: Configure allowed origins for production

### Database Security

- **Prepared Statements**: SQLAlchemy ORM prevents SQL injection
- **Input Validation**: Pydantic schemas validate all inputs
- **Sensitive Data**: Don't store secrets or credentials in insights

### Container Security

- **Non-Root User**: Container runs as non-root user (UID 10001)
- **Read-Only Filesystem**: Where possible
- **Security Scanning**: Scan images with Trivy

---

## Monitoring

### Prometheus Metrics

```promql
# Insights creation rate
rate(insights_created_total[5m])

# API request rate by endpoint
rate(api_requests_total[5m])

# API request duration (95th percentile)
histogram_quantile(0.95, rate(request_duration_seconds_bucket[5m]))

# Database connection pool usage
# (Add custom metrics in production)
```

### Health Checks

```bash
# Check service health
curl http://localhost:8000/health

# Expected response
{
  "status": "healthy",
  "service": "insights",
  "version": "1.0.0",
  "database_connected": true
}
```

### Logging

Configure structured logging in production:

```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='{"time":"%(asctime)s","level":"%(levelname)s","message":"%(message)s"}',
    handlers=[logging.StreamHandler()]
)
```

---

## Troubleshooting

### Common Issues

#### Database Connection Failed

**Symptom**: `database_connected: false` in health check

**Solution**:

```bash
# Check DATABASE_URL
echo $DATABASE_URL

# Test connection
psql $DATABASE_URL -c "SELECT 1"

# Check PostgreSQL is running
kubectl get pods -n fawkes | grep postgres
```

#### Slow Queries

**Symptom**: High API latency

**Solution**:

```sql
-- Enable query logging
SET log_statement = 'all';
SET log_duration = on;

-- Check slow queries
SELECT * FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;

-- Analyze query plans
EXPLAIN ANALYZE SELECT * FROM insights WHERE status = 'published';
```

#### Tag Usage Count Inconsistency

**Symptom**: `usage_count` doesn't match actual usage

**Solution**:

```sql
-- Recalculate usage counts
UPDATE tags t
SET usage_count = (
    SELECT COUNT(*)
    FROM insight_tags it
    WHERE it.tag_id = t.id
);
```

---

## Related Documentation

- [Insights Service README](../../services/insights/README.md)
- [Data API GraphQL Schema](../../services/data-api/schema/)
- [Architecture Overview](../architecture.md)
- [Database Schema Reference](./insights-database-schema.md)
- [API Development Guide](../how-to/develop-api-service.md)

---

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines on contributing to the insights service.

## License

See [LICENSE](../../LICENSE) in repository root.
