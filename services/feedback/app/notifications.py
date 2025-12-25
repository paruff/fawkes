"""
Notification module for Feedback service.

This module provides notification capabilities for feedback-to-issue automation.
Supports multiple notification channels including Mattermost and webhooks.
"""
import os
import logging
from typing import Optional, Dict, List
import httpx

logger = logging.getLogger(__name__)

# Configuration from environment
MATTERMOST_WEBHOOK_URL = os.getenv("MATTERMOST_WEBHOOK_URL")
NOTIFICATION_ENABLED = os.getenv("NOTIFICATION_ENABLED", "false").lower() == "true"


def is_notification_enabled() -> bool:
    """Check if notifications are enabled."""
    return NOTIFICATION_ENABLED and MATTERMOST_WEBHOOK_URL is not None


async def send_mattermost_notification(
    message: str,
    username: str = "Feedback Bot",
    icon_emoji: str = ":speech_balloon:",
    channel: Optional[str] = None
) -> bool:
    """
    Send notification to Mattermost via webhook.

    Args:
        message: Message text (supports Markdown)
        username: Bot username
        icon_emoji: Bot emoji icon
        channel: Optional channel override

    Returns:
        True if successful, False otherwise
    """
    if not is_notification_enabled():
        logger.debug("Notifications not enabled, skipping")
        return False

    try:
        payload = {
            "text": message,
            "username": username,
            "icon_emoji": icon_emoji
        }

        if channel:
            payload["channel"] = channel

        async with httpx.AsyncClient() as client:
            response = await client.post(
                MATTERMOST_WEBHOOK_URL,
                json=payload,
                timeout=10.0
            )

            if response.status_code == 200:
                logger.info("✅ Mattermost notification sent successfully")
                return True
            else:
                logger.warning(
                    f"Failed to send Mattermost notification: {response.status_code}"
                )
                return False

    except Exception as e:
        logger.error(f"Error sending Mattermost notification: {e}")
        return False


async def notify_issue_created(
    feedback_id: int,
    issue_url: str,
    priority: str,
    category: str,
    feedback_type: str,
    comment_preview: str
) -> bool:
    """
    Send notification when a new issue is created from feedback.

    Args:
        feedback_id: Feedback ID
        issue_url: GitHub issue URL
        priority: Priority label (P0-P3)
        category: Feedback category
        feedback_type: Type of feedback
        comment_preview: Preview of the feedback comment

    Returns:
        True if notification sent successfully
    """
    # Determine emoji based on priority
    priority_emoji = {
        "P0": "🚨",
        "P1": "⚠️",
        "P2": "📋",
        "P3": "💡"
    }
    emoji = priority_emoji.get(priority, "📝")

    # Determine type label
    type_label = {
        "bug_report": "🐛 Bug",
        "feature_request": "✨ Feature Request",
        "feedback": "💬 Feedback"
    }
    type_str = type_label.get(feedback_type, "📝 Feedback")

    # Truncate comment if too long
    max_length = 150
    if len(comment_preview) > max_length:
        comment_preview = comment_preview[:max_length] + "..."

    message = f"""
### {emoji} New Issue Created from Feedback

**Type:** {type_str}
**Priority:** {priority}
**Category:** {category}
**Feedback ID:** #{feedback_id}

> {comment_preview}

[View Issue on GitHub]({issue_url})
"""

    return await send_mattermost_notification(message)


async def notify_duplicate_detected(
    feedback_id: int,
    duplicates: List[Dict[str, any]],
    category: str,
    comment_preview: str
) -> bool:
    """
    Send notification when duplicate issues are detected.

    Args:
        feedback_id: Feedback ID
        duplicates: List of duplicate issue information
        category: Feedback category
        comment_preview: Preview of the feedback comment

    Returns:
        True if notification sent successfully
    """
    if not duplicates:
        return False

    # Get the top duplicate
    top_duplicate = duplicates[0]
    similarity = top_duplicate.get("similarity", 0.0)

    # Truncate comment if too long
    max_length = 100
    if len(comment_preview) > max_length:
        comment_preview = comment_preview[:max_length] + "..."

    message = f"""
### 🔍 Duplicate Feedback Detected

**Feedback ID:** #{feedback_id}
**Category:** {category}

> {comment_preview}

**Potential Duplicate:** [#{top_duplicate['issue_number']}]({top_duplicate['issue_url']})
**Similarity:** {similarity:.0%}
**Total Matches:** {len(duplicates)}

Issue creation skipped. Consider commenting on existing issue instead.
"""

    return await send_mattermost_notification(message)


async def notify_high_priority_feedback(
    feedback_id: int,
    priority: str,
    category: str,
    rating: int,
    comment_preview: str,
    sentiment: Optional[str] = None
) -> bool:
    """
    Send immediate notification for high-priority feedback (P0/P1).

    Args:
        feedback_id: Feedback ID
        priority: Priority label
        category: Feedback category
        rating: User rating
        comment_preview: Preview of the feedback comment
        sentiment: Sentiment classification

    Returns:
        True if notification sent successfully
    """
    # Only notify for P0 and P1
    if priority not in ["P0", "P1"]:
        return False

    # Emoji based on priority
    emoji = "🚨" if priority == "P0" else "⚠️"

    # Truncate comment if too long
    max_length = 200
    if len(comment_preview) > max_length:
        comment_preview = comment_preview[:max_length] + "..."

    sentiment_str = f" ({sentiment})" if sentiment else ""
    rating_stars = "⭐" * rating

    message = f"""
### {emoji} High-Priority Feedback Received

**Priority:** {priority}
**Category:** {category}
**Rating:** {rating_stars} ({rating}/5){sentiment_str}
**Feedback ID:** #{feedback_id}

> {comment_preview}

**Action Required:** This feedback requires immediate attention.
"""

    return await send_mattermost_notification(message)


async def notify_automation_summary(
    processed: int,
    issues_created: int,
    skipped_duplicates: int,
    errors: Optional[List[str]] = None
) -> bool:
    """
    Send summary notification after automated processing.

    Args:
        processed: Number of feedback items processed
        issues_created: Number of issues created
        skipped_duplicates: Number of duplicates skipped
        errors: List of error messages

    Returns:
        True if notification sent successfully
    """
    if processed == 0:
        return False

    error_section = ""
    if errors and len(errors) > 0:
        error_count = len(errors)
        error_section = f"\n**Errors:** {error_count}"

    message = f"""
### 🤖 Automation Summary

**Processed:** {processed} feedback items
**Issues Created:** {issues_created}
**Duplicates Skipped:** {skipped_duplicates}{error_section}

Automated feedback-to-issue pipeline completed successfully.
"""

    return await send_mattermost_notification(message)
