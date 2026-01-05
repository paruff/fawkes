"""GCP Cloud Monitoring operations."""

import logging
from typing import Dict, Any, Optional
from datetime import datetime

from google.cloud import monitoring_v3
from google.api_core import exceptions as gcp_exceptions

from ...exceptions import CloudProviderError
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class MonitoringService:
    """GCP Cloud Monitoring service operations."""

    def __init__(self, project_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Monitoring service.

        Args:
            project_id: GCP project ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.project_id = project_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._client = None

    def _get_client(self):
        """Get or create Monitoring metric service client."""
        if self._client is None:
            self.rate_limiter.acquire()
            self._client = monitoring_v3.MetricServiceClient()
            logger.debug("Created Cloud Monitoring client")
        return self._client

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def get_metrics(
        self,
        metric_type: str,
        resource_type: str,
        resource_labels: Dict[str, str],
        start_time: datetime,
        end_time: datetime,
        region: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get metrics from Cloud Monitoring.

        Args:
            metric_type: Metric type (e.g., 'compute.googleapis.com/instance/cpu/utilization')
            resource_type: Resource type (e.g., 'gce_instance', 'gke_container')
            resource_labels: Resource labels to filter by
            start_time: Start time for metrics
            end_time: End time for metrics
            region: Optional region filter

        Returns:
            Dictionary containing metric data

        Raises:
            CloudProviderError: If metrics retrieval fails
        """
        logger.debug(f"Getting Cloud Monitoring metrics: {metric_type} for {resource_type}")

        try:
            client = self._get_client()
            project_name = f"projects/{self.project_id}"

            # Build filter
            filters = [f'metric.type = "{metric_type}"', f'resource.type = "{resource_type}"']

            # Add resource label filters
            for key, value in resource_labels.items():
                filters.append(f'resource.labels.{key} = "{value}"')

            # Add region filter if specified
            if region:
                filters.append(f'resource.labels.zone = starts_with("{region}")')

            filter_str = " AND ".join(filters)

            # Build time interval
            interval = monitoring_v3.TimeInterval()
            interval.start_time.FromDatetime(start_time)
            interval.end_time.FromDatetime(end_time)

            # List time series
            self.rate_limiter.acquire()
            results = client.list_time_series(
                request={
                    "name": project_name,
                    "filter": filter_str,
                    "interval": interval,
                    "view": monitoring_v3.ListTimeSeriesRequest.TimeSeriesView.FULL,
                }
            )

            # Parse results
            datapoints = []
            for result in results:
                for point in result.points:
                    datapoint = {
                        "timestamp": point.interval.end_time.ToDatetime().isoformat(),
                        "value": None,
                    }

                    # Extract value based on type
                    if point.value.HasField("double_value"):
                        datapoint["value"] = point.value.double_value
                    elif point.value.HasField("int64_value"):
                        datapoint["value"] = point.value.int64_value
                    elif point.value.HasField("bool_value"):
                        datapoint["value"] = point.value.bool_value
                    elif point.value.HasField("string_value"):
                        datapoint["value"] = point.value.string_value

                    datapoints.append(datapoint)

            logger.info(f"Retrieved {len(datapoints)} metric datapoints")

            return {
                "metric_type": metric_type,
                "resource_type": resource_type,
                "datapoints": datapoints,
                "project_id": self.project_id,
            }

        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to get metrics {metric_type}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
        except Exception as e:
            raise CloudProviderError(f"Failed to get metrics {metric_type}: {str(e)}", provider="gcp")
