"""
GitHub Integration module for Feedback service.

This module provides functionality to create GitHub issues from feedback submissions.
It supports automatic issue creation with labels, screenshot attachments, and linking.
"""
import os
import logging
import base64
from typing import Optional, Tuple
import httpx

logger = logging.getLogger(__name__)

# GitHub configuration from environment
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GITHUB_OWNER = os.getenv("GITHUB_OWNER", "paruff")
GITHUB_REPO = os.getenv("GITHUB_REPO", "fawkes")
GITHUB_API_URL = "https://api.github.com"


def is_github_enabled() -> bool:
    """Check if GitHub integration is enabled."""
    return GITHUB_TOKEN is not None


async def create_github_issue(
    feedback_id: int,
    feedback_type: str,
    category: str,
    comment: str,
    page_url: Optional[str] = None,
    rating: Optional[int] = None,
    email: Optional[str] = None,
    screenshot_data: Optional[str] = None,
    browser_info: Optional[str] = None,
    user_agent: Optional[str] = None
) -> Tuple[bool, Optional[str], Optional[str]]:
    """
    Create a GitHub issue from feedback submission.

    Args:
        feedback_id: ID of the feedback in the database
        feedback_type: Type of feedback (bug_report, feature_request, feedback)
        category: Feedback category
        comment: User's feedback comment
        page_url: URL of the page where feedback was submitted
        rating: User rating (1-5)
        email: User email for follow-up
        screenshot_data: Base64 encoded screenshot data
        browser_info: Browser information
        user_agent: User agent string

    Returns:
        Tuple of (success: bool, issue_url: Optional[str], error: Optional[str])
    """
    if not is_github_enabled():
        logger.warning("GitHub integration not enabled - GITHUB_TOKEN not set")
        return False, None, "GitHub integration not configured"

    try:
        # Determine issue title prefix based on feedback type
        prefix_map = {
            "bug_report": "🐛 Bug",
            "feature_request": "✨ Feature Request",
            "feedback": "💬 Feedback"
        }
        prefix = prefix_map.get(feedback_type, "💬 Feedback")

        # Create issue title
        title = f"{prefix}: {comment[:80]}..." if len(comment) > 80 else f"{prefix}: {comment}"

        # Build issue body
        body_parts = [
            f"**Feedback ID**: {feedback_id}",
            f"**Type**: {feedback_type}",
            f"**Category**: {category}",
            ""
        ]

        if rating:
            body_parts.extend([
                f"**Rating**: {'⭐' * rating} ({rating}/5)",
                ""
            ])

        body_parts.extend([
            "## Description",
            comment,
            ""
        ])

        if page_url:
            body_parts.extend([
                "## Context",
                f"**Page URL**: {page_url}",
                ""
            ])

        if browser_info:
            body_parts.append(f"**Browser**: {browser_info}")

        if user_agent:
            body_parts.append(f"**User Agent**: {user_agent}")

        if email:
            body_parts.extend([
                "",
                "## Contact",
                f"**Email**: {email}",
                ""
            ])

        if screenshot_data:
            body_parts.extend([
                "",
                "## Screenshot",
                "A screenshot has been captured and will be attached to this issue.",
                ""
            ])

        body_parts.extend([
            "",
            "---",
            f"*This issue was automatically created from user feedback via the Fawkes Developer Portal.*"
        ])

        body = "\n".join(body_parts)

        # Determine labels based on type and category
        labels = ["feedback", "automated"]
        if feedback_type == "bug_report":
            labels.append("bug")
        elif feedback_type == "feature_request":
            labels.append("enhancement")

        # Add category as label (normalized)
        category_label = category.lower().replace("/", "-").replace(" ", "-")
        labels.append(f"category:{category_label}")

        # Create the issue
        headers = {
            "Authorization": f"Bearer {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json",
            "X-GitHub-Api-Version": "2022-11-28"
        }

        issue_data = {
            "title": title,
            "body": body,
            "labels": labels
        }

        async with httpx.AsyncClient() as client:
            # Create the issue
            response = await client.post(
                f"{GITHUB_API_URL}/repos/{GITHUB_OWNER}/{GITHUB_REPO}/issues",
                json=issue_data,
                headers=headers,
                timeout=30.0
            )

            if response.status_code not in [200, 201]:
                error_msg = f"Failed to create GitHub issue: {response.status_code} - {response.text}"
                logger.error(error_msg)
                return False, None, error_msg

            issue = response.json()
            issue_url = issue.get("html_url")
            issue_number = issue.get("number")

            logger.info(f"✅ Created GitHub issue #{issue_number} for feedback ID {feedback_id}: {issue_url}")

            # If screenshot is provided, try to attach it as a comment
            if screenshot_data and issue_number:
                await _attach_screenshot_to_issue(
                    client, headers, issue_number, screenshot_data, feedback_id
                )

            return True, issue_url, None

    except Exception as e:
        error_msg = f"Error creating GitHub issue: {str(e)}"
        logger.error(error_msg)
        return False, None, error_msg


