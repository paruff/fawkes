"""AWS EKS (Elastic Kubernetes Service) operations."""

import logging
from typing import List, Optional

import boto3
from botocore.exceptions import ClientError

from ...interfaces.models import Cluster
from ...interfaces.provider import ClusterConfig
from ...exceptions import (
    CloudProviderError,
    ResourceNotFoundError,
    ResourceAlreadyExistsError,
    ValidationError,
)
from ...utils import retry_with_backoff, RateLimiter

logger = logging.getLogger(__name__)


class EKSService:
    """AWS EKS service operations."""

    def __init__(self, session: boto3.Session, rate_limiter: Optional[RateLimiter] = None):
        """
        Initialize EKS service.

        Args:
            session: Boto3 session
            rate_limiter: Optional rate limiter for API calls
        """
        self.session = session
        self.rate_limiter = rate_limiter or RateLimiter(max_calls=10, time_window=1.0)
        self._clients = {}

    def _get_client(self, region: str):
        """Get or create EKS client for region."""
        if region not in self._clients:
            self.rate_limiter.acquire()
            self._clients[region] = self.session.client("eks", region_name=region)
            logger.debug(f"Created EKS client for region: {region}")
        return self._clients[region]

    @retry_with_backoff(
        max_retries=3,
        retriable_exceptions=(ClientError,),
    )
    def create_cluster(self, config: ClusterConfig) -> Cluster:
        """
        Create an EKS cluster.

        Args:
            config: Cluster configuration

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster creation fails
        """
        logger.info(f"Creating EKS cluster: {config.name} in region {config.region}")

        try:
            client = self._get_client(config.region)

            # Build cluster creation request
            create_params = {
                "name": config.name,
                "version": config.version,
                "roleArn": config.metadata.get("role_arn"),
                "resourcesVpcConfig": {
                    "subnetIds": config.subnet_ids,
                },
                "tags": config.tags,
            }

            # Add optional parameters
            if config.security_group_ids:
                create_params["resourcesVpcConfig"]["securityGroupIds"] = config.security_group_ids

            if config.metadata.get("logging"):
                create_params["logging"] = config.metadata["logging"]

            self.rate_limiter.acquire()
            response = client.create_cluster(**create_params)

            cluster_data = response["cluster"]

            logger.info(f"✅ Initiated EKS cluster creation: {config.name} (status: {cluster_data['status']})")

            return Cluster(
                id=cluster_data["name"],
                name=cluster_data["name"],
                status=cluster_data["status"],
                version=cluster_data["version"],
                endpoint=cluster_data.get("endpoint"),
                region=config.region,
                created_at=cluster_data.get("createdAt"),
                metadata={
                    "arn": cluster_data.get("arn"),
                    "role_arn": cluster_data.get("roleArn"),
                    "vpc_config": cluster_data.get("resourcesVpcConfig"),
                    "platform_version": cluster_data.get("platformVersion"),
                },
            )

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "ResourceInUseException":
                raise ResourceAlreadyExistsError(f"Cluster {config.name} already exists", provider="aws")
            elif error_code == "InvalidParameterException":
                raise ValidationError(f"Invalid parameter: {error_msg}", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to create EKS cluster {config.name}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def get_cluster(self, cluster_name: str, region: str) -> Cluster:
        """
        Get EKS cluster details.

        Args:
            cluster_name: Cluster name
            region: AWS region

        Returns:
            Cluster object with details

        Raises:
            CloudProviderError: If cluster retrieval fails
        """
        logger.debug(f"Getting EKS cluster: {cluster_name} in region {region}")

        try:
            client = self._get_client(region)
            self.rate_limiter.acquire()
            response = client.describe_cluster(name=cluster_name)

            cluster_data = response["cluster"]

            # Get node group count
            node_count = 0
            try:
                self.rate_limiter.acquire()
                nodegroups = client.list_nodegroups(clusterName=cluster_name)
                for ng_name in nodegroups.get("nodegroups", []):
                    self.rate_limiter.acquire()
                    ng_response = client.describe_nodegroup(clusterName=cluster_name, nodegroupName=ng_name)
                    ng_data = ng_response.get("nodegroup", {})
                    node_count += ng_data.get("scalingConfig", {}).get("desiredSize", 0)
            except ClientError as e:
                logger.warning(f"Could not retrieve node group info: {e}")

            return Cluster(
                id=cluster_data["name"],
                name=cluster_data["name"],
                status=cluster_data["status"],
                version=cluster_data["version"],
                endpoint=cluster_data.get("endpoint"),
                region=region,
                node_count=node_count,
                created_at=cluster_data.get("createdAt"),
                metadata={
                    "arn": cluster_data.get("arn"),
                    "role_arn": cluster_data.get("roleArn"),
                    "vpc_config": cluster_data.get("resourcesVpcConfig"),
                    "platform_version": cluster_data.get("platformVersion"),
                    "health": cluster_data.get("health"),
                },
            )

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "ResourceNotFoundException":
                raise ResourceNotFoundError(f"Cluster {cluster_name} not found", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to get EKS cluster {cluster_name}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def delete_cluster(self, cluster_name: str, region: str) -> bool:
        """
        Delete an EKS cluster.

        Args:
            cluster_name: Cluster name
            region: AWS region

        Returns:
            True if deletion was initiated

        Raises:
            CloudProviderError: If cluster deletion fails
        """
        logger.info(f"Deleting EKS cluster: {cluster_name} in region {region}")

        try:
            client = self._get_client(region)

            # First, delete all node groups
            try:
                self.rate_limiter.acquire()
                nodegroups = client.list_nodegroups(clusterName=cluster_name)
                for ng_name in nodegroups.get("nodegroups", []):
                    logger.info(f"Deleting node group: {ng_name}")
                    self.rate_limiter.acquire()
                    client.delete_nodegroup(clusterName=cluster_name, nodegroupName=ng_name)
            except ClientError as e:
                logger.warning(f"Could not delete node groups: {e}")

            # Delete the cluster
            self.rate_limiter.acquire()
            client.delete_cluster(name=cluster_name)

            logger.info(f"✅ Initiated EKS cluster deletion: {cluster_name}")
            return True

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))

            if error_code == "ResourceNotFoundException":
                raise ResourceNotFoundError(f"Cluster {cluster_name} not found", provider="aws")
            else:
                raise CloudProviderError(
                    f"Failed to delete EKS cluster {cluster_name}: {error_msg}", provider="aws", error_code=error_code
                )

    @retry_with_backoff(max_retries=3, retriable_exceptions=(ClientError,))
    def list_clusters(self, region: str) -> List[Cluster]:
        """
        List all EKS clusters in a region.

        Args:
            region: AWS region

        Returns:
            List of Cluster objects

        Raises:
            CloudProviderError: If listing fails
        """
        logger.debug(f"Listing EKS clusters in region {region}")

        try:
            client = self._get_client(region)
            clusters = []

            # List cluster names
            self.rate_limiter.acquire()
            response = client.list_clusters()

            # Get details for each cluster
            for cluster_name in response.get("clusters", []):
                try:
                    cluster = self.get_cluster(cluster_name, region)
                    clusters.append(cluster)
                except Exception as e:
                    logger.warning(f"Could not retrieve cluster {cluster_name}: {e}")

            logger.info(f"Found {len(clusters)} EKS clusters in region {region}")
            return clusters

        except ClientError as e:
            error_code = e.response.get("Error", {}).get("Code", "Unknown")
            error_msg = e.response.get("Error", {}).get("Message", str(e))
            raise CloudProviderError(
                f"Failed to list EKS clusters in {region}: {error_msg}", provider="aws", error_code=error_code
            )
