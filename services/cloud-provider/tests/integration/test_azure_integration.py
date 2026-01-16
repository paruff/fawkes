"""Integration tests for Azure Provider.

These tests run against real Azure resources and require valid credentials.
Set SKIP_INTEGRATION_TESTS=1 to skip these tests.

Required environment variables:
- AZURE_SUBSCRIPTION_ID: Azure subscription ID
- AZURE_TENANT_ID: Azure tenant ID (for service principal auth)
- AZURE_CLIENT_ID: Azure client ID (for service principal auth)
- AZURE_CLIENT_SECRET: Azure client secret (for service principal auth)
- AZURE_TEST_RESOURCE_GROUP: Resource group for test resources
- AZURE_TEST_REGION: Azure region for test resources (default: eastus)
"""

import os
import pytest
import time
from datetime import datetime, timedelta

from src.providers.azure_provider import AzureProvider
from src.interfaces.provider import ClusterConfig, DatabaseConfig, StorageConfig
from src.exceptions import ResourceNotFoundError, CloudProviderError


# Skip all tests if SKIP_INTEGRATION_TESTS is set
pytestmark = pytest.mark.skipif(
    os.getenv("SKIP_INTEGRATION_TESTS") == "1",
    reason="Integration tests skipped",
)


@pytest.fixture(scope="module")
def azure_provider():
    """Create Azure provider for integration tests."""
    subscription_id = os.getenv("AZURE_SUBSCRIPTION_ID")
    tenant_id = os.getenv("AZURE_TENANT_ID")
    client_id = os.getenv("AZURE_CLIENT_ID")
    client_secret = os.getenv("AZURE_CLIENT_SECRET")

    if not subscription_id:
        pytest.skip("AZURE_SUBSCRIPTION_ID not set")

    # Try to authenticate
    try:
        if client_id and client_secret and tenant_id:
            # Service principal authentication
            provider = AzureProvider(
                subscription_id=subscription_id,
                tenant_id=tenant_id,
                client_id=client_id,
                client_secret=client_secret,
            )
        else:
            # Try DefaultAzureCredential (CLI or managed identity)
            provider = AzureProvider(subscription_id=subscription_id)

        return provider
    except Exception as e:
        pytest.skip(f"Could not initialize Azure provider: {e}")


@pytest.fixture(scope="module")
def test_resource_group():
    """Get test resource group from environment."""
    rg = os.getenv("AZURE_TEST_RESOURCE_GROUP")
    if not rg:
        pytest.skip("AZURE_TEST_RESOURCE_GROUP not set")
    return rg


@pytest.fixture(scope="module")
def test_region():
    """Get test region from environment or use default."""
    return os.getenv("AZURE_TEST_REGION", "eastus")


class TestAzureProviderIntegration:
    """Integration tests for Azure provider."""

    def test_provider_initialization(self, azure_provider):
        """Test that provider initializes successfully."""
        assert azure_provider is not None
        assert azure_provider.subscription_id is not None
        assert azure_provider.aks is not None
        assert azure_provider.database is not None
        assert azure_provider.storage is not None
        assert azure_provider.monitor is not None
        assert azure_provider.cost_management is not None

    def test_list_clusters(self, azure_provider, test_resource_group):
        """Test listing AKS clusters."""
        try:
            clusters = azure_provider.list_clusters(resource_group=test_resource_group)
            assert isinstance(clusters, list)
            # May be empty if no clusters exist
        except CloudProviderError as e:
            pytest.skip(f"Could not list clusters: {e}")

    def test_list_databases(self, azure_provider, test_resource_group):
        """Test listing databases."""
        try:
            databases = azure_provider.list_databases(resource_group=test_resource_group)
            assert isinstance(databases, list)
            # May be empty if no databases exist
        except CloudProviderError as e:
            pytest.skip(f"Could not list databases: {e}")

    def test_list_storage(self, azure_provider, test_resource_group):
        """Test listing storage accounts."""
        try:
            storage_accounts = azure_provider.list_storage(resource_group=test_resource_group)
            assert isinstance(storage_accounts, list)
            # May be empty if no storage accounts exist
        except CloudProviderError as e:
            pytest.skip(f"Could not list storage: {e}")

    def test_get_cost_data(self, azure_provider):
        """Test getting cost data."""
        try:
            cost_data = azure_provider.get_cost_data("LAST_7_DAYS", "DAILY")
            assert cost_data is not None
            assert cost_data.total_cost >= 0
            assert cost_data.currency == "USD"
            assert isinstance(cost_data.breakdown, dict)
        except CloudProviderError as e:
            # Cost data might not be available for all subscriptions
            pytest.skip(f"Could not get cost data: {e}")

    def test_cluster_not_found(self, azure_provider, test_resource_group):
        """Test that getting non-existent cluster raises ResourceNotFoundError."""
        with pytest.raises(ResourceNotFoundError):
            azure_provider.get_cluster("non-existent-cluster-xyz-123", test_resource_group)

    def test_database_not_found(self, azure_provider, test_resource_group):
        """Test that getting non-existent database raises ResourceNotFoundError."""
        with pytest.raises(ResourceNotFoundError):
            azure_provider.get_database("non-existent-db-xyz-123", test_resource_group)

    def test_storage_not_found(self, azure_provider, test_resource_group):
        """Test that getting non-existent storage raises ResourceNotFoundError."""
        with pytest.raises(ResourceNotFoundError):
            azure_provider.get_storage("nonexistentstorageabc123", test_resource_group)


