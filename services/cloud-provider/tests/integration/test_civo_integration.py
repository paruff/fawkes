"""Integration tests for Civo Provider.

These tests run against real Civo infrastructure and require:
1. CIVO_TOKEN environment variable with valid API key
2. Active Civo account with sufficient quota
3. Will create and delete real resources (incurs costs)

Tests are skipped by default unless CIVO_TOKEN is set.
"""

import os
import pytest
import time
from datetime import datetime

from src.providers.civo_provider import CivoProvider
from src.interfaces.provider import ClusterConfig, StorageConfig, DatabaseConfig
from src.exceptions import CloudProviderError, ResourceNotFoundError


# Skip all tests in this file unless CIVO_TOKEN is set
pytestmark = pytest.mark.skipif(
    not os.getenv("CIVO_TOKEN"),
    reason="CIVO_TOKEN environment variable not set. Set it to run integration tests."
)


@pytest.fixture(scope="module")
def civo_provider():
    """Create a real Civo provider instance."""
    api_key = os.getenv("CIVO_TOKEN")
    region = os.getenv("CIVO_REGION", "NYC1")
    
    provider = CivoProvider(api_key=api_key, region=region)
    yield provider


@pytest.fixture
def unique_name():
    """Generate a unique name for test resources."""
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    return f"test-{timestamp}"


class TestCivoIntegrationCluster:
    """Integration tests for Civo cluster operations."""

    def test_cluster_lifecycle(self, civo_provider, unique_name):
        """Test complete cluster lifecycle: create, get, list, delete."""
        cluster_name = f"{unique_name}-cluster"
        
        try:
            # Create cluster
            config = ClusterConfig(
                name=cluster_name,
                region=civo_provider.region,
                version="1.28.0",
                node_count=2,
                node_instance_type="g4s.kube.small",
                tags={
                    "test": "integration",
                    "cleanup": "auto",
                }
            )
            
            print(f"\n🔨 Creating cluster: {cluster_name}")
            cluster = civo_provider.create_cluster(config)
            
            assert cluster is not None
            assert cluster.name == cluster_name
            assert cluster.status in ["creating", "ACTIVE"]
            cluster_id = cluster.id
            
            print(f"✅ Cluster created: {cluster_id}")
            
            # Wait a bit for cluster to initialize
            time.sleep(5)
            
            # Get cluster
            print(f"🔍 Getting cluster details: {cluster_id}")
            retrieved_cluster = civo_provider.get_cluster(cluster_id)
            assert retrieved_cluster.id == cluster_id
            assert retrieved_cluster.name == cluster_name
            
            print(f"✅ Cluster retrieved: {retrieved_cluster.status}")
            
            # List clusters
            print("📋 Listing all clusters")
            clusters = civo_provider.list_clusters()
            cluster_ids = [c.id for c in clusters]
            assert cluster_id in cluster_ids
            
            print(f"✅ Found {len(clusters)} clusters, including ours")
            
            # Delete cluster
            print(f"🗑️  Deleting cluster: {cluster_id}")
            result = civo_provider.delete_cluster(cluster_id)
            assert result is True
            
            print("✅ Cluster deleted successfully")
            
            # Verify deletion
            time.sleep(2)
            with pytest.raises(ResourceNotFoundError):
                civo_provider.get_cluster(cluster_id)
            
            print("✅ Verified cluster is deleted")
            
        except Exception as e:
            # Cleanup on error
            print(f"❌ Test failed: {e}")
            try:
                if 'cluster_id' in locals():
                    print(f"🧹 Cleaning up cluster: {cluster_id}")
                    civo_provider.delete_cluster(cluster_id)
            except:
                pass
            raise


