# Insights Database and Tracking System

A FastAPI-based service for capturing, organizing, and tracking insights with tagging, categorization, and searchability.

## Features

- **Structured Insights Storage**: Capture and organize insights with rich metadata
- **Tagging System**: Flexible tagging for cross-categorization
- **Hierarchical Categories**: Organize insights in a hierarchical category structure
- **Advanced Search**: Full-text search with multiple filters
- **Priority & Status Management**: Track insight priority and lifecycle status
- **Statistics & Aggregation**: Built-in statistics and aggregation endpoints
- **RESTful API**: Comprehensive REST API with OpenAPI documentation
- **Observability**: Prometheus metrics and health checks

## Quick Start

### Prerequisites

- Python 3.12+
- PostgreSQL 15+

### Installation

1. Install dependencies:

```bash
pip install -r requirements.txt
```

2. Set environment variables:

```bash
export DATABASE_URL="postgresql://insights:insights@localhost:5432/insights"
```

3. Run database migrations:

```bash
alembic upgrade head
```

4. Start the service:

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### Docker Deployment

```bash
# Build image
docker build -t fawkes-insights:latest .

# Run container
docker run -d \
  -p 8000:8000 \
  -e DATABASE_URL="postgresql://insights:insights@db:5432/insights" \
  fawkes-insights:latest
```

## API Documentation

Once running, access the interactive API documentation at:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc

## Database Schema

### Tables

#### insights
Stores captured insights and learnings.

- `id`: Primary key
- `title`: Insight title (max 500 chars)
- `description`: Short description or summary
- `content`: Extended content or details
- `source`: Where the insight came from
- `author`: Insight author
- `category_id`: Foreign key to categories
- `priority`: Priority level (low, medium, high, critical)
- `status`: Status (draft, published, archived)
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp
- `published_at`: Publication timestamp

#### categories
Hierarchical categorization for insights.

- `id`: Primary key
- `name`: Category name (unique)
- `slug`: URL-friendly slug (unique)
- `description`: Category description
- `parent_id`: Parent category for hierarchy
- `color`: Hex color for UI display
- `icon`: Icon name for UI display
- `created_at`: Creation timestamp
- `updated_at`: Last update timestamp

#### tags
Flexible tagging system.

- `id`: Primary key
- `name`: Tag name (unique)
- `slug`: URL-friendly slug (unique)
- `description`: Tag description
- `color`: Hex color for UI display
- `created_at`: Creation timestamp
- `usage_count`: Number of insights using this tag

#### insight_tags
Many-to-many association between insights and tags.

- `insight_id`: Foreign key to insights
- `tag_id`: Foreign key to tags

## API Endpoints

### Insights

- `POST /insights` - Create a new insight
- `GET /insights` - List insights with pagination and filters
- `POST /insights/search` - Advanced search with multiple filters
- `GET /insights/{insight_id}` - Get a specific insight
- `PUT /insights/{insight_id}` - Update an insight
- `DELETE /insights/{insight_id}` - Delete an insight

### Tags

- `POST /tags` - Create a new tag
- `GET /tags` - List all tags
- `GET /tags/{tag_id}` - Get a specific tag
- `PUT /tags/{tag_id}` - Update a tag
- `DELETE /tags/{tag_id}` - Delete a tag

### Categories

- `POST /categories` - Create a new category
- `GET /categories` - List all categories
- `GET /categories/{category_id}` - Get a specific category
- `PUT /categories/{category_id}` - Update a category
- `DELETE /categories/{category_id}` - Delete a category

### Statistics

- `GET /statistics` - Get insights statistics and aggregations

### Health & Metrics

- `GET /health` - Health check endpoint
- `GET /metrics` - Prometheus metrics

## Example Usage

### Create an Insight

```bash
curl -X POST "http://localhost:8000/insights" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Performance optimization in PostgreSQL",
    "description": "Discovered that adding indexes on frequently queried columns improved query performance by 10x",
    "content": "We were experiencing slow query times on the insights table. After analyzing the query patterns, we added composite indexes on (status, priority) and (category_id, status). This reduced average query time from 500ms to 50ms.",
    "source": "Production incident #1234",
    "author": "engineering-team",
    "category_id": 1,
    "priority": "high",
    "status": "published",
    "tag_ids": [1, 5]
  }'
```

### Search Insights

```bash
curl -X POST "http://localhost:8000/insights/search" \
  -H "Content-Type: application/json" \
  -d '{
    "query": "performance",
    "category_id": 1,
    "status": "published",
    "priority": "high",
    "page": 1,
    "page_size": 20
  }'
```

### Get Statistics

```bash
curl "http://localhost:8000/statistics"
```

## Development

### Running Tests

```bash
# Run all tests
pytest

# Run with coverage
pytest --cov=app --cov-report=html

# Run specific test file
pytest tests/test_insights.py
```

### Database Migrations

```bash
# Create a new migration
alembic revision --autogenerate -m "description"

# Apply migrations
alembic upgrade head

# Rollback one migration
alembic downgrade -1

# Show current version
alembic current
```

## Configuration

Environment variables:

- `DATABASE_URL`: PostgreSQL connection string (required)
- `SQL_ECHO`: Enable SQL query logging (`true`/`false`, default: `false`)

## Aggregation Process

The insights system supports aggregation in multiple ways:

1. **Statistics Endpoint**: Provides real-time aggregations by status, priority, and category
2. **Tag Usage Tracking**: Automatically tracks how many insights use each tag
3. **Category Insight Count**: Each category includes a count of associated insights
4. **Time-based Filtering**: Filter insights by creation date for trend analysis

## Dashboard Integration

The insights service is designed to integrate with dashboards through:

- **RESTful API**: All data accessible via REST endpoints
- **Prometheus Metrics**: Service metrics for monitoring
- **Statistics API**: Pre-calculated aggregations for dashboard display
- **Search API**: Flexible search for dashboard filtering

Example metrics exposed:

- `insights_created_total`: Total insights created
- `insights_updated_total`: Total insights updated
- `insights_deleted_total`: Total insights deleted
- `api_requests_total`: Total API requests by method and endpoint
- `request_duration_seconds`: Request duration histogram

## Architecture

The service follows a layered architecture:

```
┌─────────────────────────────────────┐
│       FastAPI Application           │
│  (REST API + OpenAPI Docs)         │
└─────────────────────────────────────┘
                 │
┌─────────────────────────────────────┐
│      SQLAlchemy ORM Layer           │
│  (Models + Relationships)           │
└─────────────────────────────────────┘
                 │
┌─────────────────────────────────────┐
│      PostgreSQL Database            │
│  (Insights, Tags, Categories)       │
└─────────────────────────────────────┘
```

## Security

- Non-root container execution
- Read-only filesystem where possible
- SQL injection protection via SQLAlchemy ORM
- Input validation via Pydantic schemas
- CORS configuration (configure appropriately for production)

## Performance

- Connection pooling (10 connections by default)
- Composite indexes for common query patterns
- Query pagination to prevent large result sets
- Tag usage count maintained incrementally

## License

See LICENSE file in repository root.

## Contributing

See CONTRIBUTING.md in repository root.
