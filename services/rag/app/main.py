"""
FastAPI application for RAG (Retrieval Augmented Generation) service.

This service provides context retrieval from Weaviate vector database
for AI assistants and code generation tools.
"""
import os
import time
import logging
from pathlib import Path
from typing import List, Optional, Dict
from contextlib import asynccontextmanager
from datetime import datetime

from fastapi import FastAPI, HTTPException, Query
from fastapi.responses import JSONResponse, HTMLResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel, Field
from prometheus_client import make_asgi_app, Counter, Histogram
import weaviate
from weaviate.util import generate_uuid5

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration from environment
WEAVIATE_URL = os.getenv("WEAVIATE_URL", "http://weaviate.fawkes.svc:80")
SCHEMA_NAME = os.getenv("SCHEMA_NAME", "FawkesDocument")
DEFAULT_TOP_K = int(os.getenv("DEFAULT_TOP_K", "5"))
DEFAULT_THRESHOLD = float(os.getenv("DEFAULT_THRESHOLD", "0.7"))

# Global Weaviate client
weaviate_client = None


# Pydantic models
class QueryRequest(BaseModel):
    """Request model for context query."""
    query: str = Field(..., description="Search query for context retrieval", min_length=1)
    top_k: Optional[int] = Field(DEFAULT_TOP_K, description="Number of results to return", ge=1, le=20)
    threshold: Optional[float] = Field(DEFAULT_THRESHOLD, description="Minimum relevance score threshold", ge=0.0, le=1.0)


class ContextResult(BaseModel):
    """Individual context result."""
    content: str = Field(..., description="Document content")
    relevance_score: float = Field(..., description="Relevance score (0-1)")
    source: str = Field(..., description="Source file path")
    title: Optional[str] = Field(None, description="Document title")
    category: Optional[str] = Field(None, description="Document category")


class QueryResponse(BaseModel):
    """Response model for context query."""
    query: str = Field(..., description="Original query")
    results: List[ContextResult] = Field(..., description="Ranked context results")
    count: int = Field(..., description="Number of results returned")
    retrieval_time_ms: float = Field(..., description="Query execution time in milliseconds")


class HealthResponse(BaseModel):
    """Health check response."""
    status: str = Field(..., description="Service status")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    weaviate_connected: bool = Field(..., description="Weaviate connection status")
    weaviate_url: str = Field(..., description="Weaviate URL")


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan (startup/shutdown)."""
    # Startup
    global weaviate_client
    logger.info(f"Connecting to Weaviate at {WEAVIATE_URL}")
    try:
        weaviate_client = weaviate.Client(WEAVIATE_URL)
        if weaviate_client.is_ready():
            logger.info("✅ Connected to Weaviate successfully")
        else:
            logger.warning("⚠️  Weaviate connection established but not ready")
    except Exception as e:
        logger.error(f"❌ Failed to connect to Weaviate: {e}")
        weaviate_client = None
    
    yield
    
    # Shutdown
    logger.info("Shutting down RAG service")


# Create FastAPI app
app = FastAPI(
    title="RAG Service",
    description="Retrieval Augmented Generation service for AI context",
    version="0.1.0",
    lifespan=lifespan
)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'rag_requests_total',
    'Total RAG requests',
    ['method', 'endpoint', 'status']
)

QUERY_LATENCY = Histogram(
    'rag_query_duration_seconds',
    'RAG query latency',
    buckets=[0.1, 0.25, 0.5, 1.0, 2.5, 5.0]
)

RELEVANCE_SCORE = Histogram(
    'rag_relevance_score',
    'RAG relevance scores',
    buckets=[0.5, 0.6, 0.7, 0.8, 0.9, 1.0]
)

# Add prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


@app.middleware("http")
async def add_metrics(request, call_next):
    """Add prometheus metrics to all requests."""
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    return response


@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint."""
    return {
        "service": "rag-service",
        "status": "running",
        "version": "0.1.0",
        "endpoints": {
            "query": "/api/v1/query",
            "health": "/api/v1/health",
            "stats": "/api/v1/stats",
            "dashboard": "/dashboard",
            "docs": "/docs",
            "metrics": "/metrics"
        }
    }


