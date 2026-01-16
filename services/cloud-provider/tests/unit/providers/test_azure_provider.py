"""Unit tests for Azure Provider."""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime

from src.providers.azure_provider import AzureProvider
from src.interfaces.provider import ClusterConfig, DatabaseConfig, StorageConfig
from src.interfaces.models import Cluster, Database, Storage, CostData
from src.exceptions import AuthenticationError, ValidationError


@pytest.fixture
def azure_credentials():
    """Mock Azure credentials for testing."""
    import os

    os.environ["AZURE_SUBSCRIPTION_ID"] = "12345678-1234-1234-1234-123456789012"
    os.environ["AZURE_TENANT_ID"] = "87654321-4321-4321-4321-210987654321"
    os.environ["AZURE_CLIENT_ID"] = "test-client-id"
    os.environ["AZURE_CLIENT_SECRET"] = "test-client-secret"


@pytest.fixture
def mock_credential():
    """Create a mock Azure credential."""
    credential = Mock()
    credential.get_token = Mock(return_value=Mock(token="mock-token"))
    return credential


@pytest.fixture
def mock_subscription_id():
    """Return a mock subscription ID."""
    return "12345678-1234-1234-1234-123456789012"


class TestAzureProviderInitialization:
    """Test Azure Provider initialization and authentication."""

    def test_init_with_service_principal(self, azure_credentials):
        """Test initialization with service principal credentials."""
        with patch("src.providers.azure_provider.ClientSecretCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Mock credential
            mock_credential = Mock()
            mock_credential.get_token = Mock(return_value=Mock(token="mock-token"))
            mock_cred_class.return_value = mock_credential

            # Mock resource management client for verification
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            provider = AzureProvider(
                subscription_id="test-sub-id",
                tenant_id="test-tenant-id",
                client_id="test-client-id",
                client_secret="test-client-secret",
            )

            assert provider.subscription_id == "test-sub-id"
            mock_cred_class.assert_called_once_with(
                tenant_id="test-tenant-id",
                client_id="test-client-id",
                client_secret="test-client-secret",
            )

    def test_init_with_managed_identity(self, azure_credentials):
        """Test initialization with managed identity."""
        with patch("src.providers.azure_provider.ManagedIdentityCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Mock credential
            mock_credential = Mock()
            mock_credential.get_token = Mock(return_value=Mock(token="mock-token"))
            mock_cred_class.return_value = mock_credential

            # Mock resource management client for verification
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            provider = AzureProvider(
                subscription_id="test-sub-id",
                use_managed_identity=True,
            )

            assert provider.subscription_id == "test-sub-id"
            mock_cred_class.assert_called_once()

    def test_init_with_azure_cli(self, azure_credentials):
        """Test initialization with Azure CLI."""
        with patch("src.providers.azure_provider.AzureCliCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Mock credential
            mock_credential = Mock()
            mock_credential.get_token = Mock(return_value=Mock(token="mock-token"))
            mock_cred_class.return_value = mock_credential

            # Mock resource management client for verification
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            provider = AzureProvider(
                subscription_id="test-sub-id",
                use_cli=True,
            )

            assert provider.subscription_id == "test-sub-id"
            mock_cred_class.assert_called_once()

    def test_init_with_default_credential(self, azure_credentials):
        """Test initialization with DefaultAzureCredential."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Mock credential
            mock_credential = Mock()
            mock_credential.get_token = Mock(return_value=Mock(token="mock-token"))
            mock_cred_class.return_value = mock_credential

            # Mock resource management client for verification
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            provider = AzureProvider(subscription_id="test-sub-id")

            assert provider.subscription_id == "test-sub-id"
            mock_cred_class.assert_called_once()

    def test_init_default_behavior(self, azure_credentials):
        """Test default initialization behavior."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks, \
             patch("src.providers.azure_provider.DatabaseService") as mock_db, \
             patch("src.providers.azure_provider.StorageService") as mock_storage, \
             patch("src.providers.azure_provider.MonitorService") as mock_monitor, \
             patch("src.providers.azure_provider.CostManagementService") as mock_cost:

            # Mock credential
            mock_credential = Mock()
            mock_credential.get_token = Mock(return_value=Mock(token="mock-token"))
            mock_cred_class.return_value = mock_credential

            # Mock resource management client for verification
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            provider = AzureProvider()

            # Verify all service clients are initialized
            assert provider.aks is not None
            assert provider.database is not None
            assert provider.storage is not None
            assert provider.monitor is not None
            assert provider.cost_management is not None

            # Verify services were created
            mock_aks.assert_called_once()
            mock_db.assert_called_once()
            mock_storage.assert_called_once()
            mock_monitor.assert_called_once()
            mock_cost.assert_called_once()

    def test_init_without_subscription_id(self):
        """Test initialization fails without subscription_id."""
        import os

        # Clear subscription ID environment variable
        if "AZURE_SUBSCRIPTION_ID" in os.environ:
            del os.environ["AZURE_SUBSCRIPTION_ID"]

        with pytest.raises(AuthenticationError) as exc_info:
            _ = AzureProvider()

        assert "subscription ID is required" in str(exc_info.value)

    def test_credential_verification(self, azure_credentials):
        """Test credential verification during initialization."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Mock credential
            mock_credential = Mock()
            mock_credential.get_token = Mock(return_value=Mock(token="mock-token"))
            mock_cred_class.return_value = mock_credential

            # Mock resource management client for verification
            mock_client = MagicMock()
            mock_rg_list = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            _ = AzureProvider(subscription_id="test-sub-id")

            # Verify credential verification was attempted
            mock_rm_client.assert_called_once()
            mock_client.resource_groups.list.assert_called_once()

    def test_credential_verification_failure(self, azure_credentials):
        """Test initialization fails when credential verification fails."""
        from azure.core.exceptions import ClientAuthenticationError as AzureAuthError

        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client:

            # Mock credential
            mock_credential = Mock()
            mock_cred_class.return_value = mock_credential

            # Mock resource management client to raise auth error
            mock_client = MagicMock()
            mock_client.resource_groups.list.side_effect = AzureAuthError("Authentication failed")
            mock_rm_client.return_value = mock_client

            with pytest.raises(AuthenticationError) as exc_info:
                _ = AzureProvider(subscription_id="test-sub-id")

            assert "Credential verification failed" in str(exc_info.value)


class TestAzureProviderClusterOperations:
    """Test cluster operations."""

    def test_create_cluster(self, azure_credentials, mock_credential):
        """Test AKS cluster creation."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks_class, \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock AKS service
            mock_aks = Mock()
            mock_aks_class.return_value = mock_aks

            provider = AzureProvider(subscription_id="test-sub-id")

            config = ClusterConfig(
                name="test-cluster",
                region="eastus",
                version="1.28.0",
                node_count=3,
                metadata={"resource_group": "test-rg"},
            )

            expected_cluster = Cluster(
                id="test-cluster",
                name="test-cluster",
                status="Creating",
                version="1.28.0",
                region="eastus",
            )

            mock_aks.create_cluster.return_value = expected_cluster

            cluster = provider.create_cluster(config)

            assert cluster.name == "test-cluster"
            assert cluster.status == "Creating"
            assert cluster.version == "1.28.0"
            mock_aks.create_cluster.assert_called_once_with(config)

    def test_get_cluster_with_resource_group(self, azure_credentials, mock_credential):
        """Test getting cluster details with resource group."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks_class, \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock AKS service
            mock_aks = Mock()
            mock_aks_class.return_value = mock_aks

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_cluster = Cluster(
                id="test-cluster",
                name="test-cluster",
                status="Running",
                version="1.28.0",
                region="eastus",
                node_count=3,
            )

            mock_aks.get_cluster.return_value = expected_cluster

            cluster = provider.get_cluster("test-cluster", resource_group="test-rg", include_node_count=True)

            assert cluster.name == "test-cluster"
            assert cluster.status == "Running"
            assert cluster.node_count == 3
            mock_aks.get_cluster.assert_called_once_with("test-cluster", "test-rg", True)

    def test_get_cluster_extract_resource_group_from_id(self, azure_credentials, mock_credential):
        """Test getting cluster by extracting resource group from full ID."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks_class, \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock AKS service
            mock_aks = Mock()
            mock_aks_class.return_value = mock_aks

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_cluster = Cluster(
                id="test-cluster",
                name="test-cluster",
                status="Running",
                version="1.28.0",
                region="eastus",
            )

            mock_aks.get_cluster.return_value = expected_cluster

            # Full Azure resource ID
            full_id = "/subscriptions/test-sub/resourceGroups/my-rg/providers/Microsoft.ContainerService/managedClusters/test-cluster"
            cluster = provider.get_cluster(full_id)

            assert cluster.name == "test-cluster"
            mock_aks.get_cluster.assert_called_once_with("test-cluster", "my-rg", True)

    def test_get_cluster_without_resource_group_fails(self, azure_credentials, mock_credential):
        """Test getting cluster without resource group fails."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks_class, \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            mock_aks = Mock()
            mock_aks_class.return_value = mock_aks

            provider = AzureProvider(subscription_id="test-sub-id")

            with pytest.raises(ValidationError) as exc_info:
                provider.get_cluster("test-cluster")

            assert "resource_group is required" in str(exc_info.value)

    def test_delete_cluster(self, azure_credentials, mock_credential):
        """Test cluster deletion."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks_class, \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock AKS service
            mock_aks = Mock()
            mock_aks_class.return_value = mock_aks
            mock_aks.delete_cluster.return_value = True

            provider = AzureProvider(subscription_id="test-sub-id")

            result = provider.delete_cluster("test-cluster", resource_group="test-rg")

            assert result is True
            mock_aks.delete_cluster.assert_called_once_with("test-cluster", "test-rg")

    def test_list_clusters_no_filter(self, azure_credentials, mock_credential):
        """Test listing clusters without resource group filter."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks_class, \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock AKS service
            mock_aks = Mock()
            mock_aks_class.return_value = mock_aks

            expected_clusters = [
                Cluster(id="cluster-1", name="cluster-1", status="Running", version="1.28.0", region="eastus"),
                Cluster(id="cluster-2", name="cluster-2", status="Running", version="1.27.0", region="westus"),
            ]
            mock_aks.list_clusters.return_value = expected_clusters

            provider = AzureProvider(subscription_id="test-sub-id")

            clusters = provider.list_clusters(include_details=False)

            assert len(clusters) == 2
            assert clusters[0].name == "cluster-1"
            assert clusters[1].name == "cluster-2"
            mock_aks.list_clusters.assert_called_once_with(None, False)

    def test_list_clusters_with_resource_group_filter(self, azure_credentials, mock_credential):
        """Test listing clusters with resource group filter."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService") as mock_aks_class, \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock AKS service
            mock_aks = Mock()
            mock_aks_class.return_value = mock_aks

            expected_clusters = [
                Cluster(id="cluster-1", name="cluster-1", status="Running", version="1.28.0", region="eastus"),
            ]
            mock_aks.list_clusters.return_value = expected_clusters

            provider = AzureProvider(subscription_id="test-sub-id")

            clusters = provider.list_clusters(resource_group="test-rg", include_details=True)

            assert len(clusters) == 1
            assert clusters[0].name == "cluster-1"
            mock_aks.list_clusters.assert_called_once_with("test-rg", True)


class TestAzureProviderDatabaseOperations:
    """Test database operations."""

    def test_create_database(self, azure_credentials, mock_credential):
        """Test database creation."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService") as mock_db_class, \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Database service
            mock_db = Mock()
            mock_db_class.return_value = mock_db

            provider = AzureProvider(subscription_id="test-sub-id")

            config = DatabaseConfig(
                name="test-db",
                engine="postgres",
                engine_version="14",
                instance_class="GP_Gen5_2",
                region="eastus",
                master_username="admin",
                master_password="test_password",
                metadata={"resource_group": "test-rg"},
            )

            expected_database = Database(
                id="test-db",
                name="test-db",
                engine="postgres",
                engine_version="14",
                status="Creating",
                region="eastus",
                instance_class="GP_Gen5_2",
            )

            mock_db.create_database.return_value = expected_database

            database = provider.create_database(config)

            assert database.name == "test-db"
            assert database.engine == "postgres"
            assert database.status == "Creating"
            mock_db.create_database.assert_called_once_with(config)

    def test_get_database(self, azure_credentials, mock_credential):
        """Test getting database details."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService") as mock_db_class, \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Database service
            mock_db = Mock()
            mock_db_class.return_value = mock_db

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_database = Database(
                id="test-db",
                name="test-db",
                engine="postgres",
                engine_version="14",
                status="Ready",
                endpoint="test-db.postgres.database.azure.com",
                port=5432,
                region="eastus",
                instance_class="GP_Gen5_2",
            )

            mock_db.get_database_any_engine.return_value = expected_database

            database = provider.get_database("test-db", resource_group="test-rg")

            assert database.name == "test-db"
            assert database.status == "Ready"
            assert database.port == 5432
            mock_db.get_database_any_engine.assert_called_once_with("test-db", "test-rg")

    def test_delete_database(self, azure_credentials, mock_credential):
        """Test database deletion."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService") as mock_db_class, \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Database service
            mock_db = Mock()
            mock_db_class.return_value = mock_db
            mock_db.delete_database_any_engine.return_value = True

            provider = AzureProvider(subscription_id="test-sub-id")

            result = provider.delete_database("test-db", resource_group="test-rg", skip_final_snapshot=True)

            assert result is True
            mock_db.delete_database_any_engine.assert_called_once_with("test-db", "test-rg")

    def test_list_databases(self, azure_credentials, mock_credential):
        """Test listing databases."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService") as mock_db_class, \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Database service
            mock_db = Mock()
            mock_db_class.return_value = mock_db

            expected_databases = [
                Database(
                    id="db-1",
                    name="db-1",
                    engine="postgres",
                    engine_version="14",
                    status="Ready",
                    region="eastus",
                    instance_class="GP_Gen5_2",
                ),
                Database(
                    id="db-2",
                    name="db-2",
                    engine="mysql",
                    engine_version="8.0",
                    status="Ready",
                    region="westus",
                    instance_class="GP_Gen5_4",
                ),
            ]

            mock_db.list_all_databases.return_value = expected_databases

            provider = AzureProvider(subscription_id="test-sub-id")

            databases = provider.list_databases(resource_group="test-rg")

            assert len(databases) == 2
            assert databases[0].engine == "postgres"
            assert databases[1].engine == "mysql"
            mock_db.list_all_databases.assert_called_once_with("test-rg")


