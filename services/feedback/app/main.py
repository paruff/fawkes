"""
FastAPI application for Feedback service.

This service provides feedback collection and management for Backstage.
Users can submit feedback with ratings, categories, and comments.
Admins can view and manage all feedback submissions.
"""
import os
import logging
import base64
from datetime import datetime
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, Header, Query, BackgroundTasks
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr
from prometheus_client import make_asgi_app
import asyncpg

# Import metrics from metrics module
from .metrics import (
    feedback_submissions_total,
    feedback_request_duration,
    feedback_time_to_action_seconds,
    update_all_metrics,
)

# Import sentiment analysis
from .sentiment import analyze_feedback_sentiment

# Import GitHub integration
from .github_integration import create_github_issue, update_issue_status, is_github_enabled

# Import AI triage
from .ai_triage import triage_feedback

# Import notifications
from .notifications import (
    notify_issue_created,
    notify_duplicate_detected,
    notify_high_priority_feedback,
    notify_automation_summary,
    is_notification_enabled,
)

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Configuration from environment
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql://feedback:feedback@db-feedback-dev-rw.fawkes.svc.cluster.local:5432/feedback_db"
)
# SECURITY: In production, ADMIN_TOKEN must be set via environment variable
# This default is ONLY for development/testing purposes
ADMIN_TOKEN = os.getenv("ADMIN_TOKEN", "admin-secret-token")

# Global database pool
db_pool = None


# Pydantic models
class FeedbackSubmission(BaseModel):
    """Request model for feedback submission."""

    rating: int = Field(..., description="Rating from 1-5", ge=1, le=5)
    category: str = Field(..., description="Feedback category", min_length=1, max_length=100)
    comment: str = Field(..., description="Feedback comment", min_length=1, max_length=2000)
    email: Optional[EmailStr] = Field(None, description="Optional email for follow-up")
    page_url: Optional[str] = Field(None, description="Page URL where feedback was submitted")
    feedback_type: str = Field("feedback", description="Type of feedback (feedback, bug_report, feature_request)")
    screenshot: Optional[str] = Field(None, description="Base64 encoded screenshot data (optional)")
    browser_info: Optional[str] = Field(None, description="Browser information (name, version)")
    user_agent: Optional[str] = Field(None, description="User agent string")
    create_github_issue: bool = Field(False, description="Whether to automatically create a GitHub issue")


class FeedbackResponse(BaseModel):
    """Response model for feedback item."""

    id: int = Field(..., description="Feedback ID")
    rating: int = Field(..., description="Rating from 1-5")
    category: str = Field(..., description="Feedback category")
    comment: str = Field(..., description="Feedback comment")
    email: Optional[str] = Field(None, description="User email")
    page_url: Optional[str] = Field(None, description="Page URL")
    status: str = Field(..., description="Feedback status")
    sentiment: Optional[str] = Field(None, description="Sentiment classification (positive/neutral/negative)")
    sentiment_compound: Optional[float] = Field(None, description="Sentiment compound score (-1 to +1)")
    feedback_type: Optional[str] = Field(None, description="Type of feedback")
    browser_info: Optional[str] = Field(None, description="Browser information")
    user_agent: Optional[str] = Field(None, description="User agent string")
    has_screenshot: bool = Field(False, description="Whether screenshot is available")
    github_issue_url: Optional[str] = Field(None, description="Associated GitHub issue URL")
    created_at: datetime = Field(..., description="Creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")


class FeedbackListResponse(BaseModel):
    """Response model for feedback list."""

    items: List[FeedbackResponse] = Field(..., description="List of feedback items")
    total: int = Field(..., description="Total number of feedback items")
    page: int = Field(..., description="Current page number")
    page_size: int = Field(..., description="Page size")


class StatusUpdate(BaseModel):
    """Request model for status update."""

    status: str = Field(..., description="New status (open, in_progress, resolved, dismissed)")


