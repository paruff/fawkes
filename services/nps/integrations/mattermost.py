"""
Mattermost integration for NPS survey distribution.

This module handles:
- Sending survey DMs to users
- Including survey links
- Tracking who received surveys
- Sending reminders after 1 week
- Preventing spam to users who already responded
"""
import os
import logging
from typing import List, Dict, Optional
from datetime import datetime, timedelta

import httpx
import asyncpg

logger = logging.getLogger(__name__)

# Configuration
MATTERMOST_URL = os.getenv("MATTERMOST_URL", "http://mattermost.fawkes.svc.cluster.local:8065")
MATTERMOST_TOKEN = os.getenv("MATTERMOST_TOKEN", "")
REMINDER_DAYS = int(os.getenv("REMINDER_DAYS", "7"))


class MattermostClient:
    """Client for Mattermost API integration."""
    
    def __init__(self, base_url: str = MATTERMOST_URL, token: str = MATTERMOST_TOKEN):
        """Initialize Mattermost client."""
        self.base_url = base_url.rstrip('/')
        self.token = token
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
    
    async def get_user_by_email(self, email: str) -> Optional[Dict]:
        """Get Mattermost user by email."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/api/v4/users/email/{email}",
                    headers=self.headers,
                    timeout=10.0
                )
                
                if response.status_code == 200:
                    return response.json()
                elif response.status_code == 404:
                    logger.warning(f"User not found in Mattermost: {email}")
                    return None
                else:
                    logger.error(f"Failed to get user by email: {response.status_code} - {response.text}")
                    return None
        except Exception as e:
            logger.error(f"Error getting user by email {email}: {e}")
            return None
    
    async def create_direct_channel(self, user_id: str, bot_user_id: str) -> Optional[str]:
        """Create a direct message channel between bot and user."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/api/v4/channels/direct",
                    headers=self.headers,
                    json=[bot_user_id, user_id],
                    timeout=10.0
                )
                
                if response.status_code in [200, 201]:
                    data = response.json()
                    return data.get("id")
                else:
                    logger.error(f"Failed to create direct channel: {response.status_code} - {response.text}")
                    return None
        except Exception as e:
            logger.error(f"Error creating direct channel: {e}")
            return None
    
    async def send_direct_message(self, channel_id: str, message: str) -> bool:
        """Send a direct message to a channel."""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/api/v4/posts",
                    headers=self.headers,
                    json={
                        "channel_id": channel_id,
                        "message": message
                    },
                    timeout=10.0
                )
                
                if response.status_code in [200, 201]:
                    logger.info(f"Message sent to channel {channel_id}")
                    return True
                else:
                    logger.error(f"Failed to send message: {response.status_code} - {response.text}")
                    return False
        except Exception as e:
            logger.error(f"Error sending direct message: {e}")
            return False
    
    async def send_survey_dm(
        self,
        user_email: str,
        survey_url: str,
        bot_user_id: str,
        is_reminder: bool = False
    ) -> bool:
        """Send survey DM to a user."""
        # Get user
        user = await self.get_user_by_email(user_email)
        if not user:
            logger.warning(f"Cannot send survey to {user_email}: user not found")
            return False
        
        user_id = user.get("id")
        
        # Create direct channel
        channel_id = await self.create_direct_channel(user_id, bot_user_id)
        if not channel_id:
            logger.error(f"Cannot send survey to {user_email}: failed to create channel")
            return False
        
        # Compose message
        if is_reminder:
            message = f"""
### :bell: Reminder: Fawkes Platform Survey

Hi {user.get('first_name', 'there')}! 👋

We noticed you haven't completed our quarterly platform survey yet. Your feedback is valuable to us!

**It only takes 2 minutes to complete.**

:link: **[Take the survey now]({survey_url})**

This survey helps us understand how we can improve Fawkes Platform to better serve you.

The survey link will expire in a few days.

Thank you for your time! 🙏
            """.strip()
        else:
            message = f"""
### :clipboard: Fawkes Platform Quarterly Survey

Hi {user.get('first_name', 'there')}! 👋

We'd love to hear your thoughts on Fawkes Platform! Your feedback helps us improve and deliver better experiences.

**Quick 2-minute survey:** How likely are you to recommend Fawkes to a colleague?

:link: **[Take the survey now]({survey_url})**

Your responses are anonymous and will be used to enhance the platform.

Thank you for being part of our community! 🎯

_Survey expires in 30 days_
            """.strip()
        
        # Send message
        success = await self.send_direct_message(channel_id, message)
        
        if success:
            logger.info(f"Survey {'reminder' if is_reminder else 'invitation'} sent to {user_email}")
        
        return success


