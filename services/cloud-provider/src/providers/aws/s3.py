"""AWS S3 (Simple Storage Service) operations."""

import logging
from typing import List, Optional
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

from ...interfaces.models import Storage
from ...interfaces.provider import StorageConfig
from ...exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
    ValidationError,
)
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class S3Service:
    """AWS S3 service operations."""

    def __init__(self, session: boto3.Session, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize S3 service.

        Args:
            session: Boto3 session
            rate_limiter: Optional rate limiter for API calls
        """
        self.session = session
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._clients = {}

    def _get_client(self, region: str):
        """Get or create S3 client for region."""
        if region not in self._clients:
            self.rate_limiter.acquire()
            self._clients[region] = self.session.client("s3", region_name=region)
            logger.debug(f"Created S3 client for region: {region}")
        return self._clients[region]

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def create_storage(self, config: StorageConfig) -> Storage:
        """
        Create an S3 bucket.

        Args:
            config: Storage configuration

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If bucket creation fails
        """
        logger.info(f"Creating S3 bucket: {config.name} in region {config.region}")

        try:
            client = self._get_client(config.region)

            # Create bucket
            create_params = {"Bucket": config.name}

            # For regions other than us-east-1, we need to specify LocationConstraint
            if config.region != "us-east-1":
                create_params["CreateBucketConfiguration"] = {"LocationConstraint": config.region}

            self.rate_limiter.acquire()
            client.create_bucket(**create_params)

            # Enable versioning if requested
            if config.versioning_enabled:
                self.rate_limiter.acquire()
                client.put_bucket_versioning(Bucket=config.name, VersioningConfiguration={"Status": "Enabled"})
                logger.debug(f"Enabled versioning for bucket: {config.name}")

            # Enable encryption if requested
            if config.encryption_enabled:
                self.rate_limiter.acquire()
                client.put_bucket_encryption(
                    Bucket=config.name,
                    ServerSideEncryptionConfiguration={
                        "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
                    },
                )
                logger.debug(f"Enabled encryption for bucket: {config.name}")

            # Block public access if requested
            if config.public_access_blocked:
                self.rate_limiter.acquire()
                client.put_public_access_block(
                    Bucket=config.name,
                    PublicAccessBlockConfiguration={
                        "BlockPublicAcls": True,
                        "IgnorePublicAcls": True,
                        "BlockPublicPolicy": True,
                        "RestrictPublicBuckets": True,
                    },
                )
                logger.debug(f"Blocked public access for bucket: {config.name}")

            # Add tags if provided
            if config.tags:
                self.rate_limiter.acquire()
                client.put_bucket_tagging(
                    Bucket=config.name, Tagging={"TagSet": [{"Key": k, "Value": v} for k, v in config.tags.items()]}
                )

            logger.info(f"✅ Created S3 bucket: {config.name}")

            return Storage(
                id=config.name,
                name=config.name,
                region=config.region,
                versioning_enabled=config.versioning_enabled,
                encryption_enabled=config.encryption_enabled,
                created_at=datetime.utcnow(),
                metadata={"tags": config.tags, "lifecycle_rules": config.lifecycle_rules},
            )

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "BucketAlreadyExists" or error_code == "BucketAlreadyOwnedByYou":
                raise ResourceAlreadyExistsError(f"Bucket {config.name} already exists", provider="aws")
            elif error_code == "InvalidBucketName":
                raise ValidationError(f"Invalid bucket name: {error_msg}", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to create S3 bucket {config.name}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def get_storage(self, bucket_name: str, region: str) -> Storage:
        """
        Get S3 bucket details.

        Args:
            bucket_name: Bucket name
            region: AWS region

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If bucket retrieval fails
        """
        logger.debug(f"Getting S3 bucket: {bucket_name}")

        try:
            client = self._get_client(region)

            # Get bucket location
            self.rate_limiter.acquire()
            location_response = client.get_bucket_location(Bucket=bucket_name)
            bucket_region = location_response.get("LocationConstraint") or "us-east-1"

            # Get versioning status
            versioning_enabled = False
            try:
                self.rate_limiter.acquire()
                versioning_response = client.get_bucket_versioning(Bucket=bucket_name)
                versioning_enabled = versioning_response.get("Status") == "Enabled"
            except ClientError:
                pass

            # Get encryption status
            encryption_enabled = False
            try:
                self.rate_limiter.acquire()
                client.get_bucket_encryption(Bucket=bucket_name)
                encryption_enabled = True
            except ClientError:
                pass

            # Get bucket size and object count
            # Note: Getting accurate size requires CloudWatch metrics which may not be real-time
            size_bytes = 0
            object_count = 0

            return Storage(
                id=bucket_name,
                name=bucket_name,
                region=bucket_region,
                size_bytes=size_bytes,
                object_count=object_count,
                versioning_enabled=versioning_enabled,
                encryption_enabled=encryption_enabled,
                metadata={"location_constraint": bucket_region},
            )

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "NoSuchBucket":
                raise ResourceNotFoundError(f"Bucket {bucket_name} not found", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to get S3 bucket {bucket_name}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def delete_storage(self, bucket_name: str, region: str, force: bool = False) -> bool:
        """
        Delete an S3 bucket.

        Args:
            bucket_name: Bucket name
            region: AWS region
            force: Whether to delete bucket even if not empty

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If bucket deletion fails
        """
        logger.info(f"Deleting S3 bucket: {bucket_name}")

        try:
            client = self._get_client(region)

            # If force is True, delete all objects first
            if force:
                logger.info(f"Force deletion enabled - deleting all objects in bucket: {bucket_name}")

                # List and delete all objects
                self.rate_limiter.acquire()
                paginator = client.get_paginator("list_objects_v2")
                for page in paginator.paginate(Bucket=bucket_name):
                    if "Contents" in page:
                        objects = [{"Key": obj["Key"]} for obj in page["Contents"]]
                        self.rate_limiter.acquire()
                        client.delete_objects(Bucket=bucket_name, Delete={"Objects": objects})

                # List and delete all object versions if versioning is enabled
                self.rate_limiter.acquire()
                versions_paginator = client.get_paginator("list_object_versions")
                for page in versions_paginator.paginate(Bucket=bucket_name):
                    versions_to_delete = []
                    if "Versions" in page:
                        versions_to_delete.extend(
                            [{"Key": v["Key"], "VersionId": v["VersionId"]} for v in page["Versions"]]
                        )
                    if "DeleteMarkers" in page:
                        versions_to_delete.extend(
                            [{"Key": m["Key"], "VersionId": m["VersionId"]} for m in page["DeleteMarkers"]]
                        )
                    if versions_to_delete:
                        self.rate_limiter.acquire()
                        client.delete_objects(Bucket=bucket_name, Delete={"Objects": versions_to_delete})

            # Delete the bucket
            self.rate_limiter.acquire()
            client.delete_bucket(Bucket=bucket_name)

            logger.info(f"✅ Deleted S3 bucket: {bucket_name}")
            return True

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "NoSuchBucket":
                raise ResourceNotFoundError(f"Bucket {bucket_name} not found", provider="aws")
            elif error_code == "BucketNotEmpty":
                raise CloudProviderError(
                    f"Bucket {bucket_name} is not empty. Use force=True to delete all contents.",
                    provider="aws",
                    error_code=error_code,
                )
            else:
                raise CloudProviderError(
                    f"Failed to delete S3 bucket {bucket_name}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def list_storage(self, region: Optional[str] = None) -> List[Storage]:
        """
        List all S3 buckets.

        Args:
            region: Optional region filter (S3 is global, but buckets have regions)

        Returns:
            List of Storage objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug("Listing S3 buckets")

        try:
            # Use any region for the client (S3 list_buckets is global)
            client = self._get_client(region or "us-east-1")

            self.rate_limiter.acquire()
            response = client.list_buckets()

            buckets = []
            for bucket_data in response.get("Buckets", []):
                try:
                    bucket_name = bucket_data["Name"]

                    # Get bucket region
                    self.rate_limiter.acquire()
                    location_response = client.get_bucket_location(Bucket=bucket_name)
                    bucket_region = location_response.get("LocationConstraint") or "us-east-1"

                    # Filter by region if specified
                    if region and bucket_region != region:
                        continue

                    # Get full bucket details
                    bucket = self.get_storage(bucket_name, bucket_region)
                    buckets.append(bucket)

                except Exception as e:
                    logger.warning(f"Could not retrieve bucket {bucket_data['Name']}: {e}")

            logger.info(f"Found {len(buckets)} S3 buckets")
            return buckets

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise CloudProviderError(f"Failed to list S3 buckets: {error_msg}", provider="aws", error_code=error_code)
