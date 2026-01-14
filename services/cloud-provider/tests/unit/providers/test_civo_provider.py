"""Unit tests for Civo Provider."""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime

from src.providers.civo_provider import CivoProvider
from src.interfaces.provider import ClusterConfig, DatabaseConfig, StorageConfig
from src.interfaces.models import Cluster, Database, Storage, CostData
from src.exceptions import AuthenticationError, CloudProviderError, ResourceNotFoundError


@pytest.fixture
def mock_civo_client():
    """Create a mock Civo client."""
    client = Mock()
    
    # Mock quota endpoint for credential verification
    client.quota = Mock()
    client.quota.get = Mock(return_value={
        "instance_count_usage": 2,
        "instance_count_limit": 10,
    })
    
    # Mock kubernetes endpoints
    client.kubernetes = Mock()
    client.kubernetes.create = Mock(return_value={
        "id": "test-cluster-123",
        "name": "test-cluster",
        "status": "creating",
        "kubernetes_version": "1.28.0",
        "api_endpoint": "https://test.k8s.civo.com",
        "region": "NYC1",
        "num_target_nodes": 3,
        "created_at": "2024-01-14T10:00:00Z",
    })
    client.kubernetes.get = Mock(return_value={
        "id": "test-cluster-123",
        "name": "test-cluster",
        "status": "running",
        "kubernetes_version": "1.28.0",
        "api_endpoint": "https://test.k8s.civo.com",
        "region": "NYC1",
        "num_target_nodes": 3,
        "created_at": "2024-01-14T10:00:00Z",
    })
    client.kubernetes.list = Mock(return_value=[
        {
            "id": "cluster-1",
            "name": "cluster-1",
            "status": "running",
            "kubernetes_version": "1.28.0",
            "region": "NYC1",
            "num_target_nodes": 3,
            "created_at": "2024-01-14T10:00:00Z",
        },
        {
            "id": "cluster-2",
            "name": "cluster-2",
            "status": "running",
            "kubernetes_version": "1.28.0",
            "region": "NYC1",
            "num_target_nodes": 2,
            "created_at": "2024-01-14T11:00:00Z",
        },
    ])
    client.kubernetes.delete = Mock(return_value={"result": "success"})
    
    # Mock instances endpoints (optional, may not exist)
    client.instances = Mock()
    client.instances.list = Mock(return_value=[])
    
    # Mock objectstore endpoints
    client.objectstore = Mock()
    client.objectstore.create = Mock(return_value={
        "id": "store-123",
        "name": "test-store",
        "max_size_gb": 500,
        "bucket_url": "https://test-store.objectstore.civo.com",
        "status": "ready",
    })
    client.objectstore.get = Mock(return_value={
        "id": "store-123",
        "name": "test-store",
        "region": "NYC1",
        "size_gb": 10,
        "max_size_gb": 500,
        "bucket_url": "https://test-store.objectstore.civo.com",
        "created_at": "2024-01-14T10:00:00Z",
        "status": "ready",
    })
    client.objectstore.list = Mock(return_value=[
        {
            "id": "store-1",
            "name": "store-1",
            "region": "NYC1",
            "size_gb": 5,
            "max_size_gb": 500,
            "created_at": "2024-01-14T10:00:00Z",
            "status": "ready",
        },
    ])
    client.objectstore.delete = Mock(return_value={"result": "success"})
    
    return client


@pytest.fixture
def civo_provider(mock_civo_client):
    """Create a CivoProvider instance with mocked client."""
    with patch("src.providers.civo_provider.Civo", return_value=mock_civo_client):
        provider = CivoProvider(api_key="test-api-key", region="NYC1")
        return provider


