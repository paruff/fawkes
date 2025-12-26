"""
FastAPI application for NPS Survey service.

This service provides NPS survey automation including:
- Quarterly survey scheduling
- Unique survey link generation per user
- Survey response collection
- NPS score calculation
- Integration with Mattermost for survey distribution
"""
import os
import logging
import secrets
from datetime import datetime, timedelta
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Depends, Query, Path
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, EmailStr
from prometheus_client import make_asgi_app, Counter, Histogram, Gauge
import asyncpg

# Configure logging
logging.basicConfig(level=logging.INFO, format="%(asctime)s - %(name)s - %(levelname)s - %(message)s")
logger = logging.getLogger(__name__)

# Configuration from environment
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://nps:nps@db-nps-dev-rw.fawkes.svc.cluster.local:5432/nps_db")
SURVEY_EXPIRY_DAYS = int(os.getenv("SURVEY_EXPIRY_DAYS", "30"))
REMINDER_DAYS = int(os.getenv("REMINDER_DAYS", "7"))

# Global database pool
# NOTE: Using global for simplicity. For better testability, consider
# dependency injection pattern with app.state.db_pool
db_pool = None

# Prometheus metrics
nps_responses = Counter(
    "nps_responses_total", "Total number of NPS responses", ["score_type"]  # promoter, passive, detractor
)
nps_score_gauge = Gauge("nps_score", "Current NPS score", ["period"])  # quarterly, overall
survey_request_duration = Histogram(
    "nps_survey_request_duration_seconds", "Time spent processing NPS survey requests", ["endpoint"]
)


# Pydantic models
class SurveyResponse(BaseModel):
    """Request model for NPS survey response."""

    score: int = Field(..., description="NPS score from 0-10", ge=0, le=10)
    comment: Optional[str] = Field(None, description="Optional feedback comment", max_length=2000)


class SurveyResponseOut(BaseModel):
    """Response model for survey response."""

    id: int
    user_id: str
    score: int
    comment: Optional[str]
    score_type: str  # promoter, passive, detractor
    created_at: datetime


class SurveyLink(BaseModel):
    """Survey link model."""

    token: str
    user_id: str
    email: str
    expires_at: datetime
    responded: bool
    created_at: datetime


class NPSMetrics(BaseModel):
    """NPS metrics calculation."""

    nps_score: float = Field(..., description="NPS score (-100 to 100)")
    total_responses: int
    promoters: int
    passives: int
    detractors: int
    response_rate: float
    period_start: datetime
    period_end: datetime


class HealthResponse(BaseModel):
    """Health check response."""

    status: str
    service: str
    version: str
    database_connected: bool


# Database initialization
async def init_database():
    """Initialize database schema."""
    global db_pool
    try:
        db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10)
        logger.info("✅ Connected to database successfully")

        # Create tables if not exists
        async with db_pool.acquire() as conn:
            await conn.execute(
                """
                -- Survey links table
                CREATE TABLE IF NOT EXISTS survey_links (
                    id SERIAL PRIMARY KEY,
                    token VARCHAR(64) UNIQUE NOT NULL,
                    user_id VARCHAR(255) NOT NULL,
                    email VARCHAR(255) NOT NULL,
                    expires_at TIMESTAMP NOT NULL,
                    responded BOOLEAN DEFAULT FALSE,
                    reminder_sent BOOLEAN DEFAULT FALSE,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                );

                -- Survey responses table
                CREATE TABLE IF NOT EXISTS survey_responses (
                    id SERIAL PRIMARY KEY,
                    user_id VARCHAR(255) NOT NULL,
                    token VARCHAR(64) NOT NULL,
                    score INTEGER NOT NULL CHECK (score >= 0 AND score <= 10),
                    score_type VARCHAR(20) NOT NULL,
                    comment TEXT,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    FOREIGN KEY (token) REFERENCES survey_links(token)
                );

                -- Survey campaigns table
                CREATE TABLE IF NOT EXISTS survey_campaigns (
                    id SERIAL PRIMARY KEY,
                    quarter VARCHAR(10) NOT NULL,
                    year INTEGER NOT NULL,
                    started_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    completed_at TIMESTAMP,
                    total_sent INTEGER DEFAULT 0,
                    total_responses INTEGER DEFAULT 0,
                    nps_score FLOAT,
                    UNIQUE(quarter, year)
                );

                -- Indexes
                CREATE INDEX IF NOT EXISTS idx_survey_links_token ON survey_links(token);
                CREATE INDEX IF NOT EXISTS idx_survey_links_user ON survey_links(user_id);
                CREATE INDEX IF NOT EXISTS idx_survey_links_expires ON survey_links(expires_at);
                CREATE INDEX IF NOT EXISTS idx_survey_responses_created ON survey_responses(created_at DESC);
                CREATE INDEX IF NOT EXISTS idx_survey_responses_score_type ON survey_responses(score_type);
            """
            )
            logger.info("✅ Database schema initialized")
    except Exception as e:
        logger.error(f"❌ Failed to connect to database: {e}")
        db_pool = None


