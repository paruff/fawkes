"""
FastAPI application for DevEx Survey Automation Service
"""
import logging
import secrets
from datetime import datetime, timedelta
from typing import List, Optional
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Path, Query
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app, Counter, Gauge, Histogram
from sqlalchemy import select, func, and_
from sqlalchemy.orm import selectinload

from .config import settings
from .database import init_database, close_database, get_db_session, check_database_health
from .models import SurveyCampaign, SurveyRecipient, PulseSurveyAggregate, SurveyOptOut
from .schemas import (
    PulseSurveyResponse,
    SurveyDistributionRequest,
    CampaignResponse,
    PulseAnalytics,
    WeeklyTrend,
    ResponseRateMetrics,
    HealthResponse,
    SurveySubmissionResponse
)
from integrations.mattermost import mattermost_client
from integrations.space_metrics import space_metrics_client

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics
surveys_distributed = Counter(
    'devex_survey_distributed_total',
    'Total surveys distributed',
    ['type']
)
survey_responses = Counter(
    'devex_survey_responses_total',
    'Total survey responses',
    ['type']
)
response_rate_gauge = Gauge(
    'devex_survey_response_rate',
    'Survey response rate',
    ['type']
)
request_duration = Histogram(
    'devex_survey_request_duration_seconds',
    'Request processing duration',
    ['endpoint']
)

