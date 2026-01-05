"""GCP Cloud Billing operations."""

import logging
from typing import Optional
from datetime import datetime, timedelta

from google.cloud import billing_v1
from google.api_core import exceptions as gcp_exceptions

from ...interfaces.models import CostData
from ...exceptions import CloudProviderError
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class BillingService:
    """GCP Cloud Billing service operations."""

    def __init__(
        self, project_id: str, billing_account_id: Optional[str] = None, rate_limiter: Optional[RateLimiter] = None
    ):
        """
        Initialize Billing service.

        Args:
            project_id: GCP project ID
            billing_account_id: Optional billing account ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.project_id = project_id
        self.billing_account_id = billing_account_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._client = None

    def _get_client(self):
        """Get or create Cloud Billing client."""
        if self._client is None:
            self.rate_limiter.acquire()
            self._client = billing_v1.CloudBillingClient()
            logger.debug("Created Cloud Billing client")
        return self._client

    def _parse_timeframe(self, timeframe: str) -> tuple:
        """
        Parse timeframe string into start and end dates.

        Args:
            timeframe: Timeframe string (e.g., 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH')

        Returns:
            Tuple of (start_date, end_date)
        """
        end_date = datetime.now()

        if timeframe == "LAST_7_DAYS":
            start_date = end_date - timedelta(days=7)
        elif timeframe == "LAST_30_DAYS":
            start_date = end_date - timedelta(days=30)
        elif timeframe == "THIS_MONTH":
            start_date = end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        elif timeframe == "LAST_MONTH":
            # First day of last month
            first_of_this_month = end_date.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            start_date = (first_of_this_month - timedelta(days=1)).replace(day=1)
            end_date = first_of_this_month - timedelta(seconds=1)
        else:
            # Default to last 30 days
            start_date = end_date - timedelta(days=30)

        return start_date, end_date

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def get_cost_data(self, timeframe: str, granularity: str = "MONTHLY") -> CostData:
        """
        Get cost data for a specified timeframe.

        Note: GCP Cloud Billing API requires BigQuery export to be configured
        for detailed cost analysis. This implementation provides a simplified
        version using the Cloud Billing API.

        Args:
            timeframe: Time period (e.g., 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH')
            granularity: Data granularity ('DAILY', 'MONTHLY') - currently not fully supported

        Returns:
            CostData object with cost information

        Raises:
            CloudProviderError: If cost data retrieval fails
        """
        logger.debug(f"Getting Cloud Billing cost data for timeframe: {timeframe}")

        try:
            client = self._get_client()

            # Parse timeframe
            start_date, end_date = self._parse_timeframe(timeframe)

            # Get project billing info
            project_name = f"projects/{self.project_id}"

            self.rate_limiter.acquire()
            billing_info = client.get_project_billing_info(name=project_name)

            # Note: The Cloud Billing API doesn't provide historical cost data directly.
            # For detailed cost data, you would need to:
            # 1. Enable BigQuery billing export
            # 2. Query the exported billing data from BigQuery
            #
            # This is a simplified implementation that returns billing account information
            # In a real implementation, you would query BigQuery for actual costs.

            if not billing_info.billing_enabled:
                logger.warning(f"Billing is not enabled for project {self.project_id}")
                return CostData(
                    start_date=start_date,
                    end_date=end_date,
                    total_cost=0.0,
                    currency="USD",
                    breakdown={},
                    metadata={
                        "project_id": self.project_id,
                        "billing_enabled": False,
                        "note": "Billing export to BigQuery required for detailed cost data",
                    },
                )

            # For actual cost data, you would need to query BigQuery
            # Here we return a placeholder structure
            logger.info(
                f"Retrieved billing info for project {self.project_id}. "
                "Note: Configure BigQuery export for detailed cost data."
            )

            return CostData(
                start_date=start_date,
                end_date=end_date,
                total_cost=0.0,
                currency="USD",
                breakdown={},
                metadata={
                    "project_id": self.project_id,
                    "billing_account_name": billing_info.billing_account_name,
                    "billing_enabled": billing_info.billing_enabled,
                    "note": "Configure BigQuery billing export for detailed cost data",
                    "instructions": (
                        "Enable billing export: https://cloud.google.com/billing/docs/how-to/export-data-bigquery"
                    ),
                },
            )

        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to get billing data: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
        except Exception as e:
            raise CloudProviderError(f"Failed to get billing data: {str(e)}", provider="gcp")
