# RAG Indexers

This directory contains specialized indexers for different documentation sources in the Fawkes RAG system.

## Available Indexers

### 1. GitHub Repository Indexer (`github.py`)

Indexes documentation from GitHub repositories.

**Features:**

- Fetches repositories from organizations or specific repos
- Extracts README and markdown files from `docs/` directories
- Handles rate limiting automatically
- Chunks content for optimal embedding
- Tracks changes with MD5 hashing for incremental updates
- Skips binary files and large files (>1MB)

**Usage:**

```bash
# Index all repos in an organization
python -m indexers.github \
  --github-token ghp_xxxxx \
  --org paruff \
  --weaviate-url http://localhost:8080

# Index specific repository
python -m indexers.github \
  --github-token ghp_xxxxx \
  --repo paruff/fawkes \
  --weaviate-url http://localhost:8080

# Dry run to preview what would be indexed
python -m indexers.github \
  --github-token ghp_xxxxx \
  --org paruff \
  --dry-run

# Force re-index all documents
python -m indexers.github \
  --github-token ghp_xxxxx \
  --repo paruff/fawkes \
  --force-reindex
```

**Configuration:**

- `--github-token` (required): GitHub personal access token
- `--weaviate-url`: Weaviate instance URL (default: http://localhost:8080)
- `--org`: GitHub organization name
- `--repo`: Specific repository (format: owner/repo)
- `--dry-run`: Preview mode without indexing
- `--force-reindex`: Re-index even if unchanged

**Rate Limiting:**
The indexer automatically handles GitHub API rate limits and will wait when approaching limits.

### 2. Backstage TechDocs Indexer (`techdocs.py`)

Indexes TechDocs from Backstage catalog.

**Features:**

- Fetches all catalog entities from Backstage API
- Identifies entities with TechDocs
- Parses markdown and HTML content
- Extracts sections and headings for better context
- Chunks content optimally
- Links back to Backstage URLs

**Usage:**

```bash
# Index TechDocs from Backstage
python -m indexers.techdocs \
  --backstage-url http://backstage.example.com \
  --weaviate-url http://localhost:8080

# With authentication token
python -m indexers.techdocs \
  --backstage-url http://backstage.example.com \
  --token your_auth_token \
  --weaviate-url http://localhost:8080

# Dry run
python -m indexers.techdocs \
  --backstage-url http://backstage.example.com \
  --dry-run

# Force re-index
python -m indexers.techdocs \
  --backstage-url http://backstage.example.com \
  --force-reindex
```

**Configuration:**

- `--backstage-url` (required): Backstage instance URL
- `--weaviate-url`: Weaviate instance URL (default: http://localhost:8080)
- `--token`: Optional Backstage authentication token
- `--dry-run`: Preview mode without indexing
- `--force-reindex`: Re-index even if unchanged

**How it works:**

1. Fetches all entities from Backstage catalog API
2. Filters for entities with TechDocs annotations
3. Retrieves TechDocs metadata and content
4. Parses HTML/markdown content
5. Extracts sections based on headings
6. Chunks and indexes to Weaviate

## Common Features

All indexers share these features:

- **Incremental Updates**: Uses MD5 hashing to detect changes and skip unchanged files
- **Smart Chunking**: Splits documents into ~512-token chunks while preserving paragraph boundaries
- **Metadata Tracking**: Stores filepath, category, hash, chunk index, and timestamp
- **Dry Run Mode**: Preview what would be indexed without making changes
- **Error Handling**: Gracefully handles API errors and continues processing
- **Progress Reporting**: Shows detailed progress during indexing

## Testing

Run tests for the indexers:

```bash
# Test GitHub indexer
pytest tests/unit/indexers/test_github.py -v

# Test TechDocs indexer
pytest tests/unit/indexers/test_techdocs.py -v

# Test all indexers
pytest tests/unit/indexers/ -v
```

## Architecture

```
┌─────────────────────────────┐
│   GitHub API / Backstage    │
│                             │
│   - Repositories            │
│   - TechDocs                │
│   - Documentation           │
└──────────┬──────────────────┘
           │
           │ Fetch & Parse
           ▼
┌─────────────────────────────┐
│      Indexer Scripts        │
│                             │
│   - github.py               │
│   - techdocs.py             │
│                             │
│   Functions:                │
│   - Content extraction      │
│   - Change detection (MD5)  │
│   - Smart chunking          │
│   - Metadata enrichment     │
└──────────┬──────────────────┘
           │
           │ Index & Store
           ▼
┌─────────────────────────────┐
│    Weaviate Vector DB       │
│                             │
│   Schema: FawkesDocument    │
│   - title                   │
│   - content (vectorized)    │
│   - filepath                │
│   - category                │
│   - fileHash                │
│   - chunkIndex              │
│   - indexed_at              │
└─────────────────────────────┘
```

## Best Practices

### 1. GitHub Token Permissions

Your GitHub token needs:

- `repo` scope for private repositories
- `public_repo` scope for public repositories only
- `read:org` scope for organization repositories

### 2. Scheduling

Run indexers on a schedule using the CronJob:

```yaml
# See platform/apps/rag-service/cronjob-indexing.yaml
schedule: "0 2 * * *" # Daily at 2 AM UTC
```

### 3. Rate Limiting

- GitHub: ~5000 requests/hour for authenticated requests
- Backstage: Check your instance's rate limits

### 4. Incremental Updates

Indexers automatically detect changes using file hashes. Only changed documents are re-indexed, making daily runs efficient.

### 5. Storage Considerations

- Each document chunk is ~2KB
- 1000 documents ≈ 3000 chunks ≈ 6MB
- Monitor Weaviate storage with `/api/v1/stats` endpoint

## Troubleshooting

### GitHub Indexer Issues

**Rate limit exceeded:**

- Wait for rate limit reset (indexer will do this automatically)
- Use `--dry-run` to preview before indexing
- Index specific repos instead of entire organization

**Missing files:**

- Check excluded patterns in `EXCLUDE_PATTERNS`
- Verify file extensions in `MD_EXTENSIONS`

### TechDocs Indexer Issues

**No TechDocs found:**

- Verify entities have `backstage.io/techdocs-ref` annotation
- Check TechDocs are built and published
- Try accessing TechDocs in Backstage UI first

**Authentication errors:**

- Verify `--token` is valid
- Check token has correct permissions
- Some Backstage instances allow unauthenticated access

### General Issues

**Connection errors:**

- Verify Weaviate is running: `curl http://localhost:8080/v1/.well-known/ready`
- Check network connectivity
- Verify URLs are correct

**Out of memory:**

- Reduce batch size in indexer code
- Process fewer documents at once
- Increase system resources

## Extending Indexers

To create a new indexer:

1. Create new file in `services/rag/indexers/`
2. Implement these methods:
   - `__init__()`: Initialize connections
   - `fetch_*()`: Retrieve content
   - `chunk_content()`: Split into chunks
   - `index_*()`: Store in Weaviate
3. Add tests in `tests/unit/indexers/`
4. Update this README

Example template:

```python
class MyIndexer:
    def __init__(self, source_url, weaviate_url, dry_run=False):
        self.source_url = source_url
        self.weaviate_url = weaviate_url
        self.dry_run = dry_run
        if not dry_run:
            self._connect_weaviate()

    def fetch_content(self):
        # Retrieve content from source
        pass

    def chunk_content(self, content):
        # Split content into chunks
        pass

    def index_content(self, content, metadata):
        # Store in Weaviate
        pass
```

## See Also

- [RAG Service README](../README.md)
- [Main indexing script](../scripts/index-docs.py)
- [API documentation](../app/main.py)
- [Dashboard](../../platform/apps/rag-service/dashboard.html)