class TestAzureProviderClusterLifecycle:
    """
    Integration tests for full cluster lifecycle.
    
    WARNING: These tests create and delete real resources in Azure.
    They are disabled by default. Set ENABLE_DESTRUCTIVE_TESTS=1 to enable.
    """

    @pytest.mark.skipif(
        os.getenv("ENABLE_DESTRUCTIVE_TESTS") != "1",
        reason="Destructive tests disabled (set ENABLE_DESTRUCTIVE_TESTS=1 to enable)",
    )
    def test_cluster_lifecycle(self, azure_provider, test_resource_group, test_region):
        """Test full cluster lifecycle: create, get, delete."""
        cluster_name = f"test-cluster-{int(time.time())}"

        # Create cluster
        config = ClusterConfig(
            name=cluster_name,
            region=test_region,
            version="1.28",
            node_count=1,
            node_instance_type="Standard_DS2_v2",
            metadata={
                "resource_group": test_resource_group,
                "dns_prefix": f"{cluster_name}-dns",
                "identity": {"type": "SystemAssigned"},
                "network_plugin": "kubenet",
            },
            tags={"Test": "true", "CreatedBy": "integration-test"},
        )

        try:
            cluster = azure_provider.create_cluster(config)
            assert cluster.name == cluster_name
            assert cluster.status in ["CREATING", "ACTIVE"]

            # Wait a bit for cluster to be in a stable state (optional)
            # In practice, AKS cluster creation takes 10-15 minutes

            # Get cluster
            cluster = azure_provider.get_cluster(cluster_name, test_resource_group)
            assert cluster.name == cluster_name

        finally:
            # Clean up - delete cluster
            try:
                azure_provider.delete_cluster(cluster_name, test_resource_group)
            except Exception as e:
                print(f"Warning: Could not clean up test cluster {cluster_name}: {e}")


class TestAzureProviderStorageLifecycle:
    """
    Integration tests for storage account lifecycle.
    
    WARNING: These tests create and delete real resources in Azure.
    They are disabled by default. Set ENABLE_DESTRUCTIVE_TESTS=1 to enable.
    """

    @pytest.mark.skipif(
        os.getenv("ENABLE_DESTRUCTIVE_TESTS") != "1",
        reason="Destructive tests disabled (set ENABLE_DESTRUCTIVE_TESTS=1 to enable)",
    )
    def test_storage_lifecycle(self, azure_provider, test_resource_group, test_region):
        """Test full storage lifecycle: create, get, delete."""
        # Azure storage account names must be globally unique, lowercase, 3-24 chars
        storage_name = f"teststg{int(time.time()) % 1000000000}"

        # Create storage account
        config = StorageConfig(
            name=storage_name,
            region=test_region,
            versioning_enabled=False,
            encryption_enabled=True,
            public_access_blocked=True,
            metadata={
                "resource_group": test_resource_group,
                "sku": "Standard_LRS",
                "kind": "StorageV2",
            },
            tags={"Test": "true", "CreatedBy": "integration-test"},
        )

        try:
            storage = azure_provider.create_storage(config)
            assert storage.name == storage_name
            assert storage.region == test_region

            # Wait for storage account to be ready
            time.sleep(30)

            # Get storage
            storage = azure_provider.get_storage(storage_name, test_resource_group)
            assert storage.name == storage_name

        finally:
            # Clean up - delete storage
            try:
                azure_provider.delete_storage(storage_name, test_resource_group, force=True)
            except Exception as e:
                print(f"Warning: Could not clean up test storage {storage_name}: {e}")