@app.get("/dashboard", response_class=HTMLResponse, include_in_schema=False, tags=["Dashboard"])
async def dashboard():
    """
    Serve the indexing dashboard.
    
    Provides a web UI for viewing indexing statistics and managing re-indexing.
    """
    # Path to dashboard HTML file
    # In production, this would be in a proper static files directory
    # For now, we'll return a simple inline version
    dashboard_path = Path(__file__).parent.parent.parent / "platform" / "apps" / "rag-service" / "dashboard.html"
    
    try:
        if dashboard_path.exists():
            with open(dashboard_path, 'r') as f:
                return HTMLResponse(content=f.read())
    except Exception as e:
        logger.warning(f"Could not load dashboard from {dashboard_path}: {e}")
    
    # Fallback: return simple inline dashboard
    return HTMLResponse(content="""
    <!DOCTYPE html>
    <html>
    <head>
        <title>RAG Service Dashboard</title>
        <style>
            body { font-family: Arial, sans-serif; margin: 40px; background: #f5f5f5; }
            .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; }
            h1 { color: #333; }
            .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
            .stat-card { background: #667eea; color: white; padding: 20px; border-radius: 8px; text-align: center; }
            .stat-value { font-size: 2em; font-weight: bold; }
            .stat-label { font-size: 0.9em; opacity: 0.9; }
            button { background: #667eea; color: white; border: none; padding: 15px 30px; border-radius: 5px; cursor: pointer; font-size: 1em; }
            button:hover { background: #5568d3; }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🤖 RAG Service Dashboard</h1>
            <p>Document Indexing Statistics & Management</p>
            <div class="stats" id="stats">Loading...</div>
            <button onclick="location.reload()">🔄 Refresh Stats</button>
        </div>
        <script>
            fetch('/api/v1/stats')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('stats').innerHTML = `
                        <div class="stat-card">
                            <div class="stat-value">${data.total_documents}</div>
                            <div class="stat-label">Total Documents</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value">${data.total_chunks}</div>
                            <div class="stat-label">Total Chunks</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value">${data.index_freshness_hours?.toFixed(1) || 'N/A'}</div>
                            <div class="stat-label">Hours Since Update</div>
                        </div>
                        <div class="stat-card">
                            <div class="stat-value">${data.storage_usage_mb?.toFixed(1) || 'N/A'}</div>
                            <div class="stat-label">Storage (MB)</div>
                        </div>
                    `;
                })
                .catch(err => {
                    document.getElementById('stats').innerHTML = '<p>Error loading stats: ' + err.message + '</p>';
                });
        </script>
    </body>
    </html>
    """)


@app.get("/api/v1/health", response_model=HealthResponse, tags=["Health"])
async def health():
    """
    Health check endpoint.
    
    Returns service status and Weaviate connection status.
    """
    weaviate_connected = False
    if weaviate_client:
        try:
            weaviate_connected = weaviate_client.is_ready()
        except Exception as e:
            logger.warning(f"Weaviate health check failed: {e}")
    
    return HealthResponse(
        status="UP" if weaviate_connected else "DEGRADED",
        service="rag-service",
        version="0.1.0",
        weaviate_connected=weaviate_connected,
        weaviate_url=WEAVIATE_URL
    )


@app.post("/api/v1/query", response_model=QueryResponse, tags=["Query"])
async def query_context(request: QueryRequest):
    """
    Query endpoint for context retrieval.
    
    Retrieves relevant context from Weaviate vector database based on
    semantic similarity to the provided query.
    
    Args:
        request: Query request with query text, top_k, and threshold
        
    Returns:
        QueryResponse with ranked results and metadata
        
    Raises:
        HTTPException: If Weaviate is not connected or query fails
    """
    # Check Weaviate connection
    if not weaviate_client:
        raise HTTPException(
            status_code=503,
            detail="Weaviate client not initialized"
        )
    
    try:
        if not weaviate_client.is_ready():
            raise HTTPException(
                status_code=503,
                detail="Weaviate is not ready"
            )
    except Exception as e:
        logger.error(f"Weaviate readiness check failed: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"Weaviate connection error: {str(e)}"
        )
    
    # Start timing
    start_time = time.time()
    
    try:
        # Execute semantic search query
        logger.info(f"Executing query: '{request.query}' (top_k={request.top_k}, threshold={request.threshold})")
        
        result = (
            weaviate_client.query
            .get(SCHEMA_NAME, ["title", "content", "filepath", "category"])
            .with_near_text({"concepts": [request.query]})
            .with_limit(request.top_k)
            .with_additional(["certainty", "distance"])
            .do()
        )
        
        # Calculate retrieval time
        retrieval_time_ms = (time.time() - start_time) * 1000
        QUERY_LATENCY.observe(retrieval_time_ms / 1000)
        
        # Parse results
        if "data" not in result or "Get" not in result["data"]:
            logger.warning("No data returned from Weaviate")
            return QueryResponse(
                query=request.query,
                results=[],
                count=0,
                retrieval_time_ms=retrieval_time_ms
            )
        
        documents = result["data"]["Get"].get(SCHEMA_NAME, [])
        
        # Filter and format results
        context_results = []
        for doc in documents:
            # Get certainty score (Weaviate's relevance metric, 0-1)
            certainty = doc.get("_additional", {}).get("certainty", 0.0)
            
            # Apply threshold filter
            if certainty >= request.threshold:
                RELEVANCE_SCORE.observe(certainty)
                
                context_results.append(
                    ContextResult(
                        content=doc.get("content", ""),
                        relevance_score=round(certainty, 3),
                        source=doc.get("filepath", "unknown"),
                        title=doc.get("title"),
                        category=doc.get("category")
                    )
                )
        
        logger.info(f"Query completed in {retrieval_time_ms:.2f}ms, returned {len(context_results)} results")
        
        return QueryResponse(
            query=request.query,
            results=context_results,
            count=len(context_results),
            retrieval_time_ms=round(retrieval_time_ms, 2)
        )
        
    except Exception as e:
        logger.error(f"Query execution failed: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Query execution failed: {str(e)}"
        )