# Lifespan context manager
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifespan"""
    # Startup
    logger.info("Starting DevEx Survey Automation Service")
    await init_database()
    logger.info("Service ready")
    
    yield
    
    # Shutdown
    await close_database()
    logger.info("Service shut down")


# Create FastAPI app
app = FastAPI(
    title="DevEx Survey Automation Service",
    description="Automated DevEx surveys with multi-channel distribution and analysis",
    version=settings.version,
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount Prometheus metrics
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)


@app.get("/health", response_model=HealthResponse, tags=["Health"])
async def health_check():
    """Check service health"""
    db_healthy = await check_database_health()
    
    integrations = {
        "database": db_healthy,
        "space_metrics": await space_metrics_client.check_health(),
        "mattermost": mattermost_client is not None
    }
    
    status = "healthy" if all(integrations.values()) else "degraded"
    
    return HealthResponse(
        status=status,
        service=settings.service_name,
        version=settings.version,
        database_connected=db_healthy,
        integrations=integrations
    )


@app.get("/", tags=["Info"])
async def root():
    """Root endpoint with service information"""
    return {
        "service": settings.service_name,
        "version": settings.version,
        "description": "DevEx Survey Automation with weekly pulse and quarterly deep-dive surveys",
        "endpoints": {
            "health": "/health",
            "distribute_survey": "POST /api/v1/survey/distribute",
            "campaigns": "GET /api/v1/survey/campaigns",
            "survey_page": "GET /survey/{token}",
            "submit_response": "POST /api/v1/survey/{token}/submit",
            "pulse_analytics": "GET /api/v1/analytics/pulse/weekly",
            "response_rate": "GET /api/v1/analytics/response-rate",
            "metrics": "/metrics"
        }
    }


@app.post("/api/v1/survey/distribute", tags=["Survey Distribution"])
async def distribute_survey(request: SurveyDistributionRequest):
    """Distribute surveys to developers"""
    with request_duration.labels(endpoint="distribute_survey").time():
        try:
            # Determine period
            now = datetime.now()
            if request.type == "pulse":
                period = f"W{now.isocalendar()[1]}"  # ISO week number
            else:  # deep_dive
                period = f"Q{(now.month - 1) // 3 + 1}"
            
            # Create campaign
            async with get_db_session() as session:
                # Check if campaign already exists
                existing = await session.execute(
                    select(SurveyCampaign).where(
                        and_(
                            SurveyCampaign.type == request.type,
                            SurveyCampaign.period == period,
                            SurveyCampaign.year == now.year
                        )
                    )
                )
                if existing.scalar_one_or_none():
                    raise HTTPException(
                        status_code=400,
                        detail=f"Campaign for {request.type} {period} {now.year} already exists"
                    )
                
                # Create campaign
                campaign = SurveyCampaign(
                    type=request.type,
                    period=period,
                    year=now.year,
                    started_at=now
                )
                session.add(campaign)
                await session.flush()
                
                # Get recipients
                recipients_list = []
                if request.test_mode and request.test_users:
                    recipients_list = [{"email": email, "user_id": email.split("@")[0]} 
                                      for email in request.test_users]
                else:
                    # In production, integrate with Backstage or user directory
                    # For now, use test users
                    recipients_list = [
                        {"email": "dev1@fawkes.idp", "user_id": "dev1"},
                        {"email": "dev2@fawkes.idp", "user_id": "dev2"}
                    ]
                
                # Check opt-outs
                opt_out_users = await session.execute(
                    select(SurveyOptOut.user_id)
                )
                opted_out = {row[0] for row in opt_out_users.fetchall()}
                
                # Create recipients and send surveys
                sent_count = 0
                for recipient_info in recipients_list:
                    if recipient_info["user_id"] in opted_out:
                        logger.info(f"Skipping opted-out user: {recipient_info['user_id']}")
                        continue
                    
                    # Generate token
                    token = secrets.token_urlsafe(32)
                    survey_url = f"{settings.survey_base_url}/survey/{token}"
                    
                    # Create recipient record
                    recipient = SurveyRecipient(
                        campaign_id=campaign.id,
                        user_id=recipient_info["user_id"],
                        email=recipient_info["email"],
                        token=token,
                        sent_at=now
                    )
                    session.add(recipient)
                    
                    # Send via Mattermost
                    if mattermost_client and request.type == "pulse":
                        success = await mattermost_client.send_pulse_survey(
                            recipient_info["email"],
                            recipient_info["user_id"],
                            survey_url
                        )
                        if success:
                            sent_count += 1
                    else:
                        # Would send via email or other channels
                        logger.info(f"Would send {request.type} survey to {recipient_info['email']}")
                        sent_count += 1
                
                # Update campaign
                campaign.total_sent = sent_count
                await session.commit()
                
                # Update metrics
                surveys_distributed.labels(type=request.type).inc(sent_count)
                
                logger.info(f"✅ Distributed {sent_count} {request.type} surveys for {period} {now.year}")
                
                return {
                    "success": True,
                    "campaign_id": campaign.id,
                    "type": request.type,
                    "period": period,
                    "year": now.year,
                    "total_sent": sent_count
                }
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error distributing surveys: {e}")
            raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/survey/campaigns", response_model=List[CampaignResponse], tags=["Survey Management"])
async def list_campaigns(
    type: Optional[str] = Query(None, description="Filter by survey type"),
    limit: int = Query(10, ge=1, le=100)
):
    """List survey campaigns"""
    try:
        async with get_db_session() as session:
            query = select(SurveyCampaign).order_by(SurveyCampaign.started_at.desc()).limit(limit)
            if type:
                query = query.where(SurveyCampaign.type == type)
            
            result = await session.execute(query)
            campaigns = result.scalars().all()
            
            return [CampaignResponse.model_validate(c) for c in campaigns]
    
    except Exception as e:
        logger.error(f"Error listing campaigns: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/survey/campaign/{campaign_id}", response_model=CampaignResponse, tags=["Survey Management"])
async def get_campaign(campaign_id: int = Path(..., description="Campaign ID")):
    """Get campaign details"""
    try:
        async with get_db_session() as session:
            result = await session.execute(
                select(SurveyCampaign).where(SurveyCampaign.id == campaign_id)
            )
            campaign = result.scalar_one_or_none()
            
            if not campaign:
                raise HTTPException(status_code=404, detail="Campaign not found")
            
            return CampaignResponse.model_validate(campaign)
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting campaign: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/survey/{token}", response_class=HTMLResponse, tags=["Survey"])
async def get_survey_page(token: str = Path(..., description="Survey token")):
    """Render survey page"""
    try:
        async with get_db_session() as session:
            result = await session.execute(
                select(SurveyRecipient).where(SurveyRecipient.token == token)
            )
            recipient = result.scalar_one_or_none()
            
            if not recipient:
                return HTMLResponse(content="""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Invalid Survey</title>
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        <style>
                            body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; 
                                   padding: 20px; text-align: center; }
                            .error { color: #d32f2f; }
                        </style>
                    </head>
                    <body>
                        <h1 class="error">Invalid Survey Link</h1>
                        <p>This survey link is not valid.</p>
                    </body>
                    </html>
                """)
            
            if recipient.responded_at:
                return HTMLResponse(content="""
                    <!DOCTYPE html>
                    <html>
                    <head>
                        <title>Already Completed</title>
                        <meta name="viewport" content="width=device-width, initial-scale=1">
                        <style>
                            body { font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; 
                                   padding: 20px; text-align: center; }
                            .success { color: #388e3c; }
                        </style>
                    </head>
                    <body>
                        <h1 class="success">Thank You!</h1>
                        <p>You have already completed this survey.</p>
                    </body>
                    </html>
                """)
            
            # Get campaign type
            result = await session.execute(
                select(SurveyCampaign).where(SurveyCampaign.id == recipient.campaign_id)
            )
            campaign = result.scalar_one()
            
            if campaign.type == "pulse":
                return _render_pulse_survey(token)
            else:
                return _render_deep_dive_survey(token)
    
    except Exception as e:
        logger.error(f"Error rendering survey: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _render_pulse_survey(token: str) -> HTMLResponse:
    """Render pulse survey HTML"""
    return HTMLResponse(content=f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Weekly DevEx Pulse Survey</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {{
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Arial, sans-serif;
                    max-width: 600px;
                    margin: 50px auto;
                    padding: 20px;
                    background-color: #f5f5f5;
                }}
                .survey-container {{
                    background: white;
                    padding: 30px;
                    border-radius: 8px;
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
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
                    margin-bottom: 25px;
                }}
                .question-label {{
                    font-weight: 600;
                    margin-bottom: 10px;
                    display: block;
                }}
                .question-help {{
                    font-size: 14px;
                    color: #666;
                    margin-bottom: 10px;
                }}
                input[type="range"] {{
                    width: 100%;
                    height: 6px;
                }}
                .range-value {{
                    text-align: center;
                    font-size: 24px;
                    font-weight: bold;
                    color: #1976d2;
                    margin: 10px 0;
                }}
                .range-labels {{
                    display: flex;
                    justify-content: space-between;
                    font-size: 12px;
                    color: #666;
                }}
                .checkbox-group {{
                    margin: 10px 0;
                }}
                textarea {{
                    width: 100%;
                    min-height: 80px;
                    padding: 10px;
                    border: 1px solid #ddd;
                    border-radius: 4px;
                    font-family: inherit;
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
            </style>
        </head>
        <body>
            <div class="survey-container">
                <h1>📊 Weekly DevEx Pulse</h1>
                <p class="subtitle">Help us improve your developer experience (2 minutes)</p>
                
                <form id="surveyForm">
                    <div class="question">
                        <label class="question-label">How many days this week did you achieve flow state?</label>
                        <div class="question-help">Flow state = Deep focus without interruptions</div>
                        <input type="range" id="flowState" min="0" max="7" step="0.5" value="3.5">
                        <div class="range-value" id="flowStateValue">3.5 days</div>
                        <div class="range-labels">
                            <span>0 days</span>
                            <span>7 days</span>
                        </div>
                    </div>
                    
                    <div class="question">
                        <label class="question-label">What % of time did you spend on valuable work?</label>
                        <div class="question-help">Valuable = Writing code, solving problems (not meetings, admin)</div>
                        <input type="range" id="valuableWork" min="0" max="100" step="5" value="70">
                        <div class="range-value" id="valuableWorkValue">70%</div>
                        <div class="range-labels">
                            <span>0%</span>
                            <span>100%</span>
                        </div>
                    </div>
                    
                    <div class="question">
                        <label class="question-label">How was your cognitive load this week?</label>
                        <div class="question-help">1 = Very manageable, 5 = Overwhelming</div>
                        <input type="range" id="cognitiveLoad" min="1" max="5" step="0.5" value="3">
                        <div class="range-value" id="cognitiveLoadValue">3</div>
                        <div class="range-labels">
                            <span>1 - Manageable</span>
                            <span>5 - Overwhelming</span>
                        </div>
                    </div>
                    
                    <div class="question">
                        <label class="question-label">Did you experience significant friction this week?</label>
                        <div class="checkbox-group">
                            <label>
                                <input type="checkbox" id="friction" />
                                Yes, I experienced friction (slow builds, broken tools, unclear docs, etc.)
                            </label>
                        </div>
                    </div>
                    
                    <div class="question">
                        <label class="question-label">Any additional feedback? (Optional)</label>
                        <textarea id="comment" placeholder="What went well? What could be better?"></textarea>
                    </div>
                    
                    <button type="submit" class="submit-button" id="submitButton">
                        Submit Feedback
                    </button>
                    
                    <div class="error" id="errorMessage"></div>
                </form>
            </div>
            
            <script>
                // Update range value displays
                const flowState = document.getElementById('flowState');
                const flowStateValue = document.getElementById('flowStateValue');
                const valuableWork = document.getElementById('valuableWork');
                const valuableWorkValue = document.getElementById('valuableWorkValue');
                const cognitiveLoad = document.getElementById('cognitiveLoad');
                const cognitiveLoadValue = document.getElementById('cognitiveLoadValue');
                
                flowState.addEventListener('input', (e) => {{
                    flowStateValue.textContent = e.target.value + ' days';
                }});
                
                valuableWork.addEventListener('input', (e) => {{
                    valuableWorkValue.textContent = e.target.value + '%';
                }});
                
                cognitiveLoad.addEventListener('input', (e) => {{
                    cognitiveLoadValue.textContent = e.target.value;
                }});
                
                // Form submission
                document.getElementById('surveyForm').addEventListener('submit', async (e) => {{
                    e.preventDefault();
                    
                    const submitButton = document.getElementById('submitButton');
                    const errorMessage = document.getElementById('errorMessage');
                    
                    submitButton.disabled = true;
                    submitButton.textContent = 'Submitting...';
                    errorMessage.style.display = 'none';
                    
                    const data = {{
                        flow_state_days: parseFloat(flowState.value),
                        valuable_work_pct: parseFloat(valuableWork.value),
                        cognitive_load: parseFloat(cognitiveLoad.value),
                        friction_incidents: document.getElementById('friction').checked,
                        comment: document.getElementById('comment').value || null
                    }};
                    
                    try {{
                        const response = await fetch('/api/v1/survey/{token}/submit', {{
                            method: 'POST',
                            headers: {{
                                'Content-Type': 'application/json',
                            }},
                            body: JSON.stringify(data)
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
    """)


def _render_deep_dive_survey(token: str) -> HTMLResponse:
    """Render deep-dive survey HTML (placeholder)"""
    return HTMLResponse(content=f"""
        <!DOCTYPE html>
        <html>
        <head>
            <title>Quarterly DevEx Survey</title>
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <style>
                body {{ font-family: Arial, sans-serif; max-width: 600px; margin: 50px auto; padding: 20px; }}
            </style>
        </head>
        <body>
            <h1>Quarterly Developer Experience Survey</h1>
            <p>This comprehensive survey is integrated with the NPS service.</p>
            <p>Token: {token}</p>
        </body>
        </html>
    """)


@app.post("/api/v1/survey/{token}/submit", response_model=SurveySubmissionResponse, tags=["Survey"])
async def submit_survey(
    token: str = Path(..., description="Survey token"),
    response: PulseSurveyResponse = None
):
    """Submit survey response"""
    with request_duration.labels(endpoint="submit_survey").time():
        try:
            async with get_db_session() as session:
                # Get recipient
                result = await session.execute(
                    select(SurveyRecipient).where(SurveyRecipient.token == token)
                )
                recipient = result.scalar_one_or_none()
                
                if not recipient:
                    raise HTTPException(status_code=404, detail="Invalid survey token")
                
                if recipient.responded_at:
                    raise HTTPException(status_code=400, detail="Survey already completed")
                
                # Store response
                response_data = response.model_dump()
                recipient.response_data = response_data
                recipient.responded_at = datetime.now()
                
                # Update campaign stats
                result = await session.execute(
                    select(SurveyCampaign).where(SurveyCampaign.id == recipient.campaign_id)
                )
                campaign = result.scalar_one()
                campaign.total_responses += 1
                if campaign.total_sent > 0:
                    campaign.response_rate = (campaign.total_responses / campaign.total_sent) * 100
                
                await session.commit()
                
                # Submit to space-metrics
                await space_metrics_client.submit_pulse_survey(response_data)
                
                # Update metrics
                survey_responses.labels(type=campaign.type).inc()
                response_rate_gauge.labels(type=campaign.type).set(campaign.response_rate)
                
                logger.info(f"✅ Survey response submitted: {token}")
                
                return SurveySubmissionResponse(
                    success=True,
                    message="Survey submitted successfully",
                    recipient_id=recipient.id,
                    submitted_at=recipient.responded_at
                )
        
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error submitting survey: {e}")
            raise HTTPException(status_code=500, detail=str(e))


@app.get("/survey/{token}/thanks", response_class=HTMLResponse, tags=["Survey"])
async def thank_you_page(token: str = Path(..., description="Survey token")):
    """Thank you page after survey submission"""
    return HTMLResponse(content="""
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
                    box-shadow: 0 2px 8px rgba(0,0,0,0.1);
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
                <p>We appreciate you taking the time to help us improve the platform.</p>
                <p><strong>Your feedback makes a difference!</strong></p>
            </div>
        </body>
        </html>
    """)


@app.get("/api/v1/analytics/pulse/weekly", response_model=List[PulseAnalytics], tags=["Analytics"])
async def get_pulse_weekly_analytics(
    weeks: int = Query(12, ge=1, le=52, description="Number of weeks to retrieve")
):
    """Get weekly pulse survey analytics"""
    try:
        async with get_db_session() as session:
            result = await session.execute(
                select(PulseSurveyAggregate)
                .order_by(PulseSurveyAggregate.year.desc(), PulseSurveyAggregate.week.desc())
                .limit(weeks)
            )
            aggregates = result.scalars().all()
            
            return [PulseAnalytics.model_validate(a) for a in aggregates]
    
    except Exception as e:
        logger.error(f"Error getting pulse analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/api/v1/analytics/response-rate", response_model=List[ResponseRateMetrics], tags=["Analytics"])
async def get_response_rate_metrics():
    """Get response rate metrics for all survey types"""
    try:
        async with get_db_session() as session:
            # Get latest campaigns by type
            result = await session.execute(
                select(SurveyCampaign)
                .order_by(SurveyCampaign.type, SurveyCampaign.started_at.desc())
            )
            campaigns = result.scalars().all()
            
            metrics = []
            seen_types = set()
            
            for campaign in campaigns:
                if campaign.type in seen_types:
                    continue
                seen_types.add(campaign.type)
                
                target_rate = 60.0 if campaign.type == "pulse" else 40.0
                status = "above_target" if campaign.response_rate >= target_rate else "below_target"
                
                metrics.append(ResponseRateMetrics(
                    survey_type=campaign.type,
                    period=f"{campaign.period} {campaign.year}",
                    total_sent=campaign.total_sent,
                    total_responses=campaign.total_responses,
                    response_rate=campaign.response_rate,
                    target_rate=target_rate,
                    status=status
                ))
            
            return metrics
    
    except Exception as e:
        logger.error(f"Error getting response rate metrics: {e}")
        raise HTTPException(status_code=500, detail=str(e))
