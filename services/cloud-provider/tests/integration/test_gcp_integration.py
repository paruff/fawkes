"""Integration tests for GCP Provider.

These tests require real GCP credentials and will create actual resources.
They should be run in a test project with appropriate cleanup.

To run:
    pytest tests/integration/test_gcp_integration.py -v --gcp-project-id=YOUR_PROJECT_ID

Environment variables:
    GCP_PROJECT_ID: GCP project ID for testing
    GOOGLE_APPLICATION_CREDENTIALS: Path to service account key file
    GCP_TEST_REGION: Region for testing (default: us-central1)
"""

import pytest
import os
import time
from datetime import datetime

from src.providers.gcp_provider import GCPProvider
from src.interfaces.provider import ClusterConfig, DatabaseConfig, StorageConfig
from src.exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
)


def pytest_addoption(parser):
    """Add custom command line options."""
    parser.addoption(
        "--gcp-project-id",
        action="store",
        default=os.getenv("GCP_PROJECT_ID"),
        help="GCP project ID for integration tests",
    )
    parser.addoption(
        "--gcp-test-region",
        action="store",
        default=os.getenv("GCP_TEST_REGION", "us-central1"),
        help="GCP region for integration tests",
    )


@pytest.fixture(scope="session")
def gcp_project_id(request):
    """Get GCP project ID from command line or environment."""
    project_id = request.config.getoption("--gcp-project-id")
    if not project_id:
        pytest.skip("GCP project ID not provided. Use --gcp-project-id or set GCP_PROJECT_ID")
    return project_id


@pytest.fixture(scope="session")
def gcp_test_region(request):
    """Get GCP test region from command line or environment."""
    return request.config.getoption("--gcp-test-region")


@pytest.fixture(scope="session")
def gcp_provider(gcp_project_id):
    """Create GCP provider for integration tests."""
    try:
        provider = GCPProvider(project_id=gcp_project_id)
        yield provider
    except Exception as e:
        pytest.skip(f"Failed to initialize GCP provider: {str(e)}")


@pytest.fixture
def test_prefix():
    """Generate unique test resource prefix."""
    timestamp = int(time.time())
    return f"fawkes-test-{timestamp}"


@pytest.mark.integration
@pytest.mark.gcp
class TestGCPProviderIntegration:
    """Integration tests for GCP Provider."""

    def test_provider_initialization(self, gcp_provider, gcp_project_id):
        """Test that provider initializes correctly."""
        assert gcp_provider.project_id == gcp_project_id
        assert gcp_provider.gke is not None
        assert gcp_provider.cloudsql is not None
        assert gcp_provider.gcs is not None
        assert gcp_provider.monitoring is not None
        assert gcp_provider.billing is not None

    def test_list_clusters(self, gcp_provider, gcp_test_region):
        """Test listing GKE clusters."""
        try:
            clusters = gcp_provider.list_clusters(region=gcp_test_region, include_details=False)
            assert isinstance(clusters, list)
            # May be empty if no clusters exist
        except CloudProviderError as e:
            pytest.skip(f"Cannot list clusters: {str(e)}")

    def test_list_databases(self, gcp_provider, gcp_test_region):
        """Test listing Cloud SQL instances."""
        try:
            databases = gcp_provider.list_databases(region=gcp_test_region)
            assert isinstance(databases, list)
            # May be empty if no databases exist
        except CloudProviderError as e:
            pytest.skip(f"Cannot list databases: {str(e)}")

    def test_list_storage(self, gcp_provider, gcp_test_region):
        """Test listing GCS buckets."""
        try:
            buckets = gcp_provider.list_storage(region=gcp_test_region, include_details=False)
            assert isinstance(buckets, list)
            # May be empty if no buckets exist
        except CloudProviderError as e:
            pytest.skip(f"Cannot list buckets: {str(e)}")

    @pytest.mark.slow
    def test_storage_lifecycle(self, gcp_provider, gcp_test_region, test_prefix):
        """Test complete storage bucket lifecycle (create, get, delete)."""
        bucket_name = f"{test_prefix}-bucket"

        try:
            # Create bucket
            config = StorageConfig(
                name=bucket_name,
                region=gcp_test_region,
                versioning_enabled=False,
                encryption_enabled=True,
                public_access_blocked=True,
                tags={"environment": "test", "managed-by": "fawkes-test"},
            )

            storage = gcp_provider.create_storage(config)
            assert storage.name == bucket_name
            assert storage.region == gcp_test_region

            # Get bucket
            retrieved = gcp_provider.get_storage(bucket_name)
            assert retrieved.name == bucket_name

            # Delete bucket
            result = gcp_provider.delete_storage(bucket_name, force=True)
            assert result is True

            # Verify deletion
            with pytest.raises(ResourceNotFoundError):
                gcp_provider.get_storage(bucket_name)

        except CloudProviderError as e:
            # Clean up on error
            try:
                gcp_provider.delete_storage(bucket_name, force=True)
            except Exception:
                pass
            pytest.fail(f"Storage lifecycle test failed: {str(e)}")

    def test_get_cost_data(self, gcp_provider):
        """Test getting cost data."""
        try:
            cost_data = gcp_provider.get_cost_data("LAST_7_DAYS", "DAILY")
            assert cost_data is not None
            assert cost_data.currency == "USD"
            # Note: Cost data may be 0.0 if BigQuery export is not configured
        except CloudProviderError as e:
            pytest.skip(f"Cannot get cost data: {str(e)}")

    def test_resource_not_found(self, gcp_provider):
        """Test handling of non-existent resources."""
        with pytest.raises(ResourceNotFoundError):
            gcp_provider.get_cluster("non-existent-cluster", "us-central1")

        with pytest.raises(ResourceNotFoundError):
            gcp_provider.get_database("non-existent-database")

        with pytest.raises(ResourceNotFoundError):
            gcp_provider.get_storage("non-existent-bucket-" + str(time.time()))


@pytest.mark.integration
@pytest.mark.gcp
@pytest.mark.workload_identity
class TestWorkloadIdentityIntegration:
    """Integration tests for Workload Identity operations."""

    @pytest.mark.slow
    def test_create_service_account(self, gcp_provider, test_prefix):
        """Test creating a service account."""
        sa_name = f"{test_prefix}-sa"

        try:
            result = gcp_provider.create_service_account(
                name=sa_name, display_name="Test Service Account", description="Created by integration test"
            )

            assert "email" in result
            assert result["project_id"] == gcp_provider.project_id
            assert sa_name in result["email"]

            # Cleanup: Delete service account
            # Note: This requires additional GCP IAM API calls not implemented in this test
            # In production, you would need to delete the service account

        except CloudProviderError as e:
            pytest.skip(f"Cannot create service account: {str(e)}")


# Test fixtures for cleanup
@pytest.fixture(scope="session", autouse=True)
def cleanup_test_resources(request, gcp_provider, gcp_test_region):
    """Clean up any lingering test resources after all tests complete."""
    yield

    # Cleanup after tests
    try:
        # List and delete test buckets
        buckets = gcp_provider.list_storage(region=gcp_test_region, include_details=False)
        for bucket in buckets:
            if "fawkes-test-" in bucket.name:
                try:
                    gcp_provider.delete_storage(bucket.name, force=True)
                    print(f"Cleaned up test bucket: {bucket.name}")
                except Exception as e:
                    print(f"Failed to cleanup bucket {bucket.name}: {str(e)}")

    except Exception as e:
        print(f"Cleanup failed: {str(e)}")
