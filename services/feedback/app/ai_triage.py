"""
AI Triage module for Feedback service.

This module provides AI-assisted triage and prioritization of feedback submissions.
It analyzes feedback to determine priority, detect duplicates, and suggest appropriate
labels and assignments.
"""
import os
import logging
import re
from typing import Optional, Tuple, List, Dict
from difflib import SequenceMatcher
import httpx

logger = logging.getLogger(__name__)

# GitHub configuration
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
GITHUB_OWNER = os.getenv("GITHUB_OWNER", "paruff")
GITHUB_REPO = os.getenv("GITHUB_REPO", "fawkes")
GITHUB_API_URL = "https://api.github.com"

# Priority thresholds
PRIORITY_THRESHOLDS = {
    "P0": {
        "min_severity": 0.8,
        "keywords": ["critical", "urgent", "blocker", "security", "data loss", "outage", "down", "broken"],
        "sentiment_max": -0.5,  # Very negative
    },
    "P1": {
        "min_severity": 0.6,
        "keywords": ["important", "blocking", "major", "error", "failure", "crash"],
        "sentiment_max": -0.2,
    },
    "P2": {
        "min_severity": 0.4,
        "keywords": ["enhancement", "improvement", "feature", "request"],
        "sentiment_max": 0.2,
    },
    "P3": {
        "min_severity": 0.0,
        "keywords": ["minor", "nice to have", "suggestion", "polish"],
        "sentiment_max": 1.0,
    },
}


def calculate_priority_score(
    feedback_type: str, category: str, comment: str, rating: int, sentiment_compound: Optional[float] = None
) -> Tuple[str, float, Dict[str, any]]:
    """
    Calculate priority for feedback using AI-based scoring.

    Args:
        feedback_type: Type of feedback (bug_report, feature_request, feedback)
        category: Feedback category
        comment: User's feedback comment
        rating: User rating (1-5)
        sentiment_compound: Sentiment compound score (-1 to +1)

    Returns:
        Tuple of (priority: str, score: float, details: dict)
    """
    score = 0.0
    details = {
        "type_score": 0.0,
        "rating_score": 0.0,
        "sentiment_score": 0.0,
        "keyword_score": 0.0,
        "category_score": 0.0,
        "matched_keywords": [],
    }

    # Type scoring (40% weight)
    type_weights = {"bug_report": 0.8, "feature_request": 0.4, "feedback": 0.2}
    details["type_score"] = type_weights.get(feedback_type, 0.2) * 0.4
    score += details["type_score"]

    # Rating scoring (25% weight) - Lower ratings = higher priority
    # Convert 1-5 rating to 0-1 score (inverted)
    rating_normalized = (6 - rating) / 5.0  # 1->1.0, 5->0.2
    details["rating_score"] = rating_normalized * 0.25
    score += details["rating_score"]

    # Sentiment scoring (20% weight) - More negative = higher priority
    if sentiment_compound is not None:
        # Convert -1 to +1 range to 0-1 score (inverted)
        sentiment_normalized = (1 - sentiment_compound) / 2.0  # -1->1.0, +1->0.0
        details["sentiment_score"] = sentiment_normalized * 0.20
        score += details["sentiment_score"]

    # Keyword scoring (10% weight)
    comment_lower = comment.lower()
    matched_keywords = []
    keyword_weight = 0.0

    for priority, config in PRIORITY_THRESHOLDS.items():
        for keyword in config["keywords"]:
            if keyword in comment_lower:
                matched_keywords.append(keyword)
                # Higher priority keywords get more weight
                if priority == "P0":
                    keyword_weight = max(keyword_weight, 1.0)
                elif priority == "P1":
                    keyword_weight = max(keyword_weight, 0.7)
                elif priority == "P2":
                    keyword_weight = max(keyword_weight, 0.4)

    details["keyword_score"] = keyword_weight * 0.10
    details["matched_keywords"] = matched_keywords
    score += details["keyword_score"]

    # Category scoring (5% weight)
    high_priority_categories = ["Security", "Performance", "Bug Report", "CI/CD", "Deployment"]
    if category in high_priority_categories:
        details["category_score"] = 0.05
        score += details["category_score"]

    # Determine priority label based on score
    if score >= 0.65:
        priority = "P0"
    elif score >= 0.45:
        priority = "P1"
    elif score >= 0.25:
        priority = "P2"
    else:
        priority = "P3"

    logger.info(
        f"Priority calculated: {priority} (score: {score:.2f}) - "
        f"type: {feedback_type}, rating: {rating}, keywords: {matched_keywords}"
    )

    return priority, score, details


def suggest_labels(feedback_type: str, category: str, priority: str, comment: str) -> List[str]:
    """
    Suggest GitHub labels for the issue based on feedback characteristics.

    Args:
        feedback_type: Type of feedback
        category: Feedback category
        priority: Calculated priority (P0-P3)
        comment: User's feedback comment

    Returns:
        List of suggested label names
    """
    labels = ["feedback", "automated"]

    # Type-based labels
    if feedback_type == "bug_report":
        labels.append("bug")
    elif feedback_type == "feature_request":
        labels.append("enhancement")

    # Priority label
    labels.append(priority)

    # Category label (normalized)
    category_label = category.lower().replace("/", "-").replace(" ", "-")
    labels.append(f"category:{category_label}")

    # Keyword-based labels
    comment_lower = comment.lower()

    if any(word in comment_lower for word in ["security", "vulnerability", "exploit"]):
        labels.append("security")

    if any(word in comment_lower for word in ["performance", "slow", "latency"]):
        labels.append("performance")

    if any(word in comment_lower for word in ["documentation", "docs", "guide"]):
        labels.append("documentation")

    if any(word in comment_lower for word in ["ux", "ui", "interface", "design"]):
        labels.append("ux")

    if any(word in comment_lower for word in ["accessibility", "a11y", "screen reader"]):
        labels.append("accessibility")

    logger.info(f"Suggested labels: {labels}")
    return labels