def calculate_score_type(score: int) -> str:
    """Calculate NPS score type from numeric score."""
    if score >= 9:
        return "promoter"
    elif score >= 7:
        return "passive"
    else:
        return "detractor"


async def calculate_nps(
    conn: asyncpg.Connection, start_date: Optional[datetime] = None, end_date: Optional[datetime] = None
) -> NPSMetrics:
    """Calculate NPS metrics for a given period."""
    if not start_date:
        start_date = datetime.now() - timedelta(days=90)  # Last quarter
    if not end_date:
        end_date = datetime.now()

    # Get response counts by score type
    stats = await conn.fetchrow(
        """
        SELECT
            COUNT(*) FILTER (WHERE score_type = 'promoter') as promoters,
            COUNT(*) FILTER (WHERE score_type = 'passive') as passives,
            COUNT(*) FILTER (WHERE score_type = 'detractor') as detractors,
            COUNT(*) as total_responses
        FROM survey_responses
        WHERE created_at >= $1 AND created_at <= $2
    """,
        start_date,
        end_date,
    )

    # Get total sent count
    total_sent = (
        await conn.fetchval(
            """
        SELECT SUM(total_sent)
        FROM survey_campaigns
        WHERE started_at >= $1 AND started_at <= $2
    """,
            start_date,
            end_date,
        )
        or 0
    )

    promoters = stats["promoters"] or 0
    passives = stats["passives"] or 0
    detractors = stats["detractors"] or 0
    total_responses = stats["total_responses"] or 0

    # Calculate NPS: (% promoters - % detractors) * 100
    if total_responses > 0:
        promoter_pct = promoters / total_responses
        detractor_pct = detractors / total_responses
        nps_score = (promoter_pct - detractor_pct) * 100
    else:
        nps_score = 0.0

    # Calculate response rate
    response_rate = (total_responses / total_sent * 100) if total_sent > 0 else 0.0

    return NPSMetrics(
        nps_score=round(nps_score, 2),
        total_responses=total_responses,
        promoters=promoters,
        passives=passives,
        detractors=detractors,
        response_rate=round(response_rate, 2),
        period_start=start_date,
        period_end=end_date,
    )


# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan (startup/shutdown)."""
    # Startup
    await init_database()
    yield
    # Shutdown
    if db_pool:
        await db_pool.close()
    logger.info("Shutting down NPS survey service")


# Create FastAPI app
app = FastAPI(
    title="NPS Survey Service",
    description="NPS survey automation with quarterly scheduling and Mattermost integration",
    version="1.0.0",
    lifespan=lifespan,
)

# Add CORS middleware
# SECURITY: In production, set ALLOWED_ORIGINS environment variable
# Example: ALLOWED_ORIGINS=https://backstage.fawkes.idp,https://nps.fawkes.idp
ALLOWED_ORIGINS = os.getenv("ALLOWED_ORIGINS", "*").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Prometheus metrics
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


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
        service="nps-survey-service",
        version="1.0.0",
        database_connected=db_connected,
    )


