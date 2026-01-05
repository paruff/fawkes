"""GCP Cloud SQL operations using REST API.

Note: This implementation uses the Google Cloud SQL Admin API v1 REST API
via google-api-python-client instead of google-cloud-sql which doesn't exist.
"""

import logging
from typing import List, Optional

from googleapiclient import discovery
from googleapiclient.errors import HttpError
from google.auth import default as get_default_credentials

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
        self._service = None

    def _get_service(self):
        """Get or create Cloud SQL admin service."""
        if self._service is None:
            self.rate_limiter.acquire()
            credentials, _ = get_default_credentials()
            self._service = discovery.build('sqladmin', 'v1', credentials=credentials)
            logger.debug("Created Cloud SQL admin service")
        return self._service

    def _map_engine_to_database_version(self, engine: str, engine_version: str) -> str:
        """Map generic engine name to GCP database version string."""
        engine_lower = engine.lower()

        if engine_lower == "postgres" or engine_lower == "postgresql":
            return f"POSTGRES_{engine_version.replace('.', '_')}"
        elif engine_lower == "mysql":
            return f"MYSQL_{engine_version.replace('.', '_')}"
        elif engine_lower == "sqlserver":
            return f"SQLSERVER_{engine_version.replace('.', '_')}"
        else:
            return engine_version

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpError,))
    def create_database(self, config: DatabaseConfig) -> Database:
        """Create a Cloud SQL database instance."""
        logger.info(f"Creating Cloud SQL instance: {config.name} in region {config.region}")

        try:
            service = self._get_service()
            database_version = self._map_engine_to_database_version(config.engine, config.engine_version)

            # Build database instance
            instance_body = {
                "name": config.name,
                "databaseVersion": database_version,
                "region": config.region,
                "settings": {
                    "tier": config.instance_class,
                    "dataDiskSizeGb": config.allocated_storage,
                    "backupConfiguration": {
                        "enabled": config.backup_retention_days > 0,
                        "backupRetentionSettings": {
                            "retainedBackups": config.backup_retention_days
                        }
                    },
                    "ipConfiguration": {
                        "ipv4Enabled": config.publicly_accessible
                    },
                    "availabilityType": "REGIONAL" if config.multi_az else "ZONAL",
                    "userLabels": config.tags
                }
            }

            if config.master_password:
                instance_body["rootPassword"] = config.master_password

            self.rate_limiter.acquire()
            operation = service.instances().insert(
                project=self.project_id,
                body=instance_body
            ).execute()

            logger.info(f"✅ Initiated Cloud SQL instance creation: {config.name}")

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
                    "operation_name": operation.get("name"),
                    "database_version": database_version,
                },
            )

        except HttpError as e:
            if e.resp.status == 409:
                raise ResourceAlreadyExistsError(
                    f"Database instance {config.name} already exists", provider="gcp"
                )
            elif e.resp.status == 400:
                raise ValidationError(f"Invalid parameter: {str(e)}", provider="gcp")
            else:
                raise CloudProviderError(
                    f"Failed to create Cloud SQL instance {config.name}: {str(e)}",
                    provider="gcp",
                    error_code=str(e.resp.status),
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpError,))
    def get_database(self, database_name: str, region: Optional[str] = None) -> Database:
        """Get Cloud SQL instance details."""
        logger.debug(f"Getting Cloud SQL instance: {database_name}")

        try:
            service = self._get_service()

            self.rate_limiter.acquire()
            instance = service.instances().get(
                project=self.project_id,
                instance=database_name
            ).execute()

            # Parse database version
            engine = "unknown"
            engine_version = instance.get("databaseVersion", "")
            if "POSTGRES" in engine_version:
                engine = "postgres"
                engine_version = engine_version.replace("POSTGRES_", "").replace("_", ".")
            elif "MYSQL" in engine_version:
                engine = "mysql"
                engine_version = engine_version.replace("MYSQL_", "").replace("_", ".")
            elif "SQLSERVER" in engine_version:
                engine = "sqlserver"
                engine_version = engine_version.replace("SQLSERVER_", "").replace("_", ".")

            # Get first IP address
            endpoint = None
            port = None
            ip_addresses = instance.get("ipAddresses", [])
            if ip_addresses:
                endpoint = ip_addresses[0].get("ipAddress")
                # Default ports
                if "POSTGRES" in instance.get("databaseVersion", ""):
                    port = 5432
                elif "MYSQL" in instance.get("databaseVersion", ""):
                    port = 3306
                elif "SQLSERVER" in instance.get("databaseVersion", ""):
                    port = 1433

            settings = instance.get("settings", {})

            return Database(
                id=instance["name"],
                name=instance["name"],
                engine=engine,
                engine_version=engine_version,
                status=instance.get("state", "UNKNOWN"),
                endpoint=endpoint,
                port=port,
                region=instance.get("region", ""),
                allocated_storage=settings.get("dataDiskSizeGb", 0),
                instance_class=settings.get("tier", ""),
                metadata={
                    "project_id": self.project_id,
                    "connection_name": instance.get("connectionName"),
                    "self_link": instance.get("selfLink"),
                    "database_version": instance.get("databaseVersion"),
                },
            )

        except HttpError as e:
            if e.resp.status == 404:
                raise ResourceNotFoundError(f"Database instance {database_name} not found", provider="gcp")
            else:
                raise CloudProviderError(
                    f"Failed to get Cloud SQL instance {database_name}: {str(e)}",
                    provider="gcp",
                    error_code=str(e.resp.status),
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpError,))
    def delete_database(
        self, database_name: str, region: Optional[str] = None, skip_final_snapshot: bool = False
    ) -> bool:
        """Delete a Cloud SQL instance."""
        logger.info(f"Deleting Cloud SQL instance: {database_name}")

        try:
            service = self._get_service()

            self.rate_limiter.acquire()
            operation = service.instances().delete(
                project=self.project_id,
                instance=database_name
            ).execute()

            logger.info(f"✅ Initiated Cloud SQL instance deletion: {database_name}")
            return True

        except HttpError as e:
            if e.resp.status == 404:
                raise ResourceNotFoundError(f"Database instance {database_name} not found", provider="gcp")
            else:
                raise CloudProviderError(
                    f"Failed to delete Cloud SQL instance {database_name}: {str(e)}",
                    provider="gcp",
                    error_code=str(e.resp.status),
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpError,))
    def list_databases(self, region: Optional[str] = None) -> List[Database]:
        """List all Cloud SQL instances in the project."""
        logger.debug(f"Listing Cloud SQL instances in project {self.project_id}")

        try:
            service = self._get_service()

            databases = []

            self.rate_limiter.acquire()
            response = service.instances().list(project=self.project_id).execute()

            for instance in response.get("items", []):
                # Filter by region if specified
                if region and instance.get("region") != region:
                    continue

                # Parse database version
                engine = "unknown"
                engine_version = instance.get("databaseVersion", "")
                if "POSTGRES" in engine_version:
                    engine = "postgres"
                    engine_version = engine_version.replace("POSTGRES_", "").replace("_", ".")
                elif "MYSQL" in engine_version:
                    engine = "mysql"
                    engine_version = engine_version.replace("MYSQL_", "").replace("_", ".")
                elif "SQLSERVER" in engine_version:
                    engine = "sqlserver"
                    engine_version = engine_version.replace("SQLSERVER_", "").replace("_", ".")

                settings = instance.get("settings", {})

                databases.append(
                    Database(
                        id=instance["name"],
                        name=instance["name"],
                        engine=engine,
                        engine_version=engine_version,
                        status=instance.get("state", "UNKNOWN"),
                        region=instance.get("region", ""),
                        allocated_storage=settings.get("dataDiskSizeGb", 0),
                        instance_class=settings.get("tier", ""),
                        metadata={
                            "project_id": self.project_id,
                            "connection_name": instance.get("connectionName"),
                        },
                    )
                )

            logger.info(f"Found {len(databases)} Cloud SQL instances")
            return databases

        except HttpError as e:
            raise CloudProviderError(
                f"Failed to list Cloud SQL instances: {str(e)}",
                provider="gcp",
                error_code=str(e.resp.status),
            )