class TestAzureProviderStorageOperations:
    """Test storage operations."""

    def test_create_storage(self, azure_credentials, mock_credential):
        """Test storage account creation."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService") as mock_storage_class, \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Storage service
            mock_storage = Mock()
            mock_storage_class.return_value = mock_storage

            provider = AzureProvider(subscription_id="test-sub-id")

            config = StorageConfig(
                name="teststorageacct",
                region="eastus",
                versioning_enabled=True,
                encryption_enabled=True,
                metadata={"resource_group": "test-rg"},
            )

            expected_storage = Storage(
                id="teststorageacct",
                name="teststorageacct",
                region="eastus",
                versioning_enabled=True,
                encryption_enabled=True,
            )

            mock_storage.create_storage.return_value = expected_storage

            storage = provider.create_storage(config)

            assert storage.name == "teststorageacct"
            assert storage.versioning_enabled is True
            assert storage.encryption_enabled is True
            mock_storage.create_storage.assert_called_once_with(config)

    def test_get_storage(self, azure_credentials, mock_credential):
        """Test getting storage details."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService") as mock_storage_class, \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Storage service
            mock_storage = Mock()
            mock_storage_class.return_value = mock_storage

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_storage = Storage(
                id="teststorageacct",
                name="teststorageacct",
                region="eastus",
                size_bytes=1024000,
                object_count=100,
                versioning_enabled=True,
                encryption_enabled=True,
            )

            mock_storage.get_storage.return_value = expected_storage

            storage = provider.get_storage("teststorageacct", resource_group="test-rg")

            assert storage.name == "teststorageacct"
            assert storage.object_count == 100
            mock_storage.get_storage.assert_called_once_with("teststorageacct", "test-rg")

    def test_delete_storage(self, azure_credentials, mock_credential):
        """Test storage deletion."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService") as mock_storage_class, \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Storage service
            mock_storage = Mock()
            mock_storage_class.return_value = mock_storage
            mock_storage.delete_storage.return_value = True

            provider = AzureProvider(subscription_id="test-sub-id")

            result = provider.delete_storage("teststorageacct", resource_group="test-rg", force=True)

            assert result is True
            mock_storage.delete_storage.assert_called_once_with("teststorageacct", "test-rg", True)

    def test_list_storage(self, azure_credentials, mock_credential):
        """Test listing storage accounts."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService") as mock_storage_class, \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Storage service
            mock_storage = Mock()
            mock_storage_class.return_value = mock_storage

            expected_storage_accounts = [
                Storage(id="storage-1", name="storage-1", region="eastus"),
                Storage(id="storage-2", name="storage-2", region="westus"),
            ]

            mock_storage.list_storage.return_value = expected_storage_accounts

            provider = AzureProvider(subscription_id="test-sub-id")

            storage_accounts = provider.list_storage(resource_group="test-rg", include_details=False)

            assert len(storage_accounts) == 2
            assert storage_accounts[0].name == "storage-1"
            mock_storage.list_storage.assert_called_once_with("test-rg", False)