class FeedbackStats(BaseModel):
    """Aggregated feedback statistics."""

    total_feedback: int = Field(..., description="Total feedback count")
    average_rating: float = Field(..., description="Average rating")
    by_category: dict = Field(..., description="Feedback count by category")
    by_status: dict = Field(..., description="Feedback count by status")
    by_rating: dict = Field(..., description="Feedback count by rating")


class HealthResponse(BaseModel):
    """Health check response."""

    status: str = Field(..., description="Service status")
    service: str = Field(..., description="Service name")
    version: str = Field(..., description="Service version")
    database_connected: bool = Field(..., description="Database connection status")


# Database initialization
async def init_database():
    """Initialize database schema."""
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(DATABASE_URL)
        logger.info("✅ Connected to database successfully")

        # Create table if not exists
        async with db_pool.acquire() as conn:
            await conn.execute(
                """
                CREATE TABLE IF NOT EXISTS feedback (
                    id SERIAL PRIMARY KEY,
                    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
                    category VARCHAR(100) NOT NULL,
                    comment TEXT NOT NULL,
                    email VARCHAR(255),
                    page_url TEXT,
                    status VARCHAR(50) DEFAULT 'open',
                    sentiment VARCHAR(20),
                    sentiment_compound FLOAT,
                    sentiment_pos FLOAT,
                    sentiment_neu FLOAT,
                    sentiment_neg FLOAT,
                    feedback_type VARCHAR(50) DEFAULT 'feedback',
                    screenshot BYTEA,
                    browser_info TEXT,
                    user_agent TEXT,
                    github_issue_url TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    status_changed_at TIMESTAMP
                );

                CREATE INDEX IF NOT EXISTS idx_feedback_status ON feedback(status);
                CREATE INDEX IF NOT EXISTS idx_feedback_category ON feedback(category);
                CREATE INDEX IF NOT EXISTS idx_feedback_created_at ON feedback(created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_feedback_sentiment ON feedback(sentiment);
                CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback(feedback_type);
                CREATE INDEX IF NOT EXISTS idx_feedback_github_issue ON feedback(github_issue_url);

                -- Add status_changed_at column if it doesn't exist (migration)
                DO $$
                BEGIN
                    IF NOT EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name='feedback' AND column_name='status_changed_at'
                    ) THEN
                        ALTER TABLE feedback ADD COLUMN status_changed_at TIMESTAMP;
                    END IF;
                END $$;
            """
            )
            logger.info("✅ Database schema initialized")
    except Exception as e:
        logger.error(f"❌ Failed to connect to database: {e}")
        db_pool = None


# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan (startup/shutdown)."""
    # Startup
    await init_database()

    # Initial metrics refresh
    if db_pool:
        try:
            async with db_pool.acquire() as conn:
                await update_all_metrics(conn)
            logger.info("✅ Initial metrics refresh completed")
        except Exception as e:
            logger.warning(f"⚠️  Initial metrics refresh failed: {e}")

    yield

    # Shutdown
    if db_pool:
        await db_pool.close()
    logger.info("Shutting down feedback service")


# Create FastAPI app
app = FastAPI(
    title="Feedback Service",
    description="Feedback collection and management service for Backstage",
    version="1.0.0",
    lifespan=lifespan,
)

# Add CORS middleware
# SECURITY: In production, restrict allow_origins to specific domains
# Use environment variable ALLOWED_ORIGINS for production configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # TODO: Restrict to Backstage origin in production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Prometheus metrics
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


# Authentication dependency
async def verify_admin_token(authorization: Optional[str] = Header(None)):
    """Verify admin token for protected endpoints."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")

    token = authorization.replace("Bearer ", "")
    if token != ADMIN_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid admin token")
    return token


# Health check endpoint
@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Check service health and database connectivity."""
    db_connected = db_pool is not None
    if db_connected:
        try:
            async with db_pool.acquire() as conn:
                await conn.fetchval("SELECT 1")
        except Exception as e:
            logger.error(f"Database health check failed: {e}")
            db_connected = False

    return HealthResponse(
        status="healthy" if db_connected else "degraded",
        service="feedback-service",
        version="1.0.0",
        database_connected=db_connected,
    )


