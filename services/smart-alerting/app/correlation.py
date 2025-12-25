"""
Alert correlation engine for grouping related alerts.

Groups alerts by:
- Time proximity (within correlation window)
- Service (same service label)
- Symptom (similar alert patterns)
"""
import os
import json
import hashlib
from typing import List, Dict, Optional, Tuple
from datetime import datetime, timedelta
from collections import defaultdict
import logging

import redis.asyncio as redis

logger = logging.getLogger(__name__)

# Configuration
CORRELATION_TIME_WINDOW = int(os.getenv("CORRELATION_TIME_WINDOW", "300"))  # 5 minutes


class AlertCorrelator:
    """Correlates and groups related alerts."""

    def __init__(self, redis_client: redis.Redis):
        """Initialize correlator with Redis client."""
        self.redis = redis_client
        self.time_window = timedelta(seconds=CORRELATION_TIME_WINDOW)

    async def correlate_alerts(self, alerts: List[Dict]) -> List[Dict]:
        """
        Correlate incoming alerts and group related ones.

        Returns list of alert groups.
        """
        groups = []

        # Convert alerts to dict if needed
        alert_dicts = []
        for alert in alerts:
            if hasattr(alert, 'dict'):
                alert_dicts.append(alert.dict())
            else:
                alert_dicts.append(alert)

        # Group by correlation key
        correlation_map = defaultdict(list)

        for alert in alert_dicts:
            key = self._generate_grouping_key(alert)
            correlation_map[key].append(alert)

        # Create alert groups
        for grouping_key, grouped_alerts in correlation_map.items():
            # Check for existing group
            existing_group = await self._get_existing_group(grouping_key)

            if existing_group:
                # Update existing group
                existing_group["alerts"].extend(grouped_alerts)
                existing_group["count"] = len(existing_group["alerts"])
                existing_group["last_seen"] = datetime.now().isoformat()

                # Recalculate priority
                existing_group["priority_score"] = self._calculate_priority(existing_group["alerts"])

                await self._save_group(existing_group)
                groups.append(existing_group)
            else:
                # Create new group
                group = {
                    "id": self._generate_group_id(grouping_key),
                    "alerts": grouped_alerts,
                    "grouping_key": grouping_key,
                    "priority_score": self._calculate_priority(grouped_alerts),
                    "first_seen": datetime.now().isoformat(),
                    "last_seen": datetime.now().isoformat(),
                    "count": len(grouped_alerts),
                    "suppressed": False,
                    "suppression_reason": None,
                    "routed_to": None
                }

                await self._save_group(group)
                groups.append(group)

        # Deduplicate within groups
        for group in groups:
            group["alerts"] = self._deduplicate_alerts(group["alerts"])
            group["count"] = len(group["alerts"])

        return groups

    def _generate_grouping_key(self, alert: Dict) -> str:
        """
        Generate grouping key based on alert attributes.

        Groups by: service, alertname, severity
        """
        labels = alert.get("labels", {})

        service = labels.get("service", "unknown")
        alertname = labels.get("alertname", "unknown")
        severity = labels.get("severity", "medium")

        # Create a grouping key
        key = f"{service}:{alertname}:{severity}"
        return key

    def _generate_group_id(self, grouping_key: str) -> str:
        """Generate unique group ID from grouping key."""
        hash_obj = hashlib.md5(grouping_key.encode(), usedforsecurity=False)
        return f"group-{hash_obj.hexdigest()[:8]}"

    def _calculate_priority(self, alerts: List[Dict]) -> float:
        """
        Calculate priority score for alert group.

        Formula: severity_score × impact_score × frequency_score
        Range: 0.0 to 100.0
        """
        if not alerts:
            return 0.0

        # Severity scoring
        severity_map = {
            "critical": 10.0,
            "high": 7.5,
            "warning": 5.0,
            "medium": 5.0,
            "low": 2.5,
            "info": 1.0
        }

        max_severity = 0.0
        for alert in alerts:
            severity = alert.get("labels", {}).get("severity", "medium")
            score = severity_map.get(severity, 5.0)
            max_severity = max(max_severity, score)

        # Impact scoring (based on number of affected services/pods)
        affected_services = set()
        affected_pods = set()

        for alert in alerts:
            labels = alert.get("labels", {})
            if "service" in labels:
                affected_services.add(labels["service"])
            if "pod" in labels:
                affected_pods.add(labels["pod"])

        impact_score = min(len(affected_services) + len(affected_pods) * 0.5, 10.0)

        # Frequency scoring (based on alert count)
        frequency_score = min(len(alerts) * 0.5, 10.0)

        # Combined priority score
        priority = (max_severity * 0.5) + (impact_score * 0.3) + (frequency_score * 0.2)

        return round(priority, 2)

    def _deduplicate_alerts(self, alerts: List[Dict]) -> List[Dict]:
        """Remove duplicate alerts based on fingerprint or labels."""
        seen_fingerprints = set()
        deduplicated = []

        for alert in alerts:
            # Use fingerprint if available, otherwise generate from labels
            fingerprint = alert.get("fingerprint")
            if not fingerprint:
                labels = alert.get("labels", {})
                fingerprint = hashlib.md5(json.dumps(labels, sort_keys=True).encode(), usedforsecurity=False).hexdigest()

            if fingerprint not in seen_fingerprints:
                seen_fingerprints.add(fingerprint)
                deduplicated.append(alert)

        return deduplicated

    async def _get_existing_group(self, grouping_key: str) -> Optional[Dict]:
        """Get existing alert group from Redis."""
        group_id = self._generate_group_id(grouping_key)
        group_data = await self.redis.get(f"alert_group:{group_id}")

        if group_data:
            group = json.loads(group_data)

            # Check if group is still within time window
            last_seen = datetime.fromisoformat(group["last_seen"])
            if datetime.now() - last_seen < self.time_window:
                return group

        return None

    async def _save_group(self, group: Dict):
        """Save alert group to Redis."""
        group_id = group["id"]

        # Set with expiration (2x time window to keep history)
        expiration = int(self.time_window.total_seconds() * 2)

        await self.redis.setex(
            f"alert_group:{group_id}",
            expiration,
            json.dumps(group)
        )

        # Add to recent groups list
        await self.redis.lpush("alert_groups:recent", group_id)
        await self.redis.ltrim("alert_groups:recent", 0, 99)  # Keep last 100

    async def get_recent_groups(self, limit: int = 50) -> List[Dict]:
        """Get recent alert groups."""
        group_ids = await self.redis.lrange("alert_groups:recent", 0, limit - 1)

        groups = []
        for group_id in group_ids:
            group_data = await self.redis.get(f"alert_group:{group_id}")
            if group_data:
                groups.append(json.loads(group_data))

        return groups

    async def get_group(self, group_id: str) -> Optional[Dict]:
        """Get specific alert group."""
        group_data = await self.redis.get(f"alert_group:{group_id}")

        if group_data:
            return json.loads(group_data)

        return None
