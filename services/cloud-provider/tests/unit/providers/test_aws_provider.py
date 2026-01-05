"""Unit tests for AWS Provider."""
import pytest
import boto3
from unittest.mock import Mock, patch, MagicMock
from moto import mock_aws
from botocore.exceptions import ClientError, NoCredentialsError

from src.providers.aws_provider import AWSProvider
from src.interfaces.provider import ClusterConfig, DatabaseConfig, StorageConfig
from src.exceptions import AuthenticationError, ResourceNotFoundError


@pytest.fixture
def aws_credentials():
    """Mock AWS credentials for testing."""
    import os

    os.environ["AWS_ACCESS_KEY_ID"] = "testing"
    os.environ["AWS_SECRET_ACCESS_KEY"] = "testing"
    os.environ["AWS_SECURITY_TOKEN"] = "testing"
    os.environ["AWS_SESSION_TOKEN"] = "testing"
    os.environ["AWS_DEFAULT_REGION"] = "us-east-1"


@pytest.fixture
def mock_session():
    """Create a mock boto3 session."""
    session = Mock(spec=boto3.Session)
    return session


class TestAWSProviderInitialization:
    """Test AWS Provider initialization and authentication."""

    @mock_aws
    def test_init_with_credentials(self, aws_credentials):
        """Test initialization with explicit credentials."""
        provider = AWSProvider(
            region="us-west-2",
            access_key_id="test_key",
            secret_access_key="test_secret",
        )

        assert provider.region == "us-west-2"
        assert provider.eks is not None
        assert provider.rds is not None
        assert provider.s3 is not None
        assert provider.cloudwatch is not None
        assert provider.cost_explorer is not None

    @mock_aws
    def test_init_with_profile(self, aws_credentials):
        """Test initialization with AWS profile."""
        with patch("boto3.Session") as mock_session_class:
            mock_session = MagicMock()
            mock_session_class.return_value = mock_session

            # Mock STS client for credential verification
            mock_sts = MagicMock()
            mock_sts.get_caller_identity.return_value = {"Arn": "arn:aws:iam::123456789012:user/test"}
            mock_session.client.return_value = mock_sts

            provider = AWSProvider(profile_name="test-profile", region="us-east-1")

            mock_session_class.assert_called_once()
            call_kwargs = mock_session_class.call_args[1]
            assert call_kwargs["profile_name"] == "test-profile"
            assert call_kwargs["region_name"] == "us-east-1"

    @mock_aws
    def test_init_default_region(self, aws_credentials):
        """Test initialization with default region."""
        provider = AWSProvider()
        assert provider.region == "us-east-1"

    def test_init_no_credentials(self):
        """Test initialization fails without credentials."""
        import os

        # Clear AWS environment variables
        for key in list(os.environ.keys()):
            if key.startswith("AWS_"):
                del os.environ[key]

        with pytest.raises(AuthenticationError) as exc_info:
            AWSProvider()

        assert "No AWS credentials found" in str(exc_info.value)

    @mock_aws
    def test_assume_role(self, aws_credentials):
        """Test IAM role assumption."""
        with patch("boto3.Session") as mock_session_class:
            # Setup mocks
            initial_session = MagicMock()
            assumed_session = MagicMock()

            mock_session_class.side_effect = [initial_session, assumed_session]

            # Mock STS client
            mock_sts = MagicMock()
            mock_sts.assume_role.return_value = {
                "Credentials": {
                    "AccessKeyId": "assumed_key",
                    "SecretAccessKey": "assumed_secret",
                    "SessionToken": "assumed_token",
                }
            }
            mock_sts.get_caller_identity.return_value = {"Arn": "arn:aws:iam::123456789012:user/test"}

            initial_session.client.return_value = mock_sts
            assumed_session.client.return_value = mock_sts

            provider = AWSProvider(role_arn="arn:aws:iam::123456789012:role/test-role")

            # Verify assume_role was called
            mock_sts.assume_role.assert_called_once()
            call_args = mock_sts.assume_role.call_args[1]
            assert call_args["RoleArn"] == "arn:aws:iam::123456789012:role/test-role"