# Submit feedback (public endpoint)
@app.post("/api/v1/feedback", response_model=FeedbackResponse, status_code=201, tags=["Feedback"])
async def submit_feedback(feedback: FeedbackSubmission, background_tasks: BackgroundTasks):
    """Submit new feedback with optional screenshot and GitHub issue creation."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    # Validate feedback type
    valid_types = ["feedback", "bug_report", "feature_request"]
    if feedback.feedback_type not in valid_types:
        raise HTTPException(status_code=400, detail=f"Invalid feedback_type. Must be one of: {', '.join(valid_types)}")

    with feedback_request_duration.labels(endpoint="submit_feedback").time():
        try:
            # Analyze sentiment of the comment
            sentiment, compound, pos, neu, neg = analyze_feedback_sentiment(feedback.comment)

            # Process screenshot if provided
            screenshot_bytes = None
            if feedback.screenshot:
                try:
                    # Validate and decode base64 screenshot
                    # Remove data URL prefix if present (e.g., "data:image/png;base64,")
                    screenshot_data = feedback.screenshot
                    if "," in screenshot_data:
                        screenshot_data = screenshot_data.split(",", 1)[1]

                    screenshot_bytes = base64.b64decode(screenshot_data)

                    # Basic validation - check if it's a reasonable size (< 5MB)
                    if len(screenshot_bytes) > 5 * 1024 * 1024:
                        raise HTTPException(status_code=400, detail="Screenshot too large (max 5MB)")

                    logger.info(f"Screenshot received: {len(screenshot_bytes)} bytes")
                except Exception as e:
                    logger.error(f"Error processing screenshot: {e}")
                    raise HTTPException(
                        status_code=400, detail="Invalid screenshot data. Must be base64 encoded image."
                    )

            async with db_pool.acquire() as conn:
                row = await conn.fetchrow(
                    """
                    INSERT INTO feedback (
                        rating, category, comment, email, page_url, status,
                        sentiment, sentiment_compound, sentiment_pos, sentiment_neu, sentiment_neg,
                        feedback_type, screenshot, browser_info, user_agent
                    )
                    VALUES ($1, $2, $3, $4, $5, 'open', $6, $7, $8, $9, $10, $11, $12, $13, $14)
                    RETURNING id, rating, category, comment, email, page_url, status,
                              sentiment, sentiment_compound, feedback_type, browser_info,
                              user_agent, github_issue_url, created_at, updated_at,
                              (screenshot IS NOT NULL) as has_screenshot
                    """,
                    feedback.rating,
                    feedback.category,
                    feedback.comment,
                    feedback.email,
                    feedback.page_url,
                    sentiment,
                    compound,
                    pos,
                    neu,
                    neg,
                    feedback.feedback_type,
                    screenshot_bytes,
                    feedback.browser_info,
                    feedback.user_agent,
                )

                # Update metrics
                feedback_submissions_total.labels(category=feedback.category, rating=str(feedback.rating)).inc()

                feedback_id = row["id"]

                logger.info(
                    f"Feedback submitted: ID={feedback_id}, type={feedback.feedback_type}, "
                    f"category={feedback.category}, rating={feedback.rating}, "
                    f"sentiment={sentiment}, has_screenshot={row['has_screenshot']}"
                )

                # Create GitHub issue if requested and enabled
                github_issue_url = None
                if feedback.create_github_issue and is_github_enabled():
                    logger.info(f"Creating GitHub issue for feedback ID {feedback_id}")

                    # Create issue in background to not block response
                    async def create_issue_task():
                        success, issue_url, error = await create_github_issue(
                            feedback_id=feedback_id,
                            feedback_type=feedback.feedback_type,
                            category=feedback.category,
                            comment=feedback.comment,
                            page_url=feedback.page_url,
                            rating=feedback.rating,
                            email=feedback.email,
                            screenshot_data=feedback.screenshot if feedback.screenshot else None,
                            browser_info=feedback.browser_info,
                            user_agent=feedback.user_agent,
                        )

                        if success and issue_url:
                            # Update feedback record with GitHub issue URL
                            async with db_pool.acquire() as update_conn:
                                await update_conn.execute(
                                    """
                                    UPDATE feedback
                                    SET github_issue_url = $1, updated_at = CURRENT_TIMESTAMP
                                    WHERE id = $2
                                    """,
                                    issue_url,
                                    feedback_id,
                                )
                            logger.info(f"✅ Linked GitHub issue to feedback ID {feedback_id}: {issue_url}")
                        elif error:
                            logger.error(f"❌ Failed to create GitHub issue for feedback ID {feedback_id}: {error}")

                    # Add to background tasks
                    background_tasks.add_task(create_issue_task)

                elif feedback.create_github_issue and not is_github_enabled():
                    logger.warning("GitHub issue creation requested but GitHub integration not enabled")

                return FeedbackResponse(
                    id=row["id"],
                    rating=row["rating"],
                    category=row["category"],
                    comment=row["comment"],
                    email=row["email"],
                    page_url=row["page_url"],
                    status=row["status"],
                    sentiment=row["sentiment"],
                    sentiment_compound=row["sentiment_compound"],
                    feedback_type=row["feedback_type"],
                    browser_info=row["browser_info"],
                    user_agent=row["user_agent"],
                    has_screenshot=row["has_screenshot"],
                    github_issue_url=row["github_issue_url"],
                    created_at=row["created_at"],
                    updated_at=row["updated_at"],
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error submitting feedback: {e}")
            raise HTTPException(status_code=500, detail="Failed to submit feedback")


# List feedback (admin only)
@app.get("/api/v1/feedback", response_model=FeedbackListResponse, tags=["Feedback"])
async def list_feedback(
    page: int = Query(1, ge=1, description="Page number"),
    page_size: int = Query(20, ge=1, le=100, description="Page size"),
    status: Optional[str] = Query(None, description="Filter by status"),
    category: Optional[str] = Query(None, description="Filter by category"),
    _token: str = Depends(verify_admin_token),
):
    """List all feedback (admin only)."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    with feedback_request_duration.labels(endpoint="list_feedback").time():
        try:
            offset = (page - 1) * page_size

            # Build query with filters
            where_clauses = []
            params = []
            param_idx = 1

            if status:
                where_clauses.append(f"status = ${param_idx}")
                params.append(status)
                param_idx += 1

            if category:
                where_clauses.append(f"category = ${param_idx}")
                params.append(category)
                param_idx += 1

            where_sql = " WHERE " + " AND ".join(where_clauses) if where_clauses else ""

            async with db_pool.acquire() as conn:
                # Get total count
                count_query = f"SELECT COUNT(*) FROM feedback{where_sql}"
                total = await conn.fetchval(count_query, *params)

                # Get paginated results
                query = f"""
                    SELECT id, rating, category, comment, email, page_url, status,
                           sentiment, sentiment_compound, feedback_type, browser_info,
                           user_agent, github_issue_url, created_at, updated_at,
                           (screenshot IS NOT NULL) as has_screenshot
                    FROM feedback
                    {where_sql}
                    ORDER BY created_at DESC
                    LIMIT ${param_idx} OFFSET ${param_idx + 1}
                """
                params.extend([page_size, offset])

                rows = await conn.fetch(query, *params)

                items = [
                    FeedbackResponse(
                        id=row["id"],
                        rating=row["rating"],
                        category=row["category"],
                        comment=row["comment"],
                        email=row["email"],
                        page_url=row["page_url"],
                        status=row["status"],
                        sentiment=row["sentiment"],
                        sentiment_compound=row["sentiment_compound"],
                        feedback_type=row["feedback_type"],
                        browser_info=row["browser_info"],
                        user_agent=row["user_agent"],
                        has_screenshot=row["has_screenshot"],
                        github_issue_url=row["github_issue_url"],
                        created_at=row["created_at"],
                        updated_at=row["updated_at"],
                    )
                    for row in rows
                ]

                return FeedbackListResponse(items=items, total=total, page=page, page_size=page_size)
        except Exception as e:
            logger.error(f"Error listing feedback: {e}")
            raise HTTPException(status_code=500, detail="Failed to list feedback")


