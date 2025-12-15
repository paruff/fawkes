"""
FastAPI application for ${{ values.name }}
"""
from fastapi import FastAPI
from prometheus_client import make_asgi_app, Counter, Histogram
import time
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="${{ values.name }}",
    description="${{ values.description }}",
    version="0.1.0"
)

# Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total',
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds',
    'HTTP request latency'
)

# Add prometheus metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


@app.middleware("http")
async def add_metrics(request, call_next):
    """Add prometheus metrics to all requests"""
    start_time = time.time()
    response = await call_next(request)
    duration = time.time() - start_time
    
    REQUEST_COUNT.labels(
        method=request.method,
        endpoint=request.url.path,
        status=response.status_code
    ).inc()
    
    REQUEST_LATENCY.observe(duration)
    
    return response


@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "service": "${{ values.name }}",
        "status": "running",
        "version": "0.1.0"
    }


@app.get("/health")
async def health():
    """Health check endpoint"""
    return {
        "status": "UP",
        "service": "${{ values.name }}"
    }


@app.get("/ready")
async def ready():
    """Readiness check endpoint"""
    # Add any readiness checks here (database connection, etc.)
    return {
        "status": "READY",
        "service": "${{ values.name }}"
    }


@app.get("/info")
async def info():
    """Service information endpoint"""
    return {
        "name": "${{ values.name }}",
        "description": "${{ values.description }}",
        "version": "0.1.0"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=${{ values.port }})