class TestCivoIntegrationStorage:
    """Integration tests for Civo storage operations."""

    def test_storage_lifecycle(self, civo_provider, unique_name):
        """Test complete storage lifecycle: create, get, list, delete."""
        storage_name = f"{unique_name}-store"
        
        try:
            # Create storage
            config = StorageConfig(
                name=storage_name,
                region=civo_provider.region,
                metadata={"max_size_gb": 100}
            )
            
            print(f"\n🔨 Creating storage: {storage_name}")
            storage = civo_provider.create_storage(config)
            
            assert storage is not None
            assert storage.name == storage_name
            storage_id = storage.id
            
            print(f"✅ Storage created: {storage_id}")
            
            # Get storage
            print(f"🔍 Getting storage details: {storage_id}")
            retrieved_storage = civo_provider.get_storage(storage_id)
            assert retrieved_storage.id == storage_id
            assert retrieved_storage.name == storage_name
            
            print(f"✅ Storage retrieved")
            
            # List storage
            print("📋 Listing all storage")
            storages = civo_provider.list_storage()
            storage_ids = [s.id for s in storages]
            assert storage_id in storage_ids
            
            print(f"✅ Found {len(storages)} storage buckets, including ours")
            
            # Delete storage
            print(f"🗑️  Deleting storage: {storage_id}")
            result = civo_provider.delete_storage(storage_id)
            assert result is True
            
            print("✅ Storage deleted successfully")
            
            # Verify deletion
            time.sleep(2)
            with pytest.raises(ResourceNotFoundError):
                civo_provider.get_storage(storage_id)
            
            print("✅ Verified storage is deleted")
            
        except Exception as e:
            # Cleanup on error
            print(f"❌ Test failed: {e}")
            try:
                if 'storage_id' in locals():
                    print(f"🧹 Cleaning up storage: {storage_id}")
                    civo_provider.delete_storage(storage_id)
            except:
                pass
            raise


class TestCivoIntegrationCosts:
    """Integration tests for Civo cost operations."""

    def test_get_cost_data(self, civo_provider):
        """Test getting cost data."""
        print("\n💰 Getting cost data")
        cost_data = civo_provider.get_cost_data("LAST_30_DAYS", "MONTHLY")
        
        assert cost_data is not None
        assert cost_data.currency == "USD"
        assert cost_data.total_cost >= 0
        
        print(f"✅ Cost data retrieved: ${cost_data.total_cost:.2f}")
        print(f"   Breakdown: {cost_data.breakdown}")

    def test_get_quota(self, civo_provider):
        """Test getting account quota."""
        print("\n📊 Getting quota information")
        quota = civo_provider.get_quota()
        
        assert quota is not None
        assert isinstance(quota, dict)
        
        print(f"✅ Quota retrieved:")
        for key, value in quota.items():
            print(f"   {key}: {value}")


class TestCivoIntegrationDatabase:
    """Integration tests for Civo database operations."""

    @pytest.mark.skip(reason="Database deployment takes too long for CI/CD")
    def test_database_lifecycle(self, civo_provider, unique_name):
        """Test database lifecycle (skipped by default due to time)."""
        # This test would:
        # 1. Create a cluster first
        # 2. Deploy a database application to the cluster
        # 3. Verify the database is running
        # 4. Clean up
        
        # Skipped because it takes 5+ minutes to deploy a cluster
        # and then additional time to deploy the database
        pass


# Cleanup function to remove any leftover test resources
def cleanup_test_resources(provider):
    """Clean up any test resources that might be left over."""
    print("\n🧹 Cleaning up test resources...")
    
    # List and clean up test clusters
    try:
        clusters = provider.list_clusters()
        for cluster in clusters:
            if cluster.name.startswith("test-"):
                print(f"  Removing test cluster: {cluster.name}")
                try:
                    provider.delete_cluster(cluster.id)
                except:
                    pass
    except Exception as e:
        print(f"  Error cleaning clusters: {e}")
    
    # List and clean up test storage
    try:
        storages = provider.list_storage()
        for storage in storages:
            if storage.name.startswith("test-"):
                print(f"  Removing test storage: {storage.name}")
                try:
                    provider.delete_storage(storage.id)
                except:
                    pass
    except Exception as e:
        print(f"  Error cleaning storage: {e}")
    
    print("✅ Cleanup complete")


# Pytest hook to run cleanup after all tests
@pytest.fixture(scope="module", autouse=True)
def cleanup_after_tests(civo_provider):
    """Auto-cleanup after all tests complete."""
    yield
    
    # Only cleanup if CIVO_TOKEN is set and tests ran
    if os.getenv("CIVO_TOKEN"):
        cleanup_test_resources(civo_provider)
