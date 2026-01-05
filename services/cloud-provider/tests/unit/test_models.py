"""Unit tests for interface models."""

from datetime import datetime

from src.interfaces.models import Cluster, Database, Storage, CostData


class TestCluster:
    """Test Cluster model."""

    def test_cluster_creation(self):
        """Test creating a cluster object."""
        cluster = Cluster(
            id="cluster-1",
            name="my-cluster",
            status="ACTIVE",
            version="1.28",
            endpoint="https://cluster.example.com",
            region="us-west-2",
            node_count=3,
        )

        assert cluster.id == "cluster-1"
        assert cluster.name == "my-cluster"
        assert cluster.status == "ACTIVE"
        assert cluster.version == "1.28"
        assert cluster.endpoint == "https://cluster.example.com"
        assert cluster.region == "us-west-2"
        assert cluster.node_count == 3
        assert cluster.metadata == {}

    def test_cluster_with_metadata(self):
        """Test cluster with metadata."""
        metadata = {"arn": "arn:aws:eks:us-west-2:123456789012:cluster/my-cluster", "platform_version": "eks.1"}

        cluster = Cluster(
            id="cluster-1", name="my-cluster", status="ACTIVE", version="1.28", region="us-west-2", metadata=metadata
        )

        assert cluster.metadata["arn"] == "arn:aws:eks:us-west-2:123456789012:cluster/my-cluster"
        assert cluster.metadata["platform_version"] == "eks.1"


class TestDatabase:
    """Test Database model."""

    def test_database_creation(self):
        """Test creating a database object."""
        database = Database(
            id="db-1",
            name="my-database",
            engine="postgres",
            engine_version="14.7",
            status="available",
            endpoint="db.example.com",
            port=5432,
            region="us-west-2",
            allocated_storage=100,
            instance_class="db.t3.medium",
        )

        assert database.id == "db-1"
        assert database.name == "my-database"
        assert database.engine == "postgres"
        assert database.engine_version == "14.7"
        assert database.status == "available"
        assert database.endpoint == "db.example.com"
        assert database.port == 5432
        assert database.region == "us-west-2"
        assert database.allocated_storage == 100
        assert database.instance_class == "db.t3.medium"
        assert database.metadata == {}

    def test_database_with_created_at(self):
        """Test database with creation timestamp."""
        created_at = datetime(2024, 1, 1, 12, 0, 0)

        database = Database(
            id="db-1",
            name="my-database",
            engine="postgres",
            engine_version="14.7",
            status="available",
            region="us-west-2",
            instance_class="db.t3.medium",
            created_at=created_at,
        )

        assert database.created_at == created_at


class TestStorage:
    """Test Storage model."""

    def test_storage_creation(self):
        """Test creating a storage object."""
        storage = Storage(
            id="bucket-1",
            name="my-bucket",
            region="us-west-2",
            size_bytes=1024000,
            object_count=100,
            versioning_enabled=True,
            encryption_enabled=True,
        )

        assert storage.id == "bucket-1"
        assert storage.name == "my-bucket"
        assert storage.region == "us-west-2"
        assert storage.size_bytes == 1024000
        assert storage.object_count == 100
        assert storage.versioning_enabled is True
        assert storage.encryption_enabled is True
        assert storage.metadata == {}

    def test_storage_defaults(self):
        """Test storage with default values."""
        storage = Storage(id="bucket-1", name="my-bucket", region="us-west-2")

        assert storage.size_bytes == 0
        assert storage.object_count == 0
        assert storage.versioning_enabled is False
        assert storage.encryption_enabled is False


class TestCostData:
    """Test CostData model."""

    def test_cost_data_creation(self):
        """Test creating a cost data object."""
        start_date = datetime(2024, 1, 1)
        end_date = datetime(2024, 1, 31)
        breakdown = {"EC2": 500.0, "S3": 200.0, "RDS": 300.0}

        cost_data = CostData(
            start_date=start_date, end_date=end_date, total_cost=1000.0, currency="USD", breakdown=breakdown
        )

        assert cost_data.start_date == start_date
        assert cost_data.end_date == end_date
        assert cost_data.total_cost == 1000.0
        assert cost_data.currency == "USD"
        assert cost_data.breakdown == breakdown
        assert cost_data.metadata == {}

    def test_cost_data_defaults(self):
        """Test cost data with default values."""
        cost_data = CostData(start_date=datetime(2024, 1, 1), end_date=datetime(2024, 1, 31), total_cost=500.0)

        assert cost_data.currency == "USD"
        assert cost_data.breakdown == {}
        assert cost_data.metadata == {}

    def test_cost_data_with_metadata(self):
        """Test cost data with metadata."""
        metadata = {"granularity": "DAILY", "timeframe": "LAST_30_DAYS"}

        cost_data = CostData(
            start_date=datetime(2024, 1, 1), end_date=datetime(2024, 1, 31), total_cost=500.0, metadata=metadata
        )

        assert cost_data.metadata["granularity"] == "DAILY"
        assert cost_data.metadata["timeframe"] == "LAST_30_DAYS"
