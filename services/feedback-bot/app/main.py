"""
Mattermost Feedback Bot (@fawkes) - Main Application

This bot provides a conversational interface for collecting feedback
with natural language processing, sentiment analysis, and auto-categorization.
"""
import os
import logging
import re
from typing import Optional, Dict, Any
from datetime import datetime

from fastapi import FastAPI, Form, HTTPException, Request
from fastapi.responses import JSONResponse
import httpx
from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from starlette.responses import Response

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
FEEDBACK_API_URL = os.getenv(
    "FEEDBACK_API_URL",
    "http://feedback-service.fawkes.svc.cluster.local:8000"
)
FEEDBACK_API_TOKEN = os.getenv("FEEDBACK_API_TOKEN", "")
BOT_TOKEN = os.getenv("BOT_TOKEN", "")
MATTERMOST_URL = os.getenv("MATTERMOST_URL", "http://mattermost.fawkes.svc.cluster.local:8065")

# Initialize FastAPI
app = FastAPI(
    title="Fawkes Mattermost Feedback Bot",
    description="Conversational feedback bot with NLP and sentiment analysis",
    version="1.0.0"
)

# Initialize sentiment analyzer
sentiment_analyzer = SentimentIntensityAnalyzer()

# Prometheus metrics
feedback_logs_total = Counter(
    'feedback_bot_logs_total',
    'Total feedback submissions via bot',
    ['platform', 'status', 'sentiment', 'category']
)
slash_commands_total = Counter(
    'feedback_bot_slash_commands_total',
    'Total slash commands received',
    ['command', 'platform']
)
request_duration = Histogram(
    'feedback_bot_request_duration_seconds',
    'Request processing duration',
    ['endpoint']
)


# Category keywords for auto-categorization
CATEGORY_KEYWORDS = {
    "UI": ["interface", "ui", "design", "layout", "visual", "button", "menu", "navigation", "display"],
    "Performance": ["slow", "fast", "speed", "performance", "lag", "loading", "responsive", "timeout"],
    "Documentation": ["docs", "documentation", "guide", "tutorial", "help", "readme", "instructions"],
    "CI/CD": ["build", "deploy", "pipeline", "jenkins", "argocd", "ci", "cd", "deployment"],
    "Security": ["security", "vulnerability", "auth", "authentication", "permission", "access", "secure"],
    "API": ["api", "endpoint", "rest", "graphql", "request", "response", "integration"],
    "Feature Request": ["want", "wish", "need", "could", "should", "feature", "add", "new"],
    "Bug": ["bug", "error", "issue", "problem", "broken", "crash", "fail", "wrong"],
    "Observability": ["metrics", "logs", "traces", "monitoring", "grafana", "prometheus", "alert"],
    "Developer Experience": ["dx", "experience", "workflow", "productivity", "friction", "ease"]
}


def analyze_sentiment(text: str) -> Dict[str, Any]:
    """
    Analyze sentiment of text using VADER.
    
    Returns dict with sentiment label and scores.
    """
    scores = sentiment_analyzer.polarity_scores(text)
    compound = scores['compound']
    
    # Classify sentiment
    if compound >= 0.05:
        sentiment = "positive"
    elif compound <= -0.05:
        sentiment = "negative"
    else:
        sentiment = "neutral"
    
    return {
        "sentiment": sentiment,
        "compound": compound,
        "pos": scores['pos'],
        "neu": scores['neu'],
        "neg": scores['neg']
    }


def auto_categorize(text: str) -> str:
    """
    Automatically categorize feedback based on keywords.
    
    Returns the most relevant category or "General" if no match.
    """
    text_lower = text.lower()
    
    # Count matches for each category
    category_scores = {}
    for category, keywords in CATEGORY_KEYWORDS.items():
        score = sum(1 for keyword in keywords if keyword in text_lower)
        if score > 0:
            category_scores[category] = score
    
    # Return category with highest score
    if category_scores:
        return max(category_scores, key=category_scores.get)
    
    return "General"


def extract_rating(text: str) -> Optional[int]:
    """
    Extract rating from natural language text.
    
    Examples:
    - "5 stars" -> 5
    - "rate it 4" -> 4
    - "3/5" -> 3
    """
    # Pattern: "X stars", "X/5", "rate it X", "X out of 5"
    patterns = [
        r'(\d)[/]5',
        r'(\d)\s+(?:stars?|out of 5)',
        r'(?:rate|rating|score).*?(\d)',
    ]
    
    for pattern in patterns:
        match = re.search(pattern, text.lower())
        if match:
            rating = int(match.group(1))
            if 1 <= rating <= 5:
                return rating
    
    # Sentiment-based rating if no explicit rating
    sentiment_result = analyze_sentiment(text)
    compound = sentiment_result['compound']
    
    if compound >= 0.6:
        return 5
    elif compound >= 0.2:
        return 4
    elif compound >= -0.2:
        return 3
    elif compound >= -0.6:
        return 2
    else:
        return 1


def parse_feedback(text: str, user_name: str, user_email: str) -> Dict[str, Any]:
    """
    Parse natural language feedback into structured format.
    
    Args:
        text: Feedback text from user
        user_name: Mattermost username
        user_email: User email
        
    Returns:
        Dict with parsed feedback data
    """
    # Analyze sentiment
    sentiment_result = analyze_sentiment(text)
    
    # Auto-categorize
    category = auto_categorize(text)
    
    # Extract or infer rating
    rating = extract_rating(text)
    
    return {
        "rating": rating,
        "category": category,
        "comment": text,
        "email": user_email,
        "page_url": None,  # Not available from Mattermost
        "sentiment": sentiment_result["sentiment"],
        "sentiment_compound": sentiment_result["compound"],
        "metadata": {
            "source": "mattermost",
            "user_name": user_name,
            "processed_at": datetime.utcnow().isoformat()
        }
    }


