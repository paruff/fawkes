"""Unit tests for GCP Provider."""

import pytest
from unittest.mock import Mock, patch, MagicMock, PropertyMock
from datetime import datetime

from src.providers.gcp_provider import GCPProvider
from src.interfaces.provider import ClusterConfig, DatabaseConfig, StorageConfig
from src.exceptions import AuthenticationError


@pytest.fixture
def gcp_credentials():
    """Mock GCP credentials for testing."""
    import os

    os.environ["GCP_PROJECT_ID"] = "test-project"
    os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "/tmp/fake-credentials.json"


@pytest.fixture
def mock_credentials():
    """Create mock GCP credentials."""
    with patch("src.providers.gcp_provider.get_default_credentials") as mock_creds:
        mock_creds.return_value = (Mock(), "test-project")
        yield mock_creds


class TestGCPProviderInitialization:
    """Test GCP Provider initialization and authentication."""

    def test_init_with_project_id(self, mock_credentials):
        """Test initialization with explicit project ID."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            assert provider.project_id == "test-project"
            assert provider.gke is not None
            assert provider.cloudsql is not None
            assert provider.gcs is not None
            assert provider.monitoring is not None
            assert provider.billing is not None

    def test_init_with_credentials_path(self, mock_credentials):
        """Test initialization with credentials file path."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project", credentials_path="/path/to/credentials.json")

            assert provider.project_id == "test-project"

    def test_init_with_detected_project(self):
        """Test initialization with auto-detected project."""
        with patch("src.providers.gcp_provider.get_default_credentials") as mock_creds:
            mock_creds.return_value = (Mock(), "detected-project")
            with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
                provider = GCPProvider()

                assert provider.project_id == "detected-project"

    def test_init_no_project_id(self):
        """Test initialization fails without project ID."""
        with patch("src.providers.gcp_provider.get_default_credentials") as mock_creds:
            mock_creds.return_value = (Mock(), None)
            import os

            if "GCP_PROJECT_ID" in os.environ:
                del os.environ["GCP_PROJECT_ID"]

            with pytest.raises(AuthenticationError) as exc_info:
                GCPProvider()

            assert "project ID not provided" in str(exc_info.value)

    def test_init_no_credentials(self):
        """Test initialization fails without credentials."""
        from google.auth.exceptions import DefaultCredentialsError

        with patch("src.providers.gcp_provider.get_default_credentials") as mock_creds:
            mock_creds.side_effect = DefaultCredentialsError("No credentials found")

            with pytest.raises(AuthenticationError) as exc_info:
                GCPProvider(project_id="test-project")

            assert "No GCP credentials found" in str(exc_info.value)

    def test_init_with_workload_identity(self, mock_credentials):
        """Test initialization with Workload Identity."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(
                project_id="test-project", service_account_email="test@test-project.iam.gserviceaccount.com"
            )

            assert provider.service_account_email == "test@test-project.iam.gserviceaccount.com"


class TestGCPProviderClusterOperations:
    """Test cluster operations."""

    def test_create_cluster(self, mock_credentials):
        """Test GKE cluster creation."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            config = ClusterConfig(
                name="test-cluster",
                region="us-central1",
                version="1.28",
                node_count=3,
                subnet_ids=["subnet-1"],
                metadata={"enable_workload_identity": True},
            )

            with patch.object(provider.gke, "create_cluster") as mock_create:
                from src.interfaces.models import Cluster

                mock_create.return_value = Cluster(
                    id="test-cluster",
                    name="test-cluster",
                    status="PROVISIONING",
                    version="1.28",
                    region="us-central1",
                    node_count=3,
                )

                cluster = provider.create_cluster(config)

                assert cluster.name == "test-cluster"
                assert cluster.status == "PROVISIONING"
                assert cluster.version == "1.28"
                mock_create.assert_called_once_with(config)

    def test_get_cluster(self, mock_credentials):
        """Test getting cluster details."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.gke, "get_cluster") as mock_get:
                from src.interfaces.models import Cluster

                mock_get.return_value = Cluster(
                    id="test-cluster",
                    name="test-cluster",
                    status="RUNNING",
                    version="1.28",
                    region="us-central1",
                    node_count=3,
                )

                cluster = provider.get_cluster("test-cluster", "us-central1", include_node_count=True)

                assert cluster.name == "test-cluster"
                assert cluster.status == "RUNNING"
                mock_get.assert_called_once_with("test-cluster", "us-central1", True)

    def test_get_cluster_requires_region(self, mock_credentials):
        """Test get_cluster fails without region."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with pytest.raises(ValueError) as exc_info:
                provider.get_cluster("test-cluster")

            assert "region parameter is required" in str(exc_info.value)

    def test_delete_cluster(self, mock_credentials):
        """Test cluster deletion."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.gke, "delete_cluster") as mock_delete:
                mock_delete.return_value = True

                result = provider.delete_cluster("test-cluster", "us-central1")

                assert result is True
                mock_delete.assert_called_once_with("test-cluster", "us-central1")

    def test_list_clusters(self, mock_credentials):
        """Test listing clusters."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.gke, "list_clusters") as mock_list:
                from src.interfaces.models import Cluster

                mock_list.return_value = [
                    Cluster(id="cluster-1", name="cluster-1", status="RUNNING", version="1.28", region="us-central1"),
                    Cluster(id="cluster-2", name="cluster-2", status="RUNNING", version="1.27", region="us-central1"),
                ]

                clusters = provider.list_clusters("us-central1", include_details=False)

                assert len(clusters) == 2
                assert clusters[0].name == "cluster-1"
                assert clusters[1].name == "cluster-2"
                mock_list.assert_called_once_with("us-central1", False)

    def test_list_clusters_all_regions(self, mock_credentials):
        """Test listing clusters in all regions."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.gke, "list_clusters") as mock_list:
                mock_list.return_value = []

                provider.list_clusters()

                mock_list.assert_called_once_with("-", False)


class TestGCPProviderDatabaseOperations:
    """Test database operations."""

    def test_create_database(self, mock_credentials):
        """Test Cloud SQL database creation."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            config = DatabaseConfig(
                name="test-db",
                engine="postgres",
                engine_version="14",
                instance_class="db-n1-standard-1",
                region="us-central1",
                master_username="admin",
                master_password="test_password",
            )

            with patch.object(provider.cloudsql, "create_database") as mock_create:
                from src.interfaces.models import Database

                mock_create.return_value = Database(
                    id="test-db",
                    name="test-db",
                    engine="postgres",
                    engine_version="14",
                    status="PENDING_CREATE",
                    region="us-central1",
                    instance_class="db-n1-standard-1",
                )

                database = provider.create_database(config)

                assert database.name == "test-db"
                assert database.engine == "postgres"
                assert database.status == "PENDING_CREATE"
                mock_create.assert_called_once_with(config)

    def test_get_database(self, mock_credentials):
        """Test getting database details."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.cloudsql, "get_database") as mock_get:
                from src.interfaces.models import Database

                mock_get.return_value = Database(
                    id="test-db",
                    name="test-db",
                    engine="postgres",
                    engine_version="14",
                    status="RUNNABLE",
                    endpoint="10.0.0.1",
                    port=5432,
                    region="us-central1",
                    instance_class="db-n1-standard-1",
                )

                database = provider.get_database("test-db")

                assert database.name == "test-db"
                assert database.status == "RUNNABLE"
                assert database.port == 5432
                mock_get.assert_called_once_with("test-db", None)

    def test_delete_database(self, mock_credentials):
        """Test database deletion."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.cloudsql, "delete_database") as mock_delete:
                mock_delete.return_value = True

                result = provider.delete_database("test-db", skip_final_snapshot=True)

                assert result is True
                mock_delete.assert_called_once_with("test-db", None, True)

    def test_list_databases(self, mock_credentials):
        """Test listing databases."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.cloudsql, "list_databases") as mock_list:
                from src.interfaces.models import Database

                mock_list.return_value = [
                    Database(
                        id="db-1",
                        name="db-1",
                        engine="postgres",
                        engine_version="14",
                        status="RUNNABLE",
                        region="us-central1",
                        instance_class="db-n1-standard-1",
                    ),
                    Database(
                        id="db-2",
                        name="db-2",
                        engine="mysql",
                        engine_version="8.0",
                        status="RUNNABLE",
                        region="us-central1",
                        instance_class="db-n1-standard-2",
                    ),
                ]

                databases = provider.list_databases("us-central1")

                assert len(databases) == 2
                assert databases[0].engine == "postgres"
                assert databases[1].engine == "mysql"
                mock_list.assert_called_once_with("us-central1")


class TestGCPProviderStorageOperations:
    """Test storage operations."""

    def test_create_storage(self, mock_credentials):
        """Test GCS bucket creation."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            config = StorageConfig(
                name="test-bucket",
                region="us-central1",
                versioning_enabled=True,
                encryption_enabled=True,
            )

            with patch.object(provider.gcs, "create_storage") as mock_create:
                from src.interfaces.models import Storage

                mock_create.return_value = Storage(
                    id="test-bucket",
                    name="test-bucket",
                    region="us-central1",
                    versioning_enabled=True,
                    encryption_enabled=True,
                )

                storage = provider.create_storage(config)

                assert storage.name == "test-bucket"
                assert storage.versioning_enabled is True
                assert storage.encryption_enabled is True
                mock_create.assert_called_once_with(config)

    def test_get_storage(self, mock_credentials):
        """Test getting storage details."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.gcs, "get_storage") as mock_get:
                from src.interfaces.models import Storage

                mock_get.return_value = Storage(
                    id="test-bucket",
                    name="test-bucket",
                    region="us-central1",
                    size_bytes=1024000,
                    object_count=100,
                    versioning_enabled=True,
                    encryption_enabled=True,
                )

                storage = provider.get_storage("test-bucket")

                assert storage.name == "test-bucket"
                assert storage.object_count == 100
                mock_get.assert_called_once_with("test-bucket", None)

    def test_delete_storage(self, mock_credentials):
        """Test storage deletion."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.gcs, "delete_storage") as mock_delete:
                mock_delete.return_value = True

                result = provider.delete_storage("test-bucket", force=True)

                assert result is True
                mock_delete.assert_called_once_with("test-bucket", None, True)

    def test_list_storage(self, mock_credentials):
        """Test listing storage buckets."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.gcs, "list_storage") as mock_list:
                from src.interfaces.models import Storage

                mock_list.return_value = [
                    Storage(id="bucket-1", name="bucket-1", region="us-central1"),
                    Storage(id="bucket-2", name="bucket-2", region="us-central1"),
                ]

                buckets = provider.list_storage("us-central1", include_details=False)

                assert len(buckets) == 2
                assert buckets[0].name == "bucket-1"
                mock_list.assert_called_once_with("us-central1", False)


class TestGCPProviderCostOperations:
    """Test cost and metrics operations."""

    def test_get_cost_data(self, mock_credentials):
        """Test getting cost data."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.billing, "get_cost_data") as mock_get:
                from src.interfaces.models import CostData
                from datetime import datetime

                mock_get.return_value = CostData(
                    start_date=datetime(2024, 1, 1),
                    end_date=datetime(2024, 1, 31),
                    total_cost=1000.50,
                    currency="USD",
                    breakdown={"Compute Engine": 500.0, "Cloud Storage": 200.0, "Cloud SQL": 300.50},
                )

                cost_data = provider.get_cost_data("THIS_MONTH", "MONTHLY")

                assert cost_data.total_cost == 1000.50
                assert cost_data.currency == "USD"
                assert len(cost_data.breakdown) == 3
                mock_get.assert_called_once_with("THIS_MONTH", "MONTHLY")

    def test_get_metrics(self, mock_credentials):
        """Test getting Cloud Monitoring metrics."""
        with patch("src.providers.gcp_provider.GCPProvider._verify_credentials"):
            provider = GCPProvider(project_id="test-project")

            with patch.object(provider.monitoring, "get_metrics") as mock_get:
                mock_get.return_value = {
                    "metric_type": "compute.googleapis.com/instance/cpu/utilization",
                    "resource_type": "gce_instance",
                    "datapoints": [{"timestamp": "2024-01-01T00:00:00Z", "value": 45.5}],
                }

                metrics = provider.get_metrics(
                    resource_id="instance-1",
                    metric_name="compute.googleapis.com/instance/cpu/utilization",
                    start_time="2024-01-01T00:00:00Z",
                    end_time="2024-01-02T00:00:00Z",
                    resource_type="gce_instance",
                )

                assert metrics["metric_type"] == "compute.googleapis.com/instance/cpu/utilization"
                assert len(metrics["datapoints"]) == 1
                mock_get.assert_called_once()


class TestGCPProviderWorkloadIdentity:
    """Test Workload Identity operations."""

    @pytest.mark.skip(reason="Requires google-cloud-iam library")
    def test_create_service_account(self, mock_credentials):
        """Test service account creation."""
        pass

    @pytest.mark.skip(reason="Requires google-cloud-iam library")
    def test_bind_workload_identity(self, mock_credentials):
        """Test Workload Identity binding."""
        pass
