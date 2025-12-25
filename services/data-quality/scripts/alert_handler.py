#!/usr/bin/env python3
"""
Alert handler for Great Expectations validation results.
Sends alerts to Mattermost on validation failures.
"""
import os
import json
import requests
from typing import Dict, Any
from datetime import datetime


def send_mattermost_alert(validation_result_suite: Any, data_docs_url: str = None) -> Dict[str, Any]:
    """
    Send alert to Mattermost when validation fails.

    Args:
        validation_result_suite: Great Expectations validation result
        data_docs_url: URL to the data docs (optional)

    Returns:
        Dict with alert status
    """
    webhook_url = os.environ.get("MATTERMOST_WEBHOOK_URL")
    alert_on_failure = os.environ.get("ALERT_ON_FAILURE", "true").lower() == "true"

    if not webhook_url:
        print("WARNING: MATTERMOST_WEBHOOK_URL not set, skipping alert")
        return {"status": "skipped", "reason": "webhook_url_not_set"}

    if not alert_on_failure:
        return {"status": "skipped", "reason": "alerts_disabled"}

    # Extract validation results
    success = validation_result_suite.success
    statistics = validation_result_suite.statistics

    if success:
        # Only alert on failures by default
        return {"status": "skipped", "reason": "validation_passed"}

    # Build alert message
    expectation_suite_name = validation_result_suite.meta.get("expectation_suite_name", "Unknown")
    run_time = datetime.now().strftime("%Y-%m-%d %H:%M:%S UTC")

    successful_expectations = statistics.get("successful_expectations", 0)
    failed_expectations = statistics.get("unsuccessful_expectations", 0)
    total_expectations = statistics.get("evaluated_expectations", 0)

    # Create Mattermost message
    message = {
        "text": f"## 🚨 Data Quality Validation Failed\n\n"
                f"**Suite:** {expectation_suite_name}\n"
                f"**Time:** {run_time}\n"
                f"**Status:** ❌ Failed\n\n"
                f"**Results:**\n"
                f"- Total Expectations: {total_expectations}\n"
                f"- Successful: ✅ {successful_expectations}\n"
                f"- Failed: ❌ {failed_expectations}\n\n"
    }

    if data_docs_url:
        message["text"] += f"**Details:** [View Data Docs]({data_docs_url})\n"

    # Send to Mattermost
    try:
        response = requests.post(webhook_url, json=message, timeout=10)
        response.raise_for_status()
        return {
            "status": "sent",
            "webhook_url": webhook_url,
            "success": success,
            "statistics": statistics
        }
    except Exception as e:
        print(f"ERROR: Failed to send alert to Mattermost: {e}")
        return {
            "status": "error",
            "error": str(e)
        }


def send_daily_summary(summary_data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Send daily summary of data quality validations.

    Args:
        summary_data: Dictionary with summary statistics

    Returns:
        Dict with alert status
    """
    webhook_url = os.environ.get("MATTERMOST_WEBHOOK_URL")
    send_daily = os.environ.get("SEND_DAILY_SUMMARY", "true").lower() == "true"

    if not webhook_url or not send_daily:
        return {"status": "skipped"}

    # Build summary message
    message = {
        "text": f"## 📊 Daily Data Quality Summary\n\n"
                f"**Date:** {datetime.now().strftime('%Y-%m-%d')}\n\n"
                f"**Validations Run:** {summary_data.get('total_validations', 0)}\n"
                f"**Passed:** ✅ {summary_data.get('passed_validations', 0)}\n"
                f"**Failed:** ❌ {summary_data.get('failed_validations', 0)}\n\n"
                f"**Databases Checked:**\n"
    }

    for db, status in summary_data.get("databases", {}).items():
        emoji = "✅" if status == "passed" else "❌"
        message["text"] += f"- {emoji} {db}\n"

    try:
        response = requests.post(webhook_url, json=message, timeout=10)
        response.raise_for_status()
        return {"status": "sent"}
    except Exception as e:
        print(f"ERROR: Failed to send daily summary: {e}")
        return {"status": "error", "error": str(e)}


if __name__ == "__main__":
    # Test the alert handler
    print("Testing Mattermost alert handler...")

    # Mock validation result for testing
    class MockValidationResult:
        success = False
        statistics = {
            "evaluated_expectations": 10,
            "successful_expectations": 7,
            "unsuccessful_expectations": 3
        }
        meta = {
            "expectation_suite_name": "test_suite"
        }

    result = send_mattermost_alert(MockValidationResult())
    print(f"Alert result: {json.dumps(result, indent=2)}")
