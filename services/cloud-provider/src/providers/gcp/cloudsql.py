"""GCP Cloud SQL operations."""

import logging
from typing import List, Optional
from datetime import datetime

from google.cloud.sql.connector import Connector
from google.cloud import sql_v1
from google.api_core import exceptions as gcp_exceptions

from ...interfaces.models import Database
from ...interfaces.provider import DatabaseConfig
from ...exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
    ValidationError,
)
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class CloudSQLService:
    """GCP Cloud SQL service operations."""

    def __init__(self, project_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Cloud SQL service.

        Args:
            project_id: GCP project ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.project_id = project_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._client = None

    def _get_client(self):
        """Get or create Cloud SQL admin client."""
        if self._client is None:
            self.rate_limiter.acquire()
            self._client = sql_v1.SqlInstancesServiceClient()
            logger.debug("Created Cloud SQL admin client")
        return self._client

    def _map_engine_to_database_version(self, engine: str, engine_version: str) -> str:
        """
        Map generic engine name to GCP database version string.

        Args:
            engine: Generic engine name (e.g., 'postgres', 'mysql')
            engine_version: Engine version

        Returns:
            GCP database version string
        """
        engine_lower = engine.lower()
        
        if engine_lower == "postgres" or engine_lower == "postgresql":
            return f"POSTGRES_{engine_version.replace('.', '_')}"
        elif engine_lower == "mysql":
            return f"MYSQL_{engine_version.replace('.', '_')}"
        elif engine_lower == "sqlserver":
            return f"SQLSERVER_{engine_version.replace('.', '_')}"
        else:
            return engine_version

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def create_database(self, config: DatabaseConfig) -> Database:
        """
        Create a Cloud SQL database instance.

        Args:
            config: Database configuration

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database creation fails
        """
        logger.info(f"Creating Cloud SQL instance: {config.name} in region {config.region}")

        try:
            client = self._get_client()

            # Map engine to GCP database version
            database_version = self._map_engine_to_database_version(config.engine, config.engine_version)

            # Build database instance
            instance = sql_v1.DatabaseInstance()
            instance.name = config.name
            instance.database_version = database_version
            instance.region = config.region

            # Settings
            settings = sql_v1.Settings()
            settings.tier = config.instance_class
            settings.backup_configuration = sql_v1.BackupConfiguration()
            settings.backup_configuration.enabled = config.backup_retention_days > 0
            settings.backup_configuration.backup_retention_settings = sql_v1.BackupRetentionSettings()
            settings.backup_configuration.backup_retention_settings.retained_backups = config.backup_retention_days

            # IP configuration
            ip_configuration = sql_v1.IpConfiguration()
            ip_configuration.ipv4_enabled = config.publicly_accessible

            # Add authorized networks from metadata if provided
            if config.metadata.get("authorized_networks"):
                for network in config.metadata["authorized_networks"]:
                    acl_entry = sql_v1.AclEntry()
                    acl_entry.value = network
                    ip_configuration.authorized_networks.append(acl_entry)

            settings.ip_configuration = ip_configuration

            # Data disk configuration
            settings.data_disk_size_gb = config.allocated_storage
            if config.metadata.get("data_disk_type"):
                settings.data_disk_type = config.metadata["data_disk_type"]

            # High availability (multi-AZ equivalent)
            settings.availability_type = (
                sql_v1.SqlAvailabilityType.REGIONAL if config.multi_az else sql_v1.SqlAvailabilityType.ZONAL
            )

            instance.settings = settings

            # Set root password if provided
            if config.master_password:
                instance.root_password = config.master_password

            # Add labels (GCP equivalent of tags)
            if config.tags:
                instance.settings.user_labels = config.tags

            # Create instance request
            request = sql_v1.InsertInstanceRequest()
            request.project = self.project_id
            request.instance_resource = instance

            self.rate_limiter.acquire()
            operation = client.insert(request=request)

            logger.info(f"✅ Initiated Cloud SQL instance creation: {config.name} (operation: {operation.name})")

            return Database(
                id=config.name,
                name=config.name,
                engine=config.engine,
                engine_version=config.engine_version,
                status="PENDING_CREATE",
                region=config.region,
                allocated_storage=config.allocated_storage,
                instance_class=config.instance_class,
                metadata={
                    "project_id": self.project_id,
                    "operation_name": operation.name,
                    "database_version": database_version,
                },
            )

        except gcp_exceptions.AlreadyExists:
            raise ResourceAlreadyExistsError(f"Database instance {config.name} already exists", provider="gcp")
        except gcp_exceptions.InvalidArgument as e:
            raise ValidationError(f"Invalid parameter: {str(e)}", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to create Cloud SQL instance {config.name}: {str(e)}",
                provider="gcp",
                error_code=e.grpc_status_code,
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def get_database(self, database_name: str, region: Optional[str] = None) -> Database:
        """
        Get Cloud SQL instance details.

        Args:
            database_name: Database instance name
            region: GCP region (not used in get, kept for interface compatibility)

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database retrieval fails
        """
        logger.debug(f"Getting Cloud SQL instance: {database_name}")

        try:
            client = self._get_client()

            request = sql_v1.GetInstanceRequest()
            request.project = self.project_id
            request.instance = database_name

            self.rate_limiter.acquire()
            instance = client.get(request=request)

            # Parse database version
            engine = "unknown"
            engine_version = instance.database_version
            if "POSTGRES" in instance.database_version:
                engine = "postgres"
                engine_version = instance.database_version.replace("POSTGRES_", "").replace("_", ".")
            elif "MYSQL" in instance.database_version:
                engine = "mysql"
                engine_version = instance.database_version.replace("MYSQL_", "").replace("_", ".")
            elif "SQLSERVER" in instance.database_version:
                engine = "sqlserver"
                engine_version = instance.database_version.replace("SQLSERVER_", "").replace("_", ".")

            # Get first IP address
            endpoint = None
            port = None
            if instance.ip_addresses:
                endpoint = instance.ip_addresses[0].ip_address
                # Default ports
                if "POSTGRES" in instance.database_version:
                    port = 5432
                elif "MYSQL" in instance.database_version:
                    port = 3306
                elif "SQLSERVER" in instance.database_version:
                    port = 1433

            return Database(
                id=instance.name,
                name=instance.name,
                engine=engine,
                engine_version=engine_version,
                status=instance.state.name,
                endpoint=endpoint,
                port=port,
                region=instance.region,
                allocated_storage=instance.settings.data_disk_size_gb if instance.settings else 0,
                instance_class=instance.settings.tier if instance.settings else "",
                metadata={
                    "project_id": self.project_id,
                    "connection_name": instance.connection_name,
                    "self_link": instance.self_link,
                    "database_version": instance.database_version,
                },
            )

        except gcp_exceptions.NotFound:
            raise ResourceNotFoundError(f"Database instance {database_name} not found", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to get Cloud SQL instance {database_name}: {str(e)}",
                provider="gcp",
                error_code=e.grpc_status_code,
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def delete_database(self, database_name: str, region: Optional[str] = None, skip_final_snapshot: bool = False) -> bool:
        """
        Delete a Cloud SQL instance.

        Args:
            database_name: Database instance name
            region: GCP region (not used in delete, kept for interface compatibility)
            skip_final_snapshot: Not applicable to GCP (kept for interface compatibility)

        Returns:
            True if deletion was initiated

        Raises:
            CloudProviderError: If database deletion fails
        """
        logger.info(f"Deleting Cloud SQL instance: {database_name}")

        try:
            client = self._get_client()

            request = sql_v1.DeleteInstanceRequest()
            request.project = self.project_id
            request.instance = database_name

            self.rate_limiter.acquire()
            operation = client.delete(request=request)

            logger.info(f"✅ Initiated Cloud SQL instance deletion: {database_name} (operation: {operation.name})")
            return True

        except gcp_exceptions.NotFound:
            raise ResourceNotFoundError(f"Database instance {database_name} not found", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to delete Cloud SQL instance {database_name}: {str(e)}",
                provider="gcp",
                error_code=e.grpc_status_code,
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def list_databases(self, region: Optional[str] = None) -> List[Database]:
        """
        List all Cloud SQL instances in the project.

        Args:
            region: Optional region filter

        Returns:
            List of Database objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing Cloud SQL instances in project {self.project_id}")

        try:
            client = self._get_client()

            request = sql_v1.ListInstancesRequest()
            request.project = self.project_id

            databases = []

            self.rate_limiter.acquire()
            response = client.list(request=request)

            for instance in response.items:
                # Filter by region if specified
                if region and instance.region != region:
                    continue

                # Parse database version
                engine = "unknown"
                engine_version = instance.database_version
                if "POSTGRES" in instance.database_version:
                    engine = "postgres"
                    engine_version = instance.database_version.replace("POSTGRES_", "").replace("_", ".")
                elif "MYSQL" in instance.database_version:
                    engine = "mysql"
                    engine_version = instance.database_version.replace("MYSQL_", "").replace("_", ".")
                elif "SQLSERVER" in instance.database_version:
                    engine = "sqlserver"
                    engine_version = instance.database_version.replace("SQLSERVER_", "").replace("_", ".")

                databases.append(
                    Database(
                        id=instance.name,
                        name=instance.name,
                        engine=engine,
                        engine_version=engine_version,
                        status=instance.state.name,
                        region=instance.region,
                        allocated_storage=instance.settings.data_disk_size_gb if instance.settings else 0,
                        instance_class=instance.settings.tier if instance.settings else "",
                        metadata={
                            "project_id": self.project_id,
                            "connection_name": instance.connection_name,
                        },
                    )
                )

            logger.info(f"Found {len(databases)} Cloud SQL instances")
            return databases

        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to list Cloud SQL instances: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
