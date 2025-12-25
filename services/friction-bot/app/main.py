"""Main FastAPI application for Friction Bot."""

import logging
import os
from typing import Dict, Any, Optional, List
from datetime import datetime

from fastapi import FastAPI, HTTPException, Request, Form
from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field
import requests
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST
from fastapi.responses import Response

from app import __version__

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s"
)
logger = logging.getLogger(__name__)

# Configuration
INSIGHTS_API_URL = os.getenv("INSIGHTS_API_URL", "http://insights-service.fawkes.svc.cluster.local:8000")
BOT_TOKEN = os.getenv("BOT_TOKEN", "")
MATTERMOST_URL = os.getenv("MATTERMOST_URL", "http://mattermost.fawkes.svc.cluster.local:8065")

# Prometheus metrics
friction_logs_total = Counter(
    "friction_bot_logs_total",
    "Total number of friction logs submitted via bot",
    ["platform", "status"]
)
slash_commands_total = Counter(
    "friction_bot_slash_commands_total",
    "Total number of slash commands received",
    ["command", "platform"]
)
request_duration = Histogram(
    "friction_bot_request_duration_seconds",
    "Request processing time",
    ["endpoint"]
)

# FastAPI app
app = FastAPI(
    title="Fawkes Friction Bot",
    description="Slack/Mattermost bot for logging developer friction points",
    version=__version__
)


class FrictionData(BaseModel):
    """Model for friction data."""
    title: str = Field(..., description="Brief title of the friction point")
    description: str = Field(..., description="Detailed description")
    category: str = Field(default="Developer Experience", description="Friction category")
    priority: str = Field(default="medium", description="Priority level")
    tags: List[str] = Field(default_factory=list, description="Tags for categorization")
    author: Optional[str] = Field(None, description="User who reported the friction")


class MattermostSlashCommand(BaseModel):
    """Model for Mattermost slash command."""
    token: str
    team_domain: str
    team_id: str
    channel_id: str
    channel_name: str
    user_id: str
    user_name: str
    command: str
    text: str
    response_url: str


def send_to_insights_api(friction_data: Dict[str, Any]) -> Dict[str, Any]:
    """Send friction data to Insights API.

    Args:
        friction_data: Friction data to send

    Returns:
        Response from Insights API

    Raises:
        requests.HTTPError: If API request fails
    """
    try:
        response = requests.post(
            f"{INSIGHTS_API_URL}/insights",
            json=friction_data,
            timeout=10
        )
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logger.error(f"Failed to send to Insights API: {e}")
        raise


def send_mattermost_response(response_url: str, message: str, ephemeral: bool = False):
    """Send response back to Mattermost.

    Args:
        response_url: URL to send response to
        message: Message text
        ephemeral: Whether message should be visible only to user
    """
    try:
        payload = {
            "text": message,
            "response_type": "ephemeral" if ephemeral else "in_channel"
        }
        requests.post(response_url, json=payload, timeout=5)
    except requests.RequestException as e:
        logger.error(f"Failed to send Mattermost response: {e}")


def parse_friction_command(text: str) -> Dict[str, str]:
    """Parse friction command text.

    Format: /friction title | description | [category] | [priority]

    Args:
        text: Command text to parse

    Returns:
        Parsed friction data
    """
    parts = [p.strip() for p in text.split("|")]

    result = {
        "title": parts[0] if len(parts) > 0 else "",
        "description": parts[1] if len(parts) > 1 else "",
        "category": parts[2] if len(parts) > 2 else "Developer Experience",
        "priority": parts[3] if len(parts) > 3 else "medium",
    }

    return result


@app.get("/health")
def health_check():
    """Health check endpoint."""
    return {
        "status": "healthy",
        "service": "friction-bot",
        "version": __version__,
        "timestamp": datetime.utcnow().isoformat()
    }


@app.get("/metrics")
def metrics():
    """Prometheus metrics endpoint."""
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


@app.post("/slack/slash/friction")
async def slack_friction_command(
    token: str = Form(...),
    team_id: str = Form(...),
    team_domain: str = Form(...),
    channel_id: str = Form(...),
    channel_name: str = Form(...),
    user_id: str = Form(...),
    user_name: str = Form(...),
    command: str = Form(...),
    text: str = Form(...),
    response_url: str = Form(...)
):
    """Handle Slack /friction slash command.

    Usage:
        /friction title | description | [category] | [priority]

    Example:
        /friction Slow CI builds | Maven builds take 20+ min | CI/CD | high
    """
    slash_commands_total.labels(command="friction", platform="slack").inc()

    logger.info(f"Received Slack /friction command from {user_name}: {text}")

    # Validate token (if configured)
    if BOT_TOKEN and token != BOT_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid token")

    # Parse command
    if not text or not text.strip():
        return {
            "response_type": "ephemeral",
            "text": (
                "❓ *How to use /friction*\n\n"
                "Format: `/friction title | description | [category] | [priority]`\n\n"
                "*Example:*\n"
                "`/friction Slow CI builds | Maven builds take 20+ min | CI/CD | high`\n\n"
                "*Priority options:* `low`, `medium`, `high`, `critical`\n"
                "*Common categories:* `CI/CD`, `Documentation`, `Tooling`, `Infrastructure`"
            )
        }

    parsed = parse_friction_command(text)

    if not parsed["title"]:
        return {
            "response_type": "ephemeral",
            "text": "⚠️ Please provide at least a title for the friction point."
        }

    # Create insight
    insight_data = {
        "title": parsed["title"],
        "description": parsed.get("description", parsed["title"]),
        "content": f"# {parsed['title']}\n\n{parsed.get('description', '')}\n\n**Logged via Slack bot by {user_name}**",
        "category_name": parsed["category"],
        "tags": ["friction", "slack"],
        "priority": parsed["priority"],
        "source": "Slack Bot",
        "author": user_name,
        "metadata": {
            "platform": "slack",
            "team_id": team_id,
            "channel_id": channel_id,
            "user_id": user_id,
        }
    }

    try:
        result = send_to_insights_api(insight_data)
        friction_logs_total.labels(platform="slack", status="success").inc()

        return {
            "response_type": "in_channel",
            "text": (
                f"✅ *Friction point logged!*\n\n"
                f"**Title:** {parsed['title']}\n"
                f"**Category:** {parsed['category']}\n"
                f"**Priority:** {parsed['priority']}\n"
                f"**ID:** {result.get('id', 'N/A')}\n\n"
                f"_Thanks for helping us improve the platform!_ 🎯"
            )
        }
    except Exception as e:
        friction_logs_total.labels(platform="slack", status="error").inc()
        logger.error(f"Error creating insight: {e}")
        return {
            "response_type": "ephemeral",
            "text": f"❌ Failed to log friction: {str(e)}"
        }