async def detect_duplicates(
    comment: str, category: str, feedback_type: str, similarity_threshold: float = 0.7
) -> List[Dict[str, any]]:
    """
    Detect potential duplicate issues in GitHub repository.

    Args:
        comment: User's feedback comment
        category: Feedback category
        feedback_type: Type of feedback
        similarity_threshold: Minimum similarity score (0-1) to consider as duplicate

    Returns:
        List of potential duplicate issues with similarity scores
    """
    if not GITHUB_TOKEN:
        logger.warning("GitHub token not configured, skipping duplicate detection")
        return []

    try:
        headers = {
            "Authorization": f"Bearer {GITHUB_TOKEN}",
            "Accept": "application/vnd.github.v3+json",
            "X-GitHub-Api-Version": "2022-11-28",
        }

        # Search for open issues with feedback label and similar category
        category_normalized = category.lower().replace("/", "-").replace(" ", "-")
        search_query = (
            f"repo:{GITHUB_OWNER}/{GITHUB_REPO} "
            f"is:issue is:open label:feedback label:category:{category_normalized}"
        )

        async with httpx.AsyncClient() as client:
            response = await client.get(
                f"{GITHUB_API_URL}/search/issues",
                params={"q": search_query, "per_page": 20},
                headers=headers,
                timeout=30.0,
            )

            if response.status_code != 200:
                logger.warning(f"Failed to search issues: {response.status_code}")
                return []

            data = response.json()
            issues = data.get("items", [])

            duplicates = []
            comment_lower = comment.lower()

            for issue in issues:
                issue_title = issue.get("title", "")
                issue_body = issue.get("body", "")

                # Calculate similarity with title and body
                title_similarity = _calculate_similarity(comment_lower, issue_title.lower())
                body_similarity = _calculate_similarity(comment_lower, issue_body.lower())

                # Take the higher similarity score
                similarity = max(title_similarity, body_similarity)

                if similarity >= similarity_threshold:
                    duplicates.append(
                        {
                            "issue_number": issue.get("number"),
                            "issue_url": issue.get("html_url"),
                            "title": issue_title,
                            "similarity": similarity,
                            "state": issue.get("state"),
                        }
                    )
                    logger.info(f"Potential duplicate found: #{issue.get('number')} " f"(similarity: {similarity:.2f})")

            # Sort by similarity (highest first)
            duplicates.sort(key=lambda x: x["similarity"], reverse=True)

            return duplicates

    except Exception as e:
        logger.error(f"Error detecting duplicates: {e}")
        return []


def _calculate_similarity(text1: str, text2: str) -> float:
    """
    Calculate similarity between two text strings using SequenceMatcher.

    Args:
        text1: First text string
        text2: Second text string

    Returns:
        Similarity score (0-1)
    """
    # Handle empty strings
    if not text1 or not text2:
        return 0.0

    # Use SequenceMatcher for fuzzy matching
    matcher = SequenceMatcher(None, text1, text2)
    return matcher.ratio()


def determine_milestone(priority: str, feedback_type: str) -> Optional[str]:
    """
    Determine appropriate milestone for the issue based on priority.

    Args:
        priority: Priority label (P0-P3)
        feedback_type: Type of feedback

    Returns:
        Milestone name or None
    """
    # Map priorities to milestones
    # These should match your GitHub repository milestones
    milestone_map = {"P0": "Hotfix", "P1": "Next Sprint", "P2": "Backlog", "P3": "Future"}

    milestone = milestone_map.get(priority)

    logger.info(f"Suggested milestone for {priority}: {milestone}")
    return milestone


async def triage_feedback(
    feedback_id: int,
    feedback_type: str,
    category: str,
    comment: str,
    rating: int,
    sentiment_compound: Optional[float] = None,
) -> Dict[str, any]:
    """
    Perform complete AI triage on feedback submission.

    This is the main entry point for the triage process. It orchestrates
    priority calculation, label suggestion, and duplicate detection.

    Args:
        feedback_id: ID of the feedback in the database
        feedback_type: Type of feedback
        category: Feedback category
        comment: User's feedback comment
        rating: User rating (1-5)
        sentiment_compound: Sentiment compound score

    Returns:
        Dictionary with triage results
    """
    logger.info(f"Starting AI triage for feedback ID {feedback_id}")

    # Calculate priority
    priority, score, details = calculate_priority_score(feedback_type, category, comment, rating, sentiment_compound)

    # Suggest labels
    labels = suggest_labels(feedback_type, category, priority, comment)

    # Detect duplicates
    duplicates = await detect_duplicates(comment, category, feedback_type)

    # Determine milestone
    milestone = determine_milestone(priority, feedback_type)

    triage_result = {
        "feedback_id": feedback_id,
        "priority": priority,
        "priority_score": score,
        "priority_details": details,
        "suggested_labels": labels,
        "potential_duplicates": duplicates,
        "suggested_milestone": milestone,
        "should_create_issue": len(duplicates) == 0,  # Don't create if duplicates found
        "triage_reason": (
            "Duplicate issues found" if duplicates else f"Priority {priority} based on score {score:.2f}"
        ),
    }

    logger.info(
        f"✅ Triage complete for feedback ID {feedback_id}: "
        f"priority={priority}, duplicates={len(duplicates)}, "
        f"create_issue={triage_result['should_create_issue']}"
    )

    return triage_result