class TestAWSProviderClusterOperations:
    """Test cluster operations."""

    @mock_aws
    def test_create_cluster(self, aws_credentials):
        """Test EKS cluster creation."""
        provider = AWSProvider()

        config = ClusterConfig(
            name="test-cluster",
            region="us-west-2",
            version="1.28",
            node_count=3,
            subnet_ids=["subnet-1", "subnet-2"],
            metadata={"role_arn": "arn:aws:iam::123456789012:role/eks-role"},
        )

        # Mock EKS service
        with patch.object(provider.eks, "create_cluster") as mock_create:
            from src.interfaces.models import Cluster

            mock_create.return_value = Cluster(
                id="test-cluster",
                name="test-cluster",
                status="CREATING",
                version="1.28",
                region="us-west-2",
            )

            cluster = provider.create_cluster(config)

            assert cluster.name == "test-cluster"
            assert cluster.status == "CREATING"
            assert cluster.version == "1.28"
            mock_create.assert_called_once_with(config)

    @mock_aws
    def test_get_cluster(self, aws_credentials):
        """Test getting cluster details."""
        provider = AWSProvider()

        with patch.object(provider.eks, "get_cluster") as mock_get:
            from src.interfaces.models import Cluster

            mock_get.return_value = Cluster(
                id="test-cluster",
                name="test-cluster",
                status="ACTIVE",
                version="1.28",
                region="us-west-2",
                node_count=3,
            )

            cluster = provider.get_cluster("test-cluster", "us-west-2")

            assert cluster.name == "test-cluster"
            assert cluster.status == "ACTIVE"
            mock_get.assert_called_once_with("test-cluster", "us-west-2")

    @mock_aws
    def test_delete_cluster(self, aws_credentials):
        """Test cluster deletion."""
        provider = AWSProvider()

        with patch.object(provider.eks, "delete_cluster") as mock_delete:
            mock_delete.return_value = True

            result = provider.delete_cluster("test-cluster", "us-west-2")

            assert result is True
            mock_delete.assert_called_once_with("test-cluster", "us-west-2")

    @mock_aws
    def test_list_clusters(self, aws_credentials):
        """Test listing clusters."""
        provider = AWSProvider()

        with patch.object(provider.eks, "list_clusters") as mock_list:
            from src.interfaces.models import Cluster

            mock_list.return_value = [
                Cluster(id="cluster-1", name="cluster-1", status="ACTIVE", version="1.28", region="us-west-2"),
                Cluster(id="cluster-2", name="cluster-2", status="ACTIVE", version="1.27", region="us-west-2"),
            ]

            clusters = provider.list_clusters("us-west-2")

            assert len(clusters) == 2
            assert clusters[0].name == "cluster-1"
            assert clusters[1].name == "cluster-2"
            mock_list.assert_called_once_with("us-west-2")


class TestAWSProviderDatabaseOperations:
    """Test database operations."""

    @mock_aws
    def test_create_database(self, aws_credentials):
        """Test RDS database creation."""
        provider = AWSProvider()

        config = DatabaseConfig(
            name="test-db",
            engine="postgres",
            engine_version="14.7",
            instance_class="db.t3.micro",
            region="us-west-2",
            master_username="admin",
            master_password="test_password",
        )

        with patch.object(provider.rds, "create_database") as mock_create:
            from src.interfaces.models import Database

            mock_create.return_value = Database(
                id="test-db",
                name="test-db",
                engine="postgres",
                engine_version="14.7",
                status="creating",
                region="us-west-2",
                instance_class="db.t3.micro",
            )

            database = provider.create_database(config)

            assert database.name == "test-db"
            assert database.engine == "postgres"
            assert database.status == "creating"
            mock_create.assert_called_once_with(config)

    @mock_aws
    def test_get_database(self, aws_credentials):
        """Test getting database details."""
        provider = AWSProvider()

        with patch.object(provider.rds, "get_database") as mock_get:
            from src.interfaces.models import Database

            mock_get.return_value = Database(
                id="test-db",
                name="test-db",
                engine="postgres",
                engine_version="14.7",
                status="available",
                endpoint="test-db.abc123.us-west-2.rds.amazonaws.com",
                port=5432,
                region="us-west-2",
                instance_class="db.t3.micro",
            )

            database = provider.get_database("test-db", "us-west-2")

            assert database.name == "test-db"
            assert database.status == "available"
            assert database.port == 5432
            mock_get.assert_called_once_with("test-db", "us-west-2")

    @mock_aws
    def test_delete_database(self, aws_credentials):
        """Test database deletion."""
        provider = AWSProvider()

        with patch.object(provider.rds, "delete_database") as mock_delete:
            mock_delete.return_value = True

            result = provider.delete_database("test-db", "us-west-2", skip_final_snapshot=True)

            assert result is True
            mock_delete.assert_called_once_with("test-db", "us-west-2", True)

    @mock_aws
    def test_list_databases(self, aws_credentials):
        """Test listing databases."""
        provider = AWSProvider()

        with patch.object(provider.rds, "list_databases") as mock_list:
            from src.interfaces.models import Database

            mock_list.return_value = [
                Database(
                    id="db-1", name="db-1", engine="postgres", engine_version="14.7", status="available", region="us-west-2", instance_class="db.t3.micro"
                ),
                Database(
                    id="db-2", name="db-2", engine="mysql", engine_version="8.0", status="available", region="us-west-2", instance_class="db.t3.small"
                ),
            ]

            databases = provider.list_databases("us-west-2")

            assert len(databases) == 2
            assert databases[0].engine == "postgres"
            assert databases[1].engine == "mysql"
            mock_list.assert_called_once_with("us-west-2")


