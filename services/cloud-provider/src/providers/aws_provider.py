"""AWS Cloud Provider implementation."""

import logging
import os
from typing import Optional, List, Dict, Any

import boto3
from botocore.exceptions import ClientError, NoCredentialsError

from ..interfaces.provider import (
    CloudProvider,
    ClusterConfig,
    DatabaseConfig,
    StorageConfig,
)
from ..interfaces.models import Cluster, Database, Storage, CostData
from ..exceptions import AuthenticationError
from ..utils import RateLimiter

from .aws.eks import EKSService
from .aws.rds import RDSService
from .aws.s3 import S3Service
from .aws.cloudwatch import CloudWatchService
from .aws.cost_explorer import CostExplorerService

logger = logging.getLogger(__name__)


class AWSProvider(CloudProvider):
    """AWS cloud provider implementation."""

    def __init__(
        self,
        region: Optional[str] = None,
        access_key_id: Optional[str] = None,
        secret_access_key: Optional[str] = None,
        session_token: Optional[str] = None,
        role_arn: Optional[str] = None,
        profile_name: Optional[str] = None,
        rate_limit_calls: int = 10,
        rate_limit_window: float = 1.0,
    ):
        """
        Initialize AWS provider.

        Authentication priority:
        1. IAM role (if role_arn provided or running in AWS with instance profile)
        2. STS assume role (if role_arn provided with credentials)
        3. Access keys (if provided)
        4. Environment variables
        5. Shared credentials file (~/.aws/credentials)
        6. Instance metadata (if running on EC2)

        Args:
            region: Default AWS region
            access_key_id: AWS access key ID (least preferred)
            secret_access_key: AWS secret access key
            session_token: AWS session token for temporary credentials
            role_arn: IAM role ARN to assume
            profile_name: AWS profile name from credentials file
            rate_limit_calls: Maximum API calls per time window
            rate_limit_window: Time window in seconds for rate limiting

        Raises:
            AuthenticationError: If authentication fails
        """
        self.region = region or os.getenv("AWS_DEFAULT_REGION", "us-east-1")
        self.rate_limiter = RateLimiter(max_calls=rate_limit_calls, time_window=rate_limit_window)

        try:
            # Create boto3 session
            session_kwargs = {}

            if profile_name:
                session_kwargs["profile_name"] = profile_name
                logger.info(f"Using AWS profile: {profile_name}")
            elif access_key_id and secret_access_key:
                session_kwargs["aws_access_key_id"] = access_key_id
                session_kwargs["aws_secret_access_key"] = secret_access_key
                if session_token:
                    session_kwargs["aws_session_token"] = session_token
                logger.info("Using provided AWS credentials")

            if region:
                session_kwargs["region_name"] = region

            self.session = boto3.Session(**session_kwargs)

            # If role_arn provided, assume the role
            if role_arn:
                self._assume_role(role_arn)

            # Verify credentials by making a test call
            self._verify_credentials()

            # Initialize service clients
            self.eks = EKSService(self.session, self.rate_limiter)
            self.rds = RDSService(self.session, self.rate_limiter)
            self.s3 = S3Service(self.session, self.rate_limiter)
            self.cloudwatch = CloudWatchService(self.session, self.rate_limiter)
            self.cost_explorer = CostExplorerService(self.session, self.rate_limiter)

            logger.info(f"✅ AWS Provider initialized successfully for region: {self.region}")

        except NoCredentialsError:
            raise AuthenticationError(
                "No AWS credentials found. Please provide credentials via parameters, "
                "environment variables, or AWS credentials file.",
                provider="aws",
            )
        except ClientError as e:
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise AuthenticationError(f"AWS authentication failed: {error_msg}", provider="aws")

    def _assume_role(self, role_arn: str):
        """
        Assume an IAM role using STS.

        Args:
            role_arn: IAM role ARN to assume
        """
        logger.info(f"Assuming IAM role: {role_arn}")

        try:
            sts_client = self.session.client("sts")
            response = sts_client.assume_role(RoleArn=role_arn, RoleSessionName="fawkes-cloud-provider")

            credentials = response["Credentials"]

            # Create new session with assumed role credentials
            self.session = boto3.Session(
                aws_access_key_id=credentials["AccessKeyId"],
                aws_secret_access_key=credentials["SecretAccessKey"],
                aws_session_token=credentials["SessionToken"],
                region_name=self.region,
            )

            logger.info("✅ Successfully assumed IAM role")

        except ClientError as e:
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise AuthenticationError(f"Failed to assume role {role_arn}: {error_msg}", provider="aws")

    def _verify_credentials(self):
        """Verify AWS credentials by making a test call."""
        try:
            sts = self.session.client("sts")
            identity = sts.get_caller_identity()
            logger.info(f"Authenticated as: {identity.get('Arn')}")
        except ClientError as e:
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise AuthenticationError(f"Credential verification failed: {error_msg}", provider="aws")

    # Cluster operations
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """Create a Kubernetes cluster."""
        return self.eks.create_cluster(config)

    def get_cluster(self, cluster_id: str, region: Optional[str] = None) -> Cluster:
        """Get cluster details."""
        region = region or self.region
        return self.eks.get_cluster(cluster_id, region)

    def delete_cluster(self, cluster_id: str, region: Optional[str] = None) -> bool:
        """Delete a cluster."""
        region = region or self.region
        return self.eks.delete_cluster(cluster_id, region)

    def list_clusters(self, region: Optional[str] = None) -> List[Cluster]:
        """List all clusters."""
        region = region or self.region
        return self.eks.list_clusters(region)

    # Database operations
    def create_database(self, config: DatabaseConfig) -> Database:
        """Create a database instance."""
        return self.rds.create_database(config)

    def get_database(self, database_id: str, region: Optional[str] = None) -> Database:
        """Get database details."""
        region = region or self.region
        return self.rds.get_database(database_id, region)

    def delete_database(
        self, database_id: str, region: Optional[str] = None, skip_final_snapshot: bool = False
    ) -> bool:
        """Delete a database instance."""
        region = region or self.region
        return self.rds.delete_database(database_id, region, skip_final_snapshot)

    def list_databases(self, region: Optional[str] = None) -> List[Database]:
        """List all database instances."""
        region = region or self.region
        return self.rds.list_databases(region)

    # Storage operations
    def create_storage(self, config: StorageConfig) -> Storage:
        """Create a storage bucket."""
        return self.s3.create_storage(config)

    def get_storage(self, storage_id: str, region: Optional[str] = None) -> Storage:
        """Get storage bucket details."""
        region = region or self.region
        return self.s3.get_storage(storage_id, region)

    def delete_storage(self, storage_id: str, region: Optional[str] = None, force: bool = False) -> bool:
        """Delete a storage bucket."""
        region = region or self.region
        return self.s3.delete_storage(storage_id, region, force)

    def list_storage(self, region: Optional[str] = None) -> List[Storage]:
        """List all storage buckets."""
        return self.s3.list_storage(region)

    # Cost and metrics operations
    def get_cost_data(self, timeframe: str, granularity: str = "MONTHLY") -> CostData:
        """Get cost data for a specified timeframe."""
        return self.cost_explorer.get_cost_data(timeframe, granularity)

    def get_metrics(
        self,
        resource_id: str,
        metric_name: str,
        start_time: str,
        end_time: str,
        namespace: Optional[str] = None,
        dimensions: Optional[List[Dict[str, str]]] = None,
        region: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get metrics for a resource.

        Args:
            resource_id: Unique resource identifier
            metric_name: Name of the metric to retrieve
            start_time: Start time (ISO format)
            end_time: End time (ISO format)
            namespace: CloudWatch namespace (e.g., 'AWS/EKS', 'AWS/RDS')
            dimensions: List of dimension dicts
            region: AWS region

        Returns:
            Dictionary containing metric data
        """
        from datetime import datetime

        region = region or self.region

        # Parse ISO format times
        start_dt = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
        end_dt = datetime.fromisoformat(end_time.replace("Z", "+00:00"))

        # Set default namespace and dimensions if not provided
        if not namespace:
            namespace = "AWS/EC2"  # Default namespace

        if not dimensions:
            dimensions = [{"Name": "InstanceId", "Value": resource_id}]

        return self.cloudwatch.get_metrics(namespace, metric_name, dimensions, start_dt, end_dt, region)

    def get_cost_forecast(self, days: int = 30) -> Dict[str, Any]:
        """
        Get cost forecast.

        Args:
            days: Number of days to forecast

        Returns:
            Dictionary containing forecast data
        """
        return self.cost_explorer.get_cost_forecast(days)
