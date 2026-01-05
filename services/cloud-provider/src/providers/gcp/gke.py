"""GCP GKE (Google Kubernetes Engine) operations."""

import logging
from typing import List, Optional

from google.cloud import container_v1
from google.api_core import exceptions as gcp_exceptions
from google.api_core import retry

from ...interfaces.models import Cluster
from ...interfaces.provider import ClusterConfig
from ...exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
    ValidationError,
)
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class GKEService:
    """GCP GKE service operations."""

    def __init__(self, project_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize GKE service.

        Args:
            project_id: GCP project ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.project_id = project_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._client = None

    def _get_client(self):
        """Get or create GKE client."""
        if self._client is None:
            self.rate_limiter.acquire()
            self._client = container_v1.ClusterManagerClient()
            logger.debug("Created GKE client")
        return self._client

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """
        Create a GKE cluster.

        Args:
            config: Cluster configuration

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster creation fails
        """
        logger.info(f"Creating GKE cluster: {config.name} in region {config.region}")

        try:
            client = self._get_client()

            # Build cluster creation request
            cluster = container_v1.Cluster()
            cluster.name = config.name
            cluster.initial_cluster_version = config.version
            cluster.initial_node_count = config.node_count

            # Configure node pool
            node_config = container_v1.NodeConfig()
            node_config.machine_type = config.node_instance_type
            
            # Add node pool
            node_pool = container_v1.NodePool()
            node_pool.name = "default-pool"
            node_pool.initial_node_count = config.node_count
            node_pool.config = node_config
            cluster.node_pools = [node_pool]

            # Add VPC configuration if provided
            if config.subnet_ids:
                cluster.subnetwork = config.subnet_ids[0] if config.subnet_ids else None

            # Add labels (GCP equivalent of tags)
            if config.tags:
                cluster.resource_labels = config.tags

            # Add Workload Identity if specified in metadata
            if config.metadata.get("enable_workload_identity", False):
                cluster.workload_identity_config = container_v1.WorkloadIdentityConfig()
                cluster.workload_identity_config.workload_pool = f"{self.project_id}.svc.id.goog"

            # Build parent path
            parent = f"projects/{self.project_id}/locations/{config.region}"

            # Create cluster
            self.rate_limiter.acquire()
            operation = client.create_cluster(parent=parent, cluster=cluster)

            logger.info(f"✅ Initiated GKE cluster creation: {config.name} (operation: {operation.name})")

            return Cluster(
                id=config.name,
                name=config.name,
                status="PROVISIONING",
                version=config.version,
                region=config.region,
                node_count=config.node_count,
                metadata={
                    "project_id": self.project_id,
                    "operation_name": operation.name,
                    "location": config.region,
                },
            )

        except gcp_exceptions.AlreadyExists as e:
            raise ResourceAlreadyExistsError(f"Cluster {config.name} already exists", provider="gcp")
        except gcp_exceptions.InvalidArgument as e:
            raise ValidationError(f"Invalid parameter: {str(e)}", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to create GKE cluster {config.name}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def get_cluster(self, cluster_name: str, region: str, include_node_count: bool = True) -> Cluster:
        """
        Get GKE cluster details.

        Args:
            cluster_name: Cluster name
            region: GCP region/zone
            include_node_count: Whether to include node count

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster retrieval fails
        """
        logger.debug(f"Getting GKE cluster: {cluster_name} in region {region}")

        try:
            client = self._get_client()
            name = f"projects/{self.project_id}/locations/{region}/clusters/{cluster_name}"

            self.rate_limiter.acquire()
            cluster = client.get_cluster(name=name)

            # Count nodes across all node pools
            node_count = 0
            if include_node_count:
                for node_pool in cluster.node_pools:
                    node_count += node_pool.initial_node_count

            return Cluster(
                id=cluster.name,
                name=cluster.name,
                status=cluster.status.name,
                version=cluster.current_master_version,
                endpoint=cluster.endpoint,
                region=region,
                node_count=node_count,
                metadata={
                    "project_id": self.project_id,
                    "location": cluster.location,
                    "self_link": cluster.self_link,
                    "current_node_version": cluster.current_node_version,
                    "workload_identity_enabled": bool(cluster.workload_identity_config),
                },
            )

        except gcp_exceptions.NotFound:
            raise ResourceNotFoundError(f"Cluster {cluster_name} not found", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to get GKE cluster {cluster_name}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def delete_cluster(self, cluster_name: str, region: str) -> bool:
        """
        Delete a GKE cluster.

        Args:
            cluster_name: Cluster name
            region: GCP region/zone

        Returns:
            True if deletion was initiated

        Raises:
            CloudProviderError: If cluster deletion fails
        """
        logger.info(f"Deleting GKE cluster: {cluster_name} in region {region}")

        try:
            client = self._get_client()
            name = f"projects/{self.project_id}/locations/{region}/clusters/{cluster_name}"

            self.rate_limiter.acquire()
            operation = client.delete_cluster(name=name)

            logger.info(f"✅ Initiated GKE cluster deletion: {cluster_name} (operation: {operation.name})")
            return True

        except gcp_exceptions.NotFound:
            raise ResourceNotFoundError(f"Cluster {cluster_name} not found", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to delete GKE cluster {cluster_name}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def list_clusters(self, region: str, include_details: bool = False) -> List[Cluster]:
        """
        List all GKE clusters in a region.

        Args:
            region: GCP region/zone or "-" for all regions
            include_details: Whether to fetch detailed info for each cluster (slower)

        Returns:
            List of Cluster objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing GKE clusters in region {region}")

        try:
            client = self._get_client()
            parent = f"projects/{self.project_id}/locations/{region}"

            clusters = []

            self.rate_limiter.acquire()
            response = client.list_clusters(parent=parent)

            for cluster in response.clusters:
                if include_details:
                    # Return detailed cluster info
                    node_count = sum(node_pool.initial_node_count for node_pool in cluster.node_pools)
                    clusters.append(
                        Cluster(
                            id=cluster.name,
                            name=cluster.name,
                            status=cluster.status.name,
                            version=cluster.current_master_version,
                            endpoint=cluster.endpoint,
                            region=region,
                            node_count=node_count,
                            metadata={
                                "project_id": self.project_id,
                                "location": cluster.location,
                                "self_link": cluster.self_link,
                            },
                        )
                    )
                else:
                    # Return minimal cluster info
                    clusters.append(
                        Cluster(
                            id=cluster.name,
                            name=cluster.name,
                            status="UNKNOWN",
                            version="UNKNOWN",
                            region=region,
                        )
                    )

            logger.info(f"Found {len(clusters)} GKE clusters in region {region}")
            return clusters

        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to list GKE clusters in {region}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
