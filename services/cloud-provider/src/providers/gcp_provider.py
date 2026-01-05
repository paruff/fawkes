"""GCP Cloud Provider implementation."""

import logging
import os
from typing import Optional, List, Dict, Any

from google.auth import default as get_default_credentials
from google.auth.exceptions import DefaultCredentialsError
from google.api_core import exceptions as gcp_exceptions

from ..interfaces.provider import (
    CloudProvider,
    ClusterConfig,
    DatabaseConfig,
    StorageConfig,
)
from ..interfaces.models import Cluster, Database, Storage, CostData
from ..exceptions import AuthenticationError
from ..utils import RateLimiter

from .gcp.gke import GKEService
from .gcp.cloudsql import CloudSQLService
from .gcp.gcs import GCSService
from .gcp.monitoring import MonitoringService
from .gcp.billing import BillingService

logger = logging.getLogger(__name__)


class GCPProvider(CloudProvider):
    """GCP cloud provider implementation."""

    def __init__(
        self,
        project_id: Optional[str] = None,
        credentials_path: Optional[str] = None,
        service_account_email: Optional[str] = None,
        billing_account_id: Optional[str] = None,
        rate_limit_calls: int = 10,
        rate_limit_window: float = 1.0,
    ):
        """
        Initialize GCP provider.

        Authentication priority:
        1. Workload Identity (if running in GKE with Workload Identity enabled)
        2. Service account key file (if credentials_path provided)
        3. Application Default Credentials (ADC)
        4. Environment variable GOOGLE_APPLICATION_CREDENTIALS

        Args:
            project_id: GCP project ID (required)
            credentials_path: Path to service account key file (optional)
            service_account_email: Service account email for Workload Identity (optional)
            billing_account_id: Billing account ID for cost data (optional)
            rate_limit_calls: Maximum API calls per time window
            rate_limit_window: Time window in seconds for rate limiting

        Raises:
            AuthenticationError: If authentication fails
        """
        self.rate_limiter = RateLimiter(max_calls=rate_limit_calls, time_window=rate_limit_window)

        try:
            # Set credentials path if provided
            if credentials_path:
                os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = credentials_path
                logger.info(f"Using service account key file: {credentials_path}")

            # Get default credentials
            credentials, detected_project = get_default_credentials()

            # Use provided project_id or fall back to detected project
            self.project_id = project_id or detected_project or os.getenv("GCP_PROJECT_ID")

            if not self.project_id:
                raise AuthenticationError(
                    "GCP project ID not provided and could not be detected. "
                    "Please provide project_id parameter or set GCP_PROJECT_ID environment variable.",
                    provider="gcp",
                )

            self.credentials = credentials
            self.service_account_email = service_account_email
            self.billing_account_id = billing_account_id

            # Verify credentials by checking project access
            self._verify_credentials()

            # Initialize service clients
            self.gke = GKEService(self.project_id, self.rate_limiter)
            self.cloudsql = CloudSQLService(self.project_id, self.rate_limiter)
            self.gcs = GCSService(self.project_id, self.rate_limiter)
            self.monitoring = MonitoringService(self.project_id, self.rate_limiter)
            self.billing = BillingService(self.project_id, self.billing_account_id, self.rate_limiter)

            logger.info(f"✅ GCP Provider initialized successfully for project: {self.project_id}")

        except DefaultCredentialsError as e:
            raise AuthenticationError(
                f"No GCP credentials found: {str(e)}. "
                "Please provide credentials via service account key file, "
                "Application Default Credentials, or Workload Identity.",
                provider="gcp",
            )
        except Exception as e:
            raise AuthenticationError(f"GCP authentication failed: {str(e)}", provider="gcp")

    def _verify_credentials(self):
        """Verify GCP credentials by making a test call."""
        try:
            # Import here to avoid circular dependency
            from google.cloud import resourcemanager_v3

            client = resourcemanager_v3.ProjectsClient(credentials=self.credentials)
            project_name = f"projects/{self.project_id}"
            
            try:
                project = client.get_project(name=project_name)
                logger.info(f"Authenticated for project: {project.display_name} ({project.project_id})")
            except gcp_exceptions.NotFound:
                logger.warning(
                    f"Project {self.project_id} not found or no access. "
                    "Continuing anyway - some operations may fail."
                )
            except Exception as e:
                logger.warning(f"Could not verify project access: {str(e)}. Continuing anyway.")

        except Exception as e:
            logger.warning(f"Credential verification failed: {str(e)}. Continuing anyway.")

    def create_service_account(self, name: str, display_name: str, description: str = "") -> Dict[str, str]:
        """
        Create a service account for Workload Identity.

        Args:
            name: Service account name
            display_name: Display name
            description: Description

        Returns:
            Dictionary with service account details

        Raises:
            CloudProviderError: If service account creation fails
        """
        from google.cloud import iam_admin_v1
        from ..exceptions import CloudProviderError

        try:
            client = iam_admin_v1.IAMClient(credentials=self.credentials)

            service_account = iam_admin_v1.ServiceAccount()
            service_account.display_name = display_name
            service_account.description = description

            request = iam_admin_v1.CreateServiceAccountRequest()
            request.name = f"projects/{self.project_id}"
            request.account_id = name
            request.service_account = service_account

            self.rate_limiter.acquire()
            created_account = client.create_service_account(request=request)

            logger.info(f"✅ Created service account: {created_account.email}")

            return {
                "email": created_account.email,
                "name": created_account.name,
                "project_id": self.project_id,
            }

        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to create service account {name}: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )

    def bind_workload_identity(
        self, service_account_email: str, namespace: str, k8s_service_account: str
    ) -> bool:
        """
        Bind a GCP service account to a Kubernetes service account for Workload Identity.

        Args:
            service_account_email: GCP service account email
            namespace: Kubernetes namespace
            k8s_service_account: Kubernetes service account name

        Returns:
            True if binding was successful

        Raises:
            CloudProviderError: If binding fails
        """
        from google.cloud import iam_admin_v1
        from google.iam.v1 import policy_pb2
        from ..exceptions import CloudProviderError

        try:
            client = iam_admin_v1.IAMClient(credentials=self.credentials)

            # Get current IAM policy
            resource = f"projects/{self.project_id}/serviceAccounts/{service_account_email}"
            
            self.rate_limiter.acquire()
            policy = client.get_iam_policy(request={"resource": resource})

            # Add Workload Identity binding
            member = f"serviceAccount:{self.project_id}.svc.id.goog[{namespace}/{k8s_service_account}]"
            role = "roles/iam.workloadIdentityUser"

            # Check if binding already exists
            binding_exists = False
            for binding in policy.bindings:
                if binding.role == role:
                    if member not in binding.members:
                        binding.members.append(member)
                    binding_exists = True
                    break

            # Add new binding if it doesn't exist
            if not binding_exists:
                new_binding = policy_pb2.Binding()
                new_binding.role = role
                new_binding.members.append(member)
                policy.bindings.append(new_binding)

            # Set the updated policy
            self.rate_limiter.acquire()
            client.set_iam_policy(request={"resource": resource, "policy": policy})

            logger.info(
                f"✅ Bound Workload Identity: {service_account_email} -> {namespace}/{k8s_service_account}"
            )

            return True

        except gcp_exceptions.GoogleAPICallError as e:
            raise CloudProviderError(
                f"Failed to bind Workload Identity: {str(e)}", provider="gcp", error_code=e.grpc_status_code
            )

    # Cluster operations
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """Create a Kubernetes cluster."""
        return self.gke.create_cluster(config)

    def get_cluster(self, cluster_id: str, region: Optional[str] = None, include_node_count: bool = True) -> Cluster:
        """
        Get cluster details.

        Args:
            cluster_id: Cluster ID
            region: GCP region/zone
            include_node_count: Whether to include node count
        """
        if not region:
            raise ValueError("region parameter is required for GCP")
        return self.gke.get_cluster(cluster_id, region, include_node_count)

    def delete_cluster(self, cluster_id: str, region: Optional[str] = None) -> bool:
        """Delete a cluster."""
        if not region:
            raise ValueError("region parameter is required for GCP")
        return self.gke.delete_cluster(cluster_id, region)

    def list_clusters(self, region: Optional[str] = None, include_details: bool = False) -> List[Cluster]:
        """
        List all clusters.

        Args:
            region: GCP region/zone (or "-" for all regions)
            include_details: Whether to fetch detailed info for each cluster (slower)
        """
        region = region or "-"  # "-" means all regions in GCP
        return self.gke.list_clusters(region, include_details)

    # Database operations
    def create_database(self, config: DatabaseConfig) -> Database:
        """Create a database instance."""
        return self.cloudsql.create_database(config)

    def get_database(self, database_id: str, region: Optional[str] = None) -> Database:
        """Get database details."""
        return self.cloudsql.get_database(database_id, region)

    def delete_database(
        self, database_id: str, region: Optional[str] = None, skip_final_snapshot: bool = False
    ) -> bool:
        """Delete a database instance."""
        return self.cloudsql.delete_database(database_id, region, skip_final_snapshot)

    def list_databases(self, region: Optional[str] = None) -> List[Database]:
        """List all database instances."""
        return self.cloudsql.list_databases(region)

    # Storage operations
    def create_storage(self, config: StorageConfig) -> Storage:
        """Create a storage bucket."""
        return self.gcs.create_storage(config)

    def get_storage(self, storage_id: str, region: Optional[str] = None) -> Storage:
        """Get storage bucket details."""
        return self.gcs.get_storage(storage_id, region)

    def delete_storage(self, storage_id: str, region: Optional[str] = None, force: bool = False) -> bool:
        """Delete a storage bucket."""
        return self.gcs.delete_storage(storage_id, region, force)

    def list_storage(self, region: Optional[str] = None, include_details: bool = False) -> List[Storage]:
        """
        List all storage buckets.

        Args:
            region: Optional region filter
            include_details: Whether to fetch detailed info for each bucket (slower)
        """
        return self.gcs.list_storage(region, include_details)

    # Cost and metrics operations
    def get_cost_data(self, timeframe: str, granularity: str = "MONTHLY") -> CostData:
        """Get cost data for a specified timeframe."""
        return self.billing.get_cost_data(timeframe, granularity)

    def get_metrics(
        self,
        resource_id: str,
        metric_name: str,
        start_time: str,
        end_time: str,
        resource_type: Optional[str] = None,
        resource_labels: Optional[Dict[str, str]] = None,
        region: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Get metrics for a resource.

        Args:
            resource_id: Unique resource identifier
            metric_name: Name of the metric to retrieve (e.g., 'compute.googleapis.com/instance/cpu/utilization')
            start_time: Start time (ISO format)
            end_time: End time (ISO format)
            resource_type: GCP resource type (e.g., 'gce_instance', 'gke_container')
            resource_labels: Resource labels to filter by
            region: GCP region

        Returns:
            Dictionary containing metric data
        """
        from datetime import datetime

        # Parse ISO format times
        start_dt = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
        end_dt = datetime.fromisoformat(end_time.replace("Z", "+00:00"))

        # Set default resource type and labels if not provided
        if not resource_type:
            resource_type = "gce_instance"

        if not resource_labels:
            resource_labels = {"instance_id": resource_id}

        return self.monitoring.get_metrics(metric_name, resource_type, resource_labels, start_dt, end_dt, region)
