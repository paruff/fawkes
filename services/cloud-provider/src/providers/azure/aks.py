"""Azure AKS (Azure Kubernetes Service) operations."""

import logging
from typing import List, Optional

from azure.mgmt.containerservice import ContainerServiceClient
from azure.core.exceptions import (
    ResourceNotFoundError as AzureResourceNotFoundError,
    HttpResponseError,
)

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


class AKSService:
    """Azure AKS service operations."""

    def __init__(self, credential, subscription_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize AKS service.

        Args:
            credential: Azure credential object
            subscription_id: Azure subscription ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.credential = credential
        self.subscription_id = subscription_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._clients = {}

    def _get_client(self, subscription_id: Optional[str] = None) -> ContainerServiceClient:
        """Get or create AKS client for subscription."""
        sub_id = subscription_id or self.subscription_id
        if sub_id not in self._clients:
            self.rate_limiter.acquire()
            self._clients[sub_id] = ContainerServiceClient(self.credential, sub_id)
            logger.debug(f"Created AKS client for subscription: {sub_id}")
        return self._clients[sub_id]

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(HttpResponseError,),
    )
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """
        Create an AKS cluster.

        Args:
            config: Cluster configuration

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster creation fails
        """
        logger.info(f"Creating AKS cluster: {config.name} in region {config.region}")

        try:
            client = self._get_client()
            resource_group = config.metadata.get("resource_group")
            
            if not resource_group:
                raise ValidationError("resource_group must be provided in metadata", provider="azure")

            # Build cluster creation parameters
            managed_cluster_params = {
                "location": config.region,
                "tags": config.tags,
                "dns_prefix": config.metadata.get("dns_prefix", f"{config.name}-dns"),
                "kubernetes_version": config.version,
                "agent_pool_profiles": [
                    {
                        "name": "nodepool1",
                        "count": config.node_count,
                        "vm_size": config.node_instance_type,
                        "mode": "System",
                        "type": "VirtualMachineScaleSets",
                        "vnet_subnet_id": config.subnet_ids[0] if config.subnet_ids else None,
                    }
                ],
                "service_principal_profile": config.metadata.get("service_principal_profile"),
                "identity": config.metadata.get("identity", {"type": "SystemAssigned"}),
                "network_profile": {
                    "network_plugin": config.metadata.get("network_plugin", "kubenet"),
                    "load_balancer_sku": "standard",
                },
            }

            # Add optional parameters
            if config.metadata.get("enable_rbac") is not None:
                managed_cluster_params["enable_rbac"] = config.metadata["enable_rbac"]

            if config.metadata.get("addon_profiles"):
                managed_cluster_params["addon_profiles"] = config.metadata["addon_profiles"]

            self.rate_limiter.acquire()
            poller = client.managed_clusters.begin_create_or_update(
                resource_group_name=resource_group,
                resource_name=config.name,
                parameters=managed_cluster_params,
            )

            # Get initial result without waiting for completion
            result = poller.result(timeout=5) if config.metadata.get("wait_for_completion") else None
            
            if result:
                cluster_data = result
                status = "ACTIVE" if cluster_data.provisioning_state == "Succeeded" else cluster_data.provisioning_state
            else:
                # Return creating status
                cluster_data = None
                status = "CREATING"

            logger.info(f"✅ Initiated AKS cluster creation: {config.name} (status: {status})")

            return Cluster(
                id=f"/subscriptions/{self.subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.ContainerService/managedClusters/{config.name}",
                name=config.name,
                status=status,
                version=config.version,
                endpoint=cluster_data.fqdn if cluster_data else None,
                region=config.region,
                node_count=config.node_count,
                created_at=None,
                metadata={
                    "resource_group": resource_group,
                    "provisioning_state": cluster_data.provisioning_state if cluster_data else "Creating",
                    "dns_prefix": config.metadata.get("dns_prefix", f"{config.name}-dns"),
                },
            )

        except AzureResourceNotFoundError as e:
            raise ResourceNotFoundError(f"Resource group not found: {e}", provider="azure")
        except HttpResponseError as e:
            if "already exists" in str(e).lower():
                raise ResourceAlreadyExistsError(f"Cluster {config.name} already exists", provider="azure")
            raise CloudProviderError(f"Failed to create AKS cluster: {e}", provider="azure", error_code=e.error.code if hasattr(e, 'error') else None)
        except Exception as e:
            raise CloudProviderError(f"Unexpected error creating AKS cluster: {e}", provider="azure")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(HttpResponseError,),
    )
    def get_cluster(self, cluster_name: str, resource_group: str, include_node_count: bool = True) -> Cluster:
        """
        Get AKS cluster details.

        Args:
            cluster_name: Cluster name
            resource_group: Resource group name
            include_node_count: Whether to include node count

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster retrieval fails
        """
        logger.info(f"Getting AKS cluster: {cluster_name} in resource group {resource_group}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            cluster_data = client.managed_clusters.get(resource_group, cluster_name)

            # Calculate node count from agent pools
            node_count = 0
            if include_node_count and cluster_data.agent_pool_profiles:
                node_count = sum(pool.count for pool in cluster_data.agent_pool_profiles)

            status_map = {
                "Succeeded": "ACTIVE",
                "Failed": "FAILED",
                "Creating": "CREATING",
                "Deleting": "DELETING",
                "Updating": "UPDATING",
            }
            status = status_map.get(cluster_data.provisioning_state, cluster_data.provisioning_state)

            return Cluster(
                id=cluster_data.id,
                name=cluster_data.name,
                status=status,
                version=cluster_data.kubernetes_version,
                endpoint=cluster_data.fqdn,
                region=cluster_data.location,
                node_count=node_count,
                created_at=None,
                metadata={
                    "resource_group": resource_group,
                    "provisioning_state": cluster_data.provisioning_state,
                    "dns_prefix": cluster_data.dns_prefix,
                    "enable_rbac": cluster_data.enable_rbac,
                    "network_profile": {
                        "network_plugin": cluster_data.network_profile.network_plugin if cluster_data.network_profile else None,
                    },
                },
            )

        except AzureResourceNotFoundError:
            raise ResourceNotFoundError(f"Cluster {cluster_name} not found in resource group {resource_group}", provider="azure")
        except HttpResponseError as e:
            raise CloudProviderError(f"Failed to get AKS cluster: {e}", provider="azure", error_code=e.error.code if hasattr(e, 'error') else None)
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting AKS cluster: {e}", provider="azure")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(HttpResponseError,),
    )
    def delete_cluster(self, cluster_name: str, resource_group: str) -> bool:
        """
        Delete an AKS cluster.

        Args:
            cluster_name: Cluster name
            resource_group: Resource group name

        Returns:
            True if deletion was initiated successfully

        Raises:
            CloudProviderError: If cluster deletion fails
        """
        logger.info(f"Deleting AKS cluster: {cluster_name} in resource group {resource_group}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            poller = client.managed_clusters.begin_delete(resource_group, cluster_name)

            # Wait for deletion to complete (optional)
            # poller.result()

            logger.info(f"✅ Initiated deletion of AKS cluster: {cluster_name}")
            return True

        except AzureResourceNotFoundError:
            raise ResourceNotFoundError(f"Cluster {cluster_name} not found in resource group {resource_group}", provider="azure")
        except HttpResponseError as e:
            raise CloudProviderError(f"Failed to delete AKS cluster: {e}", provider="azure", error_code=e.error.code if hasattr(e, 'error') else None)
        except Exception as e:
            raise CloudProviderError(f"Unexpected error deleting AKS cluster: {e}", provider="azure")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(HttpResponseError,),
    )
    def list_clusters(self, resource_group: Optional[str] = None, include_details: bool = False) -> List[Cluster]:
        """
        List all AKS clusters.

        Args:
            resource_group: Optional resource group filter
            include_details: Whether to fetch detailed info for each cluster

        Returns:
            List of Cluster objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.info(f"Listing AKS clusters" + (f" in resource group {resource_group}" if resource_group else ""))

        try:
            client = self._get_client()
            clusters = []

            self.rate_limiter.acquire()
            if resource_group:
                cluster_list = client.managed_clusters.list_by_resource_group(resource_group)
            else:
                cluster_list = client.managed_clusters.list()

            for cluster_data in cluster_list:
                if include_details:
                    # Get detailed info
                    rg = cluster_data.id.split("/")[4]  # Extract resource group from ID
                    cluster = self.get_cluster(cluster_data.name, rg, include_node_count=True)
                    clusters.append(cluster)
                else:
                    # Basic info only
                    status_map = {
                        "Succeeded": "ACTIVE",
                        "Failed": "FAILED",
                        "Creating": "CREATING",
                        "Deleting": "DELETING",
                        "Updating": "UPDATING",
                    }
                    status = status_map.get(cluster_data.provisioning_state, cluster_data.provisioning_state)

                    clusters.append(
                        Cluster(
                            id=cluster_data.id,
                            name=cluster_data.name,
                            status=status,
                            version=cluster_data.kubernetes_version,
                            endpoint=cluster_data.fqdn,
                            region=cluster_data.location,
                            node_count=0,
                            metadata={"provisioning_state": cluster_data.provisioning_state},
                        )
                    )

            logger.info(f"✅ Found {len(clusters)} AKS clusters")
            return clusters

        except HttpResponseError as e:
            raise CloudProviderError(f"Failed to list AKS clusters: {e}", provider="azure", error_code=e.error.code if hasattr(e, 'error') else None)
        except Exception as e:
            raise CloudProviderError(f"Unexpected error listing AKS clusters: {e}", provider="azure")
