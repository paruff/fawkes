"""Azure Cost Management operations."""

import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta

from azure.mgmt.costmanagement import CostManagementClient
from azure.core.exceptions import HttpResponseError

from ...interfaces.models import CostData
from ...exceptions import CloudProviderError, ValidationError
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class AzureCostManagementService:
    """Azure Cost Management service operations."""

    TIMEFRAME_MAP = {
        "LAST_7_DAYS": 7,
        "LAST_30_DAYS": 30,
        "LAST_90_DAYS": 90,
        "THIS_MONTH": "THIS_MONTH",
        "LAST_MONTH": "LAST_MONTH",
    }

    def __init__(self, credential, subscription_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Azure Cost Management service.

        Args:
            credential: Azure credential object
            subscription_id: Azure subscription ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.credential = credential
        self.subscription_id = subscription_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=5, time_window=1.0)
        self._client = None

    def _get_client(self) -> CostManagementClient:
        """Get or create Cost Management client."""
        if not self._client:
            self.rate_limiter.acquire()
            self._client = CostManagementClient(self.credential)
            logger.debug("Created Cost Management client")
        return self._client

    def _calculate_time_period(self, timeframe: str) -> tuple:
        """
        Calculate start and end dates for timeframe.

        Args:
            timeframe: Timeframe string

        Returns:
            Tuple of (start_date, end_date) as datetime objects
        """
        today = datetime.utcnow().date()

        if timeframe == "THIS_MONTH":
            start_date = today.replace(day=1)
            end_date = today
        elif timeframe == "LAST_MONTH":
            first_of_this_month = today.replace(day=1)
            end_date = first_of_this_month - timedelta(days=1)
            start_date = end_date.replace(day=1)
        elif timeframe in self.TIMEFRAME_MAP:
            days = self.TIMEFRAME_MAP[timeframe]
            if isinstance(days, int):
                start_date = today - timedelta(days=days)
                end_date = today
            else:
                raise ValidationError(f"Unsupported timeframe: {timeframe}", provider="azure")
        else:
            raise ValidationError(
                f"Invalid timeframe: {timeframe}. Valid options: {list(self.TIMEFRAME_MAP.keys())}", provider="azure"
            )

        return (datetime.combine(start_date, datetime.min.time()), datetime.combine(end_date, datetime.max.time()))

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def get_cost_data(self, timeframe: str, granularity: str = "Daily") -> CostData:
        """
        Get cost data for a specified timeframe.

        Args:
            timeframe: Time period (e.g., 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH')
            granularity: Data granularity ('Daily' or 'Monthly')

        Returns:
            CostData object with cost information

        Raises:
            CloudProviderError: If cost data retrieval fails
        """
        logger.info(f"Getting Azure cost data for timeframe: {timeframe}, granularity: {granularity}")

        try:
            client = self._get_client()

            start_date, end_date = self._calculate_time_period(timeframe)

            valid_granularities = ["Daily", "Monthly"]
            if granularity not in valid_granularities:
                raise ValidationError(
                    f"Invalid granularity: {granularity}. Valid options: {', '.join(valid_granularities)}",
                    provider="azure",
                )

            scope = f"/subscriptions/{self.subscription_id}"

            query_definition = {
                "type": "ActualCost",
                "timeframe": "Custom",
                "time_period": {
                    "from": start_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    "to": end_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                },
                "dataset": {
                    "granularity": granularity,
                    "aggregation": {"totalCost": {"name": "Cost", "function": "Sum"}},
                    "grouping": [{"type": "Dimension", "name": "ServiceName"}],
                },
            }

            self.rate_limiter.acquire()
            result = client.query.usage(scope=scope, parameters=query_definition)

            total_cost = 0.0
            breakdown = {}

            if result.rows:
                for row in result.rows:
                    cost = float(row[0]) if row else 0.0
                    service_name = row[2] if len(row) > 2 else "Unknown"

                    total_cost += cost
                    if service_name in breakdown:
                        breakdown[service_name] += cost
                    else:
                        breakdown[service_name] = cost

            # Currency is typically USD for Azure Cost Management
            if hasattr(result, "columns") and result.columns:
                for col in result.columns:
                    if col.name == "Currency":
                        # Use currency column if available
                        break

            logger.info(f"✅ Retrieved cost data: ${total_cost:.2f} total")

            return CostData(
                start_date=start_date,
                end_date=end_date,
                total_cost=total_cost,
                currency="USD",
                breakdown=breakdown,
                metadata={
                    "granularity": granularity,
                    "timeframe": timeframe,
                    "result_count": len(result.rows) if result.rows else 0,
                },
            )

        except HttpResponseError as e:
            error_code = e.error.code if hasattr(e, "error") else None
            if error_code == "BadRequest":
                raise ValidationError(f"Invalid parameters: {e}", provider="azure")
            raise CloudProviderError(f"Failed to get cost data: {e}", provider="azure", error_code=error_code)
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting cost data: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def get_cost_forecast(self, days: int = 30) -> Dict[str, Any]:
        """
        Get cost forecast for specified number of days.

        Args:
            days: Number of days to forecast (default: 30)

        Returns:
            Dictionary containing forecast data

        Raises:
            CloudProviderError: If forecast retrieval fails
        """
        logger.info(f"Getting Azure cost forecast for {days} days")

        try:
            client = self._get_client()

            today = datetime.utcnow().date()
            start_date = today + timedelta(days=1)
            end_date = today + timedelta(days=days)

            scope = f"/subscriptions/{self.subscription_id}"

            query_definition = {
                "type": "ActualCost",
                "timeframe": "Custom",
                "time_period": {
                    "from": datetime.combine(start_date, datetime.min.time()).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    "to": datetime.combine(end_date, datetime.max.time()).strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                },
                "dataset": {
                    "granularity": "Daily",
                    "aggregation": {"totalCost": {"name": "Cost", "function": "Sum"}},
                },
                "include_actual_cost": False,
                "include_fresh_partial_cost": False,
            }

            self.rate_limiter.acquire()
            result = client.query.usage(scope=scope, parameters=query_definition)

            total_forecast = 0.0
            if result.rows:
                for row in result.rows:
                    cost = float(row[0]) if row else 0.0
                    total_forecast += cost

            logger.info(f"✅ Retrieved cost forecast: ${total_forecast:.2f} for next {days} days")

            return {
                "forecast_amount": total_forecast,
                "currency": "USD",
                "start_date": start_date,
                "end_date": end_date,
                "confidence_level": None,
            }

        except HttpResponseError as e:
            error_code = e.error.code if hasattr(e, "error") else None
            raise CloudProviderError(f"Failed to get cost forecast: {e}", provider="azure", error_code=error_code)
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting cost forecast: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def get_cost_by_resource_group(self, timeframe: str, resource_group: str) -> CostData:
        """
        Get cost data for a specific resource group.

        Args:
            timeframe: Time period (e.g., 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH')
            resource_group: Resource group name

        Returns:
            CostData object with cost information

        Raises:
            CloudProviderError: If cost data retrieval fails
        """
        logger.info(f"Getting cost data for resource group: {resource_group}, timeframe: {timeframe}")

        try:
            client = self._get_client()

            start_date, end_date = self._calculate_time_period(timeframe)

            scope = f"/subscriptions/{self.subscription_id}/resourceGroups/{resource_group}"

            query_definition = {
                "type": "ActualCost",
                "timeframe": "Custom",
                "time_period": {
                    "from": start_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                    "to": end_date.strftime("%Y-%m-%dT%H:%M:%S.000Z"),
                },
                "dataset": {
                    "granularity": "Daily",
                    "aggregation": {"totalCost": {"name": "Cost", "function": "Sum"}},
                    "grouping": [{"type": "Dimension", "name": "ResourceId"}],
                },
            }

            self.rate_limiter.acquire()
            result = client.query.usage(scope=scope, parameters=query_definition)

            total_cost = 0.0
            breakdown = {}

            if result.rows:
                for row in result.rows:
                    cost = float(row[0]) if row else 0.0
                    resource_id = row[2] if len(row) > 2 else "Unknown"

                    total_cost += cost
                    if resource_id in breakdown:
                        breakdown[resource_id] += cost
                    else:
                        breakdown[resource_id] = cost

            logger.info(f"✅ Retrieved cost data for resource group {resource_group}: ${total_cost:.2f} total")

            return CostData(
                start_date=start_date,
                end_date=end_date,
                total_cost=total_cost,
                currency="USD",
                breakdown=breakdown,
                metadata={
                    "resource_group": resource_group,
                    "timeframe": timeframe,
                },
            )

        except HttpResponseError as e:
            error_code = e.error.code if hasattr(e, "error") else None
            raise CloudProviderError(
                f"Failed to get cost data for resource group: {e}", provider="azure", error_code=error_code
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting cost data for resource group: {e}", provider="azure")
