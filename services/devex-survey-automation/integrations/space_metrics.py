"""
Integration with Space Metrics service for pulse survey data
"""
import logging
from typing import Dict, Any
import httpx

from app.config import settings

logger = logging.getLogger(__name__)


class SpaceMetricsClient:
    """Client for submitting pulse survey data to space-metrics service"""
    
    def __init__(self):
        self.base_url = settings.space_metrics_url
    
    async def submit_pulse_survey(self, data: Dict[str, Any]) -> bool:
        """Submit pulse survey response to space-metrics service"""
        try:
            payload = {
                "valuable_work_percentage": data.get("valuable_work_pct"),
                "flow_state_days": data.get("flow_state_days"),
                "cognitive_load": data.get("cognitive_load"),
                "friction_experienced": data.get("friction_incidents", False)
            }
            
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/api/v1/surveys/pulse/submit",
                    json=payload,
                    timeout=10.0
                )
                
                if response.status_code in [200, 201]:
                    logger.info("✅ Pulse survey data submitted to space-metrics")
                    return True
                else:
                    logger.error(f"Failed to submit to space-metrics: {response.status_code} - {response.text}")
                    return False
        
        except Exception as e:
            logger.error(f"Error submitting to space-metrics: {e}")
            return False
    
    async def check_health(self) -> bool:
        """Check if space-metrics service is healthy"""
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"{self.base_url}/health",
                    timeout=5.0
                )
                return response.status_code == 200
        except Exception as e:
            logger.error(f"Space-metrics health check failed: {e}")
            return False


# Global client instance
space_metrics_client = SpaceMetricsClient()