# Update feedback status (admin only)
@app.put("/api/v1/feedback/{feedback_id}/status", response_model=FeedbackResponse, tags=["Feedback"])
async def update_feedback_status(
    feedback_id: int,
    status_update: StatusUpdate,
    background_tasks: BackgroundTasks,
    _token: str = Depends(verify_admin_token),
):
    """Update feedback status (admin only) and sync with GitHub if applicable."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    # Validate status
    valid_statuses = ["open", "in_progress", "resolved", "dismissed"]
    if status_update.status not in valid_statuses:
        raise HTTPException(status_code=400, detail=f"Invalid status. Must be one of: {', '.join(valid_statuses)}")

    with feedback_request_duration.labels(endpoint="update_status").time():
        try:
            async with db_pool.acquire() as conn:
                # First, get the current status to check if it's changing
                current_row = await conn.fetchrow("SELECT status FROM feedback WHERE id = $1", feedback_id)

                if not current_row:
                    raise HTTPException(status_code=404, detail="Feedback not found")

                # Update status and set status_changed_at if status is actually changing
                # (and if it's changing from 'open' to any other status for first action tracking)
                status_is_changing = current_row["status"] != status_update.status
                first_action = current_row["status"] == "open" and status_update.status != "open"

                if status_is_changing and first_action:
                    row = await conn.fetchrow(
                        """
                        UPDATE feedback
                        SET status = $1, updated_at = CURRENT_TIMESTAMP,
                            status_changed_at = CURRENT_TIMESTAMP
                        WHERE id = $2
                        RETURNING id, rating, category, comment, email, page_url, status,
                                  sentiment, sentiment_compound, feedback_type, browser_info,
                                  user_agent, github_issue_url, created_at, updated_at,
                                  status_changed_at,
                                  (screenshot IS NOT NULL) as has_screenshot
                        """,
                        status_update.status,
                        feedback_id,
                    )

                    # Record time-to-action metric (time from created_at to now)
                    if row["created_at"] and row["status_changed_at"]:
                        time_to_action = (row["status_changed_at"] - row["created_at"]).total_seconds()
                        feedback_time_to_action_seconds.labels(category=row["category"]).observe(time_to_action)
                        logger.info(f"Time-to-action recorded: {time_to_action:.0f}s for feedback ID {feedback_id}")
                else:
                    row = await conn.fetchrow(
                        """
                        UPDATE feedback
                        SET status = $1, updated_at = CURRENT_TIMESTAMP
                        WHERE id = $2
                        RETURNING id, rating, category, comment, email, page_url, status,
                                  sentiment, sentiment_compound, feedback_type, browser_info,
                                  user_agent, github_issue_url, created_at, updated_at,
                                  (screenshot IS NOT NULL) as has_screenshot
                        """,
                        status_update.status,
                        feedback_id,
                    )

                if not row:
                    raise HTTPException(status_code=404, detail="Feedback not found")

                logger.info(f"Feedback status updated: ID={feedback_id}, status={status_update.status}")

                # If there's a GitHub issue linked, update it as well
                github_issue_url = row["github_issue_url"]
                if github_issue_url and is_github_enabled():
                    logger.info(f"Syncing status update to GitHub issue: {github_issue_url}")

                    # Update in background to not block response
                    async def update_github_task():
                        success, error = await update_issue_status(
                            issue_url=github_issue_url, new_status=status_update.status, feedback_id=feedback_id
                        )
                        if success:
                            logger.info(f"✅ Synced status to GitHub issue for feedback ID {feedback_id}")
                        elif error:
                            logger.error(f"❌ Failed to sync status to GitHub: {error}")

                    background_tasks.add_task(update_github_task)

                return FeedbackResponse(
                    id=row["id"],
                    rating=row["rating"],
                    category=row["category"],
                    comment=row["comment"],
                    email=row["email"],
                    page_url=row["page_url"],
                    status=row["status"],
                    sentiment=row["sentiment"],
                    sentiment_compound=row["sentiment_compound"],
                    feedback_type=row["feedback_type"],
                    browser_info=row["browser_info"],
                    user_agent=row["user_agent"],
                    has_screenshot=row["has_screenshot"],
                    github_issue_url=row["github_issue_url"],
                    created_at=row["created_at"],
                    updated_at=row["updated_at"],
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error updating feedback status: {e}")
            raise HTTPException(status_code=500, detail="Failed to update feedback status")


# Get feedback statistics (admin only)
@app.get("/api/v1/feedback/stats", response_model=FeedbackStats, tags=["Feedback"])
async def get_feedback_stats(_token: str = Depends(verify_admin_token)):
    """Get aggregated feedback statistics (admin only)."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    with feedback_request_duration.labels(endpoint="get_stats").time():
        try:
            async with db_pool.acquire() as conn:
                # Total and average
                total_and_avg = await conn.fetchrow("SELECT COUNT(*) as total, AVG(rating) as avg_rating FROM feedback")

                # By category
                category_rows = await conn.fetch("SELECT category, COUNT(*) as count FROM feedback GROUP BY category")
                by_category = {row["category"]: row["count"] for row in category_rows}

                # By status
                status_rows = await conn.fetch("SELECT status, COUNT(*) as count FROM feedback GROUP BY status")
                by_status = {row["status"]: row["count"] for row in status_rows}

                # By rating
                rating_rows = await conn.fetch(
                    "SELECT rating, COUNT(*) as count FROM feedback GROUP BY rating ORDER BY rating"
                )
                by_rating = {str(row["rating"]): row["count"] for row in rating_rows}

                return FeedbackStats(
                    total_feedback=total_and_avg["total"],
                    average_rating=float(total_and_avg["avg_rating"]) if total_and_avg["avg_rating"] else 0.0,
                    by_category=by_category,
                    by_status=by_status,
                    by_rating=by_rating,
                )
        except Exception as e:
            logger.error(f"Error getting feedback stats: {e}")
            raise HTTPException(status_code=500, detail="Failed to get feedback statistics")


