"""
Terraform utility functions for environment name validation and cluster configuration.
"""

import re


def validate_environment_name(name: str) -> bool:
    """
    Validate that an environment name consists only of lowercase alphabetic characters.

    Valid examples: dev, staging, production
    Invalid examples: Dev, PROD, test123, ""
    """
    if not name:
        return False
    return bool(re.match(r"^[a-z]+$", name))


def create_cluster_config(
    node_count: int,
    node_size: str = "Standard_DS2_v2",
    kubernetes_version: str = "1.28",
) -> dict:
    """
    Create a cluster configuration dictionary with the given node count.

    Args:
        node_count: Number of nodes in the cluster (must be > 0)
        node_size: VM size for cluster nodes. Defaults to an Azure-compatible size;
            override for other cloud providers (e.g., "e2-standard-4" for GCP).
        kubernetes_version: Target Kubernetes version. Override to match the
            version available in the target cloud provider region.

    Returns:
        dict with cluster configuration
    """
    if node_count <= 0:
        raise ValueError(f"node_count must be > 0, got {node_count}")
    return {
        "node_count": node_count,
        "node_size": node_size,
        "kubernetes_version": kubernetes_version,
    }
