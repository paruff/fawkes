"""Civo Kubernetes (K3s) operations."""

import logging
from typing import List, Optional
from datetime import datetime

from civo import Civo

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


class KubernetesService:
    """Civo Kubernetes service operations."""

    def __init__(self, client: Civo, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Kubernetes service.

        Args:
            client: Civo client instance
            rate_limiter: Optional rate limiter for API calls
        """
        self.client = client
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """
        Create a Civo Kubernetes cluster.

        Args:
            config: Cluster configuration

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster creation fails
        """
        logger.info(f"Creating Civo K3s cluster: {config.name} in region {config.region}")

        try:
            self.rate_limiter.acquire()

            # Build cluster creation parameters
            # Civo uses simpler parameters than AWS/GCP
            create_params = {
                "name": config.name,
                "num_target_nodes": config.node_count,
                "target_nodes_size": config.node_instance_type or "g4s.kube.medium",
                "kubernetes_version": config.version,
                "region": config.region,
            }

            # Add optional network ID if provided
            if config.vpc_id:
                create_params["network_id"] = config.vpc_id

            # Add applications to install if provided in metadata
            if config.metadata.get("applications"):
                create_params["applications"] = config.metadata["applications"]

            # Add CNI plugin if specified
            if config.metadata.get("cni_plugin"):
                create_params["cni_plugin"] = config.metadata["cni_plugin"]

            # Create the cluster
            result = self.client.kubernetes.create(**create_params)

            logger.info(f"✅ Initiated Civo K3s cluster creation: {config.name} (id: {result['id']})")

            return Cluster(
                id=result["id"],
                name=result["name"],
                status=result.get("status", "creating"),
                version=result.get("kubernetes_version", config.version),
                endpoint=result.get("api_endpoint"),
                region=config.region,
                node_count=config.node_count,
                created_at=datetime.fromisoformat(result["created_at"]) if result.get("created_at") else None,
                metadata={
                    "dns_entry": result.get("dns_entry"),
                    "built_at": result.get("built_at"),
                    "kubeconfig": result.get("kubeconfig"),
                    "civo_cluster_id": result["id"],
                },
            )

        except Exception as e:
            error_msg = str(e)
            
            # Check for specific error types
            if "already exists" in error_msg.lower():
                raise ResourceAlreadyExistsError(
                    f"Cluster {config.name} already exists", provider="civo"
                )
            elif "invalid" in error_msg.lower() or "validation" in error_msg.lower():
                raise ValidationError(f"Invalid cluster configuration: {error_msg}", provider="civo")
            else:
                raise CloudProviderError(f"Failed to create cluster {config.name}: {error_msg}", provider="civo")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def get_cluster(self, cluster_id: str, region: Optional[str] = None) -> Cluster:
        """
        Get cluster details.

        Args:
            cluster_id: Cluster ID or name
            region: Region (not used in Civo, kept for interface compatibility)

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster not found or error occurs
        """
        logger.info(f"Getting Civo cluster details: {cluster_id}")

        try:
            self.rate_limiter.acquire()
            result = self.client.kubernetes.get(cluster_id)

            return Cluster(
                id=result["id"],
                name=result["name"],
                status=result.get("status", "unknown"),
                version=result.get("kubernetes_version", ""),
                endpoint=result.get("api_endpoint"),
                region=result.get("region", ""),
                node_count=result.get("num_target_nodes", 0),
                created_at=datetime.fromisoformat(result["created_at"]) if result.get("created_at") else None,
                metadata={
                    "dns_entry": result.get("dns_entry"),
                    "built_at": result.get("built_at"),
                    "kubeconfig": result.get("kubeconfig"),
                    "installed_applications": result.get("installed_applications", []),
                    "civo_cluster_id": result["id"],
                },
            )

        except Exception as e:
            error_msg = str(e)
            if "not found" in error_msg.lower() or "404" in error_msg:
                raise ResourceNotFoundError(f"Cluster {cluster_id} not found", provider="civo")
            else:
                raise CloudProviderError(f"Failed to get cluster {cluster_id}: {error_msg}", provider="civo")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def delete_cluster(self, cluster_id: str, region: Optional[str] = None) -> bool:
        """
        Delete a cluster.

        Args:
            cluster_id: Cluster ID
            region: Region (not used in Civo, kept for interface compatibility)

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        logger.info(f"Deleting Civo cluster: {cluster_id}")

        try:
            self.rate_limiter.acquire()
            self.client.kubernetes.delete(cluster_id)
            logger.info(f"✅ Successfully deleted cluster: {cluster_id}")
            return True

        except Exception as e:
            error_msg = str(e)
            if "not found" in error_msg.lower() or "404" in error_msg:
                raise ResourceNotFoundError(f"Cluster {cluster_id} not found", provider="civo")
            else:
                raise CloudProviderError(f"Failed to delete cluster {cluster_id}: {error_msg}", provider="civo")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def list_clusters(self, region: Optional[str] = None) -> List[Cluster]:
        """
        List all clusters.

        Args:
            region: Optional region filter (not commonly used in Civo)

        Returns:
            List of Cluster objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.info("Listing all Civo clusters")

        try:
            self.rate_limiter.acquire()
            results = self.client.kubernetes.list()

            clusters = []
            for result in results:
                # Filter by region if specified
                if region and result.get("region") != region:
                    continue

                cluster = Cluster(
                    id=result["id"],
                    name=result["name"],
                    status=result.get("status", "unknown"),
                    version=result.get("kubernetes_version", ""),
                    endpoint=result.get("api_endpoint"),
                    region=result.get("region", ""),
                    node_count=result.get("num_target_nodes", 0),
                    created_at=datetime.fromisoformat(result["created_at"]) if result.get("created_at") else None,
                    metadata={
                        "dns_entry": result.get("dns_entry"),
                        "civo_cluster_id": result["id"],
                    },
                )
                clusters.append(cluster)

            logger.info(f"Found {len(clusters)} Civo clusters")
            return clusters

        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(f"Failed to list clusters: {error_msg}", provider="civo")
