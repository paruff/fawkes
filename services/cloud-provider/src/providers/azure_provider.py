"""Azure Cloud Provider implementation."""

import logging
import os
from typing import Optional, List, Dict, Any

from azure.identity import (
    DefaultAzureCredential,
    ClientSecretCredential,
    ManagedIdentityCredential,
    AzureCliCredential,
)
from azure.core.exceptions import HttpResponseError, ClientAuthenticationError

from ..interfaces.provider import (
    CloudProvider,
    ClusterConfig,
    DatabaseConfig,
    StorageConfig,
)
from ..interfaces.models import Cluster, Database, Storage, CostData
from ..exceptions import AuthenticationError
from ..utils import RateLimiter

from .azure.aks import AKSService
from .azure.database import AzureDatabaseService as DatabaseService
from .azure.storage import AzureStorageService as StorageService
from .azure.monitor import AzureMonitorService as MonitorService
from .azure.cost_management import AzureCostManagementService as CostManagementService

logger = logging.getLogger(__name__)


class AzureProvider(CloudProvider):
    """Azure cloud provider implementation."""

    def __init__(
        self,
        subscription_id: Optional[str] = None,
        tenant_id: Optional[str] = None,
        client_id: Optional[str] = None,
        client_secret: Optional[str] = None,
        use_managed_identity: bool = False,
        use_cli: bool = False,
        rate_limit_calls: int = 10,
        rate_limit_window: float = 1.0,
    ):
        """
        Initialize Azure provider.

        Authentication priority:
        1. Managed Identity (if use_managed_identity=True or running in Azure)
        2. Service Principal (if client_id/client_secret/tenant_id provided)
        3. Azure CLI (if use_cli=True)
        4. DefaultAzureCredential (environment variables, managed identity, CLI)

        Args:
            subscription_id: Azure subscription ID
            tenant_id: Azure tenant ID (for service principal)
            client_id: Azure client ID (for service principal)
            client_secret: Azure client secret (for service principal)
            use_managed_identity: Use managed identity authentication
            use_cli: Use Azure CLI authentication
            rate_limit_calls: Maximum API calls per time window
            rate_limit_window: Time window in seconds for rate limiting

        Raises:
            AuthenticationError: If authentication fails
        """
        self.subscription_id = subscription_id or os.getenv("AZURE_SUBSCRIPTION_ID")
        
        if not self.subscription_id:
            raise AuthenticationError(
                "Azure subscription ID is required. Provide via subscription_id parameter or "
                "AZURE_SUBSCRIPTION_ID environment variable.",
                provider="azure",
            )

        self.rate_limiter = RateLimiter(max_calls=rate_limit_calls, time_window=rate_limit_window)

        try:
            # Create credential based on authentication method
            if use_managed_identity:
                logger.info("Using Azure Managed Identity authentication")
                self.credential = ManagedIdentityCredential()
            elif client_id and client_secret and tenant_id:
                logger.info("Using Azure Service Principal authentication")
                self.credential = ClientSecretCredential(
                    tenant_id=tenant_id,
                    client_id=client_id,
                    client_secret=client_secret,
                )
            elif use_cli:
                logger.info("Using Azure CLI authentication")
                self.credential = AzureCliCredential()
            else:
                # Use DefaultAzureCredential which tries multiple methods
                logger.info("Using Azure DefaultAzureCredential (environment, managed identity, or CLI)")
                self.credential = DefaultAzureCredential()

            # Verify credentials by making a test call
            self._verify_credentials()

            # Initialize service clients
            self.aks = AKSService(self.credential, self.subscription_id, self.rate_limiter)
            self.database = DatabaseService(self.credential, self.subscription_id, self.rate_limiter)
            self.storage = StorageService(self.credential, self.subscription_id, self.rate_limiter)
            self.monitor = MonitorService(self.credential, self.subscription_id, self.rate_limiter)
            self.cost_management = CostManagementService(self.credential, self.subscription_id, self.rate_limiter)

            logger.info(f"✅ Azure Provider initialized successfully for subscription: {self.subscription_id}")

        except ClientAuthenticationError as e:
            raise AuthenticationError(
                f"Azure authentication failed: {e}",
                provider="azure",
            )
        except Exception as e:
            raise AuthenticationError(
                f"Failed to initialize Azure provider: {e}",
                provider="azure",
            )

    def _verify_credentials(self):
        """Verify Azure credentials by making a test call."""
        try:
            # Try to get a token to verify credentials
            from azure.mgmt.resource import ResourceManagementClient
            
            # Create a resource client to verify credentials
            resource_client = ResourceManagementClient(self.credential, self.subscription_id)
            
            # Try to list resource groups (minimal operation to verify auth)
            self.rate_limiter.acquire()
            list(resource_client.resource_groups.list(top=1))
            
            logger.info(f"✅ Azure credentials verified for subscription: {self.subscription_id}")
        except ClientAuthenticationError as e:
            raise AuthenticationError(f"Credential verification failed: {e}", provider="azure")
        except HttpResponseError as e:
            if e.status_code == 401 or e.status_code == 403:
                raise AuthenticationError(f"Credential verification failed: {e}", provider="azure")
            # Other HTTP errors might be non-auth related, so we'll let them pass
            logger.warning(f"Non-auth error during credential verification: {e}")
        except Exception as e:
            logger.warning(f"Could not fully verify credentials, but proceeding: {e}")

    # Cluster operations
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """
        Create a Kubernetes cluster.

        Args:
            config: Cluster configuration (must include resource_group in metadata)

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster creation fails
        """
        return self.aks.create_cluster(config)

    def get_cluster(self, cluster_id: str, resource_group: Optional[str] = None, include_node_count: bool = True) -> Cluster:
        """
        Get cluster details.

        Args:
            cluster_id: Cluster name
            resource_group: Resource group name (required for Azure)
            include_node_count: Whether to include node count

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster not found or error occurs
        """
        if not resource_group:
            # Try to extract from cluster_id if it's a full resource ID
            if "/resourceGroups/" in cluster_id:
                parts = cluster_id.split("/")
                resource_group = parts[parts.index("resourceGroups") + 1]
                cluster_name = parts[-1]
            else:
                from ..exceptions import ValidationError
                raise ValidationError("resource_group is required for Azure", provider="azure")
        else:
            cluster_name = cluster_id

        return self.aks.get_cluster(cluster_name, resource_group, include_node_count)

    def delete_cluster(self, cluster_id: str, resource_group: Optional[str] = None) -> bool:
        """
        Delete a cluster.

        Args:
            cluster_id: Cluster name
            resource_group: Resource group name (required for Azure)

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        if not resource_group:
            # Try to extract from cluster_id if it's a full resource ID
            if "/resourceGroups/" in cluster_id:
                parts = cluster_id.split("/")
                resource_group = parts[parts.index("resourceGroups") + 1]
                cluster_name = parts[-1]
            else:
                from ..exceptions import ValidationError
                raise ValidationError("resource_group is required for Azure", provider="azure")
        else:
            cluster_name = cluster_id

        return self.aks.delete_cluster(cluster_name, resource_group)

    def list_clusters(self, region: Optional[str] = None, resource_group: Optional[str] = None, include_details: bool = False) -> List[Cluster]:
        """
        List all clusters.

        Args:
            region: Not used for Azure (clusters are listed by subscription/resource group)
            resource_group: Optional resource group filter
            include_details: Whether to fetch detailed info for each cluster

        Returns:
            List of Cluster objects

        Raises:
            CloudProviderError: If listing fails
        """
        return self.aks.list_clusters(resource_group, include_details)

    # Database operations
    def create_database(self, config: DatabaseConfig) -> Database:
        """
        Create a database instance.

        Args:
            config: Database configuration (must include resource_group in metadata)

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database creation fails
        """
        return self.database.create_database(config)

    def get_database(self, database_id: str, resource_group: Optional[str] = None) -> Database:
        """
        Get database details.

        Args:
            database_id: Database server name
            resource_group: Resource group name (required for Azure)

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database not found or error occurs
        """
        if not resource_group:
            # Try to extract from database_id if it's a full resource ID
            if "/resourceGroups/" in database_id:
                parts = database_id.split("/")
                resource_group = parts[parts.index("resourceGroups") + 1]
                server_name = parts[-1]
            else:
                from ..exceptions import ValidationError
                raise ValidationError("resource_group is required for Azure", provider="azure")
        else:
            server_name = database_id

        return self.database.get_database(server_name, resource_group)

    def delete_database(self, database_id: str, resource_group: Optional[str] = None, skip_final_snapshot: bool = False) -> bool:
        """
        Delete a database instance.

        Args:
            database_id: Database server name
            resource_group: Resource group name (required for Azure)
            skip_final_snapshot: Not applicable for Azure (kept for interface compatibility)

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        if not resource_group:
            # Try to extract from database_id if it's a full resource ID
            if "/resourceGroups/" in database_id:
                parts = database_id.split("/")
                resource_group = parts[parts.index("resourceGroups") + 1]
                server_name = parts[-1]
            else:
                from ..exceptions import ValidationError
                raise ValidationError("resource_group is required for Azure", provider="azure")
        else:
            server_name = database_id

        return self.database.delete_database(server_name, resource_group)

    def list_databases(self, region: Optional[str] = None, resource_group: Optional[str] = None) -> List[Database]:
        """
        List all database instances.

        Args:
            region: Not used for Azure (databases are listed by subscription/resource group)
            resource_group: Optional resource group filter

        Returns:
            List of Database objects

        Raises:
            CloudProviderError: If listing fails
        """
        return self.database.list_databases(resource_group)

    # Storage operations
    def create_storage(self, config: StorageConfig) -> Storage:
        """
        Create a storage bucket/account.

        Args:
            config: Storage configuration (must include resource_group in metadata)

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage creation fails
        """
        return self.storage.create_storage(config)

    def get_storage(self, storage_id: str, resource_group: Optional[str] = None) -> Storage:
        """
        Get storage bucket/account details.

        Args:
            storage_id: Storage account name
            resource_group: Resource group name (required for Azure)

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage not found or error occurs
        """
        if not resource_group:
            # Try to extract from storage_id if it's a full resource ID
            if "/resourceGroups/" in storage_id:
                parts = storage_id.split("/")
                resource_group = parts[parts.index("resourceGroups") + 1]
                account_name = parts[-1]
            else:
                from ..exceptions import ValidationError
                raise ValidationError("resource_group is required for Azure", provider="azure")
        else:
            account_name = storage_id

        return self.storage.get_storage(account_name, resource_group)

    def delete_storage(self, storage_id: str, resource_group: Optional[str] = None, force: bool = False) -> bool:
        """
        Delete a storage bucket/account.

        Args:
            storage_id: Storage account name
            resource_group: Resource group name (required for Azure)
            force: Whether to delete even if not empty (Azure always allows deletion)

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        if not resource_group:
            # Try to extract from storage_id if it's a full resource ID
            if "/resourceGroups/" in storage_id:
                parts = storage_id.split("/")
                resource_group = parts[parts.index("resourceGroups") + 1]
                account_name = parts[-1]
            else:
                from ..exceptions import ValidationError
                raise ValidationError("resource_group is required for Azure", provider="azure")
        else:
            account_name = storage_id

        return self.storage.delete_storage(account_name, resource_group, force)

    def list_storage(self, region: Optional[str] = None, resource_group: Optional[str] = None, include_details: bool = False) -> List[Storage]:
        """
        List all storage buckets/accounts.

        Args:
            region: Not used for Azure (storage is listed by subscription/resource group)
            resource_group: Optional resource group filter
            include_details: Whether to fetch detailed info for each account

        Returns:
            List of Storage objects

        Raises:
            CloudProviderError: If listing fails
        """
        return self.storage.list_storage(resource_group, include_details)

    # Cost and metrics operations
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
        return self.cost_management.get_cost_data(timeframe, granularity)

    def get_metrics(
        self,
        resource_id: str,
        metric_name: str,
        start_time: str,
        end_time: str,
        aggregation: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get metrics for a resource.

        Args:
            resource_id: Full Azure resource ID
            metric_name: Name of the metric to retrieve
            start_time: Start time (ISO format)
            end_time: End time (ISO format)
            aggregation: Aggregation type (Average, Total, Minimum, Maximum, Count)

        Returns:
            Dictionary containing metric data

        Raises:
            CloudProviderError: If metrics retrieval fails
        """
        from datetime import datetime

        # Parse ISO format times
        start_dt = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
        end_dt = datetime.fromisoformat(end_time.replace("Z", "+00:00"))

        # Set default aggregation if not provided
        if not aggregation:
            aggregation = "Average"

        return self.monitor.get_metrics(
            resource_id,
            metric_name,
            start_dt,
            end_dt,
            aggregation,
        )

    def get_cost_forecast(self, days: int = 30) -> Dict[str, Any]:
        """
        Get cost forecast.

        Args:
            days: Number of days to forecast

        Returns:
            Dictionary containing forecast data

        Raises:
            CloudProviderError: If forecast retrieval fails
        """
        return self.cost_management.get_cost_forecast(days)