class TestAWSProviderStorageOperations:
    """Test storage operations."""

    @mock_aws
    def test_create_storage(self, aws_credentials):
        """Test S3 bucket creation."""
        provider = AWSProvider()

        config = StorageConfig(
            name="test-bucket",
            region="us-west-2",
            versioning_enabled=True,
            encryption_enabled=True,
        )

        with patch.object(provider.s3, "create_storage") as mock_create:
            from src.interfaces.models import Storage

            mock_create.return_value = Storage(
                id="test-bucket",
                name="test-bucket",
                region="us-west-2",
                versioning_enabled=True,
                encryption_enabled=True,
            )

            storage = provider.create_storage(config)

            assert storage.name == "test-bucket"
            assert storage.versioning_enabled is True
            assert storage.encryption_enabled is True
            mock_create.assert_called_once_with(config)

    @mock_aws
    def test_get_storage(self, aws_credentials):
        """Test getting storage details."""
        provider = AWSProvider()

        with patch.object(provider.s3, "get_storage") as mock_get:
            from src.interfaces.models import Storage

            mock_get.return_value = Storage(
                id="test-bucket",
                name="test-bucket",
                region="us-west-2",
                size_bytes=1024000,
                object_count=100,
                versioning_enabled=True,
                encryption_enabled=True,
            )

            storage = provider.get_storage("test-bucket", "us-west-2")

            assert storage.name == "test-bucket"
            assert storage.object_count == 100
            mock_get.assert_called_once_with("test-bucket", "us-west-2")

    @mock_aws
    def test_delete_storage(self, aws_credentials):
        """Test storage deletion."""
        provider = AWSProvider()

        with patch.object(provider.s3, "delete_storage") as mock_delete:
            mock_delete.return_value = True

            result = provider.delete_storage("test-bucket", "us-west-2", force=True)

            assert result is True
            mock_delete.assert_called_once_with("test-bucket", "us-west-2", True)

    @mock_aws
    def test_list_storage(self, aws_credentials):
        """Test listing storage buckets."""
        provider = AWSProvider()

        with patch.object(provider.s3, "list_storage") as mock_list:
            from src.interfaces.models import Storage

            mock_list.return_value = [
                Storage(id="bucket-1", name="bucket-1", region="us-west-2"),
                Storage(id="bucket-2", name="bucket-2", region="us-west-2"),
            ]

            buckets = provider.list_storage("us-west-2")

            assert len(buckets) == 2
            assert buckets[0].name == "bucket-1"
            mock_list.assert_called_once_with("us-west-2")


class TestAWSProviderCostOperations:
    """Test cost and metrics operations."""

    @mock_aws
    def test_get_cost_data(self, aws_credentials):
        """Test getting cost data."""
        provider = AWSProvider()

        with patch.object(provider.cost_explorer, "get_cost_data") as mock_get:
            from src.interfaces.models import CostData
            from datetime import datetime

            mock_get.return_value = CostData(
                start_date=datetime(2024, 1, 1),
                end_date=datetime(2024, 1, 31),
                total_cost=1000.50,
                currency="USD",
                breakdown={"EC2": 500.0, "S3": 200.0, "RDS": 300.50},
            )

            cost_data = provider.get_cost_data("THIS_MONTH", "MONTHLY")

            assert cost_data.total_cost == 1000.50
            assert cost_data.currency == "USD"
            assert len(cost_data.breakdown) == 3
            mock_get.assert_called_once_with("THIS_MONTH", "MONTHLY")

    @mock_aws
    def test_get_metrics(self, aws_credentials):
        """Test getting CloudWatch metrics."""
        provider = AWSProvider()

        with patch.object(provider.cloudwatch, "get_metrics") as mock_get:
            mock_get.return_value = {
                "metric_name": "CPUUtilization",
                "namespace": "AWS/EC2",
                "datapoints": [{"Timestamp": "2024-01-01T00:00:00Z", "Average": 45.5}],
            }

            metrics = provider.get_metrics(
                resource_id="i-1234567890",
                metric_name="CPUUtilization",
                start_time="2024-01-01T00:00:00Z",
                end_time="2024-01-02T00:00:00Z",
                namespace="AWS/EC2",
            )

            assert metrics["metric_name"] == "CPUUtilization"
            assert len(metrics["datapoints"]) == 1
            mock_get.assert_called_once()
