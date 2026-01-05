"""AWS Cost Explorer operations."""
import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta

import boto3
from botocore.exceptions import ClientError

from ...interfaces.models import CostData
from ...exceptions import CloudProviderError, ValidationError
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class CostExplorerService:
    """AWS Cost Explorer service operations."""

    # Timeframe mappings
    TIMEFRAME_MAP = {
        "LAST_7_DAYS": 7,
        "LAST_30_DAYS": 30,
        "LAST_90_DAYS": 90,
        "THIS_MONTH": "THIS_MONTH",
        "LAST_MONTH": "LAST_MONTH",
    }

    def __init__(self, session: boto3.Session, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Cost Explorer service.

        Args:
            session: Boto3 session
            rate_limiter: Optional rate limiter for API calls
        """
        self.session = session
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=5, time_window=1.0)  # Lower rate for Cost Explorer
        self._client = None

    def _get_client(self):
        """Get or create Cost Explorer client."""
        if not self._client:
            self.rate_limiter.acquire()
            # Cost Explorer is only available in us-east-1
            self._client = self.session.client("ce", region_name="us-east-1")
            logger.debug("Created Cost Explorer client")
        return self._client

    def _calculate_time_period(self, timeframe: str) -> Dict[str, str]:
        """
        Calculate start and end dates for timeframe.

        Args:
            timeframe: Timeframe string

        Returns:
            Dictionary with 'Start' and 'End' dates in YYYY-MM-DD format
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
                raise ValidationError(f"Unsupported timeframe: {timeframe}")
        else:
            raise ValidationError(f"Invalid timeframe: {timeframe}. Valid options: {list(self.TIMEFRAME_MAP.keys())}")

        return {"Start": start_date.strftime("%Y-%m-%d"), "End": end_date.strftime("%Y-%m-%d")}

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def get_cost_data(self, timeframe: str, granularity: str = "MONTHLY") -> CostData:
        """
        Get cost data for a specified timeframe.

        Args:
            timeframe: Time period (e.g., 'LAST_7_DAYS', 'LAST_30_DAYS', 'THIS_MONTH')
            granularity: Data granularity ('DAILY', 'MONTHLY', 'HOURLY')

        Returns:
            CostData object with cost information

        Raises:
            CloudProviderError: If cost data retrieval fails
        """
        logger.info(f"Getting cost data for timeframe: {timeframe}, granularity: {granularity}")

        try:
            client = self._get_client()

            # Calculate time period
            time_period = self._calculate_time_period(timeframe)

            # Validate granularity
            valid_granularities = ["DAILY", "MONTHLY", "HOURLY"]
            if granularity not in valid_granularities:
                raise ValidationError(
                    f"Invalid granularity: {granularity}. Valid options: {', '.join(valid_granularities)}"
                )

            # Get cost and usage
            self.rate_limiter.acquire()
            response = client.get_cost_and_usage(
                TimePeriod=time_period,
                Granularity=granularity,
                Metrics=["UnblendedCost", "UsageQuantity"],
                GroupBy=[{"Type": "DIMENSION", "Key": "SERVICE"}],
            )

            # Process results
            total_cost = 0.0
            breakdown = {}

            for result in response.get("ResultsByTime", []):
                for group in result.get("Groups", []):
                    service = group["Keys"][0]
                    cost = float(group["Metrics"]["UnblendedCost"]["Amount"])
                    total_cost += cost

                    if service in breakdown:
                        breakdown[service] += cost
                    else:
                        breakdown[service] = cost

            # Parse dates
            start_date = datetime.strptime(time_period["Start"], "%Y-%m-%d")
            end_date = datetime.strptime(time_period["End"], "%Y-%m-%d")

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
                    "result_count": len(response.get("ResultsByTime", [])),
                },
            )

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "InvalidNextToken":
                raise ValidationError(f"Invalid parameters: {error_msg}", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to get cost data: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
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
        logger.info(f"Getting cost forecast for {days} days")

        try:
            client = self._get_client()

            today = datetime.utcnow().date()
            start_date = today + timedelta(days=1)  # Forecast starts tomorrow
            end_date = today + timedelta(days=days)

            time_period = {
                "Start": start_date.strftime("%Y-%m-%d"),
                "End": end_date.strftime("%Y-%m-%d"),
            }

            self.rate_limiter.acquire()
            response = client.get_cost_forecast(
                TimePeriod=time_period, Metric="UNBLENDED_COST", Granularity="MONTHLY"
            )

            total_forecast = float(response.get("Total", {}).get("Amount", 0))

            logger.info(f"✅ Retrieved cost forecast: ${total_forecast:.2f} for next {days} days")

            return {
                "forecast_amount": total_forecast,
                "currency": "USD",
                "start_date": start_date,
                "end_date": end_date,
                "confidence_level": response.get("ForecastResultsByTime", [{}])[0].get("MeanValue"),
            }

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise CloudProviderError(
                f"Failed to get cost forecast: {error_msg}", provider="aws", error_code=error_code
            )
