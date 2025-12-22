"""
FastAPI application for AI-powered code review service.

This service listens for GitHub PR webhooks, analyzes code using LLM,
queries RAG for relevant patterns/standards, and posts review comments.
"""
import os
import time
import logging
import hashlib
import hmac
from typing import Dict, List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request, Header, BackgroundTasks
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge
import httpx

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration from environment
GITHUB_WEBHOOK_SECRET = os.getenv("GITHUB_WEBHOOK_SECRET", "")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
RAG_SERVICE_URL = os.getenv("RAG_SERVICE_URL", "http://rag-service.fawkes.svc:8000")
LLM_API_KEY = os.getenv("LLM_API_KEY", "")
LLM_API_URL = os.getenv("LLM_API_URL", "https://api.openai.com/v1/chat/completions")
LLM_MODEL = os.getenv("LLM_MODEL", "gpt-4")
SONARQUBE_URL = os.getenv("SONARQUBE_URL", "http://sonarqube.fawkes.svc:9000")
SONARQUBE_TOKEN = os.getenv("SONARQUBE_TOKEN", "")
FALSE_POSITIVE_THRESHOLD = float(os.getenv("FALSE_POSITIVE_THRESHOLD", "0.8"))

# Global HTTP client
http_client: Optional[httpx.AsyncClient] = None


# Pydantic models
class WebhookPayload(BaseModel):
    """GitHub webhook payload model."""
    action: str
    pull_request: Optional[Dict] = None
    repository: Optional[Dict] = None
    sender: Optional[Dict] = None


class ReviewComment(BaseModel):
    """Code review comment model."""
    path: str = Field(..., description="File path")
    line: int = Field(..., description="Line number")
    body: str = Field(..., description="Comment text")
    category: str = Field(..., description="Category: security, performance, quality, best_practices")
    severity: str = Field(..., description="Severity: critical, high, medium, low")
    confidence: float = Field(..., description="Confidence score 0-1")


class ReviewResult(BaseModel):
    """Review result model."""
    pr_number: int
    repository: str
    comments: List[ReviewComment]
    review_time_ms: float
    total_issues: int
    false_positive_rate: float


class HealthResponse(BaseModel):
    """Health check response."""
    status: str
    service: str
    version: str
    rag_connected: bool
    github_configured: bool
    llm_configured: bool


