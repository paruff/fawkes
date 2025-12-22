"""
Alert suppression engine for reducing alert noise.

Supports multiple suppression types:
- Maintenance windows
- Known issues
- Flapping alerts
- Cascade suppression
- Time-based suppression
"""
import os
import json
import yaml
import logging
from typing import List, Dict, Optional, Tuple
from datetime import datetime, timedelta
from pathlib import Path
import re

import redis.asyncio as redis
from croniter import croniter

logger = logging.getLogger(__name__)

# Configuration
FLAPPING_THRESHOLD = int(os.getenv("FLAPPING_THRESHOLD", "3"))
FLAPPING_WINDOW = int(os.getenv("FLAPPING_WINDOW", "600"))  # 10 minutes


class SuppressionEngine:
    """Engine for applying suppression rules to alerts."""
    
    def __init__(self, redis_client: redis.Redis):
        """Initialize suppression engine."""
        self.redis = redis_client
        self.rules: List[Dict] = []
        self.flapping_threshold = FLAPPING_THRESHOLD
        self.flapping_window = timedelta(seconds=FLAPPING_WINDOW)
    
    async def load_rules_from_directory(self, rules_dir: str):
        """Load suppression rules from YAML files in directory."""
        rules_path = Path(rules_dir)
        
        if not rules_path.exists():
            logger.warning(f"Rules directory {rules_dir} does not exist, creating it")
            rules_path.mkdir(parents=True, exist_ok=True)
            
            # Create example rules
            await self._create_example_rules(rules_path)
            return
        
        for rule_file in rules_path.glob("*.yaml"):
            try:
                with open(rule_file, 'r') as f:
                    rule_data = yaml.safe_load(f)
                    
                    # Add file path for tracking
                    rule_data["file_path"] = str(rule_file)
                    
                    self.rules.append(rule_data)
                    logger.info(f"Loaded rule: {rule_data.get('name')} from {rule_file}")
            except Exception as e:
                logger.error(f"Failed to load rule from {rule_file}: {e}")
    
    async def _create_example_rules(self, rules_path: Path):
        """Create example suppression rules."""
        example_rules = [
            {
                "name": "Example Maintenance Window",
                "type": "maintenance_window",
                "enabled": False,
                "schedule": "0 2 * * 0",
                "duration": 7200,
                "services": ["example-service"],
                "suppress_severity": ["medium", "low"]
            },
            {
                "name": "Example Known Issue",
                "type": "known_issue",
                "enabled": False,
                "alert_pattern": "ExampleAlert",
                "services": ["example-service"],
                "ticket_url": "https://jira.example.com/ISSUE-123",
                "expires_at": "2025-12-31T23:59:59Z"
            }
        ]
        
        for i, rule in enumerate(example_rules):
            rule_file = rules_path / f"example-{i+1}.yaml"
            with open(rule_file, 'w') as f:
                yaml.dump(rule, f, default_flow_style=False)
            logger.info(f"Created example rule: {rule_file}")
    
    async def should_suppress(self, alert_group: Dict) -> Tuple[bool, Optional[str]]:
        """
        Check if alert group should be suppressed.
        
        Returns:
            (should_suppress: bool, reason: str)
        """
        # Check each rule type
        for rule in self.rules:
            if not rule.get("enabled", True):
                continue
            
            rule_type = rule.get("type")
            
            if rule_type == "maintenance_window":
                if await self._check_maintenance_window(alert_group, rule):
                    return True, f"maintenance_window: {rule['name']}"
            
            elif rule_type == "known_issue":
                if await self._check_known_issue(alert_group, rule):
                    return True, f"known_issue: {rule['name']}"
            
            elif rule_type == "flapping":
                if await self._check_flapping(alert_group, rule):
                    return True, f"flapping: {rule['name']}"
            
            elif rule_type == "cascade":
                if await self._check_cascade(alert_group, rule):
                    return True, f"cascade: {rule['name']}"
            
            elif rule_type == "time_based":
                if await self._check_time_based(alert_group, rule):
                    return True, f"time_based: {rule['name']}"
        
        return False, None
    
    async def _check_maintenance_window(self, alert_group: Dict, rule: Dict) -> bool:
        """Check if alert falls within maintenance window."""
        schedule = rule.get("schedule")
        duration = rule.get("duration", 3600)  # Default 1 hour
        
        if not schedule:
            return False
        
        # Check if we're in a maintenance window
        try:
            cron = croniter(schedule, datetime.now())
            last_run = cron.get_prev(datetime)
            
            window_end = last_run + timedelta(seconds=duration)
            
            if datetime.now() < window_end:
                # Check if alert matches services
                services = rule.get("services", [])
                suppress_severity = rule.get("suppress_severity", [])
                
                for alert in alert_group.get("alerts", []):
                    labels = alert.get("labels", {})
                    service = labels.get("service")
                    severity = labels.get("severity", "medium")
                    
                    if services and service not in services:
                        continue
                    
                    if suppress_severity and severity not in suppress_severity:
                        continue
                    
                    # If we get here, alert matches maintenance window
                    return True
        except Exception as e:
            logger.error(f"Error checking maintenance window: {e}")
        
        return False
    
    async def _check_known_issue(self, alert_group: Dict, rule: Dict) -> bool:
        """Check if alert matches a known issue."""
        alert_pattern = rule.get("alert_pattern")
        services = rule.get("services", [])
        expires_at = rule.get("expires_at")
        
        # Check if rule has expired
        if expires_at:
            try:
                expiry = datetime.fromisoformat(expires_at.replace('Z', '+00:00'))
                if datetime.now() > expiry:
                    return False
            except Exception as e:
                logger.error(f"Error parsing expires_at: {e}")
        
        # Check if any alert matches pattern
        for alert in alert_group.get("alerts", []):
            labels = alert.get("labels", {})
            alertname = labels.get("alertname", "")
            service = labels.get("service")
            
            # Check pattern match
            if alert_pattern:
                try:
                    if re.match(alert_pattern, alertname):
                        # Check service if specified
                        if not services or service in services:
                            return True
                except Exception as e:
                    logger.error(f"Error matching pattern: {e}")
        
        return False
    
    async def _check_flapping(self, alert_group: Dict, rule: Dict) -> bool:
        """Check if alert is flapping (firing repeatedly)."""
        threshold = rule.get("threshold", self.flapping_threshold)
        window = rule.get("window", FLAPPING_WINDOW)
        alert_pattern = rule.get("alert_pattern")
        
        grouping_key = alert_group.get("grouping_key")
        
        # Track alert occurrences
        occurrences_key = f"flapping:{grouping_key}"
        
        # Get recent occurrences
        now = datetime.now().timestamp()
        window_start = now - window
        
        # Remove old occurrences
        await self.redis.zremrangebyscore(occurrences_key, 0, window_start)
        
        # Add current occurrence
        await self.redis.zadd(occurrences_key, {str(now): now})
        await self.redis.expire(occurrences_key, window * 2)
        
        # Check if flapping
        count = await self.redis.zcard(occurrences_key)
        
        if count >= threshold:
            # Check if pattern matches if specified
            if alert_pattern:
                for alert in alert_group.get("alerts", []):
                    alertname = alert.get("labels", {}).get("alertname", "")
                    try:
                        if re.match(alert_pattern, alertname):
                            return True
                    except Exception:
                        pass
            else:
                return True
        
        return False
    
    async def _check_cascade(self, alert_group: Dict, rule: Dict) -> bool:
        """Check if alert is a cascade of a root cause alert."""
        root_cause_alert = rule.get("root_cause_alert")
        dependent_alerts = rule.get("dependent_alerts", [])
        suppress_duration = rule.get("suppress_duration", 1800)  # 30 min default
        
        if not root_cause_alert or not dependent_alerts:
            return False
        
        # Check if root cause alert is active
        root_cause_key = f"cascade:root_cause:{root_cause_alert}"
        root_cause_active = await self.redis.get(root_cause_key)
        
        # Check if any alert in group matches root cause
        for alert in alert_group.get("alerts", []):
            alertname = alert.get("labels", {}).get("alertname", "")
            
            if alertname == root_cause_alert:
                # Mark root cause as active
                await self.redis.setex(root_cause_key, suppress_duration, "active")
                return False  # Don't suppress root cause
        
        # If root cause is active, suppress dependent alerts
        if root_cause_active:
            for alert in alert_group.get("alerts", []):
                alertname = alert.get("labels", {}).get("alertname", "")
                
                if alertname in dependent_alerts:
                    return True
        
        return False
    
    async def _check_time_based(self, alert_group: Dict, rule: Dict) -> bool:
        """Check if alert should be suppressed based on time of day."""
        # Simple implementation: suppress non-critical alerts during off-hours
        suppress_hours = rule.get("suppress_hours", [])  # e.g., [0, 1, 2, 3, 4, 5, 6]
        suppress_days = rule.get("suppress_days", [])  # e.g., ["saturday", "sunday"]
        suppress_severity = rule.get("suppress_severity", ["low", "info"])
        
        now = datetime.now()
        
        # Check hour
        if suppress_hours and now.hour in suppress_hours:
            # Check severity
            for alert in alert_group.get("alerts", []):
                severity = alert.get("labels", {}).get("severity", "medium")
                if severity in suppress_severity:
                    return True
        
        # Check day
        if suppress_days:
            day_name = now.strftime("%A").lower()
            if day_name in [d.lower() for d in suppress_days]:
                for alert in alert_group.get("alerts", []):
                    severity = alert.get("labels", {}).get("severity", "medium")
                    if severity in suppress_severity:
                        return True
        
        return False
    
    async def add_rule(self, rule: Dict):
        """Add a new suppression rule."""
        self.rules.append(rule)
        logger.info(f"Added rule: {rule.get('name')}")
    
    async def update_rule(self, rule: Dict):
        """Update existing suppression rule."""
        rule_id = rule.get("id")
        
        for i, existing_rule in enumerate(self.rules):
            if existing_rule.get("id") == rule_id:
                self.rules[i] = rule
                logger.info(f"Updated rule: {rule.get('name')}")
                return
        
        # If not found, add as new
        await self.add_rule(rule)
    
    async def delete_rule(self, rule_id: str):
        """Delete suppression rule."""
        self.rules = [r for r in self.rules if r.get("id") != rule_id]
        logger.info(f"Deleted rule: {rule_id}")
