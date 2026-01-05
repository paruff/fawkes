"""Cloud provider interface definition."""
from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from typing import Optional, Dict, Any, List

from .models import Cluster, Database, Storage, CostData


@dataclass
class ClusterConfig:
    """Configuration for cluster creation."""

    name: str
    region: str
    version: str
    node_count: int = 3
    node_instance_type: str = "t3.medium"
    vpc_id: Optional[str] = None
    subnet_ids: List[str] = field(default_factory=list)
    security_group_ids: List[str] = field(default_factory=list)
    tags: Dict[str, str] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class DatabaseConfig:
    """Configuration for database creation."""

    name: str
    engine: str
    engine_version: str
    instance_class: str
    region: str
    allocated_storage: int = 20
    master_username: str = "admin"
    master_password: Optional[str] = None
    vpc_id: Optional[str] = None
    subnet_ids: List[str] = field(default_factory=list)
    security_group_ids: List[str] = field(default_factory=list)
    backup_retention_days: int = 7
    multi_az: bool = False
    publicly_accessible: bool = False
    tags: Dict[str, str] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class StorageConfig:
    """Configuration for storage bucket creation."""

    name: str
    region: str
    versioning_enabled: bool = False
    encryption_enabled: bool = True
    public_access_blocked: bool = True
    lifecycle_rules: List[Dict[str, Any]] = field(default_factory=list)
    tags: Dict[str, str] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)


class CloudProvider(ABC):
    """Abstract base class for cloud provider implementations."""

    @abstractmethod
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """
        Create a Kubernetes cluster.

        Args:
            config: Cluster configuration

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster creation fails
        """
        pass

    @abstractmethod
    def get_cluster(self, cluster_id: str) -> Cluster:
        """
        Get cluster details.

        Args:
            cluster_id: Unique cluster identifier

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster not found or error occurs
        """
        pass

    @abstractmethod
    def delete_cluster(self, cluster_id: str) -> bool:
        """
        Delete a cluster.

        Args:
            cluster_id: Unique cluster identifier

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        pass

    @abstractmethod
    def list_clusters(self, region: Optional[str] = None) -> List[Cluster]:
        """
        List all clusters.

        Args:
            region: Optional region filter

        Returns:
            List of Cluster objects

        Raises:
            CloudProviderError: If listing fails
        """
        pass

    @abstractmethod
    def create_database(self, config: DatabaseConfig) -> Database:
        """
        Create a database instance.

        Args:
            config: Database configuration

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database creation fails
        """
        pass

    @abstractmethod
    def get_database(self, database_id: str) -> Database:
        """
        Get database details.

        Args:
            database_id: Unique database identifier

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database not found or error occurs
        """
        pass

    @abstractmethod
    def delete_database(self, database_id: str, skip_final_snapshot: bool = False) -> bool:
        """
        Delete a database instance.

        Args:
            database_id: Unique database identifier
            skip_final_snapshot: Whether to skip final snapshot

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        pass

    @abstractmethod
    def list_databases(self, region: Optional[str] = None) -> List[Database]:
        """
        List all database instances.

        Args:
            region: Optional region filter

        Returns:
            List of Database objects

        Raises:
            CloudProviderError: If listing fails
        """
        pass

    @abstractmethod
    def create_storage(self, config: StorageConfig) -> Storage:
        """
        Create a storage bucket.

        Args:
            config: Storage configuration

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage creation fails
        """
        pass

    @abstractmethod
    def get_storage(self, storage_id: str) -> Storage:
        """
        Get storage bucket details.

        Args:
            storage_id: Unique storage identifier (bucket name)

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage not found or error occurs
        """
        pass

    @abstractmethod
    def delete_storage(self, storage_id: str, force: bool = False) -> bool:
        """
        Delete a storage bucket.

        Args:
            storage_id: Unique storage identifier (bucket name)
            force: Whether to delete even if not empty

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        pass

    @abstractmethod
    def list_storage(self, region: Optional[str] = None) -> List[Storage]:
        """
        List all storage buckets.

        Args:
            region: Optional region filter

        Returns:
            List of Storage objects

        Raises:
            CloudProviderError: If listing fails
        """
        pass

    @abstractmethod
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
        pass

    @abstractmethod
    def get_metrics(self, resource_id: str, metric_name: str, start_time: str, end_time: str) -> Dict[str, Any]:
        """
        Get metrics for a resource.

        Args:
            resource_id: Unique resource identifier
            metric_name: Name of the metric to retrieve
            start_time: Start time (ISO format)
            end_time: End time (ISO format)

        Returns:
            Dictionary containing metric data

        Raises:
            CloudProviderError: If metrics retrieval fails
        """
        pass
