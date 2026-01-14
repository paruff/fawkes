"""Civo Cloud Provider implementation."""

import logging
import os
from typing import Optional, List, Dict, Any

from civo import Civo

from ..interfaces.provider import (
    CloudProvider,
    ClusterConfig,
    DatabaseConfig,
    StorageConfig,
)
from ..interfaces.models import Cluster, Database, Storage, CostData
from ..exceptions import AuthenticationError, CloudProviderError
from ..utils import RateLimiter

from .civo.kubernetes import KubernetesService
from .civo.database import DatabaseService
from .civo.objectstore import ObjectStoreService
from .civo.billing import BillingService

logger = logging.getLogger(__name__)


class CivoProvider(CloudProvider):
    """Civo cloud provider implementation.
    
    Civo is a simpler cloud provider focused on Kubernetes and developer experience.
    Key differences from AWS/GCP:
    - Limited regions (fewer global locations)
    - Simpler networking model (no complex VPC/subnet management)
    - Smaller resource options (optimized for development/testing)
    - K3s-based Kubernetes clusters (lighter than EKS/GKE)
    - Databases deployed as K8s applications (not separate managed services)
    - Rate limits are more restrictive (respect them carefully)
    """

    # Civo has fewer regions than AWS/GCP
    VALID_REGIONS = ["NYC1", "LON1", "FRA1", "PHX1"]

    def __init__(
        self,
        api_key: Optional[str] = None,
        region: Optional[str] = None,
        rate_limit_calls: int = 5,  # Civo has stricter rate limits
        rate_limit_window: float = 1.0,
    ):
        """
        Initialize Civo provider.

        Authentication:
        1. API key provided as parameter (most secure when using secret management)
        2. CIVO_TOKEN environment variable
        3. ~/.civo.json config file (if using Civo CLI)

        Args:
            api_key: Civo API key (recommended: store in secret manager)
            region: Default Civo region (NYC1, LON1, FRA1, PHX1)
            rate_limit_calls: Maximum API calls per time window (default: 5 for Civo)
            rate_limit_window: Time window in seconds for rate limiting

        Raises:
            AuthenticationError: If authentication fails
        """
        self.region = region or os.getenv("CIVO_REGION", "NYC1")
        self.rate_limiter = RateLimiter(max_calls=rate_limit_calls, time_window=rate_limit_window)

        # Validate region
        if self.region not in self.VALID_REGIONS:
            logger.warning(
                f"Region {self.region} may not be valid. "
                f"Valid regions: {', '.join(self.VALID_REGIONS)}"
            )

        try:
            # Get API key from parameter, environment, or config
            civo_token = api_key or os.getenv("CIVO_TOKEN")
            
            if not civo_token:
                raise AuthenticationError(
                    "No Civo API key found. Please provide api_key parameter or set CIVO_TOKEN environment variable. "
                    "You can generate an API key in the Civo console: https://dashboard.civo.com/security",
                    provider="civo",
                )

            # Initialize Civo client
            self.client = Civo(token=civo_token, region=self.region)
            
            # Verify credentials by making a test call
            self._verify_credentials()

            # Initialize service clients
            self.kubernetes = KubernetesService(self.client, self.rate_limiter)
            self.database = DatabaseService(self.client, self.rate_limiter)
            self.objectstore = ObjectStoreService(self.client, self.rate_limiter)
            self.billing = BillingService(self.client, self.rate_limiter)

            logger.info(f"✅ Civo Provider initialized successfully for region: {self.region}")

        except AuthenticationError:
            raise
        except Exception as e:
            error_msg = str(e)
            if "401" in error_msg or "unauthorized" in error_msg.lower():
                raise AuthenticationError(
                    f"Civo authentication failed: Invalid API key. {error_msg}",
                    provider="civo"
                )
            else:
                raise AuthenticationError(
                    f"Civo initialization failed: {error_msg}",
                    provider="civo"
                )

    def _verify_credentials(self):
        """Verify Civo credentials by making a test call."""
        try:
            # Test API access by getting quota
            self.rate_limiter.acquire()
            quota = self.client.quota.get()
            logger.info(
                f"Authenticated with Civo. "
                f"Quota: {quota.get('instance_count_usage', 0)}/{quota.get('instance_count_limit', 'N/A')} instances"
            )
        except Exception as e:
            error_msg = str(e)
            if "401" in error_msg or "unauthorized" in error_msg.lower():
                raise AuthenticationError(
                    "Credential verification failed: Invalid API key",
                    provider="civo"
                )
            else:
                logger.warning(f"Could not verify credentials: {error_msg}. Continuing anyway.")

    # Cluster operations
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """
        Create a Kubernetes cluster.

        Civo limitations:
        - Uses K3s (lighter than K8s)
        - Simpler node configuration
        - Limited node instance types
        - Faster creation time (~2-3 minutes vs 10-15 for EKS/GKE)
        """
        return self.kubernetes.create_cluster(config)

    def get_cluster(self, cluster_id: str) -> Cluster:
        """Get cluster details."""
        return self.kubernetes.get_cluster(cluster_id)

    def delete_cluster(self, cluster_id: str) -> bool:
        """Delete a cluster."""
        return self.kubernetes.delete_cluster(cluster_id)

    def list_clusters(self, region: Optional[str] = None) -> List[Cluster]:
        """List all clusters."""
        return self.kubernetes.list_clusters(region)

    # Database operations
    def create_database(self, config: DatabaseConfig) -> Database:
        """
        Create a database instance.

        Civo limitations:
        - No separate managed database service (like RDS/CloudSQL)
        - Databases deployed as Kubernetes applications
        - Must specify cluster_id in config.metadata
        - Limited to marketplace database applications
        """
        return self.database.create_database(config)

    def get_database(self, database_id: str) -> Database:
        """Get database details."""
        return self.database.get_database(database_id)

    def delete_database(self, database_id: str, skip_final_snapshot: bool = False) -> bool:
        """
        Delete a database instance.
        
        Note: skip_final_snapshot is not applicable in Civo as databases
        are K8s applications, not managed services.
        """
        return self.database.delete_database(database_id, skip_final_snapshot=skip_final_snapshot)

    def list_databases(self, region: Optional[str] = None) -> List[Database]:
        """
        List all database instances.
        
        Note: In Civo, databases are deployed as cluster applications.
        """
        return self.database.list_databases(region)

    # Storage operations
    def create_storage(self, config: StorageConfig) -> Storage:
        """
        Create a storage bucket.

        Civo limitations:
        - Simpler configuration than S3/GCS
        - Max size limit per bucket (typically 500GB-5TB)
        - S3-compatible but with fewer features
        - No versioning support
        """
        return self.objectstore.create_storage(config)

    def get_storage(self, storage_id: str) -> Storage:
        """Get storage bucket details."""
        return self.objectstore.get_storage(storage_id)

    def delete_storage(self, storage_id: str, force: bool = False) -> bool:
        """Delete a storage bucket."""
        return self.objectstore.delete_storage(storage_id, force=force)

    def list_storage(self, region: Optional[str] = None) -> List[Storage]:
        """List all storage buckets."""
        return self.objectstore.list_storage(region)

    # Cost and metrics operations
    def get_cost_data(self, timeframe: str, granularity: str = "MONTHLY") -> CostData:
        """
        Get cost data for a specified timeframe.

        Civo limitations:
        - Simpler billing API than AWS Cost Explorer
        - May not have detailed cost breakdown
        - Costs are estimated based on current resources
        """
        return self.billing.get_cost_data(timeframe, granularity)

    def get_metrics(
        self,
        resource_id: str,
        metric_name: str,
        start_time: str,
        end_time: str,
    ) -> Dict[str, Any]:
        """
        Get metrics for a resource.

        Civo limitations:
        - Simpler monitoring than CloudWatch/Cloud Monitoring
        - Metrics available through Prometheus (deployed in clusters)
        - No centralized metrics service like AWS/GCP
        
        Note: This is a basic implementation. For production use,
        you should query Prometheus directly from the cluster.
        """
        logger.info(
            f"Getting metrics for {resource_id}: {metric_name} "
            f"from {start_time} to {end_time}"
        )
        
        # Civo doesn't have a centralized metrics API like CloudWatch
        # Metrics are available through Prometheus in each cluster
        # For now, return a placeholder response
        
        return {
            "resource_id": resource_id,
            "metric_name": metric_name,
            "start_time": start_time,
            "end_time": end_time,
            "values": [],
            "note": "Civo metrics are available through Prometheus in each cluster. "
                   "Query the cluster's Prometheus instance directly for detailed metrics.",
        }

    def get_quota(self) -> Dict[str, Any]:
        """
        Get account quota information.

        Returns:
            Dictionary containing quota limits and usage
        """
        return self.billing.get_quota()
