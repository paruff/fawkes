"""AWS RDS (Relational Database Service) operations."""

import logging
from typing import List, Optional
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

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


class RDSService:
    """AWS RDS service operations."""

    def __init__(self, session: boto3.Session, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize RDS service.

        Args:
            session: Boto3 session
            rate_limiter: Optional rate limiter for API calls
        """
        self.session = session
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._clients = {}

    def _get_client(self, region: str):
        """Get or create RDS client for region."""
        if region not in self._clients:
            self.rate_limiter.acquire()
            self._clients[region] = self.session.client("rds", region_name=region)
            logger.debug(f"Created RDS client for region: {region}")
        return self._clients[region]

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def create_database(self, config: DatabaseConfig) -> Database:
        """
        Create an RDS database instance.

        Args:
            config: Database configuration

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database creation fails
        """
        logger.info(f"Creating RDS database: {config.name} in region {config.region}")

        try:
            client = self._get_client(config.region)

            # Build database creation request
            create_params = {
                "DBInstanceIdentifier": config.name,
                "Engine": config.engine,
                "EngineVersion": config.engine_version,
                "DBInstanceClass": config.instance_class,
                "AllocatedStorage": config.allocated_storage,
                "MasterUsername": config.master_username,
                "MultiAZ": config.multi_az,
                "PubliclyAccessible": config.publicly_accessible,
                "BackupRetentionPeriod": config.backup_retention_days,
                "Tags": [{"Key": k, "Value": v} for k, v in config.tags.items()],
            }

            # Add master password if provided
            if config.master_password:
                create_params["MasterUserPassword"] = config.master_password

            # Add VPC security groups if provided
            if config.security_group_ids:
                create_params["VpcSecurityGroupIds"] = config.security_group_ids

            # Add DB subnet group if subnets provided
            if config.subnet_ids and config.metadata.get("db_subnet_group_name"):
                create_params["DBSubnetGroupName"] = config.metadata["db_subnet_group_name"]

            # Add additional parameters from metadata
            if config.metadata.get("storage_type"):
                create_params["StorageType"] = config.metadata["storage_type"]
            if config.metadata.get("storage_encrypted"):
                create_params["StorageEncrypted"] = config.metadata["storage_encrypted"]

            self.rate_limiter.acquire()
            response = client.create_db_instance(**create_params)

            db_data = response["DBInstance"]

            logger.info(f"✅ Initiated RDS database creation: {config.name} (status: {db_data['DBInstanceStatus']})")

            return self._build_database_from_response(db_data, config.region)

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "DBInstanceAlreadyExists":
                raise ResourceAlreadyExistsError(f"Database {config.name} already exists", provider="aws")
            elif error_code == "InvalidParameterValue":
                raise ValidationError(f"Invalid parameter: {error_msg}", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to create RDS database {config.name}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def get_database(self, database_id: str, region: str) -> Database:
        """
        Get RDS database details.

        Args:
            database_id: Database instance identifier
            region: AWS region

        Returns:
            Database object with details

        Raises:
            CloudProviderError: If database retrieval fails
        """
        logger.debug(f"Getting RDS database: {database_id} in region {region}")

        try:
            client = self._get_client(region)
            self.rate_limiter.acquire()
            response = client.describe_db_instances(DBInstanceIdentifier=database_id)

            if not response["DBInstances"]:
                raise ResourceNotFoundError(f"Database {database_id} not found", provider="aws")

            db_data = response["DBInstances"][0]
            return self._build_database_from_response(db_data, region)

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "DBInstanceNotFound":
                raise ResourceNotFoundError(f"Database {database_id} not found", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to get RDS database {database_id}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def delete_database(self, database_id: str, region: str, skip_final_snapshot: bool = False) -> bool:
        """
        Delete an RDS database instance.

        Args:
            database_id: Database instance identifier
            region: AWS region
            skip_final_snapshot: Whether to skip final snapshot

        Returns:
            True if deletion was initiated

        Raises:
            CloudProviderError: If database deletion fails
        """
        logger.info(f"Deleting RDS database: {database_id} in region {region}")

        try:
            client = self._get_client(region)

            delete_params = {
                "DBInstanceIdentifier": database_id,
                "SkipFinalSnapshot": skip_final_snapshot,
            }

            if not skip_final_snapshot:
                # Generate final snapshot identifier
                snapshot_id = f"{database_id}-final-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"
                delete_params["FinalDBSnapshotIdentifier"] = snapshot_id

            self.rate_limiter.acquire()
            client.delete_db_instance(**delete_params)

            logger.info(f"✅ Initiated RDS database deletion: {database_id}")
            return True

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "DBInstanceNotFound":
                raise ResourceNotFoundError(f"Database {database_id} not found", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to delete RDS database {database_id}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def list_databases(self, region: str) -> List[Database]:
        """
        List all RDS database instances in a region.

        Args:
            region: AWS region

        Returns:
            List of Database objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing RDS databases in region {region}")

        try:
            client = self._get_client(region)
            databases = []

            self.rate_limiter.acquire()
            response = client.describe_db_instances()

            for db_data in response.get("DBInstances", []):
                try:
                    database = self._build_database_from_response(db_data, region)
                    databases.append(database)
                except Exception as e:
                    logger.warning(f"Could not parse database: {e}")

            logger.info(f"Found {len(databases)} RDS databases in region {region}")
            return databases

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise CloudProviderError(
                f"Failed to list RDS databases in {region}: {error_msg}", provider="aws", error_code=error_code
            )

    def _build_database_from_response(self, db_data: dict, region: str) -> Database:
        """Build Database object from AWS response."""
        endpoint_info = db_data.get("Endpoint", {})

        return Database(
            id=db_data["DBInstanceIdentifier"],
            name=db_data["DBInstanceIdentifier"],
            engine=db_data["Engine"],
            engine_version=db_data["EngineVersion"],
            status=db_data["DBInstanceStatus"],
            endpoint=endpoint_info.get("Address"),
            port=endpoint_info.get("Port"),
            region=region,
            allocated_storage=db_data.get("AllocatedStorage", 0),
            instance_class=db_data.get("DBInstanceClass", ""),
            created_at=db_data.get("InstanceCreateTime"),
            metadata={
                "arn": db_data.get("DBInstanceArn"),
                "master_username": db_data.get("MasterUsername"),
                "multi_az": db_data.get("MultiAZ", False),
                "publicly_accessible": db_data.get("PubliclyAccessible", False),
                "storage_type": db_data.get("StorageType"),
                "storage_encrypted": db_data.get("StorageEncrypted", False),
                "backup_retention_period": db_data.get("BackupRetentionPeriod", 0),
                "availability_zone": db_data.get("AvailabilityZone"),
                "vpc_security_groups": db_data.get("VpcSecurityGroups", []),
            },
        )