class TestCivoProviderInitialization:
    """Test Civo Provider initialization and authentication."""

    def test_init_with_api_key(self, mock_civo_client):
        """Test initialization with explicit API key."""
        with patch("src.providers.civo_provider.Civo", return_value=mock_civo_client):
            provider = CivoProvider(api_key="test-api-key", region="NYC1")
            
            assert provider.region == "NYC1"
            assert provider.kubernetes is not None
            assert provider.database is not None
            assert provider.objectstore is not None
            assert provider.billing is not None

    def test_init_with_env_var(self, mock_civo_client):
        """Test initialization with environment variable."""
        import os
        os.environ["CIVO_TOKEN"] = "test-token"
        
        with patch("src.providers.civo_provider.Civo", return_value=mock_civo_client):
            provider = CivoProvider(region="LON1")
            assert provider.region == "LON1"
        
        del os.environ["CIVO_TOKEN"]

    def test_init_default_region(self, mock_civo_client):
        """Test initialization with default region."""
        with patch("src.providers.civo_provider.Civo", return_value=mock_civo_client):
            provider = CivoProvider(api_key="test-key")
            assert provider.region in CivoProvider.VALID_REGIONS

    def test_init_no_api_key(self):
        """Test initialization fails without API key."""
        import os
        # Clear any existing token
        if "CIVO_TOKEN" in os.environ:
            del os.environ["CIVO_TOKEN"]
        
        with pytest.raises(AuthenticationError) as exc_info:
            CivoProvider()
        
        assert "No Civo API key found" in str(exc_info.value)

    def test_init_invalid_api_key(self):
        """Test initialization fails with invalid API key."""
        mock_client = Mock()
        mock_client.quota.get.side_effect = Exception("401 Unauthorized")
        
        with patch("src.providers.civo_provider.Civo", return_value=mock_client):
            with pytest.raises(AuthenticationError) as exc_info:
                CivoProvider(api_key="invalid-key")
            
            assert "Invalid API key" in str(exc_info.value)


class TestCivoProviderClusters:
    """Test Civo Provider cluster operations."""

    def test_create_cluster(self, civo_provider, mock_civo_client):
        """Test cluster creation."""
        config = ClusterConfig(
            name="test-cluster",
            region="NYC1",
            version="1.28.0",
            node_count=3,
            node_instance_type="g4s.kube.medium",
        )
        
        cluster = civo_provider.create_cluster(config)
        
        assert isinstance(cluster, Cluster)
        assert cluster.name == "test-cluster"
        assert cluster.status == "creating"
        assert cluster.version == "1.28.0"
        assert cluster.node_count == 3
        mock_civo_client.kubernetes.create.assert_called_once()

    def test_get_cluster(self, civo_provider, mock_civo_client):
        """Test getting cluster details."""
        cluster = civo_provider.get_cluster("test-cluster-123")
        
        assert isinstance(cluster, Cluster)
        assert cluster.id == "test-cluster-123"
        assert cluster.status == "running"
        mock_civo_client.kubernetes.get.assert_called_once_with("test-cluster-123")

    def test_list_clusters(self, civo_provider, mock_civo_client):
        """Test listing clusters."""
        clusters = civo_provider.list_clusters()
        
        assert len(clusters) == 2
        assert all(isinstance(c, Cluster) for c in clusters)
        assert clusters[0].name == "cluster-1"
        assert clusters[1].name == "cluster-2"
        mock_civo_client.kubernetes.list.assert_called_once()

    def test_delete_cluster(self, civo_provider, mock_civo_client):
        """Test cluster deletion."""
        result = civo_provider.delete_cluster("test-cluster-123")
        
        assert result is True
        mock_civo_client.kubernetes.delete.assert_called_once_with("test-cluster-123")

    def test_get_cluster_not_found(self, civo_provider, mock_civo_client):
        """Test getting non-existent cluster."""
        mock_civo_client.kubernetes.get.side_effect = Exception("404 not found")
        
        with pytest.raises(ResourceNotFoundError):
            civo_provider.get_cluster("nonexistent")


class TestCivoProviderStorage:
    """Test Civo Provider storage operations."""

    def test_create_storage(self, civo_provider, mock_civo_client):
        """Test storage creation."""
        config = StorageConfig(
            name="test-store",
            region="NYC1",
            encryption_enabled=True,
        )
        
        storage = civo_provider.create_storage(config)
        
        assert isinstance(storage, Storage)
        assert storage.name == "test-store"
        assert storage.encryption_enabled is True
        mock_civo_client.objectstore.create.assert_called_once()

    def test_get_storage(self, civo_provider, mock_civo_client):
        """Test getting storage details."""
        storage = civo_provider.get_storage("store-123")
        
        assert isinstance(storage, Storage)
        assert storage.id == "store-123"
        assert storage.name == "test-store"
        mock_civo_client.objectstore.get.assert_called_once_with("store-123")

    def test_list_storage(self, civo_provider, mock_civo_client):
        """Test listing storage buckets."""
        storages = civo_provider.list_storage()
        
        assert len(storages) == 1
        assert all(isinstance(s, Storage) for s in storages)
        assert storages[0].name == "store-1"
        mock_civo_client.objectstore.list.assert_called_once()

    def test_delete_storage(self, civo_provider, mock_civo_client):
        """Test storage deletion."""
        result = civo_provider.delete_storage("store-123")
        
        assert result is True
        mock_civo_client.objectstore.delete.assert_called_once_with("store-123")


