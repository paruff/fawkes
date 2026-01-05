"""Integration tests for AWS Provider.

These tests run against real AWS services and require:
1. Valid AWS credentials configured
2. Appropriate IAM permissions
3. Test resources to be cleaned up after execution

Set SKIP_INTEGRATION_TESTS=1 to skip these tests.
"""

import pytest
import os
from datetime import datetime

from src.providers.aws_provider import AWSProvider
from src.interfaces.provider import StorageConfig
from src.exceptions import ResourceNotFoundError, ResourceAlreadyExistsError


# Skip integration tests if environment variable is set
pytestmark = pytest.mark.skipif(os.getenv("SKIP_INTEGRATION_TESTS", "0") == "1", reason="Integration tests disabled")


@pytest.fixture(scope="module")
def aws_provider():
    """Create AWS provider for integration tests."""
    # Use environment-configured credentials
    provider = AWSProvider(region=os.getenv("AWS_TEST_REGION", "us-west-2"))
    yield provider


@pytest.fixture(scope="module")
def test_prefix():
    """Generate unique test prefix to avoid conflicts."""
    return f"fawkes-test-{datetime.utcnow().strftime('%Y%m%d%H%M%S')}"


class TestAWSProviderIntegrationStorage:
    """Integration tests for S3 storage operations."""

    def test_storage_lifecycle(self, aws_provider, test_prefix):
        """Test complete storage lifecycle: create, get, list, delete."""
        bucket_name = f"{test_prefix}-bucket"

        try:
            # Create bucket
            config = StorageConfig(
                name=bucket_name,
                region="us-west-2",
                versioning_enabled=False,
                encryption_enabled=True,
                tags={"Environment": "test", "Purpose": "integration-test"},
            )

            storage = aws_provider.create_storage(config)
            assert storage.name == bucket_name
            assert storage.encryption_enabled is True

            # Get bucket
            retrieved_storage = aws_provider.get_storage(bucket_name, "us-west-2")
            assert retrieved_storage.name == bucket_name

            # List buckets (should include our test bucket)
            buckets = aws_provider.list_storage("us-west-2")
            bucket_names = [b.name for b in buckets]
            assert bucket_name in bucket_names

        finally:
            # Cleanup: Delete bucket
            try:
                aws_provider.delete_storage(bucket_name, "us-west-2", force=True)
            except Exception as e:
                print(f"Cleanup failed for bucket {bucket_name}: {e}")

    def test_storage_not_found(self, aws_provider):
        """Test that getting non-existent bucket raises error."""
        with pytest.raises(ResourceNotFoundError):
            aws_provider.get_storage("non-existent-bucket-12345", "us-west-2")

    def test_storage_already_exists(self, aws_provider, test_prefix):
        """Test that creating existing bucket raises error."""
        bucket_name = f"{test_prefix}-duplicate"

        try:
            config = StorageConfig(name=bucket_name, region="us-west-2")

            # Create bucket
            aws_provider.create_storage(config)

            # Try to create again
            with pytest.raises(ResourceAlreadyExistsError):
                aws_provider.create_storage(config)

        finally:
            # Cleanup
            try:
                aws_provider.delete_storage(bucket_name, "us-west-2", force=True)
            except Exception:
                pass


class TestAWSProviderIntegrationCost:
    """Integration tests for cost operations."""

    def test_get_cost_data(self, aws_provider):
        """Test getting cost data."""
        cost_data = aws_provider.get_cost_data("LAST_7_DAYS", "DAILY")

        assert cost_data.total_cost >= 0
        assert cost_data.currency == "USD"
        assert isinstance(cost_data.breakdown, dict)
        assert cost_data.start_date < cost_data.end_date

    def test_get_cost_forecast(self, aws_provider):
        """Test getting cost forecast."""
        forecast = aws_provider.get_cost_forecast(days=30)

        assert "forecast_amount" in forecast
        assert forecast["forecast_amount"] >= 0
        assert forecast["currency"] == "USD"


class TestAWSProviderIntegrationMetrics:
    """Integration tests for CloudWatch metrics."""

    def test_list_metrics(self, aws_provider):
        """Test listing CloudWatch metrics."""
        # This should return some metrics (may be empty in test account)
        # We're mainly testing that the API call works
        result = aws_provider.cloudwatch.list_metrics(namespace="AWS/EC2", region="us-west-2")

        assert isinstance(result, list)
        # Note: Result may be empty if no EC2 instances exist


# Note: EKS and RDS integration tests are commented out as they:
# 1. Take a long time to create/delete (10-30 minutes)
# 2. Are expensive to run
# 3. Require extensive IAM permissions
#
# Uncomment and run manually when needed:
#
# class TestAWSProviderIntegrationEKS:
#     """Integration tests for EKS operations (expensive, slow)."""
#
#     @pytest.mark.slow
#     @pytest.mark.expensive
#     def test_eks_cluster_lifecycle(self, aws_provider, test_prefix):
#         """Test EKS cluster lifecycle (WARNING: Takes ~15 minutes, costs money)."""
#         cluster_name = f"{test_prefix}-eks"
#
#         try:
#             config = ClusterConfig(
#                 name=cluster_name,
#                 region="us-west-2",
#                 version="1.28",
#                 subnet_ids=["subnet-xxxxx", "subnet-yyyyy"],  # Replace with real subnet IDs
#                 metadata={"role_arn": "arn:aws:iam::xxxx:role/eks-role"}  # Replace with real role
#             )
#
#             cluster = aws_provider.create_cluster(config)
#             assert cluster.name == cluster_name
#
#             # Wait for cluster to be active (would need polling logic)
#             # ...
#
#         finally:
#             try:
#                 aws_provider.delete_cluster(cluster_name, "us-west-2")
#             except Exception as e:
#                 print(f"Cleanup failed: {e}")