# Refresh metrics endpoint (admin only)
@app.post("/api/v1/metrics/refresh", tags=["Metrics"])
async def refresh_metrics(_token: str = Depends(verify_admin_token)):
    """Manually refresh all Prometheus metrics (admin only)."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    try:
        async with db_pool.acquire() as conn:
            await update_all_metrics(conn)

        return {"status": "success", "message": "All metrics refreshed successfully"}
    except Exception as e:
        logger.error(f"Error refreshing metrics: {e}")
        raise HTTPException(status_code=500, detail="Failed to refresh metrics")


# Root endpoint
@app.get("/", tags=["Info"])
async def root():
    """Root endpoint with service information."""
    github_enabled = is_github_enabled()
    notification_enabled = is_notification_enabled()
    return {
        "service": "feedback-service",
        "version": "2.0.0",
        "description": "Enhanced feedback collection and management service for Backstage",
        "features": {
            "screenshot_capture": True,
            "github_integration": github_enabled,
            "sentiment_analysis": True,
            "contextual_feedback": True,
            "ai_triage": True,
            "duplicate_detection": github_enabled,
            "notifications": notification_enabled,
            "automation_pipeline": github_enabled,
            "feedback_types": ["feedback", "bug_report", "feature_request"],
        },
        "endpoints": {
            "health": "/health",
            "submit_feedback": "POST /api/v1/feedback",
            "list_feedback": "GET /api/v1/feedback (admin)",
            "update_status": "PUT /api/v1/feedback/{id}/status (admin)",
            "get_screenshot": "GET /api/v1/feedback/{id}/screenshot (admin)",
            "stats": "GET /api/v1/feedback/stats (admin)",
            "metrics": "/metrics",
            "refresh_metrics": "POST /api/v1/metrics/refresh (admin)",
            "triage_feedback": "POST /api/v1/feedback/{id}/triage (admin)",
            "automate_validated": "POST /api/v1/automation/process-validated (admin)",
        },
    }


# Get feedback screenshot (admin only)
@app.get("/api/v1/feedback/{feedback_id}/screenshot", tags=["Feedback"])
async def get_feedback_screenshot(feedback_id: int, _token: str = Depends(verify_admin_token)):
    """Get screenshot data for a specific feedback (admin only)."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    try:
        async with db_pool.acquire() as conn:
            row = await conn.fetchrow(
                """
                SELECT screenshot FROM feedback WHERE id = $1
                """,
                feedback_id,
            )

            if not row:
                raise HTTPException(status_code=404, detail="Feedback not found")

            screenshot_bytes = row["screenshot"]

            if not screenshot_bytes:
                raise HTTPException(status_code=404, detail="No screenshot available for this feedback")

            # Return screenshot as base64 encoded string
            screenshot_base64 = base64.b64encode(screenshot_bytes).decode("utf-8")

            return {
                "feedback_id": feedback_id,
                "screenshot": f"data:image/png;base64,{screenshot_base64}",
                "size_bytes": len(screenshot_bytes),
            }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error retrieving screenshot: {e}")
        raise HTTPException(status_code=500, detail="Failed to retrieve screenshot")