async def submit_feedback_to_api(feedback_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Submit parsed feedback to the feedback service API.
    
    Returns the API response.
    """
    async with httpx.AsyncClient() as client:
        try:
            response = await client.post(
                f"{FEEDBACK_API_URL}/api/v1/feedback",
                json=feedback_data,
                timeout=10.0
            )
            response.raise_for_status()
            return response.json()
        except httpx.HTTPError as e:
            logger.error(f"Failed to submit feedback to API: {e}")
            raise HTTPException(status_code=500, detail="Failed to submit feedback")


@app.get("/health")
async def health():
    """Health check endpoint."""
    return {"status": "healthy", "service": "feedback-bot"}


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/mattermost/slash/feedback")
async def mattermost_slash_feedback(
    token: str = Form(None),
    user_name: str = Form(...),
    user_id: str = Form(...),
    channel_id: str = Form(...),
    text: str = Form(...)
):
    """
    Handle /feedback slash command from Mattermost.
    
    Usage:
        /feedback <your feedback here>
        
    Examples:
        /feedback The new UI is amazing! Love the dark mode.
        /feedback Builds are too slow, taking 20+ minutes
        /feedback Rate it 5 stars, great documentation!
    """
    slash_commands_total.labels(command='feedback', platform='mattermost').inc()
    
    # Validate token if configured
    if BOT_TOKEN and token != BOT_TOKEN:
        logger.warning(f"Invalid token from user {user_name}")
        return {
            "response_type": "ephemeral",
            "text": "⚠️ Invalid token"
        }
    
    # Show help if no text provided
    if not text or text.strip() == "":
        return {
            "response_type": "ephemeral",
            "text": """### 💬 Fawkes Feedback Bot
            
**Usage:**
```
/feedback <your feedback here>
```

**Examples:**
```
/feedback The new UI is amazing! Love the dark mode.
/feedback Builds are too slow, taking 20+ minutes
/feedback Rate it 5 stars, great documentation!
```

**What I can do:**
✓ Understand natural language feedback
✓ Analyze sentiment automatically
✓ Auto-categorize your feedback
✓ Extract ratings from your comments

Just tell me what you think, and I'll handle the rest! 🎯
"""
        }
    
    try:
        # Get user email from Mattermost
        user_email = f"{user_name}@fawkes.local"  # Default if not available
        
        # Parse feedback
        feedback_data = parse_feedback(text, user_name, user_email)
        
        # Submit to feedback API
        result = await submit_feedback_to_api(feedback_data)
        
        # Track metrics
        feedback_logs_total.labels(
            platform='mattermost',
            status='success',
            sentiment=feedback_data['sentiment'],
            category=feedback_data['category']
        ).inc()
        
        # Format sentiment emoji
        sentiment_emoji = {
            "positive": "😊",
            "neutral": "😐",
            "negative": "😞"
        }
        emoji = sentiment_emoji.get(feedback_data['sentiment'], "🤔")
        
        # Return success response with analysis
        return {
            "response_type": "ephemeral",
            "text": f"""✅ **Feedback submitted successfully!**

**Your feedback:**
> {text}

**My analysis:**
• **Sentiment:** {feedback_data['sentiment'].title()} {emoji}
• **Category:** {feedback_data['category']}
• **Rating:** {'⭐' * feedback_data['rating']} ({feedback_data['rating']}/5)
• **ID:** #{result.get('id', 'unknown')}

Thank you for helping us improve Fawkes! 🎯

_Your feedback will be reviewed by the team._
"""
        }
        
    except Exception as e:
        logger.error(f"Error processing feedback: {e}")
        feedback_logs_total.labels(
            platform='mattermost',
            status='error',
            sentiment='unknown',
            category='unknown'
        ).inc()
        
        return {
            "response_type": "ephemeral",
            "text": f"❌ **Error submitting feedback**\n\n{str(e)}\n\nPlease try again later."
        }


@app.post("/api/v1/feedback")
async def api_submit_feedback(request: Request):
    """
    API endpoint for submitting feedback programmatically.
    
    Accepts JSON with feedback text and optional metadata.
    """
    try:
        data = await request.json()
        text = data.get("text", "")
        user_name = data.get("user_name", "unknown")
        user_email = data.get("user_email", f"{user_name}@fawkes.local")
        
        if not text:
            raise HTTPException(status_code=400, detail="Text is required")
        
        # Parse and submit feedback
        feedback_data = parse_feedback(text, user_name, user_email)
        result = await submit_feedback_to_api(feedback_data)
        
        # Track metrics
        feedback_logs_total.labels(
            platform='api',
            status='success',
            sentiment=feedback_data['sentiment'],
            category=feedback_data['category']
        ).inc()
        
        return {
            "status": "success",
            "feedback_id": result.get('id'),
            "analysis": {
                "sentiment": feedback_data['sentiment'],
                "category": feedback_data['category'],
                "rating": feedback_data['rating']
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error in API endpoint: {e}")
        feedback_logs_total.labels(
            platform='api',
            status='error',
            sentiment='unknown',
            category='unknown'
        ).inc()
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
