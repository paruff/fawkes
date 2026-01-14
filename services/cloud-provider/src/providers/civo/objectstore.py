"""Civo Object Storage operations.

Civo provides S3-compatible object storage.
"""

import logging
from typing import List, Optional
from datetime import datetime

from civo import Civo

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


class ObjectStoreService:
    """Civo Object Storage service operations."""

    def __init__(self, client: Civo, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Object Storage service.

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
    def create_storage(self, config: StorageConfig) -> Storage:
        """
        Create an object storage bucket.

        Args:
            config: Storage configuration

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage creation fails
        """
        logger.info(f"Creating Civo object store: {config.name} in region {config.region}")

        try:
            self.rate_limiter.acquire()

            # Create object store
            # Civo object stores have simpler configuration than AWS S3
            create_params = {
                "name": config.name,
                "max_size_gb": config.metadata.get("max_size_gb", 500),  # Default 500GB
                "region": config.region,
            }

            # Add access key name if provided
            if config.metadata.get("access_key_name"):
                create_params["access_key_name"] = config.metadata["access_key_name"]

            result = self.client.objectstore.create(**create_params)

            logger.info(f"✅ Created Civo object store: {config.name} (id: {result['id']})")

            return Storage(
                id=result["id"],
                name=result["name"],
                region=config.region,
                size_bytes=0,  # Newly created
                object_count=0,
                created_at=datetime.now(),
                versioning_enabled=False,  # Civo doesn't support versioning by default
                encryption_enabled=True,  # Civo encrypts by default
                metadata={
                    "civo_store_id": result["id"],
                    "max_size_gb": result.get("max_size_gb", 500),
                    "bucket_url": result.get("bucket_url"),
                    "status": result.get("status", "ready"),
                },
            )

        except Exception as e:
            error_msg = str(e)
            
            if "already exists" in error_msg.lower():
                raise ResourceAlreadyExistsError(
                    f"Object store {config.name} already exists",
                    provider="civo"
                )
            elif "invalid" in error_msg.lower():
                raise ValidationError(
                    f"Invalid storage configuration: {error_msg}",
                    provider="civo"
                )
            else:
                raise CloudProviderError(
                    f"Failed to create object store {config.name}: {error_msg}",
                    provider="civo"
                )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def get_storage(self, storage_id: str, region: Optional[str] = None) -> Storage:
        """
        Get object storage details.

        Args:
            storage_id: Storage ID or name
            region: Region (not strictly needed in Civo, kept for compatibility)

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage not found or error occurs
        """
        logger.info(f"Getting Civo object store details: {storage_id}")

        try:
            self.rate_limiter.acquire()
            result = self.client.objectstore.get(storage_id)

            return Storage(
                id=result["id"],
                name=result["name"],
                region=result.get("region", ""),
                size_bytes=result.get("size_gb", 0) * 1024 * 1024 * 1024,  # Convert GB to bytes
                object_count=0,  # Civo doesn't provide object count in API
                created_at=datetime.fromisoformat(result["created_at"].replace("Z", "+00:00")) if result.get("created_at") else None,
                versioning_enabled=False,
                encryption_enabled=True,
                metadata={
                    "civo_store_id": result["id"],
                    "max_size_gb": result.get("max_size_gb", 500),
                    "bucket_url": result.get("bucket_url"),
                    "status": result.get("status", "ready"),
                },
            )

        except Exception as e:
            error_msg = str(e)
            if "not found" in error_msg.lower() or "404" in error_msg:
                raise ResourceNotFoundError(
                    f"Object store {storage_id} not found",
                    provider="civo"
                )
            else:
                raise CloudProviderError(
                    f"Failed to get object store {storage_id}: {error_msg}",
                    provider="civo"
                )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def delete_storage(
        self, storage_id: str, region: Optional[str] = None, force: bool = False
    ) -> bool:
        """
        Delete an object storage bucket.

        Args:
            storage_id: Storage ID
            region: Region (not used in Civo)
            force: Whether to delete even if not empty (Civo handles this automatically)

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If deletion fails
        """
        logger.info(f"Deleting Civo object store: {storage_id}")

        try:
            self.rate_limiter.acquire()
            self.client.objectstore.delete(storage_id)
            logger.info(f"✅ Successfully deleted object store: {storage_id}")
            return True

        except Exception as e:
            error_msg = str(e)
            if "not found" in error_msg.lower() or "404" in error_msg:
                raise ResourceNotFoundError(
                    f"Object store {storage_id} not found",
                    provider="civo"
                )
            else:
                raise CloudProviderError(
                    f"Failed to delete object store {storage_id}: {error_msg}",
                    provider="civo"
                )

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(Exception,),
    )
    def list_storage(self, region: Optional[str] = None) -> List[Storage]:
        """
        List all object storage buckets.

        Args:
            region: Optional region filter

        Returns:
            List of Storage objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.info("Listing all Civo object stores")

        try:
            self.rate_limiter.acquire()
            results = self.client.objectstore.list()

            storages = []
            for result in results:
                # Filter by region if specified
                if region and result.get("region") != region:
                    continue

                storage = Storage(
                    id=result["id"],
                    name=result["name"],
                    region=result.get("region", ""),
                    size_bytes=result.get("size_gb", 0) * 1024 * 1024 * 1024,
                    object_count=0,
                    created_at=datetime.fromisoformat(result["created_at"].replace("Z", "+00:00")) if result.get("created_at") else None,
                    versioning_enabled=False,
                    encryption_enabled=True,
                    metadata={
                        "civo_store_id": result["id"],
                        "max_size_gb": result.get("max_size_gb", 500),
                        "status": result.get("status", "ready"),
                    },
                )
                storages.append(storage)

            logger.info(f"Found {len(storages)} Civo object stores")
            return storages

        except Exception as e:
            error_msg = str(e)
            raise CloudProviderError(
                f"Failed to list object stores: {error_msg}",
                provider="civo"
            )