async def send_surveys_to_users(
    db_pool: asyncpg.Pool,
    users: List[Dict[str, str]],
    base_survey_url: str,
    bot_user_id: str,
    campaign_id: Optional[int] = None
) -> Dict[str, int]:
    """
    Send surveys to a list of users.
    
    Args:
        db_pool: Database connection pool
        users: List of dicts with 'user_id' and 'email' keys
        base_survey_url: Base URL for survey (e.g., "https://nps.fawkes.local/survey")
        bot_user_id: Mattermost bot user ID
        campaign_id: Optional campaign ID for tracking
    
    Returns:
        Dict with 'sent' and 'failed' counts
    """
    client = MattermostClient()
    results = {"sent": 0, "failed": 0}
    
    async with db_pool.acquire() as conn:
        for user in users:
            user_id = user.get("user_id")
            email = user.get("email")
            
            if not user_id or not email:
                logger.warning(f"Skipping user with missing data: {user}")
                results["failed"] += 1
                continue
            
            # Check if user already has an active survey link
            existing = await conn.fetchrow("""
                SELECT * FROM survey_links
                WHERE user_id = $1 
                AND expires_at > CURRENT_TIMESTAMP
                AND responded = FALSE
                ORDER BY created_at DESC
                LIMIT 1
            """, user_id)
            
            if existing:
                # Check if user already responded
                if existing['responded']:
                    logger.info(f"User {user_id} already responded, skipping")
                    continue
                
                # Use existing token
                token = existing['token']
                logger.info(f"Reusing existing survey link for {user_id}")
            else:
                # Generate new survey link
                import secrets
                token = secrets.token_urlsafe(32)
                expires_at = datetime.now() + timedelta(days=30)
                
                await conn.execute("""
                    INSERT INTO survey_links (token, user_id, email, expires_at)
                    VALUES ($1, $2, $3, $4)
                """, token, user_id, email, expires_at)
            
            # Send survey via Mattermost
            survey_url = f"{base_survey_url}/{token}"
            success = await client.send_survey_dm(email, survey_url, bot_user_id)
            
            if success:
                results["sent"] += 1
            else:
                results["failed"] += 1
    
    logger.info(f"Survey distribution complete: {results['sent']} sent, {results['failed']} failed")
    return results


async def send_reminders(
    db_pool: asyncpg.Pool,
    base_survey_url: str,
    bot_user_id: str
) -> Dict[str, int]:
    """
    Send reminders to users who haven't responded after REMINDER_DAYS.
    
    Returns:
        Dict with 'sent' and 'skipped' counts
    """
    client = MattermostClient()
    results = {"sent": 0, "skipped": 0}
    
    reminder_threshold = datetime.now() - timedelta(days=REMINDER_DAYS)
    
    async with db_pool.acquire() as conn:
        # Find users who need reminders
        pending_links = await conn.fetch("""
            SELECT token, user_id, email, created_at
            FROM survey_links
            WHERE responded = FALSE
            AND reminder_sent = FALSE
            AND expires_at > CURRENT_TIMESTAMP
            AND created_at <= $1
        """, reminder_threshold)
        
        for link in pending_links:
            token = link['token']
            user_id = link['user_id']
            email = link['email']
            
            # Send reminder
            survey_url = f"{base_survey_url}/{token}"
            success = await client.send_survey_dm(email, survey_url, bot_user_id, is_reminder=True)
            
            if success:
                # Mark reminder as sent
                await conn.execute("""
                    UPDATE survey_links
                    SET reminder_sent = TRUE, updated_at = CURRENT_TIMESTAMP
                    WHERE token = $1
                """, token)
                results["sent"] += 1
                logger.info(f"Reminder sent to {user_id}")
            else:
                results["skipped"] += 1
    
    logger.info(f"Reminder distribution complete: {results['sent']} sent, {results['skipped']} skipped")
    return results
