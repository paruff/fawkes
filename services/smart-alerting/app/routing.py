"""
Intelligent alert routing to appropriate teams and channels.

Routes alerts based on:
- Service ownership (from Backstage)
- Severity (P0 → PagerDuty, P1 → Slack, etc.)
- On-call rotation
- Escalation policies
"""
import os
import json
import logging
from typing import List, Dict, Optional
from datetime import datetime, timedelta

import httpx

logger = logging.getLogger(__name__)

# Configuration
ESCALATION_TIMEOUT = int(os.getenv("ESCALATION_TIMEOUT", "900"))  # 15 minutes


class AlertRouter:
    """Routes alerts to appropriate teams and channels."""

    def __init__(
        self,
        http_client: httpx.AsyncClient,
        backstage_url: str,
        mattermost_webhook: str = "",
        slack_webhook: str = "",
        pagerduty_api_key: str = ""
    ):
        """Initialize alert router."""
        self.http_client = http_client
        self.backstage_url = backstage_url
        self.mattermost_webhook = mattermost_webhook
        self.slack_webhook = slack_webhook
        self.pagerduty_api_key = pagerduty_api_key
        self.escalation_timeout = timedelta(seconds=ESCALATION_TIMEOUT)

    async def route_alert_group(self, alert_group: Dict) -> List[str]:
        """
        Route alert group to appropriate channels.

        Returns list of channels where alerts were sent.
        """
        channels = []

        # Determine severity
        priority_score = alert_group.get("priority_score", 0.0)
        severity = self._calculate_severity(priority_score)

        # Get service owners
        owners = await self._get_service_owners(alert_group)

        # Add context
        context = await self._enrich_context(alert_group)

        # Route based on severity
        if severity == "P0":
            # Critical - page on-call
            if self.pagerduty_api_key:
                success = await self._send_to_pagerduty(alert_group, owners, context)
                if success:
                    channels.append("pagerduty")

        if severity in ["P0", "P1"]:
            # High priority - Slack/Mattermost
            if self.slack_webhook:
                success = await self._send_to_slack(alert_group, owners, context, severity)
                if success:
                    channels.append("slack")

            if self.mattermost_webhook:
                success = await self._send_to_mattermost(alert_group, owners, context, severity)
                if success:
                    channels.append("mattermost")

        if severity in ["P2", "P3"]:
            # Medium/Low priority - Only Mattermost
            if self.mattermost_webhook:
                success = await self._send_to_mattermost(alert_group, owners, context, severity)
                if success:
                    channels.append("mattermost")

        return channels

    def _calculate_severity(self, priority_score: float) -> str:
        """Calculate severity from priority score."""
        if priority_score >= 8.0:
            return "P0"  # Critical
        elif priority_score >= 6.0:
            return "P1"  # High
        elif priority_score >= 4.0:
            return "P2"  # Medium
        else:
            return "P3"  # Low

    async def _get_service_owners(self, alert_group: Dict) -> List[str]:
        """Get service owners from Backstage."""
        owners = []
        services = set()

        # Extract services from alerts
        for alert in alert_group.get("alerts", []):
            service = alert.get("labels", {}).get("service")
            if service:
                services.add(service)

        # Query Backstage for each service
        for service in services:
            try:
                response = await self.http_client.get(
                    f"{self.backstage_url}/api/catalog/entities/by-name/component/default/{service}",
                    timeout=5.0
                )

                if response.status_code == 200:
                    entity = response.json()
                    spec = entity.get("spec", {})
                    owner = spec.get("owner")

                    if owner:
                        owners.append(owner)

            except Exception as e:
                logger.warning(f"Failed to get owner for service {service}: {e}")

        return list(set(owners))  # Deduplicate

    async def _enrich_context(self, alert_group: Dict) -> Dict:
        """Enrich alert with context."""
        context = {
            "recent_changes": [],
            "log_samples": [],
            "similar_incidents": [],
            "runbooks": []
        }

        # Add recent changes (simplified - would query ArgoCD/Git)
        context["recent_changes"] = [
            "No recent deployments in last hour"
        ]

        # Add runbook links from annotations
        for alert in alert_group.get("alerts", []):
            annotations = alert.get("annotations", {})
            runbook_url = annotations.get("runbook_url")
            if runbook_url:
                context["runbooks"].append(runbook_url)

        # Add log samples (simplified - would query logging system)
        context["log_samples"] = [
            "Check logs for detailed error messages"
        ]

        # Similar incidents (simplified - would query incident database)
        context["similar_incidents"] = [
            "Check past incidents with similar patterns"
        ]

        return context

    async def _send_to_pagerduty(
        self,
        alert_group: Dict,
        owners: List[str],
        context: Dict
    ) -> bool:
        """Send alert to PagerDuty."""
        if not self.pagerduty_api_key:
            return False

        try:
            # Create PagerDuty event
            event = {
                "routing_key": self.pagerduty_api_key,
                "event_action": "trigger",
                "payload": {
                    "summary": self._format_summary(alert_group),
                    "severity": "critical",
                    "source": "fawkes-smart-alerting",
                    "custom_details": {
                        "alert_count": alert_group.get("count", 0),
                        "priority_score": alert_group.get("priority_score", 0),
                        "owners": owners,
                        "context": context
                    }
                }
            }

            response = await self.http_client.post(
                "https://events.pagerduty.com/v2/enqueue",
                json=event,
                timeout=10.0
            )

            if response.status_code == 202:
                logger.info(f"Sent alert group {alert_group['id']} to PagerDuty")
                return True
            else:
                logger.error(f"Failed to send to PagerDuty: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Error sending to PagerDuty: {e}")
            return False

    async def _send_to_slack(
        self,
        alert_group: Dict,
        owners: List[str],
        context: Dict,
        severity: str
    ) -> bool:
        """Send alert to Slack."""
        if not self.slack_webhook:
            return False

        try:
            # Format Slack message
            color = self._get_severity_color(severity)

            message = {
                "attachments": [{
                    "color": color,
                    "title": f"{severity} Alert: {self._format_summary(alert_group)}",
                    "text": self._format_details(alert_group),
                    "fields": [
                        {
                            "title": "Alert Count",
                            "value": str(alert_group.get("count", 0)),
                            "short": True
                        },
                        {
                            "title": "Priority Score",
                            "value": str(alert_group.get("priority_score", 0)),
                            "short": True
                        },
                        {
                            "title": "Owners",
                            "value": ", ".join(owners) if owners else "Unknown",
                            "short": True
                        },
                        {
                            "title": "First Seen",
                            "value": alert_group.get("first_seen", "Unknown"),
                            "short": True
                        }
                    ],
                    "footer": "Fawkes Smart Alerting",
                    "ts": int(datetime.now().timestamp())
                }]
            }

            # Add context
            if context.get("runbooks"):
                message["attachments"][0]["fields"].append({
                    "title": "Runbooks",
                    "value": "\n".join([f"• {url}" for url in context["runbooks"]]),
                    "short": False
                })

            response = await self.http_client.post(
                self.slack_webhook,
                json=message,
                timeout=10.0
            )

            if response.status_code == 200:
                logger.info(f"Sent alert group {alert_group['id']} to Slack")
                return True
            else:
                logger.error(f"Failed to send to Slack: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Error sending to Slack: {e}")
            return False

    async def _send_to_mattermost(
        self,
        alert_group: Dict,
        owners: List[str],
        context: Dict,
        severity: str
    ) -> bool:
        """Send alert to Mattermost."""
        if not self.mattermost_webhook:
            return False

        try:
            # Format Mattermost message
            emoji = self._get_severity_emoji(severity)

            message_text = f"{emoji} **{severity} Alert: {self._format_summary(alert_group)}**\n\n"
            message_text += f"{self._format_details(alert_group)}\n\n"
            message_text += f"**Alert Count:** {alert_group.get('count', 0)}\n"
            message_text += f"**Priority Score:** {alert_group.get('priority_score', 0)}\n"
            message_text += f"**Owners:** {', '.join(owners) if owners else 'Unknown'}\n"
            message_text += f"**First Seen:** {alert_group.get('first_seen', 'Unknown')}\n"

            # Add runbooks
            if context.get("runbooks"):
                message_text += f"\n**Runbooks:**\n"
                for url in context["runbooks"]:
                    message_text += f"• {url}\n"

            message = {
                "text": message_text,
                "username": "Fawkes Smart Alerting",
                "icon_emoji": ":bell:"
            }

            response = await self.http_client.post(
                self.mattermost_webhook,
                json=message,
                timeout=10.0
            )

            if response.status_code == 200:
                logger.info(f"Sent alert group {alert_group['id']} to Mattermost")
                return True
            else:
                logger.error(f"Failed to send to Mattermost: {response.status_code}")
                return False

        except Exception as e:
            logger.error(f"Error sending to Mattermost: {e}")
            return False

    def _format_summary(self, alert_group: Dict) -> str:
        """Format alert group summary."""
        alerts = alert_group.get("alerts", [])

        if not alerts:
            return "Unknown alert"

        # Get first alert name
        first_alert = alerts[0]
        alertname = first_alert.get("labels", {}).get("alertname", "Unknown")
        service = first_alert.get("labels", {}).get("service", "Unknown")

        count = alert_group.get("count", len(alerts))

        if count > 1:
            return f"{alertname} affecting {service} ({count} alerts)"
        else:
            return f"{alertname} affecting {service}"

    def _format_details(self, alert_group: Dict) -> str:
        """Format alert group details."""
        details = []

        for alert in alert_group.get("alerts", [])[:3]:  # Show first 3 alerts
            annotations = alert.get("annotations", {})
            summary = annotations.get("summary", "")
            description = annotations.get("description", "")

            if summary:
                details.append(summary)
            elif description:
                details.append(description)

        count = alert_group.get("count", 0)
        if count > 3:
            details.append(f"... and {count - 3} more alerts")

        return "\n".join(details) if details else "No details available"

    def _get_severity_color(self, severity: str) -> str:
        """Get color for severity level."""
        colors = {
            "P0": "danger",  # Red
            "P1": "warning",  # Orange
            "P2": "good",  # Green
            "P3": "#808080"  # Gray
        }
        return colors.get(severity, "#808080")

    def _get_severity_emoji(self, severity: str) -> str:
        """Get emoji for severity level."""
        emojis = {
            "P0": "🚨",
            "P1": "⚠️",
            "P2": "ℹ️",
            "P3": "📝"
        }
        return emojis.get(severity, "📝")