# Survey UI endpoint
@app.get("/survey/{token}", response_class=HTMLResponse, tags=["Survey"])
async def get_survey_page(token: str = Path(..., description="Survey token")):
    """Render survey page for a given token."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Service unavailable")

    try:
        async with db_pool.acquire() as conn:
            link = await conn.fetchrow("SELECT * FROM survey_links WHERE token = $1", token)

            if not link:
                return HTMLResponse(
                    content="""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Invalid Survey Link</title>
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        <style>
                            body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; text-align: center; }
                            .error { color: #d32f2f; }
                        </style>
                    </head>
                    <body>
                        <h1 class="error">Invalid Survey Link</h1>
                        <p>This survey link is not valid. Please check the link and try again.</p>
                    </body>
                    </html>
                """
                )

            if link["responded"]:
                return HTMLResponse(
                    content="""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Survey Already Completed</title>
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        <style>
                            body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; text-align: center; }
                            .success { color: #388e3c; }
                        </style>
                    </head>
                    <body>
                        <h1 class="success">Thank You!</h1>
                        <p>You have already completed this survey.</p>
                    </body>
                    </html>
                """
                )

            if datetime.now() > link["expires_at"]:
                return HTMLResponse(
                    content="""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Survey Expired</title>
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        <style>
                            body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; text-align: center; }
                            .error { color: #d32f2f; }
                        </style>
                    </head>
                    <body>
                        <h1 class="error">Survey Expired</h1>
                        <p>This survey link has expired. Please contact support if you believe this is an error.</p>
                    </body>
                    </html>
                """
                )

            # Render survey form
            return HTMLResponse(
                content=f"""
                <!DOCTYPE html>
                <html>
                <head>
                    <title>Fawkes Platform NPS Survey</title>
                    <meta name="viewport" content="width=device-width, initial-scale=1">
                    <style>
                        body {{
                            font-family: Arial, sans-serif;
                            max-width: 600px;
                            margin: 50px auto;
                            padding: 20px;
                            background-color: #f5f5f5;
                        }}
                        .survey-container {{
                            background: white;
                            padding: 30px;
                            border-radius: 8px;
                            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                        }}
                        h1 {{
                            color: #1976d2;
                            margin-bottom: 10px;
                        }}
                        .subtitle {{
                            color: #666;
                            margin-bottom: 30px;
                        }}
                        .question {{
                            font-size: 18px;
                            font-weight: bold;
                            margin-bottom: 20px;
                        }}
                        .score-buttons {{
                            display: flex;
                            justify-content: space-between;
                            margin-bottom: 10px;
                            flex-wrap: wrap;
                        }}
                        .score-button {{
                            width: 40px;
                            height: 40px;
                            border: 2px solid #ddd;
                            border-radius: 50%;
                            background: white;
                            cursor: pointer;
                            font-size: 16px;
                            font-weight: bold;
                            transition: all 0.3s;
                            margin: 5px;
                        }}
                        .score-button:hover {{
                            border-color: #1976d2;
                            transform: scale(1.1);
                        }}
                        .score-button.selected {{
                            background: #1976d2;
                            color: white;
                            border-color: #1976d2;
                        }}
                        .score-labels {{
                            display: flex;
                            justify-content: space-between;
                            font-size: 12px;
                            color: #666;
                            margin-bottom: 30px;
                        }}
                        textarea {{
                            width: 100%;
                            min-height: 100px;
                            padding: 10px;
                            border: 1px solid #ddd;
                            border-radius: 4px;
                            font-family: Arial, sans-serif;
                            font-size: 14px;
                            resize: vertical;
                            box-sizing: border-box;
                        }}
                        .submit-button {{
                            background: #1976d2;
                            color: white;
                            border: none;
                            padding: 12px 30px;
                            font-size: 16px;
                            border-radius: 4px;
                            cursor: pointer;
                            width: 100%;
                            margin-top: 20px;
                        }}
                        .submit-button:hover {{
                            background: #1565c0;
                        }}
                        .submit-button:disabled {{
                            background: #ccc;
                            cursor: not-allowed;
                        }}
                        .error {{
                            color: #d32f2f;
                            margin-top: 10px;
                            display: none;
                        }}
                        @media (max-width: 600px) {{
                            body {{
                                margin: 20px auto;
                                padding: 10px;
                            }}
                            .survey-container {{
                                padding: 20px;
                            }}
                            .score-button {{
                                width: 35px;
                                height: 35px;
                                font-size: 14px;
                            }}
                        }}
                    </style>
                </head>
                <body>
                    <div class="survey-container">
                        <h1>Fawkes Platform Survey</h1>
                        <p class="subtitle">Help us improve the platform!</p>

                        <form id="surveyForm">
                            <div class="question">
                                How likely are you to recommend Fawkes Platform to a colleague?
                            </div>

                            <div class="score-buttons" id="scoreButtons">
                                {''.join([f'<button type="button" class="score-button" data-score="{i}">{i}</button>' for i in range(11)])}
                            </div>

                            <div class="score-labels">
                                <span>Not at all likely</span>
                                <span>Extremely likely</span>
                            </div>

                            <div>
                                <label for="comment" style="font-weight: bold; display: block; margin-bottom: 10px;">
                                    What's the main reason for your score? (Optional)
                                </label>
                                <textarea id="comment" name="comment" placeholder="Your feedback helps us improve..."></textarea>
                            </div>

                            <button type="submit" class="submit-button" id="submitButton" disabled>
                                Submit Feedback
                            </button>

                            <div class="error" id="errorMessage"></div>
                        </form>
                    </div>

                    <script>
                        let selectedScore = null;
                        const scoreButtons = document.querySelectorAll('.score-button');
                        const submitButton = document.getElementById('submitButton');
                        const errorMessage = document.getElementById('errorMessage');
                        const surveyForm = document.getElementById('surveyForm');

                        scoreButtons.forEach(button => {{
                            button.addEventListener('click', () => {{
                                selectedScore = parseInt(button.dataset.score);
                                scoreButtons.forEach(btn => btn.classList.remove('selected'));
                                button.classList.add('selected');
                                submitButton.disabled = false;
                            }});
                        }});

                        surveyForm.addEventListener('submit', async (e) => {{
                            e.preventDefault();

                            if (selectedScore === null) {{
                                errorMessage.textContent = 'Please select a score';
                                errorMessage.style.display = 'block';
                                return;
                            }}

                            submitButton.disabled = true;
                            submitButton.textContent = 'Submitting...';
                            errorMessage.style.display = 'none';

                            const comment = document.getElementById('comment').value;

                            try {{
                                const response = await fetch('/api/v1/survey/{token}/submit', {{
                                    method: 'POST',
                                    headers: {{
                                        'Content-Type': 'application/json',
                                    }},
                                    body: JSON.stringify({{
                                        score: selectedScore,
                                        comment: comment || null
                                    }})
                                }});

                                if (response.ok) {{
                                    window.location.href = '/survey/{token}/thanks';
                                }} else {{
                                    const error = await response.json();
                                    errorMessage.textContent = error.detail || 'Failed to submit survey';
                                    errorMessage.style.display = 'block';
                                    submitButton.disabled = false;
                                    submitButton.textContent = 'Submit Feedback';
                                }}
                            }} catch (error) {{
                                errorMessage.textContent = 'Network error. Please try again.';
                                errorMessage.style.display = 'block';
                                submitButton.disabled = false;
                                submitButton.textContent = 'Submit Feedback';
                            }}
                        }});
                    </script>
                </body>
                </html>
            """
            )
    except Exception as e:
        logger.error(f"Error rendering survey page: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")


# Thank you page
@app.get("/survey/{token}/thanks", response_class=HTMLResponse, tags=["Survey"])
async def thank_you_page(token: str = Path(..., description="Survey token")):
    """Thank you page after survey submission."""
    return HTMLResponse(
        content="""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Thank You!</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {
                    font-family: Arial, sans-serif;
                    max-width: 600px;
                    margin: 50px auto;
                    padding: 20px;
                    text-align: center;
                    background-color: #f5f5f5;
                }
                .thank-you-container {
                    background: white;
                    padding: 50px 30px;
                    border-radius: 8px;
                    box-shadow: 0 2px 4px rgba(0,0,0,0.1);
                }
                .success-icon {
                    font-size: 60px;
                    color: #4caf50;
                    margin-bottom: 20px;
                }
                h1 {
                    color: #1976d2;
                    margin-bottom: 20px;
                }
                p {
                    color: #666;
                    line-height: 1.6;
                }
            </style>
        </head>
        <body>
            <div class="thank-you-container">
                <div class="success-icon">✓</div>
                <h1>Thank You!</h1>
                <p>Your feedback has been submitted successfully.</p>
                <p>We appreciate you taking the time to help us improve Fawkes Platform.</p>
            </div>
        </body>
        </html>
    """
    )


# Submit survey response
@app.post("/api/v1/survey/{token}/submit", response_model=SurveyResponseOut, tags=["Survey"])
async def submit_survey_response(token: str = Path(..., description="Survey token"), response: SurveyResponse = None):
    """Submit a survey response."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Service unavailable")

    with survey_request_duration.labels(endpoint="submit_response").time():
        try:
            async with db_pool.acquire() as conn:
                # Validate token
                link = await conn.fetchrow("SELECT * FROM survey_links WHERE token = $1", token)

                if not link:
                    raise HTTPException(status_code=404, detail="Invalid survey token")

                if link["responded"]:
                    raise HTTPException(status_code=400, detail="Survey already completed")

                if datetime.now() > link["expires_at"]:
                    raise HTTPException(status_code=400, detail="Survey link expired")

                # Calculate score type
                score_type = calculate_score_type(response.score)

                # Insert response
                async with conn.transaction():
                    result = await conn.fetchrow(
                        """
                        INSERT INTO survey_responses (user_id, token, score, score_type, comment)
                        VALUES ($1, $2, $3, $4, $5)
                        RETURNING id, user_id, score, score_type, comment, created_at
                    """,
                        link["user_id"],
                        token,
                        response.score,
                        score_type,
                        response.comment,
                    )

                    # Mark link as responded
                    await conn.execute(
                        "UPDATE survey_links SET responded = TRUE, updated_at = CURRENT_TIMESTAMP WHERE token = $1",
                        token,
                    )

                # Update metrics
                nps_responses.labels(score_type=score_type).inc()

                logger.info(
                    f"Survey response submitted: user={link['user_id']}, score={response.score}, type={score_type}"
                )

                return SurveyResponseOut(
                    id=result["id"],
                    user_id=result["user_id"],
                    score=result["score"],
                    comment=result["comment"],
                    score_type=result["score_type"],
                    created_at=result["created_at"],
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error submitting survey response: {e}")
            raise HTTPException(status_code=500, detail="Failed to submit survey response")


# Get NPS metrics
@app.get("/api/v1/nps/metrics", response_model=NPSMetrics, tags=["NPS"])
async def get_nps_metrics(
    start_date: Optional[datetime] = Query(None, description="Period start date"),
    end_date: Optional[datetime] = Query(None, description="Period end date"),
):
    """Get NPS metrics for a given period."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Service unavailable")

    with survey_request_duration.labels(endpoint="get_metrics").time():
        try:
            async with db_pool.acquire() as conn:
                metrics = await calculate_nps(conn, start_date, end_date)

                # Update Prometheus gauge
                nps_score_gauge.labels(period="current").set(metrics.nps_score)

                return metrics
        except Exception as e:
            logger.error(f"Error calculating NPS metrics: {e}")
            raise HTTPException(status_code=500, detail="Failed to calculate NPS metrics")


# Generate survey link (internal use)
@app.post("/api/v1/survey/generate", tags=["Survey"])
async def generate_survey_link(user_id: str, email: str):
    """Generate a unique survey link for a user."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Service unavailable")

    try:
        token = secrets.token_urlsafe(32)
        expires_at = datetime.now() + timedelta(days=SURVEY_EXPIRY_DAYS)

        async with db_pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO survey_links (token, user_id, email, expires_at)
                VALUES ($1, $2, $3, $4)
            """,
                token,
                user_id,
                email,
                expires_at,
            )

        survey_url = f"/survey/{token}"
        logger.info(f"Generated survey link for user {user_id}")

        return {"token": token, "survey_url": survey_url, "expires_at": expires_at}
    except Exception as e:
        logger.error(f"Error generating survey link: {e}")
        raise HTTPException(status_code=500, detail="Failed to generate survey link")


# Root endpoint
@app.get("/", tags=["Info"])
async def root():
    """Root endpoint with service information."""
    return {
        "service": "nps-survey-service",
        "version": "1.0.0",
        "description": "NPS survey automation with quarterly scheduling",
        "endpoints": {
            "health": "/health",
            "survey_page": "/survey/{token}",
            "submit_response": "POST /api/v1/survey/{token}/submit",
            "nps_metrics": "GET /api/v1/nps/metrics",
            "generate_link": "POST /api/v1/survey/generate",
            "metrics": "/metrics",
        },
    }
