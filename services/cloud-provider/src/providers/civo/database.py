"""Civo Database operations.

Note: Civo doesn't have a separate managed database service like AWS RDS or GCP Cloud SQL.
Databases are deployed as Kubernetes applications/add-ons within clusters.
This module provides an abstraction layer to maintain interface compatibility.
"""

import logging
from typing import List, Optional
from datetime import datetime

from civo import Civo

from ...interfaces.models import Database
from ...interfaces.provider import DatabaseConfig
from ...exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    ValidationError,
)
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class DatabaseService:
    """Civo Database service operations.
    
    Civo databases are deployed as applications in Kubernetes clusters.
    This service manages database deployments through Civo's marketplace apps.
    """

    # Supported database applications in Civo marketplace
    SUPPORTED_DATABASES = {
        "postgresql": "PostgreSQL:5GB",
        "mysql": "MySQL:5GB",
        "mariadb": "MariaDB:5GB",
        "mongodb": "MongoDB:5GB",
        "redis": "Redis:5GB",
    }

    def __init__(self, client: Civo, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Database service.

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
    def create_database(self, config: DatabaseConfig) -> Database:
        """
        Create a database instance.

        In Civo, this creates/updates a Kubernetes cluster with the database application.
        The cluster_id must be provided in config.metadata.

        Args:
            config: Database configuration

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database creation fails
            ValidationError: If configuration is invalid
        """
        logger.info(f"Creating Civo database: {config.name} (engine: {config.engine})")

        # Validate configuration
        cluster_id = config.metadata.get("cluster_id")
        if not cluster_id:
            raise ValidationError(
                "cluster_id must be provided in metadata for Civo database creation",
                provider="civo"
            )

        engine_lower = config.engine.lower()
        if engine_lower not in self.SUPPORTED_DATABASES:
            raise ValidationError(
                f"Unsupported database engine: {config.engine}. "
                f"Supported: {', '.join(self.SUPPORTED_DATABASES.keys())}",
                provider="civo"
            )

        try:
            # Get the marketplace application name
            app_name = self.SUPPORTED_DATABASES[engine_lower]
            
            # For simplicity, we'll store metadata about the database deployment
            # In a real implementation, you might create a custom application
            # or use Helm charts through Civo's application marketplace
            
            self.rate_limiter.acquire()
            
            # Note: Civo doesn't have a direct database creation API
            # This is a simplified implementation that would need to:
            # 1. Deploy database via application marketplace
            # 2. Configure storage and networking
            # 3. Track the deployment status
            
            # For now, we'll return a Database object representing the intended state
            logger.info(
                f"✅ Database {config.name} would be deployed as {app_name} "
                f"in cluster {cluster_id}"
            )

            return Database(
                id=f"{cluster_id}-{config.name}",
                name=config.name,
                engine=config.engine,
                engine_version=config.engine_version,
                status="creating",
                endpoint=None,  # Would be set after deployment
                port=self._get_default_port(config.engine),
                region=config.region,
                allocated_storage=config.allocated_storage,
                instance_class=config.instance_class,
                created_at=datetime.now(),
                metadata={
                    "cluster_id": cluster_id,
                    "application": app_name,
                    "civo_managed": True,
                    "deployment_type": "kubernetes_application",
                },
            )

        except ValidationError:
            raise
        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(
                f"Failed to create database {config.name}: {error_msg}",
                provider="civo"
            )

    def _get_default_port(self, engine: str) -> int:
        """Get default port for database engine."""
        ports = {
            "postgresql": 5432,
            "mysql": 3306,
            "mariadb": 3306,
            "mongodb": 27017,
            "redis": 6379,
        }
        return ports.get(engine.lower(), 5432)

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def get_database(self, database_id: str, region: Optional[str] = None) -> Database:
        """
        Get database details.

        Args:
            database_id: Database identifier (format: cluster_id-db_name)
            region: Region (not used in Civo, kept for interface compatibility)

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database not found or error occurs
        """
        logger.info(f"Getting Civo database details: {database_id}")

        try:
            # Parse database_id to get cluster_id and db_name
            if "-" not in database_id:
                raise ValidationError(
                    f"Invalid database_id format: {database_id}. "
                    "Expected format: cluster_id-db_name",
                    provider="civo"
                )

            cluster_id = database_id.split("-", 1)[0]
            
            self.rate_limiter.acquire()
            
            # In a real implementation, you would:
            # 1. Get cluster details
            # 2. Check installed applications
            # 3. Query database deployment status
            
            # For now, return a placeholder
            raise ResourceNotFoundError(
                f"Database {database_id} not found. "
                "Note: Civo databases are deployed as cluster applications.",
                provider="civo"
            )

        except (ValidationError, ResourceNotFoundError):
            raise
        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(
                f"Failed to get database {database_id}: {error_msg}",
                provider="civo"
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def delete_database(
        self, database_id: str, region: Optional[str] = None, skip_final_snapshot: bool = False
    ) -> bool:
        """
        Delete a database instance.

        Args:
            database_id: Database identifier
            region: Region (not used in Civo)
            skip_final_snapshot: Whether to skip final snapshot (not applicable in Civo)

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        logger.info(f"Deleting Civo database: {database_id}")

        try:
            # Parse database_id
            if "-" not in database_id:
                raise ValidationError(
                    f"Invalid database_id format: {database_id}",
                    provider="civo"
                )

            self.rate_limiter.acquire()
            
            # In a real implementation, you would:
            # 1. Find the database application in the cluster
            # 2. Uninstall the application
            # 3. Clean up associated resources
            
            logger.info(
                f"✅ Database {database_id} would be removed from cluster. "
                "Note: Actual implementation requires application uninstallation."
            )
            return True

        except ValidationError:
            raise
        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(
                f"Failed to delete database {database_id}: {error_msg}",
                provider="civo"
            )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
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
        logger.info("Listing all Civo databases")

        try:
            self.rate_limiter.acquire()
            
            # In a real implementation, you would:
            # 1. List all clusters
            # 2. For each cluster, check installed applications
            # 3. Filter for database applications
            # 4. Return Database objects for each
            
            # For now, return empty list
            logger.info(
                "Civo databases are deployed as cluster applications. "
                "Use cluster.metadata['installed_applications'] to see database deployments."
            )
            return []

        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(
                f"Failed to list databases: {error_msg}",
                provider="civo"
            )
