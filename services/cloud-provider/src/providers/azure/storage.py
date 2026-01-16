"""Azure Blob Storage operations."""

import logging
from typing import List, Optional
from datetime import datetime

from azure.mgmt.storage import StorageManagementClient
from azure.storage.blob import BlobServiceClient
from azure.core.exceptions import (
    ResourceNotFoundError as AzureResourceNotFoundError,
    HttpResponseError,
    ResourceExistsError,
)

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


class AzureStorageService:
    """Azure Blob Storage service operations."""

    def __init__(self, credential, subscription_id: str, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize Azure Storage service.

        Args:
            credential: Azure credential object
            subscription_id: Azure subscription ID
            rate_limiter: Optional rate limiter for API calls
        """
        self.credential = credential
        self.subscription_id = subscription_id
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._clients = {}

    def _get_client(self, subscription_id: Optional[str] = None) -> StorageManagementClient:
        """Get or create Storage management client."""
        sub_id = subscription_id or self.subscription_id
        if sub_id not in self._clients:
            self.rate_limiter.acquire()
            self._clients[sub_id] = StorageManagementClient(self.credential, sub_id)
            logger.debug(f"Created Storage client for subscription: {sub_id}")
        return self._clients[sub_id]

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def create_storage(self, config: StorageConfig) -> Storage:
        """
        Create an Azure Storage Account and Blob Container.

        Args:
            config: Storage configuration

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage creation fails
        """
        logger.info(f"Creating Azure Storage: {config.name} in region {config.region}")

        try:
            resource_group = config.metadata.get("resource_group")
            if not resource_group:
                raise ValidationError("resource_group must be provided in metadata", provider="azure")

            client = self._get_client()

            storage_account_params = {
                "location": config.region,
                "sku": {"name": config.metadata.get("sku", "Standard_LRS")},
                "kind": config.metadata.get("kind", "StorageV2"),
                "tags": config.tags,
                "properties": {
                    "supportsHttpsTrafficOnly": True,
                    "minimumTlsVersion": "TLS1_2",
                    "allowBlobPublicAccess": not config.public_access_blocked,
                },
            }

            if config.encryption_enabled:
                storage_account_params["encryption"] = {
                    "services": {"blob": {"enabled": True}},
                    "keySource": "Microsoft.Storage",
                }

            self.rate_limiter.acquire()
            poller = client.storage_accounts.begin_create(
                resource_group_name=resource_group,
                account_name=config.name,
                parameters=storage_account_params,
            )

            result = poller.result(timeout=5) if config.metadata.get("wait_for_completion") else None

            if result:
                account_data = result
                status = "available" if account_data.provisioning_state == "Succeeded" else account_data.provisioning_state
            else:
                account_data = None
                status = "creating"

            logger.info(f"✅ Created Azure Storage Account: {config.name} (status: {status})")

            return Storage(
                id=f"/subscriptions/{self.subscription_id}/resourceGroups/{resource_group}/providers/Microsoft.Storage/storageAccounts/{config.name}",
                name=config.name,
                region=config.region,
                versioning_enabled=config.versioning_enabled,
                encryption_enabled=config.encryption_enabled,
                created_at=account_data.creation_time if account_data else datetime.utcnow(),
                metadata={
                    "resource_group": resource_group,
                    "sku": config.metadata.get("sku", "Standard_LRS"),
                    "kind": config.metadata.get("kind", "StorageV2"),
                    "tags": config.tags,
                    "lifecycle_rules": config.lifecycle_rules,
                    "provisioning_state": account_data.provisioning_state if account_data else "Creating",
                },
            )

        except AzureResourceNotFoundError as e:
            raise ResourceNotFoundError(f"Resource group not found: {e}", provider="azure")
        except (HttpResponseError, ResourceExistsError) as e:
            if "already exists" in str(e).lower() or isinstance(e, ResourceExistsError):
                raise ResourceAlreadyExistsError(f"Storage account {config.name} already exists", provider="azure")
            raise CloudProviderError(
                f"Failed to create Azure Storage: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error creating Azure Storage: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def get_storage(self, storage_account_name: str, resource_group: str) -> Storage:
        """
        Get Azure Storage Account details.

        Args:
            storage_account_name: Storage account name
            resource_group: Resource group name

        Returns:
            Storage object with details

        Raises:
            CloudProviderError: If storage retrieval fails
        """
        logger.debug(f"Getting Azure Storage: {storage_account_name} in resource group {resource_group}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            account_data = client.storage_accounts.get_properties(resource_group, storage_account_name)

            versioning_enabled = False
            encryption_enabled = account_data.encryption and account_data.encryption.services.blob.enabled if account_data.encryption else False

            return Storage(
                id=account_data.id,
                name=account_data.name,
                region=account_data.location,
                size_bytes=0,
                object_count=0,
                versioning_enabled=versioning_enabled,
                encryption_enabled=encryption_enabled,
                created_at=account_data.creation_time,
                metadata={
                    "resource_group": resource_group,
                    "sku": account_data.sku.name if account_data.sku else None,
                    "kind": account_data.kind,
                    "provisioning_state": account_data.provisioning_state,
                    "primary_endpoints": {
                        "blob": account_data.primary_endpoints.blob if account_data.primary_endpoints else None,
                    },
                },
            )

        except AzureResourceNotFoundError:
            raise ResourceNotFoundError(
                f"Storage account {storage_account_name} not found in resource group {resource_group}", provider="azure"
            )
        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to get Azure Storage: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error getting Azure Storage: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def delete_storage(self, storage_account_name: str, resource_group: str, force: bool = False) -> bool:
        """
        Delete an Azure Storage Account.

        Args:
            storage_account_name: Storage account name
            resource_group: Resource group name
            force: Whether to delete even if not empty (Azure deletes all contents automatically)

        Returns:
            True if deletion was successful

        Raises:
            CloudProviderError: If storage deletion fails
        """
        logger.info(f"Deleting Azure Storage: {storage_account_name} in resource group {resource_group}")

        try:
            client = self._get_client()

            self.rate_limiter.acquire()
            client.storage_accounts.delete(resource_group, storage_account_name)

            logger.info(f"✅ Deleted Azure Storage Account: {storage_account_name}")
            return True

        except AzureResourceNotFoundError:
            raise ResourceNotFoundError(
                f"Storage account {storage_account_name} not found in resource group {resource_group}", provider="azure"
            )
        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to delete Azure Storage: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error deleting Azure Storage: {e}", provider="azure")

    @retry_with_backoff(max_retries=3, retriable_exceptions=(HttpResponseError,))
    def list_storage(self, resource_group: Optional[str] = None, include_details: bool = False) -> List[Storage]:
        """
        List all Azure Storage Accounts.

        Args:
            resource_group: Optional resource group filter
            include_details: Whether to fetch detailed info for each storage account

        Returns:
            List of Storage objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug("Listing Azure Storage Accounts" + (f" in resource group {resource_group}" if resource_group else ""))

        try:
            client = self._get_client()
            storage_accounts = []

            self.rate_limiter.acquire()
            if resource_group:
                account_list = client.storage_accounts.list_by_resource_group(resource_group)
            else:
                account_list = client.storage_accounts.list()

            for account_data in account_list:
                try:
                    if include_details:
                        rg = account_data.id.split("/")[4] if "/" in account_data.id else resource_group
                        storage = self.get_storage(account_data.name, rg)
                        storage_accounts.append(storage)
                    else:
                        encryption_enabled = account_data.encryption and account_data.encryption.services.blob.enabled if account_data.encryption else False

                        storage_accounts.append(
                            Storage(
                                id=account_data.id,
                                name=account_data.name,
                                region=account_data.location,
                                size_bytes=0,
                                object_count=0,
                                versioning_enabled=False,
                                encryption_enabled=encryption_enabled,
                                created_at=account_data.creation_time,
                                metadata={
                                    "sku": account_data.sku.name if account_data.sku else None,
                                    "kind": account_data.kind,
                                    "provisioning_state": account_data.provisioning_state,
                                },
                            )
                        )
                except Exception as e:
                    logger.warning(f"Could not retrieve storage account {account_data.name}: {e}")

            logger.info(f"Found {len(storage_accounts)} Azure Storage Accounts")
            return storage_accounts

        except HttpResponseError as e:
            raise CloudProviderError(
                f"Failed to list Azure Storage Accounts: {e}", provider="azure", error_code=e.error.code if hasattr(e, "error") else None
            )
        except Exception as e:
            raise CloudProviderError(f"Unexpected error listing Azure Storage: {e}", provider="azure")