# Triage feedback with AI (admin only)
@app.post("/api/v1/feedback/{feedback_id}/triage", tags=["Automation"])
async def triage_feedback_endpoint(feedback_id: int, _token: str = Depends(verify_admin_token)):
    """
    Run AI triage on specific feedback submission.

    This endpoint analyzes feedback and provides:
    - Priority score and label (P0-P3)
    - Suggested GitHub labels
    - Potential duplicate detection
    - Suggested milestone
    - Recommendation on whether to create an issue
    """
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    try:
        async with db_pool.acquire() as conn:
            # Fetch feedback details
            row = await conn.fetchrow(
                """
                SELECT id, feedback_type, category, comment, rating,
                       sentiment_compound, status
                FROM feedback
                WHERE id = $1
                """,
                feedback_id,
            )

            if not row:
                raise HTTPException(status_code=404, detail="Feedback not found")

            # Run AI triage
            triage_result = await triage_feedback(
                feedback_id=row["id"],
                feedback_type=row["feedback_type"] or "feedback",
                category=row["category"],
                comment=row["comment"],
                rating=row["rating"],
                sentiment_compound=row["sentiment_compound"],
            )

            logger.info(f"Triage completed for feedback ID {feedback_id}: {triage_result}")

            return {"status": "success", "triage": triage_result}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error triaging feedback: {e}")
        raise HTTPException(status_code=500, detail="Failed to triage feedback")


