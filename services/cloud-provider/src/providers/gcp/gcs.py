"""GCP Cloud Storage (GCS) operations."""

import logging
from typing import List, Optional

from google.cloud import storage
from google.api_core import exceptions as gcp_exceptions

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


class GCSService:
    """GCP Cloud Storage service operations."""

    def __init__(self, project_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize GCS service.

        Args:
            project_id: GCP project ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.project_id = project_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._client = None

    def _get_client(self):
        """Get or create GCS client."""
        if self._client is None:
            self.rate_limiter.acquire()
            self._client = storage.Client(project=self.project_id)
            logger.debug("Created GCS client")
        return self._client

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def create_storage(self, config: StorageConfig) -> Storage:
        """
        Create a GCS bucket.

        Args:
            config: Storage configuration

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If bucket creation fails
        """
        logger.info(f"Creating GCS bucket: {config.name} in region {config.region}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            bucket = client.bucket(config.name)

            # Set bucket location
            bucket.location = config.region

            # Set storage class from metadata or default to STANDARD
            storage_class = config.metadata.get("storage_class", "STANDARD")
            bucket.storage_class = storage_class

            # Configure versioning
            bucket.versioning_enabled = config.versioning_enabled

            # Add labels (GCP equivalent of tags)
            if config.tags:
                bucket.labels = config.tags

            # Create bucket
            bucket = client.create_bucket(bucket, project=self.project_id)

            # Configure encryption if enabled
            if config.encryption_enabled:
                # Default encryption is always enabled in GCS, but we can set customer-managed keys
                if config.metadata.get("kms_key_name"):
                    bucket.default_kms_key_name = config.metadata["kms_key_name"]
                    bucket.patch()

            # Block public access if required
            if config.public_access_blocked:
                bucket.iam_configuration.public_access_prevention = "enforced"
                bucket.iam_configuration.uniform_bucket_level_access_enabled = True
                bucket.patch()

            # Add lifecycle rules if provided
            if config.lifecycle_rules:
                rules = []
                for rule_config in config.lifecycle_rules:
                    rule = storage.bucket.LifecycleRuleDelete()
                    # Parse rule configuration
                    if "age" in rule_config:
                        rule.age = rule_config["age"]
                    rules.append(rule)
                bucket.lifecycle_rules = rules
                bucket.patch()

            logger.info(f"✅ Created GCS bucket: {config.name}")

            return Storage(
                id=bucket.name,
                name=bucket.name,
                region=bucket.location,
                versioning_enabled=bucket.versioning_enabled,
                encryption_enabled=config.encryption_enabled,
                created_at=bucket.time_created,
                metadata={
                    "project_id": self.project_id,
                    "self_link": bucket.self_link,
                    "storage_class": bucket.storage_class,
                },
            )

        except gcp_exceptions.Conflict:
            raise ResourceAlreadyExistsError(f"Bucket {config.name} already exists", provider="gcp")
        except gcp_exceptions.InvalidArgument as e:
            raise ValidationError(f"Invalid parameter: {str(e)}", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to create GCS bucket {config.name}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
        except Exception as e:
            raise CloudProviderError(f"Failed to create GCS bucket {config.name}: {str(e)}", provider="gcp")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def get_storage(self, bucket_name: str, region: Optional[str] = None) -> Storage:
        """
        Get GCS bucket details.

        Args:
            bucket_name: Bucket name
            region: Not used (kept for interface compatibility)

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If bucket retrieval fails
        """
        logger.debug(f"Getting GCS bucket: {bucket_name}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            bucket = client.get_bucket(bucket_name)

            # Get bucket size and object count
            # Note: This is an expensive operation for large buckets as it iterates all objects.
            # For production use, consider using Cloud Asset Inventory or bucket metering.
            size_bytes = 0
            object_count = 0
            try:
                logger.warning(
                    f"Calculating bucket size for {bucket_name}. "
                    "This may be slow for buckets with many objects."
                )
                self.rate_limiter.acquire()
                blobs = bucket.list_blobs(max_results=1000)  # Limit to first 1000 objects
                for blob in blobs:
                    size_bytes += blob.size
                    object_count += 1
                if object_count >= 1000:
                    logger.warning(
                        f"Bucket {bucket_name} has 1000+ objects. "
                        "Size/count may be incomplete. Use Cloud Asset Inventory for accurate metrics."
                    )
            except Exception as e:
                logger.warning(f"Could not get bucket size/count: {e}")

            # Check encryption
            encryption_enabled = bucket.default_kms_key_name is not None

            return Storage(
                id=bucket.name,
                name=bucket.name,
                region=bucket.location,
                size_bytes=size_bytes,
                object_count=object_count,
                created_at=bucket.time_created,
                versioning_enabled=bucket.versioning_enabled,
                encryption_enabled=encryption_enabled,
                metadata={
                    "project_id": self.project_id,
                    "self_link": bucket.self_link,
                    "storage_class": bucket.storage_class,
                },
            )

        except gcp_exceptions.NotFound:
            raise ResourceNotFoundError(f"Bucket {bucket_name} not found", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to get GCS bucket {bucket_name}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
        except Exception as e:
            raise CloudProviderError(f"Failed to get GCS bucket {bucket_name}: {str(e)}", provider="gcp")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def delete_storage(self, bucket_name: str, region: Optional[str] = None, force: bool = False) -> bool:
        """
        Delete a GCS bucket.

        Args:
            bucket_name: Bucket name
            region: Not used (kept for interface compatibility)
            force: Whether to delete even if not empty

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If bucket deletion fails
        """
        logger.info(f"Deleting GCS bucket: {bucket_name}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            bucket = client.get_bucket(bucket_name)

            # If force is True, delete all objects first
            if force:
                logger.info(f"Force deleting bucket {bucket_name}, removing all objects first")
                self.rate_limiter.acquire()
                blobs = bucket.list_blobs()
                for blob in blobs:
                    try:
                        self.rate_limiter.acquire()
                        blob.delete()
                    except Exception as e:
                        logger.warning(f"Could not delete blob {blob.name}: {e}")

            # Delete bucket
            self.rate_limiter.acquire()
            bucket.delete(force=force)

            logger.info(f"✅ Deleted GCS bucket: {bucket_name}")
            return True

        except gcp_exceptions.NotFound:
            raise ResourceNotFoundError(f"Bucket {bucket_name} not found", provider="gcp")
        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to delete GCS bucket {bucket_name}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
        except Exception as e:
            raise CloudProviderError(f"Failed to delete GCS bucket {bucket_name}: {str(e)}", provider="gcp")

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(gcp_exceptions.ServiceUnavailable, gcp_exceptions.DeadlineExceeded),
    )
    def list_storage(self, region: Optional[str] = None, include_details: bool = False) -> List[Storage]:
        """
        List all GCS buckets in the project.

        Args:
            region: Optional region filter
            include_details: Whether to fetch detailed info for each bucket (slower)

        Returns:
            List of Storage objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing GCS buckets in project {self.project_id}")

        try:
            client = self._get_client()

            buckets = []

            self.rate_limiter.acquire()
            for bucket in client.list_buckets():
                # Filter by region if specified
                if region and bucket.location != region:
                    continue

                if include_details:
                    # Get detailed bucket info
                    size_bytes = 0
                    object_count = 0
                    try:
                        self.rate_limiter.acquire()
                        blobs = bucket.list_blobs()
                        for blob in blobs:
                            size_bytes += blob.size
                            object_count += 1
                    except Exception as e:
                        logger.warning(f"Could not get bucket size/count for {bucket.name}: {e}")

                    encryption_enabled = bucket.default_kms_key_name is not None

                    buckets.append(
                        Storage(
                            id=bucket.name,
                            name=bucket.name,
                            region=bucket.location,
                            size_bytes=size_bytes,
                            object_count=object_count,
                            created_at=bucket.time_created,
                            versioning_enabled=bucket.versioning_enabled,
                            encryption_enabled=encryption_enabled,
                            metadata={
                                "project_id": self.project_id,
                                "self_link": bucket.self_link,
                                "storage_class": bucket.storage_class,
                            },
                        )
                    )
                else:
                    # Return minimal bucket info
                    buckets.append(
                        Storage(
                            id=bucket.name,
                            name=bucket.name,
                            region=bucket.location,
                            created_at=bucket.time_created,
                            metadata={
                                "project_id": self.project_id,
                            },
                        )
                    )

            logger.info(f"Found {len(buckets)} GCS buckets")
            return buckets

        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to list GCS buckets: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )
        except Exception as e:
            raise CloudProviderError(f"Failed to list GCS buckets: {str(e)}", provider="gcp")
