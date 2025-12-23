# SPACE Metrics Collection Service

FastAPI-based service for collecting and exposing SPACE framework metrics (Satisfaction, Performance, Activity, Communication, Efficiency) for Developer Experience measurement.

## Overview

The SPACE Metrics Service implements the SPACE framework for measuring developer experience across five key dimensions:

1. **Satisfaction**: How fulfilled and happy developers are
2. **Performance**: System and process outcomes (DORA metrics)
3. **Activity**: Developer actions and outputs
4. **Communication**: Team interaction and collaboration quality
5. **Efficiency**: Ability to complete work with minimal interruption

## Features

- **Automated Data Collection**: Pulls metrics from multiple sources (GitHub, Jenkins, Prometheus, Mattermost)
- **Survey Integration**: Integrates with NPS and pulse survey services
- **Privacy-Compliant**: Aggregates data, never exposes individual developer metrics
- **REST API**: Comprehensive API for accessing SPACE metrics
- **Prometheus Metrics**: Exposes metrics for Grafana dashboards
- **Real-time Analytics**: Calculates trends and correlations

## Quick Start

### Prerequisites

- Python 3.12+
- PostgreSQL 15+

### Local Development

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Set environment variables:
```bash
export DATABASE_URL="postgresql://space:space@localhost:5432/space_metrics"
```

3. Run database migrations:
```bash
alembic upgrade head
```

4. Start the service:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

## API Endpoints

### Metrics Retrieval

- `GET /api/v1/metrics/space` - Get all SPACE dimensions (aggregated)
- `GET /api/v1/metrics/space/{dimension}` - Get specific dimension
- `GET /health` - Health check
- `GET /metrics` - Prometheus metrics

## Privacy & Ethics

This service implements privacy-first design:
- No individual developer metrics exposed
- Aggregation threshold of 5+ developers
- Anonymous survey responses
- Opt-out capability for activity tracking

See full documentation for details on deployment, configuration, and integration.