# Automated processing of validated feedback (admin only)
@app.post("/api/v1/automation/process-validated", tags=["Automation"])
async def automate_validated_feedback(
    background_tasks: BackgroundTasks,
    min_rating: int = Query(None, ge=1, le=5, description="Minimum rating filter"),
    feedback_type: Optional[str] = Query(None, description="Filter by feedback type"),
    limit: int = Query(10, ge=1, le=100, description="Maximum number to process"),
    _token: str = Depends(verify_admin_token),
):
    """
    Automatically process validated feedback and create GitHub issues.

    This endpoint:
    1. Fetches validated feedback (status='open', optionally filtered)
    2. Runs AI triage on each feedback
    3. Creates GitHub issues for high-priority, non-duplicate feedback
    4. Sends notifications

    This can be called manually or triggered by a cron job.
    """
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")

    if not is_github_enabled():
        raise HTTPException(
            status_code=503, detail="GitHub integration not enabled. Set GITHUB_TOKEN environment variable."
        )

    try:
        async with db_pool.acquire() as conn:
            # Build query to fetch validated feedback
            query_parts = ["SELECT * FROM feedback WHERE status = 'open' AND github_issue_url IS NULL"]
            params = []
            param_idx = 1

            if min_rating:
                query_parts.append(f"AND rating <= ${param_idx}")
                params.append(min_rating)
                param_idx += 1

            if feedback_type:
                query_parts.append(f"AND feedback_type = ${param_idx}")
                params.append(feedback_type)
                param_idx += 1

            query_parts.append(f"ORDER BY created_at DESC LIMIT ${param_idx}")
            params.append(limit)

            query = " ".join(query_parts)

            feedback_items = await conn.fetch(query, *params)

            if not feedback_items:
                return {
                    "status": "success",
                    "message": "No validated feedback to process",
                    "processed": 0,
                    "issues_created": 0,
                }

            processed = 0
            issues_created = 0
            skipped_duplicates = 0
            errors = []

            # Process each feedback item
            for feedback in feedback_items:
                try:
                    # Run AI triage
                    triage_result = await triage_feedback(
                        feedback_id=feedback["id"],
                        feedback_type=feedback["feedback_type"] or "feedback",
                        category=feedback["category"],
                        comment=feedback["comment"],
                        rating=feedback["rating"],
                        sentiment_compound=feedback["sentiment_compound"],
                    )

                    processed += 1

                    # Skip if duplicates found
                    if not triage_result["should_create_issue"]:
                        skipped_duplicates += 1
                        logger.info(f"Skipping feedback ID {feedback['id']}: " f"{triage_result['triage_reason']}")

                        # Notify about duplicates
                        if triage_result["potential_duplicates"]:
                            background_tasks.add_task(
                                notify_duplicate_detected,
                                feedback["id"],
                                triage_result["potential_duplicates"],
                                feedback["category"],
                                feedback["comment"],
                            )

                        continue

                    # Create GitHub issue in background
                    async def create_issue_background():
                        success, issue_url, error = await create_github_issue(
                            feedback_id=feedback["id"],
                            feedback_type=feedback["feedback_type"] or "feedback",
                            category=feedback["category"],
                            comment=feedback["comment"],
                            page_url=feedback["page_url"],
                            rating=feedback["rating"],
                            email=feedback["email"],
                            screenshot_data=None,  # Screenshots not auto-attached in batch
                            browser_info=feedback["browser_info"],
                            user_agent=feedback["user_agent"],
                        )

                        if success and issue_url:
                            # Update feedback with GitHub issue URL
                            async with db_pool.acquire() as update_conn:
                                await update_conn.execute(
                                    """
                                    UPDATE feedback
                                    SET github_issue_url = $1,
                                        status = 'in_progress',
                                        updated_at = CURRENT_TIMESTAMP
                                    WHERE id = $2
                                    """,
                                    issue_url,
                                    feedback["id"],
                                )
                            logger.info(
                                f"✅ Automated issue created for feedback ID {feedback['id']}: "
                                f"{issue_url} (Priority: {triage_result['priority']})"
                            )

                            # Send notification about issue creation
                            await notify_issue_created(
                                feedback_id=feedback["id"],
                                issue_url=issue_url,
                                priority=triage_result["priority"],
                                category=feedback["category"],
                                feedback_type=feedback["feedback_type"] or "feedback",
                                comment_preview=feedback["comment"],
                            )
                        elif error:
                            logger.error(f"❌ Failed to create issue for feedback ID {feedback['id']}: {error}")

                    background_tasks.add_task(create_issue_background)
                    issues_created += 1

                except Exception as e:
                    error_msg = f"Error processing feedback ID {feedback['id']}: {str(e)}"
                    logger.error(error_msg)
                    errors.append(error_msg)

            result = {
                "status": "success",
                "message": f"Processed {processed} feedback items",
                "processed": processed,
                "issues_created": issues_created,
                "skipped_duplicates": skipped_duplicates,
                "errors": errors if errors else None,
            }

            logger.info(
                f"Automation complete: processed={processed}, "
                f"issues_created={issues_created}, skipped={skipped_duplicates}"
            )

            # Send automation summary notification
            background_tasks.add_task(notify_automation_summary, processed, issues_created, skipped_duplicates, errors)

            return result

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in automation pipeline: {e}")
        raise HTTPException(status_code=500, detail="Automation pipeline failed")