class TestCivoProviderDatabase:
    """Test Civo Provider database operations."""

    def test_create_database(self, civo_provider):
        """Test database creation."""
        config = DatabaseConfig(
            name="test-db",
            engine="postgresql",
            engine_version="14",
            instance_class="small",
            region="NYC1",
            metadata={"cluster_id": "cluster-123"},
        )
        
        database = civo_provider.create_database(config)
        
        assert isinstance(database, Database)
        assert database.name == "test-db"
        assert database.engine == "postgresql"

    def test_create_database_no_cluster(self, civo_provider):
        """Test database creation without cluster_id fails."""
        config = DatabaseConfig(
            name="test-db",
            engine="postgresql",
            engine_version="14",
            instance_class="small",
            region="NYC1",
        )
        
        with pytest.raises(CloudProviderError):
            civo_provider.create_database(config)

    def test_list_databases(self, civo_provider):
        """Test listing databases."""
        databases = civo_provider.list_databases()
        
        assert isinstance(databases, list)
        # Civo doesn't have separate managed databases
        assert len(databases) == 0


class TestCivoProviderCosts:
    """Test Civo Provider cost operations."""

    def test_get_cost_data(self, civo_provider, mock_civo_client):
        """Test getting cost data."""
        cost_data = civo_provider.get_cost_data("LAST_30_DAYS", "MONTHLY")
        
        assert isinstance(cost_data, CostData)
        assert cost_data.currency == "USD"
        assert cost_data.total_cost >= 0
        assert "kubernetes_clusters" in cost_data.breakdown

    def test_get_quota(self, civo_provider, mock_civo_client):
        """Test getting quota information."""
        quota = civo_provider.get_quota()
        
        assert isinstance(quota, dict)
        assert "instance_count_usage" in quota
        assert "instance_count_limit" in quota


class TestCivoProviderMetrics:
    """Test Civo Provider metrics operations."""

    def test_get_metrics(self, civo_provider):
        """Test getting metrics."""
        metrics = civo_provider.get_metrics(
            resource_id="cluster-123",
            metric_name="cpu_usage",
            start_time="2024-01-14T00:00:00Z",
            end_time="2024-01-14T23:59:59Z",
        )
        
        assert isinstance(metrics, dict)
        assert "resource_id" in metrics
        assert "note" in metrics  # Civo returns a note about Prometheus


class TestCivoProviderRateLimiting:
    """Test rate limiting behavior."""

    def test_rate_limiter_initialization(self, mock_civo_client):
        """Test that rate limiter is configured correctly."""
        with patch("src.providers.civo_provider.Civo", return_value=mock_civo_client):
            provider = CivoProvider(api_key="test-key", rate_limit_calls=5)
            
            assert provider.rate_limiter.max_calls == 5
            assert provider.rate_limiter.time_window == 1.0


class TestCivoProviderErrorHandling:
    """Test error handling in Civo provider."""

    def test_cluster_creation_already_exists(self, civo_provider, mock_civo_client):
        """Test handling of duplicate cluster creation."""
        from src.exceptions import ResourceAlreadyExistsError
        
        mock_civo_client.kubernetes.create.side_effect = Exception("Cluster already exists")
        
        config = ClusterConfig(
            name="duplicate",
            region="NYC1",
            version="1.28.0",
            node_count=2,
        )
        
        with pytest.raises(ResourceAlreadyExistsError):
            civo_provider.create_cluster(config)

    def test_cluster_creation_validation_error(self, civo_provider, mock_civo_client):
        """Test handling of validation errors during cluster creation."""
        from src.exceptions import ValidationError
        
        mock_civo_client.kubernetes.create.side_effect = Exception("invalid node count")
        
        config = ClusterConfig(
            name="invalid",
            region="NYC1",
            version="1.28.0",
            node_count=-1,
        )
        
        with pytest.raises(ValidationError):
            civo_provider.create_cluster(config)

    def test_storage_creation_already_exists(self, civo_provider, mock_civo_client):
        """Test handling of duplicate storage creation."""
        from src.exceptions import ResourceAlreadyExistsError
        
        mock_civo_client.objectstore.create.side_effect = Exception("already exists")
        
        config = StorageConfig(name="duplicate", region="NYC1")
        
        with pytest.raises(ResourceAlreadyExistsError):
            civo_provider.create_storage(config)

    def test_storage_not_found(self, civo_provider, mock_civo_client):
        """Test handling of non-existent storage."""
        mock_civo_client.objectstore.get.side_effect = Exception("404 not found")
        
        with pytest.raises(ResourceNotFoundError):
            civo_provider.get_storage("nonexistent")

    def test_delete_nonexistent_cluster(self, civo_provider, mock_civo_client):
        """Test deleting non-existent cluster."""
        mock_civo_client.kubernetes.delete.side_effect = Exception("not found")
        
        with pytest.raises(ResourceNotFoundError):
            civo_provider.delete_cluster("nonexistent")

    def test_delete_nonexistent_storage(self, civo_provider, mock_civo_client):
        """Test deleting non-existent storage."""
        mock_civo_client.objectstore.delete.side_effect = Exception("404")
        
        with pytest.raises(ResourceNotFoundError):
            civo_provider.delete_storage("nonexistent")