@app.post("/mattermost/slash/friction")
async def mattermost_friction_command(request: Request):
    """Handle Mattermost /friction slash command.

    Usage:
        /friction title | description | [category] | [priority]

    Example:
        /friction Slow CI builds | Maven builds take 20+ min | CI/CD | high
    """
    form_data = await request.form()

    slash_commands_total.labels(command="friction", platform="mattermost").inc()

    # Extract form data
    token = form_data.get("token", "")
    user_name = form_data.get("user_name", "unknown")
    text = form_data.get("text", "")
    team_id = form_data.get("team_id", "")
    channel_id = form_data.get("channel_id", "")
    user_id = form_data.get("user_id", "")

    logger.info(f"Received Mattermost /friction command from {user_name}: {text}")

    # Validate token (if configured)
    if BOT_TOKEN and token != BOT_TOKEN:
        raise HTTPException(status_code=403, detail="Invalid token")

    # Parse command
    if not text or not text.strip():
        return {
            "response_type": "ephemeral",
            "text": (
                "❓ **How to use /friction**\n\n"
                "Format: `/friction title | description | [category] | [priority]`\n\n"
                "**Example:**\n"
                "`/friction Slow CI builds | Maven builds take 20+ min | CI/CD | high`\n\n"
                "**Priority options:** `low`, `medium`, `high`, `critical`\n"
                "**Common categories:** `CI/CD`, `Documentation`, `Tooling`, `Infrastructure`"
            )
        }

    parsed = parse_friction_command(text)

    if not parsed["title"]:
        return {
            "response_type": "ephemeral",
            "text": "⚠️ Please provide at least a title for the friction point."
        }

    # Create insight
    insight_data = {
        "title": parsed["title"],
        "description": parsed.get("description", parsed["title"]),
        "content": f"# {parsed['title']}\n\n{parsed.get('description', '')}\n\n**Logged via Mattermost bot by {user_name}**",
        "category_name": parsed["category"],
        "tags": ["friction", "mattermost"],
        "priority": parsed["priority"],
        "source": "Mattermost Bot",
        "author": user_name,
        "metadata": {
            "platform": "mattermost",
            "team_id": team_id,
            "channel_id": channel_id,
            "user_id": user_id,
        }
    }

    try:
        result = send_to_insights_api(insight_data)
        friction_logs_total.labels(platform="mattermost", status="success").inc()

        return {
            "response_type": "in_channel",
            "text": (
                f"✅ **Friction point logged!**\n\n"
                f"**Title:** {parsed['title']}\n"
                f"**Category:** {parsed['category']}\n"
                f"**Priority:** {parsed['priority']}\n"
                f"**ID:** {result.get('id', 'N/A')}\n\n"
                f"_Thanks for helping us improve the platform!_ 🎯"
            )
        }
    except Exception as e:
        friction_logs_total.labels(platform="mattermost", status="error").inc()
        logger.error(f"Error creating insight: {e}")
        return {
            "response_type": "ephemeral",
            "text": f"❌ Failed to log friction: {str(e)}"
        }


@app.post("/api/v1/friction")
async def api_log_friction(friction: FrictionData):
    """Direct API endpoint for logging friction (for testing/webhooks).

    This endpoint allows friction logging via direct API calls.
    """
    logger.info(f"Received API friction log: {friction.title}")

    insight_data = {
        "title": friction.title,
        "description": friction.description,
        "content": f"# {friction.title}\n\n{friction.description}\n\n**Logged via API**",
        "category_name": friction.category,
        "tags": friction.tags + ["friction"],
        "priority": friction.priority,
        "source": "API",
        "author": friction.author,
        "metadata": {
            "platform": "api",
        }
    }

    try:
        result = send_to_insights_api(insight_data)
        friction_logs_total.labels(platform="api", status="success").inc()
        return result
    except Exception as e:
        friction_logs_total.labels(platform="api", status="error").inc()
        logger.error(f"Error creating insight: {e}")
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