# Lifespan context manager for startup/shutdown
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan (startup/shutdown)."""
    # Startup
    global http_client
    logger.info("Starting AI Code Review Service")
    http_client = httpx.AsyncClient(timeout=30.0)
    
    # Check connections
    try:
        response = await http_client.get(f"{RAG_SERVICE_URL}/health")
        if response.status_code == 200:
            logger.info("✅ Connected to RAG service successfully")
        else:
            logger.warning(f"⚠️  RAG service returned status {response.status_code}")
    except Exception as e:
        logger.error(f"❌ Failed to connect to RAG service: {e}")
    
    yield
    
    # Shutdown
    logger.info("Shutting down AI Code Review Service")
    if http_client:
        await http_client.aclose()


# Create FastAPI app
app = FastAPI(
    title="AI Code Review Service",
    description="AI-powered code review bot that automatically reviews pull requests",
    version="0.1.0",
    lifespan=lifespan
)

# Prometheus metrics
WEBHOOK_COUNT = Counter(
    'ai_review_webhooks_total',
    'Total webhook events received',
    ['event_type', 'action']
)

REVIEW_COUNT = Counter(
    'ai_review_reviews_total',
    'Total reviews performed',
    ['repository', 'status']
)

REVIEW_DURATION = Histogram(
    'ai_review_duration_seconds',
    'Review processing duration',
    buckets=[1.0, 5.0, 10.0, 30.0, 60.0, 120.0]
)

COMMENT_COUNT = Counter(
    'ai_review_comments_total',
    'Total review comments posted',
    ['repository', 'category', 'severity']
)

FALSE_POSITIVE_RATE = Gauge(
    'ai_review_false_positive_rate',
    'Estimated false positive rate',
    ['repository']
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
    return response


@app.get("/", include_in_schema=False)
async def root():
    """Root endpoint."""
    return {
        "service": "ai-code-review",
        "status": "running",
        "version": "0.1.0"
    }


@app.get("/health")
async def health() -> HealthResponse:
    """Health check endpoint."""
    rag_connected = False
    try:
        if http_client:
            response = await http_client.get(f"{RAG_SERVICE_URL}/health", timeout=5.0)
            rag_connected = response.status_code == 200
    except Exception:
        pass
    
    return HealthResponse(
        status="UP",
        service="ai-code-review",
        version="0.1.0",
        rag_connected=rag_connected,
        github_configured=bool(GITHUB_TOKEN),
        llm_configured=bool(LLM_API_KEY)
    )


@app.get("/ready")
async def ready():
    """Readiness check endpoint."""
    if not GITHUB_TOKEN:
        raise HTTPException(status_code=503, detail="GitHub token not configured")
    if not LLM_API_KEY:
        raise HTTPException(status_code=503, detail="LLM API key not configured")
    
    return {
        "status": "READY",
        "service": "ai-code-review"
    }


def verify_github_signature(payload_body: bytes, signature_header: str) -> bool:
    """Verify GitHub webhook signature."""
    if not GITHUB_WEBHOOK_SECRET:
        logger.warning("GitHub webhook secret not configured, skipping verification")
        return True
    
    if not signature_header:
        return False
    
    hash_algorithm, github_signature = signature_header.split('=')
    algorithm = hashlib.sha256 if hash_algorithm == 'sha256' else hashlib.sha1
    encoded_secret = GITHUB_WEBHOOK_SECRET.encode()
    mac = hmac.new(encoded_secret, msg=payload_body, digestmod=algorithm)
    return hmac.compare_digest(mac.hexdigest(), github_signature)


@app.post("/webhook/github")
async def github_webhook(
    request: Request,
    background_tasks: BackgroundTasks,
    x_hub_signature_256: Optional[str] = Header(None),
    x_github_event: Optional[str] = Header(None)
):
    """Handle GitHub webhook events for pull requests."""
    # Read raw body for signature verification
    body = await request.body()
    
    # Verify signature
    if not verify_github_signature(body, x_hub_signature_256):
        logger.warning("Invalid webhook signature")
        raise HTTPException(status_code=401, detail="Invalid signature")
    
    # Parse payload
    try:
        payload = await request.json()
    except Exception as e:
        logger.error(f"Failed to parse webhook payload: {e}")
        raise HTTPException(status_code=400, detail="Invalid JSON payload")
    
    # Track webhook event
    action = payload.get('action', 'unknown')
    WEBHOOK_COUNT.labels(event_type=x_github_event or 'unknown', action=action).inc()
    
    # Process pull request events
    if x_github_event == 'pull_request' and action in ['opened', 'synchronize', 'reopened']:
        pr_data = payload.get('pull_request', {})
        repo_data = payload.get('repository', {})
        
        logger.info(f"Processing PR #{pr_data.get('number')} in {repo_data.get('full_name')}")
        
        # Process review in background
        background_tasks.add_task(
            process_pull_request_review,
            pr_data,
            repo_data
        )
        
        return JSONResponse(
            status_code=202,
            content={"message": "Review scheduled for processing"}
        )
    
    return JSONResponse(content={"message": "Event ignored"})


async def process_pull_request_review(pr_data: Dict, repo_data: Dict):
    """Process pull request review asynchronously."""
    start_time = time.time()
    pr_number = pr_data.get('number')
    repo_full_name = repo_data.get('full_name')
    
    try:
        logger.info(f"Starting review for PR #{pr_number} in {repo_full_name}")
        
        # Lazy import to avoid circular dependency and reduce startup time
        from .reviewer import ReviewEngine
        
        # Initialize review engine
        engine = ReviewEngine(
            rag_service_url=RAG_SERVICE_URL,
            llm_api_key=LLM_API_KEY,
            llm_api_url=LLM_API_URL,
            llm_model=LLM_MODEL,
            github_token=GITHUB_TOKEN,
            sonarqube_url=SONARQUBE_URL,
            sonarqube_token=SONARQUBE_TOKEN,
            http_client=http_client
        )
        
        # Perform review
        review_result = await engine.review_pull_request(pr_data, repo_data)
        
        # Track metrics
        duration = time.time() - start_time
        REVIEW_DURATION.observe(duration)
        REVIEW_COUNT.labels(repository=repo_full_name, status='success').inc()
        
        for comment in review_result.comments:
            COMMENT_COUNT.labels(
                repository=repo_full_name,
                category=comment.category,
                severity=comment.severity
            ).inc()
        
        FALSE_POSITIVE_RATE.labels(repository=repo_full_name).set(
            review_result.false_positive_rate
        )
        
        logger.info(
            f"Review completed for PR #{pr_number}: "
            f"{review_result.total_issues} issues found, "
            f"FP rate: {review_result.false_positive_rate:.2%}"
        )
        
    except Exception as e:
        logger.error(f"Failed to process review for PR #{pr_number}: {e}", exc_info=True)
        REVIEW_COUNT.labels(repository=repo_full_name, status='error').inc()


@app.get("/stats")
async def get_stats():
    """Get review statistics."""
    return {
        "service": "ai-code-review",
        "message": "Check /metrics endpoint for detailed statistics"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
