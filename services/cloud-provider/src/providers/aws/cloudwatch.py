"""AWS CloudWatch operations."""
import logging
from typing import Dict, Any, Optional
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

from ...exceptions import CloudProviderError, ValidationError
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class CloudWatchService:
    """AWS CloudWatch service operations."""

    def __init__(self, session: boto3.Session, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize CloudWatch service.

        Args:
            session: Boto3 session
            rate_limiter: Optional rate limiter for API calls
        """
        self.session = session
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._clients = {}

    def _get_client(self, region: str):
        """Get or create CloudWatch client for region."""
        if region not in self._clients:
            self.rate_limiter.acquire()
            self._clients[region] = self.session.client("cloudwatch", region_name=region)
            logger.debug(f"Created CloudWatch client for region: {region}")
        return self._clients[region]

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def get_metrics(
        self, namespace: str, metric_name: str, dimensions: list, start_time: datetime, end_time: datetime, region: str
    ) -> Dict[str, Any]:
        """
        Get CloudWatch metrics.

        Args:
            namespace: Metric namespace (e.g., 'AWS/EKS', 'AWS/RDS')
            metric_name: Name of the metric
            dimensions: List of dimension dicts [{'Name': 'ClusterName', 'Value': 'my-cluster'}]
            start_time: Start time for metrics
            end_time: End time for metrics
            region: AWS region

        Returns:
            Dictionary containing metric data

        Raises:
            CloudProviderError: If metrics retrieval fails
        """
        logger.debug(f"Getting CloudWatch metrics: {metric_name} from {namespace}")

        try:
            client = self._get_client(region)

            # Calculate period (5 minutes in seconds)
            period = 300

            self.rate_limiter.acquire()
            response = client.get_metric_statistics(
                Namespace=namespace,
                MetricName=metric_name,
                Dimensions=dimensions,
                StartTime=start_time,
                EndTime=end_time,
                Period=period,
                Statistics=["Average", "Minimum", "Maximum", "Sum", "SampleCount"],
            )

            datapoints = response.get("Datapoints", [])
            # Sort by timestamp
            datapoints.sort(key=lambda x: x["Timestamp"])

            logger.debug(f"Retrieved {len(datapoints)} datapoints for metric {metric_name}")

            return {
                "metric_name": metric_name,
                "namespace": namespace,
                "dimensions": dimensions,
                "datapoints": datapoints,
                "label": response.get("Label"),
            }

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "InvalidParameterValue":
                raise ValidationError(f"Invalid metric parameter: {error_msg}", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to get CloudWatch metrics: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def list_metrics(self, namespace: Optional[str] = None, region: str = "us-east-1") -> list:
        """
        List available CloudWatch metrics.

        Args:
            namespace: Optional namespace filter
            region: AWS region

        Returns:
            List of metric information

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing CloudWatch metrics for namespace: {namespace}")

        try:
            client = self._get_client(region)

            list_params = {}
            if namespace:
                list_params["Namespace"] = namespace

            self.rate_limiter.acquire()
            response = client.list_metrics(**list_params)

            metrics = response.get("Metrics", [])
            logger.info(f"Found {len(metrics)} CloudWatch metrics")

            return metrics

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise CloudProviderError(
                f"Failed to list CloudWatch metrics: {error_msg}", provider="aws", error_code=error_code
            )