class TestAzureProviderCostAndMetrics:
    """Test cost and metrics operations."""

    def test_get_cost_data(self, azure_credentials, mock_credential):
        """Test getting cost data."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService") as mock_cost_class:

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Cost Management service
            mock_cost = Mock()
            mock_cost_class.return_value = mock_cost

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_cost_data = CostData(
                start_date=datetime(2024, 1, 1),
                end_date=datetime(2024, 1, 31),
                total_cost=1500.75,
                currency="USD",
                breakdown={"Compute": 800.0, "Storage": 300.0, "Database": 400.75},
            )

            mock_cost.get_cost_data.return_value = expected_cost_data

            cost_data = provider.get_cost_data("THIS_MONTH", "MONTHLY")

            assert cost_data.total_cost == 1500.75
            assert cost_data.currency == "USD"
            assert len(cost_data.breakdown) == 3
            assert cost_data.breakdown["Compute"] == 800.0
            mock_cost.get_cost_data.assert_called_once_with("THIS_MONTH", "MONTHLY")

    def test_get_cost_forecast(self, azure_credentials, mock_credential):
        """Test getting cost forecast."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService"), \
             patch("src.providers.azure_provider.CostManagementService") as mock_cost_class:

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Cost Management service
            mock_cost = Mock()
            mock_cost_class.return_value = mock_cost

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_forecast = {
                "forecasted_cost": 2000.0,
                "currency": "USD",
                "days": 30,
                "confidence": 0.85,
            }

            mock_cost.get_cost_forecast.return_value = expected_forecast

            forecast = provider.get_cost_forecast(days=30)

            assert forecast["forecasted_cost"] == 2000.0
            assert forecast["currency"] == "USD"
            assert forecast["days"] == 30
            mock_cost.get_cost_forecast.assert_called_once_with(30)

    def test_get_metrics(self, azure_credentials, mock_credential):
        """Test getting Azure Monitor metrics."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService") as mock_monitor_class, \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Monitor service
            mock_monitor = Mock()
            mock_monitor_class.return_value = mock_monitor

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_metrics = {
                "metric_name": "Percentage CPU",
                "resource_id": "/subscriptions/test-sub/resourceGroups/test-rg/providers/Microsoft.Compute/virtualMachines/test-vm",
                "aggregation": "Average",
                "datapoints": [
                    {"timestamp": "2024-01-01T00:00:00Z", "average": 45.5},
                    {"timestamp": "2024-01-01T01:00:00Z", "average": 52.3},
                ],
            }

            mock_monitor.get_metrics.return_value = expected_metrics

            metrics = provider.get_metrics(
                resource_id="/subscriptions/test-sub/resourceGroups/test-rg/providers/Microsoft.Compute/virtualMachines/test-vm",
                metric_name="Percentage CPU",
                start_time="2024-01-01T00:00:00Z",
                end_time="2024-01-02T00:00:00Z",
                aggregation="Average",
            )

            assert metrics["metric_name"] == "Percentage CPU"
            assert len(metrics["datapoints"]) == 2
            assert metrics["datapoints"][0]["average"] == 45.5
            mock_monitor.get_metrics.assert_called_once()

    def test_get_metrics_default_aggregation(self, azure_credentials, mock_credential):
        """Test getting metrics with default aggregation."""
        with patch("src.providers.azure_provider.DefaultAzureCredential") as mock_cred_class, \
             patch("azure.mgmt.resource.ResourceManagementClient") as mock_rm_client, \
             patch("src.providers.azure_provider.AKSService"), \
             patch("src.providers.azure_provider.DatabaseService"), \
             patch("src.providers.azure_provider.StorageService"), \
             patch("src.providers.azure_provider.MonitorService") as mock_monitor_class, \
             patch("src.providers.azure_provider.CostManagementService"):

            # Setup mocks
            mock_cred_class.return_value = mock_credential
            mock_client = MagicMock()
            mock_client.resource_groups.list.return_value = iter([])
            mock_rm_client.return_value = mock_client

            # Mock Monitor service
            mock_monitor = Mock()
            mock_monitor_class.return_value = mock_monitor

            provider = AzureProvider(subscription_id="test-sub-id")

            expected_metrics = {
                "metric_name": "Memory Usage",
                "aggregation": "Average",
                "datapoints": [],
            }

            mock_monitor.get_metrics.return_value = expected_metrics

            # Call without aggregation parameter
            metrics = provider.get_metrics(
                resource_id="/subscriptions/test-sub/resourceGroups/test-rg/providers/Microsoft.Compute/virtualMachines/test-vm",
                metric_name="Memory Usage",
                start_time="2024-01-01T00:00:00Z",
                end_time="2024-01-02T00:00:00Z",
            )

            # Verify default aggregation "Average" was used
            call_args = mock_monitor.get_metrics.call_args
            assert call_args[0][4] == "Average"  # Fifth argument is aggregation
