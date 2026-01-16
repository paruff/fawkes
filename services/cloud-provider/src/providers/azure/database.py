"""Azure Database for PostgreSQL/MySQL operations."""

import logging
from typing import List, Optional
from datetime import datetime

from azure.mgmt.rdbms.postgresql import PostgreSQLManagementClient
from azure.mgmt.rdbms.mysql import MySQLManagementClient
from azure.core.exceptions import (
    ResourceNotFoundError as AzureResourceNotFoundError,
    HttpResponseError,
)

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


class AzureDatabaseService:
    """Azure Database for PostgreSQL/MySQL service operations."""

    def __init__(self, credential, subscription_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Azure Database service.

        Args:
            credential: Azure credential object
            subscription_id: Azure subscription ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.credential = credential
        self.subscription_id = subscription_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._pg_clients = {}
        self._mysql_clients = {}

    def _get_client(self, engine: str, subscription_id: Optional[str] = None):
        """Get or create database client based on engine type."""
        sub_id = subscription_id or self.subscription_id
        
        if engine.lower() in ["postgres", "postgresql"]:
            if sub_id not in self._pg_clients:
                self.rate_limiter.acquire()
                self._pg_clients[sub_id] = PostgreSQLManagementClient(self.credential, sub_id)
                logger.debug(f"Created PostgreSQL client for subscription: {sub_id}")
            return self._pg_clients[sub_id]
        elif engine.lower() == "mysql":
            if sub_id not in self._mysql_clients:
                self.rate_limiter.acquire()
                self._mysql_clients[sub_id] = MySQLManagementClient(self.credential, sub_id)
                logger.debug(f"Created MySQL client for subscription: {sub_id}")
            return self._mysql_clients[sub_id]
        else:
            raise ValidationError(f"Unsupported database engine: {engine}. Supported: postgresql, mysql", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def create_database(self, config: DatabaseConfig) -> Database:
        """
        Create an Azure Database for PostgreSQL/MySQL instance.

        Args:
            config: Database configuration

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database creation fails
        """
        logger.info(f"Creating Azure Database: {config.name} ({config.engine}) in region {config.region}")

        try:
            resource_group = config.metadata.get("resource_group")
            if not resource_group:
                raise ValidationError("resource_group must be provided in metadata", provider="azure")

            client = self._get_client(config.engine)

            server_params = {
                "location": config.region,
                "properties": {
                    "create_mode": "Default",
                    "version": config.engine_version,
                    "administrator_login": config.master_username,
                    "administrator_login_password": config.master_password,
                    "storage_profile": {
                        "storage_mb": config.allocated_storage * 1024,
                        "backup_retention_days": config.backup_retention_days,
                        "geo_redundant_backup": "Enabled" if config.multi_az else "Disabled",
                    },
                    "ssl_enforcement": "Enabled" if config.metadata.get("ssl_enforcement", True) else "Disabled",
                    "public_network_access": "Enabled" if config.publicly_accessible else "Disabled",
                },
                "sku": {
                    "name": config.instance_class,
                    "tier": config.metadata.get("tier", "GeneralPurpose"),
                    "capacity": config.metadata.get("capacity", 2),
                },
                "tags": config.tags,
            }

            self.rate_limiter.acquire()
            poller = client.servers.begin_create(
                resource_group_name=resource_group,
                server_name=config.name,
                parameters=server_params,
            )

            result = poller.result(timeout=5) if config.metadata.get("wait_for_completion") else None

            if result:
                server_data = result
                status = "available" if server_data.user_visible_state == "Ready" else server_data.user_visible_state
            else:
                server_data = None
                status = "creating"

            logger.info(f"✅ Initiated Azure Database creation: {config.name} (status: {status})")

            provider_prefix = "Microsoft.DBforPostgreSQL" if config.engine.lower() in ["postgres", "postgresql"] else "Microsoft.DBforMySQL"

            return Database(
                id=f"/subscriptions/{self.subscription_id}/resourceGroups/{resource_group}/providers/{provider_prefix}/servers/{config.name}",
                name=config.name,
                engine=config.engine,
                engine_version=config.engine_version,
                status=status,
                endpoint=f"{config.name}.{config.engine.lower()}.database.azure.com" if server_data else None,
                port=5432 if config.engine.lower() in ["postgres", "postgresql"] else 3306,
                region=config.region,
                allocated_storage=config.allocated_storage,
                instance_class=config.instance_class,
                created_at=None,
                metadata={
                    "resource_group": resource_group,
                    "master_username": config.master_username,
                    "multi_az": config.multi_az,
                    "publicly_accessible": config.publicly_accessible,
                    "backup_retention_period": config.backup_retention_days,
                    "user_visible_state": server_data.user_visible_state if server_data else "Creating",
                },
            )

        except AzureResourceNotFoundError as e:
            raise ResourceNotFoundError(f"Resource group not found: {e}", provider="azure")
        except HttpResponseError as e:
            if "already exists" in str(e).lower():
                raise ResourceAlreadyExistsError(f"Database {config.name} already exists", provider="azure")
            raise CloudProviderError(
                f"Failed to create Azure Database: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error creating Azure Database: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def get_database(self, database_name: str, engine: str, resource_group: str) -> Database:
        """
        Get Azure Database details.

        Args:
            database_name: Database server name
            engine: Database engine (postgresql or mysql)
            resource_group: Resource group name

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database retrieval fails
        """
        logger.debug(f"Getting Azure Database: {database_name} ({engine}) in resource group {resource_group}")

        try:
            client = self._get_client(engine)

            self.rate_limiter.acquire()
            server_data = client.servers.get(resource_group, database_name)

            status_map = {
                "Ready": "available",
                "Creating": "creating",
                "Deleting": "deleting",
                "Disabled": "stopped",
                "Dropping": "deleting",
            }
            status = status_map.get(server_data.user_visible_state, server_data.user_visible_state.lower())

            return Database(
                id=server_data.id,
                name=server_data.name,
                engine=engine,
                engine_version=server_data.version,
                status=status,
                endpoint=server_data.fully_qualified_domain_name,
                port=5432 if engine.lower() in ["postgres", "postgresql"] else 3306,
                region=server_data.location,
                allocated_storage=server_data.storage_profile.storage_mb // 1024 if server_data.storage_profile else 0,
                instance_class=server_data.sku.name if server_data.sku else "",
                created_at=None,
                metadata={
                    "resource_group": resource_group,
                    "master_username": server_data.administrator_login,
                    "user_visible_state": server_data.user_visible_state,
                    "ssl_enforcement": server_data.ssl_enforcement,
                    "public_network_access": server_data.public_network_access,
                    "backup_retention_days": server_data.storage_profile.backup_retention_days if server_data.storage_profile else 0,
                    "geo_redundant_backup": server_data.storage_profile.geo_redundant_backup if server_data.storage_profile else None,
                },
            )

        except AzureResourceNotFoundError:
            raise ResourceNotFoundError(
                f"Database {database_name} not found in resource group {resource_group}", provider="azure"
            )
        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to get Azure Database: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting Azure Database: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def delete_database(self, database_name: str, engine: str, resource_group: str) -> bool:
        """
        Delete an Azure Database instance.

        Args:
            database_name: Database server name
            engine: Database engine (postgresql or mysql)
            resource_group: Resource group name

        Returns:
            True if deletion was initiated

        Raises:
            CloudProviderError: If database deletion fails
        """
        logger.info(f"Deleting Azure Database: {database_name} ({engine}) in resource group {resource_group}")

        try:
            client = self._get_client(engine)

            self.rate_limiter.acquire()
            poller = client.servers.begin_delete(resource_group, database_name)

            logger.info(f"✅ Initiated Azure Database deletion: {database_name}")
            return True

        except AzureResourceNotFoundError:
            raise ResourceNotFoundError(
                f"Database {database_name} not found in resource group {resource_group}", provider="azure"
            )
        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to delete Azure Database: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error deleting Azure Database: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def list_databases(self, engine: str, resource_group: Optional[str] = None) -> List[Database]:
        """
        List all Azure Database instances.

        Args:
            engine: Database engine (postgresql or mysql)
            resource_group: Optional resource group filter

        Returns:
            List of Database objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing Azure Databases ({engine})" + (f" in resource group {resource_group}" if resource_group else ""))

        try:
            client = self._get_client(engine)
            databases = []

            self.rate_limiter.acquire()
            if resource_group:
                server_list = client.servers.list_by_resource_group(resource_group)
            else:
                server_list = client.servers.list()

            for server_data in server_list:
                try:
                    status_map = {
                        "Ready": "available",
                        "Creating": "creating",
                        "Deleting": "deleting",
                        "Disabled": "stopped",
                        "Dropping": "deleting",
                    }
                    status = status_map.get(server_data.user_visible_state, server_data.user_visible_state.lower())

                    rg = server_data.id.split("/")[4] if "/" in server_data.id else resource_group

                    databases.append(
                        Database(
                            id=server_data.id,
                            name=server_data.name,
                            engine=engine,
                            engine_version=server_data.version,
                            status=status,
                            endpoint=server_data.fully_qualified_domain_name,
                            port=5432 if engine.lower() in ["postgres", "postgresql"] else 3306,
                            region=server_data.location,
                            allocated_storage=server_data.storage_profile.storage_mb // 1024 if server_data.storage_profile else 0,
                            instance_class=server_data.sku.name if server_data.sku else "",
                            metadata={
                                "resource_group": rg,
                                "user_visible_state": server_data.user_visible_state,
                            },
                        )
                    )
                except Exception as e:
                    logger.warning(f"Could not parse database: {e}")

            logger.info(f"Found {len(databases)} Azure Databases ({engine})")
            return databases

        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to list Azure Databases: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error listing Azure Databases: {e}", provider="azure")