@app.get("/ready", include_in_schema=False)
async def ready():
    """
    Readiness check endpoint for Kubernetes.
    
    Returns 200 if service is ready to accept traffic, 503 otherwise.
    """
    if weaviate_client:
        try:
            if weaviate_client.is_ready():
                return {"status": "READY"}
        except Exception:
            pass
    
    raise HTTPException(status_code=503, detail="Service not ready")


class StatsResponse(BaseModel):
    """Statistics response."""
    total_documents: int = Field(..., description="Total number of documents indexed")
    total_chunks: int = Field(..., description="Total number of chunks indexed")
    categories: Dict[str, int] = Field(..., description="Document count by category")
    last_indexed: Optional[str] = Field(None, description="Most recent indexing timestamp")
    index_freshness_hours: Optional[float] = Field(None, description="Hours since last indexing")
    storage_usage_mb: Optional[float] = Field(None, description="Approximate storage usage in MB")
    avg_query_time_ms: Optional[float] = Field(None, description="Average query time in milliseconds")


@app.get("/api/v1/stats", response_model=StatsResponse, tags=["Stats"])
async def get_stats():
    """
    Get indexing statistics and metrics.
    
    Returns information about indexed documents, storage usage,
    and search performance.
    """
    # Check Weaviate connection
    if not weaviate_client:
        raise HTTPException(
            status_code=503,
            detail="Weaviate client not initialized"
        )
    
    try:
        if not weaviate_client.is_ready():
            raise HTTPException(
                status_code=503,
                detail="Weaviate is not ready"
            )
    except Exception as e:
        logger.error(f"Weaviate readiness check failed: {e}")
        raise HTTPException(
            status_code=503,
            detail=f"Weaviate connection error: {str(e)}"
        )
    
    try:
        # Get all documents to calculate stats
        # Note: Limited to 10000 to prevent memory issues
        # For larger deployments, consider implementing pagination
        MAX_STATS_DOCUMENTS = 10000
        result = (
            weaviate_client.query
            .get(SCHEMA_NAME, ["category", "indexed_at", "content"])
            .with_limit(MAX_STATS_DOCUMENTS)
            .do()
        )
        
        documents = result.get("data", {}).get("Get", {}).get(SCHEMA_NAME, [])
        
        # Calculate statistics
        total_chunks = len(documents)
        
        # Count unique documents (files)
        # Documents are considered unique by their filepath (without chunk suffix)
        unique_docs = set()
        categories_count = {}
        last_indexed_timestamp = None
        storage_size_chars = 0
        
        for doc in documents:
            # Count by category
            category = doc.get("category", "unknown")
            categories_count[category] = categories_count.get(category, 0) + 1
            
            # Track last indexed
            indexed_at = doc.get("indexed_at")
            if indexed_at:
                if not last_indexed_timestamp or indexed_at > last_indexed_timestamp:
                    last_indexed_timestamp = indexed_at
            
            # Estimate storage (sum of content lengths)
            content = doc.get("content", "")
            storage_size_chars += len(content)
        
        # Calculate index freshness
        index_freshness_hours = None
        if last_indexed_timestamp:
            try:
                # Parse ISO format timestamp and ensure timezone awareness
                last_indexed_dt = datetime.fromisoformat(last_indexed_timestamp.replace("Z", "+00:00"))
                # Use timezone-aware datetime for comparison
                if last_indexed_dt.tzinfo:
                    now = datetime.now(last_indexed_dt.tzinfo)
                else:
                    now = datetime.now()
                    last_indexed_dt = last_indexed_dt.replace(tzinfo=None)
                
                delta = now - last_indexed_dt
                index_freshness_hours = round(delta.total_seconds() / 3600, 2)
            except Exception as e:
                logger.warning(f"Failed to parse timestamp: {e}")
        
        # Estimate storage in MB (rough approximation)
        # Average 1 char ≈ 1 byte, plus overhead for metadata
        storage_usage_mb = round((storage_size_chars * 1.5) / (1024 * 1024), 2)
        
        # Get average query time from Prometheus metrics
        # For now, we'll return None as we'd need to query Prometheus
        avg_query_time_ms = None
        
        # Count unique documents (estimate based on chunks)
        # Average chunks per document - this is an approximation
        AVG_CHUNKS_PER_DOCUMENT = 3
        estimated_unique_docs = max(1, total_chunks // AVG_CHUNKS_PER_DOCUMENT)
        
        return StatsResponse(
            total_documents=estimated_unique_docs,
            total_chunks=total_chunks,
            categories=categories_count,
            last_indexed=last_indexed_timestamp,
            index_freshness_hours=index_freshness_hours,
            storage_usage_mb=storage_usage_mb,
            avg_query_time_ms=avg_query_time_ms
        )
        
    except Exception as e:
        logger.error(f"Failed to get stats: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"Failed to retrieve statistics: {str(e)}"
        )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
