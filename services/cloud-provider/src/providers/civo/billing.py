"""Civo Billing operations.

Civo provides billing information through their API.
"""

import logging
from typing import Dict, Any
from datetime import datetime, timedelta

from civo import Civo

from ...interfaces.models import CostData
from ...exceptions import CloudProviderError
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class BillingService:
    """Civo Billing service operations."""

    def __init__(self, client: Civo, rate_limiter: RateLimiter = None):
        """
        Initialize Billing service.

        Args:
            client: Civo client instance
            rate_limiter: Optional rate limiter for API calls
        """
        self.client = client
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)

    def _parse_timeframe(self, timeframe: str) -> tuple:
        """
        Parse timeframe string to start and end dates.

        Args:
            timeframe: Timeframe string (e.g., 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH')

        Returns:
            Tuple of (start_date, end_date)
        """
        now = datetime.now()
        
        if timeframe == "LAST_7_DAYS":
            start_date = now - timedelta(days=7)
            end_date = now
        elif timeframe == "LAST_30_DAYS":
            start_date = now - timedelta(days=30)
            end_date = now
        elif timeframe == "THIS_MONTH":
            start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = now
        elif timeframe == "LAST_MONTH":
            # First day of last month
            first_day_this_month = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            end_date = first_day_this_month - timedelta(days=1)
            start_date = end_date.replace(day=1)
        else:
            # Default to last 30 days
            start_date = now - timedelta(days=30)
            end_date = now
            
        return start_date, end_date

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def get_cost_data(self, timeframe: str, granularity: str = "MONTHLY") -> CostData:
        """
        Get cost data for a specified timeframe.

        Args:
            timeframe: Time period (e.g., 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH')
            granularity: Data granularity ('DAILY', 'MONTHLY')

        Returns:
            CostData object with cost information

        Raises:
            CloudProviderError: If cost data retrieval fails
        """
        logger.info(f"Getting Civo cost data for timeframe: {timeframe}")

        try:
            start_date, end_date = self._parse_timeframe(timeframe)
            
            self.rate_limiter.acquire()
            
            # Get account quota which includes current usage/costs
            # Note: Civo API doesn't have a dedicated cost explorer like AWS
            # This is a simplified implementation
            quota = self.client.quota.get()
            
            # Calculate estimated costs based on current usage
            # This is approximate - in production you'd want to:
            # 1. Track actual invoices
            # 2. Query billing history if available
            # 3. Calculate based on resource usage and pricing
            
            # Get current resources to estimate costs
            try:
                clusters = self.client.kubernetes.list()
                instances = self.client.instances.list() if hasattr(self.client, 'instances') else []
                object_stores = self.client.objectstore.list()
            except Exception as e:
                logger.warning(f"Could not list resources for cost estimation: {e}")
                clusters = []
                instances = []
                object_stores = []
            
            # Rough cost estimation (Civo pricing as of implementation)
            # These are example prices and should be updated based on actual Civo pricing
            cluster_cost = len(clusters) * 5.0  # ~$5/month per small cluster (very approximate)
            instance_cost = len(instances) * 5.0  # ~$5/month per small instance
            storage_cost = len(object_stores) * 5.0  # ~$5/month per store
            
            total_cost = cluster_cost + instance_cost + storage_cost
            
            breakdown = {
                "kubernetes_clusters": cluster_cost,
                "instances": instance_cost,
                "object_storage": storage_cost,
            }
            
            logger.info(
                f"✅ Retrieved Civo cost data: ${total_cost:.2f} "
                f"(Note: This is an estimate based on current resources)"
            )
            
            return CostData(
                start_date=start_date,
                end_date=end_date,
                total_cost=total_cost,
                currency="USD",
                breakdown=breakdown,
                metadata={
                    "provider": "civo",
                    "estimation_note": "Costs are estimated based on current resources. "
                                      "For accurate billing, check Civo console.",
                    "quota": quota,
                },
            )

        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(
                f"Failed to get cost data: {error_msg}",
                provider="civo"
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def get_quota(self) -> Dict[str, Any]:
        """
        Get account quota information.

        Returns:
            Dictionary containing quota information

        Raises:
            CloudProviderError: If quota retrieval fails
        """
        logger.info("Getting Civo account quota")

        try:
            self.rate_limiter.acquire()
            quota = self.client.quota.get()
            
            logger.info(f"✅ Retrieved Civo quota information")
            return quota

        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(
                f"Failed to get quota: {error_msg}",
                provider="civo"
            )