class TestCivoProviderAdvanced:
    """Test advanced Civo provider features."""

    def test_create_cluster_with_applications(self, civo_provider, mock_civo_client):
        """Test cluster creation with applications."""
        config = ClusterConfig(
            name="app-cluster",
            region="NYC1",
            version="1.28.0",
            node_count=3,
            metadata={
                "applications": "PostgreSQL:5GB,Redis:5GB",
                "cni_plugin": "flannel",
            }
        )
        
        cluster = civo_provider.create_cluster(config)
        
        assert isinstance(cluster, Cluster)
        # Verify applications were passed to the API
        call_kwargs = mock_civo_client.kubernetes.create.call_args[1]
        assert "applications" in call_kwargs

    def test_create_cluster_with_network(self, civo_provider, mock_civo_client):
        """Test cluster creation with custom network."""
        config = ClusterConfig(
            name="network-cluster",
            region="NYC1",
            version="1.28.0",
            node_count=2,
            vpc_id="network-123",
        )
        
        cluster = civo_provider.create_cluster(config)
        
        assert isinstance(cluster, Cluster)
        call_kwargs = mock_civo_client.kubernetes.create.call_args[1]
        assert call_kwargs["network_id"] == "network-123"

    def test_create_storage_with_max_size(self, civo_provider, mock_civo_client):
        """Test storage creation with custom max size."""
        config = StorageConfig(
            name="large-store",
            region="NYC1",
            metadata={"max_size_gb": 1000}
        )
        
        storage = civo_provider.create_storage(config)
        
        assert isinstance(storage, Storage)
        call_kwargs = mock_civo_client.objectstore.create.call_args[1]
        assert call_kwargs["max_size_gb"] == 1000

    def test_list_clusters_with_region_filter(self, civo_provider, mock_civo_client):
        """Test listing clusters with region filter."""
        mock_civo_client.kubernetes.list.return_value = [
            {
                "id": "cluster-nyc",
                "name": "cluster-nyc",
                "status": "running",
                "kubernetes_version": "1.28.0",
                "region": "NYC1",
                "num_target_nodes": 2,
                "created_at": "2024-01-14T10:00:00Z",
            },
            {
                "id": "cluster-lon",
                "name": "cluster-lon",
                "status": "running",
                "kubernetes_version": "1.28.0",
                "region": "LON1",
                "num_target_nodes": 2,
                "created_at": "2024-01-14T10:00:00Z",
            },
        ]
        
        # Filter by NYC1
        clusters = civo_provider.list_clusters(region="NYC1")
        
        assert len(clusters) == 1
        assert clusters[0].region == "NYC1"

    def test_list_storage_with_region_filter(self, civo_provider, mock_civo_client):
        """Test listing storage with region filter."""
        mock_civo_client.objectstore.list.return_value = [
            {
                "id": "store-nyc",
                "name": "store-nyc",
                "region": "NYC1",
                "size_gb": 5,
                "max_size_gb": 500,
                "created_at": "2024-01-14T10:00:00Z",
                "status": "ready",
            },
            {
                "id": "store-lon",
                "name": "store-lon",
                "region": "LON1",
                "size_gb": 5,
                "max_size_gb": 500,
                "created_at": "2024-01-14T10:00:00Z",
                "status": "ready",
            },
        ]
        
        # Filter by NYC1
        storages = civo_provider.list_storage(region="NYC1")
        
        assert len(storages) == 1
        assert storages[0].region == "NYC1"

    def test_database_unsupported_engine(self, civo_provider):
        """Test database creation with unsupported engine."""
        from src.exceptions import ValidationError
        
        config = DatabaseConfig(
            name="test-db",
            engine="oracle",  # Not supported
            engine_version="19c",
            instance_class="small",
            region="NYC1",
            metadata={"cluster_id": "cluster-123"},
        )
        
        with pytest.raises(ValidationError) as exc_info:
            civo_provider.create_database(config)
        
        assert "Unsupported database engine" in str(exc_info.value)