async def _attach_screenshot_to_issue(
    client: httpx.AsyncClient,
    headers: dict,
    issue_number: int,
    screenshot_data: str,
    feedback_id: int
) -> bool:
    """
    Attach screenshot to GitHub issue as a comment with image.

    Since GitHub API doesn't support direct image uploads in issue creation,
    we need to:
    1. Upload the image as an asset
    2. Add a comment with the image markdown

    Note: This is a simplified version. In production, you might want to:
    - Upload to GitHub's image hosting via the GraphQL API
    - Use a separate image storage service (S3, etc.)
    - Include the image URL in the issue body
    """
    try:
        # For now, we'll add a comment noting the screenshot is available
        # In production, you'd upload the screenshot to external storage
        # and include the URL in the comment

        comment_body = (
            f"## 📸 Screenshot\n\n"
            f"A screenshot was captured with this feedback submission.\n\n"
            f"*Note: Screenshot data is stored in the feedback database (ID: {feedback_id}). "
            f"For privacy and security, screenshots are not automatically uploaded to GitHub. "
            f"Admins can retrieve the screenshot via the feedback API.*"
        )

        response = await client.post(
            f"{GITHUB_API_URL}/repos/{GITHUB_OWNER}/{GITHUB_REPO}/issues/{issue_number}/comments",
            json={"body": comment_body},
            headers=headers,
            timeout=30.0
        )

        if response.status_code not in [200, 201]:
            logger.warning(
                f"Failed to add screenshot comment to issue #{issue_number}: "
                f"{response.status_code}"
            )
            return False

        logger.info(f"✅ Added screenshot note to GitHub issue #{issue_number}")
        return True

    except Exception as e:
        logger.error(f"Error attaching screenshot to issue: {e}")
        return False


async def update_issue_status(
    issue_url: str,
    new_status: str,
    feedback_id: int
) -> Tuple[bool, Optional[str]]:
    """
    Update a GitHub issue status based on feedback status changes.

    Args:
        issue_url: URL of the GitHub issue
        new_status: New feedback status (open, in_progress, resolved, dismissed)
        feedback_id: ID of the feedback in the database

    Returns:
        Tuple of (success: bool, error: Optional[str])
    """
    if not is_github_enabled():
        return False, "GitHub integration not configured"

    try:
        # Extract issue number from URL
        # Format: https://github.com/{owner}/{repo}/issues/{number}
        parts = issue_url.rstrip('/').split('/')
        if len(parts) < 2 or not parts[-1].isdigit():
            return False, "Invalid issue URL format"

        issue_number = int(parts[-1])

        # Map feedback status to GitHub issue state and labels
        status_map = {
            "resolved": ("closed", "resolution:completed"),
            "dismissed": ("closed", "resolution:wont-fix"),
            "in_progress": ("open", "status:in-progress"),
            "open": ("open", None)
        }

        github_state, label = status_map.get(new_status, ("open", None))

        headers = {
            "Authorization": f"Bearer {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json",
            "X-GitHub-Api-Version": "2022-11-28"
        }

        async with httpx.AsyncClient() as client:
            # Update issue state
            update_data = {"state": github_state}

            response = await client.patch(
                f"{GITHUB_API_URL}/repos/{GITHUB_OWNER}/{GITHUB_REPO}/issues/{issue_number}",
                json=update_data,
                headers=headers,
                timeout=30.0
            )

            if response.status_code not in [200, 201]:
                error_msg = f"Failed to update issue state: {response.status_code}"
                logger.error(error_msg)
                return False, error_msg

            # Add status label if applicable
            if label:
                await client.post(
                    f"{GITHUB_API_URL}/repos/{GITHUB_OWNER}/{GITHUB_REPO}/issues/{issue_number}/labels",
                    json={"labels": [label]},
                    headers=headers,
                    timeout=30.0
                )

            # Add a comment about the status change
            comment_body = (
                f"Feedback status updated to **{new_status}** "
                f"(Feedback ID: {feedback_id})\n\n"
                f"*This update was automatically synced from the Fawkes Developer Portal.*"
            )

            await client.post(
                f"{GITHUB_API_URL}/repos/{GITHUB_OWNER}/{GITHUB_REPO}/issues/{issue_number}/comments",
                json={"body": comment_body},
                headers=headers,
                timeout=30.0
            )

            logger.info(
                f"✅ Updated GitHub issue #{issue_number} to {github_state} "
                f"for feedback ID {feedback_id}"
            )
            return True, None

    except Exception as e:
        error_msg = f"Error updating GitHub issue: {str(e)}"
        logger.error(error_msg)
        return False, error_msg
