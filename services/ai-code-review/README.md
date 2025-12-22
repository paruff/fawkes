# AI Code Review Service

## Overview

The AI Code Review Service is an automated code review bot that analyzes pull requests using AI/LLM technology. It provides intelligent feedback on security, performance, code quality, test coverage, and documentation.

## Features

- **Automated PR Review**: Listens for GitHub pull request webhooks and automatically reviews code changes
- **Multi-Category Analysis**: Reviews code for:
  - Security vulnerabilities (injection, auth issues, secrets)
  - Performance issues (N+1 queries, inefficient algorithms)
  - Best practices (SOLID, DRY, clean code)
  - Test coverage gaps
  - Documentation quality
- **RAG Integration**: Queries internal documentation and standards for context-aware reviews
- **SonarQube Integration**: Combines AI insights with SonarQube static analysis results
- **Smart Filtering**: Filters low-confidence findings to minimize false positives (<20% target)
- **Prometheus Metrics**: Tracks review statistics and false positive rates

## Architecture

```
┌─────────────┐
│   GitHub    │
│  Webhooks   │
└──────┬──────┘
       │
       v
┌─────────────────────────────────┐
│  AI Code Review Service         │
│  ┌─────────────────────────┐   │
│  │  Webhook Handler        │   │
│  └────────┬────────────────┘   │
│           │                     │
│           v                     │
│  ┌─────────────────────────┐   │
│  │  Review Engine          │   │
│  │  - Fetch PR diff        │   │
│  │  - Query RAG            │   │
│  │  - Call LLM             │   │
│  │  - Merge findings       │   │
│  └────────┬────────────────┘   │
│           │                     │
│           v                     │
│  ┌─────────────────────────┐   │
│  │  GitHub API Client      │   │
│  │  - Post review comments │   │
│  └─────────────────────────┘   │
└─────────────────────────────────┘
       │              │
       v              v
┌──────────┐   ┌─────────────┐
│   RAG    │   │  SonarQube  │
│ Service  │   │             │
└──────────┘   └─────────────┘
```

## Prerequisites

- Python 3.12+
- Access to GitHub API (webhook secret and token)
- Access to LLM API (OpenAI GPT-4 or Anthropic Claude)
- RAG service running (optional but recommended)
- SonarQube instance (optional)

## Configuration

Set the following environment variables:

```bash
# GitHub Configuration
GITHUB_WEBHOOK_SECRET=<your-webhook-secret>
GITHUB_TOKEN=<your-github-token>

# LLM Configuration
LLM_API_KEY=<your-openai-or-anthropic-api-key>
LLM_API_URL=https://api.openai.com/v1/chat/completions
LLM_MODEL=gpt-4

# RAG Service
RAG_SERVICE_URL=http://rag-service.fawkes.svc:8000

# SonarQube (Optional)
SONARQUBE_URL=http://sonarqube.fawkes.svc:9000
SONARQUBE_TOKEN=<your-sonarqube-token>

# Quality Settings
FALSE_POSITIVE_THRESHOLD=0.8
```

## Quick Start

### 1. Install Dependencies

```bash
cd services/ai-code-review
pip install -r requirements.txt
```

### 2. Run Locally

```bash
export GITHUB_TOKEN=<your-token>
export LLM_API_KEY=<your-api-key>
export RAG_SERVICE_URL=http://localhost:8001

uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Configure GitHub Webhook

1. Go to your repository settings → Webhooks
2. Add webhook with URL: `https://your-domain.com/webhook/github`
3. Set content type: `application/json`
4. Set secret: Same as `GITHUB_WEBHOOK_SECRET`
5. Select events: `Pull requests`

### 4. Test the Service

```bash
# Health check
curl http://localhost:8000/health

# Create a test PR to trigger review
gh pr create --title "Test PR" --body "Testing AI review"
```

## API Endpoints

### Health Check
```
GET /health
```

Returns service health status and configuration.

### Ready Check
```
GET /ready
```

Returns readiness status (checks if required config is present).

### GitHub Webhook
```
POST /webhook/github
```

Receives GitHub webhook events for pull requests.

### Metrics
```
GET /metrics
```

Prometheus metrics endpoint.

## Development

### Running Tests

```bash
# Install dev dependencies
pip install -r requirements-dev.txt

# Run tests
pytest tests/ -v

# Run with coverage
pytest tests/ --cov=app --cov-report=term-missing
```

### Project Structure

```
services/ai-code-review/
├── app/
│   ├── __init__.py
│   ├── main.py           # FastAPI application
│   └── reviewer.py       # Review engine logic
├── prompts/
│   ├── loader.py         # Prompt loader
│   ├── security.txt      # Security review prompt
│   ├── performance.txt   # Performance review prompt
│   ├── best_practices.txt
│   ├── test_coverage.txt
│   └── documentation.txt
├── integrations/
│   ├── __init__.py
│   └── sonarqube.py      # SonarQube integration
├── tests/
│   ├── unit/             # Unit tests
│   └── integration/      # Integration tests
├── Dockerfile
├── requirements.txt
├── requirements-dev.txt
└── README.md
```

## Review Categories

### Security
- SQL injection, XSS, CSRF vulnerabilities
- Authentication and authorization issues
- Secrets in code
- Input validation
- Insecure cryptography

### Performance
- N+1 query problems
- Inefficient algorithms
- Memory leaks
- Blocking operations in async code
- Missing caching

### Best Practices
- SOLID principles
- DRY violations
- Code organization
- Naming conventions
- Error handling

### Test Coverage
- Missing unit tests
- Missing edge case tests
- Missing error condition tests
- Test quality issues

### Documentation
- Missing docstrings
- Missing API documentation
- Unclear code without comments
- Missing README updates

## Metrics

The service exposes Prometheus metrics:

- `ai_review_webhooks_total` - Total webhook events received
- `ai_review_reviews_total` - Total reviews performed
- `ai_review_duration_seconds` - Review processing duration
- `ai_review_comments_total` - Total review comments posted
- `ai_review_false_positive_rate` - Estimated false positive rate

## Deployment

### Docker

```bash
# Build image
docker build -t ai-code-review:latest .

# Run container
docker run -p 8000:8000 \
  -e GITHUB_TOKEN=<token> \
  -e LLM_API_KEY=<key> \
  -e RAG_SERVICE_URL=http://rag-service:8000 \
  ai-code-review:latest
```

### Kubernetes

See `k8s/deployment.yaml` for Kubernetes manifests.

## Troubleshooting

### Webhook not triggering reviews

1. Check GitHub webhook delivery status
2. Verify webhook secret matches configuration
3. Check service logs for errors

### High false positive rate

1. Adjust `FALSE_POSITIVE_THRESHOLD` to filter more aggressively
2. Review and improve prompt templates
3. Add more context from RAG service

### LLM API errors

1. Check API key is valid
2. Verify rate limits not exceeded
3. Check network connectivity to LLM API

## Contributing

1. Add tests for new features
2. Update prompts in `prompts/` directory
3. Follow existing code style
4. Update documentation

## License

Copyright (c) 2024 Fawkes Platform
