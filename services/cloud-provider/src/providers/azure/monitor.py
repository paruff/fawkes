"""Azure Monitor operations for metrics."""

import logging
from typing import Dict, Any, Optional, List
from datetime import datetime

from azure.mgmt.monitor import MonitorManagementClient
from azure.core.exceptions import HttpResponseError

from ...exceptions import CloudProviderError, ValidationError
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class AzureMonitorService:
    """Azure Monitor service operations."""

    def __init__(self, credential, subscription_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Azure Monitor service.

        Args:
            credential: Azure credential object
            subscription_id: Azure subscription ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.credential = credential
        self.subscription_id = subscription_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._clients = {}

    def _get_client(self, subscription_id: Optional[str] = None) -> MonitorManagementClient:
        """Get or create Monitor client."""
        sub_id = subscription_id or self.subscription_id
        if sub_id not in self._clients:
            self.rate_limiter.acquire()
            self._clients[sub_id] = MonitorManagementClient(self.credential, sub_id)
            logger.debug(f"Created Monitor client for subscription: {sub_id}")
        return self._clients[sub_id]

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def get_metrics(
        self,
        resource_id: str,
        metric_name: str,
        start_time: datetime,
        end_time: datetime,
        aggregation: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get Azure Monitor metrics for a resource.

        Args:
            resource_id: Full Azure resource ID
            metric_name: Metric name to retrieve (single metric)
            start_time: Start time for metrics
            end_time: End time for metrics
            aggregation: Aggregation type (Average, Total, Maximum, Minimum, Count)

        Returns:
            Dictionary containing metric data

        Raises:
            CloudProviderError: If metrics retrieval fails
        """
        logger.debug(f"Getting Azure Monitor metric: {metric_name} for resource {resource_id}")

        try:
            client = self._get_client()

            # Format timestamps for Azure API
            timespan = f"{start_time.isoformat()}/{end_time.isoformat()}"

            # Set default aggregation if not provided
            if not aggregation:
                aggregation = "Average"

            # Validate aggregation
            valid_aggregations = ["Average", "Total", "Maximum", "Minimum", "Count"]
            if aggregation not in valid_aggregations:
                raise ValidationError(
                    f"Invalid aggregation: {aggregation}. Valid options: {', '.join(valid_aggregations)}", provider="azure"
                )

            self.rate_limiter.acquire()
            metrics_data = client.metrics.list(
                resource_uri=resource_id,
                timespan=timespan,
                interval="PT5M",
                metricnames=metric_name,
                aggregation=aggregation,
            )

            results = []
            for metric in metrics_data.value:
                metric_result = {
                    "name": metric.name.value,
                    "unit": metric.unit,
                    "type": metric.type,
                    "timeseries": [],
                }

                for timeseries in metric.timeseries:
                    datapoints = []
                    for data in timeseries.data:
                        datapoint = {
                            "timestamp": data.time_stamp,
                            "average": data.average,
                            "minimum": data.minimum,
                            "maximum": data.maximum,
                            "total": data.total,
                            "count": data.count,
                        }
                        datapoints.append(datapoint)

                    metric_result["timeseries"].append(
                        {
                            "metadata": timeseries.metadatavalues if hasattr(timeseries, "metadatavalues") else [],
                            "datapoints": datapoints,
                        }
                    )

                results.append(metric_result)

            logger.debug(f"Retrieved {len(results)} metrics for resource {resource_id}")

            return {
                "resource_id": resource_id,
                "timespan": timespan,
                "interval": "PT5M",
                "metrics": results,
                "namespace": metrics_data.namespace if hasattr(metrics_data, "namespace") else None,
            }

        except HttpResponseError as e:
            error_code = e.error.code if hasattr(e, "error") else None
            if error_code == "InvalidParameterValue":
                raise ValidationError(f"Invalid metric parameter: {e}", provider="azure")
            raise CloudProviderError(
                f"Failed to get Azure Monitor metrics: {e}", provider="azure", error_code=error_code
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting metrics: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def list_metric_definitions(self, resource_id: str) -> List[Dict[str, Any]]:
        """
        List available metric definitions for a resource.

        Args:
            resource_id: Full Azure resource ID

        Returns:
            List of metric definition information

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing metric definitions for resource: {resource_id}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            metric_definitions = client.metric_definitions.list(resource_uri=resource_id)

            definitions = []
            for definition in metric_definitions:
                definitions.append(
                    {
                        "name": definition.name.value,
                        "unit": definition.unit,
                        "primary_aggregation_type": definition.primary_aggregation_type,
                        "supported_aggregation_types": definition.supported_aggregation_types,
                        "metric_availabilities": [
                            {"time_grain": avail.time_grain, "retention": avail.retention}
                            for avail in definition.metric_availabilities
                        ]
                        if definition.metric_availabilities
                        else [],
                        "namespace": definition.namespace if hasattr(definition, "namespace") else None,
                    }
                )

            logger.info(f"Found {len(definitions)} metric definitions for resource {resource_id}")
            return definitions

        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to list metric definitions: {e}",
                provider="azure",
                error_code=e.error.code if hasattr(e, "error") else None,
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error listing metric definitions: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def get_activity_logs(
        self,
        start_time: datetime,
        end_time: datetime,
        resource_group: Optional[str] = None,
        resource_id: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Get Azure Activity Logs.

        Args:
            start_time: Start time for logs
            end_time: End time for logs
            resource_group: Optional resource group filter
            resource_id: Optional specific resource ID filter

        Returns:
            List of activity log entries

        Raises:
            CloudProviderError: If retrieval fails
        """
        logger.debug("Getting Azure Activity Logs")

        try:
            client = self._get_client()

            # Build filter string
            filter_parts = [
                f"eventTimestamp ge '{start_time.isoformat()}Z'",
                f"eventTimestamp le '{end_time.isoformat()}Z'",
            ]

            if resource_group:
                filter_parts.append(f"resourceGroupName eq '{resource_group}'")

            if resource_id:
                filter_parts.append(f"resourceUri eq '{resource_id}'")

            filter_string = " and ".join(filter_parts)

            self.rate_limiter.acquire()
            activity_logs = client.activity_logs.list(filter=filter_string)

            logs = []
            for log in activity_logs:
                logs.append(
                    {
                        "event_timestamp": log.event_timestamp,
                        "operation_name": log.operation_name.value if log.operation_name else None,
                        "status": log.status.value if log.status else None,
                        "level": log.level,
                        "resource_id": log.resource_id,
                        "resource_group_name": log.resource_group_name,
                        "caller": log.caller,
                        "correlation_id": log.correlation_id,
                        "description": log.description,
                    }
                )

            logger.info(f"Retrieved {len(logs)} activity log entries")
            return logs

        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to get activity logs: {e}",
                provider="azure",
                error_code=e.error.code if hasattr(e, "error") else None,
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting activity logs: {e}", provider="azure")
