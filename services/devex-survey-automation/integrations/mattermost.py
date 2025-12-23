"""
Mattermost integration for survey distribution
"""
import logging
from typing import Optional, Dict, Any
import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class MattermostClient:
    """Mattermost API client for sending survey notifications"""
    
    def __init__(self):
        self.base_url = settings.mattermost_url
        self.token = settings.mattermost_token
        self.bot_user_id = settings.mattermost_bot_user_id
        self.headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json"
        }
    
    async def get_user_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Get Mattermost user by email"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/api/v4/users/email/{email}",
                    headers=self.headers,
                    timeout=10.0
                )
                if response.status_code == 200:
                    return response.json()
                else:
                    logger.warning(f"User not found in Mattermost: {email}")
                    return None
        except Exception as e:
            logger.error(f"Error fetching Mattermost user {email}: {e}")
            return None
    
    async def create_direct_channel(self, user_id: str) -> Optional[str]:
        """Create a direct message channel with a user"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/api/v4/channels/direct",
                    headers=self.headers,
                    json=[self.bot_user_id, user_id],
                    timeout=10.0
                )
                if response.status_code in [200, 201]:
                    channel = response.json()
                    return channel.get("id")
                else:
                    logger.error(f"Failed to create DM channel: {response.text}")
                    return None
        except Exception as e:
            logger.error(f"Error creating DM channel: {e}")
            return None
    
    async def send_pulse_survey(self, email: str, user_id: str, survey_url: str) -> bool:
        """Send weekly pulse survey via Mattermost DM"""
        try:
            # Get Mattermost user
            mm_user = await self.get_user_by_email(email)
            if not mm_user:
                logger.warning(f"Cannot send survey to {email}: user not found in Mattermost")
                return False
            
            mm_user_id = mm_user.get("id")
            
            # Create DM channel
            channel_id = await self.create_direct_channel(mm_user_id)
            if not channel_id:
                logger.error(f"Cannot send survey to {email}: failed to create DM channel")
                return False
            
            # Compose message
            message = self._compose_pulse_survey_message(survey_url)
            
            # Send message
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
                
                if response.status_code == 201:
                    logger.info(f"✅ Pulse survey sent to {email}")
                    return True
                else:
                    logger.error(f"Failed to send survey to {email}: {response.text}")
                    return False
        
        except Exception as e:
            logger.error(f"Error sending pulse survey to {email}: {e}")
            return False
    
    async def send_reminder(self, email: str, survey_url: str) -> bool:
        """Send reminder for incomplete survey"""
        try:
            # Get Mattermost user
            mm_user = await self.get_user_by_email(email)
            if not mm_user:
                return False
            
            mm_user_id = mm_user.get("id")
            
            # Create DM channel
            channel_id = await self.create_direct_channel(mm_user_id)
            if not channel_id:
                return False
            
            # Compose reminder message
            message = self._compose_reminder_message(survey_url)
            
            # Send message
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
                
                if response.status_code == 201:
                    logger.info(f"✅ Reminder sent to {email}")
                    return True
                else:
                    logger.error(f"Failed to send reminder to {email}: {response.text}")
                    return False
        
        except Exception as e:
            logger.error(f"Error sending reminder to {email}: {e}")
            return False
    
    def _compose_pulse_survey_message(self, survey_url: str) -> str:
        """Compose pulse survey message"""
        return f"""### 📊 Weekly DevEx Pulse Survey

Hi! It's time for your weekly check-in. This quick 2-minute survey helps us improve your developer experience.

**This week's questions:**
- How many days were you in flow state?
- What % of time did you spend on valuable work?
- How was your cognitive load?
- Did you experience any friction?

[**Take the survey**]({survey_url})

Your feedback directly shapes our platform improvements. Thank you! 🙏
"""
    
    def _compose_reminder_message(self, survey_url: str) -> str:
        """Compose reminder message"""
        return f"""### 📊 Reminder: Weekly DevEx Pulse Survey

Hi! Just a friendly reminder that your weekly pulse survey is still open.

It only takes 2 minutes and your feedback is valuable for improving the platform.

[**Complete the survey**]({survey_url})

Thanks! 🙏
"""


# Global client instance
mattermost_client = MattermostClient() if settings.mattermost_token else None
